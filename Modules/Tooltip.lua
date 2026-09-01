assert(Automaton, "Automaton not found!")

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_Tooltip = Automaton:NewModule("Tooltip")
Automaton_Tooltip.modulename = "鼠标提示增强"
Automaton_Tooltip.moduledesc = "鼠标提示增强功能"
Automaton_Tooltip.options = {
	header1 = {
		type = "header",
		name = "物品信息",
		order = 10,
	},
	showitemid = {
		type = "toggle",
		name = "显示物品ID",
		desc = "显示物品ID",
		order = 11,
		get = function()
			return Automaton_Tooltip.db.profile.showitemid
		end,
		set = function(v)
			Automaton_Tooltip.db.profile.showitemid = v
		end,
	},
	header2 = {
		type = "header",
		name = "目标信息",
		order = 20,
	},
	showResistance = {
		type = "toggle",
		name = "目标护甲和抗性",
		desc = "鼠标提示显示目标的护甲和抗性",
		order = 21,
		get = function()
			return Automaton_Tooltip.db.profile.showResistance
		end,
		set = function(v)
			Automaton_Tooltip.db.profile.showResistance = v
		end,
	},
	showDamageAndSpeed = {
		type = "toggle",
		name = "目标伤害和攻速",
		desc = "鼠标提示显示目标的伤害范围和攻击速度",
		order = 22,
		get = function()
			return Automaton_Tooltip.db.profile.showDamageAndSpeed
		end,
		set = function(v)
			Automaton_Tooltip.db.profile.showDamageAndSpeed = v
		end,
	},
	showgather = {
		type = "toggle",
		name = "采集等级",
		desc = "在鼠标放到矿或草药上时，鼠标提示中显示采集需要的技能等级。",
		order = 12,
		get = function()
			return Automaton_Tooltip.db.profile.showgather
		end,
		set = function(v)
			Automaton_Tooltip.db.profile.showgather = v
		end,
	},
	showReputation = {
		type = "toggle",
		name = "显示目标声望",
		desc = "鼠标提示显示目标的声望信息",
		order = 23,
		get = function()
			return Automaton_Tooltip.db.profile.showReputation
		end,
		set = function(v)
			Automaton_Tooltip.db.profile.showReputation = v
		end,
	},
	showWishInfo = {
		type = "toggle",
		name = "显示玩家许愿信息",
		desc = "鼠标提示显示目标玩家的许愿物品及分数",
		order = 24,
		get = function()
			return Automaton_Tooltip.db.profile.showWishInfo
		end,
		set = function(v)
			Automaton_Tooltip.db.profile.showWishInfo = v
		end,
	},
	showImpression = {
		type = "toggle",
		name = "显示玩家印象",
		desc = "鼠标提示显示目标玩家的印象信息",
		order = 25,
		get = function()
			return Automaton_Tooltip.db.profile.showImpression
		end,
		set = function(v)
			Automaton_Tooltip.db.profile.showImpression = v
		end,
	},
	showspellid = {
		type = "toggle",
		name = "显示法术ID",
		desc = "在法术、BUFF、DEBUFF提示中显示法术ID（需要superwow）",
		order = 13,
		get = function()
			return Automaton_Tooltip.db.profile.showspellid
		end,
		set = function(v)
			Automaton_Tooltip.db.profile.showspellid = v
		end,
	},
	header3 = {
		type = "header",
		name = "界面行为",
		order = 30,
	},
	cursorScale = {
		type = "range",
		name = "鼠标大小",
		desc = "设置鼠标光标大小 (1.0 - 4.0)（需要bigcursor模组）",
		order = 31,
		min = 1,
		max = 4,
		step = 0.1,
		get = function()
			return Automaton_Tooltip.db.profile.cursorScale
		end,
		set = function(v)
			Automaton_Tooltip.db.profile.cursorScale = v
			if SetCursorScale then
				SetCursorScale(v)
			end
		end,
	},
	hideInCombat = {
		type = "toggle",
		name = "战斗中隐藏提示",
		desc = "战斗中自动隐藏鼠标提示（按住Shift可临时显示）",
		order = 32,
		get = function()
			return Automaton_Tooltip.db.profile.hideInCombat
		end,
		set = function(v)
			Automaton_Tooltip.db.profile.hideInCombat = v
		end,
	},
}

