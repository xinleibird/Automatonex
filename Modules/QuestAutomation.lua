assert(Automaton, "Automaton not found!")

local L = AceLibrary("AceLocale-2.2"):new("Automaton_QuestAutomation")

L:RegisterTranslations("enUS", function()
	return {
		["QuestAutomation"] = "Quest Automation",
		["Automate quest acceptance and completion"] = "Automate quest acceptance and completion",
		["Enabled"] = "Enabled",
		["Toggle quest automation on/off"] = "Toggle quest automation on/off",
		["Auto Accept Quests"] = "Auto Accept Quests",
		["Automatically accept available quests"] = "Automatically accept available quests",
		["Auto Complete Quests"] = "Auto Complete Quests",
		["Automatically complete ready quests"] = "Automatically complete ready quests",
		["Auto Accept Shared Quests"] = "Auto Accept Shared Quests",
		["Automatically accept quests shared by party members"] = "Automatically accept quests shared by party members",
		["Hold Alt to temporarily disable"] = "Hold Alt to temporarily disable",
		-- Basic Settings
		["Basic Settings"] = "Basic Settings",
		-- Skip Gossip
		["Skip Gossip"] = "Skip Gossip",
		["Automatically select the first gossip option when no quests are available"] = "Automatically select the first gossip option when no quests are available",
		-- Skip Gossip Blacklist
		["Skip Gossip Blacklist"] = "Skip Gossip Blacklist",
		["Manage NPCs that should not be auto-skipped"] = "Manage NPCs that should not be auto-skipped",
		["Add NPC to Blacklist"] = "Add NPC",
		["NPC name"] = "NPC name",
		["Add an NPC to blacklist"] = "Add an NPC name to the skip gossip blacklist",
		["Remove NPC from Blacklist"] = "Remove NPC",
		["NPC name to remove"] = "NPC name to remove",
		["Remove an NPC from blacklist"] = "Remove an NPC from blacklist by name",
		["List Blacklist"] = "List Blacklist",
		["Show all blacklisted NPCs"] = "Display all blacklisted NPCs in chat",
		["Clear Blacklist"] = "Clear Blacklist",
		["Remove all NPCs from blacklist"] = "Delete every NPC from the blacklist",
		["NPC added to blacklist"] = "NPC added to blacklist",
		["NPC removed from blacklist"] = "NPC removed from blacklist",
		["Blacklist cleared"] = "Blacklist cleared",
		["Blacklist is empty"] = "Blacklist is empty",
		["NPC already in blacklist"] = "NPC already in blacklist",
		["NPC not found in blacklist"] = "NPC not found in blacklist",
		-- Custom Quests (existing)
		["Custom Quest Mode"] = "Custom Quest Mode",
		["Only automate quests in the custom list"] = "Per-NPC: if the NPC offers any custom quest, only custom quests are auto accepted/completed; if the NPC has no custom quest, all quests auto accept/complete normally",
		["Custom Quests"] = "Custom Quests",
		["Manage your custom quest list"] = "Add, remove and list custom quests",
		["Add Quest"] = "Add Quest",
		["Quest name or keyword"] = "Quest name or keyword (e.g. '长夜未尽')",
		["Reward index (1-4)"] = "Reward index (1-4)",
		["Add a custom quest"] = "Add a custom quest with the specified name and reward index",
		["Remove Quest"] = "Remove Quest",
		["Quest name to remove"] = "Quest name to remove (exact match)",
		["Remove a custom quest"] = "Remove a custom quest by name",
		["List Quests"] = "List Quests",
		["Show all custom quests"] = "Display all custom quests in chat",
		["Clear All"] = "Clear All",
		["Remove all custom quests"] = "Delete every custom quest from the list",
		["Custom quest added"] = "Custom quest added",
		["Custom quest removed"] = "Custom quest removed",
		["Custom quest list cleared"] = "Custom quest list cleared",
		["Custom quest list is empty"] = "Custom quest list is empty",
		["Already exists"] = "Already exists",
		["Invalid reward index"] = "Invalid reward index, must be 1-4",
		["Quest not found"] = "Quest not found",
		["Reward index for %s"] = "Reward index for %s",
		["背包已满，跳过自动完成任务以避免重试循环"] = "Bag full, skipped auto-complete to avoid retry loop",
	}
end)

