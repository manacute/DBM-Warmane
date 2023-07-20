local mod	= DBM:NewMod(556, "DBM-Party-BC", 2, 256)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20220518110528")
mod:SetCreatureID(17380)

mod:SetModelID(19372)
mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_SUCCESS 30916"
)
local timerPoisonCloudCD		= mod:NewCDTimer(20, 30916, nil, nil, nil, 4, nil)
local warningPoisonCloud		= mod:NewSpellAnnounce(30916, 3)

function mod:SPELL_CAST_SUCCESS(args)
	if args.spellId == 30916 then
		warningPoisonCloud:Show()
		timerPoisonCloudCD:Start()
	end
end
