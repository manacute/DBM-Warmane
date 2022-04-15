local mod	= DBM:NewMod("Chromaggus", "DBM-BWL", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 188 $"):sub(12, -3))
mod:SetCreatureID(14020)
mod:RegisterCombat("combat")

mod:RegisterEvents(
	"SPELL_CAST_START 23308 23310 23313 23315 23187",
	"SPELL_CAST_SUCCESS 23170 22277 22278 22279 22280 22281",
	"SPELL_AURA_APPLIED",
	"SPELL_AURA_REMOVED",
	"UNIT_HEALTH",
	"CHAT_MSG_MONSTER_EMOTE"
)

local warnBreathSoon	= mod:NewAnnounce("WarnBreathSoon", 1, 23316)
local warnBreath		= mod:NewAnnounce("WarnBreath", 2, 23316)
local warnRed			= mod:NewTargetAnnounce(23155, 2, nil, false)
local warnGreen			= mod:NewTargetAnnounce(23169, 2, nil, false)
local warnBlue			= mod:NewTargetAnnounce(23153, 2, nil, false)
local warnBlack			= mod:NewTargetAnnounce(23154, 2, nil, false)
local warnBronze		= mod:NewSpellAnnounce(23170, 2)
local warnFrenzy		= mod:NewSpellAnnounce(23128, 3, nil, "Tank|RemoveEnrage|Healer", 5)
local warnPhase2Soon	= mod:NewAnnounce("WarnPhase2Soon")
local warnPhase2		= mod:NewPhaseAnnounce(2)
local warnVuln			= mod:NewAnnounce("Vuln Changed", 1, 22277)

local specWarnBronze	= mod:NewSpecialWarningYou(23170)
local specWarnFrenzy	= mod:NewSpecialWarningDispel(23128, "RemoveEnrage", nil, nil, 1, 6)

local timerBreath		= mod:NewTimer(2, "TimerBreath")
local timerBreathCD		= mod:NewTimer(60, "TimerBreathCD")
local timerFrenzy		= mod:mod:NewBuffActiveTimer(8, 23128, nil, "Tank|RemoveEnrage|Healer", 4, 5, nil, DBM_CORE_L.TANK_ICON..DBM_CORE_L.ENRAGE_ICON)
local timerVulnChange	= mod:NewCDTimer(45, 22277, nil, nil)

local prewarn_P2

function mod:OnCombatStart(delay)
	warnBreathSoon:Schedule(25-delay)
	timerBreathCD:Start(30-delay, "Breath 1")
	timerBreathCD:Start(60-delay, "Breath 2")
	prewarn_P2 = false;
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(23308, 23310, 23313, 23315, 23187) then
		warnBreath:Show(args.spellName)
		timerBreath:Start(2, args.spellName)
		timerBreath:UpdateIcon(args.spellId)
		timerBreathCD:Start(60, args.spellName)
		timerBreathCD:UpdateIcon(args.spellId)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(23170) then
		warnBronze:Show()
--	elseif args:IsSpellID(22276, 22277, 22278, 22279, 22280, 22281) then
--		warnVuln:show()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(23155) then
		warnRed:Show(args.destName)
	elseif args:IsSpellID(23169) then
		warnGreen:Show(args.destName)
	elseif args:IsSpellID(23153) then
		warnBlue:Show(args.destName)
	elseif args:IsSpellID(23154) then
		warnBlack:Show(args.destName)
	elseif args:IsSpellID(23170) then
		warnBronze:Show()
		if args:IsPlayer() then
			specWarnBronze:Show()
		end
	elseif args.spellId == 23128 and args:IsDestTypeHostile() then
		if self.Options.SpecWarn23128dispel then
			specWarnFrenzy:Show(args.destName)
			specWarnFrenzy:Play("enrage")
		else
			warnFrenzy:Show()
		end
		timerFrenzy:Start()
	elseif args:IsSpellID(23537) then
		warnPhase2:Show()
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args.spellId == 23128 and args:IsDestTypeHostile() then
		timerFrenzy:Stop()
	end
end

function mod:CHAT_MSG_MONSTER_EMOTE(msg)
	if msg == L.VulnEmote then
		warnVuln:Show()
		timerVulnChange:Start()
	end
end

function mod:UNIT_HEALTH(uId)
	if UnitHealth(uId) / UnitHealthMax(uId) <= 0.25 and self:GetUnitCreatureId(uId) == 14020 and not prewarn_P2 then
		warnPhase2Soon:Show()
		prewarn_P2 = true
	end
end
