--!nonstrict
-- Controllers/Spin (M2-19; brief system 13, the Lucky Boss Spin; m2-contract.md C "Shop.Spin"): the client of the spin. It asks and shows;
-- the server rolls from Shared/SpinTable, takes the ticket and puts the boss in the crate. The client never predicts the result.
--   * Open / close: Spin.open() (the Spin card of the shop, the ticket counter, or the Spin screen's own entry; no key of its own in
--     docs/controls.md). Refused while the player's policy is random-items restricted: the Spin UI is hidden for them (Spin.available()).
--   * The zone picker reads the saved zonesBeaten (Profile.Changed). Spin.zones() / Spin.selectedZone() / Spin.selectZone(z).
--   * The odds list: Spin.odds() is Shared/SpinTable.ODDS itself (what is shown is what is rolled). If the screen exposes
--     Ui/Spin.oddsVisible() the spin is refused until it returns true ("odds list before any Buy or Spin button is active").
--   * Spin.spin() -> ok, reason sends Shop.Spin { zone }. Local checks only spare a round trip: policy, a zone on the list, a ticket,
--     one spin in flight, odds visible, and the shared prompt guard is NOT applied (a spin opens no Robux prompt). The result is
--     Shop.SpinResult { ok, reason?, zone, creatureId?, tier?, uid? } -> Spin.onResult(fn).
-- API: Spin.start(ctx) (AUTO_START), open, close, toggle, isOpen, available, odds, tickets, zones, selectedZone, selectZone, spin, waiting,
-- lastResult, onChange, onResult, state(), test seams _onResult/_onState/_onProfile/_noSend/_reset.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local SpinTable = require(Shared:WaitForChild("SpinTable"))

local Spin = { AUTO_START = true }

local WAIT_MAX_S = 8 -- a spin with no answer for this long may be asked again (the server has one mutate per spin)

local ctx = nil
local started = false
local opened = false
local restricted = true -- until Shop.State says otherwise (M2-27-1: a slow or failed policy check counts as restricted)
local tickets = 0
local zones: { number } = {}
local selected: number? = nil
local waitingSince: number? = nil
local waitingZone: number? = nil
local last = nil
local noSend = false
local listeners = { change = {}, result = {} }
local stats = { spinSent = 0, refusedLocal = 0, lastRefusal = nil :: string?, resultsSeen = 0 }

local function fire(list, ...)
	for _, fn in ipairs(table.clone(list)) do
		task.spawn(fn, ...)
	end
end

local function changed()
	fire(listeners.change)
end

local function ui(name: string)
	local folder = script.Parent.Parent:FindFirstChild("Ui")
	local m = folder and folder:FindFirstChild(name)
	if m and m:IsA("ModuleScript") then
		local ok, mod = pcall(require, m)
		if ok and type(mod) == "table" then
			return mod
		end
	end
	return nil
end

local function callUi(mod, method: string, ...)
	if mod and type(mod[method]) == "function" then
		local ok, res = pcall(mod[method], ...)
		if not ok then
			warn(("[HFB] Spin: Ui.%s failed: %s"):format(method, tostring(res)))
			return nil
		end
		return res
	end
	return nil
end

