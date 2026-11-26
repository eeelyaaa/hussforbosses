if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M2-12: client probe for wave A's client half (pads, pad bosses and the patrol, the six hazards, the base, the carry, the auto ring).
-- Installed as StarterPlayerScripts.HFB_ClientAProbe for the check only, removed after (studio/checks/ClientA.lua installs and drives it).
-- It does nothing by itself: the server driver sets Workspace.HFB_CA_Step = "<step>:<n>" (and HFB_CA_Arg), the probe runs that step,
-- and sends every result line as Profile.TestReport "ca_line" {n, ok, l, d} and then "ca_done" {n}; the driver prints them as CHECK lines.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local C = script.Parent:WaitForChild("Controllers")
local Ui = script.Parent:WaitForChild("Ui")
local Pads = require(C:WaitForChild("Pads"))
local BossVisuals = require(C:WaitForChild("BossVisuals"))
local BossMoves = require(C:WaitForChild("BossMoves"))
local Hazards = require(C:WaitForChild("Hazards"))
local Base = require(C:WaitForChild("Base"))
local Carry = require(C:WaitForChild("Carry"))
local AutoRing = require(C:WaitForChild("AutoRing"))
local Clock = require(C:WaitForChild("Clock"))
local Kit = require(Ui:WaitForChild("Kit"))
local Confirm = require(Ui:WaitForChild("Confirm"))
local BossPanel = require(Ui:WaitForChild("BossPanel"))
local BagPanel = require(Ui:WaitForChild("BagPanel"))
local Shared = RS:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Patrol = require(Shared:WaitForChild("Patrol"))
local SH = require(Shared:WaitForChild("Hazards"))
local Skin = require(Shared:WaitForChild("Skin"))
local lp = Players.LocalPlayer
local N = Skin.Names
local CC = Skin.Tokens.colors

local out = {}
local function chk(ok, label, detail)
	table.insert(out, { ok = ok == true, label = label, detail = detail })
end
local function wait(s) task.wait(s) end
local function sorted(t)
	local k = {}
	for key in pairs(t) do table.insert(k, key) end
	table.sort(k, function(a, b) return tostring(a) < tostring(b) end)
	return k
end
local function padModel(padId)
	for _, m in ipairs(CollectionService:GetTagged("HFB_BossPad")) do
		if m:GetAttribute("PadId") == padId then return m end
	end
end
local function ownPlotId()
	for i = 1, 20 do
		local p = Base.plot(i)
		if p and p.owner == lp.UserId then return i end
	end
end
local function ltm(model)
	local lo, hi = 1, 0
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then lo = math.min(lo, d.LocalTransparencyModifier); hi = math.max(hi, d.LocalTransparencyModifier) end
	end
	return lo, hi
end
local function flat(a, b) return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude end
local function r2(x) return x and math.floor(x * 100 + 0.5) / 100 end
local function mmssOk(text, left)
	local m, s = string.match(text or "", "^(%d+):(%d%d)$")
	if not m then return false end
	return math.abs(tonumber(m) * 60 + tonumber(s) - math.ceil(left)) <= 1
end

local steps = {}

