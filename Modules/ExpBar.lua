assert(Automaton, "Automaton not found!")

------------------------------
--      Localization      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_ExpBar")

L:RegisterTranslations("zhCN", function()
	return {
		["ExpBar"] = "美观经验条",
		["Displays a customized experience bar with additional information."] = "显示自定义经验条及额外信息（含每小时经验、双倍经验提示等）/expbar reset重置位置",
		["Time to level: %d min"] = "预计升级: %d分钟",
		["Time to level: %.1f hours"] = "预计升级: %.1f小时",
		["Time to level: %d hours %d min"] = "预计升级: %d小时%d分钟",
		["Position reset to default."] = "位置已重置到默认设置。",
	}
end)

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_ExpBar = Automaton:NewModule("ExpBar")
Automaton_ExpBar.modulename = L["ExpBar"]
Automaton_ExpBar.moduledesc = L["Displays a customized experience bar with additional information."]
Automaton_ExpBar.options = {}

------------------------------
--      Local Variables      --
------------------------------

local expContainer, expBg, expBorder, expBar, restedBar
local expText, restedTextFont, expStatFont, levelText, timeToLevelFont

local expTrack = {
	startXP = 0,
	startTime = 0,
	level = 0,
}

-- 新增：用于估算击杀数的变量
local lastXP -- 上一次记录的经验值
local lastGainedXP -- 最近一次获得的经验值（正数）

------------------------------
--      Initialization      --
------------------------------

function Automaton_ExpBar:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("ExpBar")
	Automaton:RegisterDefaults("ExpBar", "profile", {
		disabled = false,
		position = {
			point = "TOP",
			relativePoint = "TOP",
			x = 0,
			y = -50,
		},
		width = 410,
		height = 13,
	})
	Automaton:SetDisabledAsDefault(self, "ExpBar")
	self:RegisterOptions(self.options)

	-- 注册控制台命令
	self:RegisterSlashCommand()
end

function Automaton_ExpBar:OnEnable()
	if not expContainer then
		self:CreateExpBar()
	end
	self:LoadPosition()

	self:RegisterEvent("PLAYER_XP_UPDATE")
	self:RegisterEvent("PLAYER_LEVEL_UP")
	self:RegisterEvent("UPDATE_EXHAUSTION")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	expContainer:Show()

	-- 初始化跟踪变量
	lastXP = nil
	lastGainedXP = nil

	self:UpdateExpBar()
end

function Automaton_ExpBar:OnDisable()
	self:UnregisterAllEvents()
	if expContainer then
		expContainer:Hide()
	end
end

------------------------------
--      UI Creation      --
------------------------------