------------------------------
--      战斗隐藏提示相关变量      --
------------------------------
local inCombat = 0

------------------------------
--      Initialization      --
------------------------------
function Automaton_Tooltip:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("Automaton_Tooltip")
	Automaton:RegisterDefaults("Automaton_Tooltip", "profile", {
		disabled = false,
		showitemid = true,
		showResistance = false,
		showDamageAndSpeed = true,
		showgather = true,
		showReputation = true,
		showImpression = true,
		showspellid = false,
		cursorScale = 1.0, -- 默认光标大小
		hideInCombat = false, -- 战斗隐藏提示默认关闭
	})
	Automaton:SetDisabledAsDefault(self, "Automaton_Tooltip")
	self:RegisterOptions(self.options)
	if not self.f then
		self.f = CreateFrame("Frame", "tipFormat", GameTooltip)
	end

	-- 初始化Gratuity库用于获取法术信息
	if not self.gratuity then
		self.gratuity = AceLibrary:HasInstance("Gratuity-2.0") and AceLibrary("Gratuity-2.0") or nil
	end

	-- 初始化战斗隐藏提示相关
	self:InitCombatHideTooltip()
end

------------------------------
--      战斗隐藏提示核心逻辑      --
------------------------------
function Automaton_Tooltip:ShouldHideTooltip()
	-- 未启用战斗隐藏功能 或 非战斗状态 → 不隐藏
	if not self.db.profile.hideInCombat or inCombat == 0 then
		return nil
	end

	-- 按住Shift → 不隐藏
	if IsShiftKeyDown() then
		return nil
	end

	-- 满足隐藏条件
	return 1
end

function Automaton_Tooltip:HideTooltipIfNeeded()
	if self:ShouldHideTooltip() then
		GameTooltip:Hide()
		return 1
	end
end

function Automaton_Tooltip:HookTooltipMethod(methodName)
	local original = GameTooltip[methodName]

	if type(original) ~= "function" then
		return
	end

	GameTooltip[methodName] = function(...)
		if self:HideTooltipIfNeeded() then
			return
		end

		return original(unpack(arg))
	end
end

function Automaton_Tooltip:InitCombatHideTooltip()
	-- Hook OnShow 脚本
	local originalOnShow = GameTooltip:GetScript("OnShow")
	GameTooltip:SetScript("OnShow", function()
		if self:HideTooltipIfNeeded() then
			return
		end

		if originalOnShow then
			originalOnShow()
		end
	end)

	-- Hook 所有Tooltip方法
	self:HookTooltipMethod("SetUnit")
	self:HookTooltipMethod("SetAction")
	self:HookTooltipMethod("SetBagItem")
	self:HookTooltipMethod("SetInventoryItem")
	self:HookTooltipMethod("SetLootItem")
	self:HookTooltipMethod("SetLootRollItem")
	self:HookTooltipMethod("SetMerchantItem")
	self:HookTooltipMethod("SetPetAction")
	self:HookTooltipMethod("SetQuestItem")
	self:HookTooltipMethod("SetQuestLogItem")
	self:HookTooltipMethod("SetShapeshift")
	self:HookTooltipMethod("SetSpell")
	self:HookTooltipMethod("SetTrackingSpell")
	self:HookTooltipMethod("SetTradeSkillItem")
	self:HookTooltipMethod("SetTradePlayerItem")
	self:HookTooltipMethod("SetTradeTargetItem")

	-- 注册战斗相关事件
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	self:RegisterEvent("MODIFIER_STATE_CHANGED")
end

------------------------------
--      战斗事件处理      --
------------------------------
function Automaton_Tooltip:PLAYER_REGEN_DISABLED()
	inCombat = 1
	self:HideTooltipIfNeeded()
end

function Automaton_Tooltip:PLAYER_REGEN_ENABLED()
	inCombat = 0
end