L:RegisterTranslations("zhCN", function()
	return {
		["QuestAutomation"] = "任务自动接取与完成（跳过闲聊）",
		["Automate quest acceptance and completion"] = "常规任务自动接取与完成",
		["Enabled"] = "启用",
		["Toggle quest automation on/off"] = "开启/关闭任务自动化功能",
		["Auto Accept Quests"] = "自动接取任务",
		["Automatically accept available quests"] = "开启后自动接取可接取的任务",
		["Auto Complete Quests"] = "自动完成任务",
		["Automatically complete ready quests"] = "开启后自动完成已达成条件的任务",
		["Auto Accept Shared Quests"] = "自动接受共享任务",
		["Automatically accept quests shared by party members"] = "开启后自动接受队友分享的任务",
		["Hold Alt to temporarily disable"] = "按住Alt键临时禁用",
		-- Basic Settings
		["Basic Settings"] = "基础功能",
		-- Skip Gossip
		["Skip Gossip"] = "跳过闲聊",
		["Automatically select the first gossip option when no quests are available"] = "当NPC没有任务时，自动选择第一个对话选项以跳过闲聊",
		-- Skip Gossip Blacklist
		["Skip Gossip Blacklist"] = "跳过闲聊黑名单",
		["Manage NPCs that should not be auto-skipped"] = "管理不自动跳过闲聊的NPC",
		["Add NPC to Blacklist"] = "添加NPC",
		["NPC name"] = "NPC名称",
		["Add an NPC to blacklist"] = "添加NPC名称到跳过闲聊黑名单",
		["Remove NPC from Blacklist"] = "移除NPC",
		["NPC name to remove"] = "要移除的NPC名称",
		["Remove an NPC from blacklist"] = "按名称从黑名单移除NPC",
		["List Blacklist"] = "列出黑名单",
		["Show all blacklisted NPCs"] = "在聊天框显示所有黑名单NPC",
		["Clear Blacklist"] = "清空黑名单",
		["Remove all NPCs from blacklist"] = "删除所有黑名单NPC",
		["NPC added to blacklist"] = "NPC已添加到黑名单",
		["NPC removed from blacklist"] = "NPC已从黑名单移除",
		["Blacklist cleared"] = "黑名单已清空",
		["Blacklist is empty"] = "黑名单为空",
		["NPC already in blacklist"] = "NPC已在黑名单中",
		["NPC not found in blacklist"] = "未在黑名单中找到该NPC",
		-- Custom Quests (existing)
		["Custom Quest Mode"] = "自定义任务模式",
		["Only automate quests in the custom list"] = "按 NPC 判定：若 NPC 提供任意自定义任务，则只自动接取/完成其自定义任务（其余不动）；若 NPC 无任何自定义任务，则所有任务按常规自动接取/完成",
		["Custom Quests"] = "自定义任务管理",
		["Manage your custom quest list"] = "添加、移除和列出您的自定义任务",
		["Add Quest"] = "添加任务",
		["Quest name or keyword"] = "任务名称或关键字，输入后回车，并点击添加",
		["Reward index (1-4)"] = "奖励选择 (1-4)",
		["Add a custom quest"] = "添加一个自定义任务，并指定奖励索引",
		["Remove Quest"] = "移除任务",
		["Quest name to remove"] = "要移除的任务名称（精确匹配）",
		["Remove a custom quest"] = "按名称移除一个自定义任务",
		["List Quests"] = "列出任务",
		["Show all custom quests"] = "在聊天框显示所有自定义任务",
		["Clear All"] = "清除全部",
		["Remove all custom quests"] = "删除所有自定义任务",
		["Custom quest added"] = "自定义任务已添加",
		["Custom quest removed"] = "自定义任务已移除",
		["Custom quest list cleared"] = "自定义任务列表已清空",
		["Custom quest list is empty"] = "自定义任务列表为空",
		["Already exists"] = "已存在",
		["Invalid reward index"] = "无效的奖励选择，必须为1-4",
		["Quest not found"] = "未找到该任务",
		["Reward index for %s"] = "%s 的奖励选择",
		["背包已满，跳过自动完成任务以避免重试循环"] = "背包已满，跳过自动完成任务以避免重试循环",
	}
end)

local Automaton_QuestAutomation = Automaton:NewModule("QuestAutomation")
Automaton_QuestAutomation.modulename = L["QuestAutomation"]
Automaton_QuestAutomation.moduledesc = L["Automate quest acceptance and completion"]

-- 模块状态与数据存储
Automaton_QuestAutomation.completedQuests = {}
Automaton_QuestAutomation.incompleteQuests = {}
Automaton_QuestAutomation.fullBagWarned = {}

-----------------------------------------------------------
-- 背包空位计算（1.12.1 中 GetContainerNumFreeSlots 不可用，需手动遍历）
-----------------------------------------------------------
function Automaton_QuestAutomation:GetFreeBagSlots()
	local total = 0
	for bag = 0, 4 do
		local numSlots = GetContainerNumSlots(bag)
		if numSlots and numSlots > 0 then
			for slot = 1, numSlots do
				local texture = GetContainerItemInfo(bag, slot)
				if not texture then
					total = total + 1
				end
			end
		end
	end
	return total
