assert(Automaton, "Automaton not found!")

------------------------------
--      Are you local?      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_ProcDoc")
local compost = AceLibrary("Compost-2.0")

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function()
	return {
		["ProcDoc"] = "技能触发提醒",
		["Tracks and alerts for class-specific procs like Overpower, Riposte, etc."] = "追踪并提醒职业特定的触发效果，如压制、复仇等。",

		-- 选项文本
		["Mute All Proc Sounds"] = "静音所有触发音效",
		["Disable Timers"] = "禁用计时器",
		["Sounds are now muted."] = "音效已静音。",
		["Sounds are now unmuted."] = "音效已取消静音。",
		["Timers disabled."] = "计时器已禁用。",
		["Timers enabled."] = "计时器已启用。",

		-- 职业名称
		["WARLOCK"] = "术士",
		["MAGE"] = "法师",
		["DRUID"] = "德鲁伊",
		["SHAMAN"] = "萨满祭司",
		["HUNTER"] = "猎人",
		["WARRIOR"] = "战士",
		["PRIEST"] = "牧师",
		["PALADIN"] = "圣骑士",
		["ROGUE"] = "潜行者",

		-- 触发效果名称
		["Riposte"] = "还击",
		["Surprise Attack"] = "突袭",
		["Overpower"] = "压制",
		["Execute"] = "斩杀",
		["Revenge"] = "复仇",
		["Arcane Surge"] = "奥术涌动",
		["Lacerate"] = "割伤",
		["Kill Command"] = "杀戮命令",
		["Baited Shot"] = "诱饵射击",
		["Hammer of Wrath"] = "愤怒之锤",
		["Judgement"] = "审判",
		["Hammer of Justice"] = "制裁之锤",
	}
end)

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_ProcDoc = Automaton:NewModule("ProcDoc")
Automaton_ProcDoc.modulename = L["ProcDoc"]
Automaton_ProcDoc.moduledesc = L["Tracks and alerts for class-specific procs like Overpower, Riposte, etc."]

-- 动作触发效果数据表
local ACTION_PROCS = {
	["ROGUE"] = {
		{
			buffName = L["Riposte"],
			texture = "Interface\\Icons\\Ability_Warrior_Challange",
			alertStyle = "SIDES",
			spellName = "Riposte",
			duration = 5,
		},
		{
			buffName = L["Surprise Attack"],
			texture = "Interface\\Icons\\Ability_Rogue_SurpriseAttack",
			alertStyle = "SIDES2",
			spellName = "Surprise Attack",
			duration = 5,
		},
	},
	["WARRIOR"] = {
		{
			buffName = L["Overpower"],
			texture = "Interface\\Icons\\Ability_MeleeDamage",
			alertStyle = "TOP",
			spellName = "Overpower",
			duration = 5,
		},
		{
			buffName = L["Execute"],
			texture = "Interface\\Icons\\inv_sword_48",
			alertStyle = "TOP2",
			spellName = "Execute",
			duration = 5,
		},
		{
			buffName = L["Revenge"],
			texture = "Interface\\Icons\\Ability_Warrior_Revenge",
			alertStyle = "RIGHT",
			spellName = "Revenge",
			duration = 5,
		},
	},
	["MAGE"] = {
		{
			buffName = L["Arcane Surge"],
			texture = "Interface\\Icons\\INV_Enchant_EssenceMysticalLarge",
			alertStyle = "TOP2",
			spellName = "Arcane Surge",
			duration = 4,
		},
	},
	["HUNTER"] = {
		{
			buffName = L["Lacerate"],
			texture = "Interface\\Icons\\Spell_Lacerate_1c",
			alertStyle = "SIDES2",
			spellName = "Lacerate",
			duration = 4,
		},
		{
			buffName = L["Kill Command"],
			texture = "Interface\\Icons\\Ability_Hunter_KillCommand",
			alertStyle = "TOP",
			spellName = "Kill Command",
			duration = 5,
		},
		{
			buffName = L["Baited Shot"],
			texture = "Interface\\Icons\\Inv_Misc_Food_66",
			alertStyle = "TOP",
			spellName = "Baited Shot",
			duration = 4,
		},
	},
	["PALADIN"] = {
		{
			buffName = L["Hammer of Wrath"],
			texture = "Interface\\Icons\\Ability_Thunderclap",
			alertStyle = "SIDES",
			spellName = "Hammer of Wrath",
			duration = 5,
		},
		{
			buffName = L["Judgement"],
			texture = "Interface\\Icons\\Spell_Holy_RighteousFury",
			alertStyle = "RIGHT",
			spellName = "Judgement",
			duration = 30,
		},
		{
			buffName = L["Hammer of Justice"],
			texture = "Interface\\Icons\\Spell_Holy_SealOfMight",
			alertStyle = "LEFT",
			spellName = "Hammer of Justice",
			useSpellbook = true,
			duration = 5,
		},
	},
}

