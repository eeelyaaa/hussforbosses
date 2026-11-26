--!strict
-- Skin: the one way code reaches what a player sees or hears for an id.
--   local Skin = require(ReplicatedStorage.Shared.Skin)
--   Skin.Names.creatures.z1_t1, Skin.Tokens.colors.hussRed, Skin.Sounds.burstVoice ...
--   Skin.need("Names.creatures.z1_t1")   -- the value, or an error naming the missing key
--   Skin.get("Sounds.sting")             -- the value or nil
-- The active skin is Config.SkinId, or the ForceSkin test hook in Studio (the skin check), read once when this
-- module is first required. Nothing outside Skins/ may hold a display name, a hex colour or an asset id.
-- A missing key is nil, never a silent default: callers that need a key use Skin.need.
--
-- Checks (M1-01; studio/CheckSkin.lua and tools/check_skin.py use them):
--   Skin.SCHEMA                 the keys every skin must have at M1 (m1-contract.md section F) and their types
--   Skin.check(skinTable)       -> { problem strings } (empty = passes)
--   Skin.shapeDiff(a, b, la, lb)-> { problem strings }: keys one skin has and the other lacks, or types that differ
--   Skin.load(id)               -> the raw skin table of ReplicatedStorage.Skins.<id> (for checks)
--   Skin.assetUrl(id)           -> the content string for a numeric asset id (nil for nil/0/negative/non-number).
--                                  The ONE place outside Skins/ that holds the asset scheme; tools/check_skin.py
--                                  exempts exactly this function. Every Image, SoundId, AnimationId goes through it.
local Config = require(script.Parent.Config)
local TestHooks = require(script.Parent.TestHooks)

local SECTIONS = { "Names", "Tokens", "Models", "Icons", "Sounds", "Lighting", "Effects", "Dressing" }

local Skin = {} :: any
Skin.SECTIONS = SECTIONS

-- Skins are found beside Shared (ReplicatedStorage.Skins in the game), so a check can clone Shared and Skins
-- together into one folder and load a fresh pair (edit-mode require caches modules).
function Skin.load(id: string): any
	local skins = (script.Parent.Parent :: Instance):WaitForChild("Skins", 10)
	assert(skins, "Skin: no Skins folder beside Shared")
	local folder = (skins :: Instance):WaitForChild(id, 10)
	assert(folder and folder:IsA("ModuleScript"), "Skin: no skin module ReplicatedStorage.Skins." .. tostring(id))
	return require(folder :: ModuleScript)
end

-- The one content-string builder. Keep it a self-contained `function Skin.assetUrl ... end` block: check_skin.py
-- exempts the lines from the `function Skin.assetUrl` line to the next unindented `end`, in this file only.
function Skin.assetUrl(id: any): string?
	if type(id) == "number" and id > 0 and id % 1 == 0 then
		return "rbxassetid://" .. string.format("%d", id)
	end
	return nil
end

local function walk(t: any, path: string): (any, boolean)
	local v = t
	for part in string.gmatch(path, "[^%.]+") do
		if type(v) ~= "table" then
			return nil, false
		end
		local key: any = tonumber(part) or part
		v = v[key]
		if v == nil then
			return nil, false
		end
	end
	return v, true
end

-- The schema: "path:type". Types are typeof() names; "id" = a number >= 0 (0 = not uploaded yet).
local function list(prefix: string, keys: { string }, ty: string): { string }
	local out = {}
	for _, k in ipairs(keys) do
		table.insert(out, prefix .. k .. ":" .. ty)
	end
	return out
end

local SCHEMA: { string } = {}
local function add(items: { string })
	for _, s in ipairs(items) do
		table.insert(SCHEMA, s)
	end