end

-----------------------------------------------------------
-- 任务名称匹配函数（移植自YGBExchange）
-----------------------------------------------------------
function Automaton_QuestAutomation:MatchQuestName(questName, targetName)
	if not questName or not targetName then
		return false
	end
	local lowerQuest = string.lower(questName)
	local lowerTarget = string.lower(targetName)
	-- 第 4 个参数 plain=true：把配置名当普通字符串查找，避免任务名含 . - ( ) 等模式特殊字符时匹配异常
	return string.find(lowerQuest, lowerTarget, 1, true) ~= nil
end

local function PrintLog(msg, questName, rewardIndex)
	local info = string.format("任务名称：[%s]", questName or "?")
	if rewardIndex then
		info = info .. string.format(" 奖励选择：%d", rewardIndex)
	end
	DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ffff[任务自动化]|r %s %s", msg, info))
end

-----------------------------------------------------------
-- 配置选项定义
-----------------------------------------------------------
Automaton_QuestAutomation.options = {
	basicHeader = {
		type = "header",
		name = L["Basic Settings"],
		order = 10,
	},
	acceptQuests = {
		type = "toggle",
		name = L["Auto Accept Quests"],
		desc = L["Automatically accept available quests"] .. "\n\n" .. L["Hold Alt to temporarily disable"],
		get = function()
			return Automaton_QuestAutomation.db.profile.acceptQuests
		end,
		set = function(v)
			Automaton_QuestAutomation.db.profile.acceptQuests = v
		end,
		order = 11,
	},
	completeQuests = {
		type = "toggle",
		name = L["Auto Complete Quests"],
		desc = L["Automatically complete ready quests"] .. "\n\n" .. L["Hold Alt to temporarily disable"],
		get = function()
			return Automaton_QuestAutomation.db.profile.completeQuests
		end,
		set = function(v)
			Automaton_QuestAutomation.db.profile.completeQuests = v
		end,
		order = 12,
	},
	acceptSharedQuests = {
		type = "toggle",
		name = L["Auto Accept Shared Quests"],
		desc = L["Automatically accept quests shared by party members"]
			.. "\n\n"
			.. L["Hold Alt to temporarily disable"],
		get = function()
			return Automaton_QuestAutomation.db.profile.acceptSharedQuests
		end,
		set = function(v)
			Automaton_QuestAutomation.db.profile.acceptSharedQuests = v
		end,
		order = 13,
	},
	-- 跳过闲聊
	skipGossip = {
		type = "toggle",
		name = L["Skip Gossip"],
		desc = L["Automatically select the first gossip option when no quests are available"]
			.. "\n\n"
			.. L["Hold Alt to temporarily disable"],
		get = function()
			return Automaton_QuestAutomation.db.profile.skipGossip
		end,
		set = function(v)
			Automaton_QuestAutomation.db.profile.skipGossip = v
		end,
		order = 14,
	},
	-- 跳过闲聊黑名单管理
	skipGossipBlacklistHeader = {
		type = "header",
		name = L["Skip Gossip Blacklist"],
		order = 20,
	},
	skipGossipBlacklistAddName = {
		type = "text",
		name = L["NPC name"],
		desc = L["Add an NPC to blacklist"],
		order = 21,
		get = function()
			return Automaton_QuestAutomation.db.profile._addBlacklistNameTemp or ""
		end,
		set = function(v)
			Automaton_QuestAutomation.db.profile._addBlacklistNameTemp = v
		end,
		usage = "<NPC名称>",
	},
	skipGossipBlacklistAdd = {
		type = "execute",
		name = L["Add NPC to Blacklist"],
		desc = L["Add an NPC to blacklist"],
		order = 22,
		func = function()
			local name = Automaton_QuestAutomation.db.profile._addBlacklistNameTemp
			if name and name ~= "" then
				Automaton_QuestAutomation:AddSkipGossipBlacklist(name)
			end
		end,
	},
	skipGossipBlacklistRemoveName = {
		type = "text",
		name = L["NPC name to remove"],
		desc = L["Remove an NPC from blacklist"],
		order = 23,
		get = function()
			return Automaton_QuestAutomation.db.profile._removeBlacklistNameTemp or ""
		end,
		set = function(v)
			Automaton_QuestAutomation.db.profile._removeBlacklistNameTemp = v
		end,
		usage = "<NPC名称>",
	},
	skipGossipBlacklistRemove = {
		type = "execute",
		name = L["Remove NPC from Blacklist"],
		desc = L["Remove an NPC from blacklist"],
		order = 24,
		func = function()
			local name = Automaton_QuestAutomation.db.profile._removeBlacklistNameTemp
			if name and name ~= "" then
				Automaton_QuestAutomation:RemoveSkipGossipBlacklist(name)
			end
		end,
	},
	skipGossipBlacklistList = {
		type = "execute",
		name = L["List Blacklist"],
		desc = L["Show all blacklisted NPCs"],
		order = 25,
		func = function()
			Automaton_QuestAutomation:ListSkipGossipBlacklist()
		end,
	},
	skipGossipBlacklistClear = {
		type = "execute",
		name = L["Clear Blacklist"],
		desc = L["Remove all NPCs from blacklist"],
		order = 26,
		func = function()
			Automaton_QuestAutomation:ClearSkipGossipBlacklist()
		end,
	},
	-- 自定义任务模式开关
	useCustomQuests = {
		type = "toggle",
		name = L["Custom Quest Mode"],
		desc = L["Only automate quests in the custom list"],
		get = function()
			return Automaton_QuestAutomation.db.profile.useCustomQuests
		end,
		set = function(v)
			Automaton_QuestAutomation.db.profile.useCustomQuests = v
		end,
		order = 31,
	},
	-- 自定义任务管理分组
	customQuestsHeader = {
		type = "header",
		name = L["Custom Quests"],
		order = 30,
	},
	-- 添加任务：任务名称输入框
	customQuestAddName = {
		type = "text",
		name = L["Quest name or keyword"],
		desc = L["Quest name or keyword"],
		order = 32,
		get = function()
			return Automaton_QuestAutomation.db.profile._addNameTemp or ""
		end,
		set = function(v)
			Automaton_QuestAutomation.db.profile._addNameTemp = v
		end,
		usage = "<任务名称>",
	},
	-- 添加任务：奖励选择
	customQuestAddReward = {
		type = "range",
		name = L["Reward index (1-4)"],
		desc = L["Reward index (1-4)"],
		min = 1,
		max = 4,
		step = 1,
		order = 33,
		get = function()
			return Automaton_QuestAutomation.db.profile._addRewardTemp or 1
		end,
		set = function(v)
			Automaton_QuestAutomation.db.profile._addRewardTemp = v
		end,
	},
	-- 添加任务：执行按钮
	customQuestAdd = {
		type = "execute",
		name = L["Add Quest"],
		desc = L["Add a custom quest"],
		order = 34,
		func = function()
			local name = Automaton_QuestAutomation.db.profile._addNameTemp
			local reward = Automaton_QuestAutomation.db.profile._addRewardTemp or 1
			if not name or name == "" then
				print("|cffff0000[任务自动化] 请输入任务名称！|r")
				return
			end
			Automaton_QuestAutomation:AddCustomQuest(name, reward)
		end,
	},
	-- 移除任务：任务名称输入框
	customQuestRemoveName = {
		type = "text",
		name = L["Quest name to remove"],
		desc = L["Quest name to remove"],
		order = 35,
		get = function()
			return Automaton_QuestAutomation.db.profile._removeNameTemp or ""
		end,
		set = function(v)
			Automaton_QuestAutomation.db.profile._removeNameTemp = v
		end,
		usage = "<任务名称>",
	},
	-- 移除任务：执行按钮
	customQuestRemove = {
		type = "execute",
		name = L["Remove Quest"],
		desc = L["Remove a custom quest"],
		order = 36,
		func = function()
			local name = Automaton_QuestAutomation.db.profile._removeNameTemp
			if not name or name == "" then
				print("|cffff0000[任务自动化] 请输入要移除的任务名称！|r")
				return
			end
			Automaton_QuestAutomation:RemoveCustomQuest(name)
		end,
	},
	-- 列出任务
	customQuestList = {
		type = "execute",
		name = L["List Quests"],
		desc = L["Show all custom quests"],
		order = 37,
		func = function()
			Automaton_QuestAutomation:ListCustomQuests()
		end,
	},
	-- 清除所有任务
	customQuestClear = {
		type = "execute",
		name = L["Clear All"],
		desc = L["Remove all custom quests"],
		order = 38,
		func = function()
			Automaton_QuestAutomation:ClearCustomQuests()
		end,
	},
}

