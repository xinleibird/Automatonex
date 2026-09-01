assert(Automaton, "Automaton not found!")

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_AutoDB = Automaton:NewModule("AutoDB")
Automaton_AutoDB.modulename = "自动显示飞行点、旅馆及兽栏"
Automaton_AutoDB.moduledesc = "自动显示飞行点、旅馆及兽栏，并记录飞行时间和统计信息"

------------------------------
--      Initialization      --
------------------------------

function Automaton_AutoDB:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("AutoDB")
	-- 账号级共享数据（飞行时间和费用）
	Automaton:RegisterDefaults("AutoDB", "account", {
		flightTimes = {},
		flightCosts = {},
	})
	-- 角色级数据（统计信息、设置等）
	Automaton:RegisterDefaults("AutoDB", "char", {
		disabled = false,
		statistics = {
			totalFlights = 0,
			totalTime = 0,
			totalCost = 0,
			longestFlightTime = 0,
			longestFlightPath = "",
		},
		options = {
			confirmFlights = false,
			showTimer = true,
			announceETA = false,
		},
		timerPosition = {
			point = "CENTER",
			relativePoint = "CENTER",
			x = 0,
			y = 200,
		},
	})
	Automaton:SetDisabledAsDefault(self, "AutoDB")

	-- 初始化 FlightPath-Turtle 变量
	self.flightStartTime = 0
	self.currentFlightFromIndex = 0
	self.currentFlightToIndex = 0
	self.pendingFlightCost = nil
	self.lastClickedTaxiNode = nil
	self.currentTaxiNodeName = nil
	self.isConfirming = false
	self.flightPending = false
	self.isInFlight = false
	self.isTooltipHooked = false

	-- 创建飞行计时器
	self:CreateFlightTimer()
	self:CreateUpdateFrame()

	-- 注册静态对话框
	self:RegisterStaticPopups()

	-- 创建设置选项
	self:CreateOptions()
end

