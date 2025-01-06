local mod	= DBM:NewMod("Supremus", "DBM-BlackTemple")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20230108174447")
mod:SetCreatureID(22898)
mod:SetModelID(21145)
mod:SetUsedIcons(8)
mod:SetHotfixNoticeRev(20230108000000)
mod:SetMinSyncRevision(20230108000000)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_SUCCESS 41581",
	"CHAT_MSG_RAID_BOSS_EMOTE"
)

--TODO, see if CLEU method is reliable enough to scrap scan method. scan method may still have been faster.

-- General
local warnPhase			= mod:NewAnnounce("WarnPhase", 4, 42052)

local timerPhase		= mod:NewTimer(60, "TimerPhase", 42052, nil, nil, 6)
local berserkTimer		= mod:NewBerserkTimer(900)

-- Stage One: Supremus
mod:AddTimerLine(DBM_CORE_L.SCENARIO_STAGE:format(1)..": "..L.name)
local specWarnMolten	= mod:NewSpecialWarningMove(40265, nil, nil, nil, 1, 2)

-- Stage Two: Pursuit
mod:AddTimerLine(DBM_CORE_L.SCENARIO_STAGE:format(2)..": "..DBM:GetSpellInfo(68987))
local warnFixate		= mod:NewTargetNoFilterAnnounce(41295, 3)

local specWarnVolcano	= mod:NewSpecialWarningMove(42052, nil, nil, nil, 1, 2)
local specWarnFixate	= mod:NewSpecialWarningRun(41295, nil, nil, nil, 4, 2)

mod:AddBoolOption("KiteIcon", true)

mod.vb.lastTarget = "None"

function mod:OnCombatStart(delay)
	self:SetStage(1)
	berserkTimer:Start(-delay)
	timerPhase:Start(-delay, L.Kite)
	self.vb.lastTarget = "None"
	if not self:IsTrivial() then--Only warning that uses these events is remorseless winter and that warning is completely useless spam for level 90s.
		self:RegisterShortTermEvents(
			"SPELL_DAMAGE 40265 42052",
			"SPELL_MISSED 40265 42052"
		)
	end
end

function mod:OnCombatEnd()
	self:UnregisterShortTermEvents()
	if self.vb.lastTarget ~= "None" then
		self:SetIcon(self.vb.lastTarget, 0)
	end
end

function mod:SPELL_DAMAGE(_, _, _, destGUID, _, _, spellId)
	if spellId == 40265 and destGUID == UnitGUID("player") and self:AntiSpam(4, 1) and not self:IsTrivial() then
		specWarnMolten:Show()
		specWarnMolten:Play("runaway")
	elseif spellId == 42052 and destGUID == UnitGUID("player") and self:AntiSpam(4, 2) and not self:IsTrivial() then
		specWarnVolcano:Show()
		specWarnVolcano:Play("runaway")
	end
end
mod.SPELL_MISSED = mod.SPELL_DAMAGE

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 41581 then
		self.vb.lastTarget = target
		if args:IsPlayer() then
			specWarnFixate:Show()
			specWarnFixate:Play("justrun")
			specWarnFixate:ScheduleVoice(1, "keepmove")
		else
			warnFixate:Show(target)
		end
		if self.Options.KiteIcon then
			self:SetIcon(target, 8)
		end
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg)
	if msg == L.PhaseKite or msg:find(L.PhaseKite) then
		if self.vb.phase == 1 then
			self:SetStage(2)
			warnPhase:Show(L.Kite)
			timerPhase:Start(L.Tank)
		end
	elseif msg == L.PhaseTank or msg:find(L.PhaseTank) then
		self:SetStage(1)
		warnPhase:Show(L.Tank)
		timerPhase:Start(L.Kite)
	end
end