-----------------------------------------------------------
-- 初始化数据库与配置
-----------------------------------------------------------
function Automaton_QuestAutomation:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("QuestAutomation")
	Automaton:RegisterDefaults("QuestAutomation", "profile", {
		disabled = true,
		acceptQuests = true,
		completeQuests = true,
		acceptSharedQuests = true,
		-- 跳过闲聊
		skipGossip = false,
		-- 跳过闲聊黑名单
		skipGossipBlacklist = {},
		-- 自定义任务相关
		useCustomQuests = false,
		customQuests = {},
		-- 临时存储变量
		_addNameTemp = "",
		_addRewardTemp = 1,
		_removeNameTemp = "",
		_addBlacklistNameTemp = "",
		_removeBlacklistNameTemp = "",
	})
	Automaton:SetDisabledAsDefault(self, "QuestAutomation")
	self:RegisterOptions(self.options)

	if not self.db.profile.customQuests then
		self.db.profile.customQuests = {}
	end
	if not self.db.profile.skipGossipBlacklist then
		self.db.profile.skipGossipBlacklist = {}
	end
end

function Automaton_QuestAutomation:IsAltKeyHeld()
	return IsAltKeyDown()
end

function Automaton_QuestAutomation:OnEnable()
	-- 确保预设黑名单NPC存在
	local preset = { "旅店老板", "萨克斯克", "鲍比男爵" } -- 预设列表
	local current = self.db.profile.skipGossipBlacklist
	for _, npc in ipairs(preset) do
		local found = false
		for _, existing in ipairs(current) do
			if existing == npc then
				found = true
				break
			end
		end
		if not found then
			table.insert(current, npc)
		end
	end

	self:RegisterEvent("GOSSIP_SHOW")
	self:RegisterEvent("QUEST_COMPLETE")
	self:RegisterEvent("QUEST_DETAIL")
	self:RegisterEvent("QUEST_GREETING")
	self:RegisterEvent("QUEST_LOG_UPDATE")
	self:RegisterEvent("QUEST_PROGRESS")
	self:RegisterEvent("QUEST_SHOW")