function Automaton_ExpBar:CreateExpBar()
	expContainer = CreateFrame("Frame", "Automaton_ExpBarContainer", UIParent)
	expContainer:SetWidth(self.db.profile.width)
	expContainer:SetHeight(self.db.profile.height)
	expContainer:SetFrameStrata("HIGH")

	-- 移动功能设置
	expContainer:SetMovable(true)
	expContainer:EnableMouse(true)
	expContainer:RegisterForDrag("LeftButton")

	expContainer:SetScript("OnDragStart", function()
		expContainer:StartMoving()
	end)

	expContainer:SetScript("OnDragStop", function()
		expContainer:StopMovingOrSizing()
		local point, _, rel_point, x_offset, y_offset = expContainer:GetPoint()

		if x_offset < 20 and x_offset > -20 then
			x_offset = 0
		end

		self.db.profile.position = {
			point = point,
			relativePoint = rel_point,
			x = math.floor(x_offset),
			y = math.floor(y_offset),
		}
	end)

	-- 经验条背景
	expBg = expContainer:CreateTexture(nil, "BACKGROUND")
	expBg:SetAllPoints()
	if expBg.SetColorTexture then
		expBg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
	else
		expBg:SetTexture(0.1, 0.1, 0.1, 0.8)
	end

	-- 经验条边框
	expBorder = CreateFrame("Frame", nil, expContainer)
	expBorder:SetPoint("TOPLEFT", expContainer, "TOPLEFT", -2, 2)
	expBorder:SetPoint("BOTTOMRIGHT", expContainer, "BOTTOMRIGHT", 2, -2)
	expBorder:SetBackdrop({
		edgeFile = "Interface\\AddOns\\Automatonex\\Texture\\UI-Tooltip-Border",
		edgeSize = 12,
	})
	expBorder:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)

	-- 主经验条
	expBar = CreateFrame("StatusBar", nil, expContainer)
	expBar:SetWidth(self.db.profile.width - 4)
	expBar:SetHeight(self.db.profile.height - 1)
	expBar:SetPoint("CENTER", expContainer, "CENTER", 0, 0)
	expBar:SetStatusBarTexture("Interface\\AddOns\\Automatonex\\Texture\\bar_gradient.tga")
	expBar:SetStatusBarColor(0.5, 0.3, 0.7)
	expBar:SetMinMaxValues(0, 100)
	expBar:SetValue(0)

	-- 双倍经验条
	restedBar = CreateFrame("StatusBar", nil, expContainer)
	restedBar:SetWidth(self.db.profile.width - 4)
	restedBar:SetHeight(self.db.profile.height - 1)
	restedBar:SetPoint("LEFT", expBar, "LEFT", 0, 0)
	restedBar:SetStatusBarTexture("Interface\\AddOns\\Automatonex\\Texture\\bar_gradient.tga")
	restedBar:SetStatusBarColor(0.95, 0.8, 0.3)
	restedBar:SetMinMaxValues(0, 100)
	restedBar:SetValue(0)
	restedBar:SetFrameLevel(expBar:GetFrameLevel() - 1)

	-- 经验文字
	expText = expBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	expText:SetPoint("CENTER", expBar, "CENTER", 0, 7)
	expText:SetText("")
	expText:SetTextColor(1, 1, 1)
	expText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")

	-- 双倍经验文字（右上角）
	restedTextFont = expBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	restedTextFont:SetPoint("TOPRIGHT", expBar, "TOPRIGHT", 0, 7)
	restedTextFont:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
	restedTextFont:SetText("")

	-- 每小时经验文字（左下角）
	expStatFont = expBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	expStatFont:SetPoint("BOTTOMLEFT", expBar, "BOTTOMLEFT", 2, -14)
	expStatFont:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
	expStatFont:SetText("")

	-- 预计升级时间 + 击杀估算文字（右下角，合并显示）
	timeToLevelFont = expBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	timeToLevelFont:SetPoint("BOTTOMRIGHT", expBar, "BOTTOMRIGHT", -2, -14)
	timeToLevelFont:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
	timeToLevelFont:SetJustifyH("RIGHT")
	timeToLevelFont:SetText("")

	-- 等级文字
	levelText = expContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	levelText:SetPoint("LEFT", expContainer, "LEFT", 10, 7)
	levelText:SetText("Level.1")
	levelText:SetTextColor(1, 1, 1)
	levelText:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
	levelText:SetDrawLayer("OVERLAY")
	levelText:SetParent(expBar)
end

------------------------------
--      Position Management      --
------------------------------

function Automaton_ExpBar:LoadPosition()
	local pos = self.db.profile.position
	expContainer:ClearAllPoints()
	expContainer:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
end

function Automaton_ExpBar:SavePosition()
	local point, _, relativePoint, x, y = expContainer:GetPoint()
	self.db.profile.position = {
		point = point,
		relativePoint = relativePoint,
		x = x,
		y = y,
	}
end

function Automaton_ExpBar:ResetPosition()
	self.db.profile.position = {
		point = "TOP",
		relativePoint = "TOP",
		x = 0,
		y = -50,
	}
	self:LoadPosition()
	print("|cFF33FF99Automaton_ExpBar|r: " .. L["Position reset to default."])
end

------------------------------
--      Slash Commands      --
------------------------------

function Automaton_ExpBar:RegisterSlashCommand()
	SLASH_AUTOMATON_EXPBAR1 = "/expbar"
	SlashCmdList["AUTOMATON_EXPBAR"] = function(msg)
		self:HandleSlashCommand(msg)
	end
end

function Automaton_ExpBar:HandleSlashCommand(msg)
	msg = string.lower(msg or "")

	if msg == "reset" or msg == "resetpos" then
		self:ResetPosition()
	elseif msg == "help" or msg == "?" or msg == "" then
		print("|cFF33FF99Automaton_ExpBar 命令列表:|r")
		print("  |cFF00FF00/expbar reset|r - 重置经验条位置到默认位置")
		print("  |cFF00FF00/expbar help|r - 显示此帮助信息")
		print("  |cFF00FF00右键拖动|r - 手动拖动经验条调整位置")
	else
		print("|cFF33FF99Automaton_ExpBar|r: 未知命令，输入 |cFF00FF00/expbar help|r 查看可用命令")
	end
end

------------------------------
--      Exp Bar Logic      --
------------------------------

local function FormatLargeNumber(number)
	if type(number) ~= "number" then
		return tostring(number)
	end

	local numString = tostring(number)
	local len = string.len(numString)
	local formatted = ""
	local counter = 0

	for i = len, 1, -1 do
		counter = counter + 1
		formatted = string.sub(numString, i, i) .. formatted

		if counter == 3 and i > 1 then
			formatted = "," .. formatted
			counter = 0
		end
	end

	return formatted
end

