-- Huss for Bosses loader: pulls src/ from tools/devsync.py and writes it into the place.
-- Adapted from deja-kill's DevSync (TEAM CALL B1). Edit mode only (Studio MCP run_code or the command bar):
--   require(game.ServerStorage.DevSync:Clone())()                       sync src/
--   require(game.ServerStorage.DevSync:Clone()).run("CheckPlace.lua")   run a studio/ script
--
-- The place guard: nothing runs unless workspace:GetAttribute("HussForBosses") == true.
-- The one exception is studio/SetPlaceMarker.lua, which checks the place's owner and id itself.
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local PROJECT = "huss-for-bosses"
local BASE = "http://127.0.0.1:34874"
local MARKER = "HussForBosses"
local UNGUARDED = { ["SetPlaceMarker.lua"] = true }

local StarterPlayer = game:GetService("StarterPlayer")
local ROOTS = {
	ReplicatedFirst = game:GetService("ReplicatedFirst"),
	ReplicatedStorage = game:GetService("ReplicatedStorage"),
	ServerScriptService = game:GetService("ServerScriptService"),
	ServerStorage = game:GetService("ServerStorage"),
	StarterPlayer = StarterPlayer, -- src/StarterPlayer/StarterPlayerScripts/... and StarterCharacterScripts/...
	StarterGui = game:GetService("StarterGui"),
}

local function guard(what)
	if workspace:GetAttribute(MARKER) ~= true then
		error(("DevSync: place guard refused %s: Workspace has no %s = true. This is not the Huss for Bosses place."):format(what, MARKER), 0)
	end
	if RunService:IsRunning() then
		error("DevSync: refused " .. what .. " during a play test; stop play mode first", 0)
	end
end

local function classify(file)
	if file:match("%.server%.lua$") then
		return (file:gsub("%.server%.lua$", "")), "Script"
	elseif file:match("%.client%.lua$") then
		return (file:gsub("%.client%.lua$", "")), "LocalScript"
	end
	return (file:gsub("%.lua$", "")), "ModuleScript"
end

local function fetchFiles()
	local body = HttpService:JSONDecode(HttpService:GetAsync(BASE .. "/files", true))
	if body.project ~= PROJECT then
		error(("DevSync: the server on %s is %q, not %s; start this game's tools/devsync.py"):format(BASE, tostring(body.project), PROJECT), 0)
	end
	return body.files
end

local DevSync = {}

function DevSync.sync()
	guard("the sync")
	local files = fetchFiles()

	-- Split into directory entries (with an optional init script) and plain files.
	local dirs = {} -- "Root/A/B" -> { class = "Folder" | script class, source = string? }
	local plain = {} -- { dir = "Root/A", name = ..., class = ..., source = ... }
	for path, source in pairs(files) do
		local parts = string.split(path, "/")
		if not ROOTS[parts[1]] then
			warn("DevSync: no root for " .. path)
			continue
		end
		for i = 2, #parts - 1 do
			local d = table.concat(parts, "/", 1, i)
			dirs[d] = dirs[d] or { class = "Folder" }
		end
		local name, class = classify(parts[#parts])
		local dir = table.concat(parts, "/", 1, #parts - 1)
		if name == "init" and #parts > 2 then
			dirs[dir] = { class = class, source = source }
		elseif name == "init" then
			warn("DevSync: init file directly under a root is not supported: " .. path)
		else
			table.insert(plain, { dir = dir, name = name, class = class, source = source })
		end
	end

	local seen, made = {}, {}
	local changed, total = 0, 0

	local function ensure(parent, name, class, isDir)
		local inst = parent:FindFirstChild(name)
		-- A directory without an init file reuses whatever is there (StarterPlayerScripts, an existing Folder).
		if inst and inst.ClassName ~= class and not (isDir and class == "Folder") then
			inst:Destroy()
			inst = nil
		end
		if not inst then
			inst = Instance.new(class)
			inst.Name = name
			inst.Parent = parent
		end
		if inst:IsA("Folder") or inst:IsA("LuaSourceContainer") then
			inst:SetAttribute("DevSync", true)
			seen[inst] = true
		end
		return inst
	end

	local function setSource(inst, source)
		if inst.Source ~= source then
			inst.Source = source
			changed += 1
		end
		total += 1
	end

	-- Directories first, shallowest first, so a folder that becomes a ModuleScript is settled before its children.
	local order = {}
	for d in pairs(dirs) do
		table.insert(order, d)
	end
	table.sort(order, function(a, b)
		local da, db = #string.split(a, "/"), #string.split(b, "/")
		if da ~= db then
			return da < db
		end
		return a < b
	end)
	for _, d in ipairs(order) do
		local parts = string.split(d, "/")
		local parent = if #parts == 2 then ROOTS[parts[1]] else made[table.concat(parts, "/", 1, #parts - 1)]
		local entry = dirs[d]
		local inst = ensure(parent, parts[#parts], entry.class, true)
		if entry.source then
			setSource(inst, entry.source)
		end
		made[d] = inst
	end

	for _, f in ipairs(plain) do
		local parent = made[f.dir] or ROOTS[f.dir]
		setSource(ensure(parent, f.name, f.class, false), f.source)
	end

	-- Edit-mode require caches per ModuleScript instance, and setting Source does not clear it, so a changed
	-- module would still return its old value (and so would every module that required it). When anything
	-- changed, swap every synced ModuleScript for a new instance of the same name, attributes, tags and
	-- children: one swap per module, never a clone of a tree, so no duplicates. Order does not matter: a swap reads
	-- the old module's current parent and children. The loader refuses in play mode, so this is edit mode only.
	local swapped = 0
	if changed > 0 then
		local mods = {}
		for inst in pairs(seen) do
			if inst:IsA("ModuleScript") then
				table.insert(mods, inst)
			end
		end
		for _, old in ipairs(mods) do
			local new = Instance.new("ModuleScript")
			new.Name = old.Name
			new.Source = old.Source
			for k, v in pairs(old:GetAttributes()) do
				new:SetAttribute(k, v)
			end
			for _, tag in ipairs(old:GetTags()) do
				new:AddTag(tag)
			end
			for _, child in ipairs(old:GetChildren()) do
				child.Parent = new
			end
			new.Parent = old.Parent
			seen[old] = nil
			seen[new] = true
			old:Destroy()
			swapped += 1
		end
	end

	local removed = 0
	for _, root in pairs(ROOTS) do
		for _, d in ipairs(root:GetDescendants()) do
			if d.Parent and d:GetAttribute("DevSync") and not seen[d] then
				d:Destroy()
				removed += 1
			end
		end
	end
	print(("DevSync: %d files, %d updated, %d removed, %d modules swapped"):format(total, changed, removed, swapped))
	return { total = total, changed = changed, removed = removed, swapped = swapped }
end

function DevSync.run(name)
	if not UNGUARDED[name] then
		guard("studio/" .. name)
	end
	local m = Instance.new("ModuleScript")
	m.Name = (name:gsub("%.lua$", ""):gsub("/", "_"))
	m.Source = HttpService:GetAsync(BASE .. "/studio/" .. name, true) .. "\nreturn true\n"
	return require(m)
end

return setmetatable(DevSync, {
	__call = function()
		return DevSync.sync()
	end,
})
