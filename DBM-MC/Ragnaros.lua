local mod	= DBM:NewMod("Ragnaros-Classic", "DBM-MC", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20231224101919")
mod:SetCreatureID(11502)
mod:SetModelID(11121)
mod:SetHotfixNoticeRev(20231219000000)--2023, 12, 19

mod:RegisterCombat("combat")

mod:RegisterEvents(
	"SPELL_CAST_START 19774 20568",
	"SPELL_CAST_SUCCESS 20566 19773",
	"CHAT_MSG_MONSTER_YELL"
)
mod:RegisterEventsInCombat( -- 2023/12/19: Cannot have already registered events, or it will fire in duplicate
--	"SPELL_CAST_START 20568",
--	"SPELL_CAST_SUCCESS 20566",
	"UNIT_DIED"
)

--[[
ability.id = 20566 and type = "cast" or target.id = 12143 and type = "death"
--]]
local warnWrathRag			= mod:NewSpellAnnounce(20566, 3)
local warnSubmerge			= mod:NewSpellAnnounce(21107, 2, "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendBurrow.blp")
local warnEmerge			= mod:NewSpellAnnounce(20568, 2, "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendUnBurrow.blp")
local warnSonsOfFlameLeft	= mod:NewAddsLeftAnnounce(19629, 2, 19774) -- spellId 21108 (Summon of Sons of Flame) returns nil, so use a similar spellId: 19629 (Summon Flames)

local timerWrathRag		= mod:NewCDTimer(25, 20566, nil, nil, nil, 2, nil, DBM_COMMON_L.IMPORTANT_ICON, nil, mod:IsMelee() and 1, 4)--25-31.6
local timerSubmerge		= mod:NewTimer(180, "TimerSubmerge", "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendBurrow.blp", nil, nil, 6, nil, nil, 1, 5)
local timerEmerge		= mod:NewTimer(90, "TimerEmerge", "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendUnBurrow.blp", nil, nil, 6, nil, nil, 1, 5)
local timerCombatStart	= mod:NewTimer(72.75, "timerCombatStart", "Interface\\Icons\\Ability_Warrior_OffensiveStance", nil, nil, nil, nil, nil, 1, 3)

mod:AddRangeFrameOption("18", nil, "-Melee")

mod.vb.addLeft = 0
--mod.vb.ragnarosEmerged = true
--local addsGuidCheck = {}
local firstBossMod = DBM:GetModByName("MCTrash")

function mod:OnCombatStart(delay)
--	table.wipe(addsGuidCheck)
	self.vb.addLeft = 0
--	self.vb.ragnarosEmerged = true
	timerWrathRag:Start(30-delay)
	timerSubmerge:Start(180-delay) -- (40N Lordaeron [2023-09-13]@[19:05:07]) - 180
	if self.Options.RangeFrame then
		DBM.RangeCheck:Show(18)
	end
end

function mod:OnCombatEnd(wipe)
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
	if not wipe then
		DBT:CancelBar(DBM_CORE_L.SPEED_CLEAR_TIMER_TEXT)
		if firstBossMod.vb.firstEngageTime then
			local thisTime = time() - firstBossMod.vb.firstEngageTime
			if thisTime and thisTime > 0 then
				if not firstBossMod.Options.FastestClear2 then
					--First clear, just show current clear time
					DBM:AddMsg(DBM_CORE_L.RAID_DOWN:format("MC", DBM:strFromTime(thisTime)))
					firstBossMod.Options.FastestClear2 = thisTime
				elseif (firstBossMod.Options.FastestClear2 > thisTime) then
					--Update record time if this clear shorter than current saved record time and show users new time, compared to old time
					DBM:AddMsg(DBM_CORE_L.RAID_DOWN_NR:format("MC", DBM:strFromTime(thisTime), DBM:strFromTime(firstBossMod.Options.FastestClear2)))
					firstBossMod.Options.FastestClear2 = thisTime
				else
					--Just show this clear time, and current record time (that you did NOT beat)
					DBM:AddMsg(DBM_CORE_L.RAID_DOWN_L:format("MC", DBM:strFromTime(thisTime), DBM:strFromTime(firstBossMod.Options.FastestClear2)))
				end
			end
			firstBossMod.vb.firstEngageTime = nil
		end
	end
end

local function emerged(self)
	self.vb.ragnarosEmerged = true
	timerEmerge:Stop()
	warnEmerge:Show()
	timerWrathRag:Start(30)
	timerSubmerge:Start(180)
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 19774 and self:AntiSpam(5, 4) then
		--This is still going to use a sync event because someone might start this RP from REALLY REALLY far away
		self:SendSync("SummonRag")
	elseif spellId == 20568 and self:IsInCombat() then -- Ragnaros Emerge ; needs boss engage check since Emerge will fire during his RP pre-IEEU script, and this was a regression after RegisterEventsInCombat was switched to RegisterEvents.
		DBM:AddSpecialEventToTranscriptorLog("Emerged")
--		self.vb.ragnarosEmerged = true
		timerEmerge:Stop()
		warnEmerge:Show()
		timerWrathRag:Start(30) -- (40N Lordaeron [2023-09-13]@[19:05:07] || ) - 2222.61 > 2252.60 [29.99] || "Wrath of Ragnaros-20566-npc:11502-130 = pull:29.94, 22.16, 29.66, 28.36, 20.09, 24.10, Submerged/25.63, Emerged/89.99, Emerged/0.00, 30.08/30.08/120.06/145.69"
		-- Don't start Submerge timer here, since Ragnaros will emerge after 90 seconds from Submerge/Summon Sons of Flames OR once all 8 are defeated (whichever happens first). The latter is variable and therefore not suitable for any timer
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 20566 then
		warnWrathRag:Show()
		timerWrathRag:Start()
	elseif spellId == 19773 then
		--This is still going to use a sync event because someone might start this RP from REALLY REALLY far away
		self:SendSync("DomoDeath")
	end
end

function mod:UNIT_DIED(args)
	local guid = args.destGUID
	if self:GetCIDFromGUID(guid) == 12143 then--Son of Flame
		--self:SendSync("AddDied", guid)--Send sync it died do to combat log range and size of room
		--We're in range of event, no reason to wait for sync, especially in a raid that might not have many DBM users
--		if not addsGuidCheck[guid] then
--			addsGuidCheck[guid] = true
			self.vb.addLeft = self.vb.addLeft - 1
--			if not self.vb.ragnarosEmerged and self.vb.addLeft == 0 then--After all 8 die he emerges immediately
--				self:Unschedule(emerged)
--				emerged(self)
--			end
--		end
		warnSonsOfFlameLeft:Show(self.vb.addLeft)
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.Submerge or msg == L.Submerge2 then
		self:SendSync("Submerge")
	elseif msg == L.Pull and self:AntiSpam(5, 4) then
		self:SendSync("SummonRag")
	end
end

function mod:OnSync(msg--[[, guid]])
	if msg == "SummonRag" and self:AntiSpam(5, 2) then
		timerCombatStart:Start()
	elseif msg == "Submerge" and self:IsInCombat() then
		DBM:AddSpecialEventToTranscriptorLog("Submerged")
--		self.vb.ragnarosEmerged = false
--		self:Unschedule(emerged)
		timerWrathRag:Stop()
		timerSubmerge:Stop()
		warnSubmerge:Show()
		timerEmerge:Start(90)
		timerSubmerge:Start() -- Submerge Yells diff (40N Lordaeron [2023-09-13]@[19:05:07]) - 2209.92 > 2389.91 [179.99]
--		self:Schedule(90, emerged, self)
		self.vb.addLeft = self.vb.addLeft + 8
	--[[elseif msg == "AddDied" and self:IsInCombat() and guid and not addsGuidCheck[guid] then
		--A unit died we didn't detect ourselves, so we correct our adds counter from sync
		addsGuidCheck[guid] = true
		self.vb.addLeft = self.vb.addLeft - 1
		if not self.vb.ragnarosEmerged and self.vb.addLeft == 0 then--After all 8 die he emerges immediately
			self:Unschedule(emerged)
			emerged(self)
		end--]]
	elseif msg == "DomoDeath" and self:AntiSpam(5, 3) then
		--The timer between yell/summon start and ragnaros being attackable is variable, but time between domo death and him being attackable is not.
		--As such, we start lowest timer of that variation on the RP start, but adjust timer if it's less than 10 seconds at time domo dies
		local remaining = timerCombatStart:GetRemaining()
		if remaining then
			if remaining < 10 then
				timerCombatStart:AddTime(10 - remaining)
			elseif remaining > 10 then
				timerCombatStart:RemoveTime(remaining - 10)
			end
		end
	end
end
