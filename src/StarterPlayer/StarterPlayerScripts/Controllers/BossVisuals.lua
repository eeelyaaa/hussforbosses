--!nonstrict
-- Controllers/BossVisuals: clones of a boss model for the carried, dropped and placed boss (client-only visuals of
-- server state), and the hide/show of the pad boss. Templates are taken from the pad bosses at init, before any move
-- touches them (Fight.init defers its pad idle), so a clone is at rest pose.
--   BossVisuals.init()                  capture a template per CreatureId from the tagged pad bosses
--   BossVisuals.make(creatureId, scaleToMax?) -> Model?   a clone in workspace.HFB_ClientFx (tag HFB_Boss removed)
--   BossVisuals.source(creatureId) -> Model?              the pad boss (the original)
--   BossVisuals.hide(model) / BossVisuals.show(model)     LocalTransparencyModifier, this client only
--   BossVisuals.fx() -> Folder
-- M2-12 (the pad bosses): every pad draws its own boss, a client clone named "Boss" under the pad Model (Controllers/Fight
-- finds it there), walking the patrol from the server clock (Shared/Patrol: nothing is replicated per frame) and frozen at
-- Fight.State.bossPos for the fighter. Pads feeds it the Zones.Pads entries:
--   BossVisuals.setEntry(padId, entry)       the pad's creature and patrol (draws, swaps on a new roll)
--   BossVisuals.setPadHidden(padId, hidden)  beaten for this player (ignored while the won boss is the carry's to hide)
--   BossVisuals.padBoss(padId) -> Model?     BossVisuals.source(creatureId, padId?) prefers the pad clone
--   BossVisuals.padState(padId) -> table?    for checks
-- A creature with no model yet draws the same zone's model (a stand-in until its own model is imported; TEAM CALL M2-12-2).
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local Patrol = require(Shared.Patrol)
local Clock = require(script.Parent.Clock)
local BossMoves = require(script.Parent.BossMoves)

local V = {}
local templates = {}
local padBosses = {} -- padId -> { entry, model (pad), boss, bossFor, rp, raw, written, frozen, winHold, hidden, anchor, groundY }
local fightPad = {} -- fightId -> padId
local lastFightPad = nil

function V.fx(): Folder
	local f = workspace:FindFirstChild("HFB_ClientFx") -- stream-ok: client-created folder
	if not f then
		f = Instance.new("Folder")
		f.Name = "HFB_ClientFx"
		f.Parent = workspace
	end
	return f
end

function V.source(creatureId: string, padId: string?): Model?
	if padId and padBosses[padId] and padBosses[padId].boss and padBosses[padId].bossFor == creatureId then
		return padBosses[padId].boss
	end
	if lastFightPad and padBosses[lastFightPad] and padBosses[lastFightPad].bossFor == creatureId and padBosses[lastFightPad].boss then
		return padBosses[lastFightPad].boss
	end
	for _, d in pairs(padBosses) do
		if d.boss and d.bossFor == creatureId and d.boss.Parent then
			return d.boss
		end
	end
	local fx = workspace:FindFirstChild("HFB_ClientFx") -- stream-ok: client-created folder
	for _, m in ipairs(CollectionService:GetTagged("HFB_Boss")) do
		if m:IsA("Model") and m:GetAttribute("CreatureId") == creatureId and not (fx and m:IsDescendantOf(fx)) then
			return m
		end
	end
	return nil
end

local function sanitize(m: Model)
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("Motor6D") then
			d.Transform = CFrame.identity
		end
	end
	CollectionService:RemoveTag(m, "HFB_Boss")
	-- the replicated copy can arrive without its PrimaryPart (found in the M1-14 play check): Body is the root group
	local body = m:FindFirstChild("Body", true)
	if body and body:IsA("BasePart") then
		m.PrimaryPart = body
	end
end

-- Sig exists on some body types only (squat, golem); the tailed, swayer and biped sets have Body Head FistL FistR + their own groups
local GROUPS = { "Body", "Head", "FistL", "FistR" }
-- All five groups and their joints are there (the model can arrive on the client before its children do).
local function complete(m: Model): boolean
	for _, g in ipairs(GROUPS) do
		if not m:FindFirstChild(g, true) then
			return false
		end
	end
	local joints = 0
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("Motor6D") then
			joints += 1
		end
	end
	return joints >= #GROUPS - 1
end

local function capture(m: Model): boolean
	local id = m:GetAttribute("CreatureId")
	if typeof(id) ~= "string" then
		return false
	end
	if templates[id] then
		return true
	end
	if not complete(m) then
		return false
	end
	local t = m:Clone()
	sanitize(t)
	templates[id] = t
	return true
end

-- Waits (up to 15 s) for a pad boss to arrive whole, then takes the template.
local function watch(m: Instance)
	if not m:IsA("Model") or m:IsDescendantOf(V.fx()) then
		return
	end
	task.spawn(function()
		local t0 = os.clock()
		while m.Parent and not capture(m) and os.clock() - t0 < 15 do
			task.wait(0.1)
		end
	end)
end

local inited = false
local function initPadBosses() end -- defined below
function V.init()
	if inited then
		return
	end
	inited = true
	for _, m in ipairs(CollectionService:GetTagged("HFB_Boss")) do
		watch(m)
	end
	CollectionService:GetInstanceAddedSignal("HFB_Boss"):Connect(watch)
	initPadBosses()
end

-- The template for an id: its own, else (stand-in, TEAM CALL M2-12-2) the template of the same zone nearest in tier.
local function templateFor(creatureId: string)
	local t = templates[creatureId]
	if t then
		return t
	end
	local zone, tier = string.match(creatureId, "^z(%d+)_t(%d+)$")
	if not zone then
		return nil
	end
	local best, bestGap = nil, math.huge
	for id, tpl in pairs(templates) do
		local z, ti = string.match(id, "^z(%d+)_t(%d+)$")
		if z == zone then
			local gap = math.abs(tonumber(ti) - tonumber(tier))
			if gap < bestGap then
				best, bestGap = tpl, gap
			end
		end
	end
	return best
end

function V.make(creatureId: string, maxHeight: number?): Model?
	local t = templateFor(creatureId)
	if not t then
		local s = V.source(creatureId)
		if not s then
			return nil
		end
		capture(s) -- the pad boss may be posed by now; sanitize resets the joints and make() re-poses the body
		t = templateFor(creatureId)
	end
	if not t then
		return nil
	end
	local m = t:Clone()
	local h = m:GetAttribute("H")
	if maxHeight and typeof(h) == "number" and h > maxHeight then
		m:ScaleTo(maxHeight / h)
		m:SetAttribute("H", maxHeight)
	end
	m.Parent = V.fx()
	return m
end

local function setHidden(model: Instance, on: boolean)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.LocalTransparencyModifier = on and 1 or 0
		end
	end
end
function V.hide(model: Instance)
	setHidden(model, true)
end
local resume -- defined below
function V.show(model: Instance)
	setHidden(model, false)
	for _, d in pairs(padBosses) do
		if d.boss == model and d.winHold then
			resume(d)
		end
	end
end

-- ------------------------------------------------------------------------------------------------ the pad bosses
local function padModelOf(padId: string): Model?
	for _, m in ipairs(CollectionService:GetTagged("HFB_BossPad")) do
		if m:IsA("Model") and m:GetAttribute("PadId") == padId then
			return m
		end
	end
	return nil
end

local function entryOf(padId: string)
	local d = padBosses[padId]
	if not d then
		d = { hidden = false }
		padBosses[padId] = d
	end
	return d
end

-- Where the patrol puts this pad's boss at server time t (feet on the ring's top).
local function patrolCF(d, t: number): CFrame?
	local e = d.entry
	if not (e and e.patrol and d.anchor) then
		return nil
	end
	local pos, facing = Patrol.position(d.anchor, e.patrol, t)
	pos = Vector3.new(pos.X, d.groundY, pos.Z)
	local f = Vector3.new(facing.X, 0, facing.Z)
	return CFrame.lookAt(pos, pos + (if f.Magnitude > 1e-3 then f.Unit else Vector3.zAxis))
