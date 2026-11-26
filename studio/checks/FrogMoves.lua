if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M1-17 (re-run in M1-20 with the cut-and-rest block at the end): plays the M1-09 moves on the REAL Chomp Frog (a clone of Fixed.Boss_z1_t1 placed away from the pad) through BossMoves,
-- and reads back that the groups turn about their pivots with Transform only (C0/C1 never change) and the jaw direction.
-- Run: run_script_in_play_mode (start_play) after DevSync + SetupBosses. Prints PASS/FAIL/INFO lines.
local RS = game:GetService("RunService")
local BM = require(game.StarterPlayer.StarterPlayerScripts.Controllers.BossMoves)
local src = workspace.Zones.Z1.Pads.Fixed:FindFirstChild("Boss_z1_t1")
local m = src:Clone(); m.Name = "M117Clone"
m:PivotTo(CFrame.new(0, 300, 0)); m.Parent = workspace
local body = m.Body
local function P(k, s) print(k .. " " .. s) end
local function check(c, s) P(c and "PASS" or "FAIL", s) end
local J = {}
for _, j in ipairs(body:GetChildren()) do if j:IsA("Motor6D") then J[j.Name] = { c0 = j.C0, c1 = j.C1 } end end
local function sigTip() return m.Sig.CFrame:PointToWorldSpace(Vector3.new(0, -0.5, -1.1)) end -- front-bottom of the jaw wedge
local function fistFront(n) return m[n].CFrame:PointToWorldSpace(Vector3.new(0, 0, -0.9)) end
local function pivotWorld(n) local j = body[n]; return body.CFrame * j.C0 end
local rest = { tip = sigTip(), fr = fistFront("FistR"), fl = fistFront("FistL"), headTop = m.Head.CFrame:PointToWorldSpace(Vector3.new(0, 0.9, 0)) }
P("INFO", ("rest sigTip rel Body y=%.3f z=%.3f"):format(rest.tip.Y - body.Position.Y, rest.tip.Z - body.Position.Z))
-- direct sign test: Transform about X on the Sig joint
for _, deg in ipairs({ -25, 25 }) do
	body.Sig.Transform = CFrame.Angles(math.rad(deg), 0, 0)
	P("INFO", ("direct Transform x=%d deg: jaw front-bottom moves dy=%.3f dz=%.3f"):format(deg, sigTip().Y - rest.tip.Y, sigTip().Z - rest.tip.Z))
end
body.Sig.Transform = CFrame.identity
-- pivot invariance under rotation of each group
for _, n in ipairs({ "Head", "Sig", "FistL", "FistR" }) do
	local pw0 = m[n].CFrame:PointToWorldSpace(J[n].c1.Position)
	body[n].Transform = CFrame.Angles(math.rad(40), math.rad(20), math.rad(15))
	local pw1 = m[n].CFrame:PointToWorldSpace(J[n].c1.Position)
	check((pw1 - pw0).Magnitude < 1e-3, n .. " turns about its pivot: pivot point moved " .. ("%.5f"):format((pw1 - pw0).Magnitude) .. " studs; pivot rel Body " .. tostring(J[n].c0.Position))
	body[n].Transform = CFrame.identity
end
-- play moves and sample
local stats
local hb = RS.Heartbeat:Connect(function()
	if not stats then return end
	local t = os.clock() - stats.t0
	local tip = sigTip()
	local dy, dz = tip.Y - rest.tip.Y, tip.Z - rest.tip.Z
	if dy < stats.minDy then stats.minDy = dy; stats.tMinDy = t end
	if dy > stats.maxDy then stats.maxDy = dy end
	local f = fistFront("FistR") - rest.fr
	if -f.Z > stats.fistFwd then stats.fistFwd = -f.Z end
	local fl = fistFront("FistL") - rest.fl
	if -fl.Z > stats.fistLFwd then stats.fistLFwd = -fl.Z end
	local h = m.Head.CFrame:PointToWorldSpace(Vector3.new(0, 0.9, 0)) - rest.headTop
	if h.Z > stats.headBack then stats.headBack = h.Z end
end)
local function run(name, opts)
	stats = { t0 = os.clock(), minDy = 0, maxDy = 0, fistFwd = 0, fistLFwd = 0, headBack = 0 }
	local done = false
	BM.play(m, name, { onDone = function() done = true end, onImpact = function() stats.impact = os.clock() - stats.t0 end, perfect = opts and opts.perfect, hopTo = opts and opts.hopTo })
	local t = os.clock()
	while not done and os.clock() - t < 2 do task.wait() end
	P("INFO", ("%s: done=%s %.3fs; jaw tip dy min %.3f (at %.3f s) max %.3f; right fist forward max %.3f; left fist fwd %.3f; head top back (+z) max %.3f"):format(name, tostring(done), os.clock() - stats.t0, stats.minDy, stats.tMinDy or -1, stats.maxDy, stats.fistFwd, stats.fistLFwd, stats.headBack))
	return stats
