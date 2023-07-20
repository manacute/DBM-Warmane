local mod	= DBM:NewMod(557, "DBM-Party-BC", 2, 256)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20220518110528")
mod:SetCreatureID(17377)--17377 is boss, 17653 are channelers that just pull with him.

mod:SetModelID(17153)
mod:SetModelOffset(0, 0, -0.1)
mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 30940",
	"SPELL_AURA_REMOVED 30940"
)

local timerBurningNova		= mod:NewCastTimer(5, 30940, nil, nil, nil, 4, nil)
local timerFireNovaCD		= mod:NewCDTimer(25, 33132, nil, nil, nil, 4, nil)
local warningFireNova		= mod:NewSpellAnnounce(33132, 3)

function mod:OnCombatStart(delay)
	timerFireNovaCD:Start(15-delay)
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 30940 then
		warningFireNova:Show()
		timerBurningNova:Show()
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args.spellId == 30940 then
		timerFireNovaCD:Show()
	end
end