function Automaton_ExpBar:UpdateExpBar()
	if not expContainer or not expContainer:IsShown() then
		return
	end

	local playerLevel = UnitLevel("player")

	if playerLevel >= 60 then
		expContainer:Hide()
		return
	else
		expContainer:Show()
	end

	levelText:SetText("Level." .. playerLevel)

	local currentXP = UnitXP("player")
	local maxXP = UnitXPMax("player")
	local restedXP = GetXPExhaustion() or 0

	local percentXP = (currentXP / maxXP) * 100
	local percentText = string.format("%.1f", percentXP) .. "%"
	local restedPercent = (restedXP / maxXP) * 100

	expBar:SetMinMaxValues(0, maxXP)
	expBar:SetValue(currentXP)

	restedBar:SetMinMaxValues(0, maxXP)
	restedBar:SetValue(math.min(currentXP + restedXP, maxXP))

	local formattedCurrent = FormatLargeNumber(currentXP)
	local formattedMax = FormatLargeNumber(maxXP)
	expText:SetText(formattedCurrent .. " / " .. formattedMax .. " (" .. percentText .. ")")

	restedTextFont:SetText("")
	if restedXP > 0 then
		local displayPercent = math.min(restedPercent, 150)
		restedTextFont:SetText("|cFFFFFFFF双倍经验|r |cFFFFD700" .. string.format("%.1f", displayPercent) .. "%|r")
	end

	local now = time()
	-- 等级变化或首次启动时重置跟踪变量（包括击杀估算用的 lastXP/lastGainedXP）
	if expTrack.level ~= playerLevel or expTrack.startXP == 0 then
		expTrack.startXP = currentXP
		expTrack.startTime = now
		expTrack.level = playerLevel
		-- 重置击杀估算数据
		lastXP = currentXP
		lastGainedXP = nil
	end

	-- 每小时经验计算
	local elapsed = now - expTrack.startTime
	local gained = currentXP - expTrack.startXP
	local xpPerHour = elapsed > 0 and (gained * 3600 / elapsed) or 0

	-- 击杀估算：跟踪最近一次获得的经验值
	if lastXP == nil then
		lastXP = currentXP
	end
	if currentXP > lastXP then
		local gainedXP = currentXP - lastXP
		if gainedXP > 0 then
			lastGainedXP = gainedXP
		end
		lastXP = currentXP
	elseif currentXP < lastXP then
		-- 经验减少（如升级重置），清空上次获得的经验
		lastXP = currentXP
		lastGainedXP = nil
	end

	-- 每小时经验文字（左下角）
	local statString = "每小时经验: " .. FormatLargeNumber(math.floor(xpPerHour))
	expStatFont:SetText(statString)

	-- 计算剩余经验
	local remainingXP = maxXP - currentXP

	-- 构建预计升级时间字符串
	local timeString = ""
	if remainingXP <= 0 then
		timeString = "|cFF00FF00即将升级!|r"
	elseif xpPerHour > 0 then
		local timeToLevelHours = remainingXP / xpPerHour
		if timeToLevelHours < 1 then
			local minutes = math.floor(timeToLevelHours * 60 + 0.5)
			timeString = string.format(L["Time to level: %d min"], minutes)
		else
			local hours = math.floor(timeToLevelHours)
			local minutes = math.floor((timeToLevelHours - hours) * 60 + 0.5)
			if minutes >= 60 then
				hours = hours + 1
				minutes = 0
			end
			if minutes == 0 then
				timeString = string.format(L["Time to level: %.1f hours"], hours)
			else
				timeString = string.format(L["Time to level: %d hours %d min"], hours, minutes)
			end
		end
	end

	-- 构建击杀估算字符串
	local killString = ""
	if lastGainedXP and lastGainedXP > 0 and remainingXP > 0 then
		local remainingKills = math.ceil(remainingXP / lastGainedXP)
		killString = "需击杀: " .. remainingKills
	end

	-- 合并显示在右下角
	if timeString ~= "" and killString ~= "" then
		timeToLevelFont:SetText(timeString .. " | " .. killString)
	elseif timeString ~= "" then
		timeToLevelFont:SetText(timeString)
	elseif killString ~= "" then
		timeToLevelFont:SetText(killString)
	else
		timeToLevelFont:SetText("")
	end
end

-- 事件处理
function Automaton_ExpBar:PLAYER_XP_UPDATE()
	self:UpdateExpBar()
end

function Automaton_ExpBar:PLAYER_LEVEL_UP()
	self:UpdateExpBar()
end

function Automaton_ExpBar:UPDATE_EXHAUSTION()
	self:UpdateExpBar()
end

function Automaton_ExpBar:PLAYER_ENTERING_WORLD()
	self:UpdateExpBar()
end
