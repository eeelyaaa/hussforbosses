--!strict
-- Systems/Shield: the lock shield of each owned plot (brief system 10 "Lock shield"; m2-contract.md C "Shield").
--
-- States per plot: joining (the 60 s shield on joining, unbreakable) | up (raised by the lock pad or Shield.Raise;
-- 60 s, 90 s with Long Lock) | instant (Instant Shield, 60 s, unbreakable, works in the cooldown) | cooldown (60 s
-- after any shield drops or is broken) | ready. A shield in up, joining or instant keeps everybody but the owner out:
-- they are pushed out at the entrance every Heartbeat; when it rises, holds on that plot are cancelled and a boss
-- lifted but still inside goes back (Systems/Steal, through Shield.onRaised).
-- Shield Breaker: a visitor within BREAK_RANGE of the plot's edge breaks an `up` shield that was not broken in the
-- last BREAK_LOCK_S (300 s); the shield drops into the normal cooldown; the owner gets Shield.Broken.
-- Saved: shieldReadyAt (when the shield can next be raised), so a rejoin does not reset the cooldown. On joining the
-- base starts with the joining shield, then the cooldown; a saved later readyAt wins. A rebirth resets it (M2-14
-- writes 0; Rebirth.onRebirth clears the in-memory cooldown here).
-- Clock: server time + the ShieldClock hook (Studio), for the shield, the 60 s safe time and the break timer.
--
-- c2s: Shield.Raise {}, UseCharge { plotId }, BuyBreaker { plotId }. s2c: Shield.State (all), Broken (owner), Result.
-- For M2-18: Shield.isUp(player), Shield.raiseInstant(player) -> boolean, Shield.takeBreakerTarget(player) -> held?,
-- Shield.canBreakTarget(held) -> boolean, Shield.breakFor(player, held) -> boolean (false: store one charge instead).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local TestHooks = require(Shared.TestHooks)
local Session = require(script.Parent.Parent.Data.Session)
local Plots = require(script.Parent.Plots)
local Carry = require(script.Parent.Carry)
local Bag = require(script.Parent.Bag)

local Shield = {}

type S = {
	plot: Model,
	owner: any,
	state: string, -- "joining" | "up" | "instant" | "cooldown" | "ready"
	endsAt: number?,
	readyAt: number?,
	brokenUntil: number?,
	brokenAt: number?,
	brokenBy: number?,
}

local shields: { [Model]: S } = {}
local raisedFns: { (Model, string) -> () } = {}
-- player -> { plotId, ownerUserId, at } held for the Shield Breaker receipt ([M2-02 M3])
local breakerTargets: { [any]: { plotId: number, ownerUserId: number, at: number } } = {}

Shield.stats = { results = {} :: { any }, pushed = 0, broken = {} :: { any }, raised = {} :: { any } }

function Shield.clock(): number
	local h = TestHooks.get("ShieldClock")
	return workspace:GetServerTimeNow() + (if typeof(h) == "number" then h else 0)
end

local UP = { up = true, joining = true, instant = true }

function Shield.get(plot: Model?): S?
	return plot and shields[plot] or nil
end

function Shield.stateOf(plot: Model?): string
	local s = plot and shields[plot]
	return if s then s.state else "none"
end

function Shield.isUpPlot(plot: Model?): boolean
	local s = plot and shields[plot]
	return s ~= nil and UP[s.state] == true
end

function Shield.isUp(player: any): boolean
	return Shield.isUpPlot(Plots.of(player))
end

-- Breakable now? (ok, reason) with reason 'joining' | 'instant' | 'recent' | 'down' (Net: Shield.State).
function Shield.breakable(plot: Model?): (boolean, string?)
	local s = plot and shields[plot]
	if not s then
		return false, "down"
	end
	if s.state == "joining" then
		return false, "joining"
	elseif s.state == "instant" then
		return false, "instant"
	elseif s.state ~= "up" then
		return false, "down"
	end
	if s.brokenUntil and Shield.clock() < s.brokenUntil then
		return false, "recent"
	end
	return true, nil
