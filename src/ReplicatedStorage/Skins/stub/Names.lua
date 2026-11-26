--!strict
-- stub / Names: every name is its own id, so a name leaking into the rules shows up as an id.
local Ids = require((script.Parent.Parent.Parent :: Instance):WaitForChild("Shared"):WaitForChild("Ids")) -- Shared beside Skins

local function byIndex(prefix: string, n: number): { string }
	local t = {}
	for i = 1, n do
		t[i] = prefix .. i
	end
	return t
end
local function byKey(keys: { string }): { [string]: string }
	local t = {}
	for _, k in ipairs(keys) do
		t[k] = k
	end
	return t
end
local products = byKey(Ids.PASSES)
for k, v in pairs(byKey(Ids.PRODUCTS)) do
	products[k] = v
end

return {
	game = "stub",
	zones = byIndex("zone", 6),
	tiers = byIndex("tier", 6),
	creatures = byKey(Ids.CREATURES),
	hazards = byIndex("hazard", 6),
	bags = byIndex("bag", 6),
	bands = byKey(Ids.BANDS),
	grades = { good = "good", perfect = "perfect" },
	hudWords = byKey({ "huss", "run", "place", "grab", "power", "cash" }),
	products = products,
}
