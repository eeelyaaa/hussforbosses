--!nonstrict
-- Controllers/Steal (M2-16; brief system 10; m2-contract.md C "Steal"): the client of stealing. It shows and asks; the
-- server times the hold, decides every result and sets the chase speed and the stun (Systems/Steal).
--   * The thief: near another player's placed boss (within Config.Steal.HOLD_RANGE of the spot, shield not up, not carrying,
--     no fight) the "HOLD TO STEAL" prompt (Ui/Prompts.showSteal) is up; greyed "CAN'T BE STOLEN" while Steal.Flag says locked.
--     HOLD E (keyboard), X (gamepad) or the prompt plate (touch / mouse) sends Steal.HoldStart { plotId, uid }; letting go or
--     moving away sends Steal.HoldCancel. A bar fills over the hold (the server's holdEndsAt once Steal.Result 'held' lands) and
--     the stealLift clip runs stretched to the hold. 'cancelled' / 'refused' / 'carried' end it (refusals toast in StealAlert).
--   * Iron Grip: the server slows the thief (Carry.setSlow); Carry.State.slowSpeed only drives the flinch look here.
--   * The owner: Steal.Alert says who carries the boss; Huss within PUNCH_RANGE of that thief sends Steal.OwnerPunch
--     { thiefUserId } (0.8 s apart), plays the single huss and one jab at once, and swallows the tap (Main routes it here
--     first). Main shows the Huss button in its "start" look while a thief is in reach (HussButton has no thief mode yet).
--   * Clips on every character within 150 studs come from Steal.Punch (Controllers/Watchers).
-- API: Steal.start(ctx) (AUTO_START), Steal.thiefInRange() -> userId?, Steal.tryPunch(source, t) -> boolean,
--      Steal.state() -> table (for the check and the client probe).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Skin = require(Shared:WaitForChild("Skin"))

local C = Skin.Tokens.colors
local CFG = Config.Steal
local Steal = { AUTO_START = true }

local ctx = nil
local flags = {} -- uid -> locked (Steal.Flag, per viewer)
local alerts = {} -- uid -> thiefUserId (owner side: Steal.Alert until dropped / returned / success)
local shieldStates = {} -- plotId -> Shield.State payload
local quickOwned = false
local hold = nil -- { uid, plotId, t0, dur, endsAt, source, input }
local shown = nil -- the key of the steal prompt on screen
local lastHoldSent = 0
local lastPunchAt = 0
local stagger = nil -- { hum, slowed, normal, untilT }
local faceConn = nil
local face = nil
local bar = nil
local lastTarget = nil -- { plotId, uid, bought }
local stats = { holdSent = 0, cancelSent = 0, punchSent = 0, lastResult = nil, lastReason = nil, staggers = 0 }

local function call(target, method, ...)
	if target and type(target[method]) == "function" then
		local ok, err = pcall(target[method], ...)
		if not ok then
			warn(("[HFB] Steal: %s failed: %s"):format(method, tostring(err)))
		end
	end
end

local function root(): BasePart?
	local c = Players.LocalPlayer.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function humanoid(): Humanoid?
	local c = Players.LocalPlayer.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function now(): number
	local ok, Clock = pcall(function()
		return require(script.Parent.Clock)
	end)
	return if ok then Clock.now() else workspace:GetServerTimeNow()
end

local function flat(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function plotFolder()
	return workspace:FindFirstChild("Plots") -- stream-ok: read on every use, nil-tolerant (no plots streamed = no target)
end

local function shieldUp(plotId: number): boolean
	local st = shieldStates[plotId]
	return st ~= nil and (st.state == "up" or st.state == "joining" or st.state == "instant")
end

-- ------------------------------------------------------------------ the thief: which spot, which prompt
local function carrying(): boolean
	local carry = ctx and ctx.Carry
	local s = carry and carry.state and carry.state()
	return s == "carrying"
end

local testTarget = nil -- Studio client probe only (Steal._setTarget)
local testNoSend = false -- Studio client probe only: HoldStart is not sent
local function nearestSpot()
	if testTarget and game:GetService("RunService"):IsStudio() then
		return testTarget
	end
	local r = root()
	if not r or carrying() then
		return nil
	end
	if ctx.Fight and ctx.Fight.active and ctx.Fight.active() then
		return nil
	end
	local folder = plotFolder()
	local base = ctx.Base
	if not (folder and base and base.plot) then
		return nil
	end
	local me = Players.LocalPlayer.UserId
	local best, bestD = nil, math.huge
	for _, plotM in ipairs(folder:GetChildren()) do
		local plotId = tonumber(string.match(plotM.Name, "^Plot(%d+)$"))
		local plot = plotId and base.plot(plotId)
		if plot and plot.owner and plot.owner ~= me and not shieldUp(plotId) then
			for i = 1, Config.Base.MAX_SPOTS do
				local data = plot.spots[i]
				if data and not data.carried and plot.unlocked[i] and typeof(data.uid) == "string" then
					local spot = plotM:FindFirstChild("Spot_" .. i)
					if spot and spot:IsA("BasePart") then
						local d = flat(r.Position, spot.Position)
						if d <= CFG.HOLD_RANGE and math.abs(r.Position.Y - spot.Position.Y) <= CFG.HOLD_HEIGHT and d < bestD then
							best, bestD = { plotId = plotId, uid = data.uid, bought = data.bought, spot = spot }, d
						end
					end
				end
			end
		end
	end
	return best
end

local function holdSeconds(): number
	return if quickOwned then CFG.QUICK_HOLD_S else CFG.HOLD_S
end

-- ------------------------------------------------------------------ the bar (over the prompt plate)
local function ensureBar()
	local parts = ctx.views.Prompts.parts and ctx.views.Prompts.parts()
	local k = parts and parts.kinds and parts.kinds.steal
	local f = k and k.button and k.button.face
	if not f then
		return nil
	end
	if bar and bar.frame.Parent == f then
		return bar
	end
	if bar then
		bar.frame:Destroy()
	end
	local back = Instance.new("Frame")
	back.Name = "HoldBar"
	back.AnchorPoint = Vector2.new(0, 1)
	back.Position = UDim2.new(0, 6, 1, -4)
	back.Size = UDim2.new(1, -12, 0, 7)
	back.BackgroundColor3 = C.ink
	back.BorderSizePixel = 0
	back.ZIndex = 8
	back.Visible = false
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 4)
	bc.Parent = back
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = C.arrowYellow
	fill.BorderSizePixel = 0
	fill.ZIndex = 9
	local fc = Instance.new("UICorner")
	fc.CornerRadius = UDim.new(0, 4)
	fc.Parent = fill
	fill.Parent = back
	back.Parent = f
	bar = { frame = back, fill = fill }
	return bar
end

local function setBar(p: number?)
	local b = ensureBar()
	if not b then
		return
	end
	if p == nil then
		b.frame.Visible = false
		b.fill.Size = UDim2.fromScale(0, 1)
	else
		b.frame.Visible = true
		b.fill.Size = UDim2.fromScale(math.clamp(p, 0, 1), 1)
	end
end

-- ------------------------------------------------------------------ the hold
local function clearHold(stopClip: boolean?)
	if hold then
		hold = nil
		setBar(nil)
		if stopClip ~= false then
			call(ctx.Avatar, "stopClip", "stealLift")
		end
	end
end

local function sendCancel()
	stats.cancelSent += 1
	Net.get("Steal", "HoldCancel"):FireServer({})
end

local function endHold(sendIt: boolean)
	if not hold then
		return
	end
	clearHold(true)
	if sendIt then
		sendCancel()
	end
end

local function beginHold(source: string, input: InputObject?)
	if hold or not lastTarget then
		return
	end
	local flagged = flags[lastTarget.uid] == true
	if flagged then
		return -- the greyed prompt: no press does anything
	end
	if os.clock() - lastHoldSent < 0.55 then
		return -- HoldStart is 2 a second on the server
	end
	lastHoldSent = os.clock()
	local dur = holdSeconds()
	hold = { uid = lastTarget.uid, plotId = lastTarget.plotId, spot = lastTarget.spot, t0 = os.clock(), dur = dur, endsAt = nil, source = source, input = input }
	stats.holdSent += 1
	if not (testNoSend and game:GetService("RunService"):IsStudio()) then
		Net.get("Steal", "HoldStart"):FireServer({ plotId = lastTarget.plotId, uid = lastTarget.uid })
	end
	call(ctx.Avatar, "playClip", "stealLift", { hold = dur })
	setBar(0)
end

-- ------------------------------------------------------------------ the owner's punch
local function thiefRoot(userId: number): BasePart?
	local plr = Players:GetPlayerByUserId(userId)
	local c = plr and plr.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

function Steal.thiefInRange(): number?
	local r = root()
	if not r or next(alerts) == nil then
		return nil
	end
	for _, thiefId in pairs(alerts) do
		local tr = thiefRoot(thiefId)
		if tr and flat(r.Position, tr.Position) <= CFG.PUNCH_RANGE and math.abs(r.Position.Y - tr.Position.Y) <= CFG.PUNCH_HEIGHT then
			return thiefId
		end
	end
	return nil
end

-- One punch at a thief: the single huss and one jab at once (the same cut as Main's untimed punch), then the report.
function Steal.tryPunch(source: string, t: number): boolean
	local thiefId = Steal.thiefInRange()
	if not thiefId then
		return false
	end
	if os.clock() - lastPunchAt < CFG.PUNCH_GAP_S then
		return true -- inside the 0.8 s gap: the tap is swallowed (the server would refuse it)
	end
	lastPunchAt = os.clock()
	stats.punchSent += 1
	Net.get("Steal", "OwnerPunch"):FireServer({ thiefUserId = thiefId })
	local audio, avatar = ctx.Audio, ctx.Avatar
	if audio and type(audio.singleHuss) == "function" then
		pcall(audio.singleHuss)
	end
	if avatar and type(avatar.startJab) == "function" then
		local ok = pcall(avatar.startJab, "good", t)
		if ok then
			local gap = Config.Punch.BEAT[2] - 0.015
			task.delay(gap, function()
				if ctx.BurstClock and not ctx.BurstClock.running() then
					pcall(avatar.cancel)
				end
			end)
		end
	end
	return true
end

-- ------------------------------------------------------------------ Iron Grip stagger
-- The server slows the thief itself (Carry.setSlow); Carry.State.slowSpeed (sent while a slow runs) is used only for the look.
local function onCarryState(p)
	if typeof(p) ~= "table" then
		return
	end
	local slowed = typeof(p.slowSpeed) == "number"
	if slowed and not stagger then
		stats.staggers += 1
		call(ctx.Avatar, "playClip", "flinch")
	end
	stagger = if slowed then { slowSpeed = p.slowSpeed } else nil
end
Steal._onCarryState = onCarryState

-- ------------------------------------------------------------------ remotes
local function onResult(p)
	if typeof(p) ~= "table" or typeof(p.state) ~= "string" then
		return
	end
	stats.lastResult, stats.lastReason = p.state, p.reason
	local uid = p.uid
	if p.state == "held" then
		if hold and hold.uid == uid and typeof(p.holdEndsAt) == "number" then
			hold.endsAt = p.holdEndsAt
			hold.dur = math.max(0.05, p.holdEndsAt - now())
			hold.t0 = os.clock()
		end
	elseif p.state == "cancelled" or p.state == "refused" or p.state == "carried" then
		if hold and (hold.uid == uid or p.state == "refused") then
			clearHold(p.state ~= "carried")
		end
		if p.state == "carried" then
			call(ctx.Avatar, "stopClip", "stealLift")
		end
	elseif p.state == "dropped" or p.state == "returned" or p.state == "success" then
		alerts[uid] = nil
		if hold and hold.uid == uid then
			clearHold(true)
		end
	end
end

function Steal.state()
	local info = ctx and ctx.Carry and ctx.Carry.info and ctx.Carry.info()
	return {
		holding = hold ~= nil,
		holdUid = hold and hold.uid,
		barP = bar and bar.fill.Size.X.Scale,
		barVisible = bar and bar.frame.Visible,
		prompt = shown,
		target = lastTarget and lastTarget.uid,
		flags = flags,
		alerts = alerts,
		staggered = stagger ~= nil,
		walk = humanoid() and humanoid().WalkSpeed,
		carrying = info and info.state,
		stats = stats,
	}
end

-- Test seam (Studio client probe): feed contract-shaped payloads without a remote.
Steal._onResult = onResult
function Steal._setFlag(uid: string, locked: boolean)
	flags[uid] = locked
end
function Steal._setAlert(uid: string, thiefUserId: number?)
	alerts[uid] = thiefUserId
end
function Steal._setTarget(t)
	testTarget = t
end
function Steal._noSend(on: boolean)
	testNoSend = on
end
function Steal._begin(source: string)
	beginHold(source, nil)
end
function Steal._setShield(plotId: number, st)
	shieldStates[plotId] = st
end

-- ------------------------------------------------------------------ per frame
local function bindFace()
	local parts = ctx.views.Prompts.parts and ctx.views.Prompts.parts()
	local k = parts and parts.kinds and parts.kinds.steal
	local f = k and k.button and k.button.face
	if f == face then
		return
	end
	if faceConn then
		for _, c in ipairs(faceConn) do
			c:Disconnect()
		end
		faceConn = nil
	end
	face = f
	if f then
		faceConn = {
			f.InputBegan:Connect(function(io: InputObject)
				if io.UserInputType == Enum.UserInputType.Touch or io.UserInputType == Enum.UserInputType.MouseButton1 then
					if shown then
						beginHold("pointer", io)
					end
				end
			end),
		}
	end
end

local function update()
	if not ctx then
		return
	end
	local Prompts = ctx.views.Prompts
	bindFace()
	-- The thief mode flag Main reads is thiefInRange(); nothing to do for the owner here.
	local target = nearestSpot()
	lastTarget = target
	if hold then
		-- moving away ends the hold at once (the server cancels 'moved' too; do not wait for it)
		local r = root()
		if not (r and hold.spot and hold.spot.Parent and flat(r.Position, hold.spot.Position) <= CFG.HOLD_RANGE + CFG.HOLD_CANCEL_SLACK) then
			endHold(true)
		else
			local p = if hold.endsAt then 1 - math.max(0, hold.endsAt - now()) / hold.dur else (os.clock() - hold.t0) / hold.dur
			setBar(math.clamp(p, 0, 1))
		end
	end
	-- the prompt
	if target then
		local locked = flags[target.uid] == true
		local kind = ctx.Input.kind()
		local key = table.concat({ target.uid, tostring(locked), kind, tostring(quickOwned) }, "|")
		if key ~= shown then
			shown = key
			call(Prompts, "showSteal", { locked = locked, holdS = CFG.HOLD_S, quickS = CFG.QUICK_HOLD_S, quickHandsOwned = quickOwned, glyphKind = kind })
		end
	elseif shown then
		shown = nil
		call(Prompts, "hideSteal")
		if hold then
			endHold(true)
		end
	end
end

local function onKey(io: InputObject, processed: boolean)
	if processed then
		return
	end
	if io.KeyCode == Enum.KeyCode.E then
		if shown then
			beginHold("keyboard", io)
		end
	elseif io.KeyCode == Enum.KeyCode.ButtonX then
		if shown then
			beginHold("gamepad", io)
		end
	end
end

local function onEnd(io: InputObject)
	if not hold then
		return
	end
	local src = hold.source
	if (src == "keyboard" and io.KeyCode == Enum.KeyCode.E)
		or (src == "gamepad" and io.KeyCode == Enum.KeyCode.ButtonX)
		or (src == "pointer" and (io.UserInputType == Enum.UserInputType.Touch or io.UserInputType == Enum.UserInputType.MouseButton1)) then
		endHold(true)
	end
end

function Steal.start(c)
	if ctx then
		return
	end
	ctx = c
	Net.get("Steal", "Flag").OnClientEvent:Connect(function(p)
		if typeof(p) == "table" and typeof(p.uid) == "string" and typeof(p.locked) == "boolean" then
			flags[p.uid] = p.locked
		end
	end)
	Net.get("Steal", "Alert").OnClientEvent:Connect(function(p)
		if typeof(p) == "table" and typeof(p.uid) == "string" and typeof(p.thiefUserId) == "number" then
			alerts[p.uid] = p.thiefUserId
		end
	end)
	Net.get("Steal", "Result").OnClientEvent:Connect(onResult)
	Net.get("Carry", "State").OnClientEvent:Connect(onCarryState)
	Net.get("Shield", "State").OnClientEvent:Connect(function(p)
		if typeof(p) == "table" and typeof(p.plotId) == "number" then
			shieldStates[p.plotId] = p
		end
	end)
	Net.get("Shop", "State").OnClientEvent:Connect(function(p)
		if typeof(p) == "table" and typeof(p.passes) == "table" then
			quickOwned = p.passes.pass_quick_hands == true
		end
	end)
	UserInputService.InputBegan:Connect(onKey)
	UserInputService.InputEnded:Connect(onEnd)
	RunService.Heartbeat:Connect(update)
	-- a respawn ends everything of ours (the server cancels the hold and ends the carry on its side)
	Players.LocalPlayer.CharacterAdded:Connect(function()
		clearHold(false)
		alerts = {}
		shown = nil
		lastTarget = nil
	end)
end

return Steal
