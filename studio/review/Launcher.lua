if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- LocalScript HFB_ReviewLine (StarterPlayerScripts), built by studio/BuildReviewLine.lua. Studio only.
if not game:GetService("RunService"):IsStudio() then return end
local root = workspace:WaitForChild("ReviewLine", 30) -- a Persistent Model (M2-34): it arrives shortly after join, before PersistentLoaded
if not root then return end
root:WaitForChild("Dummies", 30); root:WaitForChild("Plates", 30); root:WaitForChild("Bosses", 30); task.wait(2) -- let the client's own scripts and the rigs settle
local D = require(script.Parent:WaitForChild("HFB_ReviewLineDriver"))
D.start(root)
print("ReviewLine: driver started (" .. #root.Bosses:GetChildren() .. " bosses, " .. #root.Dummies:GetChildren() .. " dummies)")