function Automaton_Tooltip:UPDATE_MOUSEOVER_UNIT()
	-- 增强已由 GameTooltip.SetUnit 钩子处理，此处调用以确保鼠标悬停时也生效
	self:EnhanceUnitTooltip("mouseover")
	-- 战斗中检查是否需要隐藏
	self:HideTooltipIfNeeded()
end

function Automaton_Tooltip:MODIFIER_STATE_CHANGED()
	if inCombat == 1 and self.db.profile.hideInCombat then
		if arg1 == "LSHIFT" or arg1 == "RSHIFT" then
			if arg2 == 0 then
				GameTooltip:Hide()
			elseif UnitExists("mouseover") then
				GameTooltip:SetUnit("mouseover")
			end
		end
	end
end

function Automaton_Tooltip:OnEnable()
	self:HookScript(self.f, "OnShow")
	self:HookScript(self.f, "OnHide")
	self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")

	-- 钩子法术相关提示函数
	self:HookSpellTooltipFunctions()

	-- 钩住 GameTooltip.SetUnit 以便在所有框架上显示增强信息
	local oldSetUnit = GameTooltip.SetUnit
	function GameTooltip.SetUnit(self, unit)
		oldSetUnit(self, unit)
		-- 模块已启用时才增强 (检查 disabled 标志)
		if Automaton_Tooltip.db and not Automaton_Tooltip.db.profile.disabled then
			Automaton_Tooltip:EnhanceUnitTooltip(unit)
		end
	end
	Automaton_Tooltip.oldSetUnit = oldSetUnit

	-- 强制PFUI框架显示tooltip
	if pfUI and pfUI.uf and pfUI.uf.OnEnter then
		local oldOnEnter = pfUI.uf.OnEnter
		pfUI.uf.OnEnter = function(self)
			if not self then
				return
			end -- 保护判断，需要 end
			oldOnEnter(self)
			if self.label and type(self.config) == "table" and self.config.showtooltip == "0" then
				GameTooltip_SetDefaultAnchor(GameTooltip, self)
				GameTooltip:SetUnit(self.label .. self.id)
				GameTooltip:Show()
			end -- 内层 if 的 end
		end -- 函数定义自身的 end
		self.savedOnEnter = oldOnEnter
	end -- 外部 if 的 end

	-- 应用光标大小
	if SetCursorScale then
		SetCursorScale(self.db.profile.cursorScale or 1.0)
	end
end

function Automaton_Tooltip:OnDisable()
	-- 恢复 GameTooltip.SetUnit 原函数
	if Automaton_Tooltip.oldSetUnit then
		GameTooltip.SetUnit = Automaton_Tooltip.oldSetUnit
		Automaton_Tooltip.oldSetUnit = nil
	end

	-- 恢复 PFUI OnEnter 原函数
	if self.savedOnEnter then
		pfUI.uf.OnEnter = self.savedOnEnter
		self.savedOnEnter = nil
	end

	self.f:Hide()
	self:UnhookAll()
	self:UnregisterAllEvents()

	-- 恢复光标大小为默认值（可选）
	if SetCursorScale then
		SetCursorScale(1.0)
	end
end

