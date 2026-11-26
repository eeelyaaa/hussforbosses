--!nonstrict
-- Controllers/Base: the base plot as client visuals of the server's Base.State (m1-contract.md C, I;
-- m1-carry-base-income.md). The server decides every result; this module shows and asks.
--   * Glow: an empty spot of the player's plot glows (a client Highlight) while its replicated attribute Glow is true.
--   * Place prompt: while carrying and a glowing spot is in the server's range (14 studs flat, 10 vertical); the prompt
--     or interact (E / X) sends Base.Place { spotIndex } for the nearest such spot.
--   * Placed boss: a clone standing on its spot facing its cash pad, playing "halfIdle"; one that appears after the first
--     Base.State of its plot lands: a short drop, then the thump (BossMoves hitGood, a 0.1 s squash of the Body).
--   * Cash on a pad: income x min(floor(now - stamp), capSeconds), shown as a "$N" label and a stack of slabs over the
--     CashPad (the label refreshes 4 times a second; no per-boss loop). Base.Collected pops "+$N" into the counter.
-- API: Base.init(deps{views, BossMoves, Carry}), Base.snapshot().
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Net = require(Shared:WaitForChild("Net"))
local Skin = require(Shared.Skin)
local Clock = require(script.Parent.Clock)
local BossVisuals = require(script.Parent.BossVisuals)
local Input = require(script.Parent.Input)
local Kit = require(script.Parent.Parent.Ui.Kit)

local C = Skin.Tokens.colors
local Base = {}
local views, moves, carryCtl = nil, nil, nil
local plots = {} -- plotId -> { owner, spots = { [i] = data or false }, seen }
local placed = {} -- "plot:i" -> { model, uid }
local pads = {} -- "plot:i" -> { gui, label, slabs = {parts}, cash }
local glow = {} -- spot part -> Highlight
local placeShown = false
local pendingUntil = 0
local STACK_MAX = 6
local DROP_FROM = 4 -- studs a placed boss falls from
local DROP_S = 0.12

local function call(target, method, ...)
	if target and type(target[method]) == "function" then
		local ok, err = pcall(target[method], ...)
		if not ok then
			warn(("[HFB] Base: %s failed: %s"):format(method, tostring(err)))
		end
	end
end

local function root(): BasePart?
	local c = Players.LocalPlayer.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function plotModel(plotId)
	local folder = workspace:FindFirstChild("Plots")
	return folder and folder:FindFirstChild("Plot" .. tostring(plotId))
end

local function partOf(plotId, prefix: string, i: number): BasePart?
	local plot = plotModel(plotId)
	local p = plot and plot:FindFirstChild(prefix .. i)
	return p and p:IsA("BasePart") and p or nil
end

-- ------------------------------------------------------------------ glow
local function trackSpot(spot: Instance)
	if not spot:IsA("BasePart") or glow[spot] ~= nil then
		return
	end
	local h = Instance.new("Highlight")
	h.Name = "GlowFx"
	h.Adornee = spot
	h.FillColor = C.arrowYellow
	h.OutlineColor = C.white
	h.FillTransparency = 0.5
	h.OutlineTransparency = 0
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Enabled = spot:GetAttribute("Glow") == true
	h.Parent = spot
	glow[spot] = h
	spot:GetAttributeChangedSignal("Glow"):Connect(function()
		h.Enabled = spot:GetAttribute("Glow") == true
	end)
end

-- ------------------------------------------------------------------ placed boss
local function standOn(spot: BasePart, pad: BasePart?): CFrame
	local feet = spot.Position + Vector3.new(0, spot.Size.Y / 2, 0)
	local dir = Vector3.new(0, 0, -1)
	if pad then
		local d = pad.Position - spot.Position
		d = Vector3.new(d.X, 0, d.Z)
		if d.Magnitude > 0.1 then
			dir = d.Unit
		end
	end
	return CFrame.lookAt(feet, feet + dir)
end

local function removePlaced(key: string)
	local v = placed[key]
	if v then
		if moves and v.model.Parent then
			call(moves, "stop", v.model)
		end
		v.model:Destroy()
		placed[key] = nil
	end
end

