--!strict
-- Funnel: the 12 first-session events (brief "The first session"; m2-contract.md section F). Built by M2-21 on M2-01's skeleton;
-- the API did not change.
--
-- Funnel.mark(player, name): name from Ids.FUNNEL; once per player, ever: the once-guard is the SAVED flag profile.flags[name]
-- (Data/Session: one mutate, sent to the client in Profile.Changed, kept through rebirth by Config.Rebirth.KEPT, reset by the
-- Wipe hook). A player with no live profile (loading, a stand-in) falls back to this server's memory. Logs
--   [HFB][funnel] <name> <userId> t=<seconds since this join>
-- and in Studio appends { name, userId, t } to TestHooks.reports.funnel. Never yields, never errors on a bad name (warns once),
-- so a caller can mark from any handler. No AnalyticsService call (TEAM CALL M2-21-1: the requirement lists analytics services
-- under "not asked for"; the funnel is read from the log).
-- Joined: Funnel marks it itself on Session.onJoin (the first load of a profile without the flag), and in Studio after the Wipe
-- hook (a wiped profile is a fresh one: the flags table comes back empty).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Ids = require(Shared.Ids)
local TestHooks = require(Shared.TestHooks)
local Session = require(script.Parent.Parent.Data.Session)

local Funnel = {}

local joinedAt: { [Player]: number } = {}
local marked: { [Player]: { [string]: boolean } } = {} -- only for a player with no live profile
local warned: { [string]: boolean } = {}

function Funnel.mark(player: Player, name: string)
	if not table.find(Ids.FUNNEL, name) then
		if not warned[name] then
			warned[name] = true
			warn("[HFB][funnel] unknown event " .. tostring(name))
		end
		return
	end
	if Funnel.has(player, name) then
		return
	end
	local saved = false
	if Session.get(player) then
		saved = Session.mutate(player, function(q)
			q.flags[name] = true
		end)
	end
	if not saved then
		local set = marked[player]
		if not set then
			set = {}
			marked[player] = set
		end
		set[name] = true
	end
	local t = os.clock() - (joinedAt[player] or os.clock())
	print(("[HFB][funnel] %s %d t=%.1f"):format(name, player.UserId, t))
	if RunService:IsStudio() then
		local list = TestHooks.reports.funnel
		if type(list) ~= "table" then
			list = {}
			TestHooks.reports.funnel = list
		end
		table.insert(list, { name = name, userId = player.UserId, t = t })
	end
end

-- True once the player has the mark (the saved flag; memory for a player with no live profile).
function Funnel.has(player: Player, name: string): boolean
	local prof = Session.get(player)
	if prof and prof.flags ~= nil and prof.flags[name] == true then
		return true
	end
	local set = marked[player]
	return set ~= nil and set[name] == true
end

function Funnel.start()
	local function added(p: Player)
		joinedAt[p] = os.clock()
	end
	Players.PlayerAdded:Connect(added)
	for _, p in ipairs(Players:GetPlayers()) do
		added(p)
	end
	Players.PlayerRemoving:Connect(function(p)
		joinedAt[p] = nil
		marked[p] = nil
	end)
	Session.onJoin(function(p)
		Funnel.mark(p, "Joined")
	end)
	if RunService:IsStudio() then
		Session.onChanged(function(p, key, value)
			-- the Wipe hook: a fresh profile, so a fresh first session
			if key == "flags" and type(value) == "table" and value.Joined == nil and Session.state(p) == "live" then
				joinedAt[p] = os.clock()
				Funnel.mark(p, "Joined")
			end
		end)
	end
end

return Funnel