-- 模块变量
local alertFrames = {}
local actionProcStates = {}
local timerFrame

------------------------------
--      Initialization      --
------------------------------

function Automaton_ProcDoc:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("ProcDoc")
	Automaton:RegisterDefaults("ProcDoc", "profile", {
		disabled = false,
		sound = false,
		disableTimers = false,
		alertPositions = {}, -- 各警报样式(样式名)的拖动位置
	})
	Automaton:SetDisabledAsDefault(self, "ProcDoc")
	-- 新增：注册配置选项到主界面
	self:RegisterOptions(self.options)
end

function Automaton_ProcDoc:OnEnable()
	self:InitializeDatabase()
	self:CreateAlertSystem()
	self:RegisterEvents()

	-- 加载消息
	local _, playerClass = UnitClass("player")
	DEFAULT_CHAT_FRAME:AddMessage(
		"|cff00ff00Automaton-ProcDoc|r: 已加载，正在追踪 |cffffffff"
			.. L[playerClass]
			.. "|r 的触发效果。"
	)
end

function Automaton_ProcDoc:OnDisable()
	self:UnregisterAllEvents()
	self:HideAllAlerts()
	if timerFrame then
		timerFrame:Hide()
	end
end

-- 选项配置
Automaton_ProcDoc.options = {
	sound = {
		type = "toggle",
		name = L["Mute All Proc Sounds"],
		desc = "启用或禁用触发音效",
		order = 1,
		get = function()
			return not Automaton_ProcDoc.db.profile.sound
		end,
		set = function(v)
			Automaton_ProcDoc.db.profile.sound = not v
			if v then
				DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFFProcDoc|r: " .. L["Sounds are now muted."])
			else
				DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFFProcDoc|r: " .. L["Sounds are now unmuted."])
			end
		end,
	},
	disableTimers = {
		type = "toggle",
		name = L["Disable Timers"],
		desc = "启用或禁用计时器显示",
		order = 2,
		get = function()
			return Automaton_ProcDoc.db.profile.disableTimers
		end,
		set = function(v)
			Automaton_ProcDoc.db.profile.disableTimers = v
			if v then
				DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFFProcDoc|r: " .. L["Timers disabled."])
			else
				DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFFProcDoc|r: " .. L["Timers enabled."])
			end
		end,
	},
}

------------------------------
--      Core Functions      --
------------------------------

function Automaton_ProcDoc:InitializeDatabase()
	if not self.db.profile.procsEnabled then
		self.db.profile.procsEnabled = {}
	end
end

function Automaton_ProcDoc:CreateAlertSystem()
	-- 创建计时器更新帧
	-- 除每帧刷新倒计时外，每 0.25 秒轮询一次技能可用性，
	-- 保证「触发后且可用期间持续提醒」不依赖事件触发频率
	-- （1.12 的 OnUpdate 回调不传 self，elapsed 用 arg1 取）
	timerFrame = CreateFrame("Frame")
	local lastCheck = 0
	timerFrame:SetScript("OnUpdate", function()
		Automaton_ProcDoc:UpdateAllTimers()
		lastCheck = lastCheck + (arg1 or 0)
		if lastCheck >= 0.25 then
			lastCheck = 0
			Automaton_ProcDoc:CheckAllActionProcs()
			Automaton_ProcDoc:UpdateSpellbookActionProcs()
		end
	end)
