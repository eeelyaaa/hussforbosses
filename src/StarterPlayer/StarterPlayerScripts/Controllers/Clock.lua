--!nonstrict
-- Controllers/Clock: the server's hazard and pad clock on the client (m1-contract.md section C, Zones.Clock).
-- now() = Workspace:GetServerTimeNow() + offset, where offset = Zones.Clock.serverTime - GetServerTimeNow() at receipt.
-- TEAM CALL M1-14a: an offset under 0.25 s is latency (the server's ClockOffset hook is 0 live), so it counts as 0; a bigger
-- one is the hook (tests) and is taken as sent.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))

local Clock = {}
local offset = 0
local started = false

function Clock.now(): number
	return workspace:GetServerTimeNow() + offset
end

function Clock.offset(): number
	return offset
end

function Clock.init()
	if started then
		return
	end
	started = true
	Net.get("Zones", "Clock").OnClientEvent:Connect(function(p)
		if typeof(p) ~= "table" or typeof(p.serverTime) ~= "number" then
			return
		end
		local o = p.serverTime - workspace:GetServerTimeNow()
		offset = if math.abs(o) < 0.25 then 0 else o
	end)
end

return Clock
