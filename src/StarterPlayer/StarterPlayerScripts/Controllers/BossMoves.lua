--!nonstrict
-- BossMoves: plays a boss's moves (m1-contract.md section H; style guide section 5). Client-side dressing only: it
-- reads events and never waits on, gates or touches the ring (it never yields).
--
--   BossMoves.play(model, name, opts?)  an overlay move (hit, attack, lastHeart, gloat, defeat). A new play cuts a
--                                       running one and starts from its first frame. When it ends the loop under it
--                                       (guard / idle) carries on; with none, the rest pose is restored.
--                                       opts.perfect (hitBig goes further), opts.onImpact(), opts.onDone(),
--                                       opts.speed, opts.hopTo (Vector3, defeat: where the hop onto the head lands).
--                                       A loop move name given to play is the same as loop.
--   BossMoves.loop(model, name, opts?)  the base loop (guard, idle, halfIdle, carryRock) at a random phase (opts.phase
--                                       in seconds, opts.speed a multiplier). Asking for the one already running does
--                                       nothing, so Fight can ask for guard again without a pop.
--   BossMoves.stop(model)               cut everything and put the model back at its exact rest pose.
--   BossMoves.isPlaying(model, name?)   any move (or the named one) is running or holding.
--   BossMoves.current(model)            -> base name, overlay name
--   BossMoves.startPadIdle(model)       loop(model, "idle")
--   BossMoves.setSpeed(model, x)        the base loop's speed (carry rock follows the run)
--
-- B11 (TEAM CALL, animator-vfx, M1-09): moves play on Motor6D.Transform of each non-root group's joint (Part0 =
-- Body, Part1 = the group, C1 = CFrame.new(-pivotInGroup), identity rotations, so Transform = identity is the rest
-- pose and a Transform rotation turns the group about its pivot). The root group, Body, is the whole model: it moves
-- as Body.CFrame (rest pivot x pose); Body.PivotOffset must put the pivot at the middle of the feet. Scale is
-- MeshPart.Size scaled about the pivot with the position corrected, because a joint cannot scale; a Body scale also
-- carries every other group's pivot with it (they scale about the feet).
-- Cost: one Heartbeat connection while anything plays; a move allocates CFrames per frame and no tables.
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Moves = require(ReplicatedStorage.Shared.Moves)
local Skin = require(ReplicatedStorage.Shared.Skin)

local BossMoves = {}

local FLASH_LEN = 0.05
local GROUPS = Moves.GROUPS
local rad = math.rad
local STYLE = { Quad = Enum.EasingStyle.Quad, Back = Enum.EasingStyle.Back, Sine = Enum.EasingStyle.Sine }

local states = setmetatable({}, { __mode = "k" })
local active = {} -- state -> true while a runner is still advancing
local conn

local function ease(alpha, name)
	local dir = name == "Sine" and Enum.EasingDirection.InOut or Enum.EasingDirection.Out
	return TweenService:GetValue(alpha, STYLE[name], dir)
end

-- Compile a move once: per group, the keys it appears in, flattened.
local compiled = setmetatable({}, { __mode = "k" })
local function compile(move)
	local c = compiled[move]
	if c then
		return c
	end
	c = {}
	for _, g in ipairs(GROUPS) do
		local track = {}
		for _, k in ipairs(move.keys or {}) do
			local pose = k.pose[g]
			if pose then
				local p, r, s = pose.p, pose.r, pose.s
				local sx, sy, sz = 1, 1, 1
				if type(s) == "number" then
					sx, sy, sz = s, s, s
				elseif s then
					sx, sy, sz = s[1], s[2], s[3]
				end
				table.insert(track, {
					t = k.t, ease = k.ease,
					px = p and p[1] or 0, py = p and p[2] or 0, pz = p and p[3] or 0,
					rx = r and r[1] or 0, ry = r and r[2] or 0, rz = r and r[3] or 0,
					sx = sx, sy = sy, sz = sz,
				})
			end
		end
		if #track > 0 then
			c[g] = track
		end
	end
	compiled[move] = c
	return c
end

