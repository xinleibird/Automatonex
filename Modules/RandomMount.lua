assert(Automaton, "Automaton not found!")

------------------------------
--      Are you local?      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_RandomMount")

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function()
	return {
		["RandomMount"] = "Random Mount",
		["Automatically summon random mounts, using bug mounts in Ahn'Qiraj"] = "Automatically summon random mounts, using bug mounts in Ahn'Qiraj",
	}
end)

L:RegisterTranslations("zhCN", function()
	return {
		["RandomMount"] = "随机坐骑",
		["Automatically summon random mounts, using bug mounts in Ahn'Qiraj"] = "自动召唤随机坐骑，在安其拉神殿使用虫子坐骑，/rm 或 /randommount（建议做宏） - 使用随机坐骑",
	}
end)

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_RandomMount = Automaton:NewModule("RandomMount")
Automaton_RandomMount.modulename = L["RandomMount"]
Automaton_RandomMount.moduledesc = L["Automatically summon random mounts, using bug mounts in Ahn'Qiraj"]
Automaton_RandomMount.options = {}

-- 日志输出控制（0=禁用，1=启用）
local RM_ENABLE_DEBUG = 0

-- 坐骑页面的可能名称（用于在多语言环境下识别）
local mountTabNames = {
	"坐骑",
}

-- 职业坐骑列表
local classMounts = {
	-- 术士职业坐骑
	"召唤地狱战马",
	"召唤恐惧战马",

	-- 圣骑士职业坐骑
	"召唤战马",
	"召唤军马",
	"骑乘斑马",
	-- 德鲁伊特殊形态
	"条纹霜刃豹",
	"迅捷旅行形态",
}

-- 不被视为坐骑的法术列表（优先包含所有生活技能）
local nonMountSpells = {
	-- 生活技能（主要专业）
	"采矿",
	"熔炼矿石",
	"草药学",
	"剥皮",
	"锻造",
	"工程学",
	"侏儒工程学",
	"地精工程学",
	"炼金术",
	"转化",
	"裁缝",
	"制皮",
	"元素制皮",
	"部落制皮",
	"龙鳞制皮",
	"附魔",
	"分解",
	-- 生活技能（次要专业）
	"烹饪",
	"急救",
	"绷带",
	"钓鱼",
	"生存",
	-- 其他非坐骑法术
	"传送门",
	"传送",
	"开锁",
	"复活",
	"霜甲术",
	"侦测隐藏",
	"侦测魔法",
	"追踪矿物",
	"追踪草药",
	"追踪野兽",
	"追踪亡灵",
	"追踪恶魔",
	"追踪人型生物",
	"碾磨",
	"制作",
	"研磨",
	"龟速模式",
}

-- 打印调试信息
local function DebugMessage(message, force)
	if force or RM_ENABLE_DEBUG == 1 then
		DEFAULT_CHAT_FRAME:AddMessage("|cFF33AAFF[随机坐骑]|r " .. message)
	end
end

-- 获取表的长度（兼容所有表）
local function GetTableLength(t)
	if not t then
		return 0
	end
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

-- 获取玩家法术总数（安全版本）
local function GetTotalSpellCount()
	if GetNumSpellCount then
		return GetNumSpellCount(BOOKTYPE_SPELL)
	else
		return 300 -- 后备值，兼容旧版本
	end
end

-- 安全获取法术名称，如果出错返回nil
local function SafeGetSpellName(spellIndex, bookType)
	local success, name = pcall(GetSpellName, spellIndex, bookType)
	if success then
		return name
	end
	return nil
end

-- 安全获取法术信息，如果出错返回nil
local function SafeGetSpellInfo(spellID)
	local success, name = pcall(GetSpellInfo, spellID)
	if success then
		return name
	end
	return nil
end

-- 检查玩家是否在安其拉神殿
local function IsInAhnQiraj()
	local zoneName = GetRealZoneText()

	if not zoneName then
		return false
	end

	local aqPatterns = {
		"安其拉",
	}

	for i = 1, GetTableLength(aqPatterns) do
		local pattern = aqPatterns[i]
		if zoneName == pattern then
			DebugMessage("检测到当前位置：" .. zoneName .. "，判定为安其拉区域")
			return true
		end
	end

	DebugMessage("当前位置：" .. zoneName .. "，非安其拉区域")
	return false
