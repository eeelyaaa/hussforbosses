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

## Passes and developer products (M2-00, main session in Chrome, 2026-11-25, the manager's yes in chat)
Created under the group's game (universe 10779089797), on sale at the brief's prices, no images yet (UI kit board 04 later), free trials off, managed pricing off. Code key -> id goes into `Config.Shop` (M2-01 / M2-18).

| Key | Name | R$ | Id |
|---|---|---|---|
| pass_auto_punch | Auto Punch | 249 | 2099520308 |
| pass_perfect_auto_punch | Perfect Auto Punch | 399 | 2099490208 |
| pass_2x_power | 2x Power | 349 | 2100054256 |
| pass_2x_cash | 2x Cash | 349 | 2099214230 |
| pass_fast_carry | Fast Carry | 149 | 2099688287 |
| pass_long_lock | Long Lock | 199 | 2100348165 |
| pass_extra_spots | Extra Spots | 249 | 2098776390 |
| pass_quick_hands | Quick Hands | 199 | 2101224215 |
| pass_iron_grip | Iron Grip | 299 | 2101823523 |
| pass_starter_pack | Starter Pack | 99 | 2099874270 |
| product_cash_small | Small Cash Pack | 29 | 3736423996 |
| product_cash_medium | Medium Cash Pack | 79 | 3736424184 |
| product_cash_large | Large Cash Pack | 199 | 3736424519 |
| product_cash_huge | Huge Cash Pack | 399 | 3736424302 |
| product_spin_1 | Lucky Boss Spin x1 | 49 | 3736424361 |
| product_spin_3 | Lucky Boss Spin x3 | 129 | 3736424608 |
| product_spin_10 | Lucky Boss Spin x10 | 399 | 3736424705 |
| product_instant_shield | Instant Shield | 19 | 3736424920 |
| product_shield_breaker | Shield Breaker | 39 | 3736425030 |

Server size (Maximum Visitor Count) set to 8 on place 139279056607944, read back after reload (M2-00).
| Image | `assets-src/stud/stud-color-baked-256.png` (HFB Stud Color Baked 256) | 134322499090979 (decal 95970853589864) | `Tokens.stud.worldColorBakedMapId` | main session (Creator Hub, Chrome), 2026-11-25 | group-owned, AssetTypeId 1 read back; PreloadAsync Failure right after upload (moderation likely pending); re-check before SetupStud |

## M2 imports and clips (main session, 2026-11-26)
| Kind | Source | Asset id | Skin key | Check |
|---|---|---|---|---|
| Image | `assets-src/models/boss-atlas.png` (HFB Boss Atlas M2, decal 97710172015828) | 108529045034445 | `Models.creatures.z2_t2..z6_t6.textureId` | group-owned, AssetTypeId 1; z1_t1 and gloves keep 116542096217311 (cells appended only) |
| Mesh x6 | `z2_t2_atlas.fbx` (Studio 3D importer, Last Imported preset, creator group) | Body 74817454597379, Head 81369259691429, FistL 137359375338333, FistR 107533493934104, TailA 84620791590064, TailB 109535509730296 | `creatures.z2_t2.groups` | models in `ServerStorage.BossScratch`; importer also uploaded its own atlas copy 74236253437666 (unused) |
| Mesh x5 | `z3_t3_atlas.fbx` | Body 130134962728242, Upper 93691925897161, Head 91170633650555, FistL 109655917514539, FistR 140550747084067 | `creatures.z3_t3.groups` | atlas copy 124639306128139 unused |
| Mesh x4 | `z4_t4_atlas.fbx` | Body 134595472358355, Head 117536241681869, FistL 110499296221904, FistR 118331184554897 | `creatures.z4_t4.groups` | atlas copy 89153673523900 unused |
| Mesh x6 | `z5_t5_atlas.fbx` | Body 131367176709138, Head 133730452918557, FistL 103833278107785, FistR 89968252463982, TailA 75606567259717, TailB 102741818269993 | `creatures.z5_t5.groups` | atlas copy 100672977156898 unused |
| Mesh x5 | `z6_t6_atlas.fbx` | Body 108321898599938, Head 103511935236798, FistL 112321661796987, FistR 134367753968255, Sig 104123716997259 | `creatures.z6_t6.groups` | atlas copy 121624406734270 unused |
| Animation x10 | `ServerStorage.HFB_Clips` (BuildClips2), Explorer Save to Roblox, creator group | Flinch R15 134871997175385 / R6 115934676015982; CarryHold 104908826483350 / 115818486780894; StealLift 98967342912981 / 112279758563479; Knockdown 128104978695493 / 77300258469560; Stun 105520069391796 / 135578946454442 | `Models.clips.*`, `Models.clipsR6.*` | all AssetTypeId 24, group 432262304 (GetProductInfo) |

## M2-24 fix-pass re-import (main session, 2026-11-26) — supersedes the z2..z6 rows above
| Kind | Source | Asset id | Skin key |
|---|---|---|---|
| Image | `boss-atlas.png` (HFB Boss Atlas M2b, decal 89243250183815) | 131662969906561 | `creatures.z2_t2..z6_t6.textureId` |
| Mesh | z2_t2_atlas.fbx | Body 86635252190823, Head 92480351659598, FistL 110304413948016, FistR 76594033350875, TailA 84620791590064, TailB 109535509730296 | `creatures.z2_t2.groups` |
| Mesh | z3_t3_atlas.fbx | Body 72958695042638, Upper 120223582736801, Head 101148513208139, FistL 119929680357524, FistR 99980588152630 | `creatures.z3_t3.groups` |
| Mesh | z4_t4_atlas.fbx | Body 121945055273244, Head 116859351158815, FistL 72856501334740, FistR 87415690784851 | `creatures.z4_t4.groups` |
| Mesh | z5_t5_atlas.fbx | Body 105363820205535, Head 73984879618041, FistL 127795680987940, FistR 75544402492491, TailA 81054688719818, TailB 91636845515290 | `creatures.z5_t5.groups` |
| Mesh | z6_t6_atlas.fbx | Body 80783494035999, Head 118805192049060, FistL 87353624750499, FistR 120847069623083, Sig 104123716997259 | `creatures.z6_t6.groups` |
