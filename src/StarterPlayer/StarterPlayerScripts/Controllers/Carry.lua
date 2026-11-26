--!nonstrict
-- Controllers/Carry: the carried, dropped and (via Base) placed boss as client visuals of the server's Carry.State
-- (m1-contract.md B, C; m1-carry-base-income.md). The server owns every result; this module shows and asks.
--   carrying : the boss clone stands on the head (feet Config.Carry.HEAD_GAP above it, never over MAX_HEIGHT tall),
--              BossMoves "carryRock" (leans back 8, rocks 4), Avatar.carryHold(true). After a won fight the pad boss
--              plays "defeat" with its hop onto the head first, then the clone takes over and the pad boss is hidden
--              until Zones.PadBeaten's backIn has passed.
--   dropped  : the clone lies on its back at dropPos with a white square timer plate (seconds left to graceEnds); the
--              Grab prompt shows while the server would accept (dropper, before graceEnds, within GRAB_RANGE).
--   Grab     : the prompt or interact (E / X) sends Carry.Grab { uid }.
-- The body is moved by BossMoves each Heartbeat (Body.CFrame = rest pivot x pose); each RenderStepped this module re-bases
-- the raw pose onto the head: world = target * restPivot^-1 * raw.
-- M2-12: Carry.State { origin, level, bought, stolenFrom, speed } is kept (Carry.info()): Base's Sell and Swap read the level and
--   the bought mark from it; the carried boss shows a "LEVEL n" label over its head (a studs-sized world label); the rock follows the
--   server's carry speed (12, 16 with Fast Carry: BossMoves.setSpeed(model, speed / Config.Carry.CARRY)).
-- API: Carry.init(deps{Avatar, BossMoves, Prompts}), Carry.state() -> name, uid, creatureId, Carry.info(), Carry.snapshot().
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Net = require(Shared:WaitForChild("Net"))
local Skin = require(Shared.Skin)
local Clock = require(script.Parent.Clock)
local BossVisuals = require(script.Parent.BossVisuals)
local Input = require(script.Parent.Input)
local Fight = require(script.Parent.Fight)
local Kit = require(script.Parent.Parent.Ui.Kit)
local WorldLabel = require(script.Parent.Parent.Ui.WorldLabel)

local C = Skin.Tokens.colors
local CFG = Config.Carry

local Carry = {}
local views, avatar, moves = nil, nil, nil
local S = { name = "none" } -- the server's last state: name, uid, creatureId, dropPos, graceEnds
local carried = nil -- { model, rp, raw, written }
local dropped = nil -- { model, plate, label, bar, anchor }
local hopping = false
local sources = {} -- hidden pad boss -> deadline (os.clock) before which it stays hidden
local padDeadline = {} -- padId -> os.clock deadline from Zones.PadBeaten
local grabShown = false
local pendingUntil = 0
local lastReport = 0

local function call(target, method, ...)
	if target and type(target[method]) == "function" then
		local ok, err = pcall(target[method], ...)
		if not ok then
			warn(("[HFB] Carry: %s failed: %s"):format(method, tostring(err)))
		end
	end
end

local function character()
	return Players.LocalPlayer and Players.LocalPlayer.Character
end
local function root(): BasePart?
	local c = character()
	return c and c:FindFirstChild("HumanoidRootPart")
end

-- Where the boss's feet go: on top of the head, facing where the player faces.
local function headTarget(): CFrame?
	local c = character()
	local head = c and c:FindFirstChild("Head")
	local r = root()
	if not (head and r) then
		return nil
	end
	local pos = head.Position + Vector3.new(0, head.Size.Y / 2 + CFG.HEAD_GAP, 0)
	local look = Vector3.new(r.CFrame.LookVector.X, 0, r.CFrame.LookVector.Z)
	if look.Magnitude < 1e-3 then
		look = Vector3.new(0, 0, -1)
	end
	return CFrame.lookAt(pos, pos + look.Unit)
end

