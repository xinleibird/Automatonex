assert(Automaton, "Automaton not found!")

------------------------------
--      Localization      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_RangeController")

L:RegisterTranslations("zhCN", function()
	return {
		["RangeController"] = "战斗记录范围控制器",
		["Set combat log recording range"] = "设置战斗记录收集范围，控制战斗记录的收集距离，小退后会重置",
		["Range Value"] = "范围值",
		["Set the combat log recording range (0-200)"] = "设置战斗记录范围值 (0-200)",
		["Apply Range"] = "应用范围",
		["Apply the selected range value"] = "应用选中的范围值",
	}
end)

----------------------------------
--      Module Declaration      --
----------------------------------

Automaton_RangeController = Automaton:NewModule("RangeController")
Automaton_RangeController.modulename = L["RangeController"]
Automaton_RangeController.moduledesc = L["Set combat log recording range"]
Automaton_RangeController.options = {
	rangeValue = {
		type = "range",
		name = L["Range Value"],
		desc = L["Set the combat log recording range (0-200)"],
		order = 2,
		get = function()
			-- 从当前值读取，而不是数据库
			return Automaton_RangeController.currentRange or 150
		end,
		set = function(v)
			-- 只设置当前值，不保存到数据库
			Automaton_RangeController.currentRange = v
		end,
		min = 0,
		max = 200,
		step = 5,
		bigStep = 10,
	},
	applyRange = {
		type = "execute",
		name = L["Apply Range"],
		desc = L["Apply the selected range value"],
		order = 3,
		func = function()
			Automaton_RangeController:ApplyRangeSettings()
		end,
	},
	enabled = {
		type = "toggle",
		name = "启用模块",
		desc = "启用/禁用战斗记录范围控制器",
		get = function()
			return not Automaton_RangeController.db.profile.disabled
		end,
		set = function(v)
			Automaton_RangeController.db.profile.disabled = not v
			if v then
				Automaton_RangeController:OnEnable()
			else
				Automaton_RangeController:OnDisable()
			end
		end,
	},
}

------------------------------
--      Initialization      --
------------------------------

function Automaton_RangeController:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("RangeController")
	Automaton:RegisterDefaults("RangeController", "profile", {
		disabled = false,
		-- 移除rangeValue的默认值设置，因为它不再保存
	})
	Automaton:SetDisabledAsDefault(self, "RangeController")
	self:RegisterOptions(self.options)

	-- 初始化当前范围为默认值150
	self.currentRange = 150

	-- 注册斜杠命令
	self:RegisterSlashCommands()
end

function Automaton_RangeController:OnEnable()
	-- 初始化GUI界面
	self:InitGUI()
end

function Automaton_RangeController:OnDisable()
	-- 隐藏GUI界面
	if self.GUI then
		self.GUI:Hide()
	end
end

--########### RangeController
--########### By Automaton Module

