local mod	= DBM:NewMod("Council", "DBM-BlackTemple")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20220518110528")
mod:SetCreatureID(22949, 22950, 22951, 22952)

mod:SetModelID(21416)
mod:SetUsedIcons(1)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 41455 41481",
	"SPELL_CAST_SUCCESS 41541 41476 41482",
	"SPELL_AURA_APPLIED 41485 41481 41482 41541 41476 41475 41452 41453 41450 41451",
	"SPELL_AURA_REMOVED 41479 41485"
)

local warnPoison			= mod:NewTargetNoFilterAnnounce(41485, 3, nil, "Healer", 3)
local warnVanish			= mod:NewTargetNoFilterAnnounce(41476, 3)
local warnVanishEnd			= mod:NewEndAnnounce(41476, 3)
local warnDevAura			= mod:NewSpellAnnounce(41452, 3, nil, "Physical", 2)
local warnResAura			= mod:NewSpellAnnounce(41453, 3, nil, "-Physical", 2)

local specWarnShield		= mod:NewSpecialWarningReflect(41475, false, nil, nil, 1, 2)
local specWarnFlamestrike	= mod:NewSpecialWarningMove(41481, nil, nil, nil, 1, 2)
local specWarnBlizzard		= mod:NewSpecialWarningMove(41482, nil, nil, nil, 1, 2)
local specWarnConsecration	= mod:NewSpecialWarningMove(41541, nil, nil, nil, 1, 2)
local specWarnCoH			= mod:NewSpecialWarningInterrupt(41455, "HasInterrupt", nil, 2, 1, 2)
local specWarnImmune		= mod:NewSpecialWarning("Immune", false)

local timerVanish			= mod:NewBuffActiveTimer(31, 41476, nil, nil, nil, 6)
local timerShield			= mod:NewBuffActiveTimer(20, 41475, nil, false, nil, 5, nil, DBM_COMMON_L.HEALER_ICON..DBM_COMMON_L.DAMAGE_ICON)
local timerMeleeImmune		= mod:NewTargetTimer(15, 41450, nil, "Physical", 2, 5, nil, DBM_COMMON_L.DAMAGE_ICON)
local timerSpellImmune		= mod:NewTargetTimer(15, 41451, nil, "-Physical", 2, 5, nil, DBM_COMMON_L.DAMAGE_ICON)
local timerDevAura			= mod:NewBuffActiveTimer(30, 41452, nil, false, 2, 5, nil, DBM_COMMON_L.DAMAGE_ICON)
local timerResAura			= mod:NewBuffActiveTimer(30, 41453, nil, false, 2, 5, nil, DBM_COMMON_L.DAMAGE_ICON)

local timerCircleOfHealingCD = mod:NewCDTimer(20, 41455, nil, false, nil, 4, nil, DBM_COMMON_L.INTERRUPT_ICON)
local timerBlizzardCD = mod:NewCDTimer(60, 41482, nil, false, nil, 2)
local timerFlamestrikeCD = mod:NewCDTimer(60, 41481, nil, false, nil, 2)
local timerConsecrationCD = mod:NewCDTimer(30, 41541, nil, nil, nil, 2)
local timerVanishCD = mod:NewCDTimer(30, 41476, nil, nil, nil, 3)

local berserkTimer			= mod:NewBerserkTimer(900)

mod:AddSetIconOption("PoisonIcon", 41485)

function mod:OnCombatStart(delay)
	berserkTimer:Start(-delay)
	timerCircleOfHealingCD:Start(-delay)
	timerBlizzardCD:Start(5-delay)
	timerFlamestrikeCD:Start(30-delay)
	timerConsecrationCD:Start(4-delay)
	timerVanishCD:Start(10-delay)
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 41485 then
		warnPoison:Show(args.destName)
		if self.Options.PoisonIcon then
			self:SetIcon(args.destName, 1)
		end
	elseif spellId == 41481 and args:IsPlayer() and self:AntiSpam(3, 1) and not self:IsTrivial() then
		specWarnFlamestrike:Show()
		specWarnFlamestrike:Play("runaway")
	elseif spellId == 41482 and args:IsPlayer() and self:AntiSpam(3, 2) and not self:IsTrivial() then
		specWarnBlizzard:Show()
		specWarnBlizzard:Play("runaway")
	elseif spellId == 41541 and args:IsPlayer() and self:AntiSpam(3, 3) and not self:IsTrivial() then
		specWarnConsecration:Show()
		specWarnConsecration:Play("runaway")
	elseif spellId == 41475 and not self:IsTrivial() then
		specWarnShield:Show(args.destName)
		specWarnShield:Play("stopattack")
		timerShield:Start(args.destName)
	elseif spellId == 41452 and self:GetCIDFromGUID(args.destGUID) == 22949 then
		warnDevAura:Show()
		timerDevAura:Start()
	elseif spellId == 41453 and self:GetCIDFromGUID(args.destGUID) == 22949 then
		warnResAura:Show()
		timerResAura:Start()
	elseif spellId == 41450 and self:GetCIDFromGUID(args.destGUID) == 22951 then
		timerMeleeImmune:Start(args.destName)
		specWarnImmune:Show(L.Melee)
	elseif spellId == 41451 and self:GetCIDFromGUID(args.destGUID) == 22951 then
		timerSpellImmune:Start(args.destName)
		specWarnImmune:Show(L.Spell)
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 41479 then
		warnVanishEnd:Show()
		timerVanishCD:Start()
	elseif spellId == 41485 then
		if self.Options.PoisonIcon then
			-- self:SetIcon(args.destName, 0)
		end
	end
end

function mod:SPELL_CAST_START(args)
	if args.spellId == 41455 then
		timerCircleOfHealingCD:Start()
		if self:CheckInterruptFilter(args.sourceGUID) then
			specWarnCoH:Show(args.sourceName)
			specWarnCoH:Play("kickcast")
		end
	elseif args.spellId == 41481 then
		timerFlamestrikeCD:Start()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args.spellId == 41541 then
		timerConsecrationCD:Start()
	elseif args.spellId == 41476 then
		warnVanish:Show(args.sourceName)
		timerVanish:Start(args.sourceName)
	elseif args.spellId == 41482 then
		timerBlizzardCD:Start()
	end
end
