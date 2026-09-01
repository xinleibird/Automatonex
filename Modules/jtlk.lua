-- 配置变量
local debuffName = "军团镣铐" -- DEBUFF名称
local debuffNameEN = "Shackles of the Legion" -- DEBUFF英文名称
local DEBUG = false -- 调试模式开关

assert(Automaton, "Automaton not found!")

------------------------------
--      Localization      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_LegionShackles")

L:RegisterTranslations("zhCN", function()
	return {
		["LegionShackles"] = "自动禁止移动",
		["Automatically disable movement keys when affected by Legion Shackles"] = "当受到军团镣铐效果时自动禁用移动按键",
		["Debug Mode"] = "调试模式",
		["Toggle debug mode"] = "切换调试模式",
	}
end)

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_LegionShackles = Automaton:NewModule("LegionShackles")
Automaton_LegionShackles.modulename = L["LegionShackles"]
Automaton_LegionShackles.moduledesc = L["Automatically disable movement keys when affected by Legion Shackles"]
Automaton_LegionShackles.options = {
	debugMode = {
		type = "toggle",
		name = L["Debug Mode"],
		desc = L["Toggle debug mode"],
		get = function()
			return Automaton_LegionShackles.db.profile.debugMode
		end,
		set = function(v)
			Automaton_LegionShackles.db.profile.debugMode = v
			DEBUG = v
		end,
	},
}

------------------------------
--      Initialization      --
------------------------------

-- 定义允许触发的区域
Automaton_LegionShackles.zonename = {
	"荒芜巨岩",
	-- 英文名称作为备用
	"Tower of Karazhan",
}

function Automaton_LegionShackles:OnInitialize()
	-- 初始化数据库
	self.db = Automaton:AcquireDBNamespace("LegionShackles")
	Automaton:RegisterDefaults("LegionShackles", "profile", {
		disabled = false, -- 默认启用
		debugMode = false, -- 调试模式默认关闭
	})
	Automaton:SetDisabledAsDefault(self, "LegionShackles")
	self:RegisterOptions(self.options)

	-- 同步全局变量
	DEBUG = self.db.profile.debugMode

	-- 创建提示窗口
	self:CreateAlertFrame()

	-- 注册命令
	self:RegisterSlashCommands()

	-- 当前区域变量
	self.currentZone = nil
	self.isInAllowedZone = false

	-- 存储玩家当前的移动按键绑定
	self.originalBindings = {}
end

function Automaton_LegionShackles:OnEnable()
	-- 模块启用时的初始化操作
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF")
	self:RegisterEvent("PLAYER_DEAD")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")

	-- 初始化区域状态
	self:UpdateZoneStatus()

	-- 保存当前的移动按键绑定
	self:SaveCurrentMovementBindings()

	DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[军团镣铐]|r |cFF00FF00<<< 模块已启用！>>>|r")
	DEFAULT_CHAT_FRAME:AddMessage(
		"|cFF00FF00[军团镣铐]|r |cFFFFFF00当前区域: " .. (self.currentZone or "未知") .. "|r"
	)
	DEFAULT_CHAT_FRAME:AddMessage(
		"|cFF00FF00[军团镣铐]|r |cFFFFFF00允许触发: "
			.. (self.isInAllowedZone and "|cFF00FF00是|r" or "|cFFFF0000否|r")
	)
	PlaySound("igQuestListOpen")
end

function Automaton_LegionShackles:OnDisable()
	-- 模块禁用时的清理操作
	self:UnregisterAllEvents()
	if self.alertFrame then
		self.alertFrame:Hide()
	end

	-- 确保模块禁用时恢复按键绑定
	self:RestoreMovementKeys()

	DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[军团镣铐]|r |cFFFF0000<<< 模块已禁用！>>>|r")
	PlaySound("igQuestFailed")
end

------------------------------
--      Zone Management    --
------------------------------

-- 更新区域状态
function Automaton_LegionShackles:UpdateZoneStatus()
	self.currentZone = GetRealZoneText() or GetZoneText()
	self.isInAllowedZone = self:IsZoneAllowed(self.currentZone)

	self:DebugMessage(
		"区域更新: "
			.. (self.currentZone or "未知")
			.. " - 允许触发: "
			.. (self.isInAllowedZone and "是" or "否")
	)
end

-- 检查区域是否在允许列表中
function Automaton_LegionShackles:IsZoneAllowed(zoneName)
	if not zoneName then
		return false
	end

	for _, allowedZone in ipairs(self.zonename) do
		if zoneName == allowedZone then
			return true
		end
	end
	return false
end

-- 区域改变事件处理
function Automaton_LegionShackles:ZONE_CHANGED_NEW_AREA()
	self:ScheduleEvent(function()
		self:UpdateZoneStatus()
		if self.isInAllowedZone then
			self:ShowAlert("进入允许区域: " .. self.currentZone, 3)
		end
	end, 1) -- 延迟1秒确保区域信息已更新
end

function Automaton_LegionShackles:PLAYER_ENTERING_WORLD()
	self:ScheduleEvent(function()
		self:UpdateZoneStatus()
	end, 1)
end

------------------------------
--      UI Creation        --
------------------------------

function Automaton_LegionShackles:CreateAlertFrame()
	-- 创建提示窗口
	self.alertFrame = CreateFrame("Frame", "LegionShacklesAlert", UIParent)
	self.alertFrame:SetWidth(400)
	self.alertFrame:SetHeight(60)
	self.alertFrame:SetPoint("CENTER", 0, 150)
	self.alertFrame:Hide()

	-- 创建背景
	self.alertFrame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = nil,
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = { left = 11, right = 12, top = 12, bottom = 11 },
	})
	self.alertFrame:SetBackdropColor(0, 0, 0, 0.9)

	-- 创建文本
	self.alertFrame.text = self.alertFrame:CreateFontString(nil, "OVERLAY")
	self.alertFrame.text:SetFontObject(GameFontNormalLarge)
	self.alertFrame.text:SetPoint("CENTER", self.alertFrame, "CENTER")
	self.alertFrame.text:SetTextColor(1, 0.2, 0.2) -- 红色文字
	self.alertFrame.text:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")

	-- 提示框闪烁效果
	self.alertFrame.timeLeft = 0
	self.alertFrame.flashTimer = 0
	self.alertFrame.flashState = true
	self.alertFrame:SetScript("OnUpdate", function()
		if not this:IsVisible() then
			return
		end

		-- 倒计时
		this.timeLeft = this.timeLeft - arg1
		if this.timeLeft <= 0 then
			this:Hide()
			return
		end

		-- 闪烁效果
		this.flashTimer = this.flashTimer + arg1
		if this.flashTimer >= 0.5 then
			this.flashTimer = 0
			this.flashState = not this.flashState
			if this.flashState then
				this.text:SetTextColor(1, 0.2, 0.2) -- 红色
			else
				this.text:SetTextColor(1, 1, 0.2) -- 黄色
			end
		end
	end)
end

------------------------------
--      Core Functions      --
------------------------------

-- 保存当前移动按键绑定
function Automaton_LegionShackles:SaveCurrentMovementBindings()
	self.originalBindings["W"] = GetBindingAction("W")
	self.originalBindings["S"] = GetBindingAction("S")
	self.originalBindings["A"] = GetBindingAction("A")
	self.originalBindings["D"] = GetBindingAction("D")
	self.originalBindings["SPACE"] = GetBindingAction("SPACE")

	self:DebugMessage("保存移动按键绑定:")
	self:DebugMessage("  W: " .. (self.originalBindings["W"] or "无"))
	self:DebugMessage("  S: " .. (self.originalBindings["S"] or "无"))
	self:DebugMessage("  A: " .. (self.originalBindings["A"] or "无"))
	self:DebugMessage("  D: " .. (self.originalBindings["D"] or "无"))
	self:DebugMessage("  SPACE: " .. (self.originalBindings["SPACE"] or "无"))