function Automaton_RangeController:InitGUI()
	-- 创建GUI框架
	self.GUI = CreateFrame("Frame", "AutomatonRangeControllerGUI", UIParent)
	self.GUI:SetFrameStrata("BACKGROUND")
	self.GUI:SetWidth(300)
	self.GUI:SetHeight(150)
	self.GUI:SetPoint("CENTER", 0, 0)
	self.GUI:SetMovable(true)
	self.GUI:EnableMouse(true)
	self.GUI:RegisterForDrag("LeftButton")
	self.GUI:SetScript("OnDragStart", function()
		self.GUI:StartMoving()
	end)
	self.GUI:SetScript("OnDragStop", function()
		self.GUI:StopMovingOrSizing()
	end)

	-- 背景框
	local backdrop = {
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		tile = false,
		tileSize = 8,
		edgeSize = 8,
		insets = {
			left = 2,
			right = 2,
			top = 2,
			bottom = 2,
		},
	}

	self.GUI:SetBackdrop(backdrop)
	self.GUI:SetBackdropColor(0, 0, 0, 1)

	-- 标题
	local title = self.GUI:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOP", self.GUI, "TOP", 0, -20)
	title:SetText("战斗记录收集范围")

	-- 滑块
	self.Slider = CreateFrame("Slider", "Automaton_RC_Slider", self.GUI, "OptionsSliderTemplate")
	self.Slider:SetWidth(200)
	self.Slider:SetHeight(20)
	self.Slider:SetPoint("TOP", title, "BOTTOM", 0, -20)
	self.Slider:SetMinMaxValues(0, 200)
	self.Slider:SetValue(150)
	self.Slider:SetValueStep(5)
	getglobal(self.Slider:GetName() .. "Low"):SetText("0")
	getglobal(self.Slider:GetName() .. "High"):SetText("200")

	-- 当前值显示
	self.CurrentValueText = self.GUI:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	self.CurrentValueText:SetPoint("TOP", self.Slider, "BOTTOM", 0, -10)
	self.CurrentValueText:SetText("当前选择: " .. self.Slider:GetValue())

	-- 滑块值变化事件
	self.Slider:SetScript("OnValueChanged", function(slider, value)
		local currentValue = value or self.Slider:GetValue()
		self.CurrentValueText:SetText("当前选择: " .. currentValue)
		-- 同步更新当前范围值
		self.currentRange = currentValue
	end)

	-- 确认按钮
	self.ConfirmButton = CreateFrame("Button", nil, self.GUI, "UIPanelButtonTemplate")
	self.ConfirmButton:SetWidth(79)
	self.ConfirmButton:SetHeight(18)
	self.ConfirmButton:SetPoint("CENTER", self.GUI, "CENTER", -50, -50)
	self.ConfirmButton:SetText("确认")

	-- 关闭按钮
	self.CloseButton = CreateFrame("Button", nil, self.GUI, "UIPanelButtonTemplate")
	self.CloseButton:SetWidth(79)
	self.CloseButton:SetHeight(18)
	self.CloseButton:SetPoint("LEFT", self.ConfirmButton, "RIGHT", 10, 0)
	self.CloseButton:SetText("关闭窗口")

	-- 按钮事件
	self.ConfirmButton:SetScript("OnClick", function()
		local range = self.Slider:GetValue()
		self:ApplyRangeSettings()
	end)

	self.CloseButton:SetScript("OnClick", function()
		self.GUI:Hide()
	end)

	self.GUI:Hide()
end

function Automaton_RangeController:RegisterSlashCommands()
	-- 注册斜杠命令
	SLASH_AUTOMATONRC1 = "/RC"
	SLASH_AUTOMATONRC2 = "/FW"

	SlashCmdList["AUTOMATONRC"] = function(msg)
		if msg and msg ~= "" then
			-- 处理命令行参数
			local range = tonumber(msg)
			if range and range >= 0 and range <= 200 then
				self.currentRange = range
				self:ApplyRangeSettings()
				print(string.format("|cFF00FF00[范围控制器] 战斗记录范围已设置为 %d 码|r", range))
			else
				-- 显示帮助信息
				print("|cFFFFFF00用法: /RC <范围值> 或 /FW <范围值>|r")
				print("|cFFFFFF00范围值: 0-200 之间的数字|r")
			end
		else
			-- 显示/隐藏GUI界面
			if self.GUI and self.GUI:IsShown() then
				self.GUI:Hide()
			elseif self.GUI then
				self.GUI:Show()
				-- 同步滑块值
				self.Slider:SetValue(self.currentRange or 150)
			end
		end
	end
end

function Automaton_RangeController:ApplyRangeSettings()
	-- 使用当前范围值
	local range = self.currentRange or 150

	-- 设置战斗记录范围的命令
	local commands = {
		"CombatLogRangeHostilePlayers",
		"CombatLogRangeHostilePlayersPets",
		"CombatLogRangeParty",
		"CombatLogRangePartyPet",
		"CombatLogRangeFriendlyPlayers",
		"CombatLogRangeFriendlyPlayersPets",
		"CombatLogRangeCreature",
		"CombatDeathLogRange",
		"CombatModeMaxDistance",
	}

	-- 执行所有命令
	for _, cvar in ipairs(commands) do
		-- 使用 SetCVar 来设置控制台变量
		SetCVar(cvar, range)
	end

	print(string.format("|cFF00FF00[范围控制器] 战斗记录范围已设置为 %d 码|r", range))
end
