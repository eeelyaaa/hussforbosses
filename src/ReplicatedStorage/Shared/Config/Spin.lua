--!strict
-- Config.Spin: the Lucky Boss Spin (brief system 13). The odds table itself is Shared/SpinTable (one table, the
-- screen reads it). Owned by M2-18. Tests override at runtime; never edit this file for a test.
local Spin = {}

-- The distribution check: this many server rolls; each tier's share within TOLERANCE percentage points of the table
-- (4 standard deviations at 100,000 rolls for the 40% outcome is about 0.62 points).
Spin.CHECK_ROLLS = 100000
Spin.TOLERANCE = 0.7

return Spin
