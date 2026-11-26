--!strict
-- Systems/Zones: boss pads, which creature stands on each and its Power, per-player pad availability, and the
-- server clock the hazards and pads run on (brief system 5; m1-contract.md sections B, C, E).
-- M1: zone 1's fixed pad only (Config.Zones.PADS). Rolling pads are M2.
--
-- Remotes sent: Zones.Pads (every player, on join and on change), Zones.PadBeaten (owner, after a win),
-- Zones.Clock (every player, on join, every Config.Zones.CLOCK_EVERY_S and when the ClockOffset hook changes).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local TestHooks = require(Shared.TestHooks)

export type Pad = {
	padId: string,
	model: Model,
	ring: BasePart,
	radius: number,
	creatureId: string,
	power: number,
	kind: string,
	zone: number,
}

local Zones = {}

local pads: { [string]: Pad } = {}
-- availableAt[player][padId] = Zones.now() at which that pad opens again for that player (win or loss).
local availableAt: { [Player]: { [string]: number } } = {}

-- The server's hazard and pad clock: server time plus the ClockOffset hook (Studio only).
function Zones.now(): number
	local off = TestHooks.get("ClockOffset")
	return workspace:GetServerTimeNow() + (if Net.isNumber(off) then off else 0)
end

function Zones.pad(padId: string): Pad?
	return pads[padId]
end

-- The Zones.Pads payload.
function Zones.padsPayload(): { any }
	local out = {}
	for id, p in pairs(pads) do
		table.insert(out, { padId = id, creatureId = p.creatureId, power = p.power, kind = p.kind })
	end
	table.sort(out, function(a, b)
		return a.padId < b.padId
	end)
	return out
end

local function register(model: Instance)
	if not model:IsA("Model") then
		return
	end
	local padId = model:GetAttribute("PadId")
	if typeof(padId) ~= "string" then
		return
	end
	local def = Config.Zones.PADS[padId]
	if not def then
		return
	end
	local ring = model:FindFirstChild("Ring")
	if not (ring and ring:IsA("BasePart")) then
		warn("[HFB] Zones: pad " .. padId .. " has no Ring part")
		return
	end
	local radius = ring:GetAttribute("RingRadius")
	local power = Config.Zones.POWER[def.creatureId]
	assert(typeof(power) == "number", "Zones: no Power for " .. def.creatureId)
	pads[padId] = {
		padId = padId,
		model = model,
		ring = ring,
		radius = if typeof(radius) == "number" then radius else ring.Size.X / 2,
		creatureId = def.creatureId,
		power = power,
		kind = def.kind,
		zone = def.zone,
	}
end

-- Is the pad open to this player now? (false, secondsLeft) while on its win return or loss cooldown.
function Zones.isOpen(player: Player, padId: string): (boolean, number)
	local t = availableAt[player] and availableAt[player][padId]
	if not t then
		return true, 0
	end
	local left = t - Zones.now()
	if left <= 0 then
		return true, 0
	end
	return false, left
end

-- Closes the pad to this player for `seconds` (the loss cooldown).
function Zones.closeFor(player: Player, padId: string, seconds: number)
	local byPad = availableAt[player]
	if not byPad then
		byPad = {}
		availableAt[player] = byPad
	end
	byPad[padId] = math.max(byPad[padId] or 0, Zones.now() + seconds)
end

-- After a win: the fixed pad is back for that player in FIXED_BACK_S (hook PadFastBack replaces it).
function Zones.markBeaten(player: Player, padId: string)
	local fast = TestHooks.get("PadFastBack")
	local backIn = if Net.isNumber(fast, 0, 3600) then fast else Config.Fight.FIXED_BACK_S
	Zones.closeFor(player, padId, backIn)
	Net.get("Zones", "PadBeaten"):FireClient(player, { padId = padId, backIn = backIn })
end

local function sendClockAll()
	Net.get("Zones", "Clock"):FireAllClients({ serverTime = Zones.now() })
end

function Zones.start()
	for _, m in ipairs(CollectionService:GetTagged("HFB_BossPad")) do
		register(m)
	end
	CollectionService:GetInstanceAddedSignal("HFB_BossPad"):Connect(function(m)
		register(m)
		Net.get("Zones", "Pads"):FireAllClients(Zones.padsPayload())
	end)
	for id in pairs(Config.Zones.PADS) do
		if not pads[id] then
			warn("[HFB] Zones: pad " .. id .. " is in Config.Zones.PADS but not in the world")
		end
	end

	local function onJoin(p: Player)
		Net.get("Zones", "Pads"):FireClient(p, Zones.padsPayload())
		Net.get("Zones", "Clock"):FireClient(p, { serverTime = Zones.now() })
	end
	Players.PlayerAdded:Connect(onJoin)
	for _, p in ipairs(Players:GetPlayers()) do
		task.spawn(onJoin, p)
	end
	Players.PlayerRemoving:Connect(function(p)
		availableAt[p] = nil
	end)

	workspace:GetAttributeChangedSignal(TestHooks.PREFIX .. "ClockOffset"):Connect(sendClockAll)
	task.spawn(function()
		while true do
			task.wait(Config.Zones.CLOCK_EVERY_S)
			sendClockAll()
		end
	end)
end

return Zones