end

function Shield.payload(plot: Model): any
	local s = shields[plot]
	local ok, why = Shield.breakable(plot)
	local brokenUntil = s and s.brokenUntil
	if brokenUntil and Shield.clock() >= brokenUntil then
		brokenUntil = nil
	end
	return {
		plotId = plot:GetAttribute("PlotId"),
		state = if s then s.state else "ready",
		endsAt = s and UP[s.state] and s.endsAt or nil,
		readyAt = s and s.state == "cooldown" and s.readyAt or nil,
		breakable = ok,
		reason = why,
		brokenUntil = brokenUntil,
		ownerUserId = if s then s.owner.UserId else 0,
	}
end

local function broadcast(plot: Model)
	Net.fireAll("Shield", "State", Shield.payload(plot))
end

local function result(player: any, action: string, reason: string?, plotId: number?): string?
	table.insert(Shield.stats.results, { userId = player.UserId, action = action, ok = reason == nil, reason = reason, plotId = plotId })
	if #Shield.stats.results > 200 then
		table.remove(Shield.stats.results, 1)
	end
	if typeof(player) == "Instance" and player.Parent == Players then
		Net.fire("Shield", "Result", player, { action = action, ok = reason == nil, reason = reason, plotId = plotId })
	end
	return reason
end

local function saveReadyAt(owner: any, readyAt: number)
	Session.mutate(owner, function(q)
		q.shieldReadyAt = math.max(0, readyAt)
	end)
end

function Shield.onRaised(fn: (Model, string) -> ())
	table.insert(raisedFns, fn)
end

local function setUp(s: S, state: string, seconds: number, how: string)
	local now = Shield.clock()
	s.state = state
	s.endsAt = now + seconds
	s.readyAt = nil
	table.insert(Shield.stats.raised, { plotId = s.plot:GetAttribute("PlotId"), state = state, how = how, at = now })
	if #Shield.stats.raised > 100 then
		table.remove(Shield.stats.raised, 1)
	end
	for _, fn in ipairs(table.clone(raisedFns)) do
		local ok, err = pcall(fn, s.plot, how)
		if not ok then
			warn("[HFB] Shield.onRaised fn: " .. tostring(err))
		end
	end
	broadcast(s.plot)
end

local function upSeconds(owner: any): number
	return if Bag.owns(owner, Config.Shield.LONG_PASS) then Config.Shield.LONG_UP_S else Config.Shield.UP_S
end

-- Raises the owner's shield if it is ready. how: "pad" | "button". Returns nil or a refusal reason.
function Shield.raise(owner: any, how: string): string?
	local plot = Plots.of(owner)
	local s = plot and shields[plot]
	if not s then
		return "state"
	end
	if s.state ~= "ready" then
		return "state"
	end
	setUp(s, "up", upSeconds(owner), how)
	return nil
end

-- Instant Shield (M2-18 calls it after the receipt's write): a 60 s unbreakable shield at once, even in the cooldown;
-- a shield already up becomes an Instant Shield and restarts at 60 s (brief 10). False when the player has no plot.
function Shield.raiseInstant(owner: any): boolean
	local plot = Plots.of(owner)
	local s = plot and shields[plot]
	if not s then
		return false
	end
	setUp(s, "instant", Config.Shield.INSTANT_S, "instant")
	return true
end

local function toCooldown(s: S, from: number)
	s.state = "cooldown"
	s.endsAt = nil
	s.readyAt = from + Config.Shield.COOLDOWN_S
	saveReadyAt(s.owner, s.readyAt :: number)
	broadcast(s.plot)
end

-- Breaks a breakable shield by `by` (a visitor). Returns true when it broke.
local function doBreak(plot: Model, by: any): boolean
	local s = shields[plot]
	if not s or not Shield.breakable(plot) then
		return false
	end
	local now = Shield.clock()
	s.brokenUntil = now + Config.Shield.BREAK_LOCK_S
	s.brokenAt = now
	s.brokenBy = by.UserId
	table.insert(Shield.stats.broken, { plotId = plot:GetAttribute("PlotId"), by = by.UserId, at = now })
	toCooldown(s, now)
	if typeof(s.owner) == "Instance" and s.owner.Parent == Players then
		Net.fire("Shield", "Broken", s.owner, { plotId = plot:GetAttribute("PlotId"), byUserId = by.UserId })
	end
	return true
end

-- The owner's shield-broken alert is on (Base.setAlertCheck, M2-18's no-prompt rule).
function Shield.brokenAlertOn(owner: any): boolean
	local plot = Plots.of(owner)
	local s = plot and shields[plot]
	return s ~= nil and s.brokenAt ~= nil and Shield.clock() - s.brokenAt < Config.Shield.BROKEN_ALERT_S
