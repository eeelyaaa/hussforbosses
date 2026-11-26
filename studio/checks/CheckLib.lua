if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M1-16: shared helpers for the play-mode checks (CoreLoop, Refusals, BurstValues, NoDelay).
-- Installed by CheckAll ("prepare") as ServerStorage.TmpChecks.CheckLib, wrapped as `return function(...) <this> end`.
-- Use: local L = {}; require(game.ServerStorage.TmpChecks.CheckLib)(L)
-- Every line is printed as it happens (a play-mode call that times out still shows what ran). print() gets strings only.
local L = ...
local Players = game:GetService("Players")
local LogService = game:GetService("LogService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")

L.Config = require(ReplicatedStorage.Shared.Config)
L.Net = require(ReplicatedStorage.Shared.Net)
L.TestHooks = require(ReplicatedStorage.Shared.TestHooks)
L.SH = require(ReplicatedStorage.Shared.Hazards)
L.Punch = require(SSS.Systems.Punch)
L.Fight = require(SSS.Systems.Fight)
L.Bag = require(SSS.Systems.Bag)
L.Zones = require(SSS.Systems.Zones)
L.Carry = require(SSS.Systems.Carry)
L.Hazards = require(SSS.Systems.Hazards)
L.Base = require(SSS.Systems.Base)
L.Income = require(SSS.Systems.Income)
L.Session = require(SSS.Data.Session)

local C2S = { { "Punch", "Report" }, { "Fight", "Start" }, { "Fight", "Run" }, { "Carry", "Grab" }, { "Base", "Place" }, { "Profile", "TestReport" } }
L.C2S = C2S

function L.s(x)
	if type(x) == "number" then
		if x ~= x then return "nan" end
		if x % 1 == 0 and math.abs(x) < 1e15 then return tostring(x) end
		return ("%.3f"):format(x)
	end
	return tostring(x)
end

