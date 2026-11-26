if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M2-16: client probe for Controllers/Steal, Shield, Watchers. Installed as StarterPlayerScripts.HFB_StealClientProbe for the check only,
-- removed after. It runs once, 8 s after the character exists, feeds contract-shaped payloads through the controllers' test seams,
-- and sends each line as Profile.TestReport "sc_line" {ok, l, d} (the server's log shows them), then "sc_done".
-- It never fires a remote that costs anything: the server refuses the HoldStart / OwnerPunch it sends (no such uid).
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local C = script.Parent:WaitForChild("Controllers")
local Steal = require(C:WaitForChild("Steal"))
local Shield = require(C:WaitForChild("Shield"))
local Watchers = require(C:WaitForChild("Watchers"))
local Carry = require(C:WaitForChild("Carry"))
local Input = require(C:WaitForChild("Input"))
local Config = require(RS.Shared.Config)
local Net = require(RS.Shared.Net)
local lp = Players.LocalPlayer
local out = {}
local function chk(ok, label, detail) table.insert(out, { ok = ok == true, l = label, d = tostring(detail or "") }) end
local function send(name, data)
	local ok, json = pcall(HttpService.JSONEncode, HttpService, data)
	if ok then Net.get("Profile", "TestReport"):FireServer({ name = name, json = json:sub(1, 950) }) end
	task.wait(0.15)
end
repeat task.wait(0.5) until lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") and Net.get("Profile", "TestReport")
task.wait(8)
local ok, err = pcall(function()
	local root = lp.Character.HumanoidRootPart
	local hum = lp.Character.Humanoid
	local PromptsUi = require(script.Parent.Ui.Prompts)
	-- a. the prompt: a target on, glyph by input, then greyed when flagged
	Steal._setTarget({ plotId = 99, uid = "probe-uid", bought = nil, spot = root })
	task.wait(0.5)
	local st = Steal.state()
	chk(st.prompt ~= nil and st.target == "probe-uid", "a1 steal prompt up for a target in range", st.prompt)
	local parts = PromptsUi.parts()
	chk(parts and parts.kinds.steal.button.root.Visible and parts.kinds.steal.button.enabled, "a2 plate visible and enabled")
	Steal._setFlag("probe-uid", true)
	task.wait(0.4)
	chk(parts.kinds.steal.button.enabled == false, "a3 greyed when Steal.Flag locked")
	Steal._begin("keyboard")
	chk(Steal.state().holding == false, "a4 a press on the greyed plate starts no hold")
	Steal._setFlag("probe-uid", false)
	task.wait(0.4)
	-- b. a hold: sent, bar up, the server refuses (unknown plot) and the hold clears
	local before = Steal.state().stats.holdSent
	Steal._begin("keyboard")
	local s1 = Steal.state()
	chk(s1.holding and s1.barVisible == true and s1.stats.holdSent == before + 1, "b1 press starts the hold: HoldStart sent, bar visible")
	task.wait(1)
	local s2 = Steal.state()
	chk(s2.holding == false and s2.barVisible == false and s2.stats.lastResult == "refused", "b2 server's refusal ends the hold and hides the bar", tostring(s2.stats.lastResult) .. "/" .. tostring(s2.stats.lastReason))
	-- c. a hold followed by held / carried results
	Steal._noSend(true)
	Steal._begin("pointer")
	Steal._onResult({ state = "held", uid = "probe-uid", holdEndsAt = workspace:GetServerTimeNow() + 2 })
	task.wait(1)
	local s3 = Steal.state()
	chk(s3.holding and s3.barP and s3.barP > 0.3 and s3.barP < 0.8, "c1 bar follows holdEndsAt (about half after 1 s of 2)", s3.barP)
	Steal._onResult({ state = "carried", uid = "probe-uid" })
	Steal._noSend(false)
	chk(Steal.state().holding == false, "c2 'carried' ends the hold")
	-- d. stagger: the server slows; the client must not touch WalkSpeed, only show the look
	hum.WalkSpeed = 16
	Steal._onCarryState({ state = "carrying", slowSpeed = 8 })
	chk(Steal.state().staggered == true and hum.WalkSpeed == 16, "d1 slowSpeed marks the stagger look, client leaves WalkSpeed alone", hum.WalkSpeed)
	Steal._onCarryState({ state = "carrying" })
	chk(Steal.state().staggered == false, "d2 slowSpeed gone clears it")
	-- e. the owner's punch
	Steal._setTarget(nil)
	Steal._setAlert("probe-uid", lp.UserId) -- "the thief" is this character: in reach
	chk(Steal.thiefInRange() == lp.UserId, "e1 a thief within 8 studs is in reach (Huss button 'start' look)")
	local n0 = Steal.state().stats.punchSent
	local took = Steal.tryPunch("code", os.clock())
	local took2 = Steal.tryPunch("code", os.clock())
	chk(took and took2 and Steal.state().stats.punchSent == n0 + 1, "e2 first tap sent OwnerPunch, the tap inside 0.8 s is swallowed", Steal.state().stats.punchSent - n0)
	Steal._setAlert("probe-uid", nil)
	chk(Steal.thiefInRange() == nil and Steal.tryPunch("code", os.clock()) == false, "e3 no thief: the tap goes on to the ring")
	-- f. shield controller
	local r0 = Shield.state().stats.raiseSent
	Shield.raise()
	chk(Shield.state().stats.raiseSent <= r0 + 1, "f1 Shield.raise sends only from inside the own base", Shield.state().stats.raiseSent - r0)
	local hud = require(script.Parent.Ui.Hud)
	local plate = hud.root() and hud.root():FindFirstChild("ShieldPlate", true)
	chk(plate and plate:FindFirstChild("RaiseTap") ~= nil, "f2 the HUD shield plate has the raise tap")
	-- g. watchers
	local w0 = { bursts = Watchers.state().stats.bursts, clips = Watchers.state().stats.clips }
	Watchers.onBurst({ userId = lp.UserId, context = "bag", grade = "good", t0 = workspace:GetServerTimeNow() })
	chk(Watchers.state().stats.bursts == w0.bursts, "g1 own Burst is ignored")
	Watchers.onSteal({ fromUserId = 0, toUserId = lp.UserId, hit = "stagger" })
	chk(Watchers.state().stats.clips == w0.clips + 1, "g2 Steal.Punch plays a clip on the thief's character")
	chk(Watchers.state().voiceCount >= 2, "g3 voices built (two F and the singles)", Watchers.state().voiceCount)
	-- h. respawn
	local rs0 = Watchers.state().stats.respawns
	hum.Health = 0
	task.wait(8)
	chk(Watchers.state().stats.respawns == rs0 + 1, "h1 a respawn is seen by Watchers")
	local cs = Carry.state()
	chk(cs == "none", "h2 carry state is none after the respawn", cs)
	chk(Steal.state().holding == false and Steal.state().staggered == false, "h3 hold and stagger clear after a respawn")
end)
if not ok then chk(false, "probe ran without an error", tostring(err):sub(1, 200)) end
for _, l in ipairs(out) do send("sc_line", { ok = l.ok, l = l.l:sub(1, 120), d = l.d:sub(1, 80) }) end
send("sc_done", { n = #out })
print("SC|done")
