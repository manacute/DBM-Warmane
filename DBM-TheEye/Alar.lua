local mod	= DBM:NewMod("Alar", "DBM-TheEye")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20220518110528")
mod:SetCreatureID(19514)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 34229 35383 35410",
	"SPELL_AURA_REMOVED 35410",
	"SPELL_CAST_START 34342 35369",
	"SPELL_CAST_SUCCESS 35181",
	"SPELL_HEAL 34342"
)

local warnPhase2		= mod:NewPhaseAnnounce(2, 2)
local warnArmor			= mod:NewTargetAnnounce(35410, 2)
local warnMeteor		= mod:NewSpellAnnounce(35181, 3)

local specWarnQuill		= mod:NewSpecialWarningDodge(34229, nil, nil, nil, 2, 2)
local specWarnFire		= mod:NewSpecialWarningMove(35383, nil, nil, nil, 1, 2)
local specWarnArmor		= mod:NewSpecialWarningTaunt(35410, nil, nil, nil, 1, 2)

local timerQuill		= mod:NewCastTimer(10, 34229, nil, nil, nil, 3)
local timerMeteor		= mod:NewCDTimer(50, 35181, nil, nil, nil, 2)
local timerArmor		= mod:NewTargetTimer(60, 35410, nil, "Tank", 2, 5, nil, DBM_COMMON_L.TANK_ICON)
local timerNextPlatform	= mod:NewTimer(30, "NextPlatform", 40192, nil, nil, 6)--This has no spell trigger, the target scanning bosses target is still required if loop isn't accurate enough.

local berserkTimer		= mod:NewBerserkTimer(600)

local buffetName = DBM:GetSpellInfo(34121)
local UnitName = UnitName

--Loop doesn't work do to varying travel time between platforms. We just need to do target scanning and start next platform timer when Al'ar reaches a platform and starts targeting player again
--Still semi inaccurate. Sometimes Al'ar changes platforms 5-8 seconds early with no explanation. I have a feeling it's just tied to Al'ars behavior being buggy with one person.
--I don't remember code being faulty when you actually had 4 people up there.
local function Platform(self)--An attempt to avoid ugly target scanning, but i get feeling this won't be accurate enough.
	timerNextPlatform:Start()
	self:Schedule(30, Platform, self)
end

local function Add(self)--An attempt to avoid ugly target scanning, but i get feeling this won't be accurate enough.
	timerNextPlatform:Cancel()
	timerNextPlatform:Start(7)
	self:Schedule(7, Platform, self)
end

function mod:OnCombatStart(delay)
	self:AntiSpam(30, 1)--Prevent it thinking add spawn on pull and messing up first platform timer
	self:SetStage(1)
	
	timerNextPlatform:Start(30-delay)
	self:Schedule(30-delay, Platform, self)
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 34229 then
		specWarnQuill:Show()
		specWarnQuill:Play("findshelter")
		timerQuill:Start()
		
		timerNextPlatform:Cancel()
		self:Unschedule(Platform)
		self:Schedule(30, Platform, self)
	elseif args.spellId == 35383 and args:IsPlayer() and self:AntiSpam(3, 1) then
		specWarnFire:Show()
		specWarnFire:Play("runaway")
	elseif args.spellId == 35410 then
		warnArmor:Show(args.destName)
		if not args:IsPlayer() then
			specWarnArmor:Show(args.destName)
			specWarnArmor:Play("tauntboss")
		end
		timerArmor:Start(args.destName)
	end
end

function mod:SPELL_CAST_START(args)
	if args.spellId == 34342 then
		timerNextPlatform:Cancel()
		self:Unschedule(Platform)
	
		self:SetStage(2)
		warnPhase2:Show()
		berserkTimer:Start()
		timerMeteor:Start(60)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args.spellId == 35181 then
		warnMeteor:Show()
		timerMeteor:Start()
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args.spellId == 35410 then
		timerArmor:Cancel(args.destName)
	end
end