end
BM.loop(m, "guard"); task.wait(0.3)
local s = run("attack")
check(s.minDy < -0.15, "attack: the jaw front goes DOWN on impact (min dy " .. ("%.3f"):format(s.minDy) .. "), not up through the lip (max dy " .. ("%.3f"):format(s.maxDy) .. ")")
check(s.fistFwd > 0.3, "attack: right fist bops forward (-Z), " .. ("%.3f"):format(s.fistFwd) .. " studs")
check(s.fistLFwd <= s.fistFwd, "attack: left fist forward (" .. ("%.3f"):format(s.fistLFwd) .. ", world space, includes the body lunge) is not more than the right fist (M1-20: the M1-17 < 0.3 limit read a lunge-free number)")
for _, n in ipairs({ "hitGood", "hitPerfect", "hitBig", "lastHeart", "gloat" }) do run(n, { perfect = n == "hitPerfect" }) end
run("defeat", { hopTo = Vector3.new(0, 306, -10) })
BM.stop(m)
local same = true
for n, v in pairs(J) do if not (body[n].C0 == v.c0 and body[n].C1 == v.c1) then same = false end end
check(same, "no joint re-pivoted: every Motor6D C0 and C1 identical after all moves")
local hasSizeDrift = {}
for _, n in ipairs({ "Body", "Head", "Sig", "FistL", "FistR" }) do
	local o = src[n].Size; local c = m[n].Size
	if (o - c).Magnitude > 1e-3 then table.insert(hasSizeDrift, n .. tostring(c)) end
end
check(#hasSizeDrift == 0, "sizes restored after stop: " .. table.concat(hasSizeDrift, ","))

-- M1-20: rapid cuts (a reaction cut by the next result), then rest restored
local restPivot = m:GetPivot()
BM.loop(m, "guard"); task.wait(0.3)
local seq = { "hitGood", "hitPerfect", "hitBig", "attack", "hitGood", "lastHeart", "hitBig", "hitGood" }
local cutOk = true
for i, n in ipairs(seq) do
	BM.play(m, n, { perfect = n == "hitPerfect" })
	local _, ov = BM.current(m)
	if ov ~= n then cutOk = false P("FAIL", "after play(" .. n .. ") overlay is " .. tostring(ov)) end
	task.wait(0.04 + (i % 3) * 0.05) -- cut mid-move
end
check(cutOk, "each play cut the running move and the new one was the overlay at once")
-- let the last one finish, back to guard
local t = os.clock()
while select(2, BM.current(m)) and os.clock() - t < 3 do task.wait() end
task.wait(0.2)
local _, ov2 = BM.current(m)
P("INFO", "after the last reaction: overlay " .. tostring(ov2) .. ", base " .. tostring((BM.current(m))))
BM.stop(m); task.wait(0.1)
local ident = true
for n, _ in pairs(J) do if body[n].Transform ~= CFrame.identity then ident = false end end
check(ident, "after cuts + stop every joint Transform is identity (rest pose restored)")
check((m:GetPivot().Position - restPivot.Position).Magnitude < 0.01 and m:GetPivot().LookVector:Dot(restPivot.LookVector) > 0.9999, "model pivot back to where it stood: drift " .. ("%.4f"):format((m:GetPivot().Position - restPivot.Position).Magnitude))
local same2 = true
for n, v in pairs(J) do if not (body[n].C0 == v.c0 and body[n].C1 == v.c1) then same2 = false end end
check(same2, "no re-pivot after the rapid cuts (C0/C1 unchanged)")
local sd = {}
for _, n in ipairs({ "Body", "Head", "Sig", "FistL", "FistR" }) do if (src[n].Size - m[n].Size).Magnitude > 1e-3 then table.insert(sd, n) end end
check(#sd == 0, "sizes restored after the cuts: " .. table.concat(sd, ","))
check(BM.isPlaying(m) == false, "nothing running after stop")
hb:Disconnect(); m:Destroy()
return true