end

-- 检查页面名称是否是坐骑页面
local function IsMountTab(tabName)
	if not tabName then
		return false
	end

	tabName = string.lower(tabName)
	for i = 1, GetTableLength(mountTabNames) do
		local name = string.lower(mountTabNames[i])
		if string.find(tabName, name) then
			return true
		end
	end

	return false
end

-- 判断是否是虫子坐骑（通过名称）
local function IsBugMount(spellName)
	if not spellName then
		return false
	end

	if string.find(spellName, "其拉作战坦克") or string.find(spellName, "Qiraji") then
		return true
	end

	return false
end

-- 检查是否是职业坐骑
local function IsClassMount(spellName)
	if not spellName then
		return false
	end

	for i = 1, GetTableLength(classMounts) do
		if spellName == classMounts[i] then
			return true
		end
	end

	return false
end

-- 检查法术是否在nonMountSpells列表中（完全匹配）
local function IsNonMountSpell(spellName)
	if not spellName then
		return false
	end

	for i = 1, GetTableLength(nonMountSpells) do
		if spellName == nonMountSpells[i] then
			return true
		end
	end

	return false
end

-- 根据名称查找坐骑法术ID（严格匹配）
local function FindMountSpellIDByName(spellName)
	if not spellName then
		return nil
	end

	local searchName = string.lower(spellName)

	-- 遍历所有法术书页面
	local numTabs = GetNumSpellTabs()
	for tabIndex = 1, numTabs do
		local tabName, _, tabStart, tabCount = GetSpellTabInfo(tabIndex)
		for spellOffset = 0, tabCount - 1 do
			local spellIndex = tabStart + spellOffset
			local name = SafeGetSpellName(spellIndex, BOOKTYPE_SPELL)
			if name and string.lower(name) == searchName then
				-- 判断是否为坐骑（排除生活技能等）
				if not IsNonMountSpell(name) then
					return spellIndex
				else
					return nil -- 是生活技能，不是坐骑
				end
			end
		end
	end

	-- 额外扫描职业坐骑和骑乘乌龟（可能不在坐骑页面）
	local totalSpells = GetTotalSpellCount()
	for i = 1, totalSpells do
		local name = SafeGetSpellName(i, BOOKTYPE_SPELL)
		if name and string.lower(name) == searchName then
			-- 职业坐骑或骑乘乌龟
			if IsClassMount(name) or string.find(name, "骑乘乌龟") or string.find(name, "Riding Turtle") then
				return i
			end
		end
	end

	return nil
end