local function clearCarried()
	if carried then
		if moves and carried.model.Parent then
			call(moves, "stop", carried.model)
		end
		carried.model:Destroy()
		carried = nil
	end
end

local function clearDropped()
	if dropped then
		dropped.model:Destroy()
		dropped.anchor:Destroy()
		dropped = nil
	end
	if grabShown then
		grabShown = false
		call(views.Prompts, "hide", "grab")
	end
end

local function levelText(level): string
	local line = Skin.get("Names.ui.boss.level") or ""
	return (string.gsub(line, "{n}", tostring(level or 1)))
end

-- A studs-sized "LEVEL n" over the carried boss (shrinks with distance like the world).
local function addLevelLabel(model: Model)
	local body = model.PrimaryPart
	if not body then
		return
	end
	local h = model:GetAttribute("H")
	local gui = WorldLabel.new({
		name = "CarryLevel",
		adornee = body,
		studsW = 6,
		studsH = 1.4,
		offset = Vector3.new(0, (if typeof(h) == "number" then h else 4) * 0.5 + 1.5, 0),
		maxDistance = 100,
	})
	local label = Instance.new("TextLabel")
	label.Name = "Level"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.FontFace = Kit.Font()
	label.TextScaled = true
	label.TextColor3 = C.white
	label.Text = levelText(S.level)
	label.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = C.ink
	stroke.Parent = label
	return label
end

local function attach(creatureId: string)
	clearCarried()
	local target = headTarget()
	local model = BossVisuals.make(creatureId, CFG.MAX_HEIGHT)
	if not (model and target) then
		if model then
			model:Destroy()
		end
		return
	end
	model:PivotTo(target)
	carried = { model = model, uid = S.uid, rp = model:GetPivot(), raw = nil, written = nil }
	carried.label = addLevelLabel(model)
	call(moves, "loop", model, "carryRock", { phase = 0 })
	if typeof(S.speed) == "number" then
		call(moves, "setSpeed", model, S.speed / CFG.CARRY)
	end
	call(avatar, "carryHold", true)
end

-- Re-bases the model's raw pose (set by BossMoves each Heartbeat) onto the head.
local function followHead()
	local c = carried
	if not c then
		return
	end
	local body = c.model.PrimaryPart
	local target = headTarget()
	if not (body and target) then
		return
	end
	if c.written == nil or body.CFrame ~= c.written then
		c.raw = body.CFrame -- a fresh pose from BossMoves
	end
	body.CFrame = target * c.rp:Inverse() * c.raw
	c.written = body.CFrame
	local at = c.model:GetPivot().Position
	c.err = (at - target.Position).Magnitude -- after the write: where the clone stands against the head, same frame
	c.at = at
end

