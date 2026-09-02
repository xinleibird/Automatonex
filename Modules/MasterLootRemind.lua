assert(Automaton, "Automaton not found!")

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_MasterLootRemind = Automaton:NewModule("MasterLootRemind")
local self = Automaton_MasterLootRemind

local DF = AceLibrary("Deformat-2.0")
local BB = AceLibrary("Babble-Boss-2.2")
local parser = ParserLib:GetInstance("1.1")

Automaton_MasterLootRemind.modulename = "队长拾取提醒"
Automaton_MasterLootRemind.moduledesc =
	"检测到首领时自动设置队长拾取，并在拾取后恢复原拾取方式"

-- 本地化文本
local L = {
	["Group Type"] = "队伍类型",
	["1 = Party only, 2 = Raid only, 3 = Both"] = "1=仅小队, 2=仅团队, 3=两者",
	["Boss Engage"] = "首领战斗",
	["On Boss Combat"] = "在首领战斗中",
	["Reset Loot"] = "重置拾取",
	["Prompt to Reset Loot Method"] = "提示重置拾取方式",
	["Party Only"] = "仅小队",
	["Raid Only"] = "仅团队",
	["Party/Raid"] = "小队/团队",
	["No target found."] = "未找到目标。",
	[" is not a known boss."] = " 不是已知的首领。",
	[" is already being ignored."] = " 已经被忽略。",
	[" now permanently ignored!"] = " 现在被永久忽略！",
	[" ignore list reset!"] = " 忽略列表已重置！",
	[" ignore list is empty!"] = " 忽略列表为空！",
	[" ignore list:"] = " 忽略列表：",
	[" removed from "] = " 已从 ",
	[" ignore list!"] = " 忽略列表中移除！",
	[" not found in "] = " 未在 ",
	["Now ignoring: "] = "现在忽略：",
	["%s Detected!. Set yourself as Master Looter?"] = "检测到%s！是否设置自己为主拾取？",
	["Reset looting to %s?"] = "重置拾取方式为%s？",
	["Ignore List"] = "忽略列表",
	["Manage permanently ignored bosses"] = "管理永久忽略的首领",
	["Print list"] = "打印列表",
	["List all permanently ignored bosses"] = "列出所有永久忽略的首领",
	["Add boss (name)"] = "添加首领（名称）",
	["Add boss name to ignore list"] = "添加首领名称到忽略列表",
	["Remove boss (name)"] = "移除首领（名称）",
	["Remove boss name from ignore list"] = "从忽略列表中移除首领名称",
	["Clear list"] = "清空列表",
	["Clear all ignored bosses"] = "清空所有忽略的首领",
	["Boss not found in Babble-Boss database"] = "在首领数据库中没有找到该首领",
	["Boss already in ignore list"] = "首领已在忽略列表中",
	["Boss added to ignore list"] = "首领已添加到忽略列表",
	["Boss removed from ignore list"] = "首领已从忽略列表中移除",
	["Ignore list cleared"] = "忽略列表已清空",
}

-- 模块变量
self._visible = false
self._resetVisible = false
self._bossName = "_NONE_"
self._lastLootMethod = "group"
self._roster = {}
self._blacklist = {
	[BB["Gurubashi Berserker"]] = true,
	[BB["Anubisath Guardian"]] = true,
	[BB["Anubisath Defender"]] = true,
	[BB["Anubisath Warder"]] = true,
	[BB["Deathsworn Captain"]] = true,
	[BB["Obsidian Sentinel"]] = true,
	[BB["Ancient Core Hound"]] = true,
	[BB["Stoneskin Gargoyle"]] = true,
}
self._whitelist = {
	[BB["Lieutenant General Andorov"]] = true,
}
self._ignored = {}

