--!nonstrict
-- Ui/WorldLabel: the one way to put UI over a thing in the world (M2-05; the manager's rule, 2026-11-25: world labels shrink
-- with distance like the world, or they do not exist). A BillboardGui whose Size is in STUDS (the Scale part of a
-- BillboardGui Size is studs, the Offset part is pixels). Never pass pixel sizes, never AlwaysOnTop, no huge MaxDistance:
-- a label that must be read from far away belongs in the HUD. tools/check_labels.py fails on a BillboardGui with an
-- Offset Size anywhere in src/ or studio/. Display only.
local WorldLabel = {}

WorldLabel.MAX_DISTANCE = 150 -- studs; past this the label is simply not drawn

-- opts: adornee (BasePart, required), parent (default adornee), studsW, studsH (required, studs), offset (Vector3 studs),
-- name, maxDistance (<= 150), enabled (default true)
function WorldLabel.new(opts)
	assert(opts.adornee and opts.studsW and opts.studsH, "WorldLabel.new needs adornee, studsW, studsH")
	local gui = Instance.new("BillboardGui")
	gui.Name = opts.name or "WorldLabel"
	gui.Size = UDim2.new(opts.studsW, 0, opts.studsH, 0) -- Scale = studs, Offset stays 0
	gui.StudsOffset = opts.offset or Vector3.zero
	gui.AlwaysOnTop = false
	gui.LightInfluence = 0
	gui.MaxDistance = math.min(opts.maxDistance or WorldLabel.MAX_DISTANCE, WorldLabel.MAX_DISTANCE)
	gui.ResetOnSpawn = false
	gui.Adornee = opts.adornee
	gui.Enabled = opts.enabled ~= false
	gui.Parent = opts.parent or opts.adornee
	return gui
end

return WorldLabel
