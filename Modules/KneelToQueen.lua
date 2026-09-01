assert(Automaton, "Automaton not found!")

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_KneelToQueen = Automaton:NewModule("KneelToQueen")
Automaton_KneelToQueen.modulename = "自动对皇后下跪"
Automaton_KneelToQueen.moduledesc = "检测到黑暗屈从debuff时自动对皇后下跪，并监测国王之怒技能"
Automaton_KneelToQueen.options = {
	debugMode = {
		type = "toggle",
		name = "调试模式",
		desc = "切换调试模式",
		get = function()
			return Automaton_KneelToQueen.db.profile.debugMode
		end,
		set = function(v)
			Automaton_KneelToQueen.db.profile.debugMode = v
			Automaton_KneelToQueen.DEBUG = v
		end,
	},
}

------------------------------
--      Initialization      --
------------------------------

-- 定义允许触发的子区域（象棋大厅）
Automaton_KneelToQueen.allowedSubZone = "象棋大厅"

function Automaton_KneelToQueen:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("KneelToQueen")
	Automaton:RegisterDefaults("KneelToQueen", "profile", {
		disabled = false,
		debugMode = false,
	})
	Automaton:SetDisabledAsDefault(self, "KneelToQueen")

	self:RegisterOptions(self.options)

	-- 初始化配置变量
	self.targetName = "皇后"
	self.debuffName = "黑暗屈从"
	self.bossName = "国王"
	self.bossSpell = "国王之怒"
	self.DEBUG = self.db.profile.debugMode

	-- 当前区域变量
	self.currentZone = nil
	self.currentSubZone = nil
	self.isInAllowedZone = false

	-- 创建提示窗口
	self:CreateAlertFrame()

	-- 注册斜杠命令
	self:RegisterSlashCommands()
end

function Automaton_KneelToQueen:OnEnable()
	-- 注册事件
	self:RegisterEvent("PLAYER_LOGIN")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF")
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")

	-- 初始化区域状态（立即更新一次）
	self:UpdateZoneStatus()
	-- 如果当前子区域为空（刚登录/传送），启动轮询
	if not self.isInAllowedZone then
		self:StartZonePolling(5)
	end

	DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[自动下跪]|r |cFF00FF00<<< 模块已启用！>>>|r")
	DEFAULT_CHAT_FRAME:AddMessage(
		"|cFF00FF00[自动下跪]|r |cFFFFFF00当前区域: " .. (self.currentZone or "未知") .. "|r"
	)
	DEFAULT_CHAT_FRAME:AddMessage(
		"|cFF00FF00[自动下跪]|r |cFFFFFF00当前子区域: " .. (self.currentSubZone or "无") .. "|r"
	)
	DEFAULT_CHAT_FRAME:AddMessage(
		"|cFF00FF00[自动下跪]|r |cFFFFFF00允许触发: "
			.. (self.isInAllowedZone and "|cFF00FF00是|r" or "|cFFFF0000否|r")
	)
	PlaySound("igQuestListOpen")
end

function Automaton_KneelToQueen:OnDisable()
	-- 模块禁用时的清理操作
	self:UnregisterAllEvents()
	if self.updateFrame then
		self.updateFrame:SetScript("OnUpdate", nil)
	end
	if self.zonePollFrame then
		self.zonePollFrame:SetScript("OnUpdate", nil)
		self.zonePollFrame = nil
	end
	if self.alertFrame then
		self.alertFrame:Hide()
	end

	DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[自动下跪]|r |cFFFF0000<<< 模块已禁用！>>>|r")
	PlaySound("igQuestFailed")
end

------------------------------
--      Zone Management    --
------------------------------

-- 更新区域状态（包括子区域）
function Automaton_KneelToQueen:UpdateZoneStatus()
	self.currentZone = GetRealZoneText() or GetZoneText()
	self.currentSubZone = GetSubZoneText() or ""
	-- 仅当子区域为象棋大厅时才允许触发
	self.isInAllowedZone = (self.currentSubZone == self.allowedSubZone)

	self:DebugMessage(
		"区域更新: Zone="
			.. (self.currentZone or "未知")
			.. " | SubZone="
			.. (self.currentSubZone or "无")
			.. " - 允许触发: "
			.. (self.isInAllowedZone and "是" or "否")
	)
end

