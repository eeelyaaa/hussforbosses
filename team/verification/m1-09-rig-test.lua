-- M1-09 box rig check. Run with run_script_in_play_mode (server) after a DevSync of src/. Builds a box rig with the
-- contract's groups and pivots (Body, Head, Sig at the jaw hinge (0,1.6,0.6), FistL/FistR at the shoulders), plays
-- every move, prints PASS/FAIL/INFO lines, and destroys the rig.
local RS = game:GetService("RunService")
local BM = require(game.StarterPlayer.StarterPlayerScripts.Controllers.BossMoves)
local Moves = require(game.ReplicatedStorage.Shared.Moves)
local out = {}
local function P(k, msg) print(k .. " " .. msg) end
local function check(c, msg) P(c and "PASS" or "FAIL", msg) end

local rig = Instance.new("Model"); rig.Name = "BossMovesRig"
local function box(name, size, centre)
	local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = CFrame.new(centre)
	p.CanCollide = false; p.Massless = true; p.Parent = rig; return p
end
local body = box("Body", Vector3.new(6, 2.4, 3.2), Vector3.new(0, 1.2, 0))
body.Anchored = true; body.PivotOffset = CFrame.new(0, -1.2, 0) -- pivot at the middle of the feet
local function joint(part, pivotWorld)
	local m = Instance.new("Motor6D"); m.Name = part.Name; m.Part0 = body; m.Part1 = part
	m.C0 = body.CFrame:ToObjectSpace(CFrame.new(pivotWorld)); m.C1 = part.CFrame:ToObjectSpace(CFrame.new(pivotWorld))
	m.Parent = body
end
local head = box("Head", Vector3.new(6, 1.6, 2.6), Vector3.new(0, 2.4, 0))
local sig = box("Sig", Vector3.new(5, 0.8, 2.2), Vector3.new(0, 1.8, -0.6))
local fl = box("FistL", Vector3.new(1.4, 1.4, 1.4), Vector3.new(-2.2, 1.7, -0.4))
local fr = box("FistR", Vector3.new(1.4, 1.4, 1.4), Vector3.new(2.2, 1.7, -0.4))
joint(head, Vector3.new(0, 1.6, 0.6)); joint(sig, Vector3.new(0, 1.6, 0.6))
joint(fl, Vector3.new(-1.4, 2.4, -0.4)); joint(fr, Vector3.new(1.4, 2.4, -0.4))
rig.PrimaryPart = body
rig:SetAttribute("H", 4); rig:SetAttribute("BodyType", 2); rig:SetAttribute("CreatureId", "z1_t1")
rig.Parent = workspace
local parts = { Body = body, Head = head, Sig = sig, FistL = fl, FistR = fr }
local restSize, restCF = {}, body.CFrame
for n, p in pairs(parts) do restSize[n] = p.Size end

-- schema
for _, pr in ipairs(Moves.check(Moves.get(2), "squat")) do P("FAIL", pr) end
for _, pr in ipairs(Moves.check(Moves.sig("z1_t1"), "z1_t1")) do P("FAIL", pr) end
P("INFO", "schema problems above (none = clean)")

local function isRest()
	for n, p in pairs(parts) do
		if (p.Size - restSize[n]).Magnitude > 1e-4 then return false, n .. " size" end
	end
	for _, m in ipairs(body:GetChildren()) do
		if m:IsA("Motor6D") and not m.Transform:FuzzyEq(CFrame.identity, 1e-5) then return false, m.Name .. " transform" end
	end
	if not body.CFrame:FuzzyEq(restCF, 1e-5) then return false, "Body CFrame" end
	if fl.Material ~= Enum.Material.Plastic then return false, "material" end
	return true
end

local stats
local hb = RS.Heartbeat:Connect(function()
	if not stats then return end
	for n, p in pairs(parts) do
		local r = p.Size / restSize[n]
		for _, v in ipairs({ r.X, r.Y, r.Z }) do
			stats[n].min = math.min(stats[n].min, v); stats[n].max = math.max(stats[n].max, v)
		end
	end
	if fl.Material == Enum.Material.Neon then stats.sawFlash = true end
end)
local function fresh() stats = { sawFlash = false }; for n in pairs(parts) do stats[n] = { min = 9, max = 0 } end end