end

-- 命令处理函数
function Automaton_LegionShackles:ShacklesCommand(msg)
	msg = string.lower(msg or "")
	if msg == "help" or msg == "?" then
		DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[军团镣铐]|r |cFFFFFF00命令使用说明：|r")
		DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00>>> |r |cFFFFFF00/shackles debug - 切换调试模式|r")
		DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00>>> |r |cFFFFFF00/shackles zone - 显示当前区域状态|r")
		DEFAULT_CHAT_FRAME:AddMessage(
			"|cFF00FF00>>> |r |cFFFFFF00/shackles bindings - 显示当前移动按键绑定|r"
		)
		DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00>>> |r |cFFFFFF00/shackles help - 显示帮助信息|r")
		DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00注意：主要功能通过Automaton配置界面启用/禁用|r")
	elseif msg == "debug" then
		self.db.profile.debugMode = not self.db.profile.debugMode
		DEBUG = self.db.profile.debugMode
		DEFAULT_CHAT_FRAME:AddMessage(
			"|cFF00FF00[军团镣铐]|r |cFFFFFF00调试模式: "
				.. (DEBUG and "|cFF00FF00已开启|r" or "|cFFFF0000已关闭|r")
		)
		PlaySound("igMainMenuOption")
	elseif msg == "zone" or msg == "区域" then
		self:UpdateZoneStatus()
		DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[军团镣铐]|r |cFFFFFF00区域信息：|r")
		DEFAULT_CHAT_FRAME:AddMessage(
			"|cFF00FF00>>> |r |cFFFFFF00当前区域: " .. (self.currentZone or "未知") .. "|r"
		)
		DEFAULT_CHAT_FRAME:AddMessage(
			"|cFF00FF00>>> |r |cFFFFFF00允许触发: "
				.. (self.isInAllowedZone and "|cFF00FF00是|r" or "|cFFFF0000否|r")
		)
		DEFAULT_CHAT_FRAME:AddMessage(
			"|cFF00FF00>>> |r |cFFFFFF00模块状态: "
				.. (self:IsEnabled() and "|cFF00FF00已启用|r" or "|cFFFF0000已禁用|r")
		)
	elseif msg == "bindings" or msg == "绑定" then
		self:SaveCurrentMovementBindings()
		DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[军团镣铐]|r |cFFFFFF00当前移动按键绑定：|r")
		DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00>>> |r |cFFFFFF00W: " .. (self.originalBindings["W"] or "无") .. "|r")
		DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00>>> |r |cFFFFFF00S: " .. (self.originalBindings["S"] or "无") .. "|r")
		DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00>>> |r |cFFFFFF00A: " .. (self.originalBindings["A"] or "无") .. "|r")
		DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00>>> |r |cFFFFFF00D: " .. (self.originalBindings["D"] or "无") .. "|r")
		DEFAULT_CHAT_FRAME:AddMessage(
			"|cFF00FF00>>> |r |cFFFFFF00SPACE: " .. (self.originalBindings["SPACE"] or "无") .. "|r"
		)
	else
		DEFAULT_CHAT_FRAME:AddMessage(
			"|cFF00FF00[军团镣铐]|r |cFFFFFF00模块状态: "
				.. (Automaton:IsModuleActive("LegionShackles") and "|cFF00FF00已启用|r" or "|cFFFF0000已禁用|r")
		)
		DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00使用 /automaton 配置界面来启用/禁用此功能|r")
		DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00使用 /shackles zone 查看当前区域状态|r")
		DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00使用 /shackles bindings 查看当前移动按键绑定|r")
	end
end

-- 注册斜杠命令
function Automaton_LegionShackles:RegisterSlashCommands()
	SlashCmdList["LEGIONSHACKLES"] = function(msg)
		self:ShacklesCommand(msg)
	end
	SLASH_LEGIONSHACKLES1 = "/shackles"
	SLASH_LEGIONSHACKLES2 = "/jtlk"
	SLASH_LEGIONSHACKLES3 = "/镣铐"
