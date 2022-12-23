local mod	= DBM:NewMod("Onyxia", "DBM-Onyxia")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20221016121650")
mod:SetCreatureID(10184)

mod:RegisterCombat("combat")

--[[mod:RegisterEvents(
	"CHAT_MSG_MONSTER_YELL"
)]]

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 68958 17086 18351 18564 18576 18584 18596 18609 18617 18435 68970 18431 18500 18392 68926",
	"SPELL_CAST_SUCCESS 68959 68963",
	"SPELL_DAMAGE 68867 69286",
	"CHAT_MSG_MONSTER_YELL",
	"UNIT_DIED",
	"UNIT_HEALTH boss1"
)


local warnBreathNtoS		= mod:NewAnnounce("WarnNtoS", 1, 17086)
local warnBreathStoN		= mod:NewAnnounce("WarnStoN", 1, 18351)
local warnBreathEtoW		= mod:NewAnnounce("WarnEtoW", 1, 18576)
local warnBreathWtoE		= mod:NewAnnounce("WarnWtoE", 1, 18609)
local warnBreathSEtoNW		= mod:NewAnnounce("WarnSEtoNW", 1, 18564)
local warnBreathNWtoSE		= mod:NewAnnounce("WarnNWtoSE", 1, 18584)
local warnBreathSWtoNE		= mod:NewAnnounce("WarnSWtoNE", 1, 18596)
local warnBreathNEtoSW		= mod:NewAnnounce("WarnNEtoSW", 1, 18617)

-- General
local timerAchieve			= mod:NewAchievementTimer(300, 4405)

mod:AddBoolOption("SoundWTF3", false, "sound")

-- Stage One (100% – 65%)
mod:AddTimerLine(DBM_CORE_L.SCENARIO_STAGE:format(1)..": 100% – 65%")
local warnPhase2Soon		= mod:NewPrePhaseAnnounce(2)
local warnWingBuffet		= mod:NewSpellAnnounce(18500, 2, nil, "Tank")

local timerNextFlameBreath	= mod:NewCDTimer(10, 18435, nil, "Tank", 2, 5, nil, nil, true) -- Breath she does on ground in frontal cone. Random between 10-20 second cooldown

-- Stage Two (65% – 40%)
mod:AddTimerLine(DBM_CORE_L.SCENARIO_STAGE:format(2)..": 65% – 40%")
local warnPhase2			= mod:NewPhaseAnnounce(2)
local warnPhase3Soon		= mod:NewPrePhaseAnnounce(3)
local warnFireball			= mod:NewTargetNoFilterAnnounce(18392, 2, nil, false)
local warnWhelpsSoon		= mod:NewSoonAnnounce(17646, 1, 69004)
--local preWarnDeepBreath	 = mod:NewSoonAnnounce(17086, 2)--Experimental, if it is off please let me know.

local yellFireball			= mod:NewYell(18392)
local specWarnBreath		= mod:NewSpecialWarningSpell(18584, nil, nil, nil, 2, 2)
local specWarnAdds			= mod:NewSpecialWarningAdds(68959, "-Healer", nil, nil, 1, 2)
local specWarnBlastNova		= mod:NewSpecialWarningRun(68958, "Melee", nil, nil, 4, 2) -- from Onyxian Lair Guard

local timerBreathCast		= mod:NewCastTimer(8.25, 18584, nil, nil, nil, 3)
local timerNextDeepBreath	= mod:NewCDTimer(35, 18584, nil, nil, nil, 3)--Range from 35-60seconds in between based on where she moves to.
local timerWhelps			= mod:NewNextTimer(90, 17646, nil, nil, nil, 1, 69004)
local timerAchieveWhelps	= mod:NewAchievementTimer(10, 4406)
local timerBigAddCD			= mod:NewNextTimer(44.9, 68959, nil, "-Healer", nil, 1, 10697) -- Ignite Weapon for Onyxian Lair Guard

-- Stage Three (40% – 0%)
mod:AddTimerLine(DBM_CORE_L.SCENARIO_STAGE:format(3)..": 40% – 0%")
local warnPhase3			= mod:NewPhaseAnnounce(3)

