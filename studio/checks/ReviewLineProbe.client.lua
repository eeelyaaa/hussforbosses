if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M2-32 client probe: LocalScript put in StarterPlayerScripts by the check run, removed after. Reads every plate's "now playing"
-- text on the client at 5 s and 15 s and sends the lines to ReplicatedStorage.RLProbe (a RemoteEvent the check creates).
local RS = game:GetService("ReplicatedStorage")
local ev = RS:WaitForChild("RLProbe", 10)
local function snap(tag)
	local root = workspace:FindFirstChild("ReviewLine")
	local out = { tag .. " root=" .. tostring(root) }
	if root then
		for _, p in ipairs(root.Plates:GetChildren()) do
			local g = p:FindFirstChild("Now")
			local l = g and g:FindFirstChild("Label", true)
			table.insert(out, p.Name .. " = " .. (l and l.Text or "NO LABEL"))
		end
	end
	ev:FireServer(table.concat(out, "\n"))
end
task.wait(5) snap("t5")
task.wait(10) snap("t15")
