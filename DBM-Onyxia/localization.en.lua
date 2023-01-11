local L

--------------
--  Onyxia  --
--------------
L = DBM:GetModLocalization("Onyxia")

L:SetGeneralLocalization({
	name = "Onyxia"
})

L:SetWarningLocalization({
	WarnWhelpsSoon		= "Onyxian Whelps soon",
	WarnNtoS			= "North to South, stand LEFT or RIGHT",
	WarnStoN			= "South to North, stand LEFT or RIGHT",
	WarnEtoW			= "East to West, stand TOP or BOTTOM",
	WarnWtoE			= "West to East, stand TOP or BOTTOM",
	WarnNEtoSW			= "NE to SW, stand TOP-LEFT or BOTTOM-RIGHT",
	WarnSWtoNE			= "SW to NE, stand TOP-LEFT or BOTTOM-RIGHT",
	WarnNWtoSE			= "NW to SE, stand TOP-RIGHT or BOTTOM-LEFT",
	WarnSEtoNW			= "SE to NW, stand TOP-RIGHT or BOTTOM-LEFT"
})

L:SetTimerLocalization({
	TimerWhelps	= "Onyxian Whelps"
})

L:SetOptionLocalization({
--	TimerWhelps				= "Show timer for Onyxian Whelps",
--	WarnWhelpsSoon			= "Show pre-warning for Onyxian Whelps",
	SoundWTF3				= "Play some funny sounds from a legendary classic Onyxia raid"
})

L:SetMiscLocalization({
--	YellPull = "How fortuitous. Usually, I must leave my lair in order to feed.",
	YellP2 = "This meaningless exertion bores me. I'll incinerate you all from above!",
	YellP3 = "It seems you'll need another lesson, mortals!"
})