end

function Automaton_QuestAutomation:OnDisable()
	self:UnregisterAllEvents()
end

function Automaton_QuestAutomation:stripText(text)
	if not text then
		return
	end
	text = string.gsub(text, "|c%x%x%x%x%x%x%x%x(.-)|r", "%1")
	text = string.gsub(text, "%[.*%]%s*", "")
	text = string.gsub(text, "(.+) %(.+%)", "%1")
	return text
end

-----------------------------------------------------------
-- 自定义任务管理（Lua 5.0 兼容，使用 table.getn）
-----------------------------------------------------------
function Automaton_QuestAutomation:AddCustomQuest(questName, rewardIndex)
	if not questName or questName == "" then
		return
	end
	rewardIndex = tonumber(rewardIndex) or 1
	if rewardIndex < 1 or rewardIndex > 4 then
		PrintLog(L["Invalid reward index"], questName)
		return
	end

	local quests = self.db.profile.customQuests
	for _, q in ipairs(quests) do
		if q.name == questName then
			PrintLog(L["Already exists"], questName)
			return
		end
	end

	table.insert(quests, {
		name = questName,
		rewardIndex = rewardIndex,
		enabled = true,
	})
	PrintLog(L["Custom quest added"], questName, rewardIndex)

	-- 清空临时输入
	self.db.profile._addNameTemp = ""
	self.db.profile._addRewardTemp = 1
end

function Automaton_QuestAutomation:RemoveCustomQuest(questName)
	if not questName or questName == "" then
		return
	end
	local quests = self.db.profile.customQuests
	local index
	for i, q in ipairs(quests) do
		if q.name == questName then
			index = i
			break
		end
	end
	if index then
		table.remove(quests, index)
		PrintLog(L["Custom quest removed"], questName)
	else
		PrintLog(L["Quest not found"], questName)
	end
	self.db.profile._removeNameTemp = ""
end

function Automaton_QuestAutomation:ListCustomQuests()
	local quests = self.db.profile.customQuests
	if table.getn(quests) == 0 then
		print("|cff00ffff[任务自动化]|r " .. L["Custom quest list is empty"])
		return
	end
	print("|cff00ffff[任务自动化] ====== 自定义任务列表 ======|r")
	for i, q in ipairs(quests) do
		local status = q.enabled and "|cff00ff00启用|r" or "|cffff0000禁用|r"
		print(string.format("  %d. %s 奖励索引: %d %s", i, q.name, q.rewardIndex or 1, status))
	end
	print("|cff00ffff====================================|r")
end

function Automaton_QuestAutomation:ClearCustomQuests()
	self.db.profile.customQuests = {}
	PrintLog(L["Custom quest list cleared"])
end

function Automaton_QuestAutomation:GetCustomQuestSetting(questName)
	if not questName or not self.db.profile.useCustomQuests then
		return nil
	end
	local quests = self.db.profile.customQuests
	local lowerName = string.lower(questName)
	-- 第一遍：精确匹配（忽略大小写），避免短任务名误匹配长任务名
	-- 例如列表里同时有"天灾石"和"堕落者的天灾石"时，后者不会被子串匹配误判到前者
	for _, q in ipairs(quests) do
		if q.enabled and string.lower(q.name or "") == lowerName then
			return q
		end
	end
	-- 第二遍：子串匹配兜底（支持关键词）
	for _, q in ipairs(quests) do
		if q.enabled and self:MatchQuestName(questName, q.name) then
			return q
		end
	end
	return nil