-- 区域轮询：确保子区域正确加载（解决进入区域后延迟问题）
function Automaton_KneelToQueen:StartZonePolling(timeout)
	if self.zonePollFrame then
		return
	end
	self.zonePollFrame = CreateFrame("Frame")
	self.zonePollFrame.elapsed = 0
	self.zonePollFrame.timeout = timeout or 5
	self.zonePollFrame:SetScript("OnUpdate", function()
		self.zonePollFrame.elapsed = self.zonePollFrame.elapsed + arg1
		self:UpdateZoneStatus()
		if self.isInAllowedZone or self.zonePollFrame.elapsed >= self.zonePollFrame.timeout then
			self.zonePollFrame:SetScript("OnUpdate", nil)
			self.zonePollFrame = nil
			if self.isInAllowedZone then
				self:ShowAlert("进入象棋大厅", 3)
				self:DebugMessage("区域轮询成功：检测到象棋大厅")
			else
				self:DebugMessage("区域轮询超时，未检测到象棋大厅")
			end
		end
	end)
end

-- 区域改变事件处理（启动轮询，不再依赖单次延迟）
function Automaton_KneelToQueen:ZONE_CHANGED_NEW_AREA()
	self:StartZonePolling(5)
end

function Automaton_KneelToQueen:PLAYER_ENTERING_WORLD()
	self:StartZonePolling(5)
end

------------------------------
--      UI Creation        --
------------------------------

function Automaton_KneelToQueen:CreateUpdateFrame()
	-- 创建用于处理OnUpdate的帧（下跪逻辑专用）
	if not self.updateFrame then
		self.updateFrame = CreateFrame("Frame")
		self.updateTimer = 0
	end
end

function Automaton_KneelToQueen:CreateAlertFrame()
	self.alertFrame = CreateFrame("Frame", "KneelToQueenAlert", UIParent)
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

function Automaton_KneelToQueen:CreateLOSMonitor()
	if not self.losMonitorFrame then
		self.losMonitorFrame = CreateFrame("Frame")
		self.losMonitorFrame:Hide()
		self.losMonitorFrame.timeLeft = 0
		self.losMonitorFrame.checkTimer = 0
		self.losMonitorFrame.bossName = nil
		self.losMonitorFrame.bossSpell = nil
		self.losMonitorFrame.warned = false

		self.losMonitorFrame:SetScript("OnUpdate", function()
			this.timeLeft = this.timeLeft - arg1
			if this.timeLeft <= 0 then
				self:DebugMessage("--- 视野监测结束 ---")
				this:Hide()
				return
			end

			this.checkTimer = this.checkTimer + arg1
			if this.checkTimer >= 0.2 then
				this.checkTimer = 0

				if not UnitExists("target") or UnitName("target") ~= this.bossName then
					if not TargetByName(this.bossName, true) then
						self:DebugMessage("--- 视野监测中找不到BOSS，停止监测 ---")
						this:Hide()
						return
					end
				end

				local hasLOS = UnitXP("inSight", "player", "target", "chains")

				if hasLOS and not this.warned then
					self:ShowAlert(
						"|cFFFF0000!!! 警告 !!!|r\n" .. this.bossSpell .. "即将爆发，注意躲避！",
						4
					)
					PlaySound("RAID_WARNING")
					self:DebugMessage("+++ 视野未遮挡，发出警告 +++")
					this.warned = true
				elseif not hasLOS and this.warned then
					self:ShowAlert("--- 视野已遮挡，你安全了 ---")
					this.warned = false
				end
			end
		end)
	end
end

------------------------------
--      Command Handler     --
------------------------------

function Automaton_KneelToQueen:RegisterSlashCommands()
	SlashCmdList["KNEELTOQUEEN"] = function(msg)
		self:KneelCommand(msg)
	end
	SLASH_KNEELTOQUEEN1 = "/kneel"
	SLASH_KNEELTOQUEEN2 = "/不想跪"
end