-- 钩子法术相关提示函数
function Automaton_Tooltip:HookSpellTooltipFunctions()
	-- 检查 SuperWoW 是否加载（必需依赖）
	if not GetPlayerBuffID then
		-- 可选：若选项已开启，自动关闭并提示
		if self.db and self.db.profile and self.db.profile.showspellid then
			self.db.profile.showspellid = false
			-- 如果有打印函数可输出提示，例如：
			-- Automaton:Print("|cffff0000[Tooltip]|r 未检测到 SuperWoW，法术ID显示功能已禁用。")
		end
		return
	end
	-- 处理玩家BUFF
	local HookSetPlayerBuff = GameTooltip.SetPlayerBuff
	function GameTooltip.SetPlayerBuff(self, index)
		HookSetPlayerBuff(self, index)
		if Automaton_Tooltip.db.profile.showspellid then
			local spellId = GetPlayerBuffID(index)
			if spellId then
				GameTooltip:AddDoubleLine("法术ID：", spellId)
				GameTooltip:Show()
			end
		end
	end

	-- 处理玩家DEBUFF
	local HookSetPlayerDebuff = GameTooltip.SetPlayerDebuff
	function GameTooltip.SetPlayerDebuff(self, index)
		HookSetPlayerDebuff(self, index)
		if Automaton_Tooltip.db.profile.showspellid then
			local _, _, _, spellId = UnitDebuff("player", index)
			if spellId then
				GameTooltip:AddDoubleLine("法术ID：", spellId)
				GameTooltip:Show()
			end
		end
	end

	-- 处理单位BUFF
	local HookSetUnitBuff = GameTooltip.SetUnitBuff
	function GameTooltip.SetUnitBuff(self, unit, index)
		HookSetUnitBuff(self, unit, index)
		if Automaton_Tooltip.db.profile.showspellid then
			local _, _, _, _, _, _, spellId = UnitBuff(unit, index)
			if spellId then
				GameTooltip:AddDoubleLine("法术ID：", spellId)
				GameTooltip:Show()
			end
		end
	end

	-- 处理单位DEBUFF
	local HookSetUnitDebuff = GameTooltip.SetUnitDebuff
	function GameTooltip.SetUnitDebuff(self, unit, index)
		HookSetUnitDebuff(self, unit, index)
		if Automaton_Tooltip.db.profile.showspellid then
			local _, _, _, _, _, _, spellId = UnitDebuff(unit, index)
			if spellId then
				GameTooltip:AddDoubleLine("法术ID：", spellId)
				GameTooltip:Show()
			end
		end
	end
end

-- 检查物品是否在愿望列表中
function Automaton_Tooltip:IsItemInWishList(itemId)
	-- 检查AtlasLoot愿望列表是否存在
	if not AtlasLootCharDB or not AtlasLootCharDB["WishList"] then
		return false
	end

	-- 将itemId转换为数字进行比较
	itemId = tonumber(itemId)
	if not itemId then
		return false
	end

	-- 遍历愿望列表检查物品
	for _, wishItem in ipairs(AtlasLootCharDB["WishList"]) do
		local wishItemId = tonumber(wishItem[1])
		if wishItemId and wishItemId == itemId then
			return true
		end
	end

	return false
end

function Automaton_Tooltip:OnHide(object)
	GameTooltip.itemLink = nil
	GameTooltip.itemCount = nil
	self.hooks[self.f]["OnHide"](self.f, object)
end

function Automaton_Tooltip:OnShow(object)
	if self:FormatItemTooltip(GameTooltip) then
		return
	else
		self.hooks[self.f]["OnShow"](self.f, object)
		if UnitExists("mouseover") then
			return
		end
		self:ShowObj()
	end
end

-- 取单位实际抗性（优先取修正后数值，兼容只返回单值的客户端，nil 归 0）
local function zGetUnitResist(unit, index)
	local base, modified = UnitResistance(unit, index)
	return (modified or base) or 0
end

