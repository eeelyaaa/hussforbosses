if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M2-15: gate row S16's policy part (contract H, M2-02 S10, TEAM CALL 38). PLAY MODE, installed into
-- ServerStorage.TmpChecks next to CheckLib.
--   { phase = "a" }  the real player's answer arrived from Roblox and is cached (no call in a handler); fromInfo: a
--                    missing field is restrictive; a stand-in's answer is the restrictive default; the PolicyTrading and
--                    PolicyRandom hooks: on / off / fail, per-player entries win; onReady fires once per player;
--                    onChange fires on a hook change.
local ARGS = ...
if type(ARGS) ~= "table" then ARGS = {} end
local L = {}
require(game.ServerStorage.TmpChecks.CheckLib)(L)
local SSS = game:GetService("ServerScriptService")
local Policy = require(SSS.Systems.Policy)
local Plots = require(SSS.Systems.Plots)
local seam = Plots.seam

local ctx = L.begin("Policy", ARGS)
local p = ctx.p
local function C(label, ok, detail) return L.check(ctx, label, ok, detail) end
local function t(a) return ("trading=%s restricted=%s"):format(tostring(a.tradingAllowed), tostring(a.randomItemsRestricted)) end

local stand, clone
-- every pass forced off (the Studio account really owns them all)
local parts = {}
local Ids = require(game:GetService("ReplicatedStorage").Shared.Ids)
for _, k in ipairs(Ids.SHOP_KEYS) do if Ids.isPass(k) then table.insert(parts, k .. "=off") end end
L.hook(ctx, "PassOwned", table.concat(parts, ","))
local ok, err = pcall(function()
	L.waitFor(function() return Policy.isAnswered(p) end, 12)
	local real = Policy.get(p)
	local src
	for i = #Policy.stats.log, 1, -1 do if Policy.stats.log[i].userId == p.UserId then src = Policy.stats.log[i].source; break end end
	C("1 the real player's answer came from Roblox on join and is cached", Policy.isAnswered(p) and src == "roblox", src .. " " .. t(real))
	local calls = Policy.stats.calls
	for _ = 1, 20 do Policy.get(p) end
	C("2 get never calls Roblox again", Policy.stats.calls == calls)
	local f1 = Policy.fromInfo({})
	local f2 = Policy.fromInfo({ IsPaidItemTradingAllowed = true, ArePaidRandomItemsRestricted = false })
	local f3 = Policy.fromInfo(nil)
	local f4 = Policy.fromInfo({ IsPaidItemTradingAllowed = "yes", ArePaidRandomItemsRestricted = 0 })
	C("3 fromInfo: missing fields are restrictive (S10)", f1.tradingAllowed == false and f1.randomItemsRestricted == true, t(f1))
	C("4 fromInfo: both explicit = allowed / not restricted", f2.tradingAllowed == true and f2.randomItemsRestricted == false)
	C("5 fromInfo: no table or odd values are restrictive", f3.tradingAllowed == false and f3.randomItemsRestricted == true and f4.tradingAllowed == false and f4.randomItemsRestricted == true)
	local readyN = 0
	local m = workspace.Plots.Plot1:Clone()
	m.Name = "CheckPlot8"; m:SetAttribute("PlotId", 8); m:SetAttribute("OwnerUserId", 0)
	m:PivotTo(workspace.Plots.Plot1:GetPivot() + Vector3.new(0, 0, -120))
	m.Parent = workspace.Plots
	clone = m
	stand = seam.addPlayer(-81, { shield = "ready" })
	Policy.fetch(stand)
	Policy.onReady(stand, function() readyN += 1 end)
	task.wait(0.1)
	local sa = Policy.get(stand)
	C("6 a stand-in gets the restrictive default, no Roblox call", sa.tradingAllowed == false and sa.randomItemsRestricted == true and Policy.stats.calls == calls)
	C("7 onReady fires once for an answered player", readyN == 1)
	local changes = 0
	Policy.onChange(function() changes += 1 end)
	L.hook(ctx, "PolicyTrading", "on")
	task.wait(0.15)
	C("8 PolicyTrading on: allowed for everyone", Policy.get(p).tradingAllowed == true and Policy.get(stand).tradingAllowed == true)
	C("9 a hook change fires onChange", changes >= 1, changes)
	L.hook(ctx, "PolicyTrading", "off")
	task.wait(0.05)
	C("10 PolicyTrading off: not allowed", Policy.get(p).tradingAllowed == false)
	L.hook(ctx, "PolicyTrading", "fail")
	task.wait(0.05)
	C("11 PolicyTrading fail: not allowed", Policy.get(p).tradingAllowed == false)
	L.hook(ctx, "PolicyTrading", "on,-81:off")
	task.wait(0.05)
	C("12 a per-player entry wins over the global one", Policy.get(p).tradingAllowed == true and Policy.get(stand).tradingAllowed == false)
	L.hook(ctx, "PolicyTrading", p.UserId .. ":fail")
	task.wait(0.05)
	C("13 a per-player entry only: others keep their answer", Policy.get(p).tradingAllowed == false and Policy.get(stand).tradingAllowed == false)
	L.hook(ctx, "PolicyTrading", nil)
	L.hook(ctx, "PolicyRandom", "off")
	task.wait(0.05)
	C("14 PolicyRandom off: not restricted", Policy.get(p).randomItemsRestricted == false)
	L.hook(ctx, "PolicyRandom", "fail")
	task.wait(0.05)
	C("15 PolicyRandom fail: restricted", Policy.get(p).randomItemsRestricted == true)
	L.hook(ctx, "PolicyRandom", nil)
	task.wait(0.05)
	local back = Policy.get(p)
	C("16 hooks cleared: the real answer again", back.tradingAllowed == real.tradingAllowed and back.randomItemsRestricted == real.randomItemsRestricted, t(back))
end)
if not ok then C("the check ran to the end", false, tostring(err)) end
if stand then pcall(seam.removePlayer, stand) end
if clone then clone:Destroy() end
L.finish(ctx)