local function makeDropped(p)
	clearDropped()
	local dropPos = p.dropPos
	local model = BossVisuals.make(p.creatureId, CFG.MAX_HEIGHT)
	if not (model and typeof(dropPos) == "Vector3") then
		if model then
			model:Destroy()
		end
		return
	end
	local lift = model:GetExtentsSize().Z / 2
	local r = root()
	local look = r and Vector3.new(r.CFrame.LookVector.X, 0, r.CFrame.LookVector.Z) or Vector3.new(0, 0, -1)
	if look.Magnitude < 1e-3 then
		look = Vector3.new(0, 0, -1)
	end
	-- on its back: tipped fully back (+X) from facing the way the player faced when it fell
	local at = dropPos + Vector3.new(0, lift, 0)
	model:PivotTo(CFrame.lookAt(at, at + look.Unit) * CFrame.Angles(math.rad(90), 0, 0))
	-- timer plate: a white square with the seconds left and a draining bar
	local anchor = Instance.new("Part")
	anchor.Name = "DropPlate"
	anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.CanTouch = true, false, false, false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Position = dropPos + Vector3.new(0, lift * 2 + 2.2, 0)
	anchor.Parent = BossVisuals.fx()
	local gui = WorldLabel.new({ name = "DropPlate", adornee = anchor, studsW = 4, studsH = 4 })
	local plate = Instance.new("Frame")
	plate.Name = "Plate"
	plate.Size = UDim2.fromScale(1, 1)
	plate.BackgroundColor3 = C.white
	plate.BorderSizePixel = 0
	plate.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = C.ink
	stroke.Parent = plate
	local label = Instance.new("TextLabel")
	label.Name = "Seconds"
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0.7, 0)
	label.FontFace = Kit.Font()
	label.TextScaled = true
	label.TextColor3 = C.ink
	label.Text = tostring(math.ceil(CFG.GRAB_S))
	label.Parent = plate
	local track = Instance.new("Frame")
	track.Name = "BarTrack"
	track.Position = UDim2.new(0.1, 0, 0.78, 0)
	track.Size = UDim2.new(0.8, 0, 0.12, 0)
	track.BackgroundColor3 = C.pipEmpty
	track.BorderSizePixel = 0
	track.Parent = plate
	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.Size = UDim2.fromScale(1, 1)
	bar.BackgroundColor3 = C.alarmOrange
	bar.BorderSizePixel = 0
	bar.Parent = track
	dropped = { model = model, plate = plate, label = label, bar = bar, anchor = anchor, total = CFG.GRAB_S }
end

local function hideSource(source: Model, padId)
	local deadline = padId and padDeadline[padId]
	if deadline and os.clock() >= deadline then
		return -- the pad's boss is already due back
	end
	BossVisuals.hide(source)
	sources[source] = deadline or math.huge
	if deadline then
		task.delay(deadline - os.clock(), function()
			if sources[source] and source.Parent then
				-- restoreSource is defined below; called through the module table
				Carry._restore(source)
			end
		end)
	end
end

local function restoreSource(source: Model)
	if not sources[source] then
		return
	end
	sources[source] = nil
	call(moves, "stop", source)
	BossVisuals.show(source)
	call(moves, "startPadIdle", source)
end

Carry._restore = function(source)
	restoreSource(source)
end