local lengths = { hitGood = 0.15, hitPerfect = 0.2, hitBig = 0.3, attack = 0.45, lastHeart = 1.0, gloat = 0.35, defeat = 0.8 }
for _, name in ipairs({ "hitGood", "hitPerfect", "hitBig", "attack", "lastHeart", "gloat", "defeat" }) do
	fresh()
	local t0, tDone, tImpact = os.clock(), nil, nil
	BM.play(rig, name, { onDone = function() tDone = os.clock() - t0 end, onImpact = function() tImpact = os.clock() - t0 end,
		hopTo = name == "defeat" and Vector3.new(0, 6, -10) or nil })
	repeat task.wait() until tDone or os.clock() - t0 > 3
	task.wait(0.1)
	local want = lengths[name]
	check(tDone and math.abs(tDone - want) <= 1 / 30 + 0.004, ("%s length %.3f s (brief %.2f; Heartbeat steps ~%.3f)"):format(name, tDone or -1, want, 1 / 60))
	if tImpact then P("INFO", ("%s impact at %.3f s"):format(name, tImpact)) end
	local b, h = stats.Body, stats.Head
	check(b.min >= 0.85 - 1e-3 and b.max <= 1.15 + 1e-3, ("%s Body scale %.3f..%.3f"):format(name, b.min, b.max))
	check(h.min > 0.9999 and h.max < 1.0001, name .. " Head never scaled")
	for _, g in ipairs({ "Sig", "FistL", "FistR" }) do check(stats[g].max <= 1.2 + 1e-3, ("%s %s max scale %.3f"):format(name, g, stats[g].max)) end
	if name ~= "defeat" then
		local ok, why = isRest(); check(ok, name .. " rest pose restored after it ends " .. tostring(why or ""))
		check(not BM.isPlaying(rig), name .. " left nothing running")
	else
		check(BM.isPlaying(rig, "defeat"), "defeat holds its last pose")
		P("INFO", "defeat final pivot " .. tostring(body:GetPivot().Position) .. " (hopTo 0,6,-10)")
		BM.stop(rig); local ok, why = isRest(); check(ok, "stop after defeat restores rest " .. tostring(why or ""))
	end
	if name:sub(1, 3) == "hit" then check(stats.sawFlash, name .. " white flash seen") end
	check(fl.Material == Enum.Material.Plastic, name .. " flash restored")
end

-- attack timing detail
fresh()
local t0, ti
BM.play(rig, "attack", { onImpact = function() ti = os.clock() - t0 end }); t0 = os.clock()
task.wait(0.46)
check(ti and math.abs(ti - 0.21) < 0.03, ("attack impact at %.3f (~0.21)"):format(ti or -1))

-- cut: hitBig then hitGood 0.1 s later
fresh()
local firstDone, secondDone = false, nil
BM.play(rig, "hitBig", { onDone = function() firstDone = true end })
task.wait(0.1)
local t1 = os.clock()
local cf = body.CFrame
BM.play(rig, "hitGood", { onDone = function() secondDone = os.clock() - t1 end })
-- frame 1 of the new move starts from its first frame: body is at rest pose (hitGood's frame 1 = identity)
check(body.CFrame:FuzzyEq(restCF, 1e-3), "cut: the new move's first frame is drawn at once")
repeat task.wait() until secondDone
check(not firstDone, "cut: the cut move never reports done")
check(math.abs(secondDone - 0.15) <= 0.025, ("cut: hitGood after a cut lasts %.3f"):format(secondDone))
task.wait(0.1); local ok, why = isRest(); check(ok, "cut: rest restored " .. tostring(why or ""))

-- loops, layering and stop
BM.loop(rig, "guard"); task.wait(0.3)
check(select(1, BM.current(rig)) == "guard", "guard loops")
BM.play(rig, "hitPerfect"); task.wait(0.35)
local base, ov = BM.current(rig)
check(base == "guard" and ov == nil, "after a reaction the guard carries on (base " .. tostring(base) .. ")")
fresh(); BM.stop(rig); local ok2, why2 = isRest(); check(ok2, "stop restores the exact rest pose " .. tostring(why2 or ""))
BM.startPadIdle(rig); task.wait(0.9)
check(not isRest(), "idle moves the boss")
BM.stop(rig); check((isRest()), "stop after idle: rest")
-- random phase
local a, b2
BM.loop(rig, "halfIdle"); task.wait(0.05); a = body.CFrame.Position.Y; BM.stop(rig)
local diff = false
for i = 1, 8 do
	BM.loop(rig, "idle"); task.wait(0.02); local y = body.CFrame.Position.Y; BM.stop(rig)
	if math.abs(y - a) > 1e-4 then diff = true end
end
check(diff, "loops start at random phases")
-- carry rock
BM.loop(rig, "carryRock", { speed = 2 }); task.wait(0.3)
P("INFO", "carryRock body pivot rotation x about " .. math.floor(select(1, body.CFrame:ToEulerAnglesXYZ()) * 57.3 * 10) / 10 .. " deg")
BM.stop(rig); check((isRest()), "carryRock stop: rest")
-- a Miss's attack inside the 0.61 s burst
local td; local tt0 = os.clock(); BM.play(rig, "attack", { onDone = function() td = os.clock() - tt0 end }); repeat task.wait() until td
check(td < 0.61, ("attack %.3f s fits inside the 0.61 s burst"):format(td))
hb:Disconnect(); rig:Destroy()
P("INFO", "rig destroyed")
