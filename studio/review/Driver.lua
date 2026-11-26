if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- ReviewLine driver (M2-32). ModuleScript HFB_ReviewLineDriver in StarterPlayerScripts, built by studio/BuildReviewLine.lua.
-- Studio only. start(root, opts?) loops every boss through its moves and the two dummies through the avatar clips, with a
-- 1 s break between moves, forever. opts.log = a table that receives { who, move, t0, t1 } rows (timing check).
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local D = {}
D.BREAK = 1.0
D.BOSS_MOVES = { "guard", "idle", "halfIdle", "hitGood", "hitPerfect", "hitBig", "attack", "gloat", "lastHeart", "defeat", "carryRock" }
D.LOOP_HOLD = { guard = 3.0, carryRock = 3.0 } -- other loops play their full length
D.CLIPS = { "jab3", "bigThird", "flinch", "carryHold", "stealLift", "knockdown", "stun" }
D.CLIP_LOOP_HOLD = 2.0 -- carryHold loops: show two turns

function D.start(root, opts)
	opts = opts or {}
	local log = opts.log
	local ctl = script.Parent:FindFirstChild("Controllers")
	local BossMoves = require(ctl.BossMoves)
	local Avatar = require(ctl.Avatar)
	local Moves = require(ReplicatedStorage.Shared.Moves)
	local handle = { running = true, log = log }
	local function setNow(plate, text)
		local l = plate and plate:FindFirstChild("Now", true)
		l = l and l:FindFirstChild("Label", true)
		if l then l.Text = text end
	end
	local function plateOf(name) return root.Plates:FindFirstChild("Plate_" .. name) end
	local function row(who, move, t0, t1, extra)
		if log then table.insert(log, { who = who, move = move, t0 = t0, t1 = t1, note = extra }) end
	end
	for _, boss in ipairs(root.Bosses:GetChildren()) do
		task.spawn(function()
			local plate = plateOf(boss.Name)
			local bt, id = boss:GetAttribute("BodyType"), boss:GetAttribute("CreatureId")
			while handle.running do
				for _, name in ipairs(D.BOSS_MOVES) do
					if not handle.running then break end
					local move = Moves.resolve(bt, id, name)
					if move then
						setNow(plate, name)
						local t0 = os.clock()
						local len = move.length
						if move.loop then
							BossMoves.loop(boss, name, { phase = 0 })
							len = D.LOOP_HOLD[name] or move.length
						else
							BossMoves.play(boss, name)
						end
						task.wait(len)
						local t1 = os.clock()
						row(boss.Name, name, t0, t1, "len " .. len)
						setNow(plate, "- break -")
						if move.final ~= "hold" then BossMoves.stop(boss) end -- the defeat keeps its last pose through the break
						task.wait(D.BREAK)
						BossMoves.stop(boss)
					end
				end
			end
		end)
	end
	for _, rig in ipairs(root.Dummies:GetChildren()) do
		task.spawn(function()
			local plate = plateOf(rig.Name)
			pcall(function() Avatar.equipGloves(rig) end)
			task.wait(1)
			while handle.running do
				for _, clip in ipairs(D.CLIPS) do
					if not handle.running then break end
					setNow(plate, clip)
					local t0 = os.clock()
					local track = Avatar.playClip(clip, nil, rig)
					if track then
						local w = 0 -- the first play of a clip loads it: Length is 0 until then
						while track.Length == 0 and w < 5 do task.wait(0.1) w += 0.1 end
						t0 = os.clock()
						local len = track.Length
						if track.Looped then len = D.CLIP_LOOP_HOLD end
						task.wait(len)
						Avatar.stopClip(clip, rig)
						row(rig.Name, clip, t0, os.clock(), "len " .. len)
					else
						task.wait(1)
						row(rig.Name, clip, t0, os.clock(), "NO TRACK")
					end
					setNow(plate, "- break -")
					task.wait(D.BREAK)
				end
			end
		end)
	end
	function handle.stop()
		handle.running = false
		for _, b in ipairs(root.Bosses:GetChildren()) do BossMoves.stop(b) end
	end
	return handle
end

return D