local specWarnBellowingRoar	= mod:NewSpecialWarningSpell(18431, nil, nil, nil, 2, 2)
local timerBellowingRoar 	= mod:NewCDTimer(22, 18431, nil, nil, nil, 3)		-- 1st instant, 2nd 15sec, all others 22sec
mod.vb.first_bellowing = true

mod.vb.warned_preP2 = false
mod.vb.warned_preP3 = false
mod.vb.whelpsCount = 0

local function Whelps(self)
	if self:IsInCombat() then
		self.vb.whelpsCount = self.vb.whelpsCount + 1
		timerWhelps:Start()
		warnWhelpsSoon:Schedule(80)
		self:ScheduleMethod(90, "Whelps")
	end
end

function mod:FireballTarget(targetname)
	if not targetname then return end
	warnFireball:Show(targetname)
	if targetname == UnitName("player") then
		yellFireball:Yell()
	end
end

function mod:OnCombatStart(delay)
	self:SetStage(1)
	self.vb.whelpsCount = 0
	self.vb.warned_preP2 = false
	self.vb.warned_preP3 = false
	timerNextFlameBreath:Start(12.1-delay) -- REVIEW! variance? (25N Lordaeron 2022/10/13) - 12.1
	timerAchieve:Start(-delay)
	if self.Options.SoundWTF3 then
		DBM:PlaySoundFile("Interface\\AddOns\\DBM-Onyxia\\sounds\\dps-very-very-slowly.ogg")
		self:Schedule(20, DBM.PlaySoundFile, DBM, "Interface\\AddOns\\DBM-Onyxia\\sounds\\hit-it-like-you-mean-it.ogg")
		self:Schedule(30, DBM.PlaySoundFile, DBM, "Interface\\AddOns\\DBM-Onyxia\\sounds\\now-hit-it-very-hard-and-fast.ogg")
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 68958 then -- Blast Nova (from Onyxian Lair Guard)
		specWarnBlastNova:Show()
	elseif args:IsSpellID(17086, 18351, 18564, 18576) or args:IsSpellID(18584, 18596, 18609, 18617) then	-- 1 ID for each direction
--		specWarnBreath:Show()
		timerBreath:Start()
--		timerNextDeepBreath:Start() 	-- deep breaths are random
		if spellId == 18351 then
			warnBreathStoN:Show()
		elseif spellId == 18576 then
			warnBreathEtoW:Show()
		elseif spellId == 18609 then
			warnBreathWtoE:Show()
		elseif spellId == 18564 then
			warnBreathSEtoNW:Show() 
		elseif spellId == 18584 then
			warnBreathNWtoSE:Show()
		elseif spellId == 18596 then
			warnBreathSWtoNE:Show()
		elseif spellId == 18617 then
			warnBreathNEtoSW:Show()
		elseif spellId == 17086 then
			warnBreathNtoS:Show()
		end
--		preWarnDeepBreath:Schedule(35)              -- Pre-Warn Deep Breath
	elseif args:IsSpellID(18435, 68970) then        -- Flame Breath (Ground phases)
		timerNextFlameBreath:Start()
	elseif spellId == 18431 then
		specWarnBellowingRoar:Show()
		specWarnBellowingRoar:Play("fearsoon")
		if self.vb.first_bellowing then
			timerBellowingRoar:Start(15)
			self.vb.first_bellowing = false
		else
			timerBellowingRoar:Start()
		end
	elseif args:IsSpellID(18500, 69293) then -- Wing Buffet
		warnWingBuffet:Show()
	elseif args:IsSpellID(18392, 68926) then -- Fireball
		self:BossTargetScanner(args.sourceGUID, "FireballTarget", 0.15, 12)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(68959, 68963) then--Ignite Weapon (Onyxian Lair Guard spawn)
		specWarnAdds:Show()
		specWarnAdds:Play("bigmob")
		timerBigAddCD:Start()
	end
end