end

-- Flat distance from a world position to the plot's 50 x 92 (0 inside).
function Shield.distToPlot(plot: Model, pos: Vector3): number?
	local x, y = Carry.plotLocal(plot, pos)
	if not x or not y then
		return nil
	end
	local dx = math.max(0, -x, x - Config.Base.PLOT_W)
	local dy = math.max(0, -y, y - Config.Base.PLOT_D)
	return math.sqrt(dx * dx + dy * dy)
end

-- The common checks of UseCharge and BuyBreaker. Returns (plot, nil) or (nil, reason).
local function breakerChecks(player: any, plotId: any): (Model?, string?)
	if not Net.isInt(plotId, 1, 64) then
		return nil, "state"
	end
	local plot = Plots.byId(plotId)
	if not plot or not Session.get(player) or Plots.of(player) == plot or not Plots.ownerOf(plot) then
		return nil, "state"
	end
	local r = Plots.root(player)
	local d = r and Shield.distToPlot(plot, r.Position)
	if not d or d > Config.Shield.BREAK_RANGE then
		return nil, "range"
	end
	local ok, why = Shield.breakable(plot)
	if not ok then
		return nil, if why == "down" then "state" else why
	end
	return plot, nil
end

function Shield.tryUseCharge(player: any, plotId: any): string?
	local plot, why = breakerChecks(player, plotId)
	if not plot then
		return result(player, "useCharge", why, if typeof(plotId) == "number" then plotId else nil)
	end
	local p = Session.get(player)
	if not p or (p.breakerCharges or 0) < 1 then
		return result(player, "useCharge", "charge", plotId)
	end
	if not Session.mutate(player, function(q)
		assert(q.breakerCharges >= 1, "no charge")
		q.breakerCharges -= 1
	end) then
		return result(player, "useCharge", "state", plotId)
	end
	doBreak(plot, player)
	return result(player, "useCharge", nil, plotId)
end

-- The Shop's prompt seam (M2-18): Systems/Shop.prompt(player, key, ctx) -> boolean. Absent: refused 'busy'.
local function shopPrompt(player: any, ctx: any): boolean
	local m = script.Parent:FindFirstChild("Shop")
	if not m then
		return false
	end
	local ok, Shop = pcall(require, m)
	if not ok or type(Shop) ~= "table" or type((Shop :: any).prompt) ~= "function" then
		return false
	end
	local ok2, v = pcall((Shop :: any).prompt, player, "product_shield_breaker", ctx)
	return ok2 and v == true
end

function Shield.tryBuyBreaker(player: any, plotId: any): string?
	local plot, why = breakerChecks(player, plotId)
	if not plot then
		return result(player, "buyBreaker", why, if typeof(plotId) == "number" then plotId else nil)
	end
	local s = shields[plot] :: S
	local held = { plotId = plotId, ownerUserId = s.owner.UserId, at = Shield.clock() }
	breakerTargets[player] = held
	if not shopPrompt(player, held) then
		breakerTargets[player] = nil
		return result(player, "buyBreaker", "busy", plotId)
	end
	return result(player, "buyBreaker", nil, plotId)
end

-- M2-18 (the receipt): the target held when the server prompted, once (nil when none: a client-opened prompt).
function Shield.takeBreakerTarget(player: any): { plotId: number, ownerUserId: number, at: number }?
	local h = breakerTargets[player]
	breakerTargets[player] = nil
	return h
