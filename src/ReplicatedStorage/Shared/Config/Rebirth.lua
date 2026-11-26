--!strict
-- Config.Rebirth: the rebirth table and the reset / kept lists (brief system 12; m2-contract.md C "Rebirth.*", D
-- "[M2-02 M2] Rebirth, every key"). Owned by M2-14. Tests override at runtime; never edit this file for a test.
local Rebirth = {}

-- Power needed for rebirth n (index n = the rebirth about to be taken). 10 rebirths in version 1 (TEAM CALL).
Rebirth.REQUIRED = { 10e6, 16e6, 25e6, 40e6, 65e6, 100e6, 160e6, 250e6, 400e6, 650e6 }
Rebirth.MAX = 10

-- Reward per rebirth: bag Power x(1 + rebirths), boss income x(1 + 0.5 x rebirths) (brief 12). The screens read the
-- steps; Systems/Bag and Systems/Income read the functions.
Rebirth.BAG_MULT_STEP = 1
Rebirth.INCOME_STEP = 0.5
function Rebirth.POWER_MULT(rebirths: number): number
	return 1 + Rebirth.BAG_MULT_STEP * rebirths
end
function Rebirth.INCOME_MULT(rebirths: number): number
	return 1 + Rebirth.INCOME_STEP * rebirths
end

-- Rebirth.Request: at most one accepted rebirth per player per this many seconds (contract C).
Rebirth.COOLDOWN_S = 5

-- Every key of the saved record, once, as reset or kept ([M2-02 M2]; studio/checks/Rebirth.lua asserts that the two
-- lists together name every schema key exactly once).
--   power 0; cash = min(cash, boughtCash); strengthLevel 1; speedLevel 1; bosses and crate: only the player's own
--   bought bosses stay (bought.buyer == userId), re-placed lowest spot first at their level with padCash 0 and
--   padStamp now, the rest of them to the crate; shieldReadyAt 0.
Rebirth.RESET = { "power", "cash", "strengthLevel", "speedLevel", "bosses", "crate", "shieldReadyAt" }
-- rebirths goes up by one; nextUid is never reset (uids stay unique for ever); purchases and starterPackGiven are
-- kept so nothing is granted twice.
Rebirth.KEPT = {
	"version", "rebirths", "boughtCash", "zonesBeaten", "spinTickets", "breakerCharges", "starterPackGiven",
	"purchases", "transferNote", "nextUid", "leftAt", "flags", "settings", "lock",
}

return Rebirth