-- ------------------------------------------------------------------------------------------------ pads
function steps.pads()
	wait(1.5)
	local snap = Pads.snapshot()
	local n, bad, labels = 0, {}, 0
	for _, padId in ipairs(sorted(snap)) do
		local v, e = snap[padId], Pads.entry(padId)
		n += 1
		if not e then
			table.insert(bad, padId .. " no entry")
		else
			if v.text ~= Kit.commas(Config.Zones.POWER[e.creatureId]) then table.insert(bad, padId .. " text " .. tostring(v.text)) end
			local band = Config.Fight.band(e.power / math.max(v.mine, 1))
			if v.color ~= CC.band[band.id]:ToHex() then table.insert(bad, padId .. " colour") end
			if e.kind == "roll" then
				if not mmssOk(v.timer, e.rollEndsAt - Clock.now()) then table.insert(bad, padId .. " timer " .. tostring(v.timer)) end
			elseif v.timer ~= nil then
				table.insert(bad, padId .. " fixed pad shows a timer")
			end
			if not v.shown or v.beaten then table.insert(bad, padId .. " not shown") end
			local m = padModel(padId)
			local anchor = m and m:FindFirstChild("NumberAnchor")
			local gui = anchor and anchor:FindFirstChild("PowerNumber")
			if gui and gui:IsA("BillboardGui") and gui.Size.X.Offset == 0 and gui.Size.Y.Offset == 0 and gui.Size.X.Scale > 0 and not gui.AlwaysOnTop and gui.MaxDistance <= 150 then
				labels += 1
			end
		end
	end
	chk(n == 24, "24 pad labels built (S5)", n)
	chk(#bad == 0, "every pad shows its Power, its band colour, a roll timer (rolling pads only) and is shown (S5)", table.concat(bad, "; "):sub(1, 180))
	chk(labels == 24, "every pad label is a BillboardGui in studs (no offset size, not on top, max 150) (M2-05 rule)", labels)
	local rolls = 0
	for _, padId in ipairs(sorted(snap)) do if snap[padId].kind == "roll" then rolls += 1 end end
	chk(rolls == 18, "18 rolling pads, 6 fixed (S5)", rolls)
	-- timers count down
	local a = snap["z2_roll1"] and snap["z2_roll1"].timer
	wait(2.2)
	local b = Pads.snapshot()["z2_roll1"].timer
	chk(a ~= nil and b ~= nil and a ~= b, "a roll timer counts down", tostring(a) .. " -> " .. tostring(b))
end

function steps.rolled()
	wait(1.2)
	local e = Pads.entry("z1_roll1")
	local v = Pads.snapshot()["z1_roll1"]
	chk(e and e.creatureId == "z1_t4" and v.text == "100", "ForceRoll z1_roll1 = z1_t4: the pad's number is 100 (S5)", e and (e.creatureId .. " " .. tostring(v.text)))
	local st = BossVisuals.padState("z1_roll1")
	chk(st and st.creatureId == "z1_t4" and st.boss ~= nil and st.boss.Parent == padModel("z1_roll1"), "the pad's boss is redrawn for the new roll, a child of the pad named Boss", st and st.creatureId)
	chk(st and st.boss and st.boss.Name == "Boss", "the pad boss is named Boss (Controllers/Fight finds it there)")
end

function steps.beaten()
	wait(1.2)
	local v = Pads.snapshot()["z1_roll2"]
	chk(v and v.beaten and not v.shown and v.timer ~= nil, "a beaten roll shows no Power, only the time until it rolls (S5)", v and (tostring(v.shown) .. " " .. tostring(v.timer)))
	local st = BossVisuals.padState("z1_roll2")
	local lo = st and st.boss and ltm(st.boss)
	chk(st and st.hidden and lo == 1, "a beaten roll's boss is not drawn for the beater", st and tostring(st.hidden) .. " " .. tostring(lo))
	local o = Pads.snapshot()["z1_roll3"]
	chk(o and o.shown and not o.beaten, "the other pads of the zone are unchanged", o and tostring(o.shown))
end

function steps.back()
	wait(1.2)
	local v = Pads.snapshot()["z1_roll2"]
	chk(v and v.shown and not v.beaten, "when the pad rolls again it is back for the beater (S5)", v and tostring(v.shown))
	local st = BossVisuals.padState("z1_roll2")
	local lo = st and st.boss and ltm(st.boss)
	chk(st and not st.hidden and lo == 0, "its boss is drawn again", st and tostring(lo))
end

-- ------------------------------------------------------------------------------------------------ pad bosses and the patrol
function steps.boss(zoneArg)
	local zone = tonumber(zoneArg)
	wait(1.6)
	local cam = workspace.CurrentCamera.CFrame.Position
	local checked, bad, moved = 0, {}, 0
	local snap = Pads.snapshot()
	for _, padId in ipairs(sorted(snap)) do
		local e = Pads.entry(padId)
		if e and e.zone == zone then
			local m = padModel(padId)
			local boss = m and m:FindFirstChild("Boss")
			if not boss then
				table.insert(bad, padId .. " no boss")
			else
				checked += 1
				local anchor = Patrol.anchor(m, Config.Zones.LANE)
				local ring = m.Ring
				local groundY = ring.Position.Y + ring.Size.Y / 2
				RunService.Heartbeat:Wait()
				local t1 = Clock.now()
				local p1 = boss:GetPivot().Position
				local want1, face1 = Patrol.position(anchor, e.patrol, t1)
				if flat(p1, want1) > 0.8 then table.insert(bad, ("%s at %s want %s"):format(padId, tostring(p1), tostring(want1))) end
				if math.abs(p1.Y - groundY) > 0.6 then table.insert(bad, padId .. " feet y " .. r2(p1.Y) .. " ring top " .. r2(groundY)) end
				if flat(p1, anchor.Position) > Config.Zones.PATROL.halfLen + 0.8 then table.insert(bad, padId .. " out of its region") end
				local look = boss:GetPivot().LookVector
				if look:Dot(Vector3.new(face1.X, 0, face1.Z).Unit) < 0.85 then table.insert(bad, padId .. " facing") end
				local lo = ltm(boss)
				if lo ~= 0 then table.insert(bad, padId .. " hidden") end
				e._p1, e._t1 = p1, t1
			end
		end
	end
	chk(checked == 4, ("zone %d: all four pads draw their boss"):format(zone), checked)
	chk(#bad == 0, ("zone %d: each boss stands where Patrol.position puts it (<= 0.8 studs), feet on the ring, inside its region, facing its way"):format(zone), table.concat(bad, "; "):sub(1, 200))
	wait(1.5)
	for _, padId in ipairs(sorted(snap)) do
		local e = Pads.entry(padId)
		if e and e.zone == zone and e._p1 then
			local m = padModel(padId)
			local boss = m:FindFirstChild("Boss")
			local anchor = Patrol.anchor(m, Config.Zones.LANE)
			RunService.Heartbeat:Wait()
			local t2 = Clock.now()
			local p2 = boss:GetPivot().Position
			local want2 = Patrol.position(anchor, e.patrol, t2)
			local want1 = Patrol.position(anchor, e.patrol, e._t1)
			local dWant, dGot = (want2 - want1), (p2 - e._p1)
			if (dWant - dGot).Magnitude > 0.9 then table.insert(bad, ("%s moved %s want %s"):format(padId, tostring(dGot), tostring(dWant))) end
			if dGot.Magnitude > 0.5 then moved += 1 end
		end
	end
	chk(#bad == 0, ("zone %d: over 1.5 s each boss moved as the patrol says (<= 0.9 studs)"):format(zone), table.concat(bad, "; "):sub(1, 200))
	chk(moved >= 1, ("zone %d: at least one boss is walking"):format(zone), moved)
	local m1 = BossMoves.restPivot(padModel("z" .. zone .. "_fixed"):FindFirstChild("Boss"))
	chk(m1 ~= nil, ("zone %d: the pad boss idles (a BossMoves loop runs near the camera)"):format(zone))
end

function steps.freeze()
	wait(1.0)
	local m = padModel("z1_fixed")
	local boss = m:FindFirstChild("Boss")
	local e = Pads.entry("z1_fixed")
	local anchor = Patrol.anchor(m, Config.Zones.LANE)
	local ring = m.Ring
	local gy = ring.Position.Y + ring.Size.Y / 2
	local fp = anchor.Position + anchor.RightVector * 6
	fp = Vector3.new(fp.X, gy, fp.Z)
	BossVisuals._onFightState({ state = "started", fightId = 9001, padId = "z1_fixed", bossPos = fp, creatureId = e.creatureId })
	wait(0.4)
	chk(flat(boss:GetPivot().Position, fp) < 0.3, "a fight freezes the boss at Fight.State.bossPos for the fighter (M2-06 E)", r2(flat(boss:GetPivot().Position, fp)))
	local looked = boss:GetPivot().LookVector
	local toMe = lp.Character.HumanoidRootPart.Position - boss:GetPivot().Position
	chk(Vector3.new(looked.X, 0, looked.Z).Unit:Dot(Vector3.new(toMe.X, 0, toMe.Z).Unit) > 0.9, "the frozen boss faces the fighter")
	wait(2.0)
	local p = boss:GetPivot().Position
	local want = Patrol.position(anchor, e.patrol, Clock.now())
	chk(flat(p, fp) < 0.2, "it stays put while the fight runs (the patrol has moved on)", ("drift %s, patrol is %s away"):format(r2(flat(p, fp)), r2(flat(p, want))))
	chk(BossMoves.restPivot(boss) ~= nil and select(1, BossMoves.current(boss)) ~= nil, "its base loop is running at the frozen pose")
	BossVisuals._onFightState({ state = "loss", fightId = 9001 })
	wait(0.5)
	local after = flat(boss:GetPivot().Position, Patrol.position(anchor, e.patrol, Clock.now()))
	chk(after < 0.8, "after a loss or a run the boss walks on from where the patrol has it (S5)", r2(after))
	BossVisuals._onFightState({ state = "started", fightId = 9002, padId = "z1_fixed", bossPos = fp, creatureId = e.creatureId })
	wait(0.3)
	BossVisuals._onFightState({ state = "win", fightId = 9002 })
	BossVisuals.setPadHidden("z1_fixed", true)
	local st = BossVisuals.padState("z1_fixed")
	chk(st.winHold and not st.hidden and flat(boss:GetPivot().Position, fp) < 0.3, "a won boss stays where it was beaten and is not hidden by the pad refresh (the carry hops it onto the head first)")
	BossVisuals.setPadHidden("z1_fixed", false)
	wait(0.4)
	st = BossVisuals.padState("z1_fixed")
	chk(not st.winHold and not st.frozen and flat(boss:GetPivot().Position, Patrol.position(anchor, e.patrol, Clock.now())) < 0.8, "when its pad is back it is shown and walks again (S5)")
end

-- ------------------------------------------------------------------------------------------------ hazards
function steps.hazard(idArg)
	local id = tonumber(idArg)
	local model = SH.models()[id]
	local track = model and SH.trackOf(model)
	if not track then chk(false, "hazard " .. id .. " model found") return end
	wait(1.4)
	local dur = if id == 2 then 7.2 else 4.6
	local t0 = os.clock()
	local maxPose, poseN, drawnFrames, hiddenFrames = 0, 0, 0, 0
	local warns, warnN, warnErr = {}, 0, 0
	local glowStart, eruptOk, eruptBad, tileBad = {}, 0, 0, 0
	local prevStates = {}
	local chainMin, chainMax = math.huge, -math.huge
	local mismatch = 0
	local WARN = Config.Hazards.WARN_S
	while os.clock() - t0 < dur do
		RunService.Heartbeat:Wait()
		local now = Clock.now()
		local s = Hazards.snapshot()[id]
		if not s then chk(false, "hazard " .. id .. " is drawn by the client") return end
		if id == 5 then
			local states = string.split(s.tiles or "", ",")
			local V = Config.Hazards.LAVA
			for k, st in ipairs(states) do
				local tile = model:FindFirstChild("Tile_" .. k)
				local prev = prevStates[k]
				if st == "glow" and prev ~= nil and prev ~= "glow" then glowStart[k] = now end
				if st == "erupt" and prev ~= "erupt" then
					if glowStart[k] then if now - glowStart[k] >= WARN - 0.12 then eruptOk += 1 else eruptBad += 1 end end -- (a tile already glowing when the run began has no start to measure)
				end
				if tile then
					local tallOk = (st == "erupt") == (tile.Size.Y > 5)
					if not tallOk then tileBad += 1 end
				end
				prevStates[k] = st
			end
			poseN += 1
		else
			local want = SH.volumes(id, track, now)[1]
			if want then
				local pos = SH.toWorld(track, want).Position
				if s.bodyShown and s.bodyPos then
					poseN += 1
					maxPose = math.max(maxPose, (s.bodyPos - pos).Magnitude)
					drawnFrames += 1
				else
					hiddenFrames += 1
					mismatch += 1 -- (a frame's difference at the moment a run starts)
				end
			else
				hiddenFrames += 1
				if s.bodyShown then mismatch += 1 end -- (a frame's difference at the moment a run ends)
			end
			if s.warn and s.warnPos then table.insert(warns, { t = now + WARN, pos = s.warnPos }) end
			for i = #warns, 1, -1 do
				local w = warns[i]
				if now >= w.t then
					table.remove(warns, i)
					if s.bodyShown and s.bodyPos then
						warnN += 1
						warnErr = math.max(warnErr, flat(s.bodyPos, w.pos))
					end
				end
			end
			if id == 3 then
				local ch = model:FindFirstChild("Chain")
				if ch then chainMin = math.min(chainMin, ch.Position.X); chainMax = math.max(chainMax, ch.Position.X) end
			end
		end
	end
	if id == 5 then
		chk(eruptBad == 0 and eruptOk >= 4, "5 Lava: every tile glows at least 0.6 s before it erupts (the 0.6 s warning)", ("ok %d bad %d"):format(eruptOk, eruptBad))
		chk(tileBad == 0, "5 Lava: a tile is a raised block only while it erupts, flat otherwise", tileBad)
	else
		chk(poseN >= 40 and maxPose < 1.6, ("%d: the body is where Shared/Hazards.volumes says (<= 1.6 studs, the draw is up to one frame old)"):format(id), ("%d frames, worst %s"):format(poseN, r2(maxPose)))
		chk(warnN >= 3 and warnErr < 1.6, ("%d: the warning marker shows where the body arrives 0.6 s later (<= 1.6 studs)"):format(id), ("%d arrivals, worst %s"):format(warnN, r2(warnErr)))
		chk(mismatch <= 3, ("%d: the body is not drawn while the server has no volume (<= 3 frames at a run's end)"):format(id), mismatch)
		if id == 2 then chk(hiddenFrames > 0 and drawnFrames > 0, "2 Cactus: drawn while it runs, not drawn between runs", ("%d drawn, %d hidden frames"):format(drawnFrames, hiddenFrames)) end
		if id == 3 then chk(chainMax - chainMin > 5, "3 Anchor: the chain swings with the head", r2(chainMax - chainMin)) end
	end
end

-- ------------------------------------------------------------------------------------------------ base
function steps.spots(arg)
	local rebirths, extra = string.match(arg, "^(%d+),(%a+)$")
	rebirths = tonumber(rebirths)
	extra = extra == "on"
	wait(1.0)
	local plotId = ownPlotId()
	chk(plotId ~= nil, "the client has its own plot's Base.State")
	if not plotId then return end
	local plotM = workspace.Plots["Plot" .. plotId]
	local plot = Base.plot(plotId)
	local bad = {}
	for i = 1, 17 do
		local want = if i <= 10 then "n" elseif i <= 15 then (if i - 10 <= rebirths then "n" else "g") else (if extra then "n" else "h")
		local got = Base.look(plotId, i)
		if got ~= want then table.insert(bad, ("%d %s want %s"):format(i, got, want)) end
		local spot = plotM:FindFirstChild("Spot_" .. i)
		local pad = plotM:FindFirstChild("CashPad_" .. i)
		if not (spot and pad) then table.insert(bad, i .. " missing parts") else
			if spot:GetAttribute("Unlocked") ~= (want == "n") then table.insert(bad, i .. " Unlocked attr " .. tostring(spot:GetAttribute("Unlocked"))) end
			if plot.unlocked[i] ~= (want == "n") then table.insert(bad, i .. " state unlocked " .. tostring(plot.unlocked[i])) end
			if pad.LocalTransparencyModifier ~= spot.LocalTransparencyModifier then table.insert(bad, i .. " pad look differs") end
			local kind = spot:GetAttribute("SpotKind")
			if (i >= 11 and i <= 15 and kind ~= "rebirth") or (i >= 16 and kind ~= "extra") or (i <= 10 and kind ~= nil) then table.insert(bad, i .. " SpotKind " .. tostring(kind)) end
		end
	end
	chk(#bad == 0, ("%d rebirths, Extra Spots %s: spots 1-10 normal, rebirth spots 11-15 normal when earned else a ghost, 16-17 normal with the pass else not drawn (S7)"):format(rebirths, tostring(extra)), table.concat(bad, "; "):sub(1, 220))
end

function steps.placed(arg)
	local spot = tonumber(arg)
	wait(2.0)
	local plotId = ownPlotId()
	local snap = Base.snapshot()
	chk(snap.placed >= 1, "a placed boss is drawn on its spot", snap.placed)
	local pr = Base.promptOf(plotId, "spot" .. spot)
	local d = Base.plot(plotId).spots[spot]
	chk(pr and pr.enabled and pr.kind == "boss" and pr.action == N.ui.baseActions.boss and pr.key == "E" and pr.pad == "ButtonX", "the placed boss has an Interact prompt (E / X / tap) that says BOSS (S7)", pr and (tostring(pr.enabled) .. " " .. tostring(pr.kind) .. " " .. tostring(pr.key) .. "/" .. tostring(pr.pad)))
	chk(pr and pr.object == (Skin.get("Names.creatures." .. d.creatureId) or ""), "the prompt names the boss from the skin", pr and pr.object)
	local sp = workspace.Plots["Plot" .. plotId]["Spot_" .. spot]
	local prompt = sp:FindFirstChild("HFB_Interact")
	chk(prompt and prompt.HoldDuration == 0 and prompt.ClickablePrompt and not prompt.RequiresLineOfSight, "the prompt is one tap (no hold), clickable for touch")
	prompt:InputHoldBegin()
	prompt:InputHoldEnd()
	wait(0.5)
	chk(BossPanel.isOpen(), "the prompt opens the boss panel (BossPanel.open(info)) (S7)")
	BossPanel.close()
	-- pad cash
	local key = plotId .. ":" .. spot
	local text1 = Base.snapshot().pads[key]
	wait(2.2)
	local text2 = Base.snapshot().pads[key]
	chk(text1 and text2 and text2[1] > text1[1], "the pad's cash grows with the clock", text1 and text2 and (tostring(text1[2]) .. " -> " .. tostring(text2[2])))
	local sn = Base.snapshot()
	chk(sn.pads[key] ~= nil, "a cash label and stack show on the pad", sn.pads[key] and sn.pads[key][3])
	-- report the value for the driver to compare with the server's own number
	return { cash = sn.pads[key] and sn.pads[key][1], at = Clock.now() }
end

function steps.carried(arg)
	local spot = tonumber(arg)
	wait(1.0)
	local plotId = ownPlotId()
	local info = Carry.info()
	chk(info.state == "carrying" and info.origin == "spot" and info.level == 4, "Carry.State origin 'spot' and level 4 are kept (Carry.info)", ("%s %s %s"):format(tostring(info.state), tostring(info.origin), tostring(info.level)))
	chk(info.speed == 12, "Carry.State speed 12 is kept", info.speed)
	local snap = Carry.snapshot()
	chk(snap.carried and snap.lvl == string.gsub(Skin.get("Names.ui.boss.level"), "{n}", "4"), "the carried boss shows its level over its head", snap.lvl)
	local key = plotId .. ":" .. spot
	local a = Base.snapshot().pads[key]
	chk(Base.snapshot().placed == 0, "a picked-up boss is gone from its spot (the pad keeps its cash)")
	wait(2.2)
	local b = Base.snapshot().pads[key]
	chk((a == nil and b == nil) or (a ~= nil and b ~= nil and a[1] == b[1]), "the pad's cash does not grow while its boss is carried (S7)", a and b and (tostring(a[2]) .. " -> " .. tostring(b[2])))
	chk(Base.snapshot().sell == true, "the SELL tile shows while carrying inside the plot (S8)")
	local seen
	local orig = Confirm.sell
	Confirm.sell = function(i) seen = i end
	local ok = Base.sell()
	Confirm.sell = orig
	chk(ok and seen ~= nil, "Sell asks Confirm.sell(info) (S8)")
	return { amount = seen and seen.amount, creature = seen and seen.creatureId, level = seen and seen.level, bought = seen and seen.bought }
end

function steps.swap(arg)
	local spot = tonumber(arg)
	wait(1.0)
	local plotId = ownPlotId()
	local pr = Base.promptOf(plotId, "spot" .. spot)
	chk(pr and pr.enabled and pr.kind == "swap" and pr.action == N.ui.baseActions.swap, "carrying and standing by a placed boss, the prompt says SWAP (S8)", pr and (tostring(pr.enabled) .. " " .. tostring(pr.kind)))
	local seen
	local orig = Confirm.swap
	Confirm.swap = function(i) seen = i end
	local sp = workspace.Plots["Plot" .. plotId]["Spot_" .. spot]
	local prompt = sp:FindFirstChild("HFB_Interact")
	prompt:InputHoldBegin()
	prompt:InputHoldEnd()
	wait(0.4)
	Confirm.swap = orig
	chk(seen ~= nil and seen.spotIndex == spot, "the SWAP prompt asks Confirm.swap(info) with the spot (S8)", seen and seen.spotIndex)
	return { amount = seen and seen.amount, creature = seen and seen.creatureId, level = seen and seen.level }
end

function steps.crate()
	wait(1.0)
	local plotId = ownPlotId()
	local sn = Base.snapshot()
	chk(sn.crate == 1, "Base.Crate reached the client (one boss in the crate)", sn.crate)
	local pr = Base.promptOf(plotId, "crate")
	chk(pr and pr.enabled and pr.kind == "take" and pr.action == N.ui.baseActions.take and pr.key == "E", "the crate has a TAKE prompt while you carry nothing (S7)", pr and (tostring(pr.enabled) .. " " .. tostring(pr.kind)))
	local crate = workspace.Plots["Plot" .. plotId].Crate
	local gui = crate:FindFirstChild("CrateCount")
	chk(gui and gui.Enabled and gui:FindFirstChildOfClass("TextLabel").Text == "1" and gui.Size.X.Offset == 0, "the crate shows its count in a studs-sized label")
	local prompt = crate:FindFirstChild("HFB_Interact")
	local PPS = game:GetService("ProximityPromptService")
	local shown = false
	local c = PPS.PromptShown:Connect(function(pr) if pr == prompt then shown = true end end)
	local t0 = os.clock()
	while not shown and os.clock() - t0 < 4 do task.wait(0.1) end
	c:Disconnect()
	chk(shown, "the crate prompt is actually shown by ProximityPromptService", ("%.1f s"):format(os.clock() - t0))
	prompt:InputHoldBegin()
	task.wait(0.1)
	prompt:InputHoldEnd()
	wait(1.0)
	local info = Carry.info()
	chk(info.state == "carrying" and info.origin == "crate", "TAKE sends Base.TakeCrate and the boss is on the head (origin crate)", ("%s %s"):format(tostring(info.state), tostring(info.origin)))
end

function steps.bag(arg)
	wait(1.2)
	local plotId = ownPlotId()
	local plotM = workspace.Plots["Plot" .. plotId]
	local body = plotM.Bag.Body
	local tier = plotM:GetAttribute("BagTier")
	chk(body:GetAttribute("ClientTier") == tier, "the bag follows the plot attribute BagTier", ("attr %s client %s"):format(tostring(tier), tostring(body:GetAttribute("ClientTier"))))
	chk(arg ~= "" and tonumber(arg) == tier, "BagTier is the server's tier for the Strength level", tier)
	local pr = Base.promptOf(plotId, "bag")
	chk(pr and pr.enabled and pr.kind == "bag" and pr.key == "E" and pr.pad == "ButtonX", "the bag pad has an Interact prompt (E / X / tap) (S2)", pr and tostring(pr.enabled))
	local prompt = plotM.BagPad:FindFirstChild("HFB_Interact")
	prompt:InputHoldBegin()
	prompt:InputHoldEnd()
	wait(0.5)
	chk(BagPanel.isOpen(), "the prompt opens the bag panel (BagPanel.open()) (S2)")
	BagPanel.close()
	return { y = body.Size.Y }
end

function steps.dbg()
	for _, padId in ipairs({ "z1_roll1", "z1_roll2", "z1_roll3" }) do
		local m = padModel(padId)
		local e = Pads.entry(padId)
		local anchor = Patrol.anchor(m, Config.Zones.LANE)
		local bosses = {}
		for _, c in ipairs(m:GetChildren()) do if c:IsA("Model") then table.insert(bosses, c.Name .. "@" .. r2(c:GetPivot().Position.Z)) end end
		local want = Patrol.position(anchor, e.patrol, Clock.now())
		local st = BossVisuals.padState(padId)
		chk(true, padId, ("want z %s | %s | state %s fr %s wh %s"):format(r2(want.Z), table.concat(bosses, ","), tostring(st.creatureId), tostring(st.frozen), tostring(st.winHold)))
	end
end

-- ------------------------------------------------------------------------------------------------ auto ring
function steps.auto(arg)
	-- arg "good" or "perfect" or "off": the driver has set the pass hooks; this sends the real toggle remote
	local before = AutoRing.stats.taps
	if arg == "good" then Net.get("Bag", "AutoToggle"):FireServer({ on = true })
	elseif arg == "perfect" then Net.get("Bag", "PerfectToggle"):FireServer({ on = true })
	end
	local t0 = os.clock()
	wait(9.0)
	local taps = AutoRing.stats.taps - before
	if arg == "off" then
		chk(taps == 0, "with both toggles off the client taps nothing", taps)
	else
		chk(taps >= 4, "the client auto-taps every ring while the toggle is on (B23)", ("%d taps in %.1f s"):format(taps, os.clock() - t0))
		chk(AutoRing.stats.lastGrade == arg, "the auto tap's grade is " .. arg, AutoRing.stats.lastGrade)
	end
	return { taps = taps }
end

function steps.autooff()
	Net.get("Bag", "AutoToggle"):FireServer({ on = false })
	wait(0.3)
	Net.get("Bag", "PerfectToggle"):FireServer({ on = false })
	wait(0.8)
	local before = AutoRing.stats.taps
	wait(4.0)
	chk(AutoRing.stats.taps == before, "after both toggles go off the client stops (B23)", AutoRing.stats.taps - before)
end

-- ------------------------------------------------------------------------------------------------ runner
local function send(name, data)
	local ok, json = pcall(HttpService.JSONEncode, HttpService, data)
	if ok then Net.get("Profile", "TestReport"):FireServer({ name = name, json = json:sub(1, 950) }) end
	task.wait(0.15)
end

local function run(name, n, arg)
	out = {}
	local fn = steps[name]
	local vals
	if not fn then
		chk(false, "step " .. tostring(name) .. " exists")
	else
		local ok, res = pcall(fn, arg or "")
		if not ok then chk(false, name .. " ran without an error", tostring(res):sub(1, 200)) else vals = res end
	end
	for _, l in ipairs(out) do
		send("ca_line", { n = n, ok = l.ok, l = tostring(l.label):sub(1, 170), d = tostring(l.detail or ""):sub(1, 150) })
	end
	if vals then send("ca_val", { n = n, v = vals }) end
	send("ca_done", { n = n })
end

repeat task.wait(0.5) until lp.Character and Net.get("Profile", "TestReport")
workspace:GetAttributeChangedSignal("HFB_CA_Step"):Connect(function()
	local v = workspace:GetAttribute("HFB_CA_Step")
	if typeof(v) ~= "string" then return end
	local name, n = string.match(v, "^(.-):(%d+)$")
	if name then task.spawn(run, name, tonumber(n), workspace:GetAttribute("HFB_CA_Arg")) end
end)
send("ca_ready", { ok = true })
print("CA|probe ready")
