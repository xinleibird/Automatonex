assert(Automaton, "Automaton not found!")

------------------------------
--      Localization      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_QuestItemBar")

L:RegisterTranslations("enUS", function()
	return {
		["QuestItemBar"] = "Quest Item Bar",
		["Shows usable quest items in a quick bar; click to use them."] = "Shows usable quest items in a quick bar; click to use them.",
		["Button Size"] = "Button Size",
		["Size of the quest item buttons"] = "Size of the quest item buttons",
		["Max Buttons"] = "Max Buttons",
		["Maximum number of items shown in the bar"] = "Maximum number of items shown in the bar",
		["Lock Position"] = "Lock Position",
		["Prevent the bar from being dragged"] = "Prevent the bar from being dragged",
		["Reset Position"] = "Reset Position",
		["Reset the bar to its default position"] = "Reset the bar to its default position",
		["Position reset to default."] = "Position reset to default.",
		["Drag the bar to move it; click an item to use it."] = "Drag the bar to move it; click an item to use it.",
	}
end)

L:RegisterTranslations("zhCN", function()
	return {
		["QuestItemBar"] = "任务物品快捷栏",
		["Shows usable quest items in a quick bar; click to use them."] = "在快捷栏中显示可用的任务物品，点击即可使用。",
		["Button Size"] = "按钮大小",
		["Size of the quest item buttons"] = "任务物品按钮的尺寸",
		["Max Buttons"] = "最大按钮数",
		["Maximum number of items shown in the bar"] = "快捷栏中最多显示的物品数量",
		["Lock Position"] = "锁定位置",
		["Prevent the bar from being dragged"] = "禁止拖动快捷栏",
		["Reset Position"] = "重置位置",
		["Reset the bar to its default position"] = "将快捷栏恢复到默认位置",
		["Position reset to default."] = "位置已重置到默认。",
		["Drag the bar to move it; click an item to use it."] = "拖动栏可移动位置；点击物品即可使用。",
	}
end)

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_QuestItemBar = Automaton:NewModule("QuestItemBar")
Automaton_QuestItemBar.modulename = L["QuestItemBar"]
Automaton_QuestItemBar.moduledesc = L["Shows usable quest items in a quick bar; click to use them."]

Automaton_QuestItemBar.options = {
	buttonSize = {
		type = "range",
		name = L["Button Size"],
		desc = L["Size of the quest item buttons"],
		min = 24,
		max = 48,
		step = 2,
		order = 2,
		get = function()
			return Automaton_QuestItemBar.db.profile.buttonSize
		end,
		set = function(v)
			Automaton_QuestItemBar.db.profile.buttonSize = v
			Automaton_QuestItemBar:Update()
		end,
	},
	maxButtons = {
		type = "range",
		name = L["Max Buttons"],
		desc = L["Maximum number of items shown in the bar"],
		min = 1,
		max = 20,
		step = 1,
		order = 3,
		get = function()
			return Automaton_QuestItemBar.db.profile.maxButtons
		end,
		set = function(v)
			Automaton_QuestItemBar.db.profile.maxButtons = v
			Automaton_QuestItemBar:Update()
		end,
	},
	lockPosition = {
		type = "toggle",
		name = L["Lock Position"],
		desc = L["Prevent the bar from being dragged"],
		order = 4,
		get = function()
			return Automaton_QuestItemBar.db.profile.lockPosition
		end,
		set = function(v)
			Automaton_QuestItemBar.db.profile.lockPosition = v
		end,
	},
	resetPosition = {
		type = "execute",
		name = L["Reset Position"],
		desc = L["Reset the bar to its default position"],
		order = 5,
		func = function()
			Automaton_QuestItemBar:ResetPosition()
		end,
	},
}

----------------------------------
--      Local Constants      --
----------------------------------

-- 任务物品类型（GetItemInfo 返回的物品类别），兼容中英文客户端
local QUEST_TYPE_EN = "Quest"
local QUEST_TYPE_ZH = "任务物品"

----------------------------------
--      Initialization      --
----------------------------------