local function recentWin(creatureId: string): boolean
	local ev = Fight.log[#Fight.log]
	return ev ~= nil and ev.kind == "end" and ev.data.how == "win" and os.clock() - ev.at < 3
end

local function startCarrying(p)
	clearDropped()
	local uid, id = p.uid, p.creatureId
	if typeof(id) ~= "string" then
		return
	end
	local source = BossVisuals.source(id)
	local target = headTarget()
	if recentWin(id) and source and target and not sources[source] and S.prev == "none" then
		hopping = true
		call(avatar, "carryHold", true)
		call(moves, "play", source, "defeat", {
			hopTo = target.Position,
			onDone = function()
				hopping = false
				local padId = source.Parent and source.Parent:GetAttribute("PadId")
				hideSource(source, padId)
				if S.name == "carrying" and S.uid == uid then
					attach(id)
				end
			end,
		})
	else
		attach(id)
	end
end

local function onState(p)
	if typeof(p) ~= "table" or typeof(p.state) ~= "string" then
		return
	end
	S.prev = S.name
	S = {
		name = p.state, uid = p.uid, creatureId = p.creatureId, dropPos = p.dropPos, graceEnds = p.graceEnds, prev = S.name,
		origin = p.origin, level = p.level, bought = p.bought, speed = p.speed, stolenFrom = p.stolenFrom,
	}
	if p.state == "carrying" and carried and carried.model.Parent and S.prev == "carrying" and carried.uid == p.uid then
		-- the same carry re-sent (Fast Carry bought, a level change): update, do not rebuild
		if carried.label then
			carried.label.Text = levelText(S.level)
		end
		if typeof(S.speed) == "number" then
			call(moves, "setSpeed", carried.model, S.speed / CFG.CARRY)
		end
		return
	end
	if p.state == "carrying" then
		clearCarried()
		startCarrying(p)
	elseif p.state == "dropped" then
		hopping = false
		clearCarried()
		call(avatar, "carryHold", false)
		makeDropped(p)
	else -- none, placed
		hopping = false
		clearCarried()
		clearDropped()
		call(avatar, "carryHold", false)
	end
end

local function grabAccepted(): boolean
	local r = root()
	if S.name ~= "dropped" or not r or typeof(S.dropPos) ~= "Vector3" or typeof(S.graceEnds) ~= "number" then
		return false
	end
	return Clock.now() < S.graceEnds and (r.Position - S.dropPos).Magnitude <= CFG.GRAB_RANGE
end

local function requestGrab()
	if not grabAccepted() or os.clock() < pendingUntil then
		return
	end
	pendingUntil = os.clock() + 0.3
	Net.get("Carry", "Grab"):FireServer({ uid = S.uid })
end

local function update()
	followHead()
	if dropped then
		local left = (S.graceEnds or 0) - Clock.now()
		dropped.label.Text = tostring(math.max(0, math.ceil(left)))
		dropped.bar.Size = UDim2.fromScale(math.clamp(left / dropped.total, 0, 1), 1)
	end
	local want = grabAccepted()
	if want and not grabShown then
		grabShown = true
		call(views.Prompts, "show", "grab", Input.kind())
	elseif not want and grabShown then
		grabShown = false
		call(views.Prompts, "hide", "grab")
	end
end

function Carry.state()
	return S.name, S.uid, S.creatureId
end

-- What Base's Sell and Swap need (and the check reads): the server's last Carry.State.
function Carry.info()
	return { state = S.name, uid = S.uid, creatureId = S.creatureId, level = S.level, bought = S.bought, origin = S.origin, speed = S.speed, stolenFrom = S.stolenFrom }
end

function Carry.snapshot()
	local r = root()
	local d = carried and carried.err
	local t = headTarget()
	return {
		st = S.name,
		uid = S.uid,
		carried = carried ~= nil,
		headDist = d and math.floor(d * 100 + 0.5) / 100,
		rock = carried and moves and (moves.current(carried.model)) or nil,
		ht = t ~= nil,
		px = carried and carried.at and math.floor(carried.at.X * 10 + 0.5) / 10,
		pz = carried and carried.at and math.floor(carried.at.Z * 10 + 0.5) / 10,
		dropped = dropped ~= nil,
		plate = dropped and dropped.label.Text or nil,
		grab = grabShown,
		hop = hopping,
		lvl = carried and carried.label and carried.label.Text or nil,
		origin = S.origin,
		speed = S.speed,
		hidden = next(sources) ~= nil,
		dist = r and S.dropPos and math.floor((r.Position - S.dropPos).Magnitude * 10 + 0.5) / 10 or nil,
	}
end

function Carry.init(deps)
	views = deps.views or {}
	avatar, moves = deps.Avatar, deps.BossMoves
	BossVisuals.init()
	Net.get("Carry", "State").OnClientEvent:Connect(onState)
	Net.get("Zones", "PadBeaten").OnClientEvent:Connect(function(p)
		if typeof(p) ~= "table" or typeof(p.padId) ~= "string" or typeof(p.backIn) ~= "number" then
			return
		end
		local deadline = os.clock() + p.backIn
		padDeadline[p.padId] = deadline
		task.delay(p.backIn, function()
			for source, d in pairs(sources) do
				if source.Parent and source.Parent:GetAttribute("PadId") == p.padId then
					restoreSource(source)
				end
			end
		end)
	end)
	Input.onInteract(function()
		if grabShown then
			requestGrab()
		end
	end)
	call(views.Prompts, "onPress", "grab", requestGrab)
	Input.onKindChanged(function(kind)
		if grabShown then
			call(views.Prompts, "show", "grab", kind)
		end
	end)
	RunService.RenderStepped:Connect(update)
	Players.LocalPlayer.CharacterAdded:Connect(function()
		clearCarried()
		clearDropped()
		hopping = false
	end)
end

return Carry
