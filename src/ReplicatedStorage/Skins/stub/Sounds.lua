--!strict
-- stub / Sounds: no sounds. Every id 0 (the audio controller plays nothing for 0); volumes 0.
-- F_BEAT_IN_FILE equals Config.Punch.BEAT so nothing waits on a lead.
return {
	burstVoice = 0,
	F_BEAT_IN_FILE = { 0, 0.213, 0.401 },
	F_LEAD = 0,
	singleHuss = { 0, 0 },
	singleHuss01Gain = 1,
	thud = { bag1 = { 0, 0, 0 } },
	swish = 0,
	sting = 0,
	volumes = { burst = 0, thud = 0, single = 0, sting = 0, swish = 0 },
}