function Automaton_QuestItemBar:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("QuestItemBar")
	Automaton:RegisterDefaults("QuestItemBar", "profile", {
		disabled = true,
		buttonSize = 36,
		maxButtons = 12,
		lockPosition = false,
		position = {
			point = "BOTTOM",
			relativePoint = "BOTTOM",
			x = 0,
			y = 150,
		},
	})
	Automaton:SetDisabledAsDefault(self, "QuestItemBar")
	self:RegisterOptions(self.options)

	self.buttons = {}
	self.questCache = {}

	-- 扫描用隐藏 tooltip（参考 shiqu.lua 的实现方式）
	self.scanTooltip = CreateFrame("GameTooltip", "Automaton_QIB_ScanTooltip", UIParent, "GameTooltipTemplate")
	self.scanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
	self.tooltipName = "Automaton_QIB_ScanTooltip"

	-- 默认位置（重置用）
	self.defaultPosition = {
		point = "BOTTOM",
		relativePoint = "BOTTOM",
		x = 0,
		y = 150,
	}

	-- 防抖计时器：背包更新频繁，合并后再刷新一次
	self._updateTimer = CreateFrame("Frame")
	self._updateTimer:Hide()
	self._updateTimer:SetScript("OnUpdate", function()
		local elapsed = arg1 or 0
		this._acc = (this._acc or 0) + elapsed
		if this._acc >= 0.15 then
			this:Hide()
			this._acc = 0
			Automaton_QuestItemBar:Update()
		end
	end)

	-- 诊断命令：/qibdebug 打印检测过程的真实返回，便于定位“不显示”问题
	SlashCmdList["QIBDEBUG"] = function()
		Automaton_QuestItemBar:DebugDetection()
	end
	SLASH_QIBDEBUG1 = "/qibdebug"
end

function Automaton_QuestItemBar:OnEnable()
	if not self.bar then
		self:CreateBar()
	end
	self:LoadPosition()
	self:RegisterEvent("BAG_UPDATE")
	self:RegisterEvent("BAG_UPDATE_COOLDOWN")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self.bar:Show()
	self:Update()
end

function Automaton_QuestItemBar:OnDisable()
	self:UnregisterAllEvents()
	if self.bar then
		self.bar:Hide()
	end
end

----------------------------------
--      UI Creation      --
----------------------------------

function Automaton_QuestItemBar:CreateBar()
	local frame = CreateFrame("Frame", "Automaton_QuestItemBar", UIParent)
	frame:SetFrameStrata("HIGH")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 8,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	frame:SetBackdropColor(0, 0, 0, 0.6)
	frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)

	-- 拖动栏体移动位置（锁定后禁止）
	frame:SetScript("OnDragStart", function()
		if Automaton_QuestItemBar.db.profile.lockPosition then
			return
		end
		this:StartMoving()
	end)
	frame:SetScript("OnDragStop", function()
		this:StopMovingOrSizing()
		local point, _, rel, x, y = this:GetPoint()
		if point then
			Automaton_QuestItemBar.db.profile.position = {
				point = point,
				relativePoint = rel,
				x = x,
				y = y,
			}
		end
	end)

	self.bar = frame
end

function Automaton_QuestItemBar:SetupButtonScripts(btn)
	btn:RegisterForDrag("LeftButton")
	btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	-- 从栏中把物品拖出（放到动作栏 / 交易等）
	btn:SetScript("OnDragStart", function()
		if this.bagID and this.slotID then
			PickupContainerItem(this.bagID, this.slotID)
		end
	end)
	btn:SetScript("OnReceiveDrag", function()
		if this.bagID and this.slotID then
			PickupContainerItem(this.bagID, this.slotID)
		end
	end)
	-- 点击使用（左键或右键均可使用）；
	-- Shift+点击 保留聊天框链接的默认行为
	btn:SetScript("OnClick", function()
		if IsShiftKeyDown() and this.bagID and this.slotID then
			local link = GetContainerItemLink(this.bagID, this.slotID)
			if link and ChatFrameEditBox and ChatFrameEditBox:IsVisible() then
				ChatFrameEditBox:Insert(link)
				return
			end
		end
		if this.bagID and this.slotID then
			UseContainerItem(this.bagID, this.slotID)
		end
	end)
	-- 悬停显示物品提示
	-- 关键坑（已验证）：本客户端 GameTooltip:SetBagItem 实际按“按钮 parent/自身的 ID”
	-- 定位，而非传入参数。parent(bar) 与按钮自身的 ID 默认都是 0，
	-- 不处理就会定位到 (0,0)=背包本身。故先把正确的背包/槽位 ID 设到
	-- parent(bar) 与按钮自身，再调用 SetBagItem，即可显示真实物品。
	btn:SetScript("OnEnter", function()
		local bid = this.bagID
		local sid = this.slotID
		if not (bid and sid) then
			return
		end
		this:GetParent():SetID(bid)
		this:SetID(sid)
		GameTooltip:SetOwner(this, "ANCHOR_LEFT")
		GameTooltip:SetBagItem(bid, sid)
		GameTooltip:Show()
	end)
	btn:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
