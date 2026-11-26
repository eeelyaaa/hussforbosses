--!strict
-- Config.Policy: PolicyService (build plan "PolicyService checks"; m2-contract.md H, M2-02 S10). Owned by M2-15.
-- Tests override at runtime (or with the PolicyTrading / PolicyRandom hooks); never edit this file for a test.
local Policy = {}

Policy.TIMEOUT_S = 10 -- GetPolicyInfoForPlayerAsync: no answer in 10 s counts as a failure
-- Until the answer, and on failure or timeout: restrictive on both flags.
Policy.DEFAULT_RESTRICTED = true -- ArePaidRandomItemsRestricted
Policy.DEFAULT_TRADING = false -- IsPaidItemTradingAllowed

return Policy