function Automaton_AutoDB:OnEnable()
	self:RegisterEvent("SKILL_LINES_CHANGED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("TAXIMAP_OPENED")
	self:RegisterEvent("TAXIMAP_CLOSED")

	self.skillsLoaded = false
	self.done = false
	self.retryCount = 0

	-- 使用标准 WoW API 来 Hook TakeTaxiNode 函数
	self:HookTakeTaxiNode()
end

function Automaton_AutoDB:OnDisable()
	self:UnregisterAllEvents()
	self:UnhookTakeTaxiNode()
	self.done = true
end

-- Hook TakeTaxiNode 函数
function Automaton_AutoDB:HookTakeTaxiNode()
	if self.isHooked then
		return
	end

	-- 保存原始函数
	self.OriginalTakeTaxiNode = TakeTaxiNode

	-- 创建新的 Hook 函数
	TakeTaxiNode = function(nodeIndex)
		return Automaton_AutoDB:OnTakeTaxiNode(nodeIndex)
	end

	self.isHooked = true
end

-- 取消 Hook
function Automaton_AutoDB:UnhookTakeTaxiNode()
	if not self.isHooked then
		return
	end

	-- 恢复原始函数
	if self.OriginalTakeTaxiNode then
		TakeTaxiNode = self.OriginalTakeTaxiNode
	end

	self.isHooked = false
end

------------------------------
--      Event Handlers      --
------------------------------

function Automaton_AutoDB:SKILL_LINES_CHANGED()
	self.skillsLoaded = true
end

function Automaton_AutoDB:PLAYER_ENTERING_WORLD()
	-- 获取玩家职业
	self.playerClass = select(2, UnitClass("player"))

	-- 重置状态，确保每次进入世界都能重新检查执行
	self.done = false
	self.skillsLoaded = false
	self.retryCount = 0

	-- 检查是否在飞行中结束
	if self.isInFlight and not UnitOnTaxi("player") then
		self:RecordFlight()
	end

	-- 延迟到登录界面重建完成后再执行 /db 命令。
	-- 若在登录窗口期内（pfUI/pfQuest 尚在初始化）执行 /db track，
	-- pfQuest 触发的全屏世界地图 + 之后裸 Hide 会破坏 UIPanel 显示状态，
	-- 导致刚进游戏时所有动作条/界面被隐藏。固定延迟 5 秒避开竞争。
	C_Timer.After(5, function()
		self:CheckAndExecuteCommands()
	end)
end

function Automaton_AutoDB:TAXIMAP_OPENED()
	if not self.isTooltipHooked then
		self:HookTaxiNodeTooltip()
		self.isTooltipHooked = true
	end

	local currentNodeIndex = GetCurrentTaxiNode and GetCurrentTaxiNode()
	if not currentNodeIndex then
		return
	end

	self.currentTaxiNodeName = TaxiNodeName(currentNodeIndex)
end

function Automaton_AutoDB:TAXIMAP_CLOSED()
	if self.isTooltipHooked then
		self:UnhookTaxiNodeTooltip()
		self.isTooltipHooked = false
	end

	-- 使用 C_Timer.After 替代 ScheduleTimer
	C_Timer.After(1, function()
		if not self.isInFlight then
			self.currentTaxiNodeName = nil
		end
	end)
end

-- Hook 飞行点工具提示
function Automaton_AutoDB:HookTaxiNodeTooltip()
	-- 保存原始函数
	self.OriginalTaxiNodeOnButtonEnter = TaxiNodeOnButtonEnter

	-- 创建新的 Hook 函数
	TaxiNodeOnButtonEnter = function(button)
		Automaton_AutoDB:OnTaxiNodeEnter(button)
	end
end

-- 取消 Hook 工具提示
function Automaton_AutoDB:UnhookTaxiNodeTooltip()
	if self.OriginalTaxiNodeOnButtonEnter then
		TaxiNodeOnButtonEnter = self.OriginalTaxiNodeOnButtonEnter
	end
end

-- 检查pfQuest是否存在
function Automaton_AutoDB:IsPfQuestAvailable()
	return pfQuest or SlashCmdList["DB"] or false
end

-- 定期检查并执行命令
function Automaton_AutoDB:CheckAndExecuteCommands()
	if self.done then
		return
	end

	-- 检查pfQuest是否可用
	local pfQuestAvailable = self:IsPfQuestAvailable()

	if not pfQuestAvailable and self.retryCount < 5 then
		-- pfQuest未加载，重试几次（最多5次，每次间隔0.5秒）
		self.retryCount = self.retryCount + 1
		C_Timer.After(0.5, function()
			self:CheckAndExecuteCommands()
		end)
		return
	end

	if not pfQuestAvailable then
		-- 经过多次重试后pfQuest仍然不可用，放弃执行
		self.done = true
		return
	end

	if self.skillsLoaded and Automaton:IsModuleActive("AutoDB") then
		-- 先置位再执行：执行链内部已逐条 pcall，确保任何情况下不再重入
		self.done = true
		self:ExecuteEnabledCommands()
	else
		-- 延迟检查
		C_Timer.After(0.5, function()
			self:CheckAndExecuteCommands()
		end)
	end
end

------------------------------
--      Core Functions      --
------------------------------

-- 执行斜杠命令：优先直接调用 SlashCmdList 处理函数（pcall 保护），
-- 避免在登录早期操作 DEFAULT_CHAT_FRAME.editBox 与 pfUI 聊天框冲突；
-- 未命中处理函数时再回退到输入框方式。
function Automaton_AutoDB:ExecuteSlashCommand(command)
	local _, _, slash, msg = string.find(command, "^(%S+)%s*(.-)%s*$")
	if slash then
		-- SLASH_DB1 -> SlashCmdList.DB（键为大写命令名，不带斜杠）
		local handler = SlashCmdList[string.upper(string.sub(slash, 2))]
		if handler then
			local ok, err = pcall(handler, msg or "")
			if ok then
				return
			end
		end
	end

	-- 回退：走聊天输入框（同样 pcall 保护，防止登录期报错打断加载链）
	pcall(function()
		DEFAULT_CHAT_FRAME.editBox:SetText(command)
		ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
	end)
end

function Automaton_AutoDB:ExecuteEnabledCommands()
	-- 执行所有预设命令（逐条 pcall，单条出错不影响后续）
	pcall(function()
		self:ExecuteSlashCommand("/db track taxi")
	end)
	pcall(function()
		self:ExecuteSlashCommand("/db track innkeeper")
	end)

	-- 如果是猎人职业，额外执行追踪兽栏
	if self.playerClass == "HUNTER" then
		pcall(function()
			self:ExecuteSlashCommand("/db track stablemaster")
		end)
	end

	-- 隐藏可能被 pfQuest 打开的世界地图。
	-- 必须用 HideUIPanel 正规关闭（保留 UIPanel 面板状态登记），
	-- 裸 WorldMapFrame:Hide() 在登录期会留下损坏的显示状态，
	-- 表现为所有动作条/界面被隐藏。
	if WorldMapFrame and WorldMapFrame.IsShown and WorldMapFrame:IsShown() then
		local ok = pcall(function()
			HideUIPanel(WorldMapFrame)
		end)
		if not ok then
			pcall(function()
				WorldMapFrame:Hide()
			end)
		end
	end
end

-- FlightPath-Turtle 核心功能
function Automaton_AutoDB:OnTakeTaxiNode(nodeIndex)
	local originNodeIndex = 0
	for i = 1, NumTaxiNodes() do
		if TaxiNodeGetType(i) == "CURRENT" then
			originNodeIndex = i
			break
		end
	end

	if originNodeIndex == 0 then
		if self.OriginalTakeTaxiNode then
			return self.OriginalTakeTaxiNode(nodeIndex)
		else
			return TakeTaxiNode(nodeIndex)
		end
	end

	self.currentFlightFromIndex = originNodeIndex
	self.currentFlightToIndex = nodeIndex
	self.pendingFlightCost = TaxiNodeCost(nodeIndex)
	self.lastClickedTaxiNode = nodeIndex

	if self.db.char.options.confirmFlights and not self.isConfirming then
		StaticPopup_Show(
			"AUTODB_CONFIRM_FLIGHT",
			TaxiNodeName(nodeIndex) or "Unknown",
			self:FormatMoney(self.pendingFlightCost or 0)
		)
		return
	end

	self.isConfirming = false
	self.flightPending = true
	self:StartFlightMonitoring()

	if self.OriginalTakeTaxiNode then
		return self.OriginalTakeTaxiNode(nodeIndex)
	else
		return TakeTaxiNode(nodeIndex)
	end
end

function Automaton_AutoDB:OnTaxiNodeEnter(button)
	if self.OriginalTaxiNodeOnButtonEnter then
		self.OriginalTaxiNodeOnButtonEnter(button)
	end

	local nodeIndex = button:GetID()
	local nodeType = TaxiNodeGetType(nodeIndex)

	if nodeType == "CURRENT" then
		return
	end

	local destination = TaxiNodeName(nodeIndex)
	local origin = nil

	for i = 1, NumTaxiNodes() do
		if TaxiNodeGetType(i) == "CURRENT" then
			origin = TaxiNodeName(i)
			break
		end
	end

	local timeText

	-- 读取账号级飞行时间数据（规范化 key 匹配，兼容旧数据）
	local flightTime = self:GetFlightTime(origin, destination)
	if flightTime then
		timeText = self:FormatTimeTooltip(flightTime)
	else
		timeText = "--:--"
	end

	GameTooltip:AddLine("飞行时间: " .. timeText, 0.7, 0.7, 0.7)
	GameTooltip:Show()
end

function Automaton_AutoDB:StartFlight(from, to, cost)
	self.flightStartTime = GetTime()

	-- 读取账号级飞行时间数据（规范化 key 匹配，兼容旧数据）
	local knownTime = self:GetFlightTime(from, to)

	-- 向队伍或团队宣布ETA
	if self.db.char.options.announceETA then
		local chatChannel = nil
		if GetNumRaidMembers() > 0 then
			chatChannel = "RAID"
		elseif GetNumPartyMembers() > 0 then
			chatChannel = "PARTY"
		end

		if chatChannel then
			local etaText
			if knownTime and knownTime > 0 then
				etaText = "预计到达: " .. self:FormatTime(knownTime)
			else
				etaText = "预计到达: (计时中...)"
			end
			SendChatMessage("飞往 " .. (to or "未知") .. ". " .. etaText, chatChannel)
		end
	end

	if self.db.char.options.showTimer then
		local timer = self.flightTimerFrame
		timer:Show()
		timer.from = from
		timer.to = to
		timer.startTime = self.flightStartTime
		timer.duration = knownTime or 0
		timer.cost = cost

		local destinationName = to or "未知"
		local zoneName = ""

		local commaPosition = string.find(destinationName, ", ")
		if commaPosition then
			zoneName = string.sub(destinationName, commaPosition + 2)
			destinationName = string.sub(destinationName, 1, commaPosition - 1)
		end

		local timingText = ""
		if not knownTime then
			timingText = " (计时中...)"
		end

		timer.text:SetText("前往: " .. destinationName .. timingText)
		timer.zone:SetText(zoneName)
	end
end

function Automaton_AutoDB:RecordFlight()
	local fromName = TaxiNodeName(self.currentFlightFromIndex)
	local toName = TaxiNodeName(self.currentFlightToIndex)

	if not fromName or not toName or self.flightStartTime == 0 then
		self:ResetFlightState()
		return
	end

	local flightDuration = GetTime() - self.flightStartTime
	local cost = self.pendingFlightCost or 0

	if flightDuration < 3 then
		self:ResetFlightState()
		return
	end

	-- 存储到账号级数据库（规范化飞行点名称，确保跨角色 key 一致）
	local normFrom = self:NormalizeNodeName(fromName)
	local normTo = self:NormalizeNodeName(toName)
	if not self.db.account.flightTimes[normFrom] then
		self.db.account.flightTimes[normFrom] = {}
	end
	self.db.account.flightTimes[normFrom][normTo] = flightDuration

	if not self.db.account.flightCosts[normFrom] then
		self.db.account.flightCosts[normFrom] = {}
	end
	self.db.account.flightCosts[normFrom][normTo] = cost

	-- 角色级统计信息保持不变
	local stats = self.db.char.statistics
	stats.totalFlights = stats.totalFlights + 1
	stats.totalTime = stats.totalTime + flightDuration
	stats.totalCost = stats.totalCost + cost

	if flightDuration > stats.longestFlightTime then
		stats.longestFlightTime = flightDuration
		stats.longestFlightPath = fromName .. " -> " .. toName
	end

	self:Print(
		"飞行完成: "
			.. fromName
			.. " -> "
			.. toName
			.. " ("
			.. self:FormatTime(flightDuration)
			.. ", "
			.. self:FormatMoney(cost)
			.. ")"
	)

	self:ResetFlightState()
end

function Automaton_AutoDB:ResetFlightState()
	self.flightStartTime = 0
	self.currentFlightFromIndex = 0
	self.currentFlightToIndex = 0
	self.pendingFlightCost = nil
	self.lastClickedTaxiNode = nil
	self.isInFlight = false
	self.flightPending = false
	if self.flightTimerFrame then
		self.flightTimerFrame:Hide()
	end
end

function Automaton_AutoDB:CreateUpdateFrame()
	local f = CreateFrame("Frame", "AutoDBUpdateFrame")

	local function startMonitoring()
		f:SetScript("OnUpdate", function()
			if self.flightPending then
				if UnitOnTaxi("player") then
					self.flightPending = false
					self.isInFlight = true
					local fromName = TaxiNodeName(self.currentFlightFromIndex)
					local toName = TaxiNodeName(self.currentFlightToIndex)
					self:StartFlight(fromName, toName, self.pendingFlightCost)
				end
			elseif self.isInFlight then
				if not UnitOnTaxi("player") then
					self:RecordFlight()
					f:SetScript("OnUpdate", nil)
				end
			else
				f:SetScript("OnUpdate", nil)
			end
		end)
	end

	self.StartFlightMonitoring = startMonitoring
end

function Automaton_AutoDB:CreateFlightTimer()
	local f = CreateFrame("Frame", "AutoDBFlightTimer", UIParent)
	self.flightTimerFrame = f

	f:SetWidth(200)
	f:SetHeight(55)
	f:SetPoint(
		self.db.char.timerPosition.point,
		UIParent,
		self.db.char.timerPosition.relativePoint,
		self.db.char.timerPosition.x,
		self.db.char.timerPosition.y
	)
	-- 删除以下两行背景设置
	-- f:SetBackdrop({
	--     bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	--     edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	--     tile = true,
	--     tileSize = 32,
	--     edgeSize = 16,
	--     insets = { left = 4, right = 4, top = 4, bottom = 4 }
	-- })
	-- f:SetBackdropColor(0, 0, 0, 0.8)
	f:Hide()

	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function()
		if IsShiftKeyDown() then
			f:StartMoving()
		end
	end)
	f:SetScript("OnDragStop", function()
		f:StopMovingOrSizing()
		local point, _, relativePoint, x, y = f:GetPoint()
		self.db.char.timerPosition = {
			point = point,
			relativePoint = relativePoint,
			x = x,
			y = y,
		}
	end)

	f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	f.text:SetPoint("TOP", f, "TOP", 0, -8)
	f.text:SetText("目的地: 未知")

	f.zone = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	f.zone:SetPoint("TOP", f.text, "BOTTOM", 0, -2)
	f.zone:SetTextColor(0.8, 0.8, 0.8)

	f.timer = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	f.timer:SetPoint("TOP", f.zone, "BOTTOM", 0, -2)
	f.timer:SetText("00:00")

	local helpButton = CreateFrame("Button", nil, f)
	helpButton:SetWidth(16)
	helpButton:SetHeight(16)
	helpButton:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -5, 5)
	helpButton:Hide() -- 添加此行隐藏按钮

	local helpText = helpButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	helpText:SetPoint("CENTER", helpButton, "CENTER", 0, 0)
	helpText:SetText("?")
	helpText:SetTextColor(1, 0.82, 0)

	helpButton.tooltipText = "Shift+拖动移动计时器"

	helpButton:SetScript("OnEnter", function()
		GameTooltip:SetOwner(helpButton, "ANCHOR_RIGHT")
		GameTooltip:SetText(helpButton.tooltipText, nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)

	helpButton:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	f:SetScript("OnUpdate", function(_, elapsed)
		if not f.startTime or f.startTime == 0 then
			return
		end
		local timePassed = GetTime() - f.startTime
		local remaining
		if f.duration and f.duration > 0 then
			remaining = f.duration - timePassed
			if remaining < 0 then
				remaining = timePassed
			end
		else
			remaining = timePassed
		end
		local minutes = math.floor(remaining / 60)
		local seconds = math.floor(math.fmod(remaining, 60))
		f.timer:SetText(string.format("%02d:%02d", minutes, seconds))
	end)
end

-- 工具函数
function Automaton_AutoDB:FormatTime(seconds)
	if not seconds or seconds <= 0 then
		return "0秒"
	end
	seconds = math.floor(seconds)
	local days = math.floor(seconds / 86400)
	local hours = math.floor(math.fmod(seconds, 86400) / 3600)
	local mins = math.floor(math.fmod(seconds, 3600) / 60)
	local secs = math.floor(math.fmod(seconds, 60))
	local t = {}
	if days > 0 then
		table.insert(t, days .. "天")
	end
	if hours > 0 then
		table.insert(t, hours .. "小时")
	end
	if mins > 0 then
		table.insert(t, mins .. "分")
	end
	if secs > 0 or table.getn(t) == 0 then
		table.insert(t, secs .. "秒")
	end
	return table.concat(t, " ")
end

function Automaton_AutoDB:FormatTimeTooltip(seconds)
	if not seconds or seconds <= 0 then
		return "0:00"
	end
	seconds = math.floor(seconds)
	local minutes = math.floor(seconds / 60)
	local secs = math.floor(math.fmod(seconds, 60))
	return string.format("%d:%02d", minutes, secs)
end

function Automaton_AutoDB:FormatMoney(copper)
	if not copper or copper == 0 then
		return "0|cffeda55f铜|r"
	end
	copper = math.floor(copper)
	local gold = math.floor(copper / 10000)
	local silver = math.floor(math.fmod(copper, 10000) / 100)
	local copp = math.floor(math.fmod(copper, 100))

	local t = {}
	if gold > 0 then
		table.insert(t, gold .. "|cffffd700金|r")
	end
	if silver > 0 then
		table.insert(t, silver .. "|cffc7c7cf银|r")
	end
	if copp > 0 or table.getn(t) == 0 then
		table.insert(t, copp .. "|cffeda55f铜|r")
	end

	return table.concat(t, " ")
end

-- 规范化飞行点名称：去掉首尾空白/tab，统一英文逗号为中文逗号
-- 消除 TaxiNodeName 返回格式不一致（部分飞行点含 tab、英文逗号）导致的 key 匹配失败
function Automaton_AutoDB:NormalizeNodeName(name)
	if not name then
		return name
	end
	name = string.gsub(name, "^%s+", "")
	name = string.gsub(name, "%s+$", "")
	name = string.gsub(name, ",", "，")
	return name
end

-- 读取飞行时间：先按规范化 key 匹配，再按原始 key 匹配（兼容旧数据）
function Automaton_AutoDB:GetFlightTime(origin, destination)
	if not origin or not destination then
		return nil
	end
	local ft = self.db.account.flightTimes
	if not ft then
		return nil
	end
	local normOrigin = self:NormalizeNodeName(origin)
	local normDest = self:NormalizeNodeName(destination)
	if ft[normOrigin] and ft[normOrigin][normDest] then
		return ft[normOrigin][normDest]
	end
	if ft[origin] and ft[origin][destination] then
		return ft[origin][destination]
	end
	return nil
end

function Automaton_AutoDB:GetFlyerRank(flightCount)
	if flightCount >= 500 then
		return "|cffFFD700天空领主|r"
	elseif flightCount >= 200 then
		return "精英飞行大师"
	elseif flightCount >= 100 then
		return "经验丰富的飞行员"
	elseif flightCount >= 50 then
		return "旅行频繁的飞行者"
	elseif flightCount >= 10 then
		return "经常旅行者"
	else
		return "新手旅行者"
	end
end

function Automaton_AutoDB:RegisterStaticPopups()
	StaticPopupDialogs["AUTODB_CONFIRM_FLIGHT"] = {
		text = "飞往 %s 花费 %s?",
		button1 = "是",
		button2 = "否",
		OnAccept = function()
			if Automaton_AutoDB.lastClickedTaxiNode then
				Automaton_AutoDB.isConfirming = true
				TakeTaxiNode(Automaton_AutoDB.lastClickedTaxiNode)
			end
		end,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
	}

	StaticPopupDialogs["AUTODB_RESET_STATS"] = {
		text = "确定要重置此角色的所有飞行统计数据吗?",
		button1 = "是",
		button2 = "取消",
		OnAccept = function()
			Automaton_AutoDB.db.char.statistics = {
				totalFlights = 0,
				totalTime = 0,
				totalCost = 0,
				longestFlightTime = 0,
				longestFlightPath = "",
			}
			-- 保留账号级飞行时间数据，只重置角色统计
			Automaton_AutoDB:Print("角色统计数据已重置")
		end,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
	}
end

-- 创建设置选项
function Automaton_AutoDB:CreateOptions()
	self.options = {
		confirmFlights = {
			type = "toggle",
			name = "确认飞行",
			desc = "飞行前弹出确认对话框",
			get = function()
				return self.db.char.options.confirmFlights
			end,
			set = function(v)
				self.db.char.options.confirmFlights = v
				self:Print("确认飞行: " .. (v and "|cff00ff00开启|r" or "|cffff0000关闭|r"))
			end,
			order = 1,
		},
		showTimer = {
			type = "toggle",
			name = "飞行计时器",
			desc = "显示飞行计时器窗口",
			get = function()
				return self.db.char.options.showTimer
			end,
			set = function(v)
				self.db.char.options.showTimer = v
				self:Print("飞行计时器: " .. (v and "|cff00ff00开启|r" or "|cffff0000关闭|r"))
			end,
			order = 2,
		},
		announceETA = {
			type = "toggle",
			name = "通告到站",
			desc = "在队伍/团队中宣布预计到达时间",
			get = function()
				return self.db.char.options.announceETA
			end,
			set = function(v)
				self.db.char.options.announceETA = v
				self:Print("宣布到站: " .. (v and "|cff00ff00开启|r" or "|cffff0000关闭|r"))
			end,
			order = 3,
		},
		statsGroup = {
			type = "group",
			name = "飞行统计",
			desc = "查看和管理飞行统计数据",
			args = {
				showStats = {
					type = "execute",
					name = "显示统计",
					desc = "显示飞行统计数据",
					func = function()
						self:ShowFlightStats()
					end,
					order = 1,
				},
				resetStats = {
					type = "execute",
					name = "重置数据",
					desc = "重置所有飞行统计数据",
					func = function()
						StaticPopup_Show("AUTODB_RESET_STATS")
					end,
					order = 2,
				},
			},
			order = 4,
		},
	}

	self:RegisterOptions(self.options)
end

-- 显示飞行统计
function Automaton_AutoDB:ShowFlightStats()
	local stats = self.db.char.statistics
	local rank = self:GetFlyerRank(stats.totalFlights)

	self:Print("=== 飞行统计 ===")
	self:Print("飞行等级: " .. rank)
	self:Print("总飞行次数: " .. stats.totalFlights)
	self:Print("总飞行时间: " .. self:FormatTime(stats.totalTime))
	self:Print("总花费: " .. self:FormatMoney(stats.totalCost))

	if stats.longestFlightPath and stats.longestFlightPath ~= "" then
		self:Print(
			"最长飞行: " .. stats.longestFlightPath .. " (" .. self:FormatTime(stats.longestFlightTime) .. ")"
		)
	else
		self:Print("最长飞行: 暂无记录")
	end
end