end

-- 让按钮内部的子纹理（图标 / 边框 / 冷却圈）跟随按钮尺寸变化。
-- ContainerFrameItemButtonTemplate 的子纹理多为固定像素尺寸
-- （如 NormalTexture 边框图默认 46x46、IconTexture 默认 36x36），
-- 仅缩放按钮框架不会自动跟随，必须显式重置尺寸与锚点。
--
-- 注意：NormalTexture（槽位背景图 UI-Quickslot2）是按固定尺寸设计的，
-- 拉伸后会变成难看的深色色块（见截图），故直接隐藏它；
-- 图标填满按钮（留 1px 边距），边框/冷却圈铺满整按钮。
function Automaton_QuestItemBar:ResizeButton(btn, size)
	-- 图标：几乎填满按钮，仅留 1px 边距
	local icon = getglobal(btn:GetName() .. "IconTexture")
	if icon then
		icon:ClearAllPoints()
		icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
		icon:SetWidth(size - 2)
		icon:SetHeight(size - 2)
	end
	-- 槽位背景图（UI-Quickslot2）：固定尺寸纹理，拉伸后变成深色色块 → 隐藏
	local normal = getglobal(btn:GetName() .. "NormalTexture")
	if normal then
		normal:Hide()
	end
	-- 品质边框：铺满按钮边缘
	local border = getglobal(btn:GetName() .. "Border")
	if border then
		border:ClearAllPoints()
		border:SetAllPoints(btn)
	end
	-- 图标边框：跟随图标区域
	local iconBorder = getglobal(btn:GetName() .. "IconBorder")
	if iconBorder then
		iconBorder:ClearAllPoints()
		iconBorder:SetAllPoints(btn)
	end
	-- 冷却圈：覆盖整个按钮
	local cd = getglobal(btn:GetName() .. "Cooldown")
	if cd then
		cd:ClearAllPoints()
		cd:SetAllPoints(btn)
	end
end

----------------------------------
--      Quest Item Detection      --
--      自包含实现，移植自 Guda 的   --
--      ItemDetection / QuestItemBar  --
----------------------------------

