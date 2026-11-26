if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M1-10 play-mode check: gloves on R15 / R6 / scaled R15 rigs, and the jab3 + bigThird clips playing through
-- Avatar.startJab on test rigs. NOT a loader-run script: it needs play mode. Run it with the Studio MCP's
-- run_script_in_play_mode (mode start_play) after `run("BuildClips.lua")` has built ServerStorage.HFB_Clips.
-- Prints one report; deletes every rig it makes. (No place-guard line: it is not run through the loader.)
local RS = game:GetService("RunService")
local SP = game:GetService("StarterPlayer")
local Players = game:GetService("Players")
local KSP = game:GetService("KeyframeSequenceProvider")

local out, rigs = {}, {}
local function log(s) table.insert(out, s) end
local ok, err = xpcall(function()
	local Avatar = require(SP.StarterPlayerScripts.Controllers.Avatar)
	local slot = 0
	local function rig(rigType, scales)
		local d = Instance.new("HumanoidDescription")
		if scales then for k, v in pairs(scales) do d[k] = v end end
		local m = Players:CreateHumanoidModelFromDescription(d, Enum.HumanoidRigType[rigType])
		m.Name = "HFBTestRig_" .. rigType .. (scales and "_scaled" or "")
		m.HumanoidRootPart.Anchored = true
		slot += 1
		m.Parent = workspace
		m:PivotTo(CFrame.new(300 + slot * 8, 5, 0))
		table.insert(rigs, m)
		return m
	end
	-- 1. gloves
	local cases = {
		{ "R15", nil }, { "R6", nil },
		{ "R15", { HeightScale = 1.25, WidthScale = 0.8, HeadScale = 1.2, BodyTypeScale = 0, ProportionScale = 0 } },
		{ "R15", { HeightScale = 0.9, WidthScale = 1.0, HeadScale = 0.8 } },
	}
	for _, c in ipairs(cases) do
		local m = rig(c[1], c[2])
		task.wait(0.2)
		local f = Avatar.equipGloves(m)
		assert(f, "no gloves for " .. m.Name)
		for _, side in ipairs({ "L", "R" }) do
			local g = f["Glove" .. side]
			local root = g.PrimaryPart
			local weld = root:FindFirstChild("GloveWeld")
			local handName = if c[1] == "R15" then (side == "L" and "LeftHand" or "RightHand") else (side == "L" and "Left Arm" or "Right Arm")
			local hand = m[handName]
			local welded = weld and weld.Part0 == hand and weld.Part1 == root
			local size = g:GetExtentsSize()
			local before = (g:GetPivot().Position - hand.Position).Magnitude
			m:PivotTo(m:GetPivot() * CFrame.new(0, 0, -6)) -- move the body: the glove must come along
			task.wait(0.1)
			local after = (g:GetPivot().Position - hand.Position).Magnitude
			local follows = math.abs(after - before) < 0.05
			log(("%s %s glove%s: weld %s>%s %s | follows a 6 stud move %s (%.2f -> %.2f) | extents %.2f x %.2f x %.2f, head %.2f (height/head %.2f) | massless %s collide %s"):format(
				m.Name, handName, side, weld and weld.Part0.Name or "none", weld and weld.Part1.Name or "none", welded and "PASS" or "FAIL",
				follows and "PASS" or "FAIL", before, after, size.X, size.Y, size.Z, m.Head.Size.Y, size.Y / m.Head.Size.Y,
				tostring(root.Massless), tostring(root.CanCollide)))
		end
		-- the avatar keeps every one of its own parts
		local n = 0
		for _, d in ipairs(m:GetChildren()) do if d:IsA("BasePart") then n += 1 end end
		log(("%s keeps %d own body parts, %d glove parts (nothing hidden: Transparency of Head %.0f)"):format(m.Name, n, #f:GetDescendants() - 2, m.Head.Transparency))
	end
	-- 2. clips, registered locally from ServerStorage.HFB_Clips (Studio only)
	local clips = game.ServerStorage.HFB_Clips.KeyframeSequences
	local ids = { R15 = {}, R6 = {} }
	for _, rt in ipairs({ "R15", "R6" }) do
		ids[rt].jab3 = KSP:RegisterKeyframeSequence(clips["Jab3_" .. rt])
		ids[rt].bigThird = KSP:RegisterKeyframeSequence(clips["BigThird_" .. rt])
	end
	Avatar.setClipIds(ids)
	for _, rt in ipairs({ "R15", "R6" }) do
		local m = rig(rt)
		task.wait(0.3)
		local hum = m.Humanoid
		local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
		local jn = if rt == "R15" then { R = "RightShoulder", L = "LeftShoulder" } else { R = "Right Shoulder", L = "Left Shoulder" }
		local function joint(name)
			for _, x in ipairs(m:GetDescendants()) do
				if x.Name == name and (x:IsA("Motor6D") or x:IsA("AnimationConstraint")) then return x end
			end
		end
		local jR, jL = joint(jn.R), joint(jn.L)
		Avatar.preload(m)
		task.wait(0.5)
		Avatar.hitLog = {}
		local t0 = os.clock()
		assert(Avatar.startJab("good", t0, m), "startJab returned false")
		local samples = {}
		local conn = RS.Heartbeat:Connect(function()
			local function ang(j)
				local x, _, z = j.Transform:ToEulerAnglesXYZ()
				return math.abs(math.deg(rt == "R15" and x or z))
			end
			table.insert(samples, { os.clock() - t0, ang(jL), ang(jR) })
		end)
		task.wait(0.9)
		conn:Disconnect()
		local function windows(col)
			local w, cur = {}, nil
			for _, s in ipairs(samples) do
				if s[col] >= 80 then
					if not cur then cur = { s[1], s[1], s[col] } else cur[2] = s[1] cur[3] = math.max(cur[3], s[col]) end
				elseif cur then table.insert(w, cur) cur = nil end
			end
			if cur then table.insert(w, cur) end
			return w
		end
		for col, name in ipairs({ "L", "R" }) do
			local parts = {}
			for _, w in ipairs(windows(col + 1)) do table.insert(parts, ("[%.3f..%.3f s, peak %.0f deg]"):format(w[1], w[2], w[3])) end
			log(rt .. " " .. name .. " shoulder >= 80 deg: " .. table.concat(parts, " ") .. "   (beats 0 / 0.213 / 0.401)")
		end
		local hl = {}
		for _, h in ipairs(Avatar.hitLog) do table.insert(hl, ("%s%d@%.3f"):format(h.track, h.n, h.elapsed - t0)) end
		log(rt .. " Hit markers, seconds after t0: " .. table.concat(hl, " "))
		-- a late start seeks: start 0.2 s late, the jab track should read about 0.2 + the wait
		Avatar.cancel(m)
		task.wait(0.15)
		Avatar.startJab("good", os.clock() - 0.2, m)
		task.wait(0.03)
		local tp = {}
		for _, t in ipairs(animator:GetPlayingAnimationTracks()) do table.insert(tp, ("%s@%.3f"):format(t.Name, t.TimePosition)) end
		log(rt .. " late start (0.2 s late) playing tracks: " .. table.concat(tp, " ") .. " (expect jab about 0.23)")
		Avatar.cancel(m)
		task.wait(0.2)
		local still = #animator:GetPlayingAnimationTracks()
		log(rt .. " after cancel, tracks still playing: " .. still)
	end
end, debug.traceback)
if not ok then log("ERROR " .. tostring(err)) end
for _, m in ipairs(rigs) do m:Destroy() end
print("\n" .. table.concat(out, "\n"))