end

-----------------------------------------------------------
-- NPC 自定义任务粘性标记
-- 规则（按 NPC 判定）：只要当前 NPC 出现任意自定义任务，整个交互期间"只自动处理自定义任务"，
-- 列表外的任务一律不动；只有当该 NPC 一个自定义任务都没有时，才走常规自动接取/完成。
-- 切换 NPC 时重置标记（用 NPC 名称区分）。
-----------------------------------------------------------
function Automaton_QuestAutomation:GetCurrentNpcName()
	local npcName = GossipFrameTitleText and GossipFrameTitleText:GetText()
	if not npcName or npcName == "" then
		npcName = UnitName("target")
	end
	return self:stripText(npcName or "")
end

function Automaton_QuestAutomation:UpdateNpcCustomFlag(titles)
	local npcName = self:GetCurrentNpcName()
	-- NPC 切换时重置粘性标记
	if npcName ~= "" and npcName ~= self.currentNpcName then
		self.currentNpcName = npcName
		self.npcEverHadCustom = false
	end
	-- 只要可见任务里有任意自定义任务，就将标记置真并保持（粘性）
	if self.db.profile.useCustomQuests then
		for _, t in ipairs(titles) do
			if self:GetCustomQuestSetting(t) then
				self.npcEverHadCustom = true
				break
			end
		end
	end
	return self.npcEverHadCustom
end

-----------------------------------------------------------
-- 跳过闲聊黑名单管理
-----------------------------------------------------------
function Automaton_QuestAutomation:AddSkipGossipBlacklist(npcName)
	if not npcName or npcName == "" then
		return
	end
	local list = self.db.profile.skipGossipBlacklist
	for _, name in ipairs(list) do
		if name == npcName then
			PrintLog(L["NPC already in blacklist"], npcName)
			return
		end
	end
	table.insert(list, npcName)
	PrintLog(L["NPC added to blacklist"], npcName)
	self.db.profile._addBlacklistNameTemp = ""
end

function Automaton_QuestAutomation:RemoveSkipGossipBlacklist(npcName)
	if not npcName or npcName == "" then
		return
	end
	local list = self.db.profile.skipGossipBlacklist
	local index
	for i, name in ipairs(list) do
		if name == npcName then
			index = i
			break
		end
	end
	if index then
		table.remove(list, index)
		PrintLog(L["NPC removed from blacklist"], npcName)
	else
		PrintLog(L["NPC not found in blacklist"], npcName)
	end
	self.db.profile._removeBlacklistNameTemp = ""
end

function Automaton_QuestAutomation:ListSkipGossipBlacklist()
	local list = self.db.profile.skipGossipBlacklist
	if table.getn(list) == 0 then
		print("|cff00ffff[任务自动化]|r " .. L["Blacklist is empty"])
		return
	end
	print("|cff00ffff[任务自动化] ====== 跳过闲聊黑名单 ======|r")
	for i, name in ipairs(list) do
		print(string.format("  %d. %s", i, name))
	end
	print("|cff00ffff====================================|r")
end

function Automaton_QuestAutomation:ClearSkipGossipBlacklist()
	self.db.profile.skipGossipBlacklist = {}
	PrintLog(L["Blacklist cleared"])
end