-- 显示抗性和护甲的函数
function Automaton_Tooltip:ShowMouseoverResist(unit)
	-- 检查单位是否敌对或中立
	local reaction = UnitReaction("player", unit)
	local isHostileOrNeutral = reaction and (reaction <= 4) -- 4及以下为中立或敌对

	-- 1=神圣 2=火焰 3=自然 4=冰霜 5=暗影 6=奥术
	local GetFire = zGetUnitResist(unit, 2)
	local GetFrost = zGetUnitResist(unit, 4)
	local GetNature = zGetUnitResist(unit, 3)
	local GetArcane = zGetUnitResist(unit, 6)
	local GetHoly = zGetUnitResist(unit, 1)
	local GetShadow = zGetUnitResist(unit, 5)
	local GetArmor = UnitArmor(unit) or 0
	--火抗、冰抗
	if GetFire ~= 0 and GetFrost == 0 then
		GameTooltip:AddLine("|cffFF0000火抗" .. GetFire)
	elseif GetFire == 0 and GetFrost ~= 0 then
		GameTooltip:AddLine("|cff4AE8F5冰抗" .. GetFrost)
	elseif GetFire ~= 0 and GetFrost ~= 0 then
		GameTooltip:AddLine("|cffFF0000火抗" .. GetFire .. " " .. "|cff4AE8F5冰抗" .. GetFrost)
	end
	--自抗、奥抗
	if GetNature ~= 0 and GetArcane == 0 then
		GameTooltip:AddLine("|cff00FF00自抗" .. GetNature)
	elseif GetNature == 0 and GetArcane ~= 0 then
		GameTooltip:AddLine("|cffF241FF奥抗" .. GetArcane)
	elseif GetNature ~= 0 and GetArcane ~= 0 then
		GameTooltip:AddLine("|cff00FF00自抗" .. GetNature .. " " .. "|cffF241FF奥抗" .. GetArcane)
	end
	--圣抗、暗抗
	if GetHoly ~= 0 and GetShadow == 0 then
		GameTooltip:AddLine("|cffFFFE91圣抗" .. GetHoly)
	elseif GetHoly == 0 and GetShadow ~= 0 then
		GameTooltip:AddLine("|cff87248F暗抗" .. GetShadow)
	elseif GetHoly ~= 0 and GetShadow ~= 0 then
		GameTooltip:AddLine("|cffFFFE91圣抗" .. GetHoly .. " " .. "|cff87248F暗抗" .. GetShadow)
	end
	--护甲 - 只显示敌方和中立单位的
	if GetArmor ~= 0 and isHostileOrNeutral then
		GameTooltip:AddLine("护甲" .. GetArmor)
	end
end

-- 新增独立的显示伤害和攻速函数
function Automaton_Tooltip:ShowMouseoverDamageAndSpeed(unit)
	-- 检查单位是否敌对或中立
	local reaction = UnitReaction("player", unit)
	local isHostileOrNeutral = reaction and (reaction <= 4) -- 4及以下为中立或敌对

	-- 只对敌对/中立的非玩家单位显示伤害和攻速
	if isHostileOrNeutral and not UnitIsPlayer(unit) then
		local minDmg, maxDmg = UnitDamage(unit)
		local attackSpeed = UnitAttackSpeed(unit)
		if minDmg and maxDmg then
			GameTooltip:AddLine(string.format("伤害范围: %.0f - %.0f", minDmg, maxDmg))
		end
		if attackSpeed then
			GameTooltip:AddLine(string.format("攻击速度: %.2f", attackSpeed))
		end
	end
end

-- 获取单位声望信息
local function zGetUnitFaction(unit)
	local id = UnitReaction(unit, "player")
	if not id then
		return ""
	end
	if id > 6 then
		-- 从tooltip中提取阵营标签
		local label
		for i = GameTooltip:NumLines(), 1, -1 do
			label = getglobal("GameTooltipTextLeft" .. i):GetText()
			if label and label ~= PVP_ENABLED then
				break
			end
		end
		-- 匹配阵营信息以获取精确声望等级
		local name, standingId, isHeader
		for i = 1, GetNumFactions() do
			name, _, standingId, _, _, _, _, _, isHeader = GetFactionInfo(i)
			if not isHeader and name == label then
				id = standingId
				break
			end
		end
	end
	-- 格式化声望文本（带颜色）
	local ret = GetText("FACTION_STANDING_LABEL" .. id, UnitSex("player"))
	if id == 5 then
		ret = format("|cff33CC33%s|r", ret)
	elseif id == 6 then
		ret = format("|cff33CCCC%s|r", ret)
	elseif id == 7 then
		ret = format("|cffFF6633%s|r", ret)
	elseif id == 8 then
		ret = format("|cffDD33DD%s|r", ret)
	end
	return ret
end

-- 处理物品第一行文本的函数
local function FirstLineText(text)
	if not text then
		return
	end
	local result
	if strfind(text, "Mailbox") then
		result = "邮箱"
	elseif strfind(text, "Grave of ") then
		local _, _, name, level = strfind(text, "Grave of (.+) %(level (%d+)%)")
		if name and level then
			result = format("%s 的坟墓(等级 %s)", name, level)
		end
	elseif Automaton.t.obj[text] then
		result = Automaton.t.obj[text]
	elseif Automaton.t.herbmini[text] then
		result = text
	elseif strfind(text, "需要") then
		result = text
	end
	return result
