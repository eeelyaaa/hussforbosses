--!strict
-- Controllers/Input: the three M1 actions on every input (docs/controls.md; m1-contract.md section I).
--   Input.kind()            -> "keyboard" | "gamepad" | "touch" (the ForceInput hook overrides)
--   Input.onPunch(fn)       Huss: left mouse or F, right trigger, the Huss button (Ui calls Input.fire)
--   Input.onInteract(fn)    E, X, the prompt button
--   Input.onRun(fn)         Backspace, B, the Run button
--   Input.onKindChanged(fn) the input in use changed (prompts swap their glyph)
--   Input.onPressed(fn)     fn(down: boolean) for the Huss button's pressed look on keyboard and gamepad
--   Input.fire(action, src) the one entry every binding goes through (Ui buttons and TestClient's AutoTap use it)
--   Input.BINDINGS          the table above as data; Input.route(keyCode, inputType) -> action? for the check
-- Every handler gets (source: string, t: number) where t = os.clock() at the input, taken before anything else.
-- Only the M1 rows are bound here; the rest come with their systems.
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TestHooks = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TestHooks"))

export type Action = "punch" | "interact" | "run"
export type Kind = "keyboard" | "gamepad" | "touch"

local Input = {}

-- docs/controls.md rows Punch, Interact, Run. keyboard = KeyCodes or UserInputTypes; touch = the on-screen
-- control that calls Input.fire (built by Ui, M1-08).
Input.BINDINGS = {
	punch = {
		keyboard = { Enum.UserInputType.MouseButton1, Enum.KeyCode.F },
		gamepad = { Enum.KeyCode.ButtonR2 },
		touch = { "HussButton" },
	},
	interact = {
		keyboard = { Enum.KeyCode.E },
		gamepad = { Enum.KeyCode.ButtonX },
		touch = { "PromptButton" },
	},
	run = {
		keyboard = { Enum.KeyCode.Backspace },
		gamepad = { Enum.KeyCode.ButtonB },
		touch = { "RunButton" },
	},
}

local listeners: { [string]: { (string, number) -> () } } = { punch = {}, interact = {}, run = {}, kind = {}, pressed = {} }

local function add(list: { any }, fn: any): () -> ()
	table.insert(list, fn)
	return function()
		local i = table.find(list, fn)
		if i then
			table.remove(list, i)
		end
	end
end

function Input.onPunch(fn: (string, number) -> ()): () -> ()
	return add(listeners.punch, fn)
end
function Input.onInteract(fn: (string, number) -> ()): () -> ()
	return add(listeners.interact, fn)
end
function Input.onRun(fn: (string, number) -> ()): () -> ()
	return add(listeners.run, fn)
end
function Input.onKindChanged(fn: (string) -> ()): () -> ()
	return add(listeners.kind, fn :: any)
end
function Input.onPressed(fn: (boolean) -> ()): () -> ()
	return add(listeners.pressed, fn :: any)
end

-- Counts per action and source, for the scripted controls check.
Input.counts = {} :: { [string]: number }

function Input.fire(action: Action, source: string?, t: number?)
	local now = t or os.clock()
	local src = source or "code"
	local key = action .. ":" .. src
	Input.counts[key] = (Input.counts[key] or 0) + 1
	for _, fn in ipairs(table.clone(listeners[action])) do
		task.spawn(fn, src, now)
	end
end

-- The input in use. Last real input wins; the ForceInput hook (Studio only) overrides.
local current: Kind = if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then "touch" else "keyboard"

local function kindOf(inputType: Enum.UserInputType): Kind?
	if inputType == Enum.UserInputType.Touch then
		return "touch"
	elseif inputType.Name:match("^Gamepad") then
		return "gamepad"
	elseif inputType == Enum.UserInputType.Keyboard or inputType.Name:match("^Mouse") then
		return "keyboard"
	end
	return nil
end

function Input.kind(): Kind
	local forced = TestHooks.get("ForceInput")
	if forced == "touch" or forced == "gamepad" or forced == "keyboard" then
		return forced
	end
	return current
end

local lastReported: Kind = Input.kind()
local function notifyKind()
	local k = Input.kind()
	if k ~= lastReported then
		lastReported = k
		for _, fn in ipairs(table.clone(listeners.kind)) do
			task.spawn(fn :: any, k)
		end
	end
end

-- Which action a key or mouse button maps to (nil = none). Shared by the live handler and the check.
function Input.route(keyCode: Enum.KeyCode, inputType: Enum.UserInputType): Action?
	for action, rows in pairs(Input.BINDINGS) do
		for _, list in ipairs({ rows.keyboard, rows.gamepad }) do
			for _, b in ipairs(list) do
				if b == keyCode or b == inputType then
					return action :: Action
				end
			end
		end
	end
	return nil
end

local started = false
function Input.start()
	if started then
		return
	end
	started = true
	UserInputService.LastInputTypeChanged:Connect(function(inputType)
		local k = kindOf(inputType)
		if k then
			current = k
			notifyKind()
		end
	end)
	if TestHooks.get("ForceInput") ~= nil or game:GetService("RunService"):IsStudio() then
		workspace:GetAttributeChangedSignal(TestHooks.PREFIX .. "ForceInput"):Connect(notifyKind)
	end
	UserInputService.InputBegan:Connect(function(io: InputObject, processed: boolean)
		local t = os.clock()
		-- A tap on a GuiButton (the Huss button itself, menus) arrives processed; the button fires on its own.
		if processed then
			return
		end
		local action = Input.route(io.KeyCode, io.UserInputType)
		if action then
			if action == "punch" then
				for _, fn in ipairs(table.clone(listeners.pressed)) do
					task.spawn(fn :: any, true)
				end
			end
			local src = kindOf(io.UserInputType) or "keyboard"
			Input.fire(action, src, t)
		end
	end)
	UserInputService.InputEnded:Connect(function(io: InputObject)
		if Input.route(io.KeyCode, io.UserInputType) == "punch" then
			for _, fn in ipairs(table.clone(listeners.pressed)) do
				task.spawn(fn :: any, false)
			end
		end
	end)
end

return Input
