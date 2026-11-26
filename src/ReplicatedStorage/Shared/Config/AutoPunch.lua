--!strict
-- Config.AutoPunch: Auto Punch and Perfect Auto Punch on the bag pad (brief system 2; contract C Bag, B20, B23).
-- Owned by M2-10 (team/requirements/m2-contract.md section A). Tests override at runtime; never edit this file for a test.
local AutoPunch = {}

-- The pass keys (Ids.PASSES; Roblox ids in Config.Shop.IDS).
AutoPunch.PASS = "pass_auto_punch"
AutoPunch.PERFECT_PASS = "pass_perfect_auto_punch"
-- The grade every auto tap lands as: Good with Auto Punch, Perfect with Perfect Auto Punch (brief system 2).
AutoPunch.GRADE = "good"
AutoPunch.PERFECT_GRADE = "perfect"
-- A pass bought in this session: PromptGamePassPurchaseFinished(true) is a hint; ownership counts only after
-- UserOwnsGamePassAsync says true (contract M4): tries, seconds apart.
AutoPunch.VERIFY_TRIES = 3
AutoPunch.VERIFY_GAP_S = 3.5

return AutoPunch
