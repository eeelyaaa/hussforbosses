--!strict
-- Controllers/Fight: the client side of a boss fight (m1-contract.md sections C, H "Fight events -> moves", I;
-- m1-punch-and-fight.md, M1-07). The server decides every result; this module asks, shows and moves.
--   * In a boss pad's Ring with no fight: the Huss button is in "start" mode and the start prompt shows the glyph
--     of the input in use; a punch (or the prompt) sends Fight.Start { padId }.
--   * Fight.State started: the ring runs with the fight's windows, the overlay shows, the camera frames the boss
--     and stays put, the player is held in place (B13: the server stands the character at the fight spot and
--     freezes WalkSpeed/jump; the client only turns AutoRotate off), the boss loops `guard`.
--   * Beats -> hitGood / hitPerfect / hitBig; Fight.Beat won -> cutContact on the later beats (B22);
--     Fight.Heart -> attack (lastHeart, which ends in the gloat, then idle, when last); win -> defeat; run -> idle.
--   * Run (Backspace, B, the Run button) sends Fight.Run {}; a loss or run cancels a running burst (F fades 40 ms).
-- API: Fight.init(views, deps), Fight.active() -> fight?, Fight.inStartRing() -> padId?, Fight.requestStart(),
--      Fight.run(), Fight.lastGlyph, Fight.log (events seen, for checks).
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Skin = require(Shared:WaitForChild("Skin"))
local BurstClock = require(script.Parent:WaitForChild("BurstClock"))
local Ring = require(script.Parent:WaitForChild("Ring"))
local Input = require(script.Parent:WaitForChild("Input"))

local START_PENDING_S = 2
local Config = require(Shared:WaitForChild("Config"))

local Fight = {}
Fight.log = {} :: { any }
Fight.lastGlyph = nil :: string?

local views: any = {}
local moves: any = nil -- Controllers/BossMoves (M1-09), or a no-op
local current: any = nil -- the running fight
local pendingUntil = 0
local saved: any = nil -- movement and camera values to restore
local promptShown = false

local function logEvent(kind: string, data: any)
	table.insert(Fight.log, { kind = kind, at = os.clock(), data = data })
	if #Fight.log > 60 then
		table.remove(Fight.log, 1)
	end
end

local function call(target: any, method: string, ...: any)
	if target and type(target[method]) == "function" then
		local ok, err = pcall(target[method], ...)
		if not ok then
			warn(("[HFB] Fight: %s failed: %s"):format(method, tostring(err)))
		end
	end
end

-- Pads: CollectionService tag HFB_BossPad, attribute PadId; children Ring (attribute RingRadius), Boss.
local function pads(): { Instance }
	return CollectionService:GetTagged("HFB_BossPad")
end

local function padById(padId: string): Instance?
	for _, pad in ipairs(pads()) do
		if pad:GetAttribute("PadId") == padId then
			return pad
		end
	end
	return nil
end

local function bossOf(pad: Instance?): Model?
	if not pad then
		return nil
	end
	local b = pad:FindFirstChild("Boss")
	if b and b:IsA("Model") then
		return b
	end
	for _, d in ipairs(pad:GetDescendants()) do
		if d:IsA("Model") and CollectionService:HasTag(d, "HFB_Boss") then
			return d
		end
	end
	return nil
end

local function rootPart(): BasePart?
	local char = Players.LocalPlayer and Players.LocalPlayer.Character
	return char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function humanoid(): Humanoid?
	local char = Players.LocalPlayer and Players.LocalPlayer.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

function Fight.active(): any
	return current
end

-- The pad whose Ring the player stands in (horizontal distance <= RingRadius), when no fight runs.
function Fight.inStartRing(): string?
	if current then
		return nil
	end
	local root = rootPart()
	if not root then
		return nil
	end
	for _, pad in ipairs(pads()) do
		local ring = pad:FindFirstChild("Ring")
		local radius = ring and ring:GetAttribute("RingRadius")
		if ring and ring:IsA("BasePart") and typeof(radius) == "number" then
			-- M2-07: the boss patrols (Shared/Patrol, up to 14 studs from the ring), and the server tests Fight.Start against where
			-- the boss is now, so the client measures from the pad boss's live position too (the ring centre when it has none).
			local boss = bossOf(pad)
			local centre = if boss then boss:GetBoundingBox().Position else ring.Position
			local d = root.Position - centre
			if Vector2.new(d.X, d.Z).Magnitude <= radius then
				local id = pad:GetAttribute("PadId")
				if typeof(id) == "string" then
					return id
				end
			end
		end
	end
	return nil