-- Sample a group's track at time tt: returns px,py,pz,rx,ry,rz,sx,sy,sz (deviation from rest; scale 1 = rest).
local function sampleTrack(track, tt)
	local n = #track
	local first = track[1]
	if tt <= first.t then
		if first.t <= 0 then
			return first.px, first.py, first.pz, first.rx, first.ry, first.rz, first.sx, first.sy, first.sz
		end
		local a = ease(tt / first.t, first.ease)
		return first.px * a, first.py * a, first.pz * a, first.rx * a, first.ry * a, first.rz * a,
			1 + (first.sx - 1) * a, 1 + (first.sy - 1) * a, 1 + (first.sz - 1) * a
	end
	for i = 1, n - 1 do
		local k0, k1 = track[i], track[i + 1]
		if tt < k1.t and tt >= k0.t then
			local a = ease((tt - k0.t) / (k1.t - k0.t), k1.ease)
			return k0.px + (k1.px - k0.px) * a, k0.py + (k1.py - k0.py) * a, k0.pz + (k1.pz - k0.pz) * a,
				k0.rx + (k1.rx - k0.rx) * a, k0.ry + (k1.ry - k0.ry) * a, k0.rz + (k1.rz - k0.rz) * a,
				k0.sx + (k1.sx - k0.sx) * a, k0.sy + (k1.sy - k0.sy) * a, k0.sz + (k1.sz - k0.sz) * a
		end
	end
	local last = track[n]
	return last.px, last.py, last.pz, last.rx, last.ry, last.rz, last.sx, last.sy, last.sz
end

