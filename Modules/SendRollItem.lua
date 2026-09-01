assert(Automaton, "Automaton not found!")

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_SendRollItem = Automaton:NewModule("SendRollItem")
local self = Automaton_SendRollItem

-- 本地化配置
local L = AceLibrary("AceLocale-2.2"):new("Automaton_SendRollItem")
L:RegisterTranslations("zhCN", function()
	return {
		["SendRollItem"] = "掉落通告",
		["Automatically send loot notifications to group channels"] = "自动向团队/队伍频道发送指定物品掉落通告",
		["BOSS掉落通告"] = "BOSS掉落通告",
		["Enable BOSS loot notifications (rare quality and above)"] = "启用BOSS掉落通告（精良蓝色品质以上）",
		["小怪掉落通告"] = "小怪掉落通告",
		["Enable mob loot notifications (epic quality and above)"] = "启用小怪掉落通告（史诗紫色品质以上）",
		["箱子掉落通告"] = "箱子掉落通告",
		["Enable chest loot notifications (uncommon quality and above)"] = "启用箱子掉落通告（优秀绿色品质以上）",
	}
end)

-- 模块基本信息
Automaton_SendRollItem.modulename = L["SendRollItem"]
Automaton_SendRollItem.moduledesc = L["Automatically send loot notifications to group channels"]

-- 白名单物品配置
self.whiteList = {
	["22726"] = "埃提耶什的碎片",
	["22351"] = "被玷污的长袍",
	["22350"] = "被玷污的外套",
	["22349"] = "被玷污的胸甲",
	["23071"] = "天启护腿",
	["23025"] = "诅咒者的徽记",
	["23027"] = "宽恕的热情",
	["22811"] = "灵魂之弦",
	["22809"] = "赎罪十字军之槌",
	["22691"] = "堕落的灰烬使者",
	["18646"] = "神圣之眼",
	["18703"] = "远古石叶",
	["19139"] = "火焰卫士护肩",
	["18811"] = "防火披风",
	["18808"] = "眠火手套",
	["18809"] = "耳语秘言腰带",
	["18812"] = "真龙护腕",
	["18806"] = "熔火胫甲",
	["19140"] = "灼烧指环",
	["18805"] = "熔火犬牙",
	["18803"] = "芬克的熔岩挖掘器",
	["61524"] = "自然呼唤外衣",
	["61522"] = "翡翠领主项圈",
	["61527"] = "埃伦纽斯的鳞片",
	["61523"] = "绽放之水晶剑",
	["61525"] = "自然的呼唤",
	["61526"] = "翡翠石保卫者",
	["61197"] = "褪色的梦境碎片",
	["61196"] = "广阔意识之包",
}

-- 模块配置项
Automaton_SendRollItem.options = {
	report_boss = {
		type = "toggle",
		name = L["BOSS掉落通告"],
		desc = L["Enable BOSS loot notifications (rare quality and above)"],
		get = function()
			return self.db.profile.report_boss
		end,
		set = function(v)
			self.db.profile.report_boss = v
		end,
		order = 10,
	},
	report_mobs = {
		type = "toggle",
		name = L["小怪掉落通告"],
		desc = L["Enable mob loot notifications (epic quality and above)"],
		get = function()
			return self.db.profile.report_mobs
		end,
		set = function(v)
			self.db.profile.report_mobs = v
		end,
		order = 20,
	},
	report_chest = {
		type = "toggle",
		name = L["箱子掉落通告"],
		desc = L["Enable chest loot notifications (uncommon quality and above)"],
		get = function()
			return self.db.profile.report_chest
		end,
		set = function(v)
			self.db.profile.report_chest = v
		end,
		order = 30,
	},
}

------------------------------
--      Initialization      --
------------------------------

function Automaton_SendRollItem:OnInitialize()
	-- 初始化数据库
	self.db = Automaton:AcquireDBNamespace("SendRollItem")
	Automaton:RegisterDefaults("SendRollItem", "profile", {
		disabled = true,
		report_boss = true,
		report_mobs = false,
		report_chest = true,
	})

	-- 注册配置项
	self:RegisterOptions(self.options)