local function showPlaced(plotId, i: number, data, landing: boolean)
	local key = plotId .. ":" .. i
	local spot = partOf(plotId, "Spot_", i)
	if not spot then
		return
	end
	local model = BossVisuals.make(data.creatureId, Config.Carry.MAX_HEIGHT)
	if not model then
		return
	end
	local rest = standOn(spot, partOf(plotId, "CashPad_", i))
	placed[key] = { model = model, uid = data.uid }
	if not landing then
		model:PivotTo(rest)
		call(moves, "loop", model, "halfIdle")
		return
	end
	-- lands: a short fall, then the thump
	local from = rest + Vector3.new(0, DROP_FROM, 0)
	model:PivotTo(from)
	local t0 = os.clock()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		if not model.Parent then
			conn:Disconnect()
			return
		end
		local a = math.clamp((os.clock() - t0) / DROP_S, 0, 1)
		model:PivotTo(from:Lerp(rest, a * a))
		if a >= 1 then
			conn:Disconnect()
			model:PivotTo(rest)
			call(moves, "play", model, "hitGood", { onDone = function()
				if model.Parent then
					call(moves, "loop", model, "halfIdle")
				end
			end })
		end
	end)
end

-- ------------------------------------------------------------------ cash on pads
local function padFor(plotId, i: number)
	local key = plotId .. ":" .. i
	local d = pads[key]
	if d and d.part.Parent then
		return d
	end
	local part = partOf(plotId, "CashPad_", i)
	if not part then
		return nil
	end
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(110, 30)
	gui.StudsOffset = Vector3.new(0, 3.5, 0)
	gui.AlwaysOnTop = false
	gui.LightInfluence = 0
	gui.MaxDistance = 150
	gui.Adornee = part
	gui.Enabled = false
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Name = "Cash"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.FontFace = Kit.Font()
	label.TextScaled = true
	label.TextColor3 = C.white
	label.Text = ""
	label.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = C.ink
	stroke.Parent = label
	d = { part = part, gui = gui, label = label, slabs = {}, cash = 0 }
	pads[key] = d
	return d
end

local function setStack(d, count: number)
	for n = 1, STACK_MAX do
		local s = d.slabs[n]
		if n <= count then
			if not s then
				s = Instance.new("Part")
				s.Name = "Slab" .. n
				s.Anchored, s.CanCollide, s.CanQuery, s.CanTouch, s.CastShadow = true, false, false, false, false
				s.Material = Enum.Material.SmoothPlastic
				s.Color = C.cashGreen
				s.Size = Vector3.new(d.part.Size.X * 0.6, 0.35, d.part.Size.Z * 0.5)
				s.CFrame = d.part.CFrame * CFrame.new(0, d.part.Size.Y / 2 + 0.175 + (n - 1) * 0.37, 0)
				s.Parent = BossVisuals.fx()
				d.slabs[n] = s
			end
		elseif s then
			s:Destroy()
			d.slabs[n] = nil
		end
	end
end

local function refreshPads()
	local now = Clock.now()
	for plotId, plot in pairs(plots) do
		for i = 1, Config.Base.SPOTS_AT_START do
			local data = plot.spots[i]
			local d = padFor(plotId, i)
			if d then
				local cash = 0
				local frac = 0
				if data then
					local secs = math.min(math.floor(now - data.stamp), data.capSeconds)
					cash = math.max(0, data.income * math.max(secs, 0))
					frac = cash / math.max(data.income * data.capSeconds, 1)
				end
				d.cash = cash
				d.gui.Enabled = cash > 0
				d.label.Text = "$" .. Kit.commas(cash)
				setStack(d, if cash > 0 then math.clamp(math.ceil(frac * STACK_MAX), 1, STACK_MAX) else 0)
			end
		end
	end
end

-- ------------------------------------------------------------------ Base.State
local function onState(p)
	if typeof(p) ~= "table" or typeof(p.plotId) ~= "number" or typeof(p.spots) ~= "table" then
		return
	end
	local plotId = p.plotId
	local plot = plots[plotId]
	local first = plot == nil
	plot = plot or { spots = {} }
	plots[plotId] = plot
	plot.owner = p.ownerUserId
	for i = 1, Config.Base.SPOTS_AT_START do
		local data = p.spots[i] or false
		local key = plotId .. ":" .. i
		local have = placed[key]
		plot.spots[i] = data
		if data then
			if not have or have.uid ~= data.uid then
				removePlaced(key)
				showPlaced(plotId, i, data, not first and have == nil)
			end
		elseif have then
			removePlaced(key)
		end
	end
	refreshPads()
