--!nonstrict
-- Moves: the boss move tables (m1-contract.md section H). Structure, not skin: fractions of the boss's height H,
-- degrees, seconds, group names. No display names, colours or asset ids.
--
--   Moves.get(bodyType, creatureId?)    -> the body-type set (1 biped, 2 squat, 3 tailed, 5 swayer) or nil
--   Moves.sig(creatureId)               -> the creature's signature set { attack, lastHeart } or nil
--   Moves.resolve(bodyType, creatureId, name) -> the move table: the signature's if it has one, else the set's
--   Moves.check(set, label)             -> { problem strings } (empty = the schema holds)
--
-- A move: { length, loop?, final?, suppressBase?, blendIn?, perfectScale?, flashAt?, impactAt?, keys }.
-- keys: { { t, ease = "Quad"|"Back"|"Sine", pose = { [group] = { p = {x,y,z}?, r = {x,y,z}?, s = number|{x,y,z}? } } } }
-- Each GROUP has its own track made of the keys it appears in (a key's pose for a group is reached at t, with that
-- key's ease, from the group's previous key; before its first key the group is at rest; after its last it holds).
-- To hold a pose, key it again later; to snap, give the key a short interval. A group absent from a key is not
-- touched by it. p: offset from rest in fractions of H, in the model's own axes (x right, y up, -z forward, the
-- way the boss faces). r: degrees about the group's own pivot, X then Y then Z; +x tips the front up (leans back).
-- s: scale about the group's pivot: a number, or {x,y,z} for a squash and stretch.
-- loop: wraps at length (each group's last key should equal its rest or first pose).
-- final = "hold": the last pose stays after the move (the defeat, which ends on the player's head).
-- suppressBase: the running loop (guard/idle) is paused while this move plays.
-- blendIn: seconds a loop eases in from nothing (so starting a guard does not pop).
-- perfectScale: p and r are multiplied by this when play is given opts.perfect.
-- flashAt: seconds at which the whole boss flashes white for 0.05 s. impactAt: seconds at which onImpact fires.
local Moves = {}

Moves.NAMES = { "idle", "guard", "hitGood", "hitPerfect", "hitBig", "attack", "lastHeart", "gloat", "defeat", "halfIdle", "carryRock" }
-- Upper (the rearing swayer's upper body), TailA and TailB (the tailed striker's tail) are M2's; a boss without a group
-- skips it. All joints hang off Body (B11), so a group riding another is made flat in Moves/_lib.lua.
Moves.GROUPS = { "Body", "Upper", "Head", "Sig", "FistL", "FistR", "TailA", "TailB" }
-- The brief's lengths (style guide section 5); loops have no brief length.
Moves.LENGTHS = { hitGood = 0.15, hitPerfect = 0.2, hitBig = 0.3, attack = 0.45, lastHeart = 1.0, gloat = 0.35, defeat = 0.8 }

-- Body types (Skins Models bodyType; build plan "Body types"): 1 biped bruiser, 2 squat stomper, 3 tailed striker,
-- 5 rearing swayer. 4 charger, 6 flyer, 7 floater are M3.
local BODY_TYPE_MODULES = { [1] = "biped", [2] = "squat", [3] = "tailed", [5] = "swayer" }

local Geo = require(script._geo)
local built = {} -- sets made from a pivot layout, one per creature (or per body type when the creature has no layout yet)

-- The body type's set. Squat's is a plain table; the others are built from the creature's pivot layout (_geo.lua), the
-- body type's reference boss when the creature has none.
function Moves.get(bodyType: number, creatureId: string?)
	local name = BODY_TYPE_MODULES[bodyType]
	local m = name and script:FindFirstChild(name)
	local mod = m and require(m)
	if not mod then
		return nil
	end
	if not mod.build then
		return mod
	end
	local key = (creatureId and Geo.creatures[creatureId]) and creatureId or ("type" .. bodyType)
	local set = built[key]
	if not set then
		set = mod.build(Geo.of(creatureId, bodyType))
		built[key] = set
	end
	return set
end

function Moves.sig(creatureId: string)
	local folder = script:FindFirstChild("sig")
	local m = folder and creatureId and folder:FindFirstChild(creatureId)
	return m and require(m) or nil
end

function Moves.resolve(bodyType: number, creatureId: string?, name: string)
	local sig = creatureId and Moves.sig(creatureId)
	if sig and sig[name] then
		return sig[name]
	end
	local set = Moves.get(bodyType, creatureId)
	return set and set[name] or nil
end

local EASES = { Quad = true, Back = true, Sine = true }

local function vec3ok(v, what, out)
	if type(v) ~= "table" or type(v[1]) ~= "number" or type(v[2]) ~= "number" or type(v[3]) ~= "number" then
		table.insert(out, what .. ": not {x,y,z}")
	end
end

function Moves.check(set, label: string, isSignature: boolean?)
	local problems = {}
	local function bad(s)
		table.insert(problems, label .. ": " .. s)
	end
	local groups = {}
	for _, g in ipairs(Moves.GROUPS) do
		groups[g] = true
	end
	for _, name in ipairs(Moves.NAMES) do
		if not isSignature and not set[name] and name ~= "attack" and name ~= "lastHeart" then
			bad("missing move " .. name)
		end
	end
	for name, mv in pairs(set) do
		if type(mv) == "table" then
			if type(mv.length) ~= "number" or mv.length <= 0 then
				bad(name .. ": length")
			end
			local want = Moves.LENGTHS[name]
			if want and math.abs(mv.length - want) > 1 / 60 then
				bad(("%s: length %.3f, brief says %.2f"):format(name, mv.length, want))
			end
			local prev = -1
			for i, k in ipairs(mv.keys or {}) do
				if type(k.t) ~= "number" or k.t < prev or k.t > mv.length + 1e-6 then
					bad(("%s: key %d time out of order or past the length"):format(name, i))
				end
				prev = k.t or prev
				if not EASES[k.ease] then
					bad(("%s: key %d ease"):format(name, i))
				end
				for g, p in pairs(k.pose or {}) do
					if not groups[g] then
						bad(("%s: key %d unknown group %s"):format(name, i, tostring(g)))
					end
					if p.p then
						vec3ok(p.p, name .. " p", problems)
					end
					if p.r then
						vec3ok(p.r, name .. " r", problems)
					end
					if p.s ~= nil then
						local sx, sy, sz
						if type(p.s) == "number" then
							sx, sy, sz = p.s, p.s, p.s
						else
							sx, sy, sz = p.s[1], p.s[2], p.s[3]
						end
						local lo, hi = 0.0, 1.2
						if g == "Head" then
							lo, hi = 1, 1
						elseif g == "Body" then
							lo, hi = 0.85, 1.15
						end
						for _, v in ipairs({ sx, sy, sz }) do
							if v < lo - 1e-6 or v > hi + 1e-6 then
								bad(("%s: %s scale %.2f outside %.2f..%.2f"):format(name, g, v, lo, hi))
							end
						end
					end
				end
			end
		end
	end
	return problems
end

return Moves