-----------------------------------------------------------
-- 事件处理（修正版，不使用 ... 参数）
-----------------------------------------------------------
function Automaton_QuestAutomation:GOSSIP_SHOW()
	if self:IsAltKeyHeld() then
		return
	end

	-- 构建闲聊选项列表
	local gossipOptions = {}
	for i = 1, 32 do
		local button = getglobal("GossipTitleButton" .. i)
		if button and button:IsVisible() then
			local title = self:stripText(button:GetText())
			local type = button.type
			table.insert(gossipOptions, {
				title = title,
				type = type,
				index = i,
				button = button,
			})
		end
	end

	local clicked = false
	local hasAnyTask = false

	-- 构建当前 NPC 可见任务标题列表，用于判定"该 NPC 是否含自定义任务"
	local visibleTitles = {}
	for _, opt in ipairs(gossipOptions) do
		if opt.type == "Available" or opt.type == "Active" then
			table.insert(visibleTitles, opt.title)
		end
	end
	local npcHasCustom = self:UpdateNpcCustomFlag(visibleTitles)

	-- 任务选项处理（Available / Active）：
	-- 该 NPC 含自定义任务 → 只自动处理自定义任务；否则常规自动接取/完成
	local function TryClickTaskOptions(onlyCustom)
		for _, opt in ipairs(gossipOptions) do
			if opt.type == "Available" or opt.type == "Active" then
				hasAnyTask = true
				local custom = self.db.profile.useCustomQuests and self:GetCustomQuestSetting(opt.title)
				-- 仅当 custom 为有效表时才算"自定义任务"（useCustomQuests 关闭时 custom=false，不算）
				local isCustom = not not custom
				-- onlyCustom=true 仅处理自定义任务；false 仅处理非自定义任务
				if onlyCustom == isCustom then
					local shouldClick = false
					if opt.type == "Available" then
						-- 接取：自定义/非自定义一致，受 acceptQuests 控制
						if self.db.profile.acceptQuests then
							shouldClick = true
						end
					else -- Active 交任务
						if self.db.profile.completeQuests then
							-- 自定义任务直接交（奖励在 QUEST_COMPLETE 阶段按预设索引处理）
							-- 非自定义任务仅当确实已完成才交
							if custom or self.completedQuests[opt.title] then
								shouldClick = true
							end
						end
					end
					if shouldClick then
						opt.button:Click()
						return true
					end
				end
			end
		end
		return false
	end

	if npcHasCustom then
		-- 该 NPC 含自定义任务：只自动处理自定义任务，列表外任务一律不动
		clicked = TryClickTaskOptions(true)
	else
		-- 该 NPC 无自定义任务：常规自动接取 / 完成任务
		clicked = TryClickTaskOptions(false)
	end

	-- 若未点击任何任务且跳过闲聊开启，且没有任务选项，则尝试跳过闲聊
	if not clicked and self.db.profile.skipGossip and not hasAnyTask then
		-- 获取 NPC 名称
		local npcName = GossipFrameTitleText and GossipFrameTitleText:GetText()
		if not npcName or npcName == "" then
			npcName = UnitName("target")
		end
		npcName = self:stripText(npcName)

		-- 黑名单检查
		if npcName then
			for _, blackName in ipairs(self.db.profile.skipGossipBlacklist) do
				if self:MatchQuestName(npcName, blackName) then
					return -- 在黑名单中，不执行跳过
				end
			end
		end

		-- 统计非任务选项的数量
		local numGossip = 0
		for _, opt in ipairs(gossipOptions) do
			if opt.type ~= "Available" and opt.type ~= "Active" then
				numGossip = numGossip + 1
			end
		end

		-- 仅当恰好只有一个非任务选项时才自动点击
		if numGossip == 1 then
			for _, opt in ipairs(gossipOptions) do
				if opt.type ~= "Available" and opt.type ~= "Active" then
					opt.button:Click()
					break
				end
			end
		end
		-- 若有多个闲聊选项，则什么都不做，留给玩家手动选择
	end
end

function Automaton_QuestAutomation:QUEST_COMPLETE()
	if self:IsAltKeyHeld() then
		return
	end

	local questName = self:stripText(GetTitleText())
	local custom = self.db.profile.useCustomQuests and self:GetCustomQuestSetting(questName)
	-- 同步 NPC 自定义标记（保证从 gossip/greeting 或直接打开任务帧时，标记都反映当前 NPC）
	self:UpdateNpcCustomFlag({ questName })

	-- 修复:背包满时调用 GetQuestReward 会因物品无法接收而无限重试
	-- 仅当任务有物品奖励且背包完全没空位时跳过,纯金钱奖励不受影响
	local hasItemReward = (GetNumQuestRewards() or 0) > 0 or (GetNumQuestChoices() or 0) > 0
	if hasItemReward and self:GetFreeBagSlots() <= 0 then
		if not self.fullBagWarned[questName] then
			self.fullBagWarned[questName] = true
			PrintLog(L["背包已满，跳过自动完成任务以避免重试循环"], questName)
		end
		return
	end

	-- 自定义任务：按预设奖励索引自动选择
	if custom then
		local idx = custom.rewardIndex or 1
		local numChoices = GetNumQuestChoices()
		if numChoices == 0 then
			-- 无物品选择：直接点完成按钮领取固定奖励
			QuestFrameCompleteQuestButton:Click()
		elseif idx >= 1 and idx <= numChoices then
			GetQuestReward(idx)
		else
			GetQuestReward(1)
		end
	-- 非自定义任务：仅当该 NPC 没有自定义任务时才按常规规则自动完成；
	-- 若该 NPC 含自定义任务，则只自动化自定义任务（非自定义留给玩家手动处理）
	elseif self.db.profile.completeQuests and not self.npcEverHadCustom then
		local numChoices = GetNumQuestChoices()
		if numChoices <= 1 then
			-- 单一奖励：自动点击完成
			if numChoices == 0 then
				-- 无奖励任务（通常不会进入QUEST_COMPLETE），安全起见调用完成按钮
				QuestFrameCompleteQuestButton:Click()
			else
				GetQuestReward(1)
			end
		end
		-- 有多个奖励选项时，不做任何操作，等待玩家手动选择
	end