end

-- 显示物品的函数
function Automaton_Tooltip:ShowObj()
	if not self.db.profile.showgather then
		return
	end
	local lines = {}
	local text, r, g, b, a, strex
	for i = 1, GameTooltip:NumLines() do
		text = FirstLineText(getglobal("GameTooltipTextLeft" .. i):GetText())
		if not text then
			break
		end
		r, g, b, a = getglobal("GameTooltipTextLeft" .. i):GetTextColor()
		lines[i] = { text = text, r = r, g = g, b = b, a = a }
	end

	if getn(lines) > 0 then
		GameTooltip:ClearLines()
		for i, val in pairs(lines) do
			if i == 1 then
				strex = Automaton.t.herbmini[val.text] or ""
				GameTooltip:SetText(val.text)
			else
				if self.db.profile.showgather and strex then
					GameTooltip:AddLine(val.text .. strex, val.r, val.g, val.b, val.a)
				else
					GameTooltip:AddLine(val.text, val.r, val.g, val.b, val.a)
				end
			end
		end
		GameTooltip:Show()
	end
end

-- 核心增强函数：在单位提示上添加所有配置的额外信息
function Automaton_Tooltip:EnhanceUnitTooltip(unit)
	self = self or Automaton_Tooltip
	if not unit or not UnitExists(unit) then
		return
	end

	-- 抗性
	if self.db.profile.showResistance then
		self:ShowMouseoverResist(unit)
	end

	-- 伤害和攻速
	if self.db.profile.showDamageAndSpeed then
		self:ShowMouseoverDamageAndSpeed(unit)
	end

	-- 声望（仅非玩家单位）
	if
		self.db.profile.showReputation
		and not UnitIsPlayer(unit)
		and not (UnitPlayerControlled(unit) and not UnitIsPlayer(unit))
	then
		local repText = zGetUnitFaction(unit)
		if repText and repText ~= "" then
			GameTooltip:AddLine("" .. repText)
		end
	end

	-- 许愿信息
	if self.db.profile.showWishInfo and UnitIsPlayer(unit) then
		local name = UnitName(unit)
		if getXyInfo then
			local info = getXyInfo(name)
			-- 构建当前在团/在队成员表，用于统计许愿人数时过滤已退团团员（与XyTracker的XYLISTbyPlayer保持一致）
			local currentMembers = {}
			local totalRaidMembers = GetNumRaidMembers()
			if totalRaidMembers and totalRaidMembers > 0 then
				for mi = 1, totalRaidMembers do
					local raidName = GetRaidRosterInfo(mi)
					if raidName then
						currentMembers[raidName] = true
					end
				end
			else
				local playerName = UnitName("player")
				if playerName then
					currentMembers[playerName] = true
				end
			end
			if info and info["xy"] and info["xy"] ~= "" and info["xy"] ~= "---未许愿---" then
				local xy = info["xy"]
				local dkp = info["dkp"] or 0

				-- 为每个物品添加许愿人数标记（如果人数 > 1）
				local newXy = xy
				if XyArray and type(XyArray) == "table" then
					newXy = string.gsub(xy, "(|c%x+|Hitem:(%d+):.-|h%[(.-)%]|h|r)", function(link, itemId, itemName)
						-- 统计许愿该物品的人数
						local count = 0
						for i = 1, getn(XyArray) do
							local other = XyArray[i]
							local otherName = other["name"]
							if otherName and currentMembers[otherName] then
								local otherXy = other["xy"] or ""
								if otherXy ~= "---未许愿---" and otherXy ~= "" then
									if string.find(otherXy, "|Hitem:" .. itemId .. ":") then
										count = count + 1
									end
								end
							end
						end
						if count > 1 then
							return link .. " |cffffffffx" .. count .. "|r"
						else
							return link
						end
					end)
				end

				GameTooltip:AddLine(string.format("|cffFFFF00许愿:|r %s |cffFFFF00分数:|r %d", newXy, dkp))
			end
		end
	end

	-- 印象
	if self.db.profile.showImpression and UnitIsPlayer(unit) then
		local playerName = UnitName(unit)
		if SpiritSenseRecData then
			local impression = SpiritSenseRecData[playerName]
			if impression then
				local impressionText
				if type(impression) == "table" then
					impressionText = table.concat(impression, ", ")
				else
					impressionText = tostring(impression)
				end
				GameTooltip:AddLine(string.format("印象: %s", impressionText))
			end
		end
	end

	GameTooltip:Show()
