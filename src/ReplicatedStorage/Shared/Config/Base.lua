--!strict
-- Config.Base: the base plot, spots and cash pads (brief systems 7 and 8; m1-contract.md C, E; m2-contract.md C).
local Base = {}

Base.SPOTS_AT_START = 10
Base.REBIRTH_SPOTS = 5 -- +1 per rebirth, up to +5 (spots 11..15)
Base.EXTRA_SPOTS = { 16, 17 } -- the Extra Spots pass's two back corners
Base.EXTRA_PASS = "pass_extra_spots"
Base.MAX_SPOTS = 17
Base.PLACE_RANGE = 14 -- Place, Pick Up, Swap, Upgrade: within 14 studs of the spot
Base.PLACE_HEIGHT = 10 -- and at most this far above or below it
Base.COLLECT_RANGE = 4 -- the owner's character within 4 studs of the cash pad collects it
Base.PAD_CAP_S = 7200 -- a pad holds at most 2 hours of its boss's income
Base.SELL_MULT = 20 -- sell value = 20 x the boss's current income per second (brief system 7)

-- The plot's size in its own frame (base-layout: 50 across, 92 deep from the front fence line).
Base.PLOT_W = 50
Base.PLOT_D = 92

return Base
