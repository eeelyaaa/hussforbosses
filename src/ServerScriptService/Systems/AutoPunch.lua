--!strict
-- Systems/AutoPunch: Auto Punch and Perfect Auto Punch (brief system 2; m2-contract.md C "Bag" and "Punch.Report with
-- auto"; build plan B20, B23).
--
-- B23: the owner's client runs the auto ring, its burst and its sound (one clock for picture and sound) and reports
-- each auto tap as Punch.Report { grade = 'good'|'perfect', auto = true, tapServerTime }. The server applies value and
-- rate exactly as a hand burst (Systems/Punch: one accepted report per ring, the burst's beats on the server's queue),
-- after AutoPunch.refuse says the auto tap may land:
--   * grade only 'good' or 'perfect' ('untimed'/'miss' -> 'grade', Systems/Punch);
--   * the toggle on and the pass owned: 'good' needs Auto Punch on (Auto Punch or Perfect Auto Punch owned);
--     'perfect' needs Perfect Auto Punch owned and its toggle on, else 'pass';
--   * the owner on their own bag pad, never in a fight ('place'/'state', Systems/Punch's context rules);
--   * never offline: it needs the player in the server and on the pad, so nothing earns while away.
-- B20, one burst per ring: Punch's rate and busy rules allow one accepted report per ring, whoever sends it. The
-- client sends the hand tap instead of the auto tap only if it is better and before the auto burst starts; once the
-- auto burst runs a hand tap is refused 'busy'.
-- Toggles: Bag.AutoToggle / Bag.PerfectToggle { on } (contract C): per session, off on join, never saved. Turning one
-- on needs its pass (cached ownership, never a yield in the handler: M2-02 S5); turning off always works.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local Bag = require(script.Parent.Bag)

local AutoPunch = {}

AutoPunch.stats = { accepted = 0, refused = {} :: { [string]: number } }

-- nil when this auto tap may land (the rest of Systems/Punch's checks still apply), else the refusal reason.
function AutoPunch.refuse(player: Player, grade: string, context: string): string?
	if grade ~= "good" and grade ~= "perfect" then
		return "grade"
	end
	if context ~= "bag" then
		return "place"
	end
	local t = Bag.toggles(player)
	local perfectOk = t.perfect and Bag.perfectOwned(player)
	local autoOk = (t.auto and Bag.autoOwned(player)) or perfectOk
	if grade == "perfect" and not perfectOk then
		return "pass"
	end
	if not autoOk then
		return "pass"
	end
	return nil
end

-- What grade the owner's client runs at now ('perfect', 'good'), or nil when no auto is on.
function AutoPunch.grade(player: Player): string?
	local t = Bag.toggles(player)
	if t.perfect and Bag.perfectOwned(player) then
		return Config.AutoPunch.PERFECT_GRADE
	end
	if t.auto and Bag.autoOwned(player) then
		return Config.AutoPunch.GRADE
	end
	return nil
end

local function toggle(player: Player, p: any, which: string)
	local action = which
	if typeof(p.on) ~= "boolean" then
		return -- malformed: dropped (contract C)
	end
	local t = Bag.toggles(player)
	if p.on then
		local owned = if which == "perfect" then Bag.perfectOwned(player) else Bag.autoOwned(player)
		if not owned then
			AutoPunch.stats.refused.pass = (AutoPunch.stats.refused.pass or 0) + 1
			return Bag.result(player, action, false, "pass")
		end
	end
	if which == "perfect" then
		t.perfect = p.on
	else
		t.auto = p.on
	end
	Bag.result(player, action, true, nil)
	Bag.sendState(player)
end

-- Check seams (the handlers after Net's limiter).
function AutoPunch.autoToggle(player: Player, p: any)
	toggle(player, p, "auto")
end
function AutoPunch.perfectToggle(player: Player, p: any)
	toggle(player, p, "perfect")
end

function AutoPunch.start()
	Net.onServerEvent("Bag", "AutoToggle", AutoPunch.autoToggle)
	Net.onServerEvent("Bag", "PerfectToggle", AutoPunch.perfectToggle)
end

return AutoPunch
