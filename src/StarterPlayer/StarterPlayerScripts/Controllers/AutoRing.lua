--!nonstrict
-- Controllers/AutoRing: the client half of Auto Punch and Perfect Auto Punch (brief system 2; m2-contract.md C, "Punch.Report
-- with auto"; B23). While Bag.State.autoOn or perfectOn, every bag ring on the player's own bag pad is tapped for them once:
-- Perfect Auto Punch at the landing (grade "perfect"), Auto Punch in the middle of the Good window (grade "good"). The tap goes
-- through the real ring path (Ring.tap), so the burst, the audio, the Power pop and the ring's schedule run as for a hand tap, and the
-- report carries auto = true (BurstClock's sender seam adds it for exactly that tap). The server decides everything: the pass, the
-- toggle, the grade it allows, one auto burst per ring; a hand tap during the ring replaces the auto one (this module then does
-- nothing for that ring). Stops when both toggles are off (or a ring starts in a fight / off the pad: Ring raises no bag ring).
-- Auto bursts are the player's only while they stand on the pad: Ring starts no ring elsewhere.
--   AutoRing.start(ctx)   AutoRing.stats -> { rings, taps, perfect, good, lastGrade }
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)

local AutoRing = { AUTO_START = true }
AutoRing.stats = { rings = 0, taps = 0, perfect = 0, good = 0, lastGrade = nil }

local autoOn, perfectOn = false, false
local pending = nil -- { n, at, grade }
local tapping = false
local Ring, BurstClock = nil, nil

local function schedule(entry)
	if not (autoOn or perfectOn) or entry.ctx ~= "bag" or typeof(entry.r0) ~= "number" or typeof(entry.close) ~= "number" then
		return
	end
	AutoRing.stats.rings += 1
	local landing = entry.r0 + entry.close
	local goodMs = if typeof(entry.goodMs) == "number" then entry.goodMs else 130
	local perfectMs = if typeof(entry.perfectMs) == "number" then entry.perfectMs else 55
	if perfectOn then
		pending = { n = entry.n, at = landing - 0.012, grade = "perfect" }
	else
		pending = { n = entry.n, at = landing + (goodMs + perfectMs) / 2000, grade = "good" }
	end
end

local function step()
	local p = pending
	if not p or os.clock() < p.at then
		return
	end
	pending = nil
	local cur = Ring.current()
	if not (autoOn or perfectOn) or cur.phase ~= "ring" or cur.n ~= p.n or cur.context ~= "bag" then
		return -- toggled off, or the ring was already tapped / has gone
	end
	tapping = true
	local ok, err = pcall(Ring.tap, os.clock(), "auto")
	tapping = false
	if not ok then
		warn("[HFB] AutoRing tap failed: " .. tostring(err))
		return
	end
	AutoRing.stats.taps += 1
	AutoRing.stats[p.grade] += 1
	AutoRing.stats.lastGrade = p.grade
end

function AutoRing.start(ctx)
	Ring, BurstClock = ctx.Ring, ctx.BurstClock
	if not (Ring and BurstClock) then
		return
	end
	-- the report of an auto tap says so; every other report goes out as it was
	BurstClock.setSender(function(report)
		if tapping then
			report.auto = true
		end
		Net.get("Punch", "Report"):FireServer(report)
	end)
	Ring.onEvent(function(kind, data)
		if kind == "start" then
			schedule(data)
		end
	end)
	Net.get("Bag", "State").OnClientEvent:Connect(function(p)
		if typeof(p) ~= "table" then
			return
		end
		local was = autoOn or perfectOn
		autoOn = p.autoOn == true
		perfectOn = p.perfectOn == true
		if not (autoOn or perfectOn) then
			pending = nil
		elseif not was then
			-- switched on in the middle of a ring: that ring is tapped too
			local cur = Ring.current()
			if cur.phase == "ring" and cur.context == "bag" and cur.landing > os.clock() then
				schedule({ n = cur.n, ctx = "bag", r0 = cur.r0, close = cur.ringClose, goodMs = cur.windows and cur.windows.goodMs, perfectMs = cur.windows and cur.windows.perfectMs })
			end
		end
	end)
	RunService.Heartbeat:Connect(step)
end

return AutoRing