local lootMethodDesc = {
	["freeforall"] = string.gsub(LOOT_FREE_FOR_ALL, LOOT, ""),
	["roundrobin"] = string.gsub(LOOT_ROUND_ROBIN, LOOT, ""),
	["master"] = string.gsub(LOOT_MASTER_LOOTER, LOOT, ""),
	["group"] = string.gsub(LOOT_GROUP_LOOT, LOOT, ""),
	["needbeforegreed"] = string.gsub(LOOT_NEED_BEFORE_GREED, LOOT, ""),
}

local groupTypeDesc = {
	[1] = L["Party Only"],
	[2] = L["Raid Only"],
	[3] = L["Party/Raid"],
}

local combatEvents = {
	"CHAT_MSG_COMBAT_SELF_HITS",
	"CHAT_MSG_COMBAT_SELF_MISSES",
	"CHAT_MSG_COMBAT_PET_HITS",
	"CHAT_MSG_COMBAT_PET_MISSES",
	"CHAT_MSG_COMBAT_FRIENDLYPLAYER_HITS",
	"CHAT_MSG_COMBAT_FRIENDLYPLAYER_MISSES",
	"CHAT_MSG_COMBAT_PARTY_HITS",
	"CHAT_MSG_COMBAT_PARTY_MISSES",
	"CHAT_MSG_COMBAT_CREATURE_VS_PARTY_HITS",
	"CHAT_MSG_COMBAT_CREATURE_VS_PARTY_MISSES",
	"CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS",
	"CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES",
	"CHAT_MSG_COMBAT_FRIENDLY_DEATH",
	"CHAT_MSG_COMBAT_HOSTILE_DEATH",
	"CHAT_MSG_SPELL_SELF_DAMAGE",
	"CHAT_MSG_SPELL_PET_DAMAGE",
	"CHAT_MSG_SPELL_PARTY_DAMAGE",
	"CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE",
	"CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE",
	"CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE",
	"CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE",
	"CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF",
	"CHAT_MSG_SPELL_DAMAGESHIELDS_ON_OTHERS",
	"CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE",
	"CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE",
	"CHAT_MSG_SPELL_CREATURE_VS_SELF_BUFF",
	"CHAT_MSG_SPELL_CREATURE_VS_PARTY_BUFF",
}

local raidUnit, partyUnit = {}, {}
do
	for i = 1, MAX_PARTY_MEMBERS do
		partyUnit[i] = { "party" .. i, "partypet" .. i }
	end
	for i = 1, MAX_RAID_MEMBERS do
		raidUnit[i] = { "raid" .. i, "raidpet" .. i }
	end
end

