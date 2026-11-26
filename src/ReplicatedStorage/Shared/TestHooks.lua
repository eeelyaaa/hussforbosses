--!strict
-- TestHooks: values tests set as Workspace attributes, read only in Studio
-- (vault/patterns/test-hooks-gated-to-studio-and-listed.md). Every hook is named in HOOKS below AND in
-- team/test-hooks.md; a name not on the list errors. A live server warns once if any is set in the place.
--
-- Attribute name on Workspace: "HFB_" .. hook name, e.g. Workspace.HFB_SaveOff = true.
-- Tests set hooks from the play-mode script and clear them afterwards.
local RunService = game:GetService("RunService")

local PREFIX = "HFB_"

-- The list. Add a hook here and in team/test-hooks.md in the same change. Planned hooks (build plan,
-- "Test hooks") are listed in team/test-hooks.md and are added here by the task that builds them.
local HOOKS: { [string]: string } = {
	ForceSkin = "string: a skin id under ReplicatedStorage.Skins (the skin check uses 'stub')",
	SaveOff = "boolean: no DataStore reads or writes; profiles start fresh and are not saved",
}

local TestHooks = {}
TestHooks.HOOKS = HOOKS

function TestHooks.get(name: string): any
	assert(HOOKS[name], "TestHooks: unknown hook " .. name .. " (add it to HOOKS and team/test-hooks.md)")
	if not RunService:IsStudio() then
		return nil
	end
	return workspace:GetAttribute(PREFIX .. name)
end

-- Called once by Main.server.lua. On a live server, warns about hooks saved into the place by mistake.
function TestHooks.warnIfSetLive()
	if RunService:IsStudio() then
		return
	end
	local set = {}
	for name in pairs(HOOKS) do
		if workspace:GetAttribute(PREFIX .. name) ~= nil then
			table.insert(set, name)
		end
	end
	if #set > 0 then
		warn("TestHooks: set in the place (ignored on a live server): " .. table.concat(set, ", "))
	end
end

return TestHooks
