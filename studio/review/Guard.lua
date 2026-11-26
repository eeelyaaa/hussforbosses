if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- Script HFB_ReviewLineGuard (ServerScriptService), built by studio/BuildReviewLine.lua.
-- Live server: removes the review line and its scripts (it must never exist there). Studio: the teleport pads.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local function purge()
	local r = workspace:FindFirstChild("ReviewLine")
	if r then r:Destroy() end
	for _, n in ipairs({ "HFB_ReviewLine", "HFB_ReviewLineDriver" }) do
		local s = game.StarterPlayer.StarterPlayerScripts:FindFirstChild(n)
		if s then s:Destroy() end
	end
	script:Destroy()
end
if not RunService:IsStudio() then purge() return end
local root = workspace:WaitForChild("ReviewLine", 10)
if not root then return end
local last = {}
local function hook(pad, target)
	pad.Touched:Connect(function(hit)
		local char = hit.Parent
		local plr = char and Players:GetPlayerFromCharacter(char)
		if not plr or (last[plr] and os.clock() - last[plr] < 3) then return end
		last[plr] = os.clock()
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then char:PivotTo(target.CFrame + Vector3.new(0, 4, 0)) end
	end)
end
hook(root.GoPad, root.LineSpawn)
hook(root.ReturnPad, root.HomeSpawn)