function mod:SPELL_DAMAGE(_, _, _, destGUID, _, _, spellId)
	if (spellId == 68867 or spellId == 69286) and destGUID == UnitGUID("player") and self.Options.SoundWTF3 then		-- Tail Sweep
		DBM:PlaySoundFile("Interface\\AddOns\\DBM-Onyxia\\sounds\\watch-the-tail.ogg")
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
--	if msg == L.YellPull and not self:IsInCombat() then
--		DBM:StartCombat(self, 0)
	if msg == L.YellP2 or msg:find(L.YellP2) then
		self:SendSync("Phase2")
	elseif msg == L.YellP3 or msg:find(L.YellP3) then
		self:SendSync("Phase3")
	end
end

function mod:UNIT_DIED(args)
	if self:IsInCombat() and args:IsPlayer() and self.Options.SoundWTF3 then
		DBM:PlaySoundFile("Interface\\AddOns\\DBM-Onyxia\\sounds\\thats-a-fucking-fifty-dkp-minus.ogg")
	end
end

function mod:UNIT_HEALTH(uId)
	if self.vb.phase == 1 and not self.vb.warned_preP2 and self:GetUnitCreatureId(uId) == 10184 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.70 then
		self.vb.warned_preP2 = true
		warnPhase2Soon:Show()
	elseif self.vb.phase == 2 and not self.vb.warned_preP3 and self:GetUnitCreatureId(uId) == 10184 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.45 then
		self.vb.warned_preP3 = true
		warnPhase3Soon:Show()
		if self.Options.SoundWTF3 then
			self:Unschedule(DBM.PlaySoundFile, DBM)
		end
	end
end

function mod:OnSync(msg)
	if not self:IsInCombat() then return end
	if msg == "Phase2" then
		self:SetStage(2)
		self.vb.whelpsCount = 0
		warnPhase2:Show()
		timerBigAddCD:Start(20) -- (25N Lordaeron 2022/10/13) - Stage 2/20.0
--		preWarnDeepBreath:Schedule(72)	-- Pre-Warn Deep Breath
		timerNextDeepBreath:Start(75.5) -- Breath-17086. REVIEW! variance? (25N Lordaeron 2022/10/13) - 75.5
		timerAchieveWhelps:Start()
		timerNextFlameBreath:Cancel()
		self:Schedule(5, Whelps, self)
		if self.Options.SoundWTF3 then
			self:Unschedule(DBM.PlaySoundFile, DBM)
			DBM:PlaySoundFile("Interface\\AddOns\\DBM-Onyxia\\sounds\\i-dont-see-enough-dots.ogg")
			self:Schedule(10, DBM.PlaySoundFile, DBM, "Interface\\AddOns\\DBM-Onyxia\\sounds\\throw-more-dots.ogg")
			self:Schedule(17, DBM.PlaySoundFile, DBM, "Interface\\AddOns\\DBM-Onyxia\\sounds\\whelps-left-side-even-side-handle-it.ogg") -- 18
		end
		if self.Options.RangeFrame then
			DBM.RangeCheck:Show(8)
		end
	elseif msg == "Phase3" then
		self:SetStage(3)
		warnPhase3:Show()
		self:Unschedule(Whelps)
		timerWhelps:Stop()
		timerNextDeepBreath:Stop()
		timerBigAddCD:Stop()
		warnWhelpsSoon:Cancel()
--		preWarnDeepBreath:Cancel()
		if self.Options.SoundWTF3 then
			self:Unschedule(DBM.PlaySoundFile, DBM)
			self:Schedule(15, DBM.PlaySoundFile, DBM, "Interface\\AddOns\\DBM-Onyxia\\sounds\\dps-very-very-slowly.ogg")
			self:Schedule(35, DBM.PlaySoundFile, DBM, "Interface\\AddOns\\DBM-Onyxia\\sounds\\hit-it-like-you-mean-it.ogg")
			self:Schedule(45, DBM.PlaySoundFile, DBM, "Interface\\AddOns\\DBM-Onyxia\\sounds\\now-hit-it-very-hard-and-fast.ogg")
		end
		if self.Options.RangeFrame then
			DBM.RangeCheck:Hide()
		end
	end
end