-- 获取玩家可用的坐骑（自动扫描 + 自定义，并排除黑名单）
local function GetPlayerMounts()
	local bugMountList = {}
	local normalMountList = {}
	local foundMountTab = false
	local autoMountNames = {} -- 用于去重，记录自动扫描到的坐骑名称

	-- 获取法术书页面的数量
	local numTabs = GetNumSpellTabs()

	-- 遍历所有法术书页面
	for tabIndex = 1, numTabs do
		local tabName, tabTexture, tabStart, tabCount = GetSpellTabInfo(tabIndex)

		-- 检查该页面是否是坐骑页面
		if tabName and IsMountTab(tabName) then
			foundMountTab = true

			-- 遍历该页面上的所有法术
			for spellOffset = 0, tabCount - 1 do
				local spellIndex = tabStart + spellOffset
				local spellName = SafeGetSpellName(spellIndex, BOOKTYPE_SPELL)

				if spellName and spellName ~= "" then
					-- 首先检查是否在非坐骑列表中
					if IsNonMountSpell(spellName) then
						-- 跳过非坐骑法术
						-- 特殊处理职业坐骑
					elseif IsClassMount(spellName) then
						table.insert(normalMountList, { name = spellName, id = spellIndex })
						autoMountNames[spellName] = true
					-- 特殊处理骑乘乌龟
					elseif string.find(spellName, "骑乘乌龟") or string.find(spellName, "Riding Turtle") then
						table.insert(normalMountList, { name = spellName, id = spellIndex })
						autoMountNames[spellName] = true
					-- 根据名称判断是否是虫子坐骑
					elseif IsBugMount(spellName) then
						table.insert(bugMountList, { name = spellName, id = spellIndex })
						autoMountNames[spellName] = true
					else
						table.insert(normalMountList, { name = spellName, id = spellIndex })
						autoMountNames[spellName] = true
					end
				end
			end
		end
	end

	-- 特别检查是否有骑乘乌龟和职业坐骑（兜底，使用实际法术总数）
	local totalSpells = GetTotalSpellCount()
	for i = 1, totalSpells do
		local spellName = SafeGetSpellName(i, BOOKTYPE_SPELL)
		if spellName and spellName ~= "" and not autoMountNames[spellName] then
			if string.find(spellName, "骑乘乌龟") or string.find(spellName, "Riding Turtle") then
				table.insert(normalMountList, { name = spellName, id = i })
				autoMountNames[spellName] = true
			elseif IsClassMount(spellName) then
				table.insert(normalMountList, { name = spellName, id = i })
				autoMountNames[spellName] = true
			end
		end
	end

	-- 添加自定义坐骑（如果启用）
	if Automaton_RandomMount.db and Automaton_RandomMount.db.char.customMountsEnable then
		local customMounts = Automaton_RandomMount.db.char.customMounts or {}
		for _, spellID in ipairs(customMounts) do
			local spellName = SafeGetSpellInfo(spellID) -- 通过法术ID获取名称（安全）
			if spellName and not autoMountNames[spellName] then
				if IsBugMount(spellName) then
					table.insert(bugMountList, { name = spellName, id = spellID })
				else
					table.insert(normalMountList, { name = spellName, id = spellID })
				end
				autoMountNames[spellName] = true
			end
		end
	end

	-- 过滤掉被排除的坐骑（黑名单）
	local excluded = Automaton_RandomMount.db.char.excludedMounts or {}
	local excludedSet = {}
	for _, id in ipairs(excluded) do
		excludedSet[id] = true
	end

	local filteredBugs = {}
	local filteredNormal = {}

	for _, mount in ipairs(bugMountList) do
		if not excludedSet[mount.id] then
			table.insert(filteredBugs, mount)
		end
	end

	for _, mount in ipairs(normalMountList) do
		if not excludedSet[mount.id] then
			table.insert(filteredNormal, mount)
		end
	end

	return {
		bugs = filteredBugs,
		normal = filteredNormal,
	}
end

-- 随机选择坐骑并释放
local function RandomMount()
	if UnitAffectingCombat("player") then
		DebugMessage("战斗中无法召唤坐骑！")
		return
	end

	if UnitCastingInfo and UnitCastingInfo("player") then
		DebugMessage("施法中无法召唤坐骑！")
		return
	elseif IsCurrentAction(1) or IsCurrentAction(2) or IsCurrentAction(3) or IsCurrentAction(4) then
		DebugMessage("施法中无法召唤坐骑！")
		return
	end

	local mounts = GetPlayerMounts()
	local selectedMount = nil

	local hasBugMounts = (mounts.bugs and mounts.bugs[1] ~= nil)
	local hasNormalMounts = (mounts.normal and mounts.normal[1] ~= nil)

	if not hasBugMounts and not hasNormalMounts then
		DebugMessage("您没有任何坐骑！")
		return
	end

	local inAhnQiraj = IsInAhnQiraj()

	if inAhnQiraj then
		local bugMountCount = GetTableLength(mounts.bugs)
		if bugMountCount > 0 then
			local index = random(bugMountCount)
			selectedMount = mounts.bugs[index]
			DebugMessage("在安其拉神殿中，选择虫子坐骑: " .. selectedMount.name)
		else
			DebugMessage("您没有虫子坐骑，无法在安其拉神殿骑行！")
			return
		end
	else
		local normalMountCount = GetTableLength(mounts.normal)
		if normalMountCount > 0 then
			local index = random(normalMountCount)
			selectedMount = mounts.normal[index]
			DebugMessage("选择普通坐骑: " .. selectedMount.name)
		else
			local bugMountCount = GetTableLength(mounts.bugs)
			if bugMountCount > 0 then
				local index = random(bugMountCount)
				selectedMount = mounts.bugs[index]
				DebugMessage("没有普通坐骑，只能使用虫子坐骑: " .. selectedMount.name)
			end
		end
	end

	if selectedMount then
		CastSpell(selectedMount.id, BOOKTYPE_SPELL)
	end