-- State -------------------------------------------------------------------------------------------------------
local function initState(model)
	local body = model.PrimaryPart or model:FindFirstChild("Body", true)
	if not body then
		warn("BossMoves: " .. model:GetFullName() .. " has no Body")
		return nil
	end
	local st = {
		model = model, body = body,
		H = model:GetAttribute("H") or 4,
		bodyType = model:GetAttribute("BodyType") or 2,
		creatureId = model:GetAttribute("CreatureId"),
		restCF = body.CFrame,
		restPivot = body:GetPivot(),
		groups = {},
		base = nil, overlay = nil, flashEnd = nil,
	}
	local restPivotInv = st.restPivot:Inverse()
	st.bodyCentre = (restPivotInv * body.CFrame).Position -- the Body part's centre from the pivot (the feet)
	for _, name in ipairs(GROUPS) do
		local part = model:FindFirstChild(name, true)
		if part and part:IsA("BasePart") then
			local g = { name = name, part = part, restSize = part.Size, restColor = part.Color, restMaterial = part.Material, sized = false }
			if part == body then
				g.cOff = (restPivotInv * body.CFrame).Position -- where the part's centre sits from the pivot
			else
				for _, d in ipairs(model:GetDescendants()) do
					if d:IsA("Motor6D") and d.Part1 == part then
						g.joint = d
						break
					end
				end
				if not g.joint then
					warn("BossMoves: no Motor6D for " .. name .. " in " .. model:GetFullName())
				else
					g.cOff = g.joint.C1:Inverse().Position
					-- the group's pivot, where it rests, from the Body's pivot (for a Body scale)
					-- M2-22 fix: the joint hangs off the Body PART, whose centre already moves by (scale-1) x its own offset from the feet when the
					-- Body is scaled, so the extra shift a pivot needs is (scale-1) x (its offset from the feet MINUS the Body centre's). Without the
					-- subtraction a squash dragged every group down by (1-sy) x the Body centre height (0.9 stud on Ember Drake, 0.14 on the frog).
					g.pivotFromBody = (restPivotInv * (body.CFrame * g.joint.C0)).Position - st.bodyCentre
				end
			end
			if part == body or g.joint then
				st.groups[name] = g
			end
		end
	end
	return st
end

local function setFlash(st, on)
	for _, g in pairs(st.groups) do
		if on then
			g.part.Material = Enum.Material.Neon
			local c = Skin.get("Tokens.colors.white")
			if c then
				g.part.Color = c
			end
		else
			g.part.Color = g.restColor
			g.part.Material = g.restMaterial
		end
	end
	st.flashEnd = on and (os.clock() + FLASH_LEN) or nil
end

local function restore(st)
	if st.flashEnd then
		setFlash(st, false)
	end
	for _, g in pairs(st.groups) do
		if g.joint then
			g.joint.Transform = CFrame.identity
		end
		if g.sized then
			g.part.Size = g.restSize
			g.sized = false
		end
	end
	st.body.CFrame = st.restCF
end

local function release(st)
	active[st] = nil
	states[st.model] = nil
	if next(active) == nil and conn then
		conn:Disconnect()
		conn = nil
	end
end

-- Apply the pose of both layers at `now`.
local scratch = { 0, 0, 0, 0, 0, 0, 1, 1, 1 }
local function layerSample(r, gname, now)
	if not r then
		return nil
	end
	local track = r.tracks[gname]
	if not track then
		return nil
	end
	local move = r.move
	local tt = (now - r.t0) * r.speed + r.phase
	if move.loop then
		tt = tt % move.length
	elseif tt > move.length then
		tt = move.length
	end
	local px, py, pz, rx, ry, rz, sx, sy, sz = sampleTrack(track, tt)
	local ps = r.pscale
	if ps ~= 1 then
		px, py, pz, rx, ry, rz = px * ps, py * ps, pz * ps, rx * ps, ry * ps, rz * ps
	end
	local bl = move.blendIn
	if bl then
		local el = (now - r.t0) * r.speed
		if el < bl then
			local w = ease(el / bl, "Quad")
			px, py, pz, rx, ry, rz = px * w, py * w, pz * w, rx * w, ry * w, rz * w
			sx, sy, sz = 1 + (sx - 1) * w, 1 + (sy - 1) * w, 1 + (sz - 1) * w
		end
	end
	return px, py, pz, rx, ry, rz, sx, sy, sz
end

local function apply(st, now)
	local base = st.base
	local ov = st.overlay
	if ov and ov.move.suppressBase then
		base = nil
	end
	local H = st.H
	local sbx, sby, sbz = 1, 1, 1
	local bodyg = st.groups.Body
	-- Body first (its scale moves every other group's pivot)
	local function combined(gname)
		local a1, a2, a3, a4, a5, a6, a7, a8, a9 = layerSample(base, gname, now)
		local b1, b2, b3, b4, b5, b6, b7, b8, b9 = layerSample(ov, gname, now)
		if not a1 and not b1 then
			return 0, 0, 0, 0, 0, 0, 1, 1, 1
		elseif not a1 then
			return b1, b2, b3, b4, b5, b6, b7, b8, b9
		elseif not b1 then
			return a1, a2, a3, a4, a5, a6, a7, a8, a9
		end
		return a1 + b1, a2 + b2, a3 + b3, a4 + b4, a5 + b5, a6 + b6, a7 * b7, a8 * b8, a9 * b9
	end
	if bodyg then
		local px, py, pz, rx, ry, rz, sx, sy, sz = combined("Body")
		sbx, sby, sbz = sx, sy, sz
		local pivotCF = st.restPivot * CFrame.new(px * H, py * H, pz * H) * CFrame.Angles(rad(rx), rad(ry), rad(rz))
		-- the hop onto the head: a world-space slide over the move's hop window
		if ov and ov.hopTo and ov.move.hopWindow then
			local w0, w1 = ov.move.hopWindow[1], ov.move.hopWindow[2]
			local el = (now - ov.t0) * ov.speed
			local a = math.clamp((el - w0) / (w1 - w0), 0, 1)
			if a > 0 then
				a = ease(a, "Back")
				pivotCF = CFrame.new((ov.hopTo - st.restPivot.Position) * a) * pivotCF
			end
		end
		local c = bodyg.cOff
		st.body.CFrame = pivotCF * CFrame.new(c.X * sx, c.Y * sy, c.Z * sz)
		if sx ~= 1 or sy ~= 1 or sz ~= 1 or bodyg.sized then
			local rs = bodyg.restSize
			st.body.Size = Vector3.new(rs.X * sx, rs.Y * sy, rs.Z * sz)
			bodyg.sized = sx ~= 1 or sy ~= 1 or sz ~= 1
		end
	end
	for _, name in ipairs(GROUPS) do
		local g = st.groups[name]
		if g and g.joint then
			local px, py, pz, rx, ry, rz, sx, sy, sz = combined(name)
			local pb = g.pivotFromBody
			local tx = px * H + (sbx - 1) * pb.X
			local ty = py * H + (sby - 1) * pb.Y
			local tz = pz * H + (sbz - 1) * pb.Z
			local c = g.cOff
			g.joint.Transform = CFrame.new(tx, ty, tz) * CFrame.Angles(rad(rx), rad(ry), rad(rz))
				* CFrame.new((sx - 1) * c.X, (sy - 1) * c.Y, (sz - 1) * c.Z)
			if sx ~= 1 or sy ~= 1 or sz ~= 1 or g.sized then
				local rs = g.restSize
				g.part.Size = Vector3.new(rs.X * sx, rs.Y * sy, rs.Z * sz)
				g.sized = sx ~= 1 or sy ~= 1 or sz ~= 1
			end
		end
	end
end

local function finishOverlay(st, now)
	local ov = st.overlay
	local done = ov.opts and ov.opts.onDone
	if ov.move.final == "hold" then
		ov.held = true
	else
		st.overlay = nil
	end
	if done then
		local ok, err = pcall(done)
		if not ok then
			warn("BossMoves onDone: " .. tostring(err))
		end
	end
	if st.overlay == nil and st.base == nil then
		restore(st)
		release(st)
	elseif st.overlay and st.overlay.held and st.base == nil then
		active[st] = nil -- nothing left to advance
		if next(active) == nil and conn then
			conn:Disconnect()
			conn = nil
		end
	end
end

local function step()
	local now = os.clock()
	for st in pairs(active) do
		if not st.model:IsDescendantOf(game) then
			release(st)
		else
			local ov = st.overlay
			if ov and not ov.held then
				local el = (now - ov.t0) * ov.speed
				if not ov.flashed and ov.move.flashAt and el >= ov.move.flashAt then
					ov.flashed = true
					setFlash(st, true)
				end
				if not ov.impacted and ov.move.impactAt and el >= ov.move.impactAt then
					ov.impacted = true
					local f = ov.opts and ov.opts.onImpact
					if f then
						local ok, err = pcall(f)
						if not ok then
							warn("BossMoves onImpact: " .. tostring(err))
						end
					end
				end
			end
			if st.flashEnd and now >= st.flashEnd then
				setFlash(st, false)
			end
			local over = ov and not ov.held and (now - ov.t0) * ov.speed >= ov.move.length
			if ov and not ov.held then
				apply(st, now)
			elseif st.base then
				apply(st, now)
			end
			if over then
				apply(st, now)
				finishOverlay(st, now)
			end
		end
	end
end

local function ensureConn(st)
	active[st] = true
	if not conn then
		conn = RunService.Heartbeat:Connect(step)
	end
end

local function newRunner(move, opts, now)
	opts = opts or {}
	return {
		move = move, tracks = compile(move), t0 = now, speed = opts.speed or 1, phase = opts.phase or 0,
		pscale = (opts.perfect and move.perfectScale) or 1, opts = opts, hopTo = opts.hopTo,
	}
end

-- M2-34 streaming: with StreamingEnabled a Workspace model can be on the client before its parts (Default/Nonatomic) or be
-- streamed out and back. Boss models are Atomic/Persistent now (studio/SetupBosses, BuildReviewLine), so they arrive whole;
-- this is the second line: a request on a model that is not whole yet is kept (the latest per model) and retried when parts
-- arrive, for up to WAIT_WHOLE seconds, then with what is there. It never yields. TEAM CALL M2-34-2.
local WAIT_WHOLE = 10
local REQUIRED = { "Body", "Head", "FistL", "FistR" }
local pending = setmetatable({}, { __mode = "k" }) -- model -> { fn, deadline }
local forced = setmetatable({}, { __mode = "k" }) -- model -> true while a timed-out request is replayed with what is there

local function streamingNeedsWait(model: Instance): boolean
	if not (workspace.StreamingEnabled and model:IsDescendantOf(workspace)) then
		return false
	end
	for _, g in ipairs(REQUIRED) do
		local p = model:FindFirstChild(g, true)
		if not (p and p:IsA("BasePart")) then
			return true
		end
	end
	local joints = 0
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Motor6D") then
			joints += 1
		end
	end
	return joints < #REQUIRED - 1
end

local function deferUntilWhole(model: Instance, fn)
	local entry = pending[model]
	if entry then
		entry.fn = fn -- the latest request wins; the waiter already running picks it up
		return
	end
	entry = { fn = fn, deadline = os.clock() + WAIT_WHOLE }
	pending[model] = entry
	task.spawn(function()
		while pending[model] == entry do
			local timedOut = os.clock() >= entry.deadline
			if timedOut or not streamingNeedsWait(model) then
				pending[model] = nil
				if timedOut and not (model.PrimaryPart or model:FindFirstChild("Body", true)) then
					warn("BossMoves: " .. model:GetFullName() .. " has no Body after " .. WAIT_WHOLE .. " s of streaming")
					return
				end
				forced[model] = true
				entry.fn()
				forced[model] = nil
				return
			end
			task.wait(0.1)
		end
	end)
end

local function getState(model)
	local st = states[model]
	if not st then
		st = initState(model)
		if st then
			states[model] = st
		end
	end
	return st
end

-- nil when the model is not whole yet (the request is kept and replayed by deferUntilWhole)
local function stateOrDefer(model, replay)
	local st = states[model]
	if st then
		return st
	end
	if not forced[model] and streamingNeedsWait(model) then
		deferUntilWhole(model, replay)
		return nil
	end
	return getState(model)
end

-- API ---------------------------------------------------------------------------------------------------------
function BossMoves.loop(model: Model, name: string, opts)
	local st = stateOrDefer(model, function()
		BossMoves.loop(model, name, opts)
	end)
	if not st then
		return false
	end
	local move = Moves.resolve(st.bodyType, st.creatureId, name)
	if not move or not move.loop then
		warn("BossMoves.loop: no loop move " .. tostring(name))
		return false
	end
	if st.base and st.base.move == move then
		return true
	end
	opts = opts or {}
	local o = { speed = opts.speed, phase = opts.phase or math.random() * move.length }
	st.base = newRunner(move, o, os.clock())
	st.base.name = name
	ensureConn(st)
	return true
end

function BossMoves.play(model: Model, name: string, opts)
	local st = stateOrDefer(model, function()
		BossMoves.play(model, name, opts)
	end)
	if not st then
		return false
	end
	local move = Moves.resolve(st.bodyType, st.creatureId, name)
	if not move then
		warn("BossMoves.play: no move " .. tostring(name))
		return false
	end
	if move.loop then
		return BossMoves.loop(model, name, opts)
	end
	local now = os.clock()
	-- cut a running move cleanly: the new one starts from its first frame
	if st.flashEnd then
		setFlash(st, false)
	end
	st.overlay = newRunner(move, opts, now)
	st.overlay.name = name
	ensureConn(st)
	-- frame 1 of the new move is drawn now, not on the next Heartbeat
	apply(st, now)
	return true
end

function BossMoves.stop(model: Model)
	pending[model] = nil -- a request still waiting for the model's parts is cancelled too
	local st = states[model]
	if not st then
		return
	end
	restore(st)
	release(st)
end

function BossMoves.isPlaying(model: Model, name: string?): boolean
	local st = states[model]
	if not st then
		return false
	end
	if name then
		return (st.base and st.base.name == name) or (st.overlay and st.overlay.name == name) or false
	end
	return st.base ~= nil or st.overlay ~= nil
end

function BossMoves.current(model: Model)
	local st = states[model]
	if not st then
		return nil, nil
	end
	return st.base and st.base.name, st.overlay and st.overlay.name
end

-- M2-12 (TEAM CALL M2-12-1): the rest pivot a running state was started at (nil when no state: the model is at its rest
-- pose). Controllers that carry a model somewhere else (the patrol, the carry) re-base the raw pose with it.
function BossMoves.restPivot(model: Model): CFrame?
	local st = states[model]
	return st and st.restPivot or nil
end

function BossMoves.startPadIdle(model: Model)
	return BossMoves.loop(model, "idle")
end

function BossMoves.setSpeed(model: Model, x: number)
	local st = states[model]
	if st and st.base then
		local now = os.clock()
		-- keep the phase continuous when the speed changes
		st.base.phase = st.base.phase + (now - st.base.t0) * st.base.speed
		st.base.t0 = now
		st.base.speed = x
	end
end

return BossMoves
