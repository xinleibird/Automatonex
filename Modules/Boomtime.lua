assert(Automaton, "Automaton not found!")

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_Boomtime = Automaton:NewModule("Boomtime")
local L = Automaton_Boomtime.L

----------------------------
--      Localization      --
----------------------------

local localeTable = {
	zhCN = {
		LABEL = "副本%d",
		READY = "可用",
		RESET_BUTTON = "重置",
		REPORT_BUTTON = "通报",
		TIME_FORMAT = "%02d:%02d",
		RESET_PATTERNS = { "已被重置" },
		RESET_ANNOUNCE = "副本已重置，请进入副本！",
		REPORT_FORMAT = "副本重置状态：%s",
		modulename = "副本重置计时",
		moduledesc = "跟踪副本重置时间并提供通报功能",
	},
	enUS = {
		LABEL = "CD %d",
		READY = "Ready",
		RESET_BUTTON = "Reset",
		REPORT_BUTTON = "Notice",
		TIME_FORMAT = "%02d:%02d",
		RESET_PATTERNS = { "has been reset" },
		RESET_ANNOUNCE = "The instance has been reset, please re-enter the instance!",
		REPORT_FORMAT = "Instance reset status: %s",
		modulename = "Instance Reset Timer",
		moduledesc = "Track instance reset times and provide notification functions",
	},
}

-- 初始化本地化
Automaton_Boomtime.L = setmetatable(localeTable[GetLocale()] or localeTable.enUS, { __index = localeTable.enUS })
L = Automaton_Boomtime.L

Automaton_Boomtime.modulename = L.modulename
Automaton_Boomtime.moduledesc = L.moduledesc

------------------------------
--      Initialization      --
------------------------------

function Automaton_Boomtime:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("Boomtime")
	Automaton:RegisterDefaults("Boomtime", "profile", {
		disabled = true, -- 添加默认禁用标志
		lastResets = {},
		left = 200,
		top = 200,
		height = 210,
	})

	-- 使用Automaton框架的方法设置默认禁用
	Automaton:SetDisabledAsDefault(self, "Boomtime")

	self:InitializeFrame()

	-- 使用Automaton的标准方式注册选项
	self:RegisterOptions(self:GetOptions())
end

function Automaton_Boomtime:OnEnable()
	self:RegisterEvent("CHAT_MSG_SYSTEM")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")

	-- 启用时显示框架
	self.frame:Show()

	self:StartUpdateTimer()
end

function Automaton_Boomtime:OnDisable()
	self:UnregisterAllEvents()
	self.frame:Hide()
	self:StopUpdateTimer()
end

------------------------------
--      Frame Management     --
------------------------------

function Automaton_Boomtime:InitializeFrame()
	-- 创建主框架
	self.frame = CreateFrame("Frame", "Automaton_BoomtimeFrame", UIParent)
	self.frame:SetWidth(130)
	self.frame:SetHeight(170)
	self.frame:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	self.frame:SetBackdropColor(0, 0, 0, 0.8)
	self.frame:SetFrameStrata("DIALOG")
	self.frame:SetToplevel(true)

	-- 位置设置
	self:RefreshFramePosition()

	-- 拖动功能 - 始终可用
	self.frame:SetScript("OnDragStart", function()
		this:StartMoving()
	end)

	self.frame:SetScript("OnDragStop", function()
		this:StopMovingOrSizing()
		self.db.profile.left = this:GetLeft()
		self.db.profile.top = this:GetTop()
		self.db.profile.height = this:GetHeight()
	end)

	-- 创建标签和倒计时文本
	self.labelTexts = {}
	self.timeTexts = {}
	local contentStartY = -15
	for i = 1, 5 do
		local label = self.frame:CreateFontString(nil, "OVERLAY")
		label:SetFontObject(GameFontNormal)
		label:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10, contentStartY - 25 * (i - 1))
		label:SetText(string.format(L.LABEL, i))
		self.labelTexts[i] = label

		local timeText = self.frame:CreateFontString(nil, "OVERLAY")
		timeText:SetFontObject(GameFontHighlight)
		timeText:SetPoint("LEFT", label, "RIGHT", 10, 0)
		timeText:SetText(L.READY)
		self.timeTexts[i] = timeText
	end

	-- 创建按钮容器
	local buttonContainer = CreateFrame("Frame", nil, self.frame)
	buttonContainer:SetWidth(160)
	buttonContainer:SetHeight(30)
	buttonContainer:SetPoint("BOTTOM", self.frame, "BOTTOM", 20, 10)

	-- 通报按钮
	self.reportBtn = CreateFrame("Button", nil, buttonContainer, "OptionsButtonTemplate")
	self.reportBtn:SetWidth(60)
	self.reportBtn:SetHeight(25)
	self.reportBtn:SetPoint("LEFT", buttonContainer, "LEFT", 0, 0)
	self.reportBtn:SetText(L.REPORT_BUTTON)
	self.reportBtn:SetScript("OnClick", function()
		self:ReportStatus()
	end)

	-- 重置按钮
	self.resetBtn = CreateFrame("Button", nil, buttonContainer, "OptionsButtonTemplate")
	self.resetBtn:SetWidth(60)
	self.resetBtn:SetHeight(25)
	self.resetBtn:SetPoint("LEFT", self.reportBtn, "RIGHT", 0, 0)
	self.resetBtn:SetText(L.RESET_BUTTON)
	self.resetBtn:SetScript("OnClick", function()
		ResetInstances()
	end)

	-- 初始状态 - 始终可拖动
	self.frame:EnableMouse(true)
	self.frame:SetMovable(true)
	self.frame:RegisterForDrag("LeftButton")

	-- 默认隐藏框架
	self.frame:Hide()