end

-- 调试信息函数
function Automaton_LegionShackles:DebugMessage(msg)
	if DEBUG then
		DEFAULT_CHAT_FRAME:AddMessage("|cFFFF9900[军团镣铐调试]|r |cFFFFFF00" .. msg .. "|r")
	end
end

-- 显示警告信息
function Automaton_LegionShackles:ShowAlert(msg, duration)
	if self.alertFrame then
		self.alertFrame.text:SetText(msg)
		self.alertFrame.timeLeft = duration or 3
		self.alertFrame.flashTimer = 0
		self.alertFrame.flashState = true
		self.alertFrame:Show()
		PlaySound("RAID_WARNING")
	end
end

-- 禁用移动按键
function Automaton_LegionShackles:DisableMovementKeys()
	if not self.isInAllowedZone then
		self:DebugMessage("不在允许区域，跳过禁用移动按键")
		return
	end

	-- 保存当前绑定状态（以防在模块启用后有变化）
	self:SaveCurrentMovementBindings()

	self:DebugMessage("禁用移动按键")

	-- 禁用所有移动相关的按键，无论它们绑定到什么功能
	SetBinding("W")
	SetBinding("S")
	SetBinding("A")
	SetBinding("D")
	SetBinding("SPACE")
	SaveBindings(2) -- 保存到角色专用绑定

	self:ShowAlert("军团镣铐效果！移动按键已禁用", 3)
end

-- 恢复移动按键
function Automaton_LegionShackles:RestoreMovementKeys()
	self:DebugMessage("恢复移动按键")

	-- 恢复原始绑定
	if self.originalBindings["W"] then
		SetBinding("W", self.originalBindings["W"])
	else
		SetBinding("W", "MOVEFORWARD") -- 默认值
	end

	if self.originalBindings["S"] then
		SetBinding("S", self.originalBindings["S"])
	else
		SetBinding("S", "MOVEBACKWARD") -- 默认值
	end

	if self.originalBindings["A"] then
		SetBinding("A", self.originalBindings["A"])
	else
		SetBinding("A", "STRAFELEFT") -- 默认值
	end

	if self.originalBindings["D"] then
		SetBinding("D", self.originalBindings["D"])
	else
		SetBinding("D", "STRAFERIGHT") -- 默认值
	end

	if self.originalBindings["SPACE"] then
		SetBinding("SPACE", self.originalBindings["SPACE"])
	else
		SetBinding("SPACE", "JUMP") -- 默认值
	end

	SaveBindings(2) -- 保存到角色专用绑定

	self:ShowAlert("移动按键已恢复", 2)
end

-- 检查消息中是否包含指定的debuff名称
function Automaton_LegionShackles:CheckMessageForDebuff(message)
	if string.find(message, debuffName) or string.find(message, debuffNameEN) then
		self:DebugMessage("检测到军团镣铐相关消息: " .. message)
		return true
	end
	return false
end

------------------------------
--      Event Handlers      --
------------------------------

function Automaton_LegionShackles:CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE()
	if not self.isInAllowedZone then
		self:DebugMessage("不在允许区域，忽略军团镣铐事件")
		return
	end

	if self:CheckMessageForDebuff(arg1) then
		self:DebugMessage("检测到军团镣铐效果，禁用移动按键")
		self:DisableMovementKeys()
	end
end

function Automaton_LegionShackles:CHAT_MSG_SPELL_AURA_GONE_SELF()
	if not self.isInAllowedZone then
		return
	end

	if self:CheckMessageForDebuff(arg1) then
		self:DebugMessage("军团镣铐效果消失，恢复移动按键")
		self:RestoreMovementKeys()
	end
end

function Automaton_LegionShackles:PLAYER_DEAD()
	-- 仅在允许区域内恢复移动按键
	if not self.isInAllowedZone then
		self:DebugMessage("不在允许区域，死亡时不恢复移动按键")
		return
	end

	self:DebugMessage("玩家死亡，恢复移动按键")
	self:RestoreMovementKeys()
end