-- 配置选项
Automaton_MasterLootRemind.options = {
	GroupType = {
		name = L["Group Type"],
		desc = L["1 = Party only, 2 = Raid only, 3 = Both"],
		type = "range",
		order = 1,
		get = function()
			return self.db.profile.GroupType
		end,
		set = function(v)
			self.db.profile.GroupType = v
		end,
		min = 1,
		max = 3,
		step = 1,
	},
	BossCombat = {
		name = L["Boss Engage"],
		desc = L["On Boss Combat"],
		type = "toggle",
		order = 2,
		get = function()
			return self.db.profile.BossCombat
		end,
		set = function(v)
			self.db.profile.BossCombat = v
			self:ToggleCombatEvents(self.db.profile.BossCombat)
			self:PLAYER_TARGET_CHANGED()
		end,
	},
	ResetLoot = {
		name = L["Reset Loot"],
		desc = L["Prompt to Reset Loot Method"],
		type = "toggle",
		order = 3,
		get = function()
			return self.db.profile.ResetLoot
		end,
		set = function(v)
			self.db.profile.ResetLoot = v
			self:ToggleLootStatusEvents(self.db.profile.ResetLoot)
		end,
	},
	IgnoreList = {
		type = "group",
		name = L["Ignore List"],
		desc = L["Manage permanently ignored bosses"],
		order = 4,
		args = {
			list = {
				type = "execute",
				name = L["Print list"],
				desc = L["List all permanently ignored bosses"],
				order = 1,
				func = function()
					Automaton:Print(L["Ignore List"] .. ":")
					if next(self.db.profile.Ignored) == nil then
						Automaton:Print(L[" ignore list is empty!"])
					else
						for bossName, _ in pairs(self.db.profile.Ignored) do
							Automaton:Print("- " .. bossName)
						end
					end
				end,
			},
			add = {
				type = "text",
				name = L["Add boss (name)"],
				desc = L["Add boss name to ignore list"],
				order = 2,
				usage = "<boss name>",
				get = false,
				set = function(v)
					if v and v ~= "" then
						local bossName = tostring(v)

						-- 检查是否是已知的首领
						if not self:IsBossName(bossName) then
							Automaton:Print(bossName .. L[" is not a known boss."])
							return
						end

						-- 检查是否已经在忽略列表中
						if self.db.profile.Ignored[bossName] then
							Automaton:Print(bossName .. L[" is already being ignored."])
							return
						end

						-- 添加到忽略列表
						self.db.profile.Ignored[bossName] = true
						Automaton:Print(bossName .. L[" now permanently ignored!"])
					end
				end,
			},
			remove = {
				type = "text",
				name = L["Remove boss (name)"],
				desc = L["Remove boss name from ignore list"],
				order = 3,
				usage = "<boss name>",
				get = false,
				set = function(v)
					if v and v ~= "" then
						local bossName = tostring(v)

						if self.db.profile.Ignored[bossName] then
							self.db.profile.Ignored[bossName] = nil
							Automaton:Print(bossName .. L[" removed from "] .. L[" ignore list!"])
						else
							Automaton:Print(bossName .. L[" not found in "] .. L[" ignore list!"])
						end
					end
				end,
			},
			purge = {
				type = "execute",
				name = L["Clear list"],
				desc = L["Clear all ignored bosses"],
				order = 4,
				func = function()
					self.db.profile.Ignored = {}
					Automaton:Print(L[" ignore list reset!"])
				end,
			},
		},
	},
}

------------------------------
--      Initialization      --
------------------------------

function Automaton_MasterLootRemind:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("MasterLootRemind")
	Automaton:RegisterDefaults("MasterLootRemind", "profile", {
		disabled = false,
		GroupType = 2,
		BossCombat = true,
		ResetLoot = true,
		Ignored = {},
		ver = 0,
	})
	self:RegisterOptions(self.options)
end

function Automaton_MasterLootRemind:OnEnable()
	-- 数据库版本管理
	if self.db.profile.ver ~= Automaton.ver then
		self.db.profile.Ignored = {}
		self.db.profile.ver = Automaton.ver
		Automaton:Print(self.modulename .. " 数据库已更新到最新版本")
	end

	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("RAID_ROSTER_UPDATE", "Roster")
	self:RegisterEvent("PARTY_MEMBERS_CHANGED", "Roster")

	if self.db.profile.BossCombat then
		self:ToggleCombatEvents(true)
	end
	if self.db.profile.ResetLoot then
		self:ToggleLootStatusEvents(true)
	end

	Automaton:Print(self.modulename .. " 已启用")
end

function Automaton_MasterLootRemind:OnDisable()
	self:UnregisterAllEvents()
	self:ToggleCombatEvents(false)
	self:ToggleLootStatusEvents(false)
	Automaton:Print(self.modulename .. " 已禁用")
end

function Automaton_MasterLootRemind:ToggleLootStatusEvents(enable)
	if enable then
		self:RegisterEvent("LOOT_OPENED")
	else
		if self:IsEventRegistered("LOOT_CLOSED") then
			self:UnregisterEvent("LOOT_CLOSED")
		end
		if self:IsEventRegistered("LOOT_OPENED") then
			self:UnregisterEvent("LOOT_OPENED")
		end
	end
end

