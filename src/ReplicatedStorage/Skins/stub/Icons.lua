--!strict
-- stub / Icons: the 64 keys of ui-kit board 04 (brickbrawl's Icons.lua), every id 0 (the Kit draws stand-ins).
local KEYS = [[power cash punchStrength punchSpeed spinTicket heart heartLost rebirthStar
hussGlove shop rebirth upgrade pickUp place grab steal sell swap run done settings music effects bagPanel luckySpin
firstArrow pointerArrow bossBeaten lockShield shield shieldDown shieldBroken locked timer stealAlert hazard
nearImpossible offlineEarnings deliveryCrate zone1 zone2 zone3 zone4 zone5 zone6 autoPunch perfectAutoPunch power2x
cash2x fastCarry longLock extraSpots quickHands ironGrip starterPack cashPackSmall cashPackMedium cashPackLarge
cashPackHuge spin1 spin3 spin10 instantShield shieldBreaker]]

local icons = {}
for key in string.gmatch(KEYS, "%S+") do
	icons[key] = 0
end
return icons
