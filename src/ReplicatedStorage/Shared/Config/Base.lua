--!strict
-- Config.Base: the base plot, spots and cash pads (brief systems 7 and 8; m1-contract.md sections C, E).
local Base = {}

Base.SPOTS_AT_START = 10
Base.PLACE_RANGE = 14 -- Base.Place: within 14 studs of the spot
Base.COLLECT_RANGE = 4 -- the owner's character within 4 studs of the cash pad collects it
Base.PAD_CAP_S = 7200 -- a pad holds at most 2 hours of its boss's income

return Base
