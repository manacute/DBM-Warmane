local mod	= DBM:NewMod("Patchwerk", "DBM-Naxx", 2)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20220518110528")
mod:SetCreatureID(16028)
--mod:RegisterCombat("combat_yell", L.yell1, L.yell2)
mod:RegisterCombat("yell", L.yell1, L.yell2)

mod:RegisterEventsInCombat(
	"SPELL_DAMAGE 28308 59192",
	"SPELL_MISSED 28308 59192"
)

local enrageTimer	= mod:NewBerserkTimer(360)
local timerAchieve	= mod:NewAchievementTimer(180, 1857)

mod:AddBoolOption("WarningHateful", false, "announce")

local function announceStrike(target, damage)
	SendChatMessage(L.HatefulStrike:format(target, damage), "RAID")
end

function mod:OnCombatStart(delay)
	enrageTimer:Start(-delay)
	timerAchieve:Start(-delay)
end

function mod:SPELL_DAMAGE(_, _, _, _, destName, _, spellId, _, _, amount)
	if (spellId == 28308 or spellId == 59192) and self.Options.WarningHateful and DBM:GetRaidRank() >= 1 then
		announceStrike(destName, amount or 0)
	end
end

function mod:SPELL_MISSED(_, _, _, _, destName, _, spellId, _, _, missType)
	if (spellId == 28308 or spellId == 59192) and self.Options.WarningHateful and DBM:GetRaidRank() >= 1 then
		announceStrike(destName, getglobal("ACTION_SPELL_MISSED_"..(missType)) or "")
	end
end