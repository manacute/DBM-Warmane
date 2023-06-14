local mod	= DBM:NewMod(523, "DBM-Party-BC", 7, 247)

mod:SetRevision("20220518110528")
mod:SetCreatureID(18371)

mod:SetModelID(18916)
mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_SUCCESS 32265 32300 36383",
	"CHAT_MSG_RAID_BOSS_EMOTE"
)

local warnFocusFire			= mod:NewTargetAnnounce(32300, 3)

local timerAttractMagicCD 	= mod:NewCDTimer(30, 32265, nil, nil)
local timerFocusFireCD 		= mod:NewCDTimer(15, 32300, nil, false)
local timerBiteCD 			= mod:NewCDTimer(10, 36383, nil, nil)

local specWarnFocusFire		= mod:NewSpecialWarningDodge(32300, nil, nil, nil, 4, 2)

function mod:OnCombatStart(delay)
	timerAttractMagicCD:Start(28 - delay)
	timerFocusFireCD:Start(17 - delay)
	timerBiteCD:Start(10 - delay)
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(32265) then
		timerAttractMagicCD:Start()		
	elseif args:IsSpellID(36383) then
		timerBiteCD:Start()
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(_, _, _, _, target)
	local targetname = DBM:GetUnitFullName(target) or target
	timerFocusFireCD:Start()
	if targetname == UnitName("player") then
		specWarnFocusFire:Show()
		specWarnFocusFire:Play("watchstep")
	else
		warnFocusFire:Show(target)
	end
end
