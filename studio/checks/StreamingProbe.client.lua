if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M2-34 client probe (source of the LocalScript HFB_StreamingProbe that studio/checks/StreamingProbe.lua puts in StarterPlayerScripts; the installer
-- strips this first line because a real client runs before the workspace attribute has replicated, M2-32 lesson).
-- On a real client in play mode: (1) at join every Fixed pad boss and every review-line boss is whole and BossMoves is playing on it;
-- (2) the BossMoves wait-for-parts path: a boss clone missing its groups does nothing, then plays when the parts arrive;
-- (3) after the player is teleported to the review line, the plates change between 5 s and 15 s (the driver runs);
-- (4) at zone 6 and back at spawn the Fixed bosses are still whole and moving. Lines go to the server (RemoteEvent StreamProbe) and print.
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ev = RS:WaitForChild("StreamProbe", 20)
local lp = Players.LocalPlayer
local out, fails = {}, 0
local function say(line) print("STREAMPROBE " .. line) table.insert(out, line) if ev then ev:FireServer(line) end end
local function check(label, ok, extra)
	if not ok then fails += 1 end
	say((ok and "PASS " or "FAIL ") .. label .. (extra and (" (" .. tostring(extra) .. ")") or ""))
end
local BossMoves = require(script.Parent:WaitForChild("Controllers"):WaitForChild("BossMoves"))
local REQ = { "Body", "Head", "FistL", "FistR" }
local function whole(m)
	for _, g in ipairs(REQ) do local p = m:FindFirstChild(g, true) if not (p and p:IsA("BasePart")) then return false, g end end
	return true
end
local function char() return lp.Character or lp.CharacterAdded:Wait() end
local function hrp() return char():WaitForChild("HumanoidRootPart", 10) end
local function fixedBosses()
	local list, zones = {}, workspace:FindFirstChild("Zones")
	for z = 1, 6 do
		local zf = zones and zones:FindFirstChild("Z" .. z)
		local fixed = zf and zf:FindFirstChild("Pads") and zf.Pads:FindFirstChild("Fixed")
		local b = fixed and fixed:FindFirstChild("Boss_z" .. z .. "_t" .. z)
		list[z] = b
	end
	return list
end
local function checkFixed(tag)
	local list, ok = fixedBosses(), 0
	local playing = 0
	for z = 1, 6 do
		local b = list[z]
		if b and whole(b) then ok += 1 end
		if b and BossMoves.isPlaying(b) then playing += 1 end
	end
	check(tag .. ": all 6 Fixed pad bosses present and whole", ok == 6, ok .. "/6")
	check(tag .. ": BossMoves is playing on all 6", playing == 6, playing .. "/6")
end
local function goto_(cf) hrp().CFrame = cf end
local function waitLoaded()
	local t0 = os.clock()
	while os.clock() - t0 < 30 and not (workspace:FindFirstChild("Zones") and #fixedBosses() > 0) do task.wait(0.25) end
end

task.wait(1)
check("StreamingEnabled is on in this run", workspace.StreamingEnabled)
local spawnCF = hrp().CFrame
task.wait(10) -- join settles; Fight's idleAll and the Persistent models arrive
-- (1) at join
checkFixed("join")
local rl = workspace:FindFirstChild("ReviewLine")
check("join: ReviewLine is on the client (Persistent)", rl ~= nil)
if rl then
	local ok = 0
	for _, b in ipairs(rl.Bosses:GetChildren()) do if whole(b) then ok += 1 end end
	check("join: all 6 review-line bosses whole", ok == 6 and #rl.Bosses:GetChildren() == 6, ok .. "/" .. #rl.Bosses:GetChildren())
end
-- (2) the wait-for-parts path
do
	local src = fixedBosses()[1]
	local c = src and src:Clone()
	if c then
		local stash = {}
		for _, g in ipairs({ "Head", "FistL", "FistR", "Sig" }) do local p = c:FindFirstChild(g, true) if p then p.Parent = nil table.insert(stash, p) end end
		local fx = workspace:FindFirstChild("HFB_ClientFx") or workspace
		c.Parent = fx
		c:PivotTo(CFrame.new(0, 300, 0))
		local r1 = BossMoves.loop(c, "idle")
		task.wait(0.5)
		check("wait path: an incomplete model is not started (and does not warn-fail)", r1 == false and not BossMoves.isPlaying(c))
		for _, p in ipairs(stash) do p.Parent = c end
		local t0 = os.clock()
		while os.clock() - t0 < 3 and not BossMoves.isPlaying(c) do task.wait(0.1) end
		check("wait path: the move starts once the parts arrive", BossMoves.isPlaying(c), string.format("%.1f s", os.clock() - t0))
		BossMoves.stop(c) c:Destroy()
	end
end
-- (3) the review line
if rl then
	local land = rl:FindFirstChild("LineSpawn")
	if land then goto_(land.CFrame + Vector3.new(0, 4, 0)) end
	local function plates()
		local t = {}
		for _, p in ipairs(rl.Plates:GetChildren()) do
			local g = p:FindFirstChild("Now") local l = g and g:FindFirstChild("Label", true)
			t[p.Name] = l and l.Text or "NO LABEL"
		end
		return t
	end
	task.wait(5) local a = plates()
	task.wait(10) local b = plates()
	local started, changed, n = 0, 0, 0
	for name, text in pairs(a) do
		n += 1
		if text ~= "starting..." and text ~= "NO LABEL" then started += 1 end
		if b[name] ~= text then changed += 1 end
	end
	check("review line t5: every plate has left 'starting...'", n > 0 and started == n, started .. "/" .. n)
	check("review line t5->t15: every plate changed", n > 0 and changed == n, changed .. "/" .. n)
	local function dump(t) local s = {} for k, v in pairs(t) do s[#s + 1] = k .. "=" .. v end table.sort(s) return table.concat(s, "; ") end
	say("t5 " .. dump(a)) say("t15 " .. dump(b))
	-- the driver stops a boss between moves, so look over 4 s: every boss must have had a running state at some sample
	local seen = {}
	for _ = 1, 40 do
		for _, bm in ipairs(rl.Bosses:GetChildren()) do if BossMoves.isPlaying(bm) then seen[bm] = true end end
		task.wait(0.1)
	end
	local bp = 0 for _ in pairs(seen) do bp += 1 end
	check("review line: BossMoves ran on every boss within 4 s", bp == 6, bp .. "/6")
end
-- (4) zone 6, then home
local z6 = fixedBosses()[6]
if z6 then
	goto_(z6:GetPivot() * CFrame.new(0, 6, 14))
	task.wait(8)
	checkFixed("zone 6")
end
goto_(spawnCF)
task.wait(8)
checkFixed("back at spawn")
say(("DONE %d failed"):format(fails))
