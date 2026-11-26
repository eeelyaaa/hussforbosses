--!strict
-- Systems/Plots: the base plots for 8 players and the stand-in second player (brief systems 7 and 10; m2-contract.md
-- G "Steal2", M2-02 S8, S9; vault pattern stand-ins-through-module-seams.md).
--
-- Fill order (base-layout.md, TEAM CALL): 1, 8, 4, 5, 2, 7, 3, 6 (Config.Steal.PLOT_FILL_ORDER). `Plots.pick(list)` is
-- the rule. Data/Session (M2-09's file) still assigns real players by itself, lowest PlotId first; it calls
-- `Plots.pick` once its one-line seam lands (requested in verification/m2-15-steal-shield.md). With only Plot1 in the
-- place until M3 builds the hub, both give the same plot.
--
-- Who owns a plot, for every wave B system: `Plots.of(player)` (the player's plot, nil when it has none: S8, the
-- caller refuses 'state'), `Plots.ownerOf(plot)` (the real player or stand-in with a profile, or nil),
-- `Plots.byId(plotId)`, `Plots.byUserId(userId)`, `Plots.players()` (real players and stand-ins with a profile).
--
-- The stand-in seam (Studio only; S9: user ids <= 0, memory store only through Session.standIn):
--   Plots.seam.addPlayer(userId, opts?) -> fake   a profile, the next free plot in fill order, a character (an anchored
--                                                 HumanoidRootPart + Humanoid at the plot's spawn); opts.shield =
--                                                 "joining" (default) | "ready"
--   Plots.seam.removePlayer(fake) -> status       the leave path (Session.removeStandIn), the plot freed
--   Plots.seam.moveTo(who, pos)                   puts a stand-in (or a real player's character) at pos, movement
--                                                 checks restarted (a check's teleport, not the player's)
--   Plots.seam.walkTo(who, pos, speed?) -> bool   walks there in Heartbeat steps at `speed` (default the carry speed
--                                                 when carrying, else 16): what the movement checks see. Yields.
-- The Steal2 hook drives the same entry points the remotes call ('add <id>', 'hold <id> <plotId> <uid>',
-- 'cancel <id>', 'home <id>', 'punch <from> <to>', 'remove <id>'); result in TestHooks.reports.steal2.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local TestHooks = require(Shared.TestHooks)
local Session = require(script.Parent.Parent.Data.Session)

local Plots = {}

Plots.FILL_ORDER = Config.Steal.PLOT_FILL_ORDER

-- stand-in -> its plot; userId -> stand-in
local standPlots: { [any]: Model } = {}
local standIns: { [number]: any } = {}

function Plots.all(): { Model }
	local out = {}
	local root = workspace:FindFirstChild("Plots")
	if root then
		for _, m in ipairs(root:GetChildren()) do
			if m:IsA("Model") and typeof(m:GetAttribute("PlotId")) == "number" then
				table.insert(out, m)
			end
		end
	end
	return out
end

function Plots.byId(plotId: any): Model?
	if typeof(plotId) ~= "number" then
		return nil
	end
	for _, m in ipairs(Plots.all()) do
		if m:GetAttribute("PlotId") == plotId then
			return m
		end
	end
	return nil
end

-- Pure: the first free plot (OwnerUserId 0) in fill order; plots whose id is not in the order come after, lowest
-- id first. `list` holds plot models or tables { PlotId, OwnerUserId } (the check's fakes).
local function attr(m: any, k: string): any
	if typeof(m) == "Instance" then
		return m:GetAttribute(k)
	end
	return m[k]
end
function Plots.rank(plotId: number): number
	local i = table.find(Plots.FILL_ORDER, plotId)
	return if i then i else #Plots.FILL_ORDER + plotId
end
function Plots.pick(list: { any }): any?
	local best, bestRank = nil, math.huge
	for _, m in ipairs(list) do
		local id = attr(m, "PlotId")
		if typeof(id) == "number" and (attr(m, "OwnerUserId") or 0) == 0 then
			local r = Plots.rank(id)
			if r < bestRank then
				best, bestRank = m, r
			end
		end
	end
	return best
end

function Plots.isStandIn(p: any): boolean
	return type(p) == "table" and standPlots[p] ~= nil
end

-- The plot this player owns now (nil when none: S8).
function Plots.of(player: any): Model?
	local plot = standPlots[player] or (typeof(player) == "Instance" and Session.plot(player)) or nil
	if plot and plot.Parent and plot:GetAttribute("OwnerUserId") == player.UserId then
		return plot
	end
	return nil
end

function Plots.byUserId(userId: any): any?
	if typeof(userId) ~= "number" then
		return nil
	end
	if userId <= 0 then
		return standIns[userId]
	end
	return Players:GetPlayerByUserId(userId)
end

-- The plot's owner if it is in the server with a profile.
function Plots.ownerOf(plot: Model?): any?
	if not plot then
		return nil
	end
	local who = Plots.byUserId(plot:GetAttribute("OwnerUserId"))
	if who and Session.get(who) and Plots.of(who) == plot then
		return who
	end
	return nil
end

-- Real players and stand-ins that have a profile.
function Plots.players(): { any }
	local out = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if Session.get(p) then
			table.insert(out, p)
		end
	end
	for _, f in pairs(standIns) do
		if Session.get(f) then
			table.insert(out, f)
		end
	end
	return out
end

function Plots.root(who: any): BasePart?
	local c = who and who.Character
	local hum = c and c:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return nil
	end
	local r = c:FindFirstChild("HumanoidRootPart")
	return if r and r:IsA("BasePart") then r else nil
end

-- ------------------------------------------------------------------------------------------------ the seam (Studio)
local joinFns: { (any, { [string]: any }) -> () } = {}
local leaveFns: { (any) -> () } = {}
-- Systems/Shield and Steal: called when a stand-in gets / loses its plot (real players come through Session).
function Plots.onStandIn(joined: (any, { [string]: any }) -> (), left: (any) -> ())
	table.insert(joinFns, joined)
	table.insert(leaveFns, left)
end

Plots.seam = nil :: any
if RunService:IsStudio() then
	local seam = {}

	local function makeCharacter(fake: any, at: CFrame)
		local m = Instance.new("Model")
		m.Name = fake.Name
		local r = Instance.new("Part")
		r.Name = "HumanoidRootPart"
		r.Size = Vector3.new(2, 2, 1)
		r.Anchored = true
		r.CanCollide = false
		r.CanQuery = false
		r.Transparency = 0.5
		r.CFrame = at
		r.Parent = m
		local h = Instance.new("Humanoid")
		h.Parent = m
		m.PrimaryPart = r
		m:SetAttribute("HFB_StandIn", fake.UserId)
		m.Parent = workspace
		return m
	end

	function seam.addPlayer(userId: number, opts: { [string]: any }?): any
		assert(RunService:IsStudio(), "Plots.seam is Studio only")
		assert(typeof(userId) == "number" and userId <= 0 and userId % 1 == 0, "Plots.seam.addPlayer: user id must be an int <= 0 (S9)")
		assert(standIns[userId] == nil, "Plots.seam.addPlayer: stand-in exists")
		local plot = Plots.pick(Plots.all())
		assert(plot, "Plots.seam.addPlayer: no free plot")
		local fake = Session.standIn(userId)
		standIns[userId] = fake
		plot:SetAttribute("OwnerUserId", userId)
		standPlots[fake] = plot
		local sp = plot:FindFirstChild("SpawnPoint")
		local at = if sp and sp:IsA("BasePart") then sp.CFrame + Vector3.new(0, sp.Size.Y / 2 + 3, 0) else plot:GetPivot()
		fake.Character = makeCharacter(fake, at)
		for _, fn in ipairs(joinFns) do
			local ok, err = pcall(fn, fake, opts or {})
			if not ok then
				warn("[HFB] Plots stand-in join fn: " .. tostring(err))
			end
		end
		return fake
	end

	function seam.removePlayer(fake: any): string
		assert(RunService:IsStudio(), "Plots.seam is Studio only")
		if not standPlots[fake] then
			return "none"
		end
		local status = Session.removeStandIn(fake) -- onLeaving fns run first (a stolen boss goes back)
		for _, fn in ipairs(leaveFns) do
			pcall(fn, fake)
		end
		local plot = standPlots[fake]
		if plot and plot:GetAttribute("OwnerUserId") == fake.UserId then
			plot:SetAttribute("OwnerUserId", 0)
		end
		standPlots[fake] = nil
		standIns[fake.UserId] = nil
		if fake.Character then
			fake.Character:Destroy()
			fake.Character = nil
		end
		return status
	end

	function seam.moveTo(who: any, pos: Vector3)
		local c = who.Character
		if not c then
			return
		end
		local r = c:FindFirstChild("HumanoidRootPart") :: BasePart?
		c:PivotTo(CFrame.new(pos) * (if r then r.CFrame.Rotation else CFrame.identity))
		if r then
			r.AssemblyLinearVelocity = Vector3.zero
		end
		local Carry = require(script.Parent.Carry) :: any
		Carry.resetAnchor(who)
		local Steal = script.Parent:FindFirstChild("Steal")
		if Steal then
			(require(Steal) :: any).resetChase(who)
		end
	end

	-- Walks (flat) to pos at `speed` studs/s in Heartbeat steps; false when the character went away.
	-- A real player's root is anchored for the walk, so the client's own physics (it owns its character) cannot
	-- pull it back between the server's steps.
	function seam.walkTo(who: any, pos: Vector3, speed: number?): boolean
		local Carry = require(script.Parent.Carry) :: any
		local root0 = who.Character and who.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local wasAnchored = root0 and root0.Anchored
		if root0 then
			root0.Anchored = true
		end
		local ok = seam._walk(who, pos, speed, Carry)
		if root0 and root0.Parent and not wasAnchored then
			root0.Anchored = false
		end
		return ok
	end
	function seam._walk(who: any, pos: Vector3, speed: number?, Carry: any): boolean
		while true do
			local c = who.Character
			local r = c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not c or not r then
				return false
			end
			local sp = speed or (if Carry.isCarrying(who) then Carry.speed(who) else Config.Steal.WALK)
			local dt = RunService.Heartbeat:Wait()
			local here = r.Position
			local d = Vector3.new(pos.X - here.X, 0, pos.Z - here.Z)
			local stepLen = sp * dt * 0.95
			if d.Magnitude <= stepLen then
				c:PivotTo(CFrame.new(Vector3.new(pos.X, here.Y, pos.Z)) * r.CFrame.Rotation)
				r.AssemblyLinearVelocity = Vector3.zero
				return true
			end
			c:PivotTo(CFrame.new(here + d.Unit * stepLen) * r.CFrame.Rotation)
			r.AssemblyLinearVelocity = Vector3.zero
		end
	end

	-- A point inside the plot (plot-local x across 0..50, y deep 0..92 from the front fence) in world space.
	function seam.plotPoint(plot: Model, x: number, y: number, height: number?): Vector3?
		local Carry = require(script.Parent.Carry) :: any
		local f = Carry.plotFrame(plot)
		if not f then
			return nil
		end
		local p = f.o + f.ex * x + f.ey * y
		return Vector3.new(p.X, height or 3, p.Z)
	end

	seam.standIns = standIns
	Plots.seam = seam
end

-- ------------------------------------------------------------------------------------------------ the Steal2 hook
local function runCommand(v: string): any
	local w = string.split(v, " ")
	local cmd = w[1]
	local Steal = require(script.Parent.Steal) :: any
	local n2, n3 = tonumber(w[2]), tonumber(w[3])
	if cmd == "add" and n2 then
		local f = Plots.seam.addPlayer(n2, { shield = w[3] })
		local plot = Plots.of(f)
		return { ok = true, userId = f.UserId, plotId = plot and plot:GetAttribute("PlotId") }
	elseif cmd == "hold" and n2 and n3 and w[4] then
		local who = Plots.byUserId(n2)
		return { ok = who ~= nil, reason = who and Steal.tryHold(who, n3, w[4]) }
	elseif cmd == "cancel" and n2 then
		local who = Plots.byUserId(n2)
		return { ok = who ~= nil, reason = who and Steal.tryCancel(who) }
	elseif cmd == "home" and n2 then
		local who = Plots.byUserId(n2)
		local plot = who and Plots.of(who)
		local inside = plot and Plots.seam.plotPoint(plot, 25, 30, (Plots.root(who) :: BasePart).Position.Y)
		return { ok = inside ~= nil and Plots.seam.walkTo(who, inside :: Vector3) }
	elseif cmd == "punch" and n2 and n3 then
		local who = Plots.byUserId(n2)
		return { ok = who ~= nil, reason = who and Steal.tryPunch(who, n3) }
	elseif cmd == "remove" and n2 then
		local who = Plots.byUserId(n2)
		return { ok = who ~= nil, status = who and Plots.seam.removePlayer(who) }
	end
	return { ok = false, reason = "bad command" }
end

function Plots.start()
	TestHooks.onSet("Steal2", function(v)
		if typeof(v) ~= "string" or not Plots.seam then
			return
		end
		task.spawn(function()
			local ok, r = pcall(runCommand, v)
			TestHooks.reports.steal2 = if ok then r else { ok = false, reason = tostring(r) }
			TestHooks.reports.steal2.command = v
		end)
	end)
end

return Plots