-- ctx = L.begin(name, args): waits for the player and the character, starts the watchers.
function L.begin(name, args)
	args = args or {}
	local ctx = { name = name, phase = tostring(args.phase or "-"), pass = 0, fail = 0, fails = {}, errs = {}, hooks = {}, reports = {}, remotes = {}, conns = {} }
	ctx.tag = name .. "/" .. ctx.phase
	table.insert(ctx.conns, LogService.MessageOut:Connect(function(m, t)
		if m:find("CHECK ", 1, true) == 1 then return end
		if t == Enum.MessageType.MessageError then
			table.insert(ctx.errs, m)
		elseif t == Enum.MessageType.MessageWarning and m:find("[HFB]", 1, true) and not m:find("TestReport", 1, true) then
			table.insert(ctx.errs, m)
		end
	end))
	for _, e in ipairs(LogService:GetLogHistory()) do
		if e.messageType == Enum.MessageType.MessageError then
			table.insert(ctx.errs, "before the check: " .. e.message)
		elseif e.messageType == Enum.MessageType.MessageWarning and e.message:find("[HFB]", 1, true) and not e.message:find("TestReport", 1, true) then
			table.insert(ctx.errs, "before the check: " .. e.message)
		end
	end
	local p = Players:GetPlayers()[1]
	local t0 = os.clock()
	while not p and os.clock() - t0 < 20 do task.wait(0.1); p = Players:GetPlayers()[1] end
	assert(p, "no player joined in 20 s")
	ctx.p = p
	ctx.char = p.Character or p.CharacterAdded:Wait()
	ctx.hrp = ctx.char:WaitForChild("HumanoidRootPart")
	ctx.hum = ctx.char:WaitForChild("Humanoid")
	-- every Profile.TestReport the real client sends, in order
	table.insert(ctx.conns, L.Net.get("Profile", "TestReport").OnServerEvent:Connect(function(pl, payload)
		if pl ~= p or type(payload) ~= "table" or type(payload.name) ~= "string" or type(payload.json) ~= "string" then return end
		local ok, data = pcall(HttpService.JSONDecode, HttpService, payload.json)
		if ok then table.insert(ctx.reports, { name = payload.name, data = data, at = os.clock() }) end
	end))
	-- an observer on every client-to-server remote: which remote carried each result
	for _, fr in ipairs(C2S) do
		local key = fr[1] .. "." .. fr[2]
		ctx.remotes[key] = 0
		table.insert(ctx.conns, L.Net.get(fr[1], fr[2]).OnServerEvent:Connect(function(pl)
			if pl == p then ctx.remotes[key] += 1 end
		end))
	end
	-- the ledger: every server-side change to the profile, with what the check expected
	ctx.ledger = {}
	ctx.expect = nil
	ctx.unsubLedger = L.Session.onChanged(function(pl, key, value)
		if pl ~= p then return end
		-- a change within 0.5 s of a state hook the check set is the hook's (ctx.expect also marks one by hand)
		local exp = ctx.expect or (os.clock() - (ctx.stateHookAt or -math.huge) < 0.5 and "hook") or nil
		table.insert(ctx.ledger, { key = key, value = value, at = os.clock(), beatN = #L.Punch.stats.log, collectN = #L.Income.stats.collects, placedN = #L.Base.stats.placed, expect = exp })
	end)
	print(("CHECK %s start: player %d, skin %s"):format(ctx.tag, p.UserId, tostring(require(ReplicatedStorage.Shared.Skin).Id)))
	return ctx
end

function L.check(ctx, label, ok, detail)
	ok = ok == true
	if ok then ctx.pass += 1 else ctx.fail += 1; table.insert(ctx.fails, label) end
	print(("%s %s %s%s"):format(ok and "PASS" or "FAIL", ctx.tag, label, detail ~= nil and (" | " .. L.s(detail)) or ""))
	return ok
end

function L.note(ctx, s)
	print(("NOTE %s %s"):format(ctx.tag, s))
end

-- hooks: set and remember (cleared at finish)
local STATE = { Wipe = true, SetPower = true, SetCash = true, SetStrength = true, SetSpeed = true, GrantBoss = true }
function L.hook(ctx, name, value)
	ctx.hooks[name] = true
	if STATE[name] then ctx.stateHookAt = os.clock() end
	workspace:SetAttribute("HFB_" .. name, value)
end

function L.waitFor(fn, timeout, step)
	local t = os.clock()
	while os.clock() - t < timeout do
		local v = fn()
		if v then return v, os.clock() - t end
		task.wait(step or 0.03)
	end
	return nil, os.clock() - t
end

function L.flat(a, b) return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude end

-- teleport; the server's carry speed check starts over (the check moved the character, not the player)
function L.tp(ctx, pos)
	ctx.char:PivotTo(CFrame.new(pos))
	ctx.hrp.AssemblyLinearVelocity = Vector3.zero
	L.Carry.resetAnchor(ctx.p)
end

-- the height of the root above the floor it stands on (measured once at the spawn)
function L.rootY(ctx)
	if not ctx.rooty then
		local sp = workspace.Plots.Plot1.SpawnPoint
		ctx.rooty = math.clamp(ctx.hrp.Position.Y - (sp.Position.Y + sp.Size.Y / 2), 2.5, 3.5)
	end
	return ctx.rooty
end

function L.onPart(ctx, part, dx, dz)
	return part.Position + Vector3.new(dx or 0, part.Size.Y / 2 + L.rootY(ctx), dz or 0)
end

function L.prof(ctx) return L.Session.get(ctx.p) end
function L.power(ctx) return L.prof(ctx).power end
function L.carryState(ctx) local c = L.Carry.get(ctx.p); return c and c.state or "none" end

-- a snapshot of everything a refused request must not change
function L.snap(ctx)
	local pr = L.prof(ctx)
	local f = L.Fight.get(ctx.p)
	local spots = {}
	for i = 1, 10 do local s = pr.spots[i]; spots[i] = s and s.uid or "-" end
	local c = L.Carry.get(ctx.p)
	return ("power=%s cash=%s spots=%s carry=%s/%s fight=%s hearts=%s health=%s"):format(
		L.s(pr.power), L.s(pr.cash), table.concat(spots, ","), c and c.state or "none", c and tostring(c.uid) or "-",
		f and tostring(f.fightId) or "none", f and tostring(f.hearts) or "-", f and L.s(f.health) or "-")
end

-- reports from the client since index i0, by name
function L.reportsSince(ctx, i0, name)
	local out = {}
	for i = (i0 or 0) + 1, #ctx.reports do
		local r = ctx.reports[i]
		if not name or r.name == name then table.insert(out, r) end
	end
	return out
end

-- holds Net's limiter full for Punch.Report, so the real client's reports are dropped (forged-report sections and the
-- stall rule). The forged reports go through Punch.report (the handler after the limiter).
function L.muteClient(ctx, on)
	ctx.muted = on
	if on and not ctx.muteConn then
		-- refilled on every Heartbeat: the limiter's stamps then expire later in a frame than the network events of
		-- that frame are handled, so no client report finds a free slot (a 0.05 s loop let one through, run 1)
		local lim = L.Config.Punch.RATE["Punch.Report"]
		ctx.muteConn = game:GetService("RunService").Heartbeat:Connect(function()
			for _ = 1, lim + 1 do L.Net.rateOk(ctx.p, "Punch.Report", lim) end
		end)
		table.insert(ctx.conns, ctx.muteConn)
		task.wait(0.1)
	elseif not on and ctx.muteConn then
		ctx.muteConn:Disconnect()
		ctx.muteConn = nil
		task.wait(1.1) -- the sliding window empties
	end
end

local seq = 100000
function L.forge(ctx, context, grade, extra)
	seq += 1
	local pl = { seq = seq, context = context, grade = grade }
	if grade ~= "miss" then pl.tapServerTime = workspace:GetServerTimeNow() end
	for k, v in pairs(extra or {}) do pl[k] = v end
	L.Punch.report(ctx.p, pl)
	return L.Punch.stats.lastResult[ctx.p.UserId], seq
end

-- beats of one burst (server log), by seq
function L.beatsOf(ctx, s)
	local out = {}
	for _, e in ipairs(L.Punch.stats.log) do
		if e.userId == ctx.p.UserId and e.seq == s then table.insert(out, e) end
	end
	table.sort(out, function(a, b) return a.n < b.n end)
	return out
end

-- bursts (distinct seqs) of the player in the server log after index i0, in order
function L.burstsSince(ctx, i0, context)
	local order, by = {}, {}
	for i = (i0 or 0) + 1, #L.Punch.stats.log do
		local e = L.Punch.stats.log[i]
		if e.userId == ctx.p.UserId and (not context or e.context == context) then
			if not by[e.seq] then by[e.seq] = {}; table.insert(order, e.seq) end
			table.insert(by[e.seq], e)
		end
	end
	local out = {}
	for _, s in ipairs(order) do
		table.sort(by[s], function(a, b) return a.n < b.n end)
		table.insert(out, { seq = s, beats = by[s] })
	end
	return out
end

-- Server authority (gate step 9): every change to power and cash in the ledger since index i0 has a server-side
-- cause: a hook the check set (ctx.expect names it), an applied bag beat (Punch log) or a collect (Income log).
function L.authority(ctx, i0, label)
	local bad, n = {}, 0
	local prevPower, prevCash
	for i = 1, (i0 or 0) do
		local e = ctx.ledger[i]
		if e.key == "power" then prevPower = e.value elseif e.key == "cash" then prevCash = e.value end
	end
	ctx.lastPlacedN = (i0 and i0 > 0 and ctx.ledger[i0].placedN) or 0
	prevPower = prevPower or 0
	prevCash = prevCash or 0
	for i = (i0 or 0) + 1, #ctx.ledger do
		local e = ctx.ledger[i]
		if e.key == "power" then
			n += 1
			local d = e.value - prevPower
			local beat = L.Punch.stats.log[e.beatN + 1]
			local okBeat = beat and beat.userId == ctx.p.UserId and beat.context == "bag" and math.abs(beat.value - d) < 1e-9
			local okHook = e.expect ~= nil
			if not (okBeat or okHook or d == 0) then table.insert(bad, ("power %s -> %s with no beat or hook"):format(L.s(prevPower), L.s(e.value))) end
			prevPower = e.value
		elseif e.key == "cash" then
			n += 1
			local d = e.value - prevCash
			local col = L.Income.stats.collects[e.collectN + 1]
			local okCol = col and col.userId == ctx.p.UserId and math.abs(col.amount - d) < 1e-9
			if not (okCol or e.expect ~= nil or d == 0) then table.insert(bad, ("cash %s -> %s with no collect or hook"):format(L.s(prevCash), L.s(e.value))) end
			prevCash = e.value
		elseif e.key == "spots" then
			-- a spots change is a place (Base.tryPlace logs before it sets) or a collect (Income logs after it sets)
			if e.expect == nil then
				n += 1
				local byPlace = e.placedN > (ctx.lastPlacedN or 0)
				local col = L.Income.stats.collects[e.collectN + 1]
				local byCollect = col ~= nil and col.userId == ctx.p.UserId
				if not (byPlace or byCollect) then table.insert(bad, "spots changed with no place or collect") end
			end
			ctx.lastPlacedN = e.placedN
		end
	end
	L.check(ctx, ("authority: %s (%d profile changes, each with a server-side cause)"):format(label, n), #bad == 0, #bad > 0 and table.concat(bad, "; ") or nil)
end

-- the end of a check: errors, hooks cleared, one summary line (CheckAll collects these)
function L.finish(ctx)
	ctx.muted = false
	if ctx.muteConn then ctx.muteConn:Disconnect(); ctx.muteConn = nil end
	task.wait(0.2)
	L.check(ctx, "no errors and no [HFB] warnings in the server output", #ctx.errs == 0, #ctx.errs > 0 and table.concat(ctx.errs, " || "):sub(1, 900) or nil)
	for name in pairs(ctx.hooks) do workspace:SetAttribute("HFB_" .. name, nil) end
	for _, n in ipairs({ "AutoTap", "AutoMix", "AutoInteract", "ReportBeats", "FrameCap", "ForceInput", "LogForce", "ClockOffset", "PadFastBack" }) do
		workspace:SetAttribute("HFB_" .. n, nil)
	end
	workspace:SetAttribute("HFB_CheckProbe", nil)
	local left = {}
	for k in pairs(workspace:GetAttributes()) do
		if k:sub(1, 4) == "HFB_" and k ~= "HFB_ForceSkin" then table.insert(left, k) end
	end
	L.check(ctx, "every HFB_ attribute the check set is cleared", #left == 0, #left > 0 and table.concat(left, ",") or nil)
	if ctx.unsubLedger then ctx.unsubLedger() end
	for _, c in ipairs(ctx.conns) do c:Disconnect() end
	print(("CHECK %s TOTAL pass=%d fail=%d"):format(ctx.tag, ctx.pass, ctx.fail))
	print(("CHECKALL row %s|%s|%d|%d|%s"):format(ctx.name, ctx.phase, ctx.pass, ctx.fail, table.concat(ctx.fails, "; "):sub(1, 300)))
end