function Automaton_KneelToQueen:KneelCommand(msg)
	msg = string.lower(msg or "")
	if msg == "help" or msg == "?" then
		DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000<<<<<<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>|r")
		DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[自动下跪]|r |cFFFFFF00命令使用说明：|r")
		DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00>>> |r |cFFFFFF00/kneel 或 /不想跪 - 显示当前状态|r")
		DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00>>> |r |cFFFFFF00/kneel help - 显示帮助信息|r")
		DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00>>> |r |cFFFFFF00/kneel debug - 切换调试模式|r")
		DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00>>> |r |cFFFFFF00/kneel zone - 显示当前区域信息|r")
		DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00注意：主要功能通过Automaton配置界面启用/禁用|r")
		DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000<<<<<<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>|r")
		PlaySound("igQuestListOpen")
	elseif msg == "debug" then
		self.db.profile.debugMode = not self.db.profile.debugMode
		self.DEBUG = self.db.profile.debugMode
		DEFAULT_CHAT_FRAME:AddMessage(
			"|cFF00FF00[自动下跪]|r |cFFFFFF00调试模式: "
				.. (self.DEBUG and "|cFF00FF00已开启|r" or "|cFFFF0000已关闭|r")
		)
		PlaySound("igMainMenuOption")
	elseif msg == "zone" or msg == "区域" then
		self:UpdateZoneStatus()
		DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[自动下跪]|r |cFFFFFF00区域信息：|r")
		DEFAULT_CHAT_FRAME:AddMessage(
			"|cFF00FF00>>> |r |cFFFFFF00当前区域: " .. (self.currentZone or "未知") .. "|r"
		)
		DEFAULT_CHAT_FRAME:AddMessage(
			"|cFF00FF00>>> |r |cFFFFFF00当前子区域: " .. (self.currentSubZone or "无") .. "|r"
		)
		DEFAULT_CHAT_FRAME:AddMessage(
			"|cFF00FF00>>> |r |cFFFFFF00允许触发: "
				.. (self.isInAllowedZone and "|cFF00FF00是|r" or "|cFFFF0000否|r")
		)
		DEFAULT_CHAT_FRAME:AddMessage(
			"|cFF00FF00>>> |r |cFFFFFF00模块状态: "
				.. (self:IsEnabled() and "|cFF00FF00已启用|r" or "|cFFFF0000已禁用|r")
		)
	else
		self:UpdateZoneStatus()
		DEFAULT_CHAT_FRAME:AddMessage(
			"|cFF00FF00[自动下跪]|r |cFFFFFF00模块状态: "
				.. (Automaton:IsModuleActive("KneelToQueen") and "|cFF00FF00已启用|r" or "|cFFFF0000已禁用|r")
		)
		DEFAULT_CHAT_FRAME:AddMessage(
			"|cFF00FF00[自动下跪]|r |cFFFFFF00当前区域: " .. (self.currentZone or "未知") .. "|r"
		)
		DEFAULT_CHAT_FRAME:AddMessage(
			"|cFF00FF00[自动下跪]|r |cFFFFFF00当前子区域: " .. (self.currentSubZone or "无") .. "|r"
		)
		DEFAULT_CHAT_FRAME:AddMessage(
			"|cFF00FF00[自动下跪]|r |cFFFFFF00允许触发: "
				.. (self.isInAllowedZone and "|cFF00FF00是|r" or "|cFFFF0000否|r")
		)
		DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00使用 /automaton 配置界面来启用/禁用此功能|r")
		DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00使用 /kneel zone 查看当前区域状态|r")
	end
end

------------------------------
--      Event Handling      --
------------------------------

function Automaton_KneelToQueen:PLAYER_LOGIN()
	self:DebugMessage(">>> 自动下跪模块已加载。输入 /kneel help 或 /不想跪 help 查看帮助 <<<")
	PlaySound("igQuestListOpen")
end

function Automaton_KneelToQueen:CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE()
	-- 实时检查子区域，不再依赖缓存
	if GetSubZoneText() ~= self.allowedSubZone then
		self:DebugMessage("不在象棋大厅，忽略下跪事件")
		return
	end

	if self:CheckMessageForDebuff(arg1, self.debuffName) then
		self:DebugMessage(">>> 检测到" .. self.debuffName .. "效果，开始寻找目标... <<<")
		self:ShowAlert("检测到" .. self.debuffName .. "！\n正在寻找" .. self.targetName .. "...", 3)
		PlaySound("RAID_WARNING")

		self:CreateUpdateFrame()
		self.updateTimer = 0
		self.updateFrame:SetScript("OnUpdate", function()
			self.updateTimer = self.updateTimer + arg1
			if self.updateTimer >= 0.5 then
				self.updateTimer = 0

				if UnitIsDead("player") or UnitIsGhost("player") then
					self:DebugMessage("--- 玩家已死亡，停止寻找目标 --- ")
					self.updateFrame:SetScript("OnUpdate", nil)
					self.updateTimer = 0
					self:ShowAlert("玩家已死亡，停止寻找目标。")
				else
					if self:CheckAndKneel() then
						self:DebugMessage("+++ 成功执行下跪动作 +++")
					end
				end
			end
		end)
	end
end