end

function Automaton_ProcDoc:RegisterEvents()
	self:RegisterEvent("PLAYER_LOGIN")
	self:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
	self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
	self:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end

-- 警报帧管理
local function CreateAlertFrame(style)
	local alertObj = {}
	alertObj.isActive = false
	alertObj.isActionBased = false
	alertObj.style = style
	alertObj.textures = {}
	alertObj.timers = {}

	alertObj.baseWidth = 40
	alertObj.baseHeight = 40

	-- 可拖动锚点框：图标/倒计时挂在它上面，左键拖动移动位置
	-- 仅在警报激活时 Show，避免平时拦住鼠标点击
	local anchor = CreateFrame("Frame", nil, UIParent)
	anchor:SetWidth(alertObj.baseWidth)
	anchor:SetHeight(alertObj.baseHeight)
	anchor:SetMovable(true)
	anchor:EnableMouse(true)
	anchor:RegisterForDrag("LeftButton")
	anchor:SetFrameStrata("HIGH")
	anchor:Hide()
	alertObj.anchor = anchor

	-- 恢复该样式的已保存位置
	local positions = Automaton_ProcDoc.db.profile.alertPositions
	if positions and positions[style] then
		local pos = positions[style]
		anchor:ClearAllPoints()
		anchor:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOfs, pos.yOfs)
	else
		anchor:SetPoint("CENTER", UIParent, "CENTER", 211, 0)
	end

	anchor:SetScript("OnDragStart", function()
		anchor:StartMoving()
	end)
	anchor:SetScript("OnDragStop", function()
		anchor:StopMovingOrSizing()
		local point, _, relativePoint, xOfs, yOfs = anchor:GetPoint()
		local saved = Automaton_ProcDoc.db.profile.alertPositions
		if not saved then
			saved = {}
			Automaton_ProcDoc.db.profile.alertPositions = saved
		end
		saved[style] = {
			point = point,
			relativePoint = relativePoint,
			xOfs = xOfs,
			yOfs = yOfs,
		}
	end)

	local tex = anchor:CreateTexture(nil, "OVERLAY")
	tex:SetPoint("CENTER", anchor, "CENTER", 0, 0)
	tex:SetWidth(alertObj.baseWidth)
	tex:SetHeight(alertObj.baseHeight)
	tex:SetAlpha(0.8)
	tex:Hide()
	table.insert(alertObj.textures, tex)

	-- 创建计时器文本
	local timerText = anchor:CreateFontString(nil, "OVERLAY")
	timerText:SetPoint("CENTER", tex, "CENTER", 0, 0)
	timerText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
	timerText:SetTextColor(1, 1, 1, 1)
	timerText:SetJustifyH("CENTER")
	timerText:SetJustifyV("MIDDLE")
	timerText:Hide()
	table.insert(alertObj.timers, timerText)

	return alertObj
end

local function AcquireAlertFrame(style, isActionBased)
	for _, alertObj in ipairs(alertFrames) do
		if (not alertObj.isActive) and (alertObj.style == style) and (alertObj.isActionBased == isActionBased) then
			return alertObj
		end
	end
	local newAlert = CreateAlertFrame(style)
	newAlert.isActionBased = isActionBased
	table.insert(alertFrames, newAlert)
	return newAlert
end

-- 计时器显示
function Automaton_ProcDoc:UpdateTimerDisplay(alertObj, remainingTime)
	if self.db.profile.disableTimers then
		for _, timer in ipairs(alertObj.timers) do
			timer:Hide()
		end
		return
	end

	for _, timer in ipairs(alertObj.timers) do
		if remainingTime > 0 then
			timer:SetText(string.format("%.1f", remainingTime))
			timer:Show()

			-- 根据剩余时间改变颜色
			if remainingTime < 3 then
				timer:SetTextColor(1, 0.2, 0.2) -- 红色
			elseif remainingTime < 6 then
				timer:SetTextColor(1, 1, 0.2) -- 黄色
			else
				timer:SetTextColor(1, 1, 1) -- 白色
			end
		else
			timer:Hide()
		end
	end