end

function Automaton_QuestAutomation:QUEST_DETAIL()
	if self:IsAltKeyHeld() then
		return
	end

	local questName = self:stripText(GetTitleText())
	local custom = self.db.profile.useCustomQuests and self:GetCustomQuestSetting(questName)
	-- 同步 NPC 自定义标记
	self:UpdateNpcCustomFlag({ questName })
	-- 非自定义任务：仅当该 NPC 没有自定义任务时才自动接取；
	-- 若该 NPC 含自定义任务，则只自动化自定义任务（非自定义留给玩家手动处理）
	if self.db.profile.acceptQuests and (custom or not self.npcEverHadCustom) then
		AcceptQuest()
	end
end

function Automaton_QuestAutomation:QUEST_GREETING()
	if self:IsAltKeyHeld() then
		return
	end

	-- 构建可见任务标题列表，更新"该 NPC 是否含自定义任务"粘性标记
	local visibleTitles = {}
	local button, text
	for i = 1, 32 do
		button = getglobal("QuestTitleButton" .. i)
		if button and button:IsVisible() then
			text = self:stripText(button:GetText())
			table.insert(visibleTitles, text)
		end
	end
	local npcHasCustom = self:UpdateNpcCustomFlag(visibleTitles)

	for i = 1, 32 do
		button = getglobal("QuestTitleButton" .. i)
		if button and button:IsVisible() then
			text = self:stripText(button:GetText())
			local custom = self.db.profile.useCustomQuests and self:GetCustomQuestSetting(text)
			if npcHasCustom then
				-- 该 NPC 含自定义任务：只处理自定义任务
				if custom then
					if self.completedQuests[text] and self.db.profile.completeQuests then
						button:Click()
						break
					elseif not self.incompleteQuests[text] and self.db.profile.acceptQuests then
						button:Click()
						break
					end
				end
			else
				-- 该 NPC 无自定义任务：常规自动接取/完成
				if self.completedQuests[text] and self.db.profile.completeQuests then
					button:Click()
					break
				elseif not self.incompleteQuests[text] and self.db.profile.acceptQuests then
					button:Click()
					break
				end
			end
		end
	end
end

function Automaton_QuestAutomation:QUEST_LOG_UPDATE()
	local startEntry = GetQuestLogSelection()
	local numEntries = GetNumQuestLogEntries()
	local title, isComplete, noObjectives, _

	self.completedQuests = {}
	self.incompleteQuests = {}
	self.fullBagWarned = {}

	if numEntries > 0 then
		for i = 1, numEntries do
			SelectQuestLogEntry(i)
			title, _, _, _, _, _, isComplete = GetQuestLogTitle(i)
			noObjectives = GetNumQuestLeaderBoards(i) == 0
			if title then
				if isComplete or noObjectives then
					self.completedQuests[title] = true
				else
					self.incompleteQuests[title] = true
				end
			end
		end
	end

	SelectQuestLogEntry(startEntry)
end

function Automaton_QuestAutomation:QUEST_PROGRESS()
	if self:IsAltKeyHeld() then
		return
	end

	local questName = self:stripText(GetTitleText())
	local custom = self.db.profile.useCustomQuests and self:GetCustomQuestSetting(questName)
	-- 同步 NPC 自定义标记
	self:UpdateNpcCustomFlag({ questName })

	-- 自定义任务：按 completeQuests 直接完成（奖励在 QUEST_COMPLETE 阶段按预设索引处理）
	-- 非自定义任务：仅当该 NPC 没有自定义任务时，才按常规规则完成
	if self.db.profile.completeQuests and IsQuestCompletable() and (custom or not self.npcEverHadCustom) then
		CompleteQuest()
	end
end

function Automaton_QuestAutomation:QUEST_SHOW()
	if self:IsAltKeyHeld() then
		return
	end

	if self.db.profile.acceptSharedQuests then
		if StaticPopup_Visible("QUEST_ACCEPT") then
			ConfirmAcceptQuest()
			StaticPopup_Hide("QUEST_ACCEPT")
		end
	end
end

local originalStaticPopup_OnShow = StaticPopup_OnShow
function StaticPopup_OnShow()
	if originalStaticPopup_OnShow then
		originalStaticPopup_OnShow()
	end
	if this.which == "QUEST_ACCEPT" then
		if
			not IsAltKeyDown()
			and Automaton_QuestAutomation.db
			and Automaton_QuestAutomation.db.profile
			and Automaton_QuestAutomation.db.profile.acceptSharedQuests
		then
			ConfirmAcceptQuest()
			this:Hide()
		end
	end
end
