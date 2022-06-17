local mod	= DBM:NewMod("Majordomo", "DBM-MC", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20220518110528")
mod:SetCreatureID(12018, 11663, 11664)

mod:SetModelID(12018)

mod:RegisterCombat("combat")
--mod:RegisterKill("yell", L.Kill)

mod:RegisterEventsInCombat(
	"SPELL_CAST_SUCCESS 20619 21075 20534 20618"
)

--[[
(ability.id = 20619 or ability.id = 21075 or ability.id = 20534) and type = "cast"		20618, 20534
--]]
local warnTeleport			= mod:NewTargetNoFilterAnnounce(20534)
local warnTeleportRandom	= mod:NewTargetNoFilterAnnounce(20618)
local warnDamageShield		= mod:NewSpellAnnounce(21075, 2)

local specWarnMagicReflect	= mod:NewSpecialWarningReflect(20619, "CasterDps", nil, 2, 1, 2)
local specWarnDamageShield	= mod:NewSpecialWarningReflect(21075, false, nil, 2, 1, 2)

local timerMagicReflect		= mod:NewBuffActiveTimer(10, 20619, nil, nil, nil, 5, nil, DBM_CORE_L.DAMAGE_ICON)
local timerDamageShield		= mod:NewBuffActiveTimer(10, 21075, nil, nil, nil, 5, nil, DBM_CORE_L.DAMAGE_ICON)
local timerTeleportCD		= mod:NewCDTimer(30, 20534, nil, nil, nil, 5, nil, DBM_CORE_L.TANK_ICON)
local timerTeleportRandomCD = mod:NewCDTimer(30, 20618, nil, nil, nil, 5, nil, DBM_CORE_L.TANK_ICON)
local timerShieldCD			= mod:NewTimer(30, "timerShieldCD", nil, nil, nil, 6, nil, DBM_CORE_L.DAMAGE_ICON)


function mod:OnCombatStart(delay)
	timerTeleportCD:Start(15-delay)
	timerTeleportRandomCD:Start(25-delay)
	timerShieldCD:Start(30-delay)
end

function mod:SPELL_CAST_SUCCESS(args)
	if args.spellId == 20619 then
		specWarnMagicReflect:Show(BOSS)--Always a threat to casters
		specWarnMagicReflect:Play("stopattack")
		timerMagicReflect:Start()
		timerShieldCD:Start()
	elseif args.spellId == 21075 then
		if self.Options.SpecWarn21075reflect and not self:IsTrivial() then--Not a threat to high level melee
			specWarnDamageShield:Show(BOSS)
			specWarnDamageShield:Play("stopattack")
		else
			warnDamageShield:Show()
		end
		timerDamageShield:Start()
		timerShieldCD:Start()
	elseif args.spellId == 20534 then
		warnTeleport:Show(args.destName)
		timerTeleportCD:Start()
	elseif args.spellId == 20618 then
		warnTeleportRandom:Show(args.destName)
		timerTeleportRandomCD:Start()
	end
end