local mod	= DBM:NewMod("Shahraz", "DBM-BlackTemple")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20220518110528")
mod:SetCreatureID(22947)

mod:SetModelID(21252)
mod:SetUsedIcons(1, 2, 3)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"CHAT_MSG_RAID_BOSS_EMOTE",
	"SPELL_AURA_APPLIED 41001",
	"SPELL_AURA_REMOVED 41001",
	"SPELL_CAST_SUCCESS 40823",
	"UNIT_SPELLCAST_SUCCEEDED"
)

--TODO, announce auras?
local warnFA			= mod:NewTargetNoFilterAnnounce(41001, 4)
local warnShriek		= mod:NewSpellAnnounce(40823)
local warnEnrageSoon	= mod:NewSoonAnnounce(21340) --not actual spell id
local warnEnrage		= mod:NewSpellAnnounce(21340)

local specWarnFA		= mod:NewSpecialWarningMoveAway(41001, nil, nil, nil, 1, 2)

local timerFatalAttractionCD = mod:NewCDTimer(60, 41001, nil, nil, nil, 3)
local timerAura			= mod:NewTimer(15, "timerAura", 22599)
local timerShriekCD		= mod:NewCDTimer(30, 40823, nil, nil, nil, 2)

mod:AddSetIconOption("FAIcons", 41001, true)

mod.vb.prewarn_enrage = false
mod.vb.enrage = false

local GetSpellInfo = GetSpellInfo
local aura = {
	[GetSpellInfo(40880)] = true,
	[GetSpellInfo(40882)] = true,
	[GetSpellInfo(40883)] = true,
	[GetSpellInfo(40891)] = true,
	[GetSpellInfo(40896)] = true,
	[GetSpellInfo(40897)] = true
}

function mod:OnCombatStart(delay)
	self.vb.prewarn_enrage = false
	self.vb.enrage = false
	timerShriekCD:Start(-delay)
	timerFatalAttractionCD:Start(50-delay)
	if not self:IsTrivial() then
		self:RegisterShortTermEvents(
			"UNIT_HEALTH boss1"
		)
	end
end

function mod:OnCombatEnd()
	self:UnregisterShortTermEvents()
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 41001 then
		warnFA:CombinedShow(1, args.destName)
		if args:IsPlayer() then
			specWarnFA:Show()
			specWarnFA:Play("scatter")
		end
		if self.Options.FAIcons then
			self:SetIcon(args.destName, 1)
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args.spellId == 41001 and self.Options.FAIcons then
		self:SetIcon(args.destName, 0)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args.spellId == 40823 then
		warnShriek:Show()
		timerShriekCD:Start()
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(_, source)
	if not self.vb.enrage and (source or "") == L.name then
		self.vb.enrage = true
		warnEnrage:Show()
	end
end

function mod:UNIT_HEALTH(uId)
	if UnitHealth(uId) / UnitHealthMax(uId) <= 0.23 and self:GetUnitCreatureId(uId) == 22947 and not self.vb.prewarn_enrage then
		self:UnregisterShortTermEvents()
		self.vb.prewarn_enrage = true
		warnEnrageSoon:Show()
	end
end

function mod:UNIT_SPELLCAST_SUCCEEDED(_, spellName)
	if self:AntiSpam(3, spellName) then
		if aura[spellName] then
			timerAura:Start(spellName)
		elseif spellName == GetSpellInfo(40869) then
			timerFatalAttractionCD:Start()
		end
	end
end

function mod:OnSync(msg)
	if msg == "fatalAttraction" then
		timerFatalAttractionCD:Start()
	end
end
