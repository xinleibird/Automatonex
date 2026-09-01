assert(Automaton, "Automaton not found!")

------------------------------
--      Are you local?      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_Unlock")

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function()
	return {
		["Unlock"] = "自动开锁",
		["Automatically handle lockpicking for rogues"] = "为盗贼自动处理开锁功能",
		["Right-Click Unlock"] = "右键开锁",
		["Right-click locked items in bags to unlock"] = "右键点击背包中的锁定物品进行开锁",
		["Trade Frame Button"] = "交易界面按钮",
		["Add a lockpicking button to the trade window"] = "在交易窗口添加开锁按钮",
	}
end)

L:RegisterTranslations("zhCN", function()
	return {
		["Unlock"] = "自动开锁",
		["Automatically handle lockpicking for rogues"] = "为盗贼自动处理开锁功能",
		["Right-Click Unlock"] = "右键开锁",
		["Right-click locked items in bags to unlock"] = "右键点击背包中的锁定物品进行开锁",
		["Trade Frame Button"] = "交易界面按钮",
		["Add a lockpicking button to the trade window"] = "在交易窗口添加开锁按钮",
	}
end)

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_Unlock = Automaton:NewModule("Unlock")
Automaton_Unlock.modulename = L["Unlock"]
Automaton_Unlock.moduledesc = L["Automatically handle lockpicking for rogues"]
Automaton_Unlock.options = {
	rightClick = {
		type = "toggle",
		name = L["Right-Click Unlock"],
		desc = L["Right-click locked items in bags to unlock"],
		order = 2,
		get = function()
			return Automaton_Unlock.db.profile.rightClick
		end,
		set = function(v)
			Automaton_Unlock.db.profile.rightClick = v
		end,
	},
	tradeFrameButton = {
		type = "toggle",
		name = L["Trade Frame Button"],
		desc = L["Add a lockpicking button to the trade window"],
		order = 3,
		get = function()
			return Automaton_Unlock.db.profile.tradeFrameButton
		end,
		set = function(v)
			Automaton_Unlock.db.profile.tradeFrameButton = v
			if v then
				Automaton_Unlock:CreateTradeFrameButton()
			else
				Automaton_Unlock:HideTradeFrameButton()
			end
		end,
	},
}

------------------------------
--      Initialization      --
------------------------------

-- 辅助函数：获取开锁技能的槽位信息（兼容多版本和多语言）
local function GetLockpickingSpellSlot()
	-- 1. 多语言技能名适配
	local spellName, _, spellId = GetSpellInfo("开锁") -- 中文技能名
	if not spellId then
		spellName, _, spellId = GetSpellInfo("Pick Lock") -- 英文技能名
	end

	-- 验证技能是否存在
	if not spellName or not spellId then
		print("[自动开锁] 未找到开锁技能（可能未学习或技能名不匹配）")
		return nil, nil
	end

	-- 2. 扩大法术书遍历范围（覆盖更多标签页）
	for tab = 1, 8 do -- 从1-4扩展到1-8，兼容更多技能布局
		local _, _, offset, numSpells = GetSpellTabInfo(tab)
		-- 过滤无效的标签页数据
		if offset and numSpells and offset >= 0 and numSpells > 0 then
			for i = offset + 1, offset + numSpells do
				-- 优先通过技能ID匹配（更可靠）
				local _, _, bookSpellId = GetSpellInfo(i, "spell")
				if bookSpellId and bookSpellId == spellId then
					return i, "spell"
				end
				-- 兼容名称匹配（应对特殊情况）
				local bookSpellName = GetSpellName(i, "spell")
				if bookSpellName and bookSpellName == spellName then
					return i, "spell"
				end
			end
		end
	end

	print(
		"[自动开锁] 法术书中未找到开锁技能（技能名："
			.. spellName
			.. "，ID："
			.. tostring(spellId)
			.. "）"
	)
	return nil, nil
end

-- 新增：调试命令注册函数
local function RegisterDebugCommands()
	-- 创建一个全局函数供调试调用（仅用于测试）
	_G["Automaton_Unlock_DebugCheck"] = function()
		local slot, book = GetLockpickingSpellSlot()
		if slot then
			print("[自动开锁调试] 技能位置获取成功：槽位=" .. slot .. ", 类型=" .. book)
			print("[自动开锁调试] 尝试施放开锁技能...")
			CastSpell(slot, book)
		else
			print("[自动开锁调试] 无法获取技能位置")
		end
	end
	-- 提示用户如何使用调试命令
	print("[自动开锁] 调试命令已注册，输入 /run Automaton_Unlock_DebugCheck() 测试技能获取")
