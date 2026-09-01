-- DrunkTracker Addon for WoW Vanilla 1.12.1
-- Tracks drunk states and displays color-coded GUI
-- 集成于 Automaton：/auto 开关控制启用，/dt 切换面板显隐

assert(Automaton, "Automaton not found!")

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_DrunkTracker = Automaton:NewModule("DrunkTracker")
Automaton_DrunkTracker.modulename = "酒仙挑战"
Automaton_DrunkTracker.moduledesc = "追踪醉酒状态，完成酒仙挑战"

------------------------------
--      Local Variables      --
------------------------------

local frame = nil
local DrunkTrackerDB = nil

-- Drunk states
local DRUNK_STATES = {
	SOBER = 0, --未醉待饮
	TIPSY = 1, --浅醉微醺
	DRUNK = 2, --渐醉上头
	SMASHED = 3, --烂醉如泥
}

-- Current state
local currentState = DRUNK_STATES.SOBER

-- 整句精确匹配（优先，命中即用；用数组保证顺序确定，避免 pairs 随机）
local CHAT_PATTERNS = {
	{ p = "你再次感觉清醒。", s = DRUNK_STATES.SOBER },
	{ p = "你感到喝醉了。喔哦！", s = DRUNK_STATES.TIPSY },
	{ p = "你感觉喝醉了。喔哦！", s = DRUNK_STATES.DRUNK },
	{ p = "你感觉完全喝醉了。", s = DRUNK_STATES.SMASHED },
}

-- 关键词兜底（按特异性从高到低）：避免游戏文案标点/版本差异导致漏判
local CHAT_KEYWORDS = {
	{ kw = "清醒", s = DRUNK_STATES.SOBER },
	{ kw = "完全喝醉", s = DRUNK_STATES.SMASHED },
	{ kw = "烂醉如泥", s = DRUNK_STATES.SMASHED },
	{ kw = "感觉喝醉", s = DRUNK_STATES.DRUNK },
	{ kw = "喝醉", s = DRUNK_STATES.TIPSY },
	{ kw = "醉醺醺", s = DRUNK_STATES.TIPSY },
}

-- Colors for each state
local STATE_COLORS = {
	[DRUNK_STATES.SOBER] = { r = 0.5, g = 0.5, b = 0.5 }, -- Gray
	[DRUNK_STATES.TIPSY] = { r = 1.0, g = 1.0, b = 0.0 }, -- Yellow
	[DRUNK_STATES.DRUNK] = { r = 1.0, g = 0.0, b = 0.0 }, -- Red
	[DRUNK_STATES.SMASHED] = { r = 0.0, g = 1.0, b = 0.0 }, -- Green
}

-- State names for display
local STATE_NAMES = {
	[DRUNK_STATES.SOBER] = "未醉待饮",
	[DRUNK_STATES.TIPSY] = "浅醉微醺",
	[DRUNK_STATES.DRUNK] = "渐醉上头",
	[DRUNK_STATES.SMASHED] = "烂醉如泥",
}

------------------------------
--      Frame Functions      --
------------------------------

-- Update the GUI based on current state
local function UpdateGUI()
	if not frame then
		return
	end

	local color = STATE_COLORS[currentState]
	local name = STATE_NAMES[currentState]

	-- 用独立背景纹理着色（1.12 下 SetVertexColor 可靠刷新；SetBackdropColor 从聊天事件调用不重绘）
	if frame.bg then
		frame.bg:SetVertexColor(color.r, color.g, color.b)
	else
		frame:SetBackdropColor(color.r, color.g, color.b, 1.0)
	end
	frame.text:SetText(name)

	-- White text for all states
	frame.text:SetTextColor(1, 1, 1)
end

-- Create the main frame
local function CreateMainFrame()
	frame = CreateFrame("Frame", "DrunkTrackerFrame", UIParent)
	frame:SetWidth(105)
	frame:SetHeight(44)
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
	frame:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	-- backdrop 背景透明（仅由下方纹理着色），保留可见边框
	frame:SetBackdropColor(0, 0, 0, 0)
	frame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

	-- 独立背景纹理：用 SetVertexColor 着色（不透明色块），覆盖在 backdrop 之上、边框之内
	local bg = frame:CreateTexture(nil, "BACKGROUND")
	bg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	bg:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -4)
	bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
	bg:SetVertexColor(0.5, 0.5, 0.5)
	frame.bg = bg
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:RegisterForDrag("LeftButton", "Shift")
	frame:SetScript("OnDragStart", function()
		if IsShiftKeyDown() then -- 检测Shift键状态
			this:StartMoving()
		end
	end)
	frame:SetScript("OnDragStop", function()
		this:StopMovingOrSizing()
		-- Save position
		local point, relativeTo, relativePoint, xOfs, yOfs = this:GetPoint()
		if DrunkTrackerDB then
			DrunkTrackerDB.position = {
				point = point,
				relativePoint = relativePoint,
				xOfs = xOfs,
				yOfs = yOfs,
			}
		end
	end)

	-- Create text label directly on main frame
	local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	text:SetPoint("CENTER", frame, "CENTER", 0, 0)
	text:SetText(STATE_NAMES[currentState])
	text:SetTextColor(1, 1, 1) -- White text for all states
	frame.text = text

	UpdateGUI()