-- 判断物品是否为任务物品，以及是否可用 / 起始任务
-- 通过链接缓存检测结果，避免每次背包更新都重复扫描 tooltip
function Automaton_QuestItemBar:CheckQuestItem(bag, slot, link)
	if self.questCache[link] then
		local c = self.questCache[link]
		return c.isQuest, c.isStarter, c.isUsable
	end

	local isQuest = false
	local isStarter = false
	local isUsable = false

	-- 主要判定来源：扫描背包物品的 tooltip。
	-- Guda 已验证：普通背包(0-4) 的 SetBagItem 可靠有效。
	self.scanTooltip:ClearLines()
	self.scanTooltip:SetBagItem(bag, slot)
	local numLines = self.scanTooltip:NumLines() or 0

	for i = 1, numLines do
		local left = getglobal(self.tooltipName .. "TextLeft" .. i)
		local right = getglobal(self.tooltipName .. "TextRight" .. i)
		local ltext = left and left:GetText() or ""
		local rtext = right and right:GetText() or ""
		local ll = string.lower(ltext)
		local rl = string.lower(rtext)

		-- 类别行：精确匹配“任务物品 / Quest”
		if ltext == QUEST_TYPE_ZH or rtext == QUEST_TYPE_ZH or ltext == QUEST_TYPE_EN or rtext == QUEST_TYPE_EN then
			isQuest = true
		end
		-- 起始任务（右键开始任务）——起始必为任务物品
		if
			string.find(ll, "开始")
			or string.find(rl, "开始")
			or string.find(ll, "begin")
			or string.find(rl, "begin")
			or string.find(ll, "start")
			or string.find(rl, "start")
		then
			isStarter = true
			isQuest = true
		end
		-- 使用效果（任务物品通常带“使用：/ Use:”）
		if
			string.find(ll, "使用")
			or string.find(rl, "使用")
			or string.find(ll, "use:")
			or string.find(rl, "use:")
		then
			isUsable = true
		end
	end

	-- 兜底：GetItemInfo 类别（扫描全部返回值，绕开本客户端布局错位）。
	-- 用 pcall 防止未缓存时抛错；仅在 tooltip 尚未判定为任务物品时补充。
	if not isQuest then
		local ok, itemInfo = pcall(GetItemInfo, link)
		if ok and itemInfo then
			for _, v in ipairs(itemInfo) do
				if v == QUEST_TYPE_EN or v == QUEST_TYPE_ZH then
					isQuest = true
					break
				end
			end
		end
	end

	-- 仅当 tooltip 数据看起来完整（>=2 行）才缓存，
	-- 避免 GetItemInfo / tooltip 未加载时的占位结果被永久缓存（缓存污染）。
	if numLines >= 2 then
		self.questCache[link] = {
			isQuest = isQuest,
			isStarter = isStarter,
			isUsable = isUsable,
		}
	end
	return isQuest, isStarter, isUsable
end

-- 扫描背包（0-4）收集可显示的任务物品
function Automaton_QuestItemBar:ScanBagsForQuestItems()
	local items = {}
	for bag = 0, 4 do
		local numSlots = GetContainerNumSlots(bag)
		for slot = 1, numSlots do
			local texture, count = GetContainerItemInfo(bag, slot)
			if texture then
				local link = GetContainerItemLink(bag, slot)
				if link then
					local isQuest, isStarter, isUsable = self:CheckQuestItem(bag, slot, link)
					-- 显示：任务物品 且 （可用 或 起始任务）；
					-- 纯交任务物品（无使用/起始效果）不显示
					if isQuest and (isUsable or isStarter) then
						table.insert(items, {
							bagID = bag,
							slotID = slot,
							link = link,
							texture = texture,
							count = count,
						})
					end
				end
			end
		end
	end
	return items
end

----------------------------------
--      Bar Update      --
----------------------------------

function Automaton_QuestItemBar:Update()
	if not self.bar then
		return
	end
	local frame = self.bar

	local items = self:ScanBagsForQuestItems()
	if table.getn(items) == 0 then
		frame:Hide()
		return
	end
	frame:Show()

	local size = self.db.profile.buttonSize
	local spacing = 4
	local pad = 6
	local maxB = self.db.profile.maxButtons
	local n = math.min(table.getn(items), maxB)

	for i = 1, n do
		local item = items[i]
		local btn = self.buttons[i]
		if not btn then
			btn = CreateFrame("Button", "Automaton_QIB_Btn" .. i, frame, "ContainerFrameItemButtonTemplate")
			self.buttons[i] = btn
			self:SetupButtonScripts(btn)
		end
		btn.bagID = item.bagID
		btn.slotID = item.slotID
		btn.link = item.link

		SetItemButtonTexture(btn, item.texture)
		SetItemButtonCount(btn, item.count or 1)

		btn:SetWidth(size)
		btn:SetHeight(size)
		self:ResizeButton(btn, size)

		local cd = getglobal(btn:GetName() .. "Cooldown")
		if cd then
			local startT, duration, enable = GetContainerItemCooldown(item.bagID, item.slotID)
			if startT and duration and duration > 0 and enable == 1 then
				CooldownFrame_SetTimer(cd, startT, duration, enable)
			else
				cd:Hide()
			end
		end

		btn:ClearAllPoints()
		btn:SetPoint("TOPLEFT", frame, "TOPLEFT", pad + (i - 1) * (size + spacing), -pad)
		btn:Show()
	end

	-- 隐藏多余的按钮
	for j = n + 1, table.getn(self.buttons) do
		self.buttons[j]:Hide()
	end

	-- 根据按钮数量调整栏尺寸
	frame:SetWidth(pad * 2 + n * (size + spacing) - spacing)
	frame:SetHeight(size + pad * 2)