end

function Automaton_Tooltip:FormatItemTooltip(tooltip)
	local self = Automaton_Tooltip
	if not tooltip.itemLink then
		return
	end

	tooltip.itemCount = IsShiftKeyDown() and tooltip.itemCount or 1
	local _, _, itemId = strfind(tooltip.itemLink, ".*item:(%d+):[%d:]+|h%[(.+)%]|h|.*")
	if not itemId then
		return
	end

	local showing = false

	--显示物品ID
	if self.db.profile.showitemid then
		tooltip:AddDoubleLine("物品ID：", itemId)
		showing = true
	end

	-- 检查是否在愿望列表中
	if self:IsItemInWishList(tonumber(itemId)) then
		tooltip:AddLine("|cff00FF00✓ 我的愿望|r")
		showing = true
	end

	if showing then
		tooltip:Show()
	end
	return showing
end

-- 钩子函数，用于获取物品链接
local HookSetHyperlink = GameTooltip.SetHyperlink
function GameTooltip.SetHyperlink(self, itemstring)
	if not itemstring then
		return
	end
	local name, linkstr, quality = GetItemInfo(itemstring)
	if name then
		local hex = select(4, GetItemQualityColor(quality))
		GameTooltip.itemLink = hex .. "|H" .. itemstring .. "|h[" .. name .. "]|h" .. FONT_COLOR_CODE_CLOSE

		-- 替换原有的物品数量获取方式：通过遍历背包获取数量
		local itemCount = 0
		-- 遍历所有背包容器（0-4为背包，5-11为银行，这里只算背包）
		for container = 0, 4 do
			-- 遍历容器内所有槽位
			for slot = 1, GetContainerNumSlots(container) do
				local itemLink = GetContainerItemLink(container, slot)
				if itemLink and itemLink == linkstr then
					-- 获取该槽位的物品数量并累加
					local count = select(2, GetContainerItemInfo(container, slot))
					itemCount = itemCount + (count or 0)
				end
			end
		end
		GameTooltip.itemCount = itemCount
	end
	return HookSetHyperlink(self, itemstring)
end

local HookSetBagItem = GameTooltip.SetBagItem
function GameTooltip.SetBagItem(self, container, slot)
	GameTooltip.itemLink = GetContainerItemLink(container, slot)
	_, GameTooltip.itemCount = GetContainerItemInfo(container, slot)
	return HookSetBagItem(self, container, slot)
end

local HookSetQuestLogItem = GameTooltip.SetQuestLogItem
function GameTooltip.SetQuestLogItem(self, itemType, index)
	GameTooltip.itemLink = GetQuestLogItemLink(itemType, index)
	if not GameTooltip.itemLink then
		return
	end
	return HookSetQuestLogItem(self, itemType, index)
end

local HookSetQuestItem = GameTooltip.SetQuestItem
function GameTooltip.SetQuestItem(self, itemType, index)
	GameTooltip.itemLink = GetQuestItemLink(itemType, index)
	return HookSetQuestItem(self, itemType, index)
end

local HookSetLootItem = GameTooltip.SetLootItem
function GameTooltip.SetLootItem(self, slot)
	GameTooltip.itemLink = GetLootSlotLink(slot)
	HookSetLootItem(self, slot)
end

local HookSetInventoryItem = GameTooltip.SetInventoryItem
function GameTooltip.SetInventoryItem(self, unit, slot)
	GameTooltip.itemLink = GetInventoryItemLink(unit, slot)
	return HookSetInventoryItem(self, unit, slot)
end