end

-- 创建交易界面开锁按钮
function Automaton_Unlock:CreateTradeFrameButton()
	if self.tradeFrameButton then
		return
	end

	-- 检查是否为盗贼
	local isRogue = (self.playerClass.en == "ROGUE") or (self.playerClass.locale == "盗贼")
	if not isRogue then
		return
	end

	-- 创建按钮
	self.tradeFrameButton =
		CreateFrame("Button", "AutomatonTradeFrameLockpickButton", TradeFrame, "UIPanelButtonTemplate")
	self.tradeFrameButton:SetWidth(80)
	self.tradeFrameButton:SetHeight(25)
	self.tradeFrameButton:SetText(L["Unlock"])
	self.tradeFrameButton:SetPoint("TOP", TradeFrameCancelButton, "BOTTOM", 0, -5)

	-- 设置点击事件
	self.tradeFrameButton:SetScript("OnClick", function()
		if not self.spellId then
			self.spellId, self.spellBook = GetLockpickingSpellSlot()
		end
		if self.spellId then
			CastSpell(self.spellId, self.spellBook)
		else
			print("[自动开锁] 无法找到开锁技能")
		end
	end)

	-- 初始显示状态 - 修复：使用 Show() 和 Hide() 而不是 SetShown()
	if self.db.profile.tradeFrameButton then
		self.tradeFrameButton:Show()
	else
		self.tradeFrameButton:Hide()
	end
end

-- 隐藏交易界面按钮
function Automaton_Unlock:HideTradeFrameButton()
	if self.tradeFrameButton then
		self.tradeFrameButton:Hide()
	end
end

function Automaton_Unlock:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("Unlock")
	Automaton:RegisterDefaults("Unlock", "profile", {
		disabled = false,
		rightClick = true,
		tradeFrameButton = true, -- 默认启用交易界面按钮
	})
	Automaton:SetDisabledAsDefault(self, "Unlock")
	self:RegisterOptions(self.options)

	-- 缓存开锁技能信息
	self.spellId, self.spellBook = GetLockpickingSpellSlot()

	-- 获取玩家职业信息
	local classLocale, classEn = UnitClass("player")
	self.playerClass = {
		locale = classLocale,
		en = classEn,
	}

	-- 注册调试命令（仅在盗贼职业时）
	if (self.playerClass.en == "ROGUE") or (self.playerClass.locale == "盗贼") then
		RegisterDebugCommands()
		-- 创建交易界面按钮
		self:CreateTradeFrameButton()
	end
end

function Automaton_Unlock:OnEnable()
	local isRogue = (self.playerClass.en == "ROGUE") or (self.playerClass.locale == "盗贼")
	if isRogue then
		self:Hook("ContainerFrameItemButton_OnClick", "OnBagItemClick")
		-- 显示交易界面按钮（如果已创建）
		if self.tradeFrameButton and self.db.profile.tradeFrameButton then
			self.tradeFrameButton:Show()
		end
	end
end

function Automaton_Unlock:OnDisable()
	self:UnhookAll()
	if _G["LockpickingFrame"] then
		_G["LockpickingFrame"]:Hide()
	end
	-- 隐藏交易界面按钮
	self:HideTradeFrameButton()
end

------------------------------
--      Helper Functions      --
------------------------------

function Automaton_Unlock:OnBagItemClick(button, ignoreShift)
	local isRogue = (self.playerClass.en == "ROGUE") or (self.playerClass.locale == "盗贼")
	if button == "RightButton" and self.db.profile.rightClick and isRogue then
		-- 右键点击时强制刷新技能信息
		self.spellId, self.spellBook = GetLockpickingSpellSlot()

		local bag, slot = this:GetParent():GetID(), this:GetID()
		Automaton.gratuity:SetBagItem(bag, slot)

		-- 模糊匹配锁定状态（兼容"已锁"、"锁定"等描述）
		local lockText = Automaton.gratuity:GetLine(2) or ""
		if self.spellId and string.find(lockText, "锁") and not BankFrame:IsVisible() then
			CastSpell(self.spellId, self.spellBook)
			PickupContainerItem(bag, slot)
			return
		end
	end

	-- 执行原始点击处理
	self.hooks.ContainerFrameItemButton_OnClick(button, ignoreShift)
end