end

-- Is the held target still that owner's plot and breakable now ([M2-02 M3])?
function Shield.canBreakTarget(held: any): boolean
	if type(held) ~= "table" then
		return false
	end
	local plot = Plots.byId(held.plotId)
	local owner = Plots.ownerOf(plot)
	return plot ~= nil and owner ~= nil and owner.UserId == held.ownerUserId and (Shield.breakable(plot)) == true
end

-- After the receipt's write: breaks the held target for `player`. False = not breakable now: store one charge.
function Shield.breakFor(player: any, held: any): boolean
	if not Shield.canBreakTarget(held) then
		return false
	end
	return doBreak(Plots.byId(held.plotId) :: Model, player)
end

-- ------------------------------------------------------------------------------------------------ owners
local function readyAtFor(owner: any, now: number): number
	local p = Session.get(owner)
	local saved = p and typeof(p.shieldReadyAt) == "number" and p.shieldReadyAt or 0
	return math.max(saved, now + Config.Shield.JOIN_S + Config.Shield.COOLDOWN_S)
end

-- The owner is in the server with a plot: the joining shield (opts.shield = "ready" skips it; checks only).
function Shield.ownerJoined(owner: any, opts: { [string]: any }?)
	local plot = Plots.of(owner)
	if not plot then
		return
	end
	local now = Shield.clock()
	local s: S = { plot = plot, owner = owner, state = "joining", endsAt = now + Config.Shield.JOIN_S }
	local saved = readyAtFor(owner, now)
	shields[plot] = s
	if opts and opts.shield == "ready" and RunService:IsStudio() then
		s.state, s.endsAt, s.readyAt = "ready", nil, nil
		broadcast(plot)
		return
	end
	s.readyAt = saved -- held while joining; the cooldown ends at the later of the two
	setUp(s, "joining", Config.Shield.JOIN_S, "join")
	s.readyAt = saved
end

function Shield.ownerLeft(owner: any)
	for plot, s in pairs(shields) do
		if s.owner == owner then
			shields[plot] = nil
			breakerTargets[owner] = nil
			if plot.Parent then
				broadcast(plot)
			end
		end
	end
	breakerTargets[owner] = nil
end

-- A rebirth writes shieldReadyAt = 0 (M2-14): the in-memory cooldown goes too.
function Shield.resetCooldown(owner: any)
	local plot = Plots.of(owner)
	local s = plot and shields[plot]
	if s and s.state == "cooldown" then
		s.state, s.readyAt = "ready", nil
		broadcast(s.plot)
	end
end

-- Studio, checks only: put a plot's shield in a state now ("ready" | "cooldown" | "up").
Shield.forceState = nil :: any
if RunService:IsStudio() then
	Shield.forceState = function(plot: Model, state: string)
		local s = shields[plot]
		if not s then
			return false
		end
		local now = Shield.clock()
		if state == "ready" then
			s.state, s.endsAt, s.readyAt = "ready", nil, nil
			broadcast(plot)
		elseif state == "cooldown" then
			toCooldown(s, now)
		elseif state == "up" then
			setUp(s, "up", upSeconds(s.owner), "check")
		end
		if state ~= "cooldown" then
			s.brokenUntil, s.brokenAt = nil, nil
		end
		return true
	end
end

-- ------------------------------------------------------------------------------------------------ the step
local function onLockPad(owner: any, plot: Model): boolean
	local pad = plot:FindFirstChild("LockPad")
	local r = Plots.root(owner)
	if not (pad and pad:IsA("BasePart") and r) then
		return false
	end
	local rel = pad.CFrame:PointToObjectSpace(r.Position)
	local above = rel.Y - pad.Size.Y / 2
	return math.abs(rel.X) <= pad.Size.X / 2 and math.abs(rel.Z) <= pad.Size.Z / 2 and above >= -1 and above <= Config.Shield.PAD_HEIGHT
end