end

----------------------------------
--      Cooldown Refresh      --
----------------------------------

function Automaton_QuestItemBar:UpdateCooldowns()
	if not self.buttons then
		return
	end
	for _, btn in ipairs(self.buttons) do
		if btn:IsShown() and btn.bagID and btn.slotID then
			local cd = getglobal(btn:GetName() .. "Cooldown")
			if cd then
				local startT, duration, enable = GetContainerItemCooldown(btn.bagID, btn.slotID)
				if startT and duration and duration > 0 and enable == 1 then
					CooldownFrame_SetTimer(cd, startT, duration, enable)
				else
					cd:Hide()
				end
			end
		end
	end
end

----------------------------------
--      Position Management      --
----------------------------------

function Automaton_QuestItemBar:LoadPosition()
	local pos = self.db.profile.position or self.defaultPosition
	self.bar:ClearAllPoints()
	self.bar:SetPoint(pos.point, UIParent, pos.relativePoint or pos.point, pos.x, pos.y)
end

function Automaton_QuestItemBar:ResetPosition()
	self.db.profile.position = {
		point = self.defaultPosition.point,
		relativePoint = self.defaultPosition.relativePoint,
		x = self.defaultPosition.x,
		y = self.defaultPosition.y,
	}
	self:LoadPosition()
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[任务物品快捷栏]|r " .. L["Position reset to default."])
	end
end

----------------------------------
--      Events      --
----------------------------------

function Automaton_QuestItemBar:BAG_UPDATE()
	self:ScheduleUpdate()
end

function Automaton_QuestItemBar:BAG_UPDATE_COOLDOWN()
	if self.bar and self.bar:IsShown() then
		self:UpdateCooldowns()
	end
end

function Automaton_QuestItemBar:PLAYER_ENTERING_WORLD()
	-- 切换角色 / 升级后清空检测缓存（物品属性可能因等级/语言变化）
	self.questCache = {}
	-- 延迟刷新：进服瞬间物品数据可能尚未完全加载，等一拍再检测
	self:ScheduleUpdate()
end

function Automaton_QuestItemBar:ScheduleUpdate()
	self._updateTimer._acc = 0
	self._updateTimer:Show()
end

----------------------------------
--      诊断（/qibdebug）      --
----------------------------------

-- 打印每个背包物品的真实检测数据，定位“栏不显示”问题时用
function Automaton_QuestItemBar:DebugDetection()
	if not DEFAULT_CHAT_FRAME then
		return
	end
	DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[任务物品快捷栏 诊断]|r 背包物品检测情况：")
	for bag = 0, 4 do
		local numSlots = GetContainerNumSlots(bag)
		for slot = 1, numSlots do
			local texture = GetContainerItemInfo(bag, slot)
			if texture then
				local link = GetContainerItemLink(bag, slot)
				if link then
					local info = { GetItemInfo(link) }
					local cat = "?"
					for _, v in ipairs(info) do
						if v == "Quest" or v == "任务物品" then
							cat = tostring(v)
						end
					end
					self.scanTooltip:ClearLines()
					self.scanTooltip:SetBagItem(bag, slot)
					local n = self.scanTooltip:NumLines() or 0
					local lines = {}
					for i = 1, math.min(n, 6) do
						local l = getglobal(self.tooltipName .. "TextLeft" .. i)
						lines[table.getn(lines) + 1] = (l and l:GetText() or "")
					end
					local isQ, isS, isU = self:CheckQuestItem(bag, slot, link)
					DEFAULT_CHAT_FRAME:AddMessage(
						string.format(
							"bag%d slot%d | link=%s | 类别=%s | tip行数=%d | quest=%s starter=%s usable=%s",
							bag,
							slot,
							link,
							cat,
							n,
							tostring(isQ),
							tostring(isS),
							tostring(isU)
						)
					)
					DEFAULT_CHAT_FRAME:AddMessage("    tip: " .. table.concat(lines, " | "))
				end
			end
		end
	end
	DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[诊断结束]|r")
end
