--!strict
-- Systems/Bag: the own bag pad, Power per bag punch, buying Punch Strength (30 levels) and Punch Speed (10 levels), the
-- six bag tiers, and the Bag.State the bag sign draws (brief systems 2 and 3; m2-contract.md C "Bag", D).
-- Systems/Punch decides when a beat applies; this module decides what it is worth and applies it through Data/Session.
-- Auto Punch's remotes and report rules are Systems/AutoPunch; the toggles and the pass cache live here (Bag.State
-- carries them, and AutoPunch requires this module, not the other way round).
--
-- The server decides (brief 2): every Power gain, every level bought (cost checked and taken here), whether the player
-- is on their own bag pad. No remote carries a price, a level or an amount (contract C).
-- Remotes handled: Bag.BuyStrength, Bag.BuySpeed ({}). Sent: Bag.State (owner: on join, on spawn, on entering the pad,
-- on any change; the client can miss the join one, so spawn and pad entry resend it: M2-13), Bag.Result (owner).
-- The bag tier is the plot's attribute BagTier (1..6, Ids.BAGS): the client and the skin pick the model by that id.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local TestHooks = require(Shared.TestHooks)
local Session = require(script.Parent.Parent.Data.Session)
local Funnel = require(script.Parent.Funnel)

local Bag = {}

-- Studs above the pad's top the root may be and still count as standing on it (a jump stays on the pad).
local PAD_HEIGHT = 8

-- What checks read.
Bag.stats = { bought = {} :: { any }, refused = {} :: { [string]: number }, states = 0, lastResult = {} :: { [number]: any }, lastState = {} :: { [number]: any } }

local function root(player: Player): BasePart?
	local c = player.Character
	local hum = c and c:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return nil
	end
	local r = c and c:FindFirstChild("HumanoidRootPart")
	return if r and r:IsA("BasePart") then r else nil
end
Bag.root = root

local function ownPad(player: Player): BasePart?
	local plot = Session.plot(player)
	if not plot or plot:GetAttribute("OwnerUserId") ~= player.UserId then
		return nil
	end
	local pad = plot:FindFirstChild("BagPad")
	return if pad and pad:IsA("BasePart") then pad else nil
end

-- Ground-plane distance from the own bag pad's centre and height above its top, or nil.
local function fromPad(player: Player): (number?, number?)
	local pad, r = ownPad(player), root(player)
	if not pad or not r then
		return nil, nil
	end
	local d = r.Position - pad.Position
	return Vector3.new(d.X, 0, d.Z).Magnitude, r.Position.Y - (pad.Position.Y + pad.Size.Y / 2)
end

-- True when the player stands on the bag pad of the plot they own.
function Bag.onOwnPad(player: Player): boolean
	local flat, above = fromPad(player)
	return flat ~= nil and above ~= nil and flat <= Config.Bag.PAD_RADIUS and above >= -1 and above <= PAD_HEIGHT
end

-- True within Config.Bag.PAD_RANGE of the own bag pad (the bag sign: buying levels).
function Bag.nearOwnPad(player: Player): boolean
	local flat, above = fromPad(player)
	return flat ~= nil and above ~= nil and flat <= Config.Bag.PAD_RANGE and above >= -4 and above <= PAD_HEIGHT + 4
end

-- ---------------------------------------------------------------- passes (read from the cache, never yield: C/S5)
-- Systems/Passes (M2-18) is the owner of pass ownership; until it exists this module keeps its own cache: filled on
-- join with UserOwnsGamePassAsync (pcall; a failure is "not owned"), re-asked after PromptGamePassPurchaseFinished,
-- and overridden in Studio by the PassOwned hook ('<key>=on|off,...').
local passCache: { [Player]: { [string]: boolean } } = {}
local PASS_KEYS = { "pass_auto_punch", "pass_perfect_auto_punch", "pass_2x_power" }

local passesMod: any = nil
local function passes(): any
	if passesMod == nil then
		local m = script.Parent:FindFirstChild("Passes")
		passesMod = false
		if m and m:IsA("ModuleScript") then
			local ok, P = pcall(require, m)
			if ok and type(P) == "table" and type((P :: any).owns) == "function" then
				passesMod = P
			end
		end
	end
	return if passesMod then passesMod else nil
end

local function hookOwned(key: string): boolean?
	local v = TestHooks.get("PassOwned")
	if typeof(v) ~= "string" then
		return nil
	end
	for k, state in string.gmatch(v, "([%w_]+)%s*=%s*(%a+)") do
		if k == key then
			return state == "on"
		end
	end
	return nil
end

-- Does the player own the pass? Never yields.
function Bag.owns(player: Player, key: string): boolean
	local P = passes()
	if P then
		return P.owns(player, key) == true
	end
	local h = hookOwned(key)
	if h ~= nil then
		return h
	end
	local c = passCache[player]
	return c ~= nil and c[key] == true
end

local function passId(key: string): number
	local ids = (Config :: any).Shop and (Config :: any).Shop.IDS
	local id = ids and ids[key]
	return if typeof(id) == "number" then id else 0
end