end

local retried = false -- one automatic retry per press after a "ring" refusal

function Fight.requestStart(isRetry: boolean?)
	local padId = Fight.inStartRing()
	if not padId or os.clock() < pendingUntil then
		return
	end
	if not isRetry then
		retried = false
	end
	pendingUntil = os.clock() + START_PENDING_S
	logEvent("request", { padId = padId })
	Net.get("Fight", "Start"):FireServer({ padId = padId })
end

function Fight.run()
	if not current then
		return
	end
	logEvent("runRequest", { fightId = current.fightId })
	Net.get("Fight", "Run"):FireServer({})
end

-- Held in place and the fight camera (B13). Saved values are restored on end.
-- `spot` (Fight.State started, M1-26b): the server already stood the character there facing the boss; the client sets
-- the same CFrame at once (it owns the character's physics, and the move may replicate after the remote), then frames.
local function hold(boss: Model?, spot: Vector3?)
	local hum = humanoid()
	local root = rootPart()
	local cam = workspace.CurrentCamera
	-- WalkSpeed and jump are the server's (Systems/Fight freeze/unfreeze, B13): its freeze has already replicated when
	-- this runs, so saving and restoring them here wrote 0 back after Run (M1-26b). The client keeps only AutoRotate.
	saved = {
		hum = hum,
		autoRotate = hum and hum.AutoRotate,
		camType = cam and cam.CameraType,
	}
	if hum then
		hum.AutoRotate = false
	end
	if root and boss and cam then
		local at = if typeof(spot) == "Vector3" then spot else root.Position
		local centre = boss:GetBoundingBox().Position
		local flat = Vector3.new(centre.X - at.X, 0, centre.Z - at.Z)
		if flat.Magnitude > 0.1 then
			root.AssemblyLinearVelocity = Vector3.zero
			root.CFrame = CFrame.lookAt(at, at + flat.Unit)
			cam.CameraType = Enum.CameraType.Scriptable
			cam.CFrame = Fight.frameBoss(boss, root.Position, cam)
		end
	end
end

-- The camera CFrame that frames the whole boss (M1-26, Config.Fight.CAMERA). Pure: reads the boss's bounding box and H,
-- the player's position and the camera's FOV and viewport; moves nothing.
local function frameAt(boss: Model, playerPos: Vector3, cam: Camera, sideDeg: number): CFrame
	local C = Config.Fight.CAMERA
	local bbCf, bbSize = boss:GetBoundingBox()
	local h = boss:GetAttribute("H")
	local height = if typeof(h) == "number" then h else bbSize.Y
	local center = bbCf.Position
	local toPlayer = Vector3.new(playerPos.X - center.X, 0, playerPos.Z - center.Z)
	toPlayer = if toPlayer.Magnitude > 0.01 then toPlayer.Unit else Vector3.new(0, 0, 1)
	local yawed = CFrame.Angles(0, math.rad(sideDeg), 0) * toPlayer
	local elev = math.rad(C.ELEV_DEG)
	local dir = (yawed * math.cos(elev) + Vector3.new(0, math.sin(elev), 0)).Unit
	local vp = cam.ViewportSize
	local tanV = math.tan(math.rad(cam.FieldOfView) / 2)
	local tanH = tanV * (vp.X / math.max(vp.Y, 1))
	local corners = {}
	for _, sx in { -0.5, 0.5 } do
		for _, sy in { -0.5, 0.5 } do
			for _, sz in { -0.5, 0.5 } do
				table.insert(corners, (bbCf * CFrame.new(bbSize.X * sx, bbSize.Y * sy, bbSize.Z * sz)).Position)
			end
		end
	end
	local wantW, wantH = C.BAND_RIGHT - C.BAND_LEFT, C.BAND_BOTTOM - C.BAND_TOP
	local midU, midV = (C.BAND_LEFT + C.BAND_RIGHT) / 2, (C.BAND_TOP + C.BAND_BOTTOM) / 2
	-- At a distance: look at the box, pan the aim until the box's screen rectangle is centred in the band, then
	-- report the camera and whether the rectangle fits the band.
	local function fitAt(dist: number): (CFrame, boolean)
		local aim = center
		local cf = CFrame.lookAt(center + dir * dist, aim)
		local w, hh = 0, 0
		for _ = 1, C.PAN_ITERATIONS do
			cf = CFrame.lookAt(center + dir * dist, aim)
			local minU, maxU, minV, maxV = math.huge, -math.huge, math.huge, -math.huge
			for _, p in corners do
				local l = cf:PointToObjectSpace(p)
				local depth = math.max(-l.Z, 0.1)
				local u = 0.5 + l.X / (depth * tanH) / 2
				local v = 0.5 - l.Y / (depth * tanV) / 2
				minU, maxU, minV, maxV = math.min(minU, u), math.max(maxU, u), math.min(minV, v), math.max(maxV, v)
			end
			w, hh = maxU - minU, maxV - minV
			local depthC = (center - cf.Position).Magnitude
			aim = aim
				+ cf.RightVector * (((minU + maxU) / 2 - midU) * 2 * tanH * depthC)
				- cf.UpVector * (((minV + maxV) / 2 - midV) * 2 * tanV * depthC)
		end
		cf = CFrame.lookAt(center + dir * dist, aim)
		return cf, w <= wantW and hh <= wantH
	end
	local lo, hi = height * C.MIN_DIST_H, bbSize.Magnitude * 20
	local best = select(1, fitAt(hi))
	for _ = 1, C.FIT_ITERATIONS do
		local mid = (lo + hi) / 2
		local cf, fits = fitAt(mid)
		if fits then
			hi, best = mid, cf
		else
			lo = mid
		end
	end
	return best
end

-- M2-07: the fight spot can leave the avatar closer than usual (a wall behind the boss, the patrol near the pad's edge), and
-- then the usual side angle puts it over the boss. Start at SIDE_DEG and turn further round (SIDE_STEP at a time, to SIDE_MAX)
-- until the avatar (a box about the player's root) covers no more than AVOID_OVERLAP of the boss's screen box; else the
-- least covering side wins. Pure like frameAt.
function Fight.frameBoss(boss: Model, playerPos: Vector3, cam: Camera): CFrame
	local C = Config.Fight.CAMERA
	local first = frameAt(boss, playerPos, cam, C.SIDE_DEG)
	if not C.AVOID_OVERLAP then
		return first
	end
	local bbCf, bbSize = boss:GetBoundingBox()
	local vp = cam.ViewportSize
	local tanV = math.tan(math.rad(cam.FieldOfView) / 2)
	local tanH = tanV * (vp.X / math.max(vp.Y, 1))
	local function rect(cf: CFrame, centre: CFrame, size: Vector3): (number, number, number, number)
		local minU, minV, maxU, maxV = math.huge, math.huge, -math.huge, -math.huge
		for _, sx in { -0.5, 0.5 } do
			for _, sy in { -0.5, 0.5 } do
				for _, sz in { -0.5, 0.5 } do
					local l = cf:PointToObjectSpace((centre * CFrame.new(size.X * sx, size.Y * sy, size.Z * sz)).Position)
					local depth = math.max(-l.Z, 0.1)
					local u = 0.5 + l.X / (depth * tanH) / 2
					local v = 0.5 - l.Y / (depth * tanV) / 2
					minU, maxU, minV, maxV = math.min(minU, u), math.max(maxU, u), math.min(minV, v), math.max(maxV, v)
				end
			end
		end
		return minU, minV, maxU, maxV
	end
	local avatarBox = CFrame.new(playerPos.X, playerPos.Y - 0.25, playerPos.Z)
	local function overlap(cf: CFrame): number
		local bu0, bv0, bu1, bv1 = rect(cf, bbCf, bbSize)
		local au0, av0, au1, av1 = rect(cf, avatarBox, Vector3.new(2.4, 5.5, 2.4))
		local w = math.min(bu1, au1) - math.max(bu0, au0)
		local h = math.min(bv1, av1) - math.max(bv0, av0)
		return if w > 0 and h > 0 then w * h / math.max((bu1 - bu0) * (bv1 - bv0), 1e-6) else 0
	end
	local best, bestOv = first, overlap(first)
	local side = C.SIDE_DEG
	while bestOv > C.AVOID_OVERLAP and side + C.SIDE_STEP <= C.SIDE_MAX do
		side += C.SIDE_STEP
		local cf = frameAt(boss, playerPos, cam, side)
		local ov = overlap(cf)
		if ov < bestOv then
			best, bestOv = cf, ov
		end
	end
	return best
end

local function release()
	local s = saved
	saved = nil
	if not s then
		return
	end
	local hum: Humanoid? = s.hum
	if hum and hum.Parent then
		hum.AutoRotate = s.autoRotate
	end
	local cam = workspace.CurrentCamera
	if cam then
		cam.CameraType = if s.camType == Enum.CameraType.Scriptable then Enum.CameraType.Custom else s.camType
		local h = humanoid()
		if h then
			cam.CameraSubject = h
		end
	end
end

local function tierWord(creatureId: string): string?
	local tier = tonumber(string.match(creatureId, "_t(%d+)$") or "")
	return tier and Skin.get("Names.tiers." .. tier)
end

local function playIdle(boss: Model?)
	if boss then
		call(moves, "startPadIdle", boss)
	end
end

local function endFight(how: string)
	local f = current
	if not f then
		return
	end
	current = nil
	Ring.setFight(nil)
	release()
	call(views.FightOverlay, "hide")
	logEvent("end", { how = how, fightId = f.fightId })
end

local function onState(p: any)
	if typeof(p) ~= "table" or typeof(p.state) ~= "string" then
		return
	end
	logEvent("state", { state = p.state, fightId = p.fightId, reason = p.reason, band = p.band })
	if p.state == "refused" then
		pendingUntil = 0
		-- Walking in, the press can beat the character's position to the server (M1-26b): ask once more.
		if p.reason == "ring" and not retried then
			retried = true
			task.delay(Config.Fight.RING_RETRY_S, function()
				if Fight.inStartRing() == p.padId then
					Fight.requestStart(true)
				end
			end)
		end
		return
	end
	if p.state == "started" then
		pendingUntil = 0
		if current then
			endFight("replaced")
		end
		local pad = padById(p.padId)
		local boss = bossOf(pad)
		current = {
			fightId = p.fightId,
			padId = p.padId,
			creatureId = p.creatureId,
			boss = boss,
			maxHealth = p.maxHealth,
			lastHeartPlaying = false,
		}
		Ring.setFight({ goodMs = p.goodMs, perfectMs = p.perfectMs })
		local info = table.clone(p)
		info.bossName = Skin.get("Names.creatures." .. tostring(p.creatureId))
		info.tierWord = tierWord(tostring(p.creatureId))
		call(views.FightOverlay, "show", info)
		call(views.FightOverlay, "setHealth", p.health, p.maxHealth)
		call(views.FightOverlay, "setHearts", p.hearts)
		call(views.FightOverlay, "setBand", p.band)
		hold(boss, p.spot)
		if boss then
			call(moves, "loop", boss, "guard")
		end
		return
	end
	if not current or p.fightId ~= current.fightId then
		return
	end
	local boss = current.boss
	if p.state == "win" then
		-- ONE defeat per win (M2-07; it was played twice in the same frame, m1-sync-test.md finding 1). The carry
		-- controller plays it, with the hop onto the head, when the server's carrying state arrives (the same frame or
		-- the next); if nothing has started one by then (no hop target), it plays here.
		if boss then
			task.delay(0.3, function()
				if boss.Parent and not (moves and type(moves.isPlaying) == "function" and moves.isPlaying(boss, "defeat")) then
					call(moves, "play", boss, "defeat", {})
				end
			end)
		end
		endFight("win")
	elseif p.state == "loss" then
		local id = BurstClock.running()
		if id then
			BurstClock.cancel(id, "knockdown")
		end
		if boss and not current.lastHeartPlaying then
			call(moves, "play", boss, "gloat", { onDone = function()
				playIdle(boss)
			end })
		end
		endFight("loss")
	elseif p.state == "run" then
		local id = BurstClock.running()
		if id then
			BurstClock.cancel(id, "run")
		end
		playIdle(boss)
		endFight("run")
	end
end

local function onBeat(p: any)
	local f = current
	if typeof(p) ~= "table" or not f or p.fightId ~= f.fightId then
		return
	end
	logEvent("beat", { n = p.n, damage = p.damage, health = p.health, won = p.won })
	call(views.FightOverlay, "setHealth", p.health, f.maxHealth)
	if p.won == true and typeof(p.n) == "number" then
		local id = BurstClock.running()
		if id then
			BurstClock.cutContact(id, p.n + 1)
		end
	end
end

local function onHeart(p: any)
	local f = current
	if typeof(p) ~= "table" or not f or p.fightId ~= f.fightId then
		return
	end
	logEvent("heart", { hearts = p.hearts, last = p.last })
	call(views.FightOverlay, "setHearts", p.hearts)
	local boss = f.boss
	if not boss then
		return
	end
	if p.last then
		f.lastHeartPlaying = true
		-- lastHeart includes the 0.35 s gloat (M1-09e), so the loss path is lastHeart then idle.
		call(moves, "play", boss, "lastHeart", { onDone = function()
			playIdle(boss)
		end })
	else
		call(moves, "play", boss, "attack", { onDone = function()
			if current == f then
				call(moves, "loop", boss, "guard")
			end
		end })
	end
end

-- Hit reactions hang off the client's beats (sound-direction.md: everything that belongs to a landing).
local function onClientBeat(ev: any)
	local f = current
	if ev.context ~= "fight" or not f or not f.boss or ev.noContact then
		return
	end
	local perfect = ev.grade == "perfect"
	local name = if ev.n == 3 then "hitBig" elseif perfect then "hitPerfect" else "hitGood"
	local boss = f.boss
	call(moves, "play", boss, name, { perfect = perfect, onDone = function()
		if current == f then
			call(moves, "loop", boss, "guard")
		end
	end })
end

-- An untimed single punch in a fight (M2-07, P3): the boss takes one hit (the server's Beat size 'single' moves the health).
Ring.onEvent(function(kind: string, data: any)
	local f = current
	if kind == "graded" and data.grade == "untimed" and f and f.boss then
		local boss = f.boss
		call(moves, "play", boss, "hitGood", { perfect = false, onDone = function()
			if current == f then
				call(moves, "loop", boss, "guard")
			end
		end })
	end
end)

local function updatePrompt()
	local inRing = Fight.inStartRing() ~= nil
	if inRing and not promptShown then
		promptShown = true
		Fight.lastGlyph = Input.kind()
		call(views.Prompts, "show", "start", Fight.lastGlyph)
	elseif not inRing and promptShown then
		promptShown = false
		call(views.Prompts, "hide", "start")
	end
end

local started = false
function Fight.init(v: any, deps: any?)
	if started then
		return
	end
	started = true
	views = v or {}
	moves = deps and deps.BossMoves or nil
	Net.get("Fight", "State").OnClientEvent:Connect(onState)
	Net.get("Fight", "Beat").OnClientEvent:Connect(onBeat)
	Net.get("Fight", "Heart").OnClientEvent:Connect(onHeart)
	BurstClock.onBeat(onClientBeat)
	Input.onRun(function()
		Fight.run()
	end)
	call(views.FightOverlay, "onRun", function()
		Input.fire("run", "touch")
	end)
	call(views.Prompts, "onPress", "start", function()
		Fight.requestStart()
	end)
	Input.onKindChanged(function(kind)
		if promptShown then
			Fight.lastGlyph = kind
			call(views.Prompts, "show", "start", kind)
		end
	end)
	local function idleAll()
		for _, pad in ipairs(pads()) do
			playIdle(bossOf(pad))
		end
	end
	task.defer(idleAll)
	CollectionService:GetInstanceAddedSignal("HFB_BossPad"):Connect(function(pad)
		task.defer(playIdle, bossOf(pad))
	end)
	-- M2-34 streaming: the pad's boss can arrive after the pad (or stream back in): idle it when it shows up
	CollectionService:GetInstanceAddedSignal("HFB_Boss"):Connect(function(boss)
		if boss:IsA("Model") and not boss:GetAttribute("PadBoss") then
			for _, pad in ipairs(pads()) do
				if boss:IsDescendantOf(pad) then
					task.defer(playIdle, boss)
					return
				end
			end
		end
	end)
	Players.LocalPlayer.CharacterAdded:Connect(function()
		if current then
			endFight("respawn") -- release() puts the camera back on the new humanoid
		end
	end)
	RunService.Heartbeat:Connect(updatePrompt)
end

-- For checks: feed server events without a server (edit-mode test).
Fight._onState, Fight._onBeat, Fight._onHeart = onState, onBeat, onHeart

return Fight