end

------------------------------
--      Core Functions      --
------------------------------

function Automaton_Boomtime:RefreshFramePosition()
	self.frame:ClearAllPoints()
	self.frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", self.db.profile.left, -self.db.profile.top)
end

-- 创建一个独立的更新函数，避免作用域问题
local function Boomtime_OnUpdate()
	if not Automaton_Boomtime.lastUpdate then
		Automaton_Boomtime.lastUpdate = 0
		return
	end

	Automaton_Boomtime.lastUpdate = Automaton_Boomtime.lastUpdate + arg1
	if Automaton_Boomtime.lastUpdate >= 1 then
		Automaton_Boomtime:UpdateAllTimers()
		Automaton_Boomtime.lastUpdate = 0
	end
end

function Automaton_Boomtime:StartUpdateTimer()
	-- 使用全局函数避免作用域问题
	self.lastUpdate = 0
	self.frame:SetScript("OnUpdate", Boomtime_OnUpdate)
end

function Automaton_Boomtime:StopUpdateTimer()
	self.frame:SetScript("OnUpdate", nil)
	self.lastUpdate = nil
end

function Automaton_Boomtime:UpdateAllTimers()
	local now = time()
	local resetData = self.db.profile.lastResets or {}

	for i = 1, 5 do
		if resetData[i] then
			local elapsed = now - resetData[i]
			if elapsed < 3600 then
				local remain = 3600 - elapsed
				local mins = math.floor(remain / 60)
				local secs = math.mod(remain, 60)
				self.timeTexts[i]:SetText(string.format(L.TIME_FORMAT, mins, secs))
			else
				self.timeTexts[i]:SetText(L.READY)
			end
		else
			self.timeTexts[i]:SetText(L.READY)
		end
	end
end

function Automaton_Boomtime:ReportStatus()
	local statusLines = {}
	for i = 1, 5 do
		local text = self.timeTexts[i]:GetText()
		local displayText = "[" .. text .. "]"
		table.insert(statusLines, string.format(L.LABEL .. ": %s", i, displayText))
	end
	local fullMessage = string.format(L.REPORT_FORMAT, table.concat(statusLines, ", "))

	local numRaid = GetNumRaidMembers()
	local numParty = GetNumPartyMembers()

	if numRaid > 0 then
		SendChatMessage(fullMessage, "RAID")
	elseif numParty > 0 then
		SendChatMessage(fullMessage, "PARTY")
	end
end

------------------------------
--      Event Handlers      --
------------------------------

function Automaton_Boomtime:CHAT_MSG_SYSTEM(msg)
	for _, pattern in ipairs(L.RESET_PATTERNS) do
		if string.find(msg, pattern) then
			-- 找到第一个可用的副本位置记录重置时间
			local resetData = self.db.profile.lastResets or {}
			for i = 1, 5 do
				if not resetData[i] or (time() - resetData[i] >= 3600) then
					resetData[i] = time()
					break
				end
			end
			self:AnnounceResetSuccess()
			return
		end
	end
end

function Automaton_Boomtime:PLAYER_ENTERING_WORLD()
	self:UpdateAllTimers()
end

function Automaton_Boomtime:AnnounceResetSuccess()
	local numRaid = GetNumRaidMembers()
	local numParty = GetNumPartyMembers()

	if numRaid > 0 then
		SendChatMessage(L.RESET_ANNOUNCE, "RAID")
	elseif numParty > 0 then
		SendChatMessage(L.RESET_ANNOUNCE, "PARTY")
	else
		SendChatMessage(L.RESET_ANNOUNCE, "SAY")
	end
end

------------------------------
--      Options Panel        --
------------------------------

function Automaton_Boomtime:GetOptions()
	return {
		enabled = {
			order = 1,
			type = "toggle",
			name = "启用模块",
			desc = "启用/禁用副本重置计时模块",
			get = function()
				return Automaton:IsModuleActive("Boomtime")
			end,
			set = function(info, v)
				if v then
					self:Enable()
				else
					self:Disable()
				end
			end,
		},
	}
end