local function askRoblox(player: Player, key: string): boolean
	local id = passId(key)
	if id <= 0 then
		return false
	end
	local ok, owned = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, id)
	return ok and owned == true
end

-- ---------------------------------------------------------------- toggles (per session, off on join: contract C)
export type Toggles = { auto: boolean, perfect: boolean }
local toggles: { [Player]: Toggles } = {}
function Bag.toggles(player: Player): Toggles
	local t = toggles[player]
	if not t then
		t = { auto = false, perfect = false }
		toggles[player] = t
	end
	return t
end
-- Auto Punch is usable: Auto Punch owned, or Perfect Auto Punch owned (it includes everything Auto Punch does, brief 2).
function Bag.autoOwned(player: Player): boolean
	return Bag.owns(player, Config.AutoPunch.PASS) or Bag.owns(player, Config.AutoPunch.PERFECT_PASS)
end
function Bag.perfectOwned(player: Player): boolean
	return Bag.owns(player, Config.AutoPunch.PERFECT_PASS)
end

-- ---------------------------------------------------------------- values
local function rebirthMult(p: any): number
	local n = if p and typeof(p.rebirths) == "number" then p.rebirths else 0
	local R = (Config :: any).Rebirth
	if R and type(R.POWER_MULT) == "function" then
		return R.POWER_MULT(n)
	end
	return 1 + n -- brief system 12: bag Power x(1 + rebirths)
end