end

-- 处理聊天命令
local function HandleChatCommand(msg)
	msg = msg and string.trim(msg) or ""

	if msg == "list" then
		local mounts = GetPlayerMounts()
		DebugMessage("您当前可用的坐骑列表（已过滤移除的）:", true)

		if GetTableLength(mounts.bugs) > 0 then
			DebugMessage("虫子坐骑:", true)
			for i, mount in ipairs(mounts.bugs) do
				DebugMessage("  " .. i .. ". " .. mount.name, true)
			end
		end

		if GetTableLength(mounts.normal) > 0 then
			DebugMessage("普通坐骑:", true)
			for i, mount in ipairs(mounts.normal) do
				DebugMessage("  " .. i .. ". " .. mount.name, true)
			end
		end

		if GetTableLength(mounts.bugs) == 0 and GetTableLength(mounts.normal) == 0 then
			DebugMessage("没有找到任何坐骑", true)
		end
	elseif string.find(msg, "^debug") then
		local _, _, value = string.find(msg, "debug%s+(%d)")
		if value then
			value = tonumber(value)
			if value == 0 or value == 1 then
				RM_ENABLE_DEBUG = value
				DebugMessage("日志输出已" .. (value == 1 and "启用" or "禁用"), true)
			else
				DebugMessage("日志设置值无效，请使用 0（禁用）或 1（启用）", true)
			end
		else
			DebugMessage("当前日志输出状态：" .. (RM_ENABLE_DEBUG == 1 and "启用" or "禁用"), true)
			DebugMessage("使用 /rm debug 0 禁用日志输出，或 /rm debug 1 启用日志输出", true)
		end
	elseif msg == "customlist" then
		if Automaton_RandomMount.ListCustomMounts then
			Automaton_RandomMount:ListCustomMounts()
		end
	elseif msg == "excludelist" then
		if Automaton_RandomMount.ListExcludedMounts then
			Automaton_RandomMount:ListExcludedMounts()
		end
	elseif string.find(msg, "^exclude add ") then
		local _, _, name = string.find(msg, "^exclude add (.+)")
		if name then
			Automaton_RandomMount:ExcludeMount(name)
		else
			DebugMessage("用法: /rm exclude add 坐骑名称", true)
		end
	elseif string.find(msg, "^exclude remove ") then
		local _, _, name = string.find(msg, "^exclude remove (.+)")
		if name then
			Automaton_RandomMount:UnExcludeMount(name)
		else
			DebugMessage("用法: /rm exclude remove 坐骑名称", true)
		end
	elseif msg == "exclude clear" then
		Automaton_RandomMount:ClearExcludedMounts()
	elseif msg == "help" or msg == "?" then
		DebugMessage("随机坐骑命令:", true)
		DebugMessage("- /rm 或 /randommount - 使用随机坐骑", true)
		DebugMessage("- /rm list - 查看当前可用坐骑（已过滤移除的）", true)
		DebugMessage("- /rm customlist - 查看自定义坐骑列表", true)
		DebugMessage("- /rm excludelist - 查看已移除（黑名单）的坐骑", true)
		DebugMessage("- /rm exclude add 坐骑名称 - 将坐骑加入黑名单（不再出现）", true)
		DebugMessage("- /rm exclude remove 坐骑名称 - 将坐骑移出黑名单", true)
		DebugMessage("- /rm exclude clear - 清空黑名单", true)
		DebugMessage("- /rm debug 0|1 - 设置日志输出", true)
		DebugMessage("- /rm help - 显示此帮助信息", true)
		DebugMessage("- 更多设置请打开Automaton配置界面", true)
	else
		RandomMount()
	end
end

------------------------------
--      Options 构建        --
------------------------------

-- 添加自定义坐骑（通过名称）
function Automaton_RandomMount:AddCustomMount(inputName)
	if not inputName or inputName == "" then
		DebugMessage("请输入坐骑名称！", true)
		return
	end

	local spellID = FindMountSpellIDByName(inputName)
	if not spellID then
		DebugMessage('未找到名为 "' .. inputName .. '" 的坐骑，请确认名称正确且已学会。', true)
		return
	end

	-- 确保customMounts存在
	self.db.char.customMounts = self.db.char.customMounts or {}

	-- 检查是否已存在
	for _, existingID in ipairs(self.db.char.customMounts) do
		if existingID == spellID then
			DebugMessage('坐骑 "' .. inputName .. '" 已在自定义列表中！', true)
			return
		end
	end

	table.insert(self.db.char.customMounts, spellID)
	DebugMessage("成功添加自定义坐骑：" .. inputName, true)
end

-- 列出所有自定义坐骑
function Automaton_RandomMount:ListCustomMounts()
	self.db.char.customMounts = self.db.char.customMounts or {}
	if GetTableLength(self.db.char.customMounts) == 0 then
		DebugMessage("自定义坐骑列表为空", true)
		return
	end

	DebugMessage("自定义坐骑列表:", true)
	for i, id in ipairs(self.db.char.customMounts) do
		-- 使用 SafeGetSpellName 通过索引获取名称（因为存储的是法术书索引）
		local name = SafeGetSpellName(id, BOOKTYPE_SPELL)
		if name then
			DebugMessage("  " .. i .. ". " .. name, true)
		else
			DebugMessage("  " .. i .. ". 未知法术 (ID: " .. id .. ")", true)
		end
	end
end

-- 清除所有自定义坐骑
function Automaton_RandomMount:ClearCustomMounts()
	self.db.char.customMounts = {}
	DebugMessage("已清除所有自定义坐骑！", true)
end

-- 黑名单管理：添加坐骑到排除列表
function Automaton_RandomMount:ExcludeMount(inputName)
	if not inputName or inputName == "" then
		DebugMessage("请输入坐骑名称！", true)
		return
	end

	local spellID = FindMountSpellIDByName(inputName)
	if not spellID then
		DebugMessage('未找到名为 "' .. inputName .. '" 的坐骑，请确认名称正确且已学会。', true)
		return
	end

	self.db.char.excludedMounts = self.db.char.excludedMounts or {}

	-- 检查是否已存在
	for _, existingID in ipairs(self.db.char.excludedMounts) do
		if existingID == spellID then
			DebugMessage('坐骑 "' .. inputName .. '" 已在移除列表中！', true)
			return
		end
	end

	table.insert(self.db.char.excludedMounts, spellID)
	DebugMessage("成功将坐骑加入移除列表：" .. inputName, true)
end

-- 从黑名单中移除坐骑
function Automaton_RandomMount:UnExcludeMount(inputName)
	if not inputName or inputName == "" then
		DebugMessage("请输入坐骑名称！", true)
		return
	end

	local spellID = FindMountSpellIDByName(inputName)
	if not spellID then
		DebugMessage('未找到名为 "' .. inputName .. '" 的坐骑，无法移除。', true)
		return
	end

	self.db.char.excludedMounts = self.db.char.excludedMounts or {}

	local index = nil
	for i, existingID in ipairs(self.db.char.excludedMounts) do
		if existingID == spellID then
			index = i
			break
		end
	end

	if index then
		table.remove(self.db.char.excludedMounts, index)
		DebugMessage("成功将坐骑移出移除列表：" .. inputName, true)
	else
		DebugMessage('移除列表中不存在坐骑 "' .. inputName .. '"', true)
	end
end

-- 列出黑名单中的所有坐骑
function Automaton_RandomMount:ListExcludedMounts()
	self.db.char.excludedMounts = self.db.char.excludedMounts or {}
	if GetTableLength(self.db.char.excludedMounts) == 0 then
		DebugMessage("移除列表为空", true)
		return
	end

	DebugMessage("已移除的坐骑列表:", true)
	for i, id in ipairs(self.db.char.excludedMounts) do
		-- 使用 SafeGetSpellName 通过索引获取名称（因为存储的是法术书索引）
		local name = SafeGetSpellName(id, BOOKTYPE_SPELL)
		if name then
			DebugMessage("  " .. i .. ". " .. name, true)
		else
			DebugMessage("  " .. i .. ". 未知法术 (ID: " .. id .. ")", true)
		end
	end
end

-- 清空黑名单
function Automaton_RandomMount:ClearExcludedMounts()
	self.db.char.excludedMounts = {}
	DebugMessage("已清空移除列表！", true)
end

-- 构建选项面板
Automaton_RandomMount.options = {
	customMountsEnable = {
		name = "启用自定义坐骑",
		desc = "启用后，随机坐骑将包括您自定义添加的坐骑（与自动扫描的坐骑合并）",
		type = "toggle",
		order = 1,
		get = function()
			return Automaton_RandomMount.db.char.customMountsEnable
		end,
		set = function(v)
			Automaton_RandomMount.db.char.customMountsEnable = v
		end,
	},
	listMounts = {
		type = "execute",
		name = "列出所有可用坐骑",
		desc = "在聊天框显示您当前可用的所有坐骑（已过滤移除的）",
		order = 2,
		func = function()
			HandleChatCommand("list")
		end,
	},
	separator1 = {
		type = "header",
		name = "自定义坐骑管理（通过名称）",
		order = 10,
	},
	customMountAdd = {
		type = "text",
		name = "添加自定义坐骑",
		desc = "输入坐骑名称添加（例如：召唤战马）",
		order = 11,
		get = false,
		set = function(v)
			Automaton_RandomMount:AddCustomMount(v)
		end,
		usage = "输入坐骑名称后按回车",
	},
	customMountList = {
		type = "execute",
		name = "查看自定义坐骑列表",
		desc = "显示所有已添加的自定义坐骑",
		order = 12,
		func = function()
			Automaton_RandomMount:ListCustomMounts()
		end,
	},
	customMountClear = {
		type = "execute",
		name = "清除所有自定义坐骑",
		desc = "一键清除所有自定义坐骑",
		order = 13,
		func = function()
			Automaton_RandomMount:ClearCustomMounts()
		end,
	},
	separator2 = {
		type = "header",
		name = "移除坐骑管理（黑名单）",
		order = 20,
	},
	excludeMountAdd = {
		type = "text",
		name = "移除坐骑（加入黑名单）",
		desc = "输入坐骑名称，将其从可用坐骑中移除",
		order = 21,
		get = false,
		set = function(v)
			Automaton_RandomMount:ExcludeMount(v)
		end,
		usage = "输入坐骑名称后按回车",
	},
	excludeMountRemove = {
		type = "text",
		name = "恢复坐骑（移出黑名单）",
		desc = "输入坐骑名称，将其重新加入可用坐骑",
		order = 22,
		get = false,
		set = function(v)
			Automaton_RandomMount:UnExcludeMount(v)
		end,
		usage = "输入坐骑名称后按回车",
	},
	excludeMountList = {
		type = "execute",
		name = "查看已移除的坐骑列表",
		desc = "显示所有已被移除（黑名单）的坐骑",
		order = 23,
		func = function()
			Automaton_RandomMount:ListExcludedMounts()
		end,
	},
	excludeMountClear = {
		type = "execute",
		name = "清空移除列表",
		desc = "一键恢复所有被移除的坐骑",
		order = 24,
		func = function()
			Automaton_RandomMount:ClearExcludedMounts()
		end,
	},
}

------------------------------
--      Initialization      --
------------------------------

function Automaton_RandomMount:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("RandomMount")
	-- 注册 profile 默认值（模块禁用状态，跨角色）
	Automaton:RegisterDefaults("RandomMount", "profile", {
		disabled = false,
	})
	-- 注册 char 默认值（角色特定数据）
	Automaton:RegisterDefaults("RandomMount", "char", {
		customMountsEnable = false,
		customMounts = {},
		excludedMounts = {},
	})
	Automaton:SetDisabledAsDefault(self, "RandomMount")
	self:RegisterOptions(self.options)

	SLASH_RANDOMMOUNT1 = "/rm"
	SLASH_RANDOMMOUNT2 = "/randommount"
	SlashCmdList["RANDOMMOUNT"] = HandleChatCommand

	_G["RandomMount"] = RandomMount
end

function Automaton_RandomMount:OnEnable() end
function Automaton_RandomMount:OnDisable() end
