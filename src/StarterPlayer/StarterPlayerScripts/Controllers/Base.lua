--!nonstrict
-- Controllers/Base: the base plot as client visuals of the server's Base.State (m1-contract.md C, I;
-- m1-carry-base-income.md). The server decides every result; this module shows and asks.
--   * Glow: an empty spot of the player's plot glows (a client Highlight) while its replicated attribute Glow is true.
--   * Place prompt: while carrying and a glowing spot is in the server's range (14 studs flat, 10 vertical); the prompt
--     or interact (E / X) sends Base.Place { spotIndex } for the nearest such spot.
--   * Placed boss: a clone standing on its spot facing its cash pad, playing "halfIdle"; one that appears after the first
--     Base.State of its plot lands: a short drop, then the thump (BossMoves hitGood, a 0.1 s squash of the Body).
--   * Cash on a pad: min(padCash + income x floor(now - stamp), income x capSeconds) (a picked-up boss's pad stays at padCash),
--     shown as a "$N" label and a stack of slabs over the CashPad (the label refreshes 4 times a second; no per-boss loop).
--     Base.Collected pops "+$N" into the counter.
-- M2-12: all 17 spots. Base.State { unlocked[1..17], rebirthSpots, extraSpots, spots[i] = false | { uid, creatureId, level, income,
--     stamp, padCash, capSeconds, bought, carried, nextCost } }. A spot that is not unlocked is a ghost (rebirth spots 11 to 15,
--     drawn faint) or not drawn at all (the Extra Spots pass's 16 and 17, SpotKind "extra"); the spot parts' Unlocked, Glow and
--     SpotKind attributes agree. A picked-up boss (carried) leaves its spot empty on screen; its pad keeps its cash.
--   * Interact (E / X / tap; ProximityPrompts on the player's own plot, the touch button is the prompt): a placed boss opens
--     BossPanel.open(info); carrying and a placed boss = Swap (Confirm.swap); the crate (when it holds a boss and you carry nothing)
--     = Base.TakeCrate; the bag pad opens BagPanel.open(). Sell = the SELL tile / Input "sell" / D-pad down, carrying inside the
--     plot (Confirm.sell). Every one only asks; the server decides.
--   * The crate: a count over it. The bag: its look follows the plot attribute BagTier (a taller body per tier; the skin's own
--     per-tier models are M3).
-- API: Base.init(deps{views, BossMoves, Carry}), Base.snapshot().
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
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
local WorldLabel = require(script.Parent.Parent.Ui.WorldLabel)

local C = Skin.Tokens.colors
local N = Skin.Names
local Base = {}
local views, moves, carryCtl = nil, nil, nil
local plots = {} -- plotId -> { owner, spots = { [i] = data or false }, unlocked = { [i] = bool }, extra, rebirthSpots, crateCount, seen }
local crateItems = {} -- Base.Crate (owner): { { uid, creatureId, level, bought } }
local myRebirths = 0
local prompts = {} -- "plotId:spot3" / ":crate" / ":bag" -> { prompt, kind }
local plotBox = {} -- plotId -> { cf, size } (the plot's bounding box, for "inside the plot")
local bagBase = {} -- Body part -> { size, cf }
local crateLabel = nil
local sellTile = nil
local ui = {} -- lazily required Ui modules: BossPanel, BagPanel, Confirm, Hud
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
	local folder = workspace:FindFirstChild("Plots") -- stream-ok: called on every use (nil when streamed out), never cached
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
	local gui = WorldLabel.new({
		name = "CashLabel",
		adornee = part,
		studsW = 4,
		studsH = 1.2,
		offset = Vector3.new(0, 3.5, 0),
		enabled = false,
	})
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
		for i = 1, Config.Base.MAX_SPOTS do
			local data = plot.spots[i]
			local d = if data then padFor(plotId, i) else pads[plotId .. ":" .. i]
			if d then
				local cash = 0
				local frac = 0
				if data then
					local capCash = data.income * data.capSeconds
					local stored = if typeof(data.padCash) == "number" then data.padCash else 0
					local secs = if data.carried then 0 else math.max(math.floor(now - data.stamp), 0) -- a picked-up boss does not fill
					cash = math.max(0, math.min(stored + data.income * secs, capCash))
					frac = cash / math.max(capCash, 1)
				end
				d.cash = cash
				d.gui.Enabled = cash > 0
				d.label.Text = "$" .. Kit.commas(cash)
				setStack(d, if cash > 0 then math.clamp(math.ceil(frac * STACK_MAX), 1, STACK_MAX) else 0)
			end
		end
	end
end

-- ------------------------------------------------------------------ spots: ghosts and hidden
-- LocalTransparencyModifier on the spot and its cash pad: 0 unlocked, 0.65 a ghost (a rebirth spot not yet earned), 1 not drawn
-- (an Extra Spots spot without the pass).
local GHOST = 0.65
local function applySpotLook(plotId, i: number)
	local plot = plots[plotId]
	if not plot then
		return
	end
	local spot, pad = partOf(plotId, "Spot_", i), partOf(plotId, "CashPad_", i)
	local unlocked = plot.unlocked[i]
	if unlocked == nil and spot then
		unlocked = spot:GetAttribute("Unlocked") == true
	end
	local kind = spot and spot:GetAttribute("SpotKind")
	local mode = if unlocked then 0 elseif kind == "extra" then 1 else GHOST
	for _, part in ipairs({ spot, pad }) do
		if part then
			part.LocalTransparencyModifier = mode
		end
	end
	local d = pads[plotId .. ":" .. i]
	if d then
		for _, s_ in pairs(d.slabs) do
			s_.LocalTransparencyModifier = if mode == 0 then 0 else 1
		end
	end
end

local function applyAllSpotLooks(plotId)
	for i = 1, Config.Base.MAX_SPOTS do
		applySpotLook(plotId, i)
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
	plot = plot or { spots = {}, unlocked = {} }
	plots[plotId] = plot
	plot.owner = p.ownerUserId
	plot.extra = p.extraSpots == true
	plot.rebirthSpots = if typeof(p.rebirthSpots) == "number" then p.rebirthSpots else 0
	plot.crateCount = if typeof(p.crateCount) == "number" then p.crateCount else 0
	for i = 1, Config.Base.MAX_SPOTS do
		local data = p.spots[i] or false
		local key = plotId .. ":" .. i
		local have = placed[key]
		plot.spots[i] = data
		plot.unlocked[i] = if typeof(p.unlocked) == "table" then p.unlocked[i] == true else i <= Config.Base.SPOTS_AT_START
		if data and not data.carried then
			if not have or have.uid ~= data.uid then
				removePlaced(key)
				showPlaced(plotId, i, data, not first and have == nil)
			end
		elseif have then
			removePlaced(key) -- empty, or the boss was picked up (it is on the player's head; the pad keeps its cash)
		end
	end
	applyAllSpotLooks(plotId)
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
				local data = plot.spots[p.spotIndex]
				if data then
					data.stamp = Clock.now() -- shown empty at once; Base.State follows with the real stamp
					data.padCash = 0
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

-- ------------------------------------------------------------------ interact: boss panel, swap, crate, bag, sell
local function ownPlotId(): number?
	local me = Players.LocalPlayer.UserId
	for plotId, plot in pairs(plots) do
		if plot.owner == me then
			return plotId
		end
	end
	return nil
end

local function uiModule(name: string)
	if ui[name] == nil then
		local folder = script.Parent.Parent:FindFirstChild("Ui")
		local m = folder and folder:FindFirstChild(name)
		local ok, mod = false, nil
		if m then
			ok, mod = pcall(require, m)
		end
		ui[name] = if ok then mod else false
	end
	return ui[name] or nil
end

local function carryInfo()
	if carryCtl and type(carryCtl.info) == "function" then
		return carryCtl.info()
	end
	return nil
end

-- income x levels x rebirths x 2x Cash, as the client can know it: the placed bosses give the exact factor, else rebirths only.
local function incomeFactor(): number
	local me = Players.LocalPlayer.UserId
	for _, plot in pairs(plots) do
		if plot.owner == me then
			for _, data in pairs(plot.spots) do
				if data and not data.carried and data.income > 0 then
					local base = Config.Zones.INCOME[data.creatureId]
					if base and base > 0 then
						return data.income / (base * Config.Income.LEVEL_MULT(data.level))
					end
				end
			end
		end
	end
	return Config.Income.REBIRTH_MULT(myRebirths)
end

local function insideOwnPlot(): boolean
	local plotId, r = ownPlotId(), root()
	if not (plotId and r) then
		return false
	end
	local box = plotBox[plotId]
	if not box then
		local plot = plotModel(plotId)
		if not plot then
			return false
		end
		local cf, size = plot:GetBoundingBox()
		box = { cf = cf, size = size }
		plotBox[plotId] = box
	end
	local l = box.cf:PointToObjectSpace(r.Position)
	return math.abs(l.X) <= box.size.X / 2 and math.abs(l.Z) <= box.size.Z / 2
end

local function sellOpen()
	local info = carryInfo()
	local Confirm = uiModule("Confirm")
	if not (info and info.state == "carrying" and info.creatureId and Confirm and insideOwnPlot()) or Confirm.isOpen() then
		return false
	end
	local base = Config.Zones.INCOME[info.creatureId] or 0
	local level = info.level or 1
	Confirm.sell({
		creatureId = info.creatureId,
		level = level,
		amount = Confirm.estimate(base * Config.Income.LEVEL_MULT(level) * incomeFactor()),
		bought = info.bought or false,
	})
	return true
end
Base.sell = sellOpen

local function spotData(plotId, i: number)
	local plot = plots[plotId]
	return plot and plot.spots[i] or nil
end

local function openBossPanel(plotId, i: number)
	local d, BossPanel = spotData(plotId, i), uiModule("BossPanel")
	if d and BossPanel then
		BossPanel.open({ uid = d.uid, creatureId = d.creatureId, level = d.level, income = d.income, spot = i, nextCost = d.nextCost })
	end
end

local function openSwap(plotId, i: number)
	local d, Confirm = spotData(plotId, i), uiModule("Confirm")
	if d and Confirm and not Confirm.isOpen() then
		Confirm.swap({ creatureId = d.creatureId, level = d.level, amount = Confirm.estimate(d.income), bought = d.bought or false, spotIndex = i })
	end
end

local crateAt = 0
local function takeCrate()
	local item = crateItems[1]
	local cs = carryCtl.state()
	if item and os.clock() >= crateAt and cs ~= "carrying" and cs ~= "dropped" then
		crateAt = os.clock() + 0.4
		Net.get("Base", "TakeCrate"):FireServer({ uid = item.uid })
	end
end

local function openBag()
	local BagPanel = uiModule("BagPanel")
	if BagPanel then
		BagPanel.open()
	end
end

-- one ProximityPrompt per interactable of the player's own plot, created when first wanted; Enabled follows the state
local function setPrompt(key: string, part: BasePart?, kind: string?, objectText: string?, fn)
	local e = prompts[key]
	if not kind or not part then
		if e and e.prompt.Enabled then
			e.prompt.Enabled = false
		end
		return
	end
	if not (e and e.prompt.Parent) then
		local pr = Instance.new("ProximityPrompt")
		pr.Name = "HFB_Interact"
		pr.MaxActivationDistance = 9
		pr.HoldDuration = 0
		pr.RequiresLineOfSight = false
		pr.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
		pr.KeyboardKeyCode = Enum.KeyCode.E
		pr.GamepadKeyCode = Enum.KeyCode.ButtonX
		pr.Enabled = false
		pr.Parent = part
		e = { prompt = pr }
		pr.Triggered:Connect(function()
			if e.fn then
				e.fn()
			end
		end)
		prompts[key] = e
	end
	e.fn = fn
	e.kind = kind
	local words = N.ui.baseActions
	local text = words[kind]
	if e.prompt.ActionText ~= text then
		e.prompt.ActionText = text
	end
	e.prompt.ObjectText = objectText or ""
	e.prompt.Enabled = true
end

local function bossName(creatureId: string): string
	return Skin.get("Names.creatures." .. creatureId) or ""
end

local function reconcile()
	local me = Players.LocalPlayer.UserId
	local cs = carryCtl.state()
	local carrying = cs == "carrying"
	for plotId, plot in pairs(plots) do
		local mine = plot.owner == me
		for i = 1, Config.Base.MAX_SPOTS do
			local key = plotId .. ":spot" .. i
			local kind, obj = nil, nil
			local data = plot.spots[i]
			if mine and plot.unlocked[i] and data and not data.carried then
				kind = if carrying then "swap" else "boss"
				obj = bossName(data.creatureId)
			end
			if kind or prompts[key] then
				setPrompt(key, partOf(plotId, "Spot_", i), kind, obj, function()
					if kind == "swap" then
						openSwap(plotId, i)
					else
						openBossPanel(plotId, i)
					end
				end)
			end
		end
		local plotM = plotModel(plotId)
		local crate = plotM and plotM:FindFirstChild("Crate")
		local crateKind = if mine and cs ~= "carrying" and cs ~= "dropped" and #crateItems > 0 then "take" else nil
		if crateKind or prompts[plotId .. ":crate"] then
			setPrompt(plotId .. ":crate", crate and crate:IsA("BasePart") and crate or nil, crateKind, N.ui.baseActions.crate, takeCrate)
		end
		local bagKind = if mine and not carrying then "bag" else nil
		if bagKind or prompts[plotId .. ":bag"] then
			local pad = plotM and (plotM:FindFirstChild("BagPad"))
			setPrompt(plotId .. ":bag", pad and pad:IsA("BasePart") and pad or nil, bagKind, nil, openBag)
		end
	end
	-- the crate's count, over the crate of the player's own plot
	local own = ownPlotId()
	local plotM = own and plotModel(own)
	local crate = plotM and plotM:FindFirstChild("Crate")
	if crate and crate:IsA("BasePart") then
		if not (crateLabel and crateLabel.gui.Parent) then
			local gui = WorldLabel.new({ name = "CrateCount", adornee = crate, studsW = 4, studsH = 2, offset = Vector3.new(0, crate.Size.Y / 2 + 1.5, 0), enabled = false })
			local label = Instance.new("TextLabel")
			label.Name = "Count"
			label.BackgroundTransparency = 1
			label.Size = UDim2.fromScale(1, 1)
			label.FontFace = Kit.Font()
			label.TextScaled = true
			label.TextColor3 = C.white
			label.Parent = gui
			local stroke = Instance.new("UIStroke")
			stroke.Thickness = 2
			stroke.Color = C.ink
			stroke.Parent = label
			crateLabel = { gui = gui, label = label }
		end
		crateLabel.label.Text = tostring(#crateItems)
		crateLabel.gui.Enabled = #crateItems > 0
	end
	-- the Sell tile follows "carrying inside the plot"
	if sellTile then
		sellTile.setVisible(carrying and insideOwnPlot())
	end
end

-- ------------------------------------------------------------------ the bag's look by tier (plot attribute BagTier)
local TIER_GROW = 0.06 -- body height x (1 + 0.06 x (tier - 1)); the skin's per-tier models are M3
local watchedPlots = {}
local function applyBagTier(plotM: Instance)
	local bag = plotM:FindFirstChild("Bag")
	local body = bag and bag:FindFirstChild("Body")
	if not (body and body:IsA("BasePart")) then
		return
	end
	local tier = plotM:GetAttribute("BagTier")
	if typeof(tier) ~= "number" then
		tier = bag:GetAttribute("BagTier")
	end
	tier = if typeof(tier) == "number" then math.clamp(tier, 1, 6) else 1
	local base = bagBase[body]
	if not base then
		base = { size = body.Size, cf = body.CFrame }
		bagBase[body] = base
	end
	local k = 1 + TIER_GROW * (tier - 1)
	body.Size = Vector3.new(base.size.X, base.size.Y * k, base.size.Z)
	body.CFrame = base.cf * CFrame.new(0, (base.size.Y * k - base.size.Y) / 2, 0)
	body:SetAttribute("ClientTier", tier)
end

local function watchPlots()
	local folder = workspace:FindFirstChild("Plots") -- stream-ok: watchPlots runs again on every refresh
	if not folder then
		return
	end
	for _, plotM in ipairs(folder:GetChildren()) do
		if plotM:IsA("Model") and not watchedPlots[plotM] then
			watchedPlots[plotM] = true
			applyBagTier(plotM)
			plotM:GetAttributeChangedSignal("BagTier"):Connect(function()
				applyBagTier(plotM)
			end)
		end
	end
end

local pulse = 0
local nextRefresh = 0
local nextReconcile = 0
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
	if os.clock() >= nextReconcile then
		nextReconcile = os.clock() + 0.2
		call({ run = reconcile }, "run")
		if os.clock() % 1 < 0.25 then
			watchPlots()
		end
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
	out.prompts = 0
	for _, e in pairs(prompts) do
		if e.prompt.Enabled then
			out.prompts += 1
		end
	end
	out.sell = sellTile ~= nil and sellTile.holder.Visible
	out.crate = #crateItems
	return out
end

-- For the M2-12 check: the look of spot i of a plot ("n" normal, "g" ghost, "h" not drawn), and what the prompts say.
function Base.look(plotId, i: number): string
	local spot = partOf(plotId, "Spot_", i)
	local m = spot and spot.LocalTransparencyModifier or 0
	return if m >= 1 then "h" elseif m > 0 then "g" else "n"
end
function Base.promptOf(plotId, key: string)
	local e = prompts[plotId .. ":" .. key]
	return e and { enabled = e.prompt.Enabled, kind = e.kind, action = e.prompt.ActionText, object = e.prompt.ObjectText, key = e.prompt.KeyboardKeyCode.Name, pad = e.prompt.GamepadKeyCode.Name, dist = e.prompt.MaxActivationDistance } or nil
end
function Base.plot(plotId)
	return plots[plotId]
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
	Net.get("Base", "Crate").OnClientEvent:Connect(function(p)
		if typeof(p) == "table" and typeof(p.items) == "table" then
			crateItems = p.items
		end
	end)
	Net.get("Profile", "Changed").OnClientEvent:Connect(function(p)
		if typeof(p) == "table" and typeof(p.rebirths) == "number" then
			myRebirths = p.rebirths
		end
	end)
	-- the SELL tile (Hud tile row) and the "sell" input; until Controllers/Input has the action (M2-07), D-pad down is read here
	task.spawn(function()
		local Hud = uiModule("Hud")
		local t0 = os.clock()
		while Hud and not Hud.root() and os.clock() - t0 < 10 do
			task.wait(0.2)
		end
		if Hud and Hud.tile and Hud.root() then
			sellTile = Hud.tile("sell", N.ui.baseActions.sell, 6, sellOpen)
			if sellTile then
				sellTile.setVisible(false)
			end
		end
	end)
	if type(Input.on) == "function" then
		Input.on("sell", sellOpen)
	else
		UserInputService.InputBegan:Connect(function(input, processed)
			if not processed and input.KeyCode == Enum.KeyCode.DPadDown then
				sellOpen()
			end
		end)
	end
	watchPlots()
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
