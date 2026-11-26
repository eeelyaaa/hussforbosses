# Huss for Bosses: assets

Every asset uploaded to Roblox, all **owned by the group Huss for Bosses (432262304)**. Uploads covered by the
approval: the build plan's "Asset list" only. Record the file, the id, who uploaded it, the date, and where it is
used (the skin table key). Ids go into `src/ReplicatedStorage/Skins/brickbrawl/` (Icons, Sounds, Models), never
anywhere else in `src/`.

| Kind | Source file | Asset id | Skin key | Uploaded by, date | Checked (loads, length, moderation) |
|---|---|---|---|---|---|
| Audio | `assets-src/audio/f_group1_no_breath.wav` (HFB Burst Voice F) | 127740860120528 | `Sounds.burstVoice` | main session (Creator Hub, Chrome), 2026-11-25 | listed under the group; **loads** (PreloadAsync Success, Studio edit + play 2026-11-25), TimeLength 0.5940 s (= local file); probe: loud parts at 0.004 / 0.237 / 0.418 s (`verification/m1-13-audio.md`); moderation state not visible to agents |
| Audio | `assets-src/audio/a_huss4_full_levelled.wav` (HFB Single Huss 02A) | 133382295573645 | `Sounds.singleHuss[1]` | main session, 2026-11-25 | listed; **loads** (PreloadAsync Success, 2026-11-25), TimeLength 0.2390 s |
| Audio | `assets-src/audio/a_huss1.wav` (HFB Single Huss 01A) | 87792871818595 | `Sounds.singleHuss[2]` | main session, 2026-11-25 | listed; **loads** (PreloadAsync Success, 2026-11-25), TimeLength 0.2400 s |
| Audio | `standin/standin_thud_bag1_1.wav` | 100565015513028 | `Sounds.thud.bag1[1]` | main session, 2026-11-25 | listed; **loads** (PreloadAsync Success, 2026-11-25), TimeLength 0.1505 s |
| Audio | `standin/standin_thud_bag1_2.wav` | 108906304686894 | `Sounds.thud.bag1[2]` | main session, 2026-11-25 | listed; **loads** (PreloadAsync Success, 2026-11-25), TimeLength 0.1506 s |
| Audio | `standin/standin_thud_bag1_3.wav` | 131000564218509 | `Sounds.thud.bag1[3]` | main session, 2026-11-25 | listed; **loads** (PreloadAsync Success, 2026-11-25), TimeLength 0.1412 s |
| Audio | `standin/standin_swish.wav` | 120181524699792 | `Sounds.swish` | main session, 2026-11-25 | listed; **loads** (PreloadAsync Success, 2026-11-25), TimeLength 0.2145 s |
| Audio | `standin/standin_sting.wav` | 92977560674627 | `Sounds.sting` | main session, 2026-11-25 | listed; **loads** (PreloadAsync Success, 2026-11-25), TimeLength 0.4000 s |
| Image | `assets-src/stud/stud-color-256.png` (HFB Stud Color 256) | 106741057264448 (decal upload; Image id) | `Tokens.stud.worldColorMapId` | main session, 2026-11-25 | listed under the group; load owed |
| Image | `assets-src/stud/stud-normal-256.png` | 106077758301166 (decal 89960411556173) | `Tokens.stud.worldNormalMapId` | main session, 2026-11-25 | listed; load owed |
| Image | `assets-src/stud/stud-normal-flipped-256.png` | 95643445290942 | `Tokens.stud.worldNormalMapFlippedId` | main session, 2026-11-25 | listed; load owed |
| Image | `assets-src/stud/stud-rough-256.png` | 106124900748892 | `Tokens.stud.worldRoughMapId` | main session, 2026-11-25 | listed; load owed |
| Image | `assets-src/stud/stud-ui-overlay-64.png` | 70915382854444 | `Tokens.stud.uiTileId` | main session, 2026-11-25 | listed; load owed |

Outside the list, for the record: the first group icon, uploaded by the main session on 2026-11-25 at the
manager's request (`pack/approval.md`).

Note: the Creator Hub lists new uploads after a lag of up to ~2 minutes; decal uploads make an Image asset with its own id, and the Image id is the one used.
| Animation | `ServerStorage.HFB_Clips` Jab3_R15 (HFB Jab3 R15) | 107079293119205 | `Models.clips.jab3` | main session (Studio, Save to Roblox, creator the group), 2026-11-25 | read back via KeyframeSequenceProvider: length 0.621, Hit at 0/0.213/0.401 |
| Animation | BigThird_R15 (HFB BigThird R15) | 85557599926728 | `Models.clips.bigThird` | main session, 2026-11-25 | read back: length 0.330, Hit at 0.080 (starts 0.08 s before beat 3) |
| Animation | Jab3_R6 (HFB Jab3 R6) | 131510122151794 | `Models.clipsR6.jab3` | main session, 2026-11-25 | read back: length 0.621, Hit at 0/0.213/0.401 |
| Animation | BigThird_R6 (HFB BigThird R6) | 112874224987934 | `Models.clipsR6.bigThird` | main session, 2026-11-25 | read back: length 0.330, Hit at 0.080 |
| Mesh x5 | `assets-src/models/z1_t1_atlas.fbx` (Studio 3D importer, creator the group) | Body 124930310883753, Head 111961754367044, Sig 110959131671988, FistL 123078999255876, FistR 109820571392209 | `Models.creatures.z1_t1.groups` (wired M1-17) | main session, 2026-11-25 | imported into `ServerStorage.BossScratch`; SetupBosses PASS 0 failed on them |
| Image | atlas texture uploaded by the importer with the FBX | 116542096217311 | `Models.creatures.z1_t1.textureId`, `Models.gloves.textureId` | importer, 2026-11-25 | texel read-back exact (cream 236,207,151); the grey-green was the MeshPart Color tint (default grey), fixed in SetupBosses/SetupGloves (white), M1-17 |
| Mesh x2 | `assets-src/models/gloves_atlas.fbx` | GloveL 76241603600658, GloveR 110446020050450 | `Models.gloves.groups` (wired M1-17) | main session, 2026-11-25 | in BossScratch; SetupGloves PASS 0 failed |
| Mesh x23 | `assets-src/models/z1_t1_perrole.fbx` | see the model in `ServerStorage.BossScratchPerRole` | for the B4 comparison only | main session, 2026-11-25 | imported; not wired |
