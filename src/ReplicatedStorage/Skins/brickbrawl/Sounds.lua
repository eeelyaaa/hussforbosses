--!strict
-- brickbrawl / Sounds: asset id per sound slot, and the burst voice's own beat table (F_BEAT_IN_FILE, measured on the uploaded F). Source: sound-direction.md
-- M1-04 (audio-specialist, 2026-11-25): slots from m1-contract F. Every id is 0 until the main session uploads (team/assets.md); 0 = not wired, never a silent default.
-- F_BEAT_IN_FILE is FINAL for M1 (M1-13, 2026-11-25): measured on the UPLOADED F in Studio (studio/checks/Probe.lua, AudioAnalyzer peak per block at
-- PlaybackSpeed 0.1, onset = last sample 20 dB under each loud part's peak): 0.004, 0.237, 0.418. Each is within 20 ms of BEAT + F_LEAD (-6, +14, +7 ms), so B21
-- does not apply and Config.Punch.BEAT is unchanged. Detail: team/verification/m1-13-audio.md. (The local file read 0.007, 0.233, 0.420.)
return {
	-- the burst voice: slot 03 F, f_group1_no_breath.wav, 0.594 s, one Play() per landed burst, PlaybackSpeed never changed
	burstVoice = 127740860120528,
	F_BEAT_IN_FILE = { 0.004, 0.237, 0.418 }, -- seconds into the file at which each of the three loud parts starts (measured on the uploaded asset)
	F_LEAD = 0.010, -- the file's own lead before the first huss (contract F; the local probe reads 0.007)

	-- single husses, strict alternation 02 A then 01 A; 01 A is not levelled (RMS -15.7 against -13.5 dBFS), so it plays x1.25
	singleHuss = { 133382295573645, 87792871818595 }, -- { 02 A a_huss4_full_levelled.wav, 01 A a_huss1.wav }
	singleHuss01Gain = 1.25,

	-- stand-in set (earshot, one bag tier; replaced by the six tier sets later). Three takes, never the same take twice in a row.
	thud = { bag1 = { 100565015513028, 108906304686894, 131000564218509 } },
	swish = 120181524699792, -- soft air swish on a bag Miss (none on a fight Miss)
	sting = 92977560674627, -- Perfect sting (0.40 s)

	-- starting Sound.Volume per use (tuned by the manager's ear; burst group and effects group)
	volumes = { burst = 0.55, thud = 0.5, single = 0.55, sting = 0.4, swish = 0.25 },
}
