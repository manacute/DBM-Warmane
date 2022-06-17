local mod	= DBM:NewMod("Broodlord", "DBM-BWL", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20220518110528")
mod:SetCreatureID(12017)

mod:SetModelID(14308)
mod:RegisterCombat("yell", L.Pull)--L.Pull is backup for classic, since classic probably won't have ENCOUNTER_START to rely on and player regen never works for this boss

mod:RegisterEventsInCombat(
	"SPELL_CAST_SUCCESS 23331 18670 24573 25778",
	"SPELL_AURA_APPLIED 24573",
	"SPELL_AURA_REMOVED 24573"
)

--Mortal Strike: 25-35, Blast Wave: 20-35, Knock Away: 15-30.
--(ability.id = 18670 or ability.id = 23331 or ability.id = 24573) and type = "cast"
local warnBlastWave		= mod:NewSpellAnnounce(23331, 2)
local warnKnockAway		= mod:NewSpellAnnounce(25778, 3)
local warnMortal		= mod:NewTargetNoFilterAnnounce(24573, 2, nil, "Tank|Healer", 4)

local timerBlastWave 	= mod:NewCDTimer(20, 23331, nil, nil, nil, 2)
local timerMortalStrike = mod:NewCDTimer(25, 24573, nil, nil, nil, 4)
local timerMortal		= mod:NewTargetTimer(5, 24573, nil, "Tank|Healer", 4, 5, nil, DBM_CORE_L.TANK_ICON)

function mod:OnCombatStart(delay)
	timerBlastWave:Start(12-delay)  -- initial timers
	timerMortalStrike:Start(20-delay)
end

function mod:SPELL_CAST_SUCCESS(args)
	if args.spellId == 23331 and args:IsSrcTypeHostile() then
		warnBlastWave:Show()
		timerBlastWave:Start()
	elseif args.spellId == 25778 then
		warnKnockAway:Show()
	elseif args.spellId == 24573 then
		timerMortalStrike:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 24573 and args:IsDestTypePlayer() then
		warnMortal:Show(args.destName)
		timerMortal:Start(args.destName)
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args.spellId == 24573 and args:IsDestTypePlayer() then
		timerMortal:Stop(args.destName)
	end
end