end

-- 显示触发警报
function Automaton_ProcDoc:ShowActionProcAlert(actionProc)
	local spellName = actionProc.spellName or "UnknownSpell"
	local state = actionProcStates[spellName] or {}
	actionProcStates[spellName] = state

	local alertObj = state.alertObj
	if alertObj and alertObj.isActive then
		return
	end

	alertObj = AcquireAlertFrame(actionProc.alertStyle or "SIDES", true)
	alertObj.isActive = true
	alertObj.anchor:Show() -- 激活期间可拖动

	local path = actionProc.texture
	for _, tex in ipairs(alertObj.textures) do
		tex:SetTexture(path)
		tex:SetAlpha(0.8)
		tex:SetWidth(alertObj.baseWidth)
		tex:SetHeight(alertObj.baseHeight)
		tex:Show()
	end

	-- 播放音效
	if self.db.profile.sound then
		PlaySoundFile("Interface\\AddOns\\Automatonex\\Sound\\SpellAlert.ogg", "SFX")
	end

	state.alertObj = alertObj
	state.startTime = GetTime()
	state.duration = actionProc.duration or 5
	state.isActive = true
end

function Automaton_ProcDoc:HideActionProcAlert(actionProc)
	local spellName = actionProc.spellName or "UnknownSpell"
	local state = actionProcStates[spellName]
	if not state or not state.isActive then
		return
	end

	local alertObj = state.alertObj
	if alertObj and alertObj.isActive then
		alertObj.isActive = false
		if alertObj.anchor then
			alertObj.anchor:Hide()
		end
		for _, tex in ipairs(alertObj.textures) do
			tex:Hide()
		end
		for _, timer in ipairs(alertObj.timers) do
			timer:Hide()
		end
	end
	state.isActive = false
	state.startTime = nil
end

function Automaton_ProcDoc:HideAllAlerts()
	for _, alertObj in ipairs(alertFrames) do
		if alertObj.isActive then
			alertObj.isActive = false
			if alertObj.anchor then
				alertObj.anchor:Hide()
			end
			for _, tex in ipairs(alertObj.textures) do
				tex:Hide()
			end
			for _, timer in ipairs(alertObj.timers) do
				timer:Hide()
			end
		end
	end
	actionProcStates = {}
end

-- 计时器更新
-- 注意：不再按 duration 到点自动隐藏警报。
-- 警报的隐藏只由「技能不可用 / 进CD / 施放成功」驱动（FindActionSlotAndCheck、
-- UpdateSpellbookActionProcs、UNIT_SPELLCAST_SUCCEEDED），这样只要技能
-- 处于触发后且可用状态，图标会一直显示（倒计时归 0 后仅隐藏数字）。
function Automaton_ProcDoc:UpdateAllTimers()
	for spellName, state in pairs(actionProcStates) do
		if state.isActive and state.startTime and state.alertObj and state.alertObj.isActive then
			local elapsed = GetTime() - state.startTime
			local remaining = state.duration - elapsed
			self:UpdateTimerDisplay(state.alertObj, remaining)
		end
	end
end

-- 法术书查找
local function FindSpellBookIndexByName(spellName)
	if not spellName then
		return nil
	end
	local numTabs = GetNumSpellTabs and GetNumSpellTabs() or 0
	for t = 1, numTabs do
		local _, _, offset, numSpells = GetSpellTabInfo(t)
		if offset and numSpells then
			for i = offset + 1, offset + numSpells do
				local sName = GetSpellName(i, BOOKTYPE_SPELL or "spell")
				if sName == spellName then
					return i
				end
			end
		end
	end
	return nil
end

