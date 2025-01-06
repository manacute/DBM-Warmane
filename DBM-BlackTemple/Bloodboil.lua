local mod	= DBM:NewMod("Bloodboil", "DBM-BlackTemple")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20230108171130")
mod:SetCreatureID(22948)
mod:SetModelID(21443)
mod:SetHotfixNoticeRev(20230108000000)
mod:SetMinSyncRevision(20230108000000)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 40508",
	"SPELL_CAST_SUCCESS 42005 40491",
	"SPELL_AURA_APPLIED 42005 40481 40491 40604 40594",
	"SPELL_AURA_APPLIED_DOSE 42005 40481",
	-- "SPELL_AURA_REFRESH 42005 40481",
	"SPELL_AURA_REMOVED 40604 40594"
)

-- General
local berserkTimer		= mod:NewBerserkTimer(600)

-- Stage One: Boiling Blood
mod:AddTimerLine(DBM_CORE_L.SCENARIO_STAGE:format(1)..": "..DBM:GetSpellInfo(38027))
local warnBlood			= mod:NewTargetAnnounce(42005, 3)
local warnWound			= mod:NewStackAnnounce(40481, 2, nil, "Tank", 2)
local warnStrike		= mod:NewTargetNoFilterAnnounce(40491, 3, nil, "Tank", 2)

local specWarnBlood		= mod:NewSpecialWarningStack(42005, nil, 1, nil, nil, 1, 2)

local timerBloodCD		= mod:NewCDCountTimer(10, 42005, nil, nil, nil, 5, nil, DBM_COMMON_L.IMPORTANT_ICON)
local timerStrikeCD		= mod:NewCDCountTimer(30, 40491, nil, "Tank", 2, 5, nil, DBM_COMMON_L.TANK_ICON)
local timerBreathCD   = mod:NewCDTimer(30, 40508, nil, nil, nil, 2)

-- Stage Two: Fel Rage
mod:AddTimerLine(DBM_CORE_L.SCENARIO_STAGE:format(2)..": "..DBM:GetSpellInfo(40594))
local warnRage			= mod:NewTargetAnnounce(40604, 4)
local warnRageSoon		= mod:NewSoonAnnounce(40604, 3)
local warnRageEnd		= mod:NewEndAnnounce(40604, 4)
local warnBreath		= mod:NewSpellAnnounce(40508, 2)

local specWarnRage		= mod:NewSpecialWarningYou(40604, nil, nil, nil, 1, 2)
local yellRage			= mod:NewYell(40604)

local timerRageCD		= mod:NewCDTimer(60, 40604, nil, nil, nil, 3, nil, DBM_COMMON_L.IMPORTANT_ICON)
local timerRageEnd		= mod:NewBuffActiveTimer(30, 40604, nil, nil, nil, 5, nil, DBM_COMMON_L.HEALER_ICON)

mod:AddInfoFrameOption(42005)

mod.vb.bloodCount = 1
mod.vb.strikeCount = 1

function mod:OnCombatStart(delay)
	self:SetStage(1)
	self.vb.bloodCount = 1
	self.vb.strikeCount = 1

	berserkTimer:Start(-delay)
	warnRageSoon:Schedule(55-delay)
  
	timerBloodCD:Start(-delay, 1)
	timerStrikeCD:Start(28-delay, 1)
	timerRageCD:Start(-delay)
	
  if self.Options.InfoFrame then
		DBM.InfoFrame:SetHeader(DBM:GetSpellInfo(42005))
		DBM.InfoFrame:Show(30, "playerdebuffstacks", 42005, 1)
	end
end

function mod:OnCombatEnd()
	if self.Options.InfoFrame then
		DBM.InfoFrame:Hide()
	end
end

function mod:SPELL_CAST_START(args)
	if args.spellId == 40508 then
		warnBreath:Show()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 42005 then
		if self.vb.bloodCount == 5 then
      self.vb.bloodCount = 1
		else
      self.vb.bloodCount = self.vb.bloodCount + 1
			timerBloodCD:Start(nil, self.vb.bloodCount)
		end
	elseif spellId == 40491 then
		if self.vb.strikeCount == 3 then
			self.vb.strikeCount = 1
		else
      self.vb.strikeCount = self.vb.strikeCount + 1
			timerStrikeCD:Start(nil, self.vb.strikeCount)
		end
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 42005 then
		warnBlood:CombinedShow(0.8, args.destName)
		if args:IsPlayer() then
      local stacks = args.amount or 1
			specWarnBlood:Show(stacks)
			specWarnBlood:Play("targetyou")
		end
	elseif spellId == 40481 then
		local stacks = args.amount or 1
		if (stacks % 5 == 0) then
			warnWound:Show(args.destName, stacks)
		end
	elseif spellId == 40491 then
		warnStrike:Show(args.destName)
	elseif spellId == 40594 then -- Fel Rage (boss)
		-- timerRageEnd:Start(28, args.destName)
	elseif spellId == 40604 then -- Fel Rage (player)
		self:SetStage(2)
		timerRageEnd:Start(args.destName)

		if args:IsPlayer() then
			specWarnRage:Show()
			specWarnRage:Play("targetyou")
			yellRage:Yell()
		else
			warnRage:Show(args.destName)
		end
	end
end

mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED
mod.SPELL_AURA_REFRESH = mod.SPELL_AURA_APPLIED

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 40604 then -- Ending on player
    warnRageEnd:Show()

    self.vb.bloodCount = 0
    self:SetStage(1)
    
    timerBloodCD:Start(nil, 1)
    timerStrikeCD:Start(nil, 1)
    
    warnRageSoon:Schedule(55)
    timerRageCD:Start()
	elseif spellId == 40594 then -- Ending on Boss
    -- warnRageEnd:Show()
	end
end