end

local function prepareModel(d)
	local m = d.model
	if d.anchor and d.groundY then
		return true
	end
	if not (m and m.Parent) then
		return false
	end
	local a = Patrol.anchor(m, Config.Zones.LANE)
	local ring = m:FindFirstChild("Ring")
	if not (a and ring and ring:IsA("BasePart")) then
		return false
	end
	d.anchor = a
	d.groundY = ring.Position.Y + ring.Size.Y / 2
	return true
end

local function destroyBoss(d)
	if d.boss then
		pcall(BossMoves.stop, d.boss)
		d.boss:Destroy()
	end
	d.boss, d.bossFor, d.rp, d.raw, d.written, d.frozen, d.winHold = nil, nil, nil, nil, nil, nil, false
end

local function ensureBoss(d)
	local e = d.entry
	if not e or typeof(e.creatureId) ~= "string" then
		return
	end
	if d.boss and d.boss.Parent and (d.bossFor == e.creatureId or d.frozen or d.winHold) then
		return -- (a fight or a beaten hold keeps its boss until it is over; a new roll swaps it after)
	end
	if not (d.model and d.model.Parent) then
		d.model = padModelOf(d.padId)
	end
	if not (d.model and prepareModel(d)) then
		return
	end
	local target = patrolCF(d, Clock.now())
	if not target then
		return
	end
	if d.boss then
		destroyBoss(d)
	end
	local m = V.make(e.creatureId)
	if not m then
		return
	end
	m.Name = "Boss"
	m:SetAttribute("PadBoss", true)
	m.Parent = d.model
	m:PivotTo(target)
	d.boss, d.bossFor = m, e.creatureId
	d.rp, d.raw, d.written, d.frozen, d.winHold = target, nil, nil, nil, false
	-- the world's own stand-in model on this pad is not drawn (this one is the pad's boss)
	for _, c in ipairs(d.model:GetChildren()) do
		if c ~= m and c:IsA("Model") and c:GetAttribute("CreatureId") ~= nil then
			setHidden(c, true)
		end
	end
	if d.hidden then
		setHidden(m, true)
	end
	BossMoves.startPadIdle(m)
