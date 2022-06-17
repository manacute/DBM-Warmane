local mod	= DBM:NewMod("Chromaggus", "DBM-BWL", 1)
local L		= mod:GetLocalizedStrings()


mod:SetRevision("20220518110528")
mod:SetCreatureID(14020)
mod:SetModelID(14367)
mod:RegisterCombat("combat")

mod:RegisterEvents(
	"SPELL_CAST_START 23308 23310 23313 23315 23187",
	"SPELL_CAST_SUCCESS 23170 22277 22278 22279 22280 22281",
	"SPELL_AURA_APPLIED 23155 23169 23153 23154 23170 23128 23537 28371 28747",
	"SPELL_AURA_REMOVED 23155 23169 23153 23154 23170 23128 28371",
	"UNIT_HEALTH",
	"CHAT_MSG_MONSTER_EMOTE"
)

--(ability.id = 23308 or ability.id = 23313 or ability.id = 23187 or ability.id = 23315 or ability.id = 23310) and type = "begincast"
local warnBreath		= mod:NewAnnounce("WarnBreath", 2, 23316)
local warnRed			= mod:NewTargetAnnounce(23155, 2, nil, false)
local warnGreen			= mod:NewTargetAnnounce(23169, 2, nil, false)
local warnBlue			= mod:NewTargetAnnounce(23153, 2, nil, false)
local warnBlack			= mod:NewTargetAnnounce(23154, 2, nil, false)
local warnBronze		= mod:NewSpellAnnounce(23170, 2)
local warnFrenzy		= mod:NewSpellAnnounce(23128, 3, nil, "Tank|RemoveEnrage|Healer", 5)
local warnFrenzyCC		= mod:NewSpellAnnounce(28371, 3, nil, "Tank|RemoveEnrage|Healer", 5)
local warnPhase2Soon	= mod:NewAnnounce("WarnPhase2Soon")
local warnPhase2		= mod:NewPhaseAnnounce(2)
local warnVuln			= mod:NewAnnounce("Vuln Changed", 1, 22277)

local specWarnBronze	= mod:NewSpecialWarningYou(23170, nil, nil, nil, 1, 8)
local specWarnFrenzy	= mod:NewSpecialWarningDispel(23128, "RemoveEnrage", nil, nil, 1, 6)
local specWarnFrenzyCC	= mod:NewSpecialWarningDispel(28371, "RemoveEnrage", nil, nil, 1, 6) --buggy frenzy spell on CC

local timerBreath		= mod:NewTimer(2, "TimerBreath", 23316, nil, nil, 3)
local timerBreathCD		= mod:NewTimer(60, "TimerBreathCD", 23316, nil, nil, 3)

local timerFrenzy		= mod:NewBuffActiveTimer(8, 23128, nil, "Tank|RemoveEnrage|Healer", 4, 5, nil, DBM_CORE_L.ENRAGE_ICON)
local timerFrenzyCC		= mod:NewBuffActiveTimer(8, 28371, nil, "Tank|RemoveEnrage|Healer", 4, 5, nil, DBM_CORE_L.ENRAGE_ICON) --buggy frenzy spell on CC
local timerVuln			= mod:NewCDTimer(17, 22277, nil, nil)
local timerFrenzyCD		= mod:NewCDTimer(10, 23128, nil, nil)
local timerFrenzyCDCC	= mod:NewCDTimer(10, 28371, nil, nil)


local prewarn_P2
function mod:OnCombatStart()
	warnBreathSoon:Schedule(25)
	timerBreathCD:Start(30, "Breath 1")
	timerBreathCD:Start(60, "Breath 2")
	timerFrenzyCD:Start(15)
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

--function mod:SPELL_CAST_SUCCESS(args)
--	if args:IsSpellID(22276, 22277, 22278, 22279, 22280, 22281) then
--		warnVuln:show()
--	end
--end

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
	elseif args.spellId == 28371 and args:IsDestTypeHostile() then
		if self.Options.SpecWarn23128dispel then
			specWarnFrenzy:Show(args.destName)
			specWarnFrenzy:Play("enrage")
		else
			warnFrenzy:Show()
		end
		timerFrenzy:Start()
		timerFrenzyCD:Start()
	elseif args.spellId == 28371 and args:IsDestTypeHostile() then
		if self.Options.SpecWarn28371dispel then
			specWarnFrenzyCC:Show(args.destName)
			specWarnFrenzyCC:Play("enrage")
		else
			warnFrenzyCC:Show()
		end
		timerFrenzyCC:Start()
		timerFrenzyCDCC:Start()
	elseif args:IsSpellID(23537) and args:IsDestTypeHostile() then
		warnPhase2:Show()
	elseif args:IsSpellID(28747) and args:IsDestTypeHostile() then -- CC uses different enrage
		warnPhase2:Show()
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args.spellId == 23128 and args:IsDestTypeHostile() then
		timerFrenzy:Stop()
	elseif args.spellId == 28371 and args:IsDestTypeHostile() then
		timerFrenzyCC:Stop()
	end
end

function mod:CHAT_MSG_MONSTER_EMOTE(msg)
	if msg == L.VulnEmote then
		warnVuln:Show()
		timerVuln:Start()
	end
end

function mod:UNIT_HEALTH(uId)
	if UnitHealth(uId) / UnitHealthMax(uId) <= 0.25 and self:GetUnitCreatureId(uId) == 14020 and not prewarn_P2 then
		warnPhase2Soon:Show()
		prewarn_P2 = true
	end
end