function Automaton_KneelToQueen:CHAT_MSG_SPELL_AURA_GONE_SELF()
	-- 实时检查子区域
	if GetSubZoneText() ~= self.allowedSubZone then
		return
	end

	if self:CheckMessageForDebuff(arg1, self.debuffName) then
		self:DebugMessage(">>> " .. self.debuffName .. "效果已消失，停止寻找目标 <<<")
		if self.updateFrame then
			self.updateFrame:SetScript("OnUpdate", nil)
		end
		self.updateTimer = 0
	end
end

function Automaton_KneelToQueen:CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE()
	-- 实时检查子区域
	if GetSubZoneText() ~= self.allowedSubZone then
		return
	end

	if arg1 then
		self:DebugMessage("收到施法事件: " .. arg1)
		if self:CheckBossSpellCast(arg1) then
			self:DebugMessage(">>> 检测到BOSS技能施放 <<<")
		end
	end
end

------------------------------
--      Core Functions      --
------------------------------

function Automaton_KneelToQueen:DebugMessage(msg)
	if self.DEBUG then
		DEFAULT_CHAT_FRAME:AddMessage("|cFFFF9900[自动下跪调试]|r |cFFFFFF00" .. msg .. "|r")
	end
end

function Automaton_KneelToQueen:ShowAlert(msg, duration)
	if self.alertFrame then
		self.alertFrame.text:SetText(msg)
		self.alertFrame.timeLeft = duration or 3
		self.alertFrame.flashTimer = 0
		self.alertFrame.flashState = true
		self.alertFrame:Show()
		PlaySound("RAID_WARNING")
	end
end

function Automaton_KneelToQueen:StartLOSMonitoring(bossName, bossSpell, duration)
	self:CreateLOSMonitor()
	self.losMonitorFrame.timeLeft = duration or 4
	self.losMonitorFrame.checkTimer = 0
	self.losMonitorFrame.bossName = bossName
	self.losMonitorFrame.bossSpell = bossSpell
	self.losMonitorFrame.warned = false
	self.losMonitorFrame:Show()
	self:ShowAlert("+++ 开始视野监测，持续" .. duration .. "秒 +++")
end

function Automaton_KneelToQueen:CheckAndKneel()
	if UnitIsGhost("player") then
		self:DebugMessage("--- 玩家已死亡，停止下跪检查 --- ")
		if self.updateFrame then
			self.updateFrame:SetScript("OnUpdate", nil)
		end
		self.updateTimer = 0
		return true
	end

	if not IsBuffActive(self.debuffName) then
		return true
	end

	if not UnitExists("target") or UnitName("target") ~= self.targetName then
		if not TargetByName(self.targetName, true) then
			self:ShowAlert("未找到目标：" .. self.targetName)
			PlaySound("igQuestFailed")
			return false
		end
	end

	if CheckInteractDistance("target", 3) then
		TargetUnit("target")
		DoEmote("KNEEL")
		self:DebugMessage("+++ 目标在范围内，执行下跪 +++")
		self:ShowAlert("成功对" .. self.targetName .. "下跪！", 2)
		PlaySound("igQuestListComplete")
		if not IsBuffActive(self.debuffName) then
			return true
		end
	else
		self:ShowAlert("--- 目标不在范围内 ---")
		return false
	end
end

function Automaton_KneelToQueen:CheckMessageForDebuff(message, debuffName)
	if string.find(message, debuffName) then
		self:DebugMessage(">>> 检测到debuff消息: " .. message)
		return true
	end
	return false
end

function Automaton_KneelToQueen:CheckBossSpellCast(message)
	if string.find(message, self.bossName .. "开始施放" .. self.bossSpell) then
		self:ShowAlert(">>> 检测到BOSS技能: " .. message)
		self:DebugMessage(">>> 检测到BOSS技能: " .. message)
		self:StartLOSMonitoring(self.bossName, self.bossSpell, 4)

		local currentTarget = UnitName("target")
		self:DebugMessage("当前目标: " .. (currentTarget or "无"))

		if currentTarget and currentTarget == self.bossName then
			self:DebugMessage("+++ 当前目标已经是BOSS +++")
		else
			local oldTarget = currentTarget
			if not TargetByName(self.bossName, true) then
				self:DebugMessage("--- 尝试选择BOSS失败 ---")
				if oldTarget then
					TargetByName(oldTarget, true)
				end
				return false
			end
			self:DebugMessage("+++ 成功选中BOSS +++")
		end
		return true
	end
	return false
end