-- The multiplier on every bag punch: rebirth x 2x Power pass (brief system 2's formula).
function Bag.mult(player: Player): number
	local p = Session.get(player)
	return rebirthMult(p) * (if Bag.owns(player, "pass_2x_power") then 2 else 1)
end

-- Value of punch n (1..3) of a burst on the bag (an untimed tap is n = 1).
function Bag.value(player: Player, grade: string, n: number): number
	local p = Session.get(player)
	local level = if p then p.strengthLevel else Config.Bag.DEFAULT_STRENGTH
	local gv = Config.Punch.GRADE_VALUE[grade] or 0
	return Config.Bag.STRENGTH_VALUE(level) * gv * (if n == 3 then Config.Punch.BIG_MULT else 1) * Bag.mult(player)
end

function Bag.gains(player: Player, grade: string): { number }
	return { Bag.value(player, grade, 1), Bag.value(player, grade, 2), Bag.value(player, grade, 3) }
end

-- Applies one bag punch; returns the value added. Power only rises (brief 3): nothing in this module lowers it.
function Bag.applyBeat(player: Player, grade: string, n: number): number
	local p = Session.get(player)
	if not p then
		return 0
	end
	local v = Bag.value(player, grade, n)
	if v > 0 then
		Session.set(player, "power", p.power + v)
	end
	return v
end

-- ---------------------------------------------------------------- Session seams (contract D API, M1 fallback)
-- Data/Session M2 (M2-09) has spendCash / addCash / mutate; the M1 facade has set only. Both are sync.
local S = Session :: any

-- ---------------------------------------------------------------- Bag.State
function Bag.statePayload(player: Player): any
	local p = Session.get(player)
	local str = if p then p.strengthLevel else Config.Bag.DEFAULT_STRENGTH
	local spd = if p then p.speedLevel else Config.Bag.DEFAULT_SPEED
	local t = Bag.toggles(player)
	return {
		tier = Config.Bag.TIER(str),
		strengthLevel = str,
		speedLevel = spd,
		nextStrengthCost = Config.Bag.nextStrengthCost(str),
		nextSpeedCost = Config.Bag.nextSpeedCost(spd),
		autoOn = t.auto,
		perfectOn = t.perfect,
		autoOwned = Bag.autoOwned(player),
		perfectOwned = Bag.perfectOwned(player),
	}
end

local function setTier(player: Player)
	local plot = Session.plot(player)
	local p = Session.get(player)
	if plot and p and plot:GetAttribute("OwnerUserId") == player.UserId then
		plot:SetAttribute("BagTier", Config.Bag.TIER(p.strengthLevel))
	end
end

function Bag.sendState(player: Player)
	if player.Parent ~= Players or not Session.get(player) then
		return
	end
	setTier(player)
	Bag.stats.states += 1
	local payload = Bag.statePayload(player)
	Bag.stats.lastState[player.UserId] = payload
	Net.fire("Bag", "State", player, payload)
end

function Bag.result(player: Player, action: string, ok: boolean, reason: string?, level: number?)
	if not ok and reason then
		Bag.stats.refused[reason] = (Bag.stats.refused[reason] or 0) + 1
	end
	local payload = { action = action, ok = ok, reason = reason, level = level }
	Bag.stats.lastResult[player.UserId] = payload
	if player.Parent == Players then
		Net.fire("Bag", "Result", player, payload)
	end
end

-- ---------------------------------------------------------------- buying levels
-- Check seams (the handlers after Net's limiter): Bag.buyStrength(player, payload), Bag.buySpeed(player, payload).
local function buy(player: Player, which: string)
	local action = if which == "strengthLevel" then "buyStrength" else "buySpeed"
	local p = Session.get(player)
	if not p or root(player) == nil then
		return Bag.result(player, action, false, "state")
	end
	if not Bag.nearOwnPad(player) then
		return Bag.result(player, action, false, "place")
	end
	local level = (p :: any)[which] :: number
	local cost = if which == "strengthLevel" then Config.Bag.nextStrengthCost(level) else Config.Bag.nextSpeedCost(level)
	if not cost then
		return Bag.result(player, action, false, "cap", level)
	end
	if not (p.cash >= cost) then
		return Bag.result(player, action, false, "cash", level)
	end
	-- no yield from the first check to here (contract C, M2-02 S5)
	-- one mutate: the cash (with the bought-cash rule, ops.spendCash) and the level together, or nothing (M2-27 SF4)
	local short = false
	local okM = Session.mutate(player, function(q: any)
		if not Session.ops.spendCash(q, cost) then
			short = true -- nothing changed in the copy: the mutate applies no change
			return
		end
		q[which] = level + 1
	end)
	if short or not okM then
		return Bag.result(player, action, false, if short then "cash" else "state", level)
	end
	table.insert(Bag.stats.bought, { userId = player.UserId, which = which, level = level + 1, cost = cost, at = os.clock() })
	if which == "strengthLevel" then
		Funnel.mark(player, "FirstStrengthBought")
	end
	Bag.result(player, action, true, nil, level + 1)
	Bag.sendState(player)
end
function Bag.buyStrength(player: Player, _payload: any)
	buy(player, "strengthLevel")
end
function Bag.buySpeed(player: Player, _payload: any)
	buy(player, "speedLevel")
end

-- ---------------------------------------------------------------- pad entry
local enterFns: { (Player) -> () } = {}
function Bag.onEnter(fn: (Player) -> ())
	table.insert(enterFns, fn)
end

local onPad: { [Player]: boolean } = {}
function Bag.isOnPad(player: Player): boolean
	return onPad[player] == true
end

local function firstBossPower(): number
	local def = Config.Zones.PADS.z1_fixed
	return Config.Zones.POWER[(def and def.creatureId) or "z1_t1"] or 25
end

local function checkPowerMilestone(player: Player)
	local p = Session.get(player)
	if p and p.power >= firstBossPower() then
		Funnel.mark(player, "ReachedFirstBossPower")
	end
end

-- Re-asks Roblox for the passes this module caches (only while Systems/Passes is absent). Yields; never in a handler.
local function refreshPasses(player: Player, keys: { string })
	if passes() then
		return
	end
	local c = passCache[player] or {}
	passCache[player] = c
	for _, k in ipairs(keys) do
		c[k] = askRoblox(player, k)
	end
	Bag.sendState(player)
end

function Bag.start()
	Net.onServerEvent("Bag", "BuyStrength", Bag.buyStrength)
	Net.onServerEvent("Bag", "BuySpeed", Bag.buySpeed)

	Session.onJoin(function(player)
		toggles[player] = { auto = false, perfect = false }
		Bag.sendState(player)
		checkPowerMilestone(player)
		task.spawn(refreshPasses, player, PASS_KEYS)
	end)
	local function watchSpawn(player: Player)
		player.CharacterAdded:Connect(function()
			task.wait(1) -- the client's controllers subscribe after the character loads
			Bag.sendState(player)
		end)
	end
	Players.PlayerAdded:Connect(watchSpawn)
	for _, p in ipairs(Players:GetPlayers()) do
		watchSpawn(p)
	end
	Session.onChanged(function(player, key, _v)
		if key == "strengthLevel" or key == "speedLevel" then
			Bag.sendState(player)
		elseif key == "power" then
			checkPowerMilestone(player)
		end
	end)
	-- A pass bought now: the event is a hint; Roblox's answer (retried) is the proof (contract M4).
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, purchased)
		if not purchased or passes() then
			return
		end
		for _, k in ipairs(PASS_KEYS) do
			if passId(k) == gamePassId then
				task.spawn(function()
					for _ = 1, Config.AutoPunch.VERIFY_TRIES do
						refreshPasses(player, { k })
						if passCache[player] and passCache[player][k] then
							return
						end
						task.wait(Config.AutoPunch.VERIFY_GAP_S)
					end
				end)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		onPad[p] = nil
		toggles[p] = nil
		passCache[p] = nil
	end)
	-- the PassOwned hook changes what Bag.State says (Studio)
	workspace:GetAttributeChangedSignal(TestHooks.PREFIX .. "PassOwned"):Connect(function()
		for _, p in ipairs(Players:GetPlayers()) do
			Bag.sendState(p)
		end
	end)
	-- Pad entry poll, 10 times a second (cheap: one distance per player).
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.1 then
			return
		end
		acc = 0
		for _, p in ipairs(Players:GetPlayers()) do
			local now = Bag.onOwnPad(p)
			if now and not onPad[p] then
				onPad[p] = true
				Bag.sendState(p)
				for _, fn in ipairs(enterFns) do
					task.spawn(fn, p)
				end
			elseif not now and onPad[p] then
				onPad[p] = nil
			end
		end
	end)
end

return Bag