-- 动作栏查找
local function FindActionSlotAndCheck(actionProc)
	local spellName = actionProc.spellName or "UnknownSpell"
	local texPath = actionProc.texture or ""
	if texPath == "" then
		return
	end

	local foundSlot = nil
	for slot = 1, 120 do
		local actionTex = GetActionTexture(slot)
		if actionTex then
			local lowerActionTex = string.lower(actionTex)
			local lowerWanted = string.lower(texPath)
			if lowerActionTex == lowerWanted then
				foundSlot = slot
				break
			end
		end
	end

	local state = actionProcStates[spellName] or {}
	actionProcStates[spellName] = state

	state.slot = foundSlot
	if not foundSlot then
		if state.isActive then
			Automaton_ProcDoc:HideActionProcAlert(actionProc)
		end
		return
	end

	local usable = IsUsableAction(foundSlot)

	-- 1.12 的 IsUsableAction 不检查技能冷却，需用 GetActionCooldown 单独判断
	-- 否则"审判"等技能触发后即使 CD 中仍会误报
	local cdStart, cdDuration = GetActionCooldown(foundSlot)
	local offCooldown = (cdDuration == nil) or (cdDuration == 0)

	if usable and offCooldown then
		if not state.isActive then
			Automaton_ProcDoc:ShowActionProcAlert(actionProc)
		end
	else
		if state.isActive then
			Automaton_ProcDoc:HideActionProcAlert(actionProc)
		end
	end
end

-- 检查所有动作触发
function Automaton_ProcDoc:CheckAllActionProcs()
	local _, playerClass = UnitClass("player")
	local actionProcs = ACTION_PROCS[playerClass] or {}

	for _, actionProc in ipairs(actionProcs) do
		if not actionProc.useSpellbook then
			FindActionSlotAndCheck(actionProc)
		end
	end
end

-- 法术书驱动的触发检查
function Automaton_ProcDoc:UpdateSpellbookActionProcs()
	local _, playerClass = UnitClass("player")
	local actionProcs = ACTION_PROCS[playerClass] or {}

	for _, actionProc in ipairs(actionProcs) do
		if actionProc.useSpellbook then
			local inCombat = (UnitAffectingCombat and UnitAffectingCombat("player"))
			if not inCombat then
				self:HideActionProcAlert(actionProc)
			else
				local idx = FindSpellBookIndexByName(actionProc.spellName)
				if idx then
					local start, duration, enable = GetSpellCooldown(idx, BOOKTYPE_SPELL or "spell")
					local ready = (duration == 0)
					if ready then
						self:ShowActionProcAlert(actionProc)
					else
						self:HideActionProcAlert(actionProc)
					end
				else
					self:HideActionProcAlert(actionProc)
				end
			end
		end
	end
end

------------------------------
--      Event Handlers      --
------------------------------

function Automaton_ProcDoc:PLAYER_LOGIN()
	self:CheckAllActionProcs()
	self:UpdateSpellbookActionProcs()
end

function Automaton_ProcDoc:ACTIONBAR_PAGE_CHANGED()
	self:CheckAllActionProcs()
	self:UpdateSpellbookActionProcs()
end

function Automaton_ProcDoc:ACTIONBAR_UPDATE_USABLE()
	self:CheckAllActionProcs()
	self:UpdateSpellbookActionProcs()
end

function Automaton_ProcDoc:ACTIONBAR_UPDATE_COOLDOWN()
	self:CheckAllActionProcs()
	self:UpdateSpellbookActionProcs()
end

function Automaton_ProcDoc:PLAYER_REGEN_DISABLED()
	self:CheckAllActionProcs()
	self:UpdateSpellbookActionProcs()
end

function Automaton_ProcDoc:PLAYER_REGEN_ENABLED()
	self:CheckAllActionProcs()
	self:UpdateSpellbookActionProcs()
end

function Automaton_ProcDoc:UNIT_SPELLCAST_SUCCEEDED()
	local _, playerClass = UnitClass("player")
	local actionProcs = ACTION_PROCS[playerClass] or {}

	for _, actionProc in ipairs(actionProcs) do
		if arg1 == "player" and (arg2 == actionProc.spellName) then
			self:HideActionProcAlert(actionProc)
		end
	end
	self:CheckAllActionProcs()
	self:UpdateSpellbookActionProcs()
end
