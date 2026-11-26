# M2-10b: the plain six-zone test strip (evidence)
Builder (sonnet), 2026-11-25. Quality pass: Function only (greybox; M3 builds the real world). Game repo, nothing committed.

## Built: `studio/BuildStrip.lua` (run after `BuildSlice.lua`; idempotent; BuildSlice wipes Zones, so run it again after)
- Zone n starts at Z0 = 236 + 120 (n - 1). Lane = Config.Zones.LANE (X 206, +Z), 36 wide (X 188..224), to Z 956.
- Zone 1: `LaneExt` (Z 300..380) and `Pads.Roll1..3` (z1_roll1..3). Zones 2..6: `Ground` (zone 2 from 380, since BuildSlice's Z1
  ground runs to 380), `Lane`, `StartLine` (white, 0.2 up, no collide), `Pads.Fixed|Roll1|Roll2|Roll3`.
- 23 pad Models as spec: tag HFB_BossPad, PadId / ZoneId / Kind, Ring 12x1x12 RingRadius 6 (no collide), invisible BossAnchor
  (Y 1), NumberAnchor (Y 13.5). Pads 40/60/80/100 studs in, alternating east X 233 / west X 179. Colours from Skin tokens
  (zone ground / ground2, padStone, laneGrey, kerbWhite), MaterialVariant Stud.
- 85 parts added (75 in Z2..Z6, 1 LaneExt, 9 in z1 rolls). No blockers needed (nothing tall); no hazards; no labels.

## Checks (Studio MCP, `studio` lock held by builder-sixzones, released; play stopped; TmpChecks and HFB_ attributes cleaned)
- BuildStrip asserts: PASS 8/8: 24 pads match Config.Zones.PADS (ids, zone, kind, ring, anchors); exactly 24 tagged; clear walk
  (nothing solid above 1 stud within 15 studs each way along Z of any BossAnchor); lane axis; walks inside Z 236..956;
  nothing taller than 4; Stud variant.
- **ZFIGHT: 0 pairs** (121 visible boxes scanned). `python tools/check_labels.py`: 0 problems. `check_guard`: 47 scripts OK.
- **M2-10 `checks/Zones.lua` on the real pads: a 19/0, b 7/0, c 16/0 = 42/0.** Phase a says "0 stand-ins added".
  The check's own stand-ins are skipped (all 24 pads exist).

## TEAM CALL M2-10b-1: StudProof moved
`Workspace.StudProof` (X 100..280, Z 400..470) lay inside zone 2 (3 coplanar pairs, and z2_roll1/roll2 stand there). The
proof is answered ("B on both"). `SetupStud.lua` now places it at X 440..620 (east of the strip); it was re-run once. No
other file references its position.

## On-screen checks (UNVERIFIED, nobody has looked)
Default camera and a phone viewport, edit-mode fly along X 206: (1) zone 2..6 grounds change colour at each start line;
(2) pads alternate east/west, lane continuous Z 236..956, no seam or flicker at Z 300/380 (lane joins) or zone seams;
(3) rolls pads read as different from fixed (fixed pad is grey stone, roll pads zone ground2); (4) StudProof is now beside
the strip at X 440+.