function Automaton_MasterLootRemind:ToggleCombatEvents(enable)
	if enable then
		for _, event in ipairs(combatEvents) do
			if not parser:IsEventRegistered("MasterLootRemind", event) then
				parser:RegisterEvent("MasterLootRemind", event, function(event, info)
					self:OnCombatEvent(event, info)
				end)
			end
		end
	else
		for _, event in ipairs(combatEvents) do
			if parser:IsEventRegistered("MasterLootRemind", event) then
				parser:UnregisterEvent("MasterLootRemind", event)
			end
		end
	end
end

function Automaton_MasterLootRemind:PLAYER_TARGET_CHANGED()
	if self.db.profile.BossCombat then
		return
	end
	if self._visible then
		return
	end
	local lootmethod = GetLootMethod()
	if lootmethod == "master" then
		return
	end

	local optType = self.db.profile.GroupType
	local getType = self:GetGroupType()
	if getType ~= 0 and (optType == 3 or getType == optType) then
		local targetName, unitid
		if UnitIsPlayer("target") or UnitPlayerControlled("target") then
			unitid = "targettarget"
			targetName = UnitName(unitid)
		else
			unitid = "target"
			targetName = UnitName(unitid)
		end
		self:TestMLPopup(targetName, lootmethod, unitid)
	end
end

function Automaton_MasterLootRemind:OnCombatEvent(event, info)
	if not self.db.profile.BossCombat then
		return
	end
	if self._visible then
		return
	end
	local lootmethod = GetLootMethod()
	if lootmethod == "master" then
		return
	end

	local optType = self.db.profile.GroupType
	local getType = self:GetGroupType()
	if (getType == 0) or (optType ~= 3 and getType ~= optType) then
		return
	end

	local source, victim = info.source, info.victim
	if source and (source ~= ParserLib_SELF and not self._roster[source]) then
		self:TestMLPopup(source, lootmethod)
	end
	if victim and (victim ~= ParserLib_SELF and not self._roster[victim]) then
		self:TestMLPopup(victim, lootmethod)
	end
end

function Automaton_MasterLootRemind:Roster()
	local numRaidMembers, numPartyMembers = GetNumRaidMembers(), GetNumPartyMembers()
	for name in pairs(self._roster) do
		self._roster[name] = false
	end
	if numRaidMembers > 0 then
		for i = 1, numRaidMembers do
			local player, pet = UnitName(raidUnit[i][1]), UnitName(raidUnit[i][2])
			if player and not self:IsBossName(player) then
				self._roster[player] = true
			end
			if pet and not (self:IsBossName(pet)) then
				self._roster[pet] = true
			end
		end
	elseif numPartyMembers > 0 then
		for i = 1, numPartyMembers do
			local player, pet = UnitName(partyUnit[i][1]), UnitName(partyUnit[i][2])
			if player and not self:IsBossName(player) then
				self._roster[player] = true
			end
			if pet and not self:IsBossName(pet) then
				self._roster[pet] = true
			end
		end
		pet = UnitName("pet")
		if pet and not self:IsBossName(pet) then
			self._roster[pet] = true
		end
	end
end

function Automaton_MasterLootRemind:LOOT_OPENED()
	if not self.db.profile.ResetLoot then
		return
	end
	if self._resetVisible then
		return
	end
	if self._visible then
		return
	end

	local lootmethod = GetLootMethod()
	if lootmethod ~= "master" then
		return
	end

	local optType = self.db.profile.GroupType
	local getType = self:GetGroupType()
	if (getType == 0) or (optType ~= 3 and getType ~= optType) then
		return
	end

	local targetName = UnitExists("target") and UnitName("target") or nil
	if not targetName then
		return
	end
	if (not self._bossName) or (self._bossName == "_NONE_") then
		return
	end

	if string.lower(targetName) == string.lower(self._bossName) then
		self:RegisterEvent("LOOT_CLOSED")
	end