end

-- Parse chat messages for drunk state changes
local function OnChatMessage(msg)
	if not msg then
		return
	end

	local newState = nil

	-- 1) 整句精确匹配（优先，顺序确定）
	for i = 1, table.getn(CHAT_PATTERNS) do
		if string.find(msg, CHAT_PATTERNS[i].p) then
			newState = CHAT_PATTERNS[i].s
			break
		end
	end

	-- 2) 关键词兜底（按特异性从高到低）
	if not newState then
		for i = 1, table.getn(CHAT_KEYWORDS) do
			if string.find(msg, CHAT_KEYWORDS[i].kw) then
				newState = CHAT_KEYWORDS[i].s
				break
			end
		end
	end

	-- 3) 战斗经验兜底：仅在已处于醉酒状态时判为烂醉，避免普通击杀误判
	if not newState and currentState ~= DRUNK_STATES.SOBER then
		if string.find(msg, "经验值") then
			newState = DRUNK_STATES.SMASHED
		end
	end

	if not newState then
		return
	end

	local previousState = currentState
	currentState = newState
	UpdateGUI()

	-- Raid warning when losing smashed state
	if previousState == DRUNK_STATES.SMASHED and newState ~= DRUNK_STATES.SMASHED then
		UIErrorsFrame:AddMessage("失去完全醉酒状态！！", 1.0, 0.1, 0.1, 1.0, UIERRORS_HOLD_TIME)
		DEFAULT_CHAT_FRAME:AddMessage("====>【失去完全醉酒状态】<=====", 0, 1, 1)
		PlaySoundFile("Interface\\AddOns\\Automatonex\\Sound\\1.mp3")
	end

	if previousState ~= DRUNK_STATES.SMASHED and newState == DRUNK_STATES.SMASHED then
		PlaySoundFile("Interface\\AddOns\\Automatonex\\Sound\\2.mp3")
	end
end

-- Initialize database with default values
local function InitializeDB()
	if not DrunkTrackerDB then
		DrunkTrackerDB = {
			position = {
				point = "CENTER",
				relativePoint = "CENTER",
				xOfs = 0,
				yOfs = 200,
			},
		}
	end
end

-- Restore saved position
local function RestorePosition()
	if DrunkTrackerDB and DrunkTrackerDB.position and frame then
		local pos = DrunkTrackerDB.position
		frame:ClearAllPoints()
		frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOfs, pos.yOfs)
	end
end

------------------------------
--      Module Functions      --
------------------------------

function Automaton_DrunkTracker:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("DrunkTracker")
	Automaton:RegisterDefaults("DrunkTracker", "profile", {
		disabled = true, -- 默认关闭
		position = {
			point = "CENTER",
			relativePoint = "CENTER",
			xOfs = 0,
			yOfs = 200,
		},
	})
	DrunkTrackerDB = self.db.profile

	Automaton:SetDisabledAsDefault(self, "DrunkTracker")

	self:RegisterOptions({})
end

function Automaton_DrunkTracker:OnEnable()
	if not frame then
		CreateMainFrame()
		RestorePosition()
	else
		frame:Show()
	end
	self:RegisterEvent("CHAT_MSG_SYSTEM", "OnChatMessage")
	self:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN", "OnChatMessage")
end

function Automaton_DrunkTracker:OnDisable()
	if frame then
		frame:Hide()
	end
	self:UnregisterAllEvents()
end

function Automaton_DrunkTracker:OnChatMessage()
	OnChatMessage(arg1)
end

------------------------------
--      Slash Commands      --
------------------------------

-- 参照独立插件写法：/dt 切换醉酒面板的显隐
SLASH_DRUNKTRACKER1 = "/dt"
SlashCmdList["DRUNKTRACKER"] = function(msg)
	if not frame then
		DEFAULT_CHAT_FRAME:AddMessage(
			"|cFFFF6666[酒仙挑战]|r 模块未启用，请先在 /auto 中开启",
			1,
			0.5,
			0
		)
		return
	end
	if frame:IsVisible() then
		frame:Hide()
		DEFAULT_CHAT_FRAME:AddMessage(
			"|cFFFF6666[酒仙挑战]|r 面板已隐藏（输入 /dt 重新显示）",
			1,
			0.5,
			0
		)
	else
		frame:Show()
		DEFAULT_CHAT_FRAME:AddMessage("|cFF88FF88[酒仙挑战]|r 面板已显示（输入 /dt 隐藏）", 0, 1, 0)
	end
end
