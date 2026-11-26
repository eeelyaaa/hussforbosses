if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M2-14: the static half of gate row S20 (the bought mark). EDIT MODE, after a sync:
--   require(game.ServerStorage.DevSync:Clone()).run("checks/BoughtScan.lua")
-- 1. No client-to-server remote in Shared/Net names bought or boughtCash in its payload.
-- 2. No script outside ServerScriptService.Data and Systems/BoughtMark claims "BoughtMark", builds a bought mark
--    (`bought = { source ...`, `.bought = {`), or (on the server) assigns `.boughtCash =`.
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local pass, fail = 0, 0
local function check(label, ok, detail)
	if ok then pass += 1 else fail += 1 end
	print(("%s BoughtScan %s%s"):format(ok and "PASS" or "FAIL", label, detail and detail ~= "" and (" | " .. detail) or ""))
end

local lines = {}
for line in RS.Shared.Net.Source:gmatch("[^\n]+") do
	if line:find("c2s%(") and line:lower():find("bought") then table.insert(lines, line) end
end
check("no client-to-server remote in Net carries bought or boughtCash", #lines == 0, table.concat(lines, " || "))

local offenders, scanned = {}, 0
local roots = { SSS, RS, game:GetService("StarterPlayer"), game:GetService("ReplicatedFirst"), game:GetService("StarterGui") }
for _, root in ipairs(roots) do
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("LuaSourceContainer") then
			scanned += 1
			local full = d:GetFullName()
			local allowed = full:find("ServerScriptService.Data.", 1, true) == 1 or full == "ServerScriptService.Systems.BoughtMark"
			if not allowed then
				local src = d.Source
				if src:find('claim%("BoughtMark"%)') or src:find("%.bought%s*=%s*{") or src:find("bought%s*=%s*{%s*source")
					or (root == SSS and src:find("%.boughtCash%s*=[^=]")) then
					table.insert(offenders, full)
				end
			end
		end
	end
end
check(("no script outside Data/ and Systems/BoughtMark claims BoughtMark, builds a mark or assigns boughtCash on the server (%d scripts)"):format(scanned), #offenders == 0, table.concat(offenders, ", "))
print(("BoughtScan TOTAL pass=%d fail=%d"):format(pass, fail))
