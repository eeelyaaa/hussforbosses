--!strict
-- Config.Offline: offline earnings (brief system 11; m2-contract.md C "Offline.*" with [M2-02 M9]).
-- Owned by M2-14. Tests override at runtime; never edit this file for a test.
--
-- What a player earned while away is the fill of their own pads between the saved leave time and now (Income's
-- padCash / padStamp, each pad capped at Config.Base.PAD_CAP_S = 2 hours, cash already on the pad counting toward
-- the cap). Collect moves that much FROM the pads to cash, so it can never pay twice.
local Offline = {}

-- Shown only if the player was away at least this long and earned something (brief 11).
Offline.MIN_AWAY_S = 60

-- Offline.Summary is sent this many seconds after the join (the client's screens start a moment after the
-- player), then sent again at each later time while it is still not collected (TEAM CALL M2-14-3: the summary is
-- otherwise sent once and can be missed; there is no "client ready" remote).
Offline.SEND_AT_S = { 2, 6, 15 }

return Offline