end

function Automaton_SendRollItem:OnEnable()
	-- 注册事件
	self:RegisterEvent("LOOT_OPENED")
end

function Automaton_SendRollItem:OnDisable()
	-- 取消事件注册
	self:UnregisterAllEvents()
end

------------------------------
--      Helper Functions      --
------------------------------

function Automaton_SendRollItem:IsWhiteListItem(itemId)
	for k, _ in pairs(self.whiteList) do
		if k == itemId then
			return true
		end
	end
	return false
end

------------------------------
--      Event Handlers      --
------------------------------

function Automaton_SendRollItem:LOOT_OPENED()
	-- 添加权限检查：只有团长或助理才能发送通告
	local hasAuthority = false

	if GetNumRaidMembers() > 1 then
		-- 在团队中，检查是否为团长或助理
		local name = UnitName("player")
		for i = 1, GetNumRaidMembers() do
			local raidName, rank = GetRaidRosterInfo(i)
			if raidName == name then
				hasAuthority = (rank == 1 or rank == 2) -- 1=助理, 2=团长
				break
			end
		end
	elseif GetNumPartyMembers() > 1 then
		-- 在队伍中，检查是否为队长
		hasAuthority = UnitIsPartyLeader("player")
	else
		-- 单人时默认有权限
		hasAuthority = true
	end

	-- 如果没有权限，则直接退出
	if not hasAuthority then
		return
	end

	-- 确定发送频道
	local channel = nil
	if GetNumRaidMembers() > 1 then
		channel = "RAID"
	elseif GetNumPartyMembers() > 1 then
		channel = "PARTY"
	else
		channel = "SAY"
	end

	-- 获取目标信息
	local unitClassification = UnitClassification("PLAYERTARGET")
	local isWorldBoss = (unitClassification == "worldboss")
	local targetName = UnitName("TARGET") or "未知目标"
	local targetIsDead = UnitIsDead("TARGET")
	local isChestOrOther = not targetIsDead

	-- 收集符合条件的掉落物品
	local lootNotifyList = {}
	for i = 1, GetNumLootItems() do
		local _, _, _, quality = GetLootSlotInfo(i)
		if LootSlotIsItem(i) then
			local itemLink = GetLootSlotLink(i)
			local _, _, itemID = string.find(itemLink, "item:(%d+):%d+:%d+:%d+")

			if targetIsDead and not isWorldBoss and self.db.profile.report_mobs then
				-- 小怪掉落：史诗品质以上
				if quality >= 4 then
					table.insert(lootNotifyList, itemLink)
				end
			elseif targetIsDead and isWorldBoss and self.db.profile.report_boss then
				-- BOSS掉落：精良品质以上
				if quality >= 3 then
					table.insert(lootNotifyList, itemLink)
				end
			elseif self.db.profile.report_chest then
				-- 箱子掉落：优秀品质以上且在白名单中
				if quality >= 1 and self:IsWhiteListItem(itemID) then
					table.insert(lootNotifyList, itemLink)
				end
			end
		end
	end

	-- 没有符合条件的物品则退出
	if table.getn(lootNotifyList) == 0 then
		return
	end

	-- 发送掉落通知
	if isWorldBoss then
		SendChatMessage(">BOSS-" .. targetName .. "<掉落：", channel)
		for i, itemLink in ipairs(lootNotifyList) do
			SendChatMessage("掉落(" .. i .. "):" .. itemLink, channel)
		end
	elseif isChestOrOther then
		SendChatMessage(">宝箱或其他<掉落：", channel)
		for i, itemLink in ipairs(lootNotifyList) do
			SendChatMessage("掉落(" .. i .. "):" .. itemLink, channel)
		end
	else
		-- 小怪掉落合并显示
		local lootItemLinks = table.concat(lootNotifyList, " ")
		SendChatMessage(">小怪-" .. targetName .. "<掉落：" .. lootItemLinks, channel)
	end
end
