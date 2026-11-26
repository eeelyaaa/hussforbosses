--!nonstrict
-- Controllers/Shield (M2-16; brief system 10; m2-contract.md C "Shield"): the client of the lock shield. It shows and asks.
--   * Raise: Q (keyboard) or Y (gamepad) inside your own base, or a tap on the HUD shield plate (touch / mouse), sends
--     Shield.Raise {}. Stepping on the lock pad needs no remote (the server watches the pad). The server refuses anything
--     that is not 'ready' (Shield.Result -> Toasts shows the reason; nothing here toasts).
--   * Break shield: within Config.Shield.BREAK_RANGE of another player's plot edge while its shield shows (up / joining /
--     instant) the Break prompt is on (Ui/Prompts.showBreak; the press is Prompts' own: UseCharge with a charge, else BuyBreaker).
--     E / X routes to Prompts.activate("breakShield"); a disabled plate does nothing.
--   * The lock board: LockBoard.show() while the owner stands at the board part of their plot, hide() away from it.
--   * The world: the lock pad takes the shield's colour (cyan up, grey otherwise) and a translucent cyan gate stands in the
--     plot's entrance while its shield is up (client-only Parts, no collision; the server pushes visitors out).
-- API: Shield.start(ctx) (AUTO_START), Shield.state(), Shield.raise().
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Skin = require(Shared:WaitForChild("Skin"))

local C = Skin.Tokens.colors
local CFG = Config.Shield
local Shield = { AUTO_START = true }

local ctx = nil
local states = {} -- plotId -> Shield.State payload
local gates = {} -- plotId -> { part, up }
local padLook = {} -- plotId -> "up"|"off"
local breakShown = nil -- "plotId|kind"
local boardShown = false
local lastRaise = 0
local tapConn = nil
local tapOn = nil
local stats = { raiseSent = 0 }
local BOARD_RANGE = 10

local function call(target, method, ...)
	if target and type(target[method]) == "function" then
		local ok, err = pcall(target[method], ...)
		if not ok then
			warn(("[HFB] Shield: %s failed: %s"):format(method, tostring(err)))
		end
	end
end

local function root(): BasePart?
	local c = Players.LocalPlayer.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function flat(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function plotById(plotId: number)
	local folder = workspace:FindFirstChild("Plots") -- stream-ok: read on every use, nil-tolerant (callers skip a plot that is not streamed in)
	return folder and folder:FindFirstChild("Plot" .. plotId)
end

local function showing(plotId: number): boolean
	local st = states[plotId]
	return st ~= nil and (st.state == "up" or st.state == "joining" or st.state == "instant")
end

-- Flat distance from a point to the plot's footprint (0 inside): the bounding box in the plot's own frame.
local function edgeDistance(plotM: Model, pos: Vector3): number
	local cf, size = plotM:GetBoundingBox()
	local rel = cf:PointToObjectSpace(pos)
	local dx = math.max(math.abs(rel.X) - size.X / 2, 0)
	local dz = math.max(math.abs(rel.Z) - size.Z / 2, 0)
	return math.sqrt(dx * dx + dz * dz)
end

local function ownPlotId(): number?
	local base = ctx and ctx.Base
	local me = Players.LocalPlayer.UserId
	for plotId = 1, 8 do
		local plot = base and base.plot and base.plot(plotId)
		if plot and plot.owner == me then
			return plotId
		end
	end
	return nil
end

local function ownerName(userId: number?): string
	local plr = userId and Players:GetPlayerByUserId(userId)
	return if plr then plr.DisplayName else ""
end

-- ------------------------------------------------------------------ raise
function Shield.raise()
	if os.clock() - lastRaise < 0.6 then
		return
	end
	local own = ownPlotId()
	local r = root()
	local plotM = own and plotById(own)
	if not (own and r and plotM and edgeDistance(plotM, r.Position) <= 0) then
		return -- not inside your own base: nothing is sent
	end
	lastRaise = os.clock()
	stats.raiseSent += 1
	Net.get("Shield", "Raise"):FireServer({})
end

-- A tap on the HUD shield plate raises it too (the brief's "shield button" on touch). One invisible button over the plate,
-- re-added if the HUD rebuilds.
local function ensureTap()
	local Hud = ctx.Hud
	local hudRoot = Hud and Hud.root and Hud.root()
	local plate = hudRoot and hudRoot:FindFirstChild("ShieldPlate", true)
	if plate == tapOn and tapConn then
		return
	end
	if tapConn then
		tapConn:Disconnect()
		tapConn = nil
	end
	tapOn = plate
	if not plate then
		return
	end
	local b = plate:FindFirstChild("RaiseTap")
	if not b then
		b = Instance.new("TextButton")
		b.Name = "RaiseTap"
		b.Text = ""
		b.AutoButtonColor = false
		b.BackgroundTransparency = 1
		b.Size = UDim2.fromScale(1, 1)
		b.ZIndex = 20
		b.Parent = plate
	end
	tapConn = b.Activated:Connect(Shield.raise)
end

-- ------------------------------------------------------------------ the world
local function gateFor(plotId: number)
	local g = gates[plotId]
	if g and g.part.Parent then
		return g
	end
	local plotM = plotById(plotId)
	local ent = plotM and plotM:FindFirstChild("Entrance")
	if not (ent and ent:IsA("BasePart")) then
		return nil
	end
	local p = Instance.new("Part")
	p.Name = "HFB_ShieldGate"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = C.shieldCyan
	p.Transparency = 1
	p.Size = ent.Size
	p.CFrame = ent.CFrame
	p.Parent = workspace
	g = { part = p, up = false }
	gates[plotId] = g
	return g
end

local function paintWorld(plotId: number)
	local up = showing(plotId)
	local g = gateFor(plotId)
	if g and g.up ~= up then
		g.up = up
		g.part.Transparency = if up then 0.65 else 1
	end
	local plotM = plotById(plotId)
	local pad = plotM and plotM:FindFirstChild("LockPad")
	if pad and pad:IsA("BasePart") then
		local want = if up then "up" else "off"
		if padLook[plotId] ~= want or pad:GetAttribute("HFB_ShieldLook") ~= want then
			padLook[plotId] = want
			pad:SetAttribute("HFB_ShieldLook", want)
			pad.Color = if up then C.shieldCyan else C.disabledGrey
		end
	end
end

-- ------------------------------------------------------------------ per frame
local function update()
	if not ctx then
		return
	end
	local r = root()
	local Prompts = ctx.views.Prompts
	local own = ownPlotId()
	-- the break prompt: the nearest other plot within the range whose shield shows
	local bestId, bestD = nil, math.huge
	if r then
		for plotId, _ in pairs(states) do
			if plotId ~= own and showing(plotId) then
				local plot = ctx.Base.plot and ctx.Base.plot(plotId)
				local plotM = plotById(plotId)
				if plot and plot.owner and plotM then
					local d = edgeDistance(plotM, r.Position)
					if d <= CFG.BREAK_RANGE and d < bestD then
						bestId, bestD = plotId, d
					end
				end
			end
		end
	end
	local stealing = ctx.views.Prompts.parts and ctx.views.Prompts.parts()
	stealing = stealing and stealing.kinds and stealing.kinds.steal.button.root.Visible
	if bestId and not stealing then
		local plot = ctx.Base.plot(bestId)
		local kind = ctx.Input.kind()
		local key = bestId .. "|" .. kind .. "|" .. tostring(plot.owner)
		if key ~= breakShown then
			breakShown = key
			call(Prompts, "showBreak", bestId, ownerName(plot.owner), kind)
		end
	elseif breakShown then
		breakShown = nil
		call(Prompts, "hideBreak")
	end
	-- the lock board for the owner
	local want = false
	if r and own then
		local plotM = plotById(own)
		local board = plotM and plotM:FindFirstChild("LockBoard")
		if board and board:IsA("BasePart") then
			want = flat(r.Position, board.Position) <= BOARD_RANGE
		end
	end
	if want ~= boardShown then
		boardShown = want
		local LB = ctx.LockBoard
		if LB then
			call(LB, if want then "show" else "hide")
		end
	end
end

function Shield.state()
	local gatesUp = 0
	for _, g in pairs(gates) do
		if g.up then
			gatesUp += 1
		end
	end
	return { breakShown = breakShown, board = boardShown, gatesUp = gatesUp, pads = padLook, stats = stats, own = ownPlotId() }
end

-- Test seam (client probe): feed a Shield.State payload without the remote.
function Shield._onState(p)
	if typeof(p) == "table" and typeof(p.plotId) == "number" then
		states[p.plotId] = p
		paintWorld(p.plotId)
	end
end

function Shield.start(c)
	if ctx then
		return
	end
	ctx = c
	local ok, LockBoard = pcall(function()
		return require(script.Parent.Parent.Ui.LockBoard)
	end)
	ctx = setmetatable({ LockBoard = if ok then LockBoard else nil }, { __index = c })
	Net.get("Shield", "State").OnClientEvent:Connect(function(p)
		if typeof(p) == "table" and typeof(p.plotId) == "number" then
			states[p.plotId] = p
			paintWorld(p.plotId)
		end
	end)
	-- Q / Y inside the base: Input.on("shield") once M2-07 adds it (then it owns the keys), else read here
	local Input = c.Input
	if type(Input.on) == "function" then
		Input.on("shield", Shield.raise)
	else
		UserInputService.InputBegan:Connect(function(io, processed)
			if processed then
				return
			end
			if io.KeyCode == Enum.KeyCode.Q or io.KeyCode == Enum.KeyCode.ButtonY then
				Shield.raise()
			end
		end)
	end
	-- E / X on the Break prompt (touch taps its plate; Prompts wires that itself)
	Input.onInteract(function()
		if breakShown then
			call(c.views.Prompts, "activate", "breakShield")
		end
	end)
	RunService.Heartbeat:Connect(update)
	task.spawn(function()
		while true do
			task.wait(1)
			pcall(ensureTap)
			for plotId in pairs(states) do
				pcall(paintWorld, plotId) -- a plot that streamed in after its state
			end
		end
	end)
	Players.LocalPlayer.CharacterAdded:Connect(function()
		breakShown = nil
		call(c.views.Prompts, "hideBreak")
	end)
	CollectionService:GetInstanceAddedSignal("HFB_LockPad"):Connect(function()
		for plotId in pairs(states) do
			pcall(paintWorld, plotId)
		end
	end)
end

return Shield