end

-- Re-bases the model onto `target` whatever BossMoves wrote this frame (Controllers/Carry's technique).
local function place(d, target: CFrame)
	local m = d.boss
	local body = m.PrimaryPart
	if not body then
		return
	end
	local rp = BossMoves.restPivot(m)
	if not rp then
		m:PivotTo(target) -- no move running: the model is at rest
		d.written, d.raw = nil, nil
		return
	end
	if d.written == nil or body.CFrame ~= d.written then
		d.raw = body.CFrame -- a fresh pose from BossMoves
	end
	body.CFrame = target * rp:Inverse() * d.raw
	d.written = body.CFrame
end

-- Stops the moves, stands the model at `cf`, and starts the base loop again at that pose (BossMoves re-reads its rest
-- pivot from the pose it starts at, so a hop or a scale about the feet stays right wherever the boss stands).
local function rest(d, cf: CFrame)
	local m = d.boss
	if not (m and m.Parent) then
		return
	end
	local base = BossMoves.current(m)
	BossMoves.stop(m)
	m:PivotTo(cf)
	d.written, d.raw = nil, nil
	if base then
		BossMoves.loop(m, base)
	end
end

resume = function(d)
	d.frozen, d.winHold = nil, false
	local cf = patrolCF(d, Clock.now())
	if cf then
		rest(d, cf)
	end
	if d.boss and not d.hidden then
		setHidden(d.boss, false)
	end
end

local function onFightState(p)
	if typeof(p) ~= "table" or typeof(p.state) ~= "string" then
		return
	end
	if p.state == "started" and typeof(p.padId) == "string" and typeof(p.fightId) == "number" then
		fightPad[p.fightId] = p.padId
		lastFightPad = p.padId
		local d = padBosses[p.padId]
		if not (d and d.boss) then
			return
		end
		local pos = if typeof(p.bossPos) == "Vector3" then p.bossPos else nil
		local cur = patrolCF(d, Clock.now())
		pos = pos or (cur and cur.Position)
		if not pos then
			return
		end
		pos = Vector3.new(pos.X, d.groundY, pos.Z)
		local char = Players.LocalPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local face = if root then Vector3.new(root.Position.X, pos.Y, root.Position.Z) else pos + Vector3.zAxis
		d.frozen = if (face - pos).Magnitude > 0.1 then CFrame.lookAt(pos, face) else CFrame.new(pos)
		d.winHold = false
		rest(d, d.frozen)
		return
	end
	local pid = fightPad[p.fightId]
	local d = pid and padBosses[pid]
	if not d then
		return
	end
	if p.state == "win" then
		d.winHold = true -- stays where it was beaten until the carry has hopped it onto the head and it is due back
	elseif p.state == "loss" or p.state == "run" then
		resume(d)
	end
end

V._onFightState = onFightState -- for checks (a fake Fight.State)

function V.setEntry(padId: string, entry)
	local d = entryOf(padId)
	d.padId = padId
	d.entry = entry
	ensureBoss(d)
end

function V.setPadHidden(padId: string, hidden: boolean)
	local d = entryOf(padId)
	d.padId = padId
	if hidden and (d.winHold or d.frozen) then
		return -- the fight is on, or the carry hides the beaten boss after its hop
	end
	d.hidden = hidden
	if d.boss then
		setHidden(d.boss, hidden)
		if not hidden and d.winHold then
			resume(d)
		end
	end
end

function V.padBoss(padId: string): Model?
	local d = padBosses[padId]
	return d and d.boss or nil
end

function V.padState(padId: string)
	local d = padBosses[padId]
	if not d then
		return nil
	end
	local pos = d.boss and d.boss.PrimaryPart and d.boss:GetPivot().Position
	return { creatureId = d.bossFor, frozen = d.frozen ~= nil, winHold = d.winHold == true, hidden = d.hidden, boss = d.boss, pos = pos, groundY = d.groundY }
end

-- wanted: every padId the registry knows
function V.padIds(): { string }
	local out = {}
	for id in pairs(padBosses) do
		table.insert(out, id)
	end
	table.sort(out)
	return out
end

local LOD_NEAR, LOD_FAR, DRAW_MAX = 200, 240, 320
initPadBosses = function()
	Net.get("Fight", "State").OnClientEvent:Connect(onFightState)
	local acc = 0
	RunService.RenderStepped:Connect(function(dt: number)
		local t = Clock.now()
		local cam = workspace.CurrentCamera
		local camPos = cam and cam.CFrame.Position
		acc += dt
		local slow = acc >= 0.5
		if slow then
			acc = 0
		end
		for _, d in pairs(padBosses) do
			if slow and d.entry and not (d.boss and d.boss.Parent) then
				ensureBoss(d)
			end
			local m = d.boss
			if m and m.Parent then
				local target = d.frozen or patrolCF(d, t)
				if target then
					local dist = if camPos then (camPos - target.Position).Magnitude else 0
					if slow and not d.frozen and not d.winHold then
						-- idle loops only near the camera (24 bosses are not 24 animations)
						local running = BossMoves.restPivot(m) ~= nil
						if dist < LOD_NEAR and not running then
							BossMoves.startPadIdle(m)
						elseif dist > LOD_FAR and running then
							BossMoves.stop(m)
						end
					end
					if dist < DRAW_MAX or d.frozen or d.winHold then
						place(d, d.frozen or target)
					end
				end
			end
		end
	end)
end

return V