local function pushOut(who: any, plot: Model, r: BasePart)
	local f = Carry.plotFrame(plot)
	if not f then
		return
	end
	local x = Carry.plotLocal(plot, r.Position) :: number
	-- out through the entrance (plot x 19..31), a little to the side the visitor stands on
	local ox = math.clamp(x, 20, 30)
	local p = f.o + f.ex * ox - f.ey * Config.Shield.PUSH_OUT
	local c = who.Character :: Model
	c:PivotTo(CFrame.new(Vector3.new(p.X, r.Position.Y, p.Z)) * r.CFrame.Rotation)
	r.AssemblyLinearVelocity = Vector3.zero
	Carry.resetAnchor(who)
	Shield.stats.pushed += 1
end

local function step()
	local now = Shield.clock()
	local everyone: { any }? = nil
	for plot, s in pairs(shields) do
		if not plot.Parent or Plots.of(s.owner) ~= plot then
			shields[plot] = nil
			continue
		end
		if UP[s.state] and now >= (s.endsAt :: number) then
			local ends = s.endsAt :: number
			local later = s.readyAt
			toCooldown(s, ends)
			if later and later > (s.readyAt :: number) then -- the joining shield's saved cooldown
				s.readyAt = later
				saveReadyAt(s.owner, later)
				broadcast(plot)
			end
		elseif s.state == "cooldown" and now >= (s.readyAt :: number) then
			s.state, s.readyAt = "ready", nil
			broadcast(plot)
		end
		if s.state == "ready" and onLockPad(s.owner, plot) then
			setUp(s, "up", upSeconds(s.owner), "pad")
		end
		if UP[s.state] then
			everyone = everyone or Plots.players()
			for _, who in ipairs(everyone :: { any }) do
				if who ~= s.owner then
					local r = Plots.root(who)
					if r and Carry.insidePlot(plot, r.Position, -Config.Shield.INSIDE_MARGIN) then
						pushOut(who, plot, r)
					end
				end
			end
		end
	end
end

function Shield.start()
	Net.onServerEvent("Shield", "Raise", function(player, _payload)
		if not Plots.of(player) or not Carry.insideOwnPlot(player) then
			result(player, "raise", "state")
			return
		end
		result(player, "raise", Shield.raise(player, "button"))
	end)
	Net.onServerEvent("Shield", "UseCharge", function(player, payload)
		Shield.tryUseCharge(player, payload.plotId)
	end)
	Net.onServerEvent("Shield", "BuyBreaker", function(player, payload)
		Shield.tryBuyBreaker(player, payload.plotId)
	end)

	Session.onJoin(function(player)
		Shield.ownerJoined(player)
		for _, plot in ipairs(Plots.all()) do
			if typeof(player) == "Instance" and player.Parent == Players then
				Net.fire("Shield", "State", player, Shield.payload(plot))
			end
		end
	end)
	Session.onLeaving(Shield.ownerLeft)
	Players.PlayerRemoving:Connect(function(p)
		Shield.ownerLeft(p)
	end)
	Plots.onStandIn(function(fake, opts)
		Shield.ownerJoined(fake, opts)
	end, Shield.ownerLeft)

	local rb = script.Parent:FindFirstChild("Rebirth")
	if rb then
		local ok, Rebirth = pcall(require, rb)
		if ok and type(Rebirth) == "table" and type((Rebirth :: any).onRebirth) == "function" then
			(Rebirth :: any).onRebirth(function(player)
				Shield.resetCooldown(player)
			end)
		end
	end

	-- SetCharges (state hook, Studio): breakerCharges of every real player becomes this.
	TestHooks.onSet("SetCharges", function(v)
		if not Net.isInt(v, 0, 1e6) then
			warn("[HFB] hook SetCharges ignored: " .. tostring(v))
			return
		end
		for _, p in ipairs(Players:GetPlayers()) do
			Session.mutate(p, function(q)
				q.breakerCharges = v
			end)
		end
	end)

	RunService.Heartbeat:Connect(step)
end

return Shield