end
local BANDS = { "easy", "fair", "hard", "veryHard", "brutal", "impossible" }
add({ "Names:table", "Tokens:table", "Models:table", "Icons:table", "Sounds:table", "Lighting:table", "Effects:table", "Dressing:table" })
-- Names
add({ "Names.game:string", "Names.zones.1:string", "Names.creatures.z1_t1:string", "Names.hazards.1:string", "Names.bags.1:string" })
add(list("Names.bands.", BANDS, "string"))
add(list("Names.grades.", { "good", "perfect" }, "string"))
add(list("Names.hudWords.", { "huss", "run", "place", "grab", "power", "cash" }, "string"))
add(list("Names.tiers.", { "1", "2", "3", "4", "5", "6" }, "string"))
-- Tokens
add(list("Tokens.colors.", {
	"panelGrey", "plateBlue", "hussRed", "cashGreen", "shopGold", "shieldCyan", "alarmOrange", "flashYellow", "white",
	"ink", "disabledGrey", "disabledText", "laneGrey", "kerbWhite", "arrowYellow", "padStone", "dirt", "bagRed",
}, "Color3"))
add(list("Tokens.colors.tier.", { "1", "2", "3", "4", "5", "6" }, "Color3"))
add(list("Tokens.colors.band.", BANDS, "Color3"))
add(list("Tokens.colors.zone1.", { "ground", "ground2", "structure", "foliage", "dark", "accent" }, "Color3"))
add({ "Tokens.font.family:string", "Tokens.font.weight:string" })
add(list("Tokens.ui.", {
	"outlinePx", "radiusPx", "lipPx", "shadowPx", "shadowAlpha", "panelPad", "gap", "header", "buttonH", "touchMin",
	"designW", "designH", "mouseScale", "studTilePx", "studTileMin", "studTileMax", "hussButtonPx", "hussButtonMinPx",
	"ringStartScale", "ringThickPx", "bandInner", "bandOuter", "bandThickPx", "ringLandScale", "pipPx", "pipGap",
}, "number"))
add(list("Tokens.stud.", { "uiTileId", "worldColorMapId", "worldNormalMapId", "worldRoughMapId" }, "id"))
add({ "Tokens.stud.studsPerTile:number", "Tokens.stud.variantName:string", "Tokens.stud.normalFlip:boolean" })
-- Models
add({
	"Models.creatures.z1_t1.model:string", "Models.creatures.z1_t1.bodyType:number", "Models.creatures.z1_t1.heightStuds:number",
	"Models.creatures.z1_t1.groups:table", "Models.bags.1:any", "Models.hazards.1:string", "Models.gloves.model:string",
	"Models.clips.jab3:id", "Models.clips.bigThird:id",
})
-- Sounds
add({
	"Sounds.burstVoice:id", "Sounds.F_BEAT_IN_FILE.1:number", "Sounds.F_BEAT_IN_FILE.2:number", "Sounds.F_BEAT_IN_FILE.3:number",
	"Sounds.F_LEAD:number", "Sounds.singleHuss.1:id", "Sounds.singleHuss.2:id", "Sounds.singleHuss01Gain:number",
	"Sounds.thud.bag1:table", "Sounds.swish:id", "Sounds.sting:id", "Sounds.volumes.burst:number", "Sounds.volumes.thud:number",
})
-- Effects (declared, empty at M1)
add({ "Effects.stars:table", "Effects.cubeBurst:table" })
Skin.SCHEMA = SCHEMA

local function typeOk(v: any, ty: string): boolean
	if ty == "any" then
		return true
	elseif ty == "id" then
		return typeof(v) == "number" and v >= 0 and v % 1 == 0
	end
	return typeof(v) == ty
end

function Skin.check(t: any): { string }
	local problems = {}
	for _, entry in ipairs(SCHEMA) do
		local path, ty = string.match(entry, "^(.-):(%w+)$")
		local v, found = walk(t, path :: string)
		if not found then
			table.insert(problems, "missing " .. path)
		elseif not typeOk(v, ty :: string) then
			table.insert(problems, ("%s is %s, wants %s"):format(path :: string, typeof(v), ty :: string))
		end
	end
	return problems
end

function Skin.shapeDiff(a: any, b: any, la: string?, lb: string?): { string }
	local nameA, nameB = la or "a", lb or "b"
	local problems = {}
	local function rec(x: any, y: any, path: string, depth: number)
		if depth > 8 then
			return
		end
		for k, vx in pairs(x) do
			local p = path == "" and tostring(k) or (path .. "." .. tostring(k))
			local vy = y[k]
			if vy == nil then
				table.insert(problems, ("%s has %s, %s does not"):format(nameA, p, nameB))
			elseif typeof(vx) ~= typeof(vy) then
				table.insert(problems, ("%s is %s in %s, %s in %s"):format(p, typeof(vx), nameA, typeof(vy), nameB))
			elseif type(vx) == "table" then
				rec(vx, vy, p, depth + 1)
			end
		end
		for k in pairs(y) do
			if x[k] == nil then
				local p = path == "" and tostring(k) or (path .. "." .. tostring(k))
				table.insert(problems, ("%s has %s, %s does not"):format(nameB, p, nameA))
			end
		end
	end
	rec(a, b, "", 0)
	table.sort(problems)
	return problems
end

-- The active skin.
local skinId = TestHooks.get("ForceSkin") or Config.SkinId
local active = Skin.load(skinId)
Skin.Id = skinId
for _, s in ipairs(SECTIONS) do
	Skin[s] = active[s]
end

function Skin.get(path: string): any
	local v = walk(active, path)
	return v
end

function Skin.need(path: string): any
	local v, found = walk(active, path)
	if not found then
		error(("Skin: skin '%s' has no key %s"):format(skinId, path), 2)
	end
	return v
end

return Skin