local function ensureSelected()
	if #zones == 0 then
		selected = nil
	elseif selected == nil or not table.find(zones, selected) then
		selected = zones[#zones] -- the furthest zone beaten
	end
end

-- ------------------------------------------------------------------ reads
-- false while the player is random-items restricted: the Spin card, the screen and the three spin products stay hidden.
function Spin.available(): boolean
	return not restricted
end
function Spin.odds()
	return SpinTable.ODDS
end
function Spin.tickets(): number
	return tickets
end
function Spin.zones(): { number }
	return table.clone(zones)
end
function Spin.selectedZone(): number?
	return selected
end
function Spin.waiting(): boolean
	if waitingSince and os.clock() - waitingSince > WAIT_MAX_S then
		waitingSince, waitingZone = nil, nil
	end
	return waitingSince ~= nil
end
function Spin.lastResult()
	return last
end
function Spin.isOpen(): boolean
	local s = ui("Spin")
	if s and type(s.isOpen) == "function" then
		local ok, v = pcall(s.isOpen)
		if ok then
			return v == true
		end
	end
	return opened
end
function Spin.onChange(fn)
	table.insert(listeners.change, fn)
end
function Spin.onResult(fn)
	table.insert(listeners.result, fn)
end

function Spin.selectZone(z: number): boolean
	if typeof(z) == "number" and table.find(zones, z) then
		selected = z
		changed()
		return true
	end
	return false
end

-- ------------------------------------------------------------------ open / close
function Spin.open(): (boolean, string?)
	if restricted then
		return false, "restricted"
	end
	if Spin.isOpen() then
		return true, nil
	end
	opened = true
	ensureSelected()
	callUi(ui("Spin"), "open")
	changed()
	return true, nil
end

function Spin.close()
	opened = false
	callUi(ui("Spin"), "close")
	changed()
end

function Spin.toggle()
	if Spin.isOpen() then
		Spin.close()
	else
		Spin.open()
	end
end

-- ------------------------------------------------------------------ spin
local function refuse(reason: string): (boolean, string)
	stats.refusedLocal += 1
	stats.lastRefusal = reason
	return false, reason
end

-- reasons: restricted | odds | zone | tickets | busy
function Spin.spin(zone: number?): (boolean, string?)
	if restricted then
		return refuse("restricted")
	end
	local screen = ui("Spin")
	if screen and type(screen.oddsVisible) == "function" and callUi(screen, "oddsVisible") ~= true then
		return refuse("odds")
	end
	local z = zone or selected
	if typeof(z) ~= "number" or z % 1 ~= 0 or not table.find(zones, z) then
		return refuse("zone")
	end
	if tickets < 1 then
		return refuse("tickets")
	end
	if Spin.waiting() then
		return refuse("busy")
	end
	waitingSince, waitingZone = os.clock(), z
	stats.spinSent += 1
	if not noSend then
		local ok, r = pcall(Net.get, "Shop", "Spin")
		if ok and r then
			r:FireServer({ zone = z })
		else
			waitingSince, waitingZone = nil, nil
			warn("[HFB] Spin: Net.Shop.Spin not there: " .. tostring(r))
			return refuse("busy")
		end
	end
	changed()
	return true, nil
end

-- ------------------------------------------------------------------ server messages
function Spin._onResult(p)
	if typeof(p) ~= "table" or typeof(p.ok) ~= "boolean" then
		return
	end
	waitingSince, waitingZone = nil, nil
	stats.resultsSeen += 1
	last = {
		ok = p.ok,
		reason = if typeof(p.reason) == "string" then p.reason else nil,
		zone = if typeof(p.zone) == "number" then p.zone else nil,
		creatureId = if typeof(p.creatureId) == "string" then p.creatureId else nil,
		tier = if typeof(p.tier) == "number" then p.tier else nil,
		uid = if typeof(p.uid) == "string" then p.uid else nil,
	}
	if p.ok == false and p.reason == "restricted" then
		restricted = true
		Spin.close()
	end
	fire(listeners.result, last)
	changed()
end

function Spin._onState(p)
	if typeof(p) == "table" and typeof(p.policy) == "table" then
		restricted = p.policy.randomItemsRestricted == true
		if restricted and opened then
			Spin.close()
		end
		changed()
	end
end

function Spin._onProfile(p)
	if typeof(p) ~= "table" then
		return
	end
	local dirty = false
	if typeof(p.spinTickets) == "number" then
		tickets = math.max(0, math.floor(p.spinTickets))
		dirty = true
	end
	if typeof(p.zonesBeaten) == "table" then
		local list = {}
		for _, z in pairs(p.zonesBeaten) do
			if typeof(z) == "number" and z % 1 == 0 and z >= 1 and z <= 6 and not table.find(list, z) then
				table.insert(list, z)
			end
		end
		table.sort(list)
		zones = list
		ensureSelected()
		dirty = true
	end
	if dirty then
		changed()
	end
end

function Spin._noSend(on: boolean)
	noSend = on == true
end

function Spin._reset()
	opened, restricted, tickets, zones, selected = false, true, 0, {}, nil
	waitingSince, waitingZone, last = nil, nil, nil
	changed()
end

function Spin.state()
	return {
		open = Spin.isOpen(),
		available = Spin.available(),
		tickets = tickets,
		zones = zones,
		selected = selected,
		waiting = Spin.waiting(),
		last = last,
		stats = stats,
	}
end

local function listen(family: string, name: string, fn)
	task.spawn(function()
		local ok, r = pcall(Net.get, family, name)
		if ok and r then
			r.OnClientEvent:Connect(fn)
		else
			warn(("[HFB] Spin: Net.%s.%s not there: %s"):format(family, name, tostring(r)))
		end
	end)
end

function Spin.start(c)
	if started then
		return
	end
	started = true
	ctx = c
	listen("Shop", "SpinResult", Spin._onResult)
	listen("Shop", "State", Spin._onState)
	listen("Profile", "Changed", Spin._onProfile)
	Players.LocalPlayer.CharacterAdded:Connect(function()
		waitingSince, waitingZone = nil, nil
	end)
end

return Spin