end

function Automaton_MasterLootRemind:LOOT_CLOSED()
	local lootDesc = lootMethodDesc[self._lastLootMethod]
	self:UnregisterEvent("LOOT_CLOSED")
	StaticPopup_Show("MASTERLOOTREMIND_RESET_POPUP", lootDesc)
end

function Automaton_MasterLootRemind:GetGroupType()
	if not IsPartyLeader() then
		return 0
	elseif UnitExists("party1") and not UnitInRaid("player") then
		return 1
	elseif UnitInRaid("player") then
		return 2
	end
end

function Automaton_MasterLootRemind:IsBossName(name)
	return BB:HasReverseTranslation(name) and BB:HasTranslation(BB:GetReverseTranslation(name))
end

function Automaton_MasterLootRemind:isIgnored(UnitName)
	return self.db.profile.Ignored[UnitName] or self:inTable(self._ignored, UnitName)
end

function Automaton_MasterLootRemind:Ignore()
	if
		not self._bossName
		or (self._bossName == "_NONE_")
		or self.db.profile.Ignored[self._bossName]
		or (self:inTable(self._ignored, self._bossName) ~= nil)
	then
		return
	end
	self:Print(L["Now ignoring: "] .. self._bossName)
	table.insert(self._ignored, self._bossName)
end

function Automaton_MasterLootRemind:inTable(tableName, searchString)
	if not searchString then
		return false
	end
	for index, value in pairs(tableName) do
		if string.lower(value) == string.lower(searchString) then
			return index
		end
	end
	return nil
end

function Automaton_MasterLootRemind:TestMLPopup(name, method, unit)
	if self._setPopupClose and (GetTime() - self._setPopupClose) < 1 then
		return
	end
	if
		name
		and (
			self:IsBossName(name)
			and (self._whitelist[name] or (unit == nil or UnitIsEnemy("player", unit)))
			and not self._blacklist[name]
		)
	then
		if not self:isIgnored(name) then
			local dialog = StaticPopup_Show("MASTERLOOTREMIND_SET_POPUP", name)
			if dialog then
				self._bossName = name
				dialog.data = name
				dialog.data2 = method
			end
		end
	end
end

-- 静态弹出窗口
StaticPopupDialogs["MASTERLOOTREMIND_SET_POPUP"] = {
	text = L["%s Detected!. Set yourself as Master Looter?"],
	button1 = TEXT(YES),
	button2 = TEXT(NO),
	OnShow = function()
		Automaton_MasterLootRemind._visible = true
	end,
	OnAccept = function(name, method)
		Automaton_MasterLootRemind._setPopupClose = GetTime()
		Automaton_MasterLootRemind._bossName = name
		Automaton_MasterLootRemind._lastLootMethod = method
		SetLootMethod("master", UnitName("player"))
		Automaton_MasterLootRemind._visible = false
	end,
	OnCancel = function()
		Automaton_MasterLootRemind._setPopupClose = GetTime()
		Automaton_MasterLootRemind:Ignore()
		Automaton_MasterLootRemind._bossName = "_NONE_"
		Automaton_MasterLootRemind._visible = false
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
	notClosableByLogout = 1,
	cancels = "MASTERLOOTREMIND_RESET_POPUP",
}

StaticPopupDialogs["MASTERLOOTREMIND_RESET_POPUP"] = {
	text = L["Reset looting to %s?"],
	button1 = TEXT(YES),
	button2 = TEXT(NO),
	OnShow = function()
		Automaton_MasterLootRemind._resetVisible = true
	end,
	OnAccept = function()
		SetLootMethod(Automaton_MasterLootRemind._lastLootMethod)
		Automaton_MasterLootRemind._resetVisible = false
		Automaton_MasterLootRemind._bossName = "_NONE_"
	end,
	OnCancel = function()
		Automaton_MasterLootRemind._resetVisible = false
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
}