end

local function onCollected(p)
	if typeof(p) ~= "table" or typeof(p.spotIndex) ~= "number" or typeof(p.amount) ~= "number" then
		return
	end
	local mine = Players.LocalPlayer.UserId
	for plotId, plot in pairs(plots) do
		if plot.owner == mine then
			local d = pads[plotId .. ":" .. p.spotIndex]
			if d then
				local cam = workspace.CurrentCamera
				local v = cam and cam:WorldToViewportPoint(d.part.Position + Vector3.new(0, 3, 0))
				call(views.Counters, "popCash", p.amount, v and Vector2.new(v.X, v.Y))
				if plot.spots[p.spotIndex] then
					plot.spots[p.spotIndex].stamp = Clock.now() -- shown empty at once; Base.State follows with the real stamp
				end
			end
		end
	end
	refreshPads()
end

-- ------------------------------------------------------------------ Place prompt
-- The nearest glowing spot of the player's plot the server would accept, or nil.
local function placeTarget(): number?
	if carryCtl.state() ~= "carrying" then
		return nil
	end
	local r = root()
	if not r then
		return nil
	end
	local best, bestD
	for _, spot in ipairs(CollectionService:GetTagged("HFB_Spot")) do
		local idx = spot:GetAttribute("SpotIndex")
		if spot:GetAttribute("Glow") == true and typeof(idx) == "number" and spot:IsA("BasePart") then
			local plot = spot.Parent
			local owner = plot and plot:GetAttribute("OwnerUserId")
			local d = r.Position - spot.Position
			local flat = Vector2.new(d.X, d.Z).Magnitude
			if (owner == nil or owner == 0 or owner == Players.LocalPlayer.UserId) and flat <= Config.Base.PLACE_RANGE and math.abs(d.Y) <= 10 then
				if not bestD or flat < bestD then
					best, bestD = idx, flat
				end
			end
		end
	end
	return best
end

local function requestPlace()
	local idx = placeTarget()
	if not idx or os.clock() < pendingUntil then
		return
	end
	pendingUntil = os.clock() + 0.3
	Net.get("Base", "Place"):FireServer({ spotIndex = idx })
end

local pulse = 0
local nextRefresh = 0
local function update(dt: number)
	local want = placeTarget() ~= nil
	if want and not placeShown then
		placeShown = true
		call(views.Prompts, "show", "place", Input.kind())
	elseif not want and placeShown then
		placeShown = false
		call(views.Prompts, "hide", "place")
	end
	pulse += dt
	local tr = 0.5 + 0.2 * math.sin(pulse * 5)
	for _, h in pairs(glow) do
		if h.Enabled then
			h.FillTransparency = tr
		end
	end
	if os.clock() >= nextRefresh then
		nextRefresh = os.clock() + 0.25
		refreshPads()
	end
end

function Base.snapshot()
	local out = { place = placeShown, placed = 0, uids = {}, pads = {}, glowOn = 0 }
	for key, v in pairs(placed) do
		out.placed += 1
		local base = moves and select(1, moves.current(v.model))
		out.uids[key] = { v.uid, base }
	end
	for key, d in pairs(pads) do
		if d.cash > 0 then
			out.pads[key] = { d.cash, d.label.Text, #d.slabs }
		end
	end
	for _, h in pairs(glow) do
		if h.Enabled then
			out.glowOn += 1
		end
	end
	return out
end

function Base.init(deps)
	views = deps.views or {}
	moves, carryCtl = deps.BossMoves, deps.Carry
	for _, spot in ipairs(CollectionService:GetTagged("HFB_Spot")) do
		trackSpot(spot)
	end
	CollectionService:GetInstanceAddedSignal("HFB_Spot"):Connect(trackSpot)
	Net.get("Base", "State").OnClientEvent:Connect(onState)
	Net.get("Base", "Collected").OnClientEvent:Connect(onCollected)
	Input.onInteract(function()
		if placeShown then
			requestPlace()
		end
	end)
	call(views.Prompts, "onPress", "place", requestPlace)
	Input.onKindChanged(function(kind)
		if placeShown then
			call(views.Prompts, "show", "place", kind)
		end
	end)
	RunService.RenderStepped:Connect(update)
end

return Base
