------------------------------
--      Are you local?      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton")

-- 安全地获取职业颜色
local function GetSafeClassColor()
	local _, playerClass = UnitClass("player")
	if playerClass and RAID_CLASS_COLORS and RAID_CLASS_COLORS[playerClass] then
		return RAID_CLASS_COLORS[playerClass]
	end
	return { r = 0.5, g = 0.5, b = 0.5 }
end

local classColor = GetSafeClassColor()
local colorR, colorG, colorB = classColor.r, classColor.g, classColor.b

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function()
	return {
		["Enabled"] = "启用",
		["Suspend/resume this module"] = "暂停/恢复该模块",
		["Debugging"] = "调试",
		["Toggle debugging for this module"] = "开关该模块的调试模式",
		["Search Modules"] = "搜索模块",
		["Search for modules by name or description"] = "按名称或描述搜索模块",
		["Clear Search"] = "清除搜索",
		["Automaton"] = "Automaton",
		["Modules"] = "模块",
		["No modules found"] = "未找到匹配模块",
		["Click to configure"] = "点击配置",
		["Close"] = "关闭",
		["General"] = "常规",
		["Module Settings"] = "模块设置",
		["Back"] = "返回",
		["Select a module"] = "请选择一个模块",
		["Move up"] = "上移",
		["Move down"] = "下移",
		["Reset order"] = "重置顺序",
		["Move this module up in the list"] = "在列表中上移该模块",
		["Move this module down in the list"] = "在列表中下移该模块",
		["Reset module order to default"] = "将模块顺序恢复为默认",
		["Home"] = "主页",
		["Displayed Modules"] = "显示的模块",
		["Hidden Modules"] = "隐藏的模块",
		["Show in list"] = "在列表中显示",
		["Modules total"] = "模块总数",
		["Enabled count"] = "已启用",
		["Disabled count"] = "已禁用",
		["Home description"] = "概览与模块管理",
	}
end)

---------------------------------
--      Addon Declaration      --
---------------------------------

Automaton = AceLibrary("AceAddon-2.0"):new(
	"AceConsole-2.0",
	"FuBarPlugin-2.0",
	"AceEvent-2.0",
	"AceDebug-2.0",
	"AceDB-2.0",
	"AceModuleCore-2.0",
	"AceHook-2.1"
)
Automaton:SetModuleMixins("AceConsole-2.0", "AceEvent-2.0", "AceDebug-2.0", "AceHook-2.1")

function Automaton:print(text, title)
	if text == nil or text == "" then
		return
	end
	if DEFAULT_CHAT_FRAME then
		if title then
			DEFAULT_CHAT_FRAME:AddMessage("|CFF00AB00" .. title .. "：|r " .. text)
		else
			DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00[|r|cff00ffffAutomaton|r|cffffcc00]|r " .. text)
		end
	end
end

Automaton.modulePrototype.print = Automaton.print
Automaton.version = tonumber(string.sub("$1.1.2$", 12, -3))

-- 窗口和控件变量
Automaton.mainFrame = nil
Automaton.selectedModule = nil
Automaton.moduleList = {}

-- 主页（概览页）在模块列表中的哨兵键，不会与任何真实模块名冲突
local HOME_KEY = "__automaton_home__"
Automaton.searchText = ""
Automaton._moduleButtons = {}

-- UI 缩放状态
Automaton.uiScale = 1.0
Automaton.UI_SCALE_MIN = 0.5
Automaton.UI_SCALE_MAX = 1.5
Automaton.UI_SCALE_STEP = 0.1

---------------------------------
--      数据库与命令注册      --
---------------------------------

Automaton.t = {}
Automaton:RegisterDB("AutomatonDB")

Automaton:RegisterChatCommand({ "/autocl", "/automatoncl" }, function()
	Automaton:ToggleMainWindow()
end)
Automaton:RegisterChatCommand({ "/auto", "/automaton" }, function()
	Automaton:ToggleMainWindow()
end)

---------------------------------
--      物品管理功能           --
---------------------------------

CHATITEMDB = {}

function Automaton:AddItem(t, item, title)
	local itemid = string.match(item, "%d+")
	if itemid then
		itemid = tonumber(itemid)
		local _, link = GetItemInfo(itemid)
		if link then
			if t[itemid] then
				self:print("物品已存在无需添加", title)
			else
				t[itemid] = link
				self:print("成功添加物品：" .. link, title)
			end
		else
			self:print("物品ID不存在或未加载", title)
		end
	else
		self:print("物品ID无效添加失败", title)
	end
end

function Automaton:RemoveItem(t, item, title)
	local itemid = string.match(item, "%d+")
	if itemid then
		itemid = tonumber(itemid)
		local _, link = GetItemInfo(itemid)
		if link then
			if t[itemid] then
				self:print("物品移除成功：" .. t[itemid], title)
				t[itemid] = nil
			else
				self:print("物品不存在于列表中", title)
			end
		else
			self:print("物品ID不存在或未加载", title)
		end
	else
		self:print("物品ID无效移除失败", title)
	end
end

function Automaton:ItemListAll(t, title)
	self:print("列表内容:", title)
	for k, v in pairs(t) do
		self:print("物品名称：" .. v .. " 物品ID:" .. k, title)
	end
end

---------------------------------
--      模块原型扩展           --
---------------------------------

function Automaton.modulePrototype:RegisterOptions(options)
	options = options or {}
	options.enabled = {
		order = 1,
		type = "toggle",
		name = L["Enabled"],
		desc = L["Suspend/resume this module"],
		get = function()
			return Automaton:IsModuleActive(self.name)
		end,
		set = function(v)
			Automaton:ToggleModuleActive(self.name, v)
		end,
	}
	self._options = options
	self._optionOrder = {}
	for k, v in pairs(options) do
		table.insert(self._optionOrder, { key = k, order = v.order or 999, data = v })
	end
	table.sort(self._optionOrder, function(a, b)
		return a.order < b.order
	end)
	-- 如果主窗口已打开且当前选中的是该模块，刷新右侧设置面板
	if Automaton.mainFrame and Automaton.mainFrame:IsShown() and Automaton.selectedModule == self.name then
		Automaton:RefreshModuleSettings(self.name)
	end
	-- 刷新左侧列表（若可见）
	if Automaton.mainFrame and Automaton.mainFrame:IsShown() then
		Automaton:PopulateModuleList()
	end
end

---------------------------------
--      初始化                 --
---------------------------------

function Automaton:OnInitialize()
	Automaton.gratuity = AceLibrary("Gratuity-2.0")
	Automaton.Deformat = AceLibrary("Deformat-2.0")
	self.ver = 20241222
	self.db.profile.searchText = self.db.profile.searchText or ""
	self.searchText = self.db.profile.searchText
	self.db.profile.uiScale = self.db.profile.uiScale or 1.0
	self.uiScale = self.db.profile.uiScale
	self.db.profile.moduleOrder = self.db.profile.moduleOrder or {}
	self.db.profile.hiddenModules = self.db.profile.hiddenModules or {}
	self.db.profile.lastModule = self.db.profile.lastModule or HOME_KEY
	-- 一次性把旧版本的 moduleOrder 按自然排序归一化，避免纯字典序/注册顺序导致乱序
	self.db.profile.moduleOrderVersion = self.db.profile.moduleOrderVersion or 0
	if self.db.profile.moduleOrderVersion < 1 then
		self:NormalizeModuleOrder()
		self.db.profile.moduleOrderVersion = 1
	end
	self:CreateMainWindow()
	if not self.db.profile.position then
		self.db.profile.position = "LEFT"
	end
end

function Automaton:OnEnable()
	self.itemDB = CHATITEMDB
end

function Automaton:SetDisabledAsDefault(object, name)
	if object.db.profile.disabled then
		object.db.profile.disabled = false
		self:ToggleModuleActive(name, false)
	end
end

---------------------------------
--      UI 背景样式定义        --
---------------------------------

local backdrop = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 16,
	edgeSize = 8,
	insets = { left = 2, right = 2, top = 2, bottom = 2 },
}

local backdrop_window = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	tile = true,
	tileSize = 16,
	edgeSize = 16,
	insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local backdrop_border = {
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 16,
	edgeSize = 16,
	insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

---------------------------------
--   扁平蓝灰主题配色与辅助    --
---------------------------------

-- 借鉴 Cat2 的扁平蓝灰设计语言，统一主窗口与控件外观
local FLAT_BG = "Interface\\Buttons\\WHITE8X8"

-- 蓝灰主题常用色（r, g, b, a）
local FLAT = {
	window = { 0.04, 0.05, 0.08, 0.98 }, -- 主窗口底色
	panel = { 0.07, 0.08, 0.12, 0.92 }, -- 左右面板底色
	row = { 0.10, 0.12, 0.16, 0.95 }, -- 行/卡片底色
	input = { 0.06, 0.09, 0.14, 0.98 }, -- 输入框底色
	border = { 0.30, 0.40, 0.52, 0.90 }, -- 常规边框
	title = { 1.00, 0.82, 0.20 }, -- 标题金色
	accent = { 0.50, 0.80, 1.00 }, -- 蓝色强调
	text = { 0.82, 0.86, 0.92 }, -- 正文浅色
	dim = { 0.55, 0.60, 0.66 }, -- 次要文字
}

-- 给控件套统一扁平背景（WHITE8X8 纯色 + 1px 边框）
local function ApplyFlatBackdrop(frame, color, borderColor)
	if not frame then
		return
	end
	frame:SetBackdrop({
		bgFile = FLAT_BG,
		edgeFile = FLAT_BG,
		edgeSize = 1,
		insets = { left = 1, right = 1, top = 1, bottom = 1 },
	})
	color = color or FLAT.panel
	frame:SetBackdropColor(color[1], color[2], color[3], color[4])
	borderColor = borderColor or FLAT.border
	frame:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
end

-- 给按钮补四边独立纹理边框，避免 backdrop 边框在 UI 缩放下粗细不均
local function AddFlatBorder(frame, color)
	if not frame then
		return
	end
	color = color or FLAT.border
	local function makeBorder(anchor1, rel1, x1, y1, anchor2, rel2, x2, y2)
		local b = frame:CreateTexture(nil, "OVERLAY")
		b:SetTexture(FLAT_BG)
		b:SetPoint(anchor1, frame, rel1, x1, y1)
		b:SetPoint(anchor2, frame, rel2, x2, y2)
		b:SetVertexColor(color[1], color[2], color[3], color[4])
		return b
	end
	local top = makeBorder("TOPLEFT", "TOPLEFT", 0, 0, "TOPRIGHT", "TOPRIGHT", 0, 0)
	top:SetHeight(1)
	local bottom = makeBorder("BOTTOMLEFT", "BOTTOMLEFT", 0, 0, "BOTTOMRIGHT", "BOTTOMRIGHT", 0, 0)
	bottom:SetHeight(1)
	local left = makeBorder("TOPLEFT", "TOPLEFT", 0, 0, "BOTTOMLEFT", "BOTTOMLEFT", 0, 0)
	left:SetWidth(1)
	local right = makeBorder("TOPRIGHT", "TOPRIGHT", 0, 0, "BOTTOMRIGHT", "BOTTOMRIGHT", 0, 0)
	right:SetWidth(1)
end

-- 创建自绘扁平按钮（execute / 循环选择共用），返回 button 和文字引用
local function CreateFlatButton(parent, width, height, labelText)
	local btn = CreateFrame("Button", nil, parent)
	btn.autoType = "button"
	btn:SetWidth(width)
	btn:SetHeight(height)
	ApplyFlatBackdrop(btn, FLAT.input, FLAT.border)
	AddFlatBorder(btn, FLAT.border)

	local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	text:SetPoint("CENTER", btn, "CENTER", 0, 0)
	text:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
	text:SetTextColor(FLAT.text[1], FLAT.text[2], FLAT.text[3])
	text:SetText(labelText or "")
	btn.text = text

	-- 悬停提亮 + 文字变金；按下文字轻微下移
	btn:SetScript("OnEnter", function()
		btn:SetBackdropColor(0.12, 0.40, 0.58, 1)
		text:SetTextColor(1, 0.84, 0.28)
	end)
	btn:SetScript("OnLeave", function()
		btn:SetBackdropColor(FLAT.input[1], FLAT.input[2], FLAT.input[3], FLAT.input[4])
		text:SetTextColor(FLAT.text[1], FLAT.text[2], FLAT.text[3])
	end)
	btn:SetScript("OnMouseDown", function()
		btn:SetBackdropColor(0.05, 0.12, 0.18, 1)
		text:ClearAllPoints()
		text:SetPoint("CENTER", btn, "CENTER", 1, -1)
	end)
	btn:SetScript("OnMouseUp", function()
		btn:SetBackdropColor(0.12, 0.40, 0.58, 1)
		text:ClearAllPoints()
		text:SetPoint("CENTER", btn, "CENTER", 0, 0)
	end)
	return btn, text
end

-- 创建自绘扁平复选框（勾选 = 在列表中显示），返回带 SetChecked/GetChecked 的按钮
-- 用居中 accent 色小方块作为“已勾选”指示，避免依赖字体对 ✓ 字形的支持（1.12 中文客户端）
local function CreateFlatCheckbox(parent)
	local btn = CreateFrame("Button", nil, parent)
	btn:SetWidth(16)
	btn:SetHeight(16)
	ApplyFlatBackdrop(btn, FLAT.input, FLAT.border)
	AddFlatBorder(btn, FLAT.border)

	-- “已勾选”指示：居中的小方块（accent 色），勾选时显示
	local mark = btn:CreateTexture(nil, "OVERLAY")
	mark:SetTexture(FLAT_BG)
	mark:SetWidth(9)
	mark:SetHeight(9)
	mark:SetPoint("CENTER", btn, "CENTER", 0, 0)
	mark:SetVertexColor(FLAT.accent[1], FLAT.accent[2], FLAT.accent[3], 1)
	mark:Hide()
	btn.mark = mark

	btn.checked = false
	function btn:SetChecked(v)
		self.checked = v and true or false
		if self.checked then
			self.mark:Show()
		else
			self.mark:Hide()
		end
	end
	function btn:GetChecked()
		return self.checked
	end
	btn:SetScript("OnClick", function()
		btn:SetChecked(not btn.checked)
		if btn._onChange then
			btn._onChange(btn.checked)
		end
	end)
	btn:SetScript("OnEnter", function()
		btn:SetBackdropColor(0.12, 0.40, 0.58, 1)
	end)
	btn:SetScript("OnLeave", function()
		btn:SetBackdropColor(FLAT.input[1], FLAT.input[2], FLAT.input[3], FLAT.input[4])
	end)
	return btn
end

---------------------------------
--   对外暴露 FLAT 风格工具    --
---------------------------------

-- 立刻暴露：紧跟 CreateFlatButton 定义后，避免后续顶层代码出错导致本块未执行
-- 供其他模块复用统一扁平蓝灰风格（sTrade / CDSafe 等自绘窗口）
Automaton.FLAT = FLAT
Automaton.FLAT_BG = FLAT_BG
Automaton.ApplyFlatBackdrop = ApplyFlatBackdrop
Automaton.AddFlatBorder = AddFlatBorder
Automaton.CreateFlatButton = CreateFlatButton

-- 当前打开的下拉菜单（全局唯一，避免多个菜单同时打开、切换模块时残留）
local currentDropdownMenu = nil

-- 关闭当前打开的下拉菜单
local function CloseDropdownMenu()
	if currentDropdownMenu then
		currentDropdownMenu:Hide()
		currentDropdownMenu = nil
	end
end

-- 打开指定下拉菜单（先关闭已打开的菜单）
local function OpenDropdownMenu(menu)
	if not menu then
		return
	end
	if currentDropdownMenu and currentDropdownMenu ~= menu then
		currentDropdownMenu:Hide()
	end
	currentDropdownMenu = menu
end

-- 滚动位置限制 + 同步滚动条（参考 Cat2 ui.SetScrollPosition）
local function SetScrollPosition(scrollFrame, slider, value)
	local maximum = scrollFrame.maxScroll or 0
	if value < 0 then
		value = 0
	end
	if value > maximum then
		value = maximum
	end
	if slider then
		slider:SetValue(value)
	end
	scrollFrame:SetVerticalScroll(value)
end

-- 刷新滚动条范围（参考 Cat2 ui.UpdateScrollBar）
local function UpdateScrollBar(scrollFrame, slider, contentHeight)
	scrollFrame:UpdateScrollChildRect()
	local maximum = contentHeight - scrollFrame:GetHeight()
	if maximum < 0 then
		maximum = 0
	end
	scrollFrame.maxScroll = maximum
	if slider then
		slider:SetMinMaxValues(0, maximum)
		if maximum <= 0 then
			slider:SetAlpha(0.28)
		else
			slider:SetAlpha(1)
		end
	end
	SetScrollPosition(scrollFrame, slider, scrollFrame:GetVerticalScroll())
end

-- 创建滚动区域（ScrollFrame + 自定义 Slider 滚动条，参考 Cat2 ui.CreateScrollArea）
local function CreateScrollArea(parent)
	local scrollFrame = CreateFrame("ScrollFrame", nil, parent)
	scrollFrame:EnableMouse(true)
	-- 1.12 vanilla 没有 SetClipsChildren 方法（Legion 7.0+ 才有），用 pcall 兼容
	if scrollFrame.SetClipsChildren then
		scrollFrame:SetClipsChildren(true)
	end

	local content = CreateFrame("Frame", nil, scrollFrame)
	content:EnableMouse(true)
	local hitArea = content:CreateTexture(nil, "BACKGROUND")
	hitArea:SetAllPoints()
	hitArea:SetTexture(FLAT_BG)
	hitArea:SetVertexColor(0, 0, 0, 0.01)
	content:SetScript("OnMouseDown", function() end)
	content:SetScript("OnMouseUp", function() end)
	scrollFrame:SetScrollChild(content)

	-- 自定义滚动条（Slider）
	local slider = CreateFrame("Slider", nil, parent)
	slider:SetOrientation("VERTICAL")
	slider:SetWidth(8)
	slider:SetFrameLevel(parent:GetFrameLevel() + 10)
	slider:SetMinMaxValues(0, 0)
	slider:SetValueStep(1)

	local track = slider:CreateTexture(nil, "BACKGROUND")
	track:SetTexture(FLAT_BG)
	track:SetAllPoints()
	track:SetVertexColor(0.05, 0.06, 0.08, 0.95)
	slider:SetThumbTexture(FLAT_BG)
	slider:SetScript("OnValueChanged", function()
		scrollFrame:SetVerticalScroll(slider:GetValue())
	end)

	local thumb = slider:GetThumbTexture()
	if thumb then
		thumb:SetWidth(8)
		thumb:SetHeight(30)
		thumb:SetVertexColor(FLAT.accent[1], FLAT.accent[2], FLAT.accent[3], 0.95)
	end

	scrollFrame:EnableMouseWheel(true)
	scrollFrame:SetScript("OnMouseWheel", function()
		-- 1.12 的 OnMouseWheel 参数通过全局 arg1 传递（非函数参数 delta）
		SetScrollPosition(scrollFrame, slider, scrollFrame:GetVerticalScroll() - (arg1 or 0) * 70)
	end)

	return scrollFrame, content, slider
end

---------------------------------
--      拖拽排序相关辅助函数   --
---------------------------------

-- 拖拽排序相关：跟随光标的预览块（dragGhost）、落点指示线（dropIndicator）
local dragGhost = nil
local dropIndicator = nil
local ROW_STEP = 26 -- 行高(24) + 行间距(2)，与 PopulateModuleList 中的行偏移一致

-- 鼠标是否位于列表可视区内（落点判定用）
local function IsCursorInsideList()
	local main = Automaton.mainFrame
	if not main or not main.listScroll then
		return false
	end
	local scale = UIParent:GetScale()
	local x, y = GetCursorPosition()
	x = x / scale
	y = y / scale
	local s = main.listScroll
	local l, r, b, t = s:GetLeft(), s:GetRight(), s:GetBottom(), s:GetTop()
	if not l or not r or not b or not t then
		return false
	end
	return x >= l and x <= r and y >= b and y <= t
end

-- 根据光标在列表中的位置计算应插入的槽位（1-based，含半行偏移，落点更自然）
local function GetModuleDropIndex()
	local main = Automaton.mainFrame
	if not main or not main.listContainer then
		return nil
	end
	local scale = UIParent:GetScale()
	local x, y = GetCursorPosition()
	x = x / scale
	y = y / scale
	local top = main.listContainer:GetTop()
	if not top then
		return nil
	end
	local rel = top - y + ROW_STEP / 2
	local idx = math.floor(rel / ROW_STEP) + 1
	local n = table.getn(Automaton.db.profile.moduleOrder)
	if n == 0 then
		return nil
	end
	if idx < 1 then
		idx = 1
	end
	if idx > n then
		idx = n
	end
	return idx
end

-- 刷新落点指示线位置（相对 UIParent 虚拟坐标，随列表滚动自动正确）
local function UpdateDropIndicator()
	if not dropIndicator then
		return
	end
	if not dragGhost or not dragGhost:IsVisible() then
		dropIndicator:Hide()
		return
	end
	local main = Automaton.mainFrame
	if not main or not main.listContainer or not IsCursorInsideList() then
		dropIndicator:Hide()
		return
	end
	local idx = GetModuleDropIndex()
	if not idx then
		dropIndicator:Hide()
		return
	end
	local c = main.listContainer
	local top = c:GetTop()
	local left = c:GetLeft()
	if not top or not left then
		dropIndicator:Hide()
		return
	end
	Automaton._dropIndex = idx
	dropIndicator:SetWidth(c:GetWidth())
	dropIndicator:ClearAllPoints()
	dropIndicator:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top - (idx - 1) * ROW_STEP)
	dropIndicator:Show()
end

-- 将预览块定位到光标，并同步刷新落点指示线
local function UpdateDragGhost()
	if not dragGhost or not dragGhost:IsVisible() then
		if dropIndicator then
			dropIndicator:Hide()
		end
		return
	end
	local scale = UIParent:GetScale()
	local x, y = GetCursorPosition()
	x = x / scale
	y = y / scale
	dragGhost:ClearAllPoints()
	dragGhost:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
	UpdateDropIndicator()
end

-- 创建拖拽预览块与落点指示线（只创建一次）
local function CreateDragGhost()
	if dragGhost then
		return
	end
	dragGhost = CreateFrame("Frame", nil, UIParent)
	dragGhost:SetWidth(220)
	dragGhost:SetHeight(24)
	dragGhost:SetFrameStrata("TOOLTIP")
	dragGhost:SetFrameLevel(20)
	dragGhost:EnableMouse(false)
	ApplyFlatBackdrop(dragGhost, FLAT.row, FLAT.border)
	local name = dragGhost:CreateFontString(nil, "OVERLAY", "GameFontWhite")
	name:SetFont(STANDARD_TEXT_FONT, 11)
	name:SetJustifyH("LEFT")
	name:SetTextColor(1, 0.82, 0.2)
	name:SetPoint("LEFT", dragGhost, "LEFT", 8, 0)
	name:SetPoint("RIGHT", dragGhost, "RIGHT", -8, 0)
	dragGhost.nameText = name
	dragGhost:Hide()

	dropIndicator = CreateFrame("Frame", nil, UIParent)
	dropIndicator:SetHeight(2)
	dropIndicator:SetFrameStrata("TOOLTIP")
	dropIndicator:SetFrameLevel(19)
	dropIndicator:EnableMouse(false)
	local tex = dropIndicator:CreateTexture(nil, "ARTWORK")
	tex:SetAllPoints()
	tex:SetTexture("Interface\\Buttons\\WHITE8X8")
	tex:SetVertexColor(1, 0.84, 0.28, 1)
	dropIndicator:Hide()

	-- 暴露到 Automaton，供 BeginModuleDrag / EndModuleDrag / 窗口隐藏清理引用
	Automaton.dragGhost = dragGhost
	Automaton.dropIndicator = dropIndicator
end

-- 开始拖拽某个模块：显示跟随光标的预览块并淡化原行
function Automaton:BeginModuleDrag(moduleName, row)
	if not self.dragGhost then
		return
	end
	self._dragging = true
	self._dragModule = moduleName
	self._dragRow = row
	local m = self.modules[moduleName]
	local displayName = (m and (m.modulename or m.name)) or moduleName
	self.dragGhost.nameText:SetText(displayName)
	self.dragGhost:Show()
	if row then
		row:SetAlpha(0.3)
	end
	GameTooltip:Hide()
	UpdateDragGhost()
end

-- 结束拖拽：若光标仍在列表内则把模块移动到目标槽位并重建列表，否则放弃
function Automaton:EndModuleDrag(moduleName)
	self._dragging = false
	self._lastDragEndTime = GetTime()
	if self.dragGhost then
		self.dragGhost:Hide()
	end
	if self.dropIndicator then
		self.dropIndicator:Hide()
	end
	if self._dragRow then
		self._dragRow:SetAlpha(1)
		self._dragRow = nil
	end
	local inside = IsCursorInsideList()
	local target = GetModuleDropIndex()
	self._dragModule = nil
	self._dropIndex = nil
	if not inside or not target then
		-- 拖到列表外，放弃本次移动（保持原顺序），仍刷新以清除淡化
		self:PopulateModuleList()
		return
	end
	self:ReorderModuleToIndex(moduleName, target)
	self:PopulateModuleList()
end

---------------------------------
--      主窗口创建 (左右分栏) --
---------------------------------

function Automaton:CreateMainWindow()
	if self.mainFrame then
		return
	end

	local f = CreateFrame("Frame", "AutomatonMainFrame", UIParent)
	f:SetWidth(660)
	f:SetHeight(500)
	f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	f:SetMovable(true)
	f:EnableMouse(true)
	-- 窗口拖动：直接在 f 上注册拖拽。模块行自身也已 RegisterForDrag，
	-- 按在哪一行就由那一行接管（拖拽排序），按在标题/空白处就由 f 接管（移动窗口），互不冲突。
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function()
		f:StartMoving()
	end)
	f:SetScript("OnDragStop", function()
		f:StopMovingOrSizing()
	end)
	f:SetClampedToScreen(true)
	f:SetFrameStrata("DIALOG")
	ApplyFlatBackdrop(f, FLAT.window, FLAT.border)
	f:EnableKeyboard(true)
	f:SetScript("OnKeyDown", function()
		if arg1 == "ESCAPE" then
			f:Hide()
		end
	end)
	f:Hide()

	-- 注册为特殊面板，使 ESC 键能关闭窗口
	if not UISpecialFrames then
		UISpecialFrames = {}
	end
	local alreadyRegistered = false
	for i = 1, table.getn(UISpecialFrames) do
		if UISpecialFrames[i] == "AutomatonMainFrame" then
			alreadyRegistered = true
			break
		end
	end
	if not alreadyRegistered then
		table.insert(UISpecialFrames, "AutomatonMainFrame")
	end

	-- 边框
	local border = CreateFrame("Frame", nil, f)
	border:SetPoint("TOPLEFT", f, "TOPLEFT", -1, 1)
	border:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 1, -1)
	border:SetFrameLevel(100)
	border:SetBackdrop(backdrop_border)
	border:SetBackdropBorderColor(FLAT.border[1], FLAT.border[2], FLAT.border[3], FLAT.border[4])

	-- 标题栏
	local titleBg = f:CreateTexture(nil, "NORMAL")
	titleBg:SetTexture(0.07, 0.10, 0.16, 0.9)
	titleBg:SetHeight(22)
	titleBg:SetPoint("TOPLEFT", 2, -2)
	titleBg:SetPoint("TOPRIGHT", -2, -2)

	local title = f:CreateFontString(nil, "OVERLAY", "GameFontWhite")
	title:SetFont(STANDARD_TEXT_FONT, 16, "OUTLINE")
	title:SetText(
		"|cff"
			.. string.format("%02x%02x%02x", colorR * 255, colorG * 255, colorB * 255)
			.. "Automaton 工具箱强化版|r"
	)
	title:SetPoint("CENTER", titleBg, "CENTER", 0, 0)

	-- 关闭按钮
	local closeBtn = CreateFrame("Button", nil, f)
	closeBtn:SetPoint("RIGHT", titleBg, "RIGHT", -4, 0)
	closeBtn:SetWidth(20)
	closeBtn:SetHeight(20)
	closeBtn:SetFrameLevel(5)
	ApplyFlatBackdrop(closeBtn, { 0.35, 0.08, 0.08, 0.98 }, FLAT.border)
	closeBtn:SetScript("OnEnter", function()
		closeBtn:SetBackdropColor(0.65, 0.12, 0.12, 1)
	end)
	closeBtn:SetScript("OnLeave", function()
		closeBtn:SetBackdropColor(0.35, 0.08, 0.08, 0.98)
	end)
	closeBtn:SetScript("OnClick", function()
		f:Hide()
	end)
	local closeLabel = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontWhite")
	closeLabel:SetFont(STANDARD_TEXT_FONT, 14)
	closeLabel:SetTextColor(1, 0.82, 0.82)
	closeLabel:SetText("X")
	closeLabel:SetAllPoints()

	-- 缩小按钮（在关闭按钮左侧）
	local zoomOutBtn = CreateFrame("Button", nil, f)
	zoomOutBtn:SetPoint("RIGHT", closeBtn, "LEFT", -2, 0)
	zoomOutBtn:SetWidth(20)
	zoomOutBtn:SetHeight(20)
	zoomOutBtn:SetFrameLevel(5)
	ApplyFlatBackdrop(zoomOutBtn, { 0.10, 0.16, 0.24, 0.98 }, FLAT.border)
	zoomOutBtn:SetScript("OnEnter", function()
		zoomOutBtn:SetBackdropColor(0.20, 0.36, 0.52, 1)
	end)
	zoomOutBtn:SetScript("OnLeave", function()
		zoomOutBtn:SetBackdropColor(0.10, 0.16, 0.24, 0.98)
	end)
	zoomOutBtn:SetScript("OnClick", function()
		Automaton:ZoomOut()
	end)
	local zoomOutLabel = zoomOutBtn:CreateFontString(nil, "OVERLAY", "GameFontWhite")
	zoomOutLabel:SetFont(STANDARD_TEXT_FONT, 16)
	zoomOutLabel:SetTextColor(0.82, 0.86, 0.92)
	zoomOutLabel:SetText("－")
	zoomOutLabel:SetAllPoints()

	-- 放大按钮（在缩小按钮左侧）
	local zoomInBtn = CreateFrame("Button", nil, f)
	zoomInBtn:SetPoint("RIGHT", zoomOutBtn, "LEFT", -2, 0)
	zoomInBtn:SetWidth(20)
	zoomInBtn:SetHeight(20)
	zoomInBtn:SetFrameLevel(5)
	ApplyFlatBackdrop(zoomInBtn, { 0.10, 0.16, 0.24, 0.98 }, FLAT.border)
	zoomInBtn:SetScript("OnEnter", function()
		zoomInBtn:SetBackdropColor(0.20, 0.36, 0.52, 1)
	end)
	zoomInBtn:SetScript("OnLeave", function()
		zoomInBtn:SetBackdropColor(0.10, 0.16, 0.24, 0.98)
	end)
	zoomInBtn:SetScript("OnClick", function()
		Automaton:ZoomIn()
	end)
	local zoomInLabel = zoomInBtn:CreateFontString(nil, "OVERLAY", "GameFontWhite")
	zoomInLabel:SetFont(STANDARD_TEXT_FONT, 16)
	zoomInLabel:SetTextColor(0.82, 0.86, 0.92)
	zoomInLabel:SetText("＋")
	zoomInLabel:SetAllPoints()

	-- ================== 左面板（模块列表） ==================
	local leftPanel = CreateFrame("Frame", nil, f)
	leftPanel:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -30)
	leftPanel:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 10)
	leftPanel:SetWidth(200)
	ApplyFlatBackdrop(leftPanel, FLAT.panel, FLAT.border)

	-- 搜索框
	local searchBox = CreateFrame("EditBox", nil, leftPanel)
	searchBox:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 4, -4)
	searchBox:SetWidth(leftPanel:GetWidth() - 52)
	searchBox:SetHeight(18)
	ApplyFlatBackdrop(searchBox, FLAT.input, FLAT.border)
	searchBox:SetFont(STANDARD_TEXT_FONT, 10)
	searchBox:SetAutoFocus(false)
	searchBox:SetText(self.searchText or "")
	searchBox:SetScript("OnTextChanged", function()
		local text = this:GetText()
		Automaton.db.profile.searchText = text
		Automaton.searchText = text
		Automaton:PopulateModuleList()
	end)
	searchBox:SetScript("OnEnterPressed", function()
		this:ClearFocus()
	end)
	searchBox:SetScript("OnEscapePressed", function()
		this:ClearFocus()
	end)

	-- 清除搜索按钮
	local clearBtn = CreateFrame("Button", nil, leftPanel)
	clearBtn:SetPoint("LEFT", searchBox, "RIGHT", 2, 0)
	clearBtn:SetWidth(16)
	clearBtn:SetHeight(16)
	ApplyFlatBackdrop(clearBtn, FLAT.input, FLAT.border)
	clearBtn:SetScript("OnClick", function()
		searchBox:SetText("")
		Automaton.db.profile.searchText = ""
		Automaton.searchText = ""
		Automaton:PopulateModuleList()
	end)
	clearBtn:SetScript("OnEnter", function()
		clearBtn:SetBackdropColor(0.12, 0.40, 0.58, 1)
	end)
	clearBtn:SetScript("OnLeave", function()
		clearBtn:SetBackdropColor(FLAT.input[1], FLAT.input[2], FLAT.input[3], FLAT.input[4])
	end)
	local clearLabel = clearBtn:CreateFontString(nil, "OVERLAY", "GameFontWhite")
	clearLabel:SetFont(STANDARD_TEXT_FONT, 12)
	clearLabel:SetTextColor(FLAT.text[1], FLAT.text[2], FLAT.text[3])
	clearLabel:SetText("X")
	clearLabel:SetAllPoints()

	-- 重置顺序按钮
	local resetBtn = CreateFrame("Button", nil, leftPanel)
	resetBtn:SetPoint("LEFT", clearBtn, "RIGHT", 2, 0)
	resetBtn:SetWidth(24)
	resetBtn:SetHeight(16)
	ApplyFlatBackdrop(resetBtn, FLAT.input, FLAT.border)
	resetBtn:SetScript("OnClick", function()
		Automaton:ResetModuleOrder()
	end)
	resetBtn:SetScript("OnEnter", function()
		resetBtn:SetBackdropColor(0.12, 0.40, 0.58, 1)
		GameTooltip:SetOwner(resetBtn, "ANCHOR_BOTTOM")
		GameTooltip:SetText(L["Reset order"], 1, 1, 1)
		GameTooltip:Show()
	end)
	resetBtn:SetScript("OnLeave", function()
		resetBtn:SetBackdropColor(FLAT.input[1], FLAT.input[2], FLAT.input[3], FLAT.input[4])
		GameTooltip:Hide()
	end)
	local resetLabel = resetBtn:CreateFontString(nil, "OVERLAY", "GameFontWhite")
	resetLabel:SetFont(STANDARD_TEXT_FONT, 10)
	resetLabel:SetTextColor(FLAT.text[1], FLAT.text[2], FLAT.text[3])
	resetLabel:SetText("重置")
	resetLabel:SetAllPoints()
	leftPanel.resetBtn = resetBtn

	-- 模块列表滚动区（自定义滚动条，参考 Cat2 CreateScrollArea）
	-- 底部留 20px 空白（BOTTOMRIGHT 的 y 为正 = 向上留空）
	local listScroll, listContainer, listSlider = CreateScrollArea(leftPanel)
	listScroll:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 4, -28)
	listScroll:SetPoint("BOTTOMRIGHT", leftPanel, "BOTTOMRIGHT", -16, 15)
	listContainer:SetWidth(leftPanel:GetWidth() - 22)
	listContainer:SetHeight(1)
	listSlider:SetPoint("TOPRIGHT", leftPanel, "TOPRIGHT", -6, -28)
	listSlider:SetPoint("BOTTOMRIGHT", leftPanel, "BOTTOMRIGHT", -6, 15)

	leftPanel.listScroll = listScroll
	leftPanel.listContainer = listContainer
	leftPanel.listSlider = listSlider
	leftPanel.searchBox = searchBox

	-- ================== 右面板（模块设置） ==================
	local rightPanel = CreateFrame("Frame", nil, f)
	rightPanel:SetPoint("TOPLEFT", leftPanel, "TOPRIGHT", 8, 0)
	rightPanel:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10)
	ApplyFlatBackdrop(rightPanel, FLAT.panel, FLAT.border)

	-- 右侧标题（显示模块名）
	local rightTitle = rightPanel:CreateFontString(nil, "OVERLAY", "GameFontWhite")
	rightTitle:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
	rightTitle:SetJustifyH("LEFT")
	rightTitle:SetTextColor(FLAT.title[1], FLAT.title[2], FLAT.title[3])
	rightTitle:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 8, -4)
	rightTitle:SetText(L["Select a module"])
	rightPanel.title = rightTitle

	-- 右侧设置滚动区（自定义滚动条，参考 Cat2 CreateScrollArea）
	-- 底部留 20px 空白（BOTTOMRIGHT 的 y 为正 = 向上留空）
	local settingsScroll, settingsContainer, settingsSlider = CreateScrollArea(rightPanel)
	settingsScroll:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 4, -28)
	settingsScroll:SetPoint("BOTTOMRIGHT", rightPanel, "BOTTOMRIGHT", -16, 15)
	settingsContainer:SetWidth(rightPanel:GetWidth() - 22)
	settingsContainer:SetHeight(1)
	settingsSlider:SetPoint("TOPRIGHT", rightPanel, "TOPRIGHT", -6, -28)
	settingsSlider:SetPoint("BOTTOMRIGHT", rightPanel, "BOTTOMRIGHT", -6, 15)

	rightPanel.settingsScroll = settingsScroll
	rightPanel.settingsContainer = settingsContainer
	rightPanel.settingsSlider = settingsSlider

	-- 保存引用
	f.leftPanel = leftPanel
	f.rightPanel = rightPanel
	f.listContainer = listContainer
	f.listScroll = listScroll
	f.listSlider = listSlider
	f.settingsContainer = settingsContainer
	f.settingsScroll = settingsScroll
	f.settingsSlider = settingsSlider
	f.closeBtn = closeBtn
	f.zoomOutBtn = zoomOutBtn
	f.zoomInBtn = zoomInBtn

	self.mainFrame = f
	-- 应用保存的 UI 缩放
	if self.uiScale and self.uiScale ~= 1.0 then
		f:SetScale(self.uiScale)
	end

	-- 拖拽排序用的预览块与落点指示线（只创建一次，常驻）
	CreateDragGhost()
	-- 主窗口常驻 OnUpdate：拖拽时驱动预览块跟随光标；未拖拽时为空操作，几乎无开销
	f:SetScript("OnUpdate", function()
		UpdateDragGhost()
	end)

	-- 窗口隐藏时清理拖拽状态（关闭按钮 / ESC / Toggle 都会触发）
	f:SetScript("OnHide", function()
		if Automaton.dragGhost then
			Automaton.dragGhost:Hide()
		end
		if Automaton.dropIndicator then
			Automaton.dropIndicator:Hide()
		end
		Automaton._dragging = false
		Automaton._dragModule = nil
		Automaton._dragRow = nil
		Automaton._dropIndex = nil
		Automaton._lastDragEndTime = nil
	end)

	self:PopulateModuleList()
	-- 默认选中上次打开的模块（首次或无记录则主页）
	self:SelectModule(self:GetInitialModule())
end

---------------------------------
--      UI 缩放               --
---------------------------------

-- 设置 UI 缩放并持久化
function Automaton:SetUIScale(scale)
	local f = self.mainFrame
	if not f then
		return
	end
	if scale < self.UI_SCALE_MIN then
		scale = self.UI_SCALE_MIN
	end
	if scale > self.UI_SCALE_MAX then
		scale = self.UI_SCALE_MAX
	end
	-- 四舍五入到两位小数，避免浮点误差累积
	scale = math.floor(scale * 100 + 0.5) / 100
	self.uiScale = scale
	self.db.profile.uiScale = scale
	f:SetScale(scale)
end

-- 放大
function Automaton:ZoomIn()
	self:SetUIScale(self.uiScale + self.UI_SCALE_STEP)
end

-- 缩小
function Automaton:ZoomOut()
	self:SetUIScale(self.uiScale - self.UI_SCALE_STEP)
end

---------------------------------
--      填充模块列表           --
---------------------------------

-- 判断名称是否为纯英文（不含中文等非 ASCII 字符）
local function IsEnglishName(text)
	if not text or text == "" then
		return false
	end
	local len = string.len(text)
	for i = 1, len do
		local b = string.byte(text, i)
		if b >= 128 then
			return false
		end
	end
	return true
end

-- 自然排序：把字符串拆成“非数字段”和“数字段”，分别按字典序/数值比较。
-- 这样"自动购买材料" < "自动购买材料1" < "自动购买材料2"，而不是按原始字节乱序。
local function BuildSortChunks(s)
	local chunks = {}
	local i = 1
	local len = string.len(s)
	while i <= len do
		local b, e = string.find(s, "^%d+", i)
		if b then
			local raw = string.sub(s, b, e)
			table.insert(chunks, { type = "num", value = tonumber(raw), raw = raw })
			i = e + 1
		else
			b, e = string.find(s, "^%D+", i)
			if b then
				local raw = string.lower(string.sub(s, b, e))
				table.insert(chunks, { type = "str", value = raw, raw = raw })
				i = e + 1
			else
				i = i + 1
			end
		end
	end
	return chunks
end

local function NaturalLess(a, b)
	local ca = BuildSortChunks(a)
	local cb = BuildSortChunks(b)
	local la = table.getn(ca)
	local lb = table.getn(cb)
	local n = la
	if lb < n then
		n = lb
	end
	for i = 1, n do
		local ai = ca[i]
		local bi = cb[i]
		if ai.type == bi.type then
			if ai.value ~= bi.value then
				return ai.value < bi.value
			end
		else
			-- 数字段与非数字段交叉时按原始字符兜底比较
			if ai.raw ~= bi.raw then
				return ai.raw < bi.raw
			end
		end
	end
	return la < lb
end

-- 维护模块自定义顺序列表：
-- 1) 剔除已不存在的模块名；2) 把新注册、尚未排名的模块按默认规则追加到末尾
-- 返回最终的有序模块名数组（同时写回 profile.moduleOrder）
local function EnsureModuleOrder(self)
	local order = self.db.profile.moduleOrder
	if not order then
		order = {}
		self.db.profile.moduleOrder = order
	end

	local cleaned = {}
	local n = table.getn(order)
	for i = 1, n do
		if self.modules[order[i]] then
			table.insert(cleaned, order[i])
		end
	end

	local missing = {}
	for name in pairs(self.modules) do
		local found = false
		local cn = table.getn(cleaned)
		for i = 1, cn do
			if cleaned[i] == name then
				found = true
				break
			end
		end
		if not found then
			table.insert(missing, name)
		end
	end

	if table.getn(missing) > 0 then
		table.sort(missing, function(a, b)
			local modA = self.modules[a]
			local modB = self.modules[b]
			local nameA = modA.modulename or a
			local nameB = modB.modulename or b
			local engA = IsEnglishName(nameA)
			local engB = IsEnglishName(nameB)
			if engA ~= engB then
				return engA
			end
			return NaturalLess(nameA, nameB)
		end)
		for _, name in ipairs(missing) do
			table.insert(cleaned, name)
		end
	end

	self.db.profile.moduleOrder = cleaned
	return cleaned
end

-- 上移 / 下移指定模块（direction = "up" / "down"），交换相邻位置后重建列表
function Automaton:MoveModule(moduleName, direction)
	local order = self.db.profile.moduleOrder
	if not order then
		return
	end
	local n = table.getn(order)
	local idx = nil
	for i = 1, n do
		if order[i] == moduleName then
			idx = i
			break
		end
	end
	if not idx then
		return
	end

	local target
	if direction == "up" then
		target = idx - 1
	else
		target = idx + 1
	end
	if target < 1 or target > n then
		return
	end

	local tmp = order[idx]
	order[idx] = order[target]
	order[target] = tmp

	-- 记录当前滚动位置，重建后恢复，避免列表跳回顶部
	local scroll = 0
	if self.mainFrame and self.mainFrame.listScroll then
		scroll = self.mainFrame.listScroll:GetVerticalScroll()
	end
	self:PopulateModuleList()
	if self.mainFrame and self.mainFrame.listScroll then
		SetScrollPosition(self.mainFrame.listScroll, self.mainFrame.listSlider, scroll)
	end
end

-- 清空自定义顺序，下次填充列表时按默认规则重建
function Automaton:ResetModuleOrder()
	self.db.profile.moduleOrder = {}
	if self.mainFrame then
		self:PopulateModuleList()
	end
end

-- 按自然排序重新整理当前 moduleOrder（保留用户自定义顺序之外的模块集合）
function Automaton:NormalizeModuleOrder()
	local order = self.db.profile.moduleOrder
	if not order then
		order = {}
		self.db.profile.moduleOrder = order
	end
	local names = {}
	local n = table.getn(order)
	for i = 1, n do
		if self.modules[order[i]] then
			table.insert(names, order[i])
		end
	end
	table.sort(names, function(a, b)
		local modA = self.modules[a]
		local modB = self.modules[b]
		local nameA = modA.modulename or a
		local nameB = modB.modulename or b
		local engA = IsEnglishName(nameA)
		local engB = IsEnglishName(nameB)
		if engA ~= engB then
			return engA
		end
		return NaturalLess(nameA, nameB)
	end)
	self.db.profile.moduleOrder = names
end

-- 将指定模块移动到有序列表的 targetIndex（1-based）位置，并写回 profile.moduleOrder
-- 仅在目标槽位与当前位置不同、且模块确实存在于顺序表中时才生效
function Automaton:ReorderModuleToIndex(moduleName, targetIndex)
	local order = self.db.profile.moduleOrder
	if not order then
		return
	end
	local n = table.getn(order)
	local cur = nil
	for i = 1, n do
		if order[i] == moduleName then
			cur = i
			break
		end
	end
	if not cur then
		return
	end
	if targetIndex < 1 then
		targetIndex = 1
	end
	if targetIndex > n then
		targetIndex = n
	end
	if cur == targetIndex then
		return
	end

	-- 先移除原位置
	local tmp = {}
	for i = 1, n do
		if i ~= cur then
			table.insert(tmp, order[i])
		end
	end
	-- 再插入到目标位置
	local newOrder = {}
	local inserted = false
	local tn = table.getn(tmp)
	for i = 1, tn do
		if i == targetIndex then
			table.insert(newOrder, moduleName)
			inserted = true
		end
		table.insert(newOrder, tmp[i])
	end
	if not inserted then
		table.insert(newOrder, moduleName)
	end
	self.db.profile.moduleOrder = newOrder
end

function Automaton:PopulateModuleList()
	if not self.mainFrame then
		return
	end
	local container = self.mainFrame.listContainer
	local searchText = string.lower(self.searchText or "")

	-- 清空容器
	for i = container:GetNumChildren(), 1, -1 do
		local child = select(i, container:GetChildren())
		child:Hide()
		child:SetParent(nil)
	end
	self._moduleButtons = {}

	local modules = {}
	for name, module in pairs(self.modules) do
		if not self:IsModuleHidden(name) then
			local nameLower = string.lower(name)
			local displayLower = string.lower(module.modulename or "")
			local descLower = string.lower(module.moduledesc or "")
			local show = (searchText == "")
				or string.find(nameLower, searchText, 1, true)
				or string.find(displayLower, searchText, 1, true)
				or string.find(descLower, searchText, 1, true)
			if show then
				table.insert(modules, { name = name, module = module })
			end
		end
	end

	-- 排序：优先使用自定义顺序（moduleOrder），未排名的按默认规则（英文在前、中文在后）
	local orderList = EnsureModuleOrder(self)
	local rankMap = {}
	for i = 1, table.getn(orderList) do
		rankMap[orderList[i]] = i
	end
	table.sort(modules, function(a, b)
		local ra = rankMap[a.name]
		local rb = rankMap[b.name]
		if ra ~= nil and rb ~= nil then
			return ra < rb
		end
		if ra ~= nil then
			return true
		end
		if rb ~= nil then
			return false
		end
		local nameA = a.module.modulename or a.name
		local nameB = b.module.modulename or b.name
		local engA = IsEnglishName(nameA)
		local engB = IsEnglishName(nameB)
		if engA ~= engB then
			return engA
		end
		return NaturalLess(nameA, nameB)
	end)

	-- 在最前面插入"主页"入口（不参与搜索过滤、不可拖拽、不可隐藏）
	table.insert(
		modules,
		1,
		{ name = HOME_KEY, module = { modulename = L["Home"], _home = true, moduledesc = L["Home description"] } }
	)

	local yOffset = 0
	local rowHeight = 24
	local maxWidth = container:GetWidth() - 4
	local reorderEnabled = (searchText == "")

	for idx, entry in ipairs(modules) do
		local m = entry.module
		local row = CreateFrame("Button", nil, container)
		row:SetPoint("TOPLEFT", container, "TOPLEFT", 0, yOffset)
		row:SetWidth(maxWidth)
		row:SetHeight(rowHeight)
		ApplyFlatBackdrop(row, FLAT.row, FLAT.border)
		local moduleName = entry.name
		local isHome = (moduleName == HOME_KEY)
		-- 原生拖拽排序：仅在非搜索状态下注册拖拽；OnDragStart/OnDragStop 由客户端保证
		-- 拖拽期间与松手时可靠派发（无需轮询 IsMouseButtonDown，也不依赖额外捕捉层）。
		if reorderEnabled and not isHome then
			row:RegisterForDrag("LeftButton")
		end
		row:SetScript("OnDragStart", function()
			if reorderEnabled and not isHome then
				Automaton:BeginModuleDrag(moduleName, row)
			end
		end)
		row:SetScript("OnDragStop", function()
			if reorderEnabled and not isHome then
				Automaton:EndModuleDrag(moduleName)
			end
		end)
		row:SetScript("OnClick", function()
			-- 拖拽刚结束（OnDragStop 之后客户端可能紧接着派发一次点击）时抑制误选中
			if Automaton._lastDragEndTime and (GetTime() - Automaton._lastDragEndTime) < 0.25 then
				return
			end
			Automaton:SelectModule(moduleName)
		end)
		-- 高亮当前选中的模块（金色边框）
		if self.selectedModule == entry.name then
			row:SetBackdropBorderColor(FLAT.title[1], FLAT.title[2], FLAT.title[3], 1)
			row.highlight = true
		else
			row.highlight = false
		end
		self._moduleButtons[entry.name] = row

		-- 模块名称（左）
		local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontWhite")
		nameText:SetFont(STANDARD_TEXT_FONT, 11, "THINOUTLINE")
		nameText:SetJustifyH("LEFT")
		nameText:SetTextColor(FLAT.text[1], FLAT.text[2], FLAT.text[3])
		nameText:SetPoint("TOPLEFT", row, "TOPLEFT", 6, 0)
		nameText:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 6, 0)
		if isHome then
			nameText:SetPoint("RIGHT", row, "RIGHT", -8, 0)
		else
			nameText:SetPoint("RIGHT", row, "RIGHT", -47, 0) -- 预留 ↑/↓ 按钮与状态色块空间
		end
		local displayName = m.modulename or entry.name
		local fullDisplayName = displayName
		-- UTF-8 安全截断：中文字符算2个显示宽度，ASCII算1个，超过20就截断加...
		-- nameText 可用宽 ~149px（约 10 个汉字 + "..."），尽量保证截断后不超出
		local dispW = 0
		local di = 1
		local dLen = string.len(displayName)
		local truncPos = dLen
		while di <= dLen do
			local db = string.byte(displayName, di)
			local dw, dl
			if db >= 224 then
				dw, dl = 2, 3
			elseif db >= 192 then
				dw, dl = 2, 2
			else
				dw, dl = 1, 1
			end
			if dispW + dw > 20 then
				truncPos = di - 1
				break
			end
			dispW = dispW + dw
			di = di + dl
		end
		if truncPos < dLen then
			displayName = string.sub(displayName, 1, truncPos) .. "..."
		end
		nameText:SetText(displayName)

		-- 鼠标悬停显示完整模块名和描述（悬停提亮背景 + 金色边框）
		local fullDesc = m.moduledesc or ""
		row:SetScript("OnEnter", function()
			if Automaton._dragging then
				return
			end
			this:SetBackdropColor(0.16, 0.20, 0.27, 0.98)
			this:SetBackdropBorderColor(FLAT.title[1], FLAT.title[2], FLAT.title[3], 1)
			GameTooltip:SetOwner(this, "ANCHOR_LEFT")
			GameTooltip:SetText(fullDisplayName, 1, 1, 1)
			if fullDesc and fullDesc ~= "" then
				GameTooltip:AddLine(fullDesc, 0.7, 0.7, 0.7, 1)
			end
			GameTooltip:Show()
		end)
		row:SetScript("OnLeave", function()
			if this.highlight == true then
				this:SetBackdropColor(FLAT.row[1], FLAT.row[2], FLAT.row[3], FLAT.row[4])
				this:SetBackdropBorderColor(FLAT.title[1], FLAT.title[2], FLAT.title[3], 1)
			else
				this:SetBackdropColor(FLAT.row[1], FLAT.row[2], FLAT.row[3], FLAT.row[4])
				this:SetBackdropBorderColor(FLAT.border[1], FLAT.border[2], FLAT.border[3], FLAT.border[4])
			end
			GameTooltip:Hide()
		end)

		-- 启用状态（右侧红/绿实心色块；主页无此色块）
		if not isHome then
			local status = row:CreateTexture(nil, "OVERLAY")
			status:SetTexture(FLAT_BG)
			status:SetWidth(9)
			status:SetHeight(9)
			status:SetPoint("RIGHT", row, "RIGHT", -7, 0)
			local active = Automaton:IsModuleActive(entry.name)
			if active then
				status:SetVertexColor(0, 1, 0, 1) -- 绿
			else
				status:SetVertexColor(1, 0.267, 0.267, 1) -- 红
			end
			row.statusSwatch = status
		end

		-- 上移 / 下移按钮（搜索时隐藏，主页不提供，避免过滤视图下移动语义混乱）
		if reorderEnabled and not isHome then
			local upBtn = CreateFrame("Button", nil, row)
			upBtn:SetPoint("RIGHT", row, "RIGHT", -33, 0)
			upBtn:SetWidth(12)
			upBtn:SetHeight(14)
			local upText = upBtn:CreateFontString(nil, "OVERLAY", "GameFontWhite")
			upText:SetFont(STANDARD_TEXT_FONT, 10)
			upText:SetTextColor(0.55, 0.60, 0.66)
			upText:SetText("↑")
			upText:SetAllPoints()
			upBtn:SetScript("OnEnter", function()
				upText:SetTextColor(1, 0.84, 0.28)
			end)
			upBtn:SetScript("OnLeave", function()
				upText:SetTextColor(0.55, 0.60, 0.66)
			end)
			upBtn:SetScript("OnClick", function()
				if Automaton._dragging then
					return
				end
				Automaton:MoveModule(moduleName, "up")
			end)

			local downBtn = CreateFrame("Button", nil, row)
			downBtn:SetPoint("RIGHT", row, "RIGHT", -19, 0)
			downBtn:SetWidth(12)
			downBtn:SetHeight(14)
			local downText = downBtn:CreateFontString(nil, "OVERLAY", "GameFontWhite")
			downText:SetFont(STANDARD_TEXT_FONT, 10)
			downText:SetTextColor(0.55, 0.60, 0.66)
			downText:SetText("↓")
			downText:SetAllPoints()
			downBtn:SetScript("OnEnter", function()
				downText:SetTextColor(1, 0.84, 0.28)
			end)
			downBtn:SetScript("OnLeave", function()
				downText:SetTextColor(0.55, 0.60, 0.66)
			end)
			downBtn:SetScript("OnClick", function()
				if Automaton._dragging then
					return
				end
				Automaton:MoveModule(moduleName, "down")
			end)
		end

		-- 拖拽中：原行淡化效果在 BeginModuleDrag 里通过 SetAlpha 处理，这里无需额外高亮

		yOffset = yOffset - rowHeight - 2
	end

	if table.getn(modules) == 0 then
		local empty = container:CreateFontString(nil, "OVERLAY", "GameFontWhite")
		empty:SetFont(STANDARD_TEXT_FONT, 11)
		empty:SetText(L["No modules found"])
		empty:SetPoint("CENTER", container, "CENTER", 0, 0)
	end

	local totalHeight = -yOffset + 10
	container:SetHeight(math.max(totalHeight, 100))
	-- 刷新滚动区域与滚动条
	UpdateScrollBar(self.mainFrame.listScroll, self.mainFrame.listSlider, totalHeight)
end

---------------------------------
--      选择模块并刷新右侧     --
---------------------------------

-- 模块是否在左侧列表中隐藏（仅影响显示，不影响功能）
function Automaton:IsModuleHidden(name)
	return self.db.profile.hiddenModules and self.db.profile.hiddenModules[name] == true
end

-- 计算打开窗口时应默认选中的模块：优先上次打开的，无记录或其已被隐藏则回退主页
function Automaton:GetInitialModule()
	local last = self.db.profile.lastModule
	if last == HOME_KEY then
		return HOME_KEY
	end
	if last and self.modules[last] and not self:IsModuleHidden(last) then
		return last
	end
	return HOME_KEY
end

function Automaton:SelectModule(moduleName)
	-- 主页（概览页）
	if moduleName == HOME_KEY then
		if self.selectedModule and self.selectedModule ~= HOME_KEY and self._moduleButtons[self.selectedModule] then
			local oldBtn = self._moduleButtons[self.selectedModule]
			oldBtn:SetBackdropBorderColor(FLAT.border[1], FLAT.border[2], FLAT.border[3], FLAT.border[4])
			oldBtn.highlight = false
		end
		self.selectedModule = HOME_KEY
		if self._moduleButtons[HOME_KEY] then
			local newBtn = self._moduleButtons[HOME_KEY]
			newBtn:SetBackdropBorderColor(FLAT.title[1], FLAT.title[2], FLAT.title[3], 1)
			newBtn.highlight = true
		end
		self.db.profile.lastModule = HOME_KEY
		self:ShowHomePage()
		return
	end

	if self.selectedModule == moduleName then
		self:RefreshModuleSettings(moduleName)
		return
	end

	if self.selectedModule and self._moduleButtons[self.selectedModule] then
		local oldBtn = self._moduleButtons[self.selectedModule]
		oldBtn:SetBackdropBorderColor(FLAT.border[1], FLAT.border[2], FLAT.border[3], FLAT.border[4])
		oldBtn.highlight = false
	end

	self.selectedModule = moduleName

	if self._moduleButtons[moduleName] then
		local newBtn = self._moduleButtons[moduleName]
		newBtn:SetBackdropBorderColor(FLAT.title[1], FLAT.title[2], FLAT.title[3], 1)
		newBtn.highlight = true
	else
		self:PopulateModuleList()
		if self._moduleButtons[moduleName] then
			local newBtn = self._moduleButtons[moduleName]
			newBtn:SetBackdropBorderColor(FLAT.title[1], FLAT.title[2], FLAT.title[3], 1)
			newBtn.highlight = true
		end
	end

	self.db.profile.lastModule = moduleName
	self:RefreshModuleSettings(moduleName)
end

---------------------------------
--      主页（概览与模块管理） --
---------------------------------

function Automaton:ShowHomePage()
	if not self.mainFrame then
		return
	end
	local rightPanel = self.mainFrame.rightPanel
	rightPanel.title:SetText(L["Home"])

	local container = rightPanel.settingsContainer
	self:ClearSettingsContainer(container)

	local maxWidth = container:GetWidth() - 10
	local yOffset = 0
	local rowHeight = 24

	-- 把所有主页内容放进一个包装帧，作为 container 唯一的子 Frame。
	-- ClearSettingsContainer 只清除子 Frame，不清理直接挂在 container 上的
	-- FontString/Texture；用包装帧可确保切换模块时主页内容被整体移除。
	local homeContent = CreateFrame("Frame", nil, container)
	homeContent:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
	homeContent:SetWidth(maxWidth)
	homeContent:SetHeight(1)

	-- 统计：总数 / 已启用 / 已禁用
	local total = 0
	local enabled = 0
	for name, module in pairs(self.modules) do
		total = total + 1
		if self:IsModuleActive(name) then
			enabled = enabled + 1
		end
	end
	local stats = homeContent:CreateFontString(nil, "OVERLAY", "GameFontWhite")
	stats:SetPoint("TOPLEFT", homeContent, "TOPLEFT", 6, yOffset)
	stats:SetFont(STANDARD_TEXT_FONT, 11)
	stats:SetTextColor(FLAT.text[1], FLAT.text[2], FLAT.text[3])
	stats:SetText(
		string.format(
			"%s：%d    %s：%d    %s：%d",
			L["Modules total"],
			total,
			L["Enabled count"],
			enabled,
			L["Disabled count"],
			total - enabled
		)
	)
	yOffset = yOffset - 22

	-- 分隔线
	local divider = homeContent:CreateTexture(nil, "ARTWORK")
	divider:SetTexture(FLAT.border[1], FLAT.border[2], FLAT.border[3], 0.6)
	divider:SetHeight(1)
	divider:SetPoint("TOPLEFT", homeContent, "TOPLEFT", 4, yOffset + 4)
	divider:SetPoint("TOPRIGHT", homeContent, "TOPRIGHT", -4, yOffset + 4)
	yOffset = yOffset - 10

	-- 按当前显示状态分组
	local orderList = EnsureModuleOrder(self)
	local visibleList = {}
	local hiddenList = {}
	for _, name in ipairs(orderList) do
		if self.modules[name] then
			if self:IsModuleHidden(name) then
				table.insert(hiddenList, name)
			else
				table.insert(visibleList, name)
			end
		end
	end

	-- 渲染分组小标题
	local function RenderSubHeader(text)
		local subHeader = homeContent:CreateFontString(nil, "OVERLAY", "GameFontWhite")
		subHeader:SetPoint("TOPLEFT", homeContent, "TOPLEFT", 6, yOffset)
		subHeader:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
		subHeader:SetTextColor(FLAT.title[1], FLAT.title[2], FLAT.title[3])
		subHeader:SetText(text)
		yOffset = yOffset - 22
	end

	-- 渲染单个模块行（含启用色块与“在列表中显示”复选框）
	local function RenderModuleRow(modName)
		local module = self.modules[modName]
		if not module then
			return
		end
		local row = CreateFrame("Frame", nil, homeContent)
		row:SetPoint("TOPLEFT", homeContent, "TOPLEFT", 0, yOffset)
		row:SetWidth(maxWidth)
		row:SetHeight(rowHeight)
		ApplyFlatBackdrop(row, FLAT.row, FLAT.border)

		-- 模块名
		local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontWhite")
		nameText:SetFont(STANDARD_TEXT_FONT, 11, "THINOUTLINE")
		nameText:SetJustifyH("LEFT")
		nameText:SetTextColor(FLAT.text[1], FLAT.text[2], FLAT.text[3])
		nameText:SetPoint("TOPLEFT", row, "TOPLEFT", 6, 0)
		nameText:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 6, 0)
		nameText:SetPoint("RIGHT", row, "RIGHT", -30, 0)
		nameText:SetText(module.modulename or modName)

		-- 启用状态色块（绿=启用，红=停用）
		local status = row:CreateTexture(nil, "OVERLAY")
		status:SetTexture(FLAT_BG)
		status:SetWidth(9)
		status:SetHeight(9)
		status:SetPoint("RIGHT", row, "RIGHT", -28, 0)
		if self:IsModuleActive(modName) then
			status:SetVertexColor(0, 1, 0, 1)
		else
			status:SetVertexColor(1, 0.267, 0.267, 1)
		end

		-- “在列表中显示”复选框
		local cb = CreateFlatCheckbox(row)
		cb:SetPoint("RIGHT", row, "RIGHT", -6, 0)
		local shown = not self:IsModuleHidden(modName)
		cb:SetChecked(shown)
		cb._onChange = function(val)
			if val then
				self.db.profile.hiddenModules[modName] = nil
			else
				self.db.profile.hiddenModules[modName] = true
			end
			-- 同步左侧列表，并重建主页以刷新勾选状态
			self:PopulateModuleList()
			self:ShowHomePage()
		end

		yOffset = yOffset - rowHeight - 2
	end

	-- 显示的模块
	if table.getn(visibleList) > 0 then
		RenderSubHeader(L["Displayed Modules"])
		for _, name in ipairs(visibleList) do
			RenderModuleRow(name)
		end
	end

	-- 隐藏的模块（与上一组之间额外留空）
	if table.getn(hiddenList) > 0 then
		if table.getn(visibleList) > 0 then
			yOffset = yOffset - 6
		end
		RenderSubHeader(L["Hidden Modules"])
		for _, name in ipairs(hiddenList) do
			RenderModuleRow(name)
		end
	end

	local totalHeight = -yOffset + 10
	homeContent:SetHeight(math.max(totalHeight, 1))
	container:SetHeight(math.max(totalHeight, 1))
	UpdateScrollBar(rightPanel.settingsScroll, rightPanel.settingsSlider, totalHeight)
end

---------------------------------
--      刷新模块设置面板       --
---------------------------------

function Automaton:RefreshModuleSettings(moduleName)
	-- 刷新前关闭可能还开着的下拉菜单
	CloseDropdownMenu()

	local module = self.modules[moduleName]
	if not module then
		self.mainFrame.rightPanel.title:SetText(L["Select a module"])
		self:ClearSettingsContainer()
		return
	end

	local rightPanel = self.mainFrame.rightPanel
	rightPanel.title:SetText(module.modulename or moduleName)

	local container = rightPanel.settingsContainer
	self:ClearSettingsContainer(container)

	local options = module._options
	if not options or next(options) == nil then
		container:SetHeight(1)
		UpdateScrollBar(rightPanel.settingsScroll, rightPanel.settingsSlider, 1)
		return
	end

	local maxWidth = container:GetWidth() - 10
	local yOffset = 0
	local rowHeight = 26

	-- 给控件挂悬停提示（title + 说明文字 desc）
	local function AttachTooltip(frame, title, desc)
		if not frame then
			return
		end
		frame:SetScript("OnEnter", function()
			GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
			GameTooltip:SetText(title, 1, 1, 1)
			if desc and desc ~= "" then
				GameTooltip:AddLine(desc, 0.7, 0.7, 0.7, 1)
			end
			GameTooltip:Show()
		end)
		frame:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	end

	local AddControl
	AddControl = function(caption, entryKey, opt, indent)
		indent = indent or 0
		-- 支持函数形式的 name（如 description 类型的动态预览文本）
		if type(caption) == "function" then
			caption = caption()
		end
		if caption == nil then
			caption = ""
		end
		local row = CreateFrame("Frame", nil, container)
		row:SetPoint("TOPLEFT", container, "TOPLEFT", indent, yOffset)
		row:SetWidth(maxWidth - indent)
		row:SetHeight(rowHeight)

		local label = row:CreateFontString(nil, "OVERLAY", "GameFontWhite")
		label:SetFont(STANDARD_TEXT_FONT, 10)
		label:SetJustifyH("LEFT")
		label:SetPoint("TOPLEFT", row, "TOPLEFT", 6, 0)
		label:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 6, 0)
		label:SetText(caption)

		-- 悬停显示说明（opt.desc / opt.usage）
		local rowTooltipDesc = opt.desc or opt.usage
		if rowTooltipDesc and rowTooltipDesc ~= "" then
			AttachTooltip(row, caption, rowTooltipDesc)
		end

		local typ = opt.type
		if typ == "header" then
			-- 大项标题：加粗橙色 + 蓝灰背景条 + 底部分隔线
			label:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
			label:SetTextColor(FLAT.title[1], FLAT.title[2], FLAT.title[3])
			local headerBg = row:CreateTexture(nil, "BACKGROUND")
			headerBg:SetTexture(0.07, 0.10, 0.16, 0.95)
			headerBg:SetAllPoints()
			local divider = row:CreateTexture(nil, "ARTWORK")
			divider:SetTexture(FLAT.border[1], FLAT.border[2], FLAT.border[3], 0.6)
			divider:SetHeight(1)
			divider:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 4, 0)
			divider:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -4, 0)
			row:SetHeight(24)
			yOffset = yOffset - row:GetHeight() - 4
			return row
		end

		if typ == "description" then
			-- 说明/预览文本：整行显示，无右侧控件，次要颜色
			label:SetTextColor(FLAT.dim[1], FLAT.dim[2], FLAT.dim[3])
			if rowTooltipDesc and rowTooltipDesc ~= "" then
				AttachTooltip(row, caption, rowTooltipDesc)
			end
			yOffset = yOffset - row:GetHeight() - 2
			return row
		end

		if typ == "toggle" then
			-- 自绘滑块开关：轨道 + 滑块，开=亮蓝靠右，关=灰靠左
			local sw = CreateFrame("Button", nil, row)
			sw.autoType = "toggle"
			sw:SetPoint("RIGHT", row, "RIGHT", -6, 0)
			sw:SetWidth(40)
			sw:SetHeight(20)

			-- 轨道
			local track = sw:CreateTexture(nil, "BACKGROUND")
			track:SetTexture(FLAT_BG)
			track:SetPoint("TOPLEFT", sw, "TOPLEFT", 1, -1)
			track:SetPoint("BOTTOMRIGHT", sw, "BOTTOMRIGHT", -1, 1)
			track:SetVertexColor(0.15, 0.18, 0.22, 1)

			-- 滑块
			local knob = sw:CreateTexture(nil, "OVERLAY")
			knob:SetTexture(FLAT_BG)
			knob:SetWidth(14)
			knob:SetHeight(14)
			knob:SetPoint("LEFT", sw, "LEFT", 3, 0)
			knob:SetVertexColor(0.55, 0.60, 0.65, 1)

			-- 状态刷新函数（sw.checked 存布尔值，避免 1.12 CheckButton 的 1/nil 问题）
			local function RefreshSwitch(val)
				sw.checked = val and true or false
				if sw.checked then
					track:SetVertexColor(0.20, 0.50, 0.75, 1)
					knob:SetVertexColor(0.50, 0.85, 1.00, 1)
					knob:ClearAllPoints()
					knob:SetPoint("RIGHT", sw, "RIGHT", -3, 0)
				else
					track:SetVertexColor(0.15, 0.18, 0.22, 1)
					knob:SetVertexColor(0.55, 0.60, 0.65, 1)
					knob:ClearAllPoints()
					knob:SetPoint("LEFT", sw, "LEFT", 3, 0)
				end
			end

			sw:SetScript("OnShow", function()
				local val = opt.get and opt.get() or false
				RefreshSwitch(val)
			end)
			sw:SetScript("OnClick", function()
				local newVal = not sw.checked
				if opt.set then
					opt.set(newVal)
				end
				RefreshSwitch(newVal)
				-- 启用/禁用开关切换后，刷新左侧列表的状态色块
				if entryKey == "enabled" and Automaton.mainFrame and Automaton.mainFrame:IsShown() then
					local btn = Automaton._moduleButtons[moduleName]
					if btn and btn.statusSwatch then
						local active = Automaton:IsModuleActive(moduleName)
						if active then
							btn.statusSwatch:SetVertexColor(0, 1, 0, 1)
						else
							btn.statusSwatch:SetVertexColor(1, 0.267, 0.267, 1)
						end
					end
				end
			end)
			sw:SetScript("OnEnter", function()
				knob:SetVertexColor(0.72, 0.88, 1.00, 1)
			end)
			sw:SetScript("OnLeave", function()
				RefreshSwitch(sw.checked)
			end)

			-- 立即设置初始状态
			local initVal = opt.get and opt.get() or false
			RefreshSwitch(initVal)
			sw:Show()
		elseif typ == "text" then
			-- validate 支持两种格式：
			--   数组：{ "需求", "贪婪", "放弃" }        —— 值即存储值和显示名
			--   字典：{ ["yell"]="喊话频道", ... }      —— key 是存储值，value 是显示名
			if opt.validate and type(opt.validate) == "table" and next(opt.validate) ~= nil then
				local passValue = opt.passValue
				local isArray = (opt.validate[1] ~= nil)

				-- 构建有序选项列表：items[i] = { key = 存储值, label = 显示名 }
				local items = {}
				if isArray then
					local n = table.getn(opt.validate)
					for i = 1, n do
						table.insert(items, { key = opt.validate[i], label = opt.validate[i] })
					end
				else
					for k, v in pairs(opt.validate) do
						table.insert(items, { key = k, label = v })
					end
					table.sort(items, function(a, b)
						return string.lower(a.key) < string.lower(b.key)
					end)
				end

				-- 有 validate 字段：自绘下拉选择菜单（点击展开选项列表，一次选中）
				local btn = CreateFlatButton(row, 90, 20, "")
				btn:SetPoint("RIGHT", row, "RIGHT", -6, 0)

				-- 处理 passValue：部分选项的 get/set 需传字段名（如 AutoNeed 的 get(field)/set(field, value)）
				local function GetCurrent()
					if not opt.get then
						return ""
					end
					if passValue then
						return opt.get(passValue) or ""
					else
						return opt.get() or ""
					end
				end

				local function SetValue(val)
					if not opt.set then
						return
					end
					if passValue then
						opt.set(passValue, val)
					else
						opt.set(val)
					end
				end

				-- 根据存储值找到对应显示名
				local function GetLabel(current)
					local listLen = table.getn(items)
					for i = 1, listLen do
						if items[i].key == current then
							return items[i].label
						end
					end
					return current or ""
				end

				local function UpdateBtnText()
					btn.text:SetText(GetLabel(GetCurrent()))
				end

				UpdateBtnText()

				-- 下拉菜单：parent 到主窗口，避免被 ScrollFrame 裁剪；ESC 关闭窗口时连带关闭
				local listLen = table.getn(items)
				local menu = CreateFrame("Frame", nil, Automaton.mainFrame)
				menu:SetWidth(90)
				menu:SetHeight(listLen * 22 + 6)
				menu:SetFrameLevel(50)
				ApplyFlatBackdrop(menu, { 0.04, 0.06, 0.10, 1 }, FLAT.border)
				menu:Hide()

				local menuEntries = {}
				for i = 1, listLen do
					local entry = CreateFrame("Button", nil, menu)
					entry:SetWidth(84)
					entry:SetHeight(20)
					entry:SetPoint("TOPLEFT", menu, "TOPLEFT", 3, -3 - (i - 1) * 22)

					local entryHighlight = entry:CreateTexture(nil, "BACKGROUND")
					entryHighlight:SetAllPoints()
					entryHighlight:SetTexture(FLAT_BG)
					entryHighlight:SetVertexColor(0.12, 0.28, 0.42, 0.55)
					entryHighlight:Hide()

					local entryText = entry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
					entryText:SetPoint("LEFT", entry, "LEFT", 6, 0)
					entryText:SetFont(STANDARD_TEXT_FONT, 10)
					entryText:SetTextColor(FLAT.text[1], FLAT.text[2], FLAT.text[3])
					entryText:SetText(items[i].label)

					local entryKey = items[i].key
					entry.entryText = entryText
					entry.entryHighlight = entryHighlight
					entry.entryKey = entryKey

					entry:SetScript("OnEnter", function()
						entryHighlight:Show()
						entryText:SetTextColor(1, 0.84, 0.28)
					end)
					entry:SetScript("OnLeave", function()
						entryHighlight:Hide()
						entryText:SetTextColor(FLAT.text[1], FLAT.text[2], FLAT.text[3])
					end)
					entry:SetScript("OnClick", function()
						SetValue(entryKey)
						UpdateBtnText()
						CloseDropdownMenu()
					end)
					menuEntries[i] = entry
				end

				-- 展开菜单时刷新选中项高亮
				local function RefreshMenu()
					local current = GetCurrent()
					for i = 1, listLen do
						if items[i].key == current then
							menuEntries[i].entryHighlight:Show()
							menuEntries[i].entryText:SetTextColor(1, 0.84, 0.28)
						else
							menuEntries[i].entryHighlight:Hide()
							menuEntries[i].entryText:SetTextColor(FLAT.text[1], FLAT.text[2], FLAT.text[3])
						end
					end
				end

				btn:SetScript("OnClick", function()
					if menu:IsVisible() then
						CloseDropdownMenu()
					else
						menu:ClearAllPoints()
						menu:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
						RefreshMenu()
						OpenDropdownMenu(menu)
						menu:Show()
					end
				end)
				btn:Show()
			else
				-- 普通文本输入框
				local edit = CreateFrame("EditBox", nil, row)
				edit.autoType = "edit"
				edit:SetPoint("RIGHT", row, "RIGHT", -6, 0)
				edit:SetWidth(120)
				edit:SetHeight(18)
				ApplyFlatBackdrop(edit, FLAT.input, FLAT.border)
				edit:SetFont(STANDARD_TEXT_FONT, 10)
				edit:SetAutoFocus(false)
				edit:SetText(opt.get and tostring(opt.get()) or "")
				-- 提交函数：回车和失焦共用，保证同一段输入只提交一次
				local function CommitTextEdit()
					local val = edit:GetText()
					if opt.set then
						opt.set(val)
					end
				end
				edit:SetScript("OnEnterPressed", function()
					CommitTextEdit()
					edit.textCommitted = true
					-- 回车提交后清空输入框，避免残留上次输入的信息
					edit:SetText("")
					edit:ClearFocus()
				end)
				edit:SetScript("OnEscapePressed", function()
					edit.textCommitted = true
					edit:ClearFocus()
				end)
				-- 失焦也保存，避免输入后不按回车直接点其他按钮导致值丢失；
				-- 但回车/ESC 已提交过则跳过，防止 OnEnterPressed 里 ClearFocus 触发 OnEditFocusLost 重复提交
				edit:SetScript("OnEditFocusLost", function()
					if edit.textCommitted then
						edit.textCommitted = false
						return
					end
					CommitTextEdit()
				end)
				edit:Show()
			end
		elseif typ == "range" or (typ == "number" and (opt.min ~= nil or opt.max ~= nil)) then
			-- 范围数值：滑动条 + 数值输入框，带上下限
			local minVal = opt.min or 0
			local maxVal = opt.max or 100
			local stepVal = opt.step or 1

			local function GetVal()
				local v = opt.get and opt.get()
				if type(v) ~= "number" then
					v = tonumber(v)
				end
				if v == nil then
					v = minVal
				end
				return v
			end

			local function SetVal(v)
				if v == nil then
					return
				end
				-- 对齐到 step 的整数倍，并修正浮点误差（保留 0.001 精度）
				if stepVal and stepVal > 0 then
					v = math.floor(v / stepVal + 0.5) * stepVal
				end
				v = math.floor(v * 1000 + 0.5) / 1000
				if v < minVal then
					v = minVal
				end
				if v > maxVal then
					v = maxVal
				end
				if opt.set then
					opt.set(v)
				end
				return v
			end

			local function FormatVal(v)
				if v == nil then
					return ""
				end
				if stepVal == math.floor(stepVal) then
					return tostring(math.floor(v + 0.5))
				end
				return string.format("%.2f", v)
			end

			-- 数值输入框（可点击直接输入）
			local edit = CreateFrame("EditBox", nil, row)
			edit.autoType = "edit"
			edit:SetWidth(44)
			edit:SetHeight(18)
			edit:SetPoint("RIGHT", row, "RIGHT", -6, 0)
			ApplyFlatBackdrop(edit, FLAT.input, FLAT.border)
			edit:SetFont(STANDARD_TEXT_FONT, 10)
			edit:SetAutoFocus(false)
			edit:SetText(FormatVal(GetVal()))

			-- 滑动条：轨道 + 填充 + 拇指
			local slider = CreateFrame("Frame", nil, row)
			slider:SetWidth(100)
			slider:SetHeight(18)
			slider:SetPoint("RIGHT", edit, "LEFT", -6, 0)

			local rail = slider:CreateTexture(nil, "BACKGROUND")
			rail:SetPoint("LEFT", slider, "LEFT", 0, 0)
			rail:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
			rail:SetHeight(4)
			rail:SetPoint("CENTER", slider, "CENTER", 0, 0)
			rail:SetTexture(FLAT.border[1], FLAT.border[2], FLAT.border[3], 0.8)

			local fill = slider:CreateTexture(nil, "ARTWORK")
			fill:SetPoint("LEFT", slider, "LEFT", 0, 0)
			fill:SetHeight(4)
			fill:SetPoint("CENTER", slider, "CENTER", 0, 0)
			fill:SetTexture(FLAT.accent[1], FLAT.accent[2], FLAT.accent[3], 1)

			local thumb = CreateFrame("Button", nil, slider)
			thumb:SetWidth(14)
			thumb:SetHeight(14)
			local thumbTex = thumb:CreateTexture(nil, "ARTWORK")
			thumbTex:SetAllPoints()
			thumbTex:SetTexture(FLAT_BG)
			thumbTex:SetVertexColor(FLAT.accent[1], FLAT.accent[2], FLAT.accent[3], 0.9)

			local valSpan = maxVal - minVal

			local function UpdateSlider()
				local v = GetVal()
				local ratio = 0
				if valSpan > 0 then
					ratio = (v - minVal) / valSpan
				end
				if ratio < 0 then
					ratio = 0
				end
				if ratio > 1 then
					ratio = 1
				end
				local trackW = slider:GetWidth() - 14
				if trackW < 0 then
					trackW = 0
				end
				fill:SetWidth(trackW * ratio)
				thumb:ClearAllPoints()
				thumb:SetPoint("CENTER", fill, "RIGHT", 0, 0)
			end

			local function CommitEdit()
				local v = tonumber(edit:GetText())
				if v ~= nil then
					v = SetVal(v)
					edit:SetText(FormatVal(v))
					UpdateSlider()
				else
					edit:SetText(FormatVal(GetVal()))
				end
			end

			edit:SetScript("OnEnterPressed", function()
				edit.textCommitted = true
				CommitEdit()
				edit:ClearFocus()
			end)
			edit:SetScript("OnEscapePressed", function()
				edit.textCommitted = true
				edit:SetText(FormatVal(GetVal()))
				edit:ClearFocus()
			end)
			edit:SetScript("OnEditFocusLost", function()
				if edit.textCommitted then
					edit.textCommitted = nil
					return
				end
				CommitEdit()
			end)

			-- 拖拽拇指更新值；OnUpdate 读鼠标位置
			local dragging = false
			thumb:SetScript("OnMouseDown", function()
				dragging = true
			end)
			thumb:SetScript("OnMouseUp", function()
				dragging = false
			end)
			slider:EnableMouse(true)
			slider:SetScript("OnMouseUp", function()
				dragging = false
			end)
			slider:SetScript("OnUpdate", function(self, elapsed)
				elapsed = elapsed or 0
				if not dragging then
					return
				end
				local x = GetCursorPosition()
				local s = UIParent:GetScale()
				if not s or s <= 0 then
					return
				end
				x = x / s
				local l = slider:GetLeft()
				if not l then
					return
				end
				local r = l + slider:GetWidth()
				if x < l then
					x = l
				end
				if x > r then
					x = r
				end
				local ratio = (x - l) / slider:GetWidth()
				if ratio < 0 then
					ratio = 0
				end
				if ratio > 1 then
					ratio = 1
				end
				local v = minVal + ratio * valSpan
				v = SetVal(v)
				edit:SetText(FormatVal(v))
				UpdateSlider()
			end)

			UpdateSlider()
			edit:Show()
			slider:Show()
		elseif typ == "number" then
			-- 纯数字输入框（无 min/max 边界）
			local edit = CreateFrame("EditBox", nil, row)
			edit.autoType = "edit"
			edit:SetPoint("RIGHT", row, "RIGHT", -6, 0)
			edit:SetWidth(60)
			edit:SetHeight(18)
			ApplyFlatBackdrop(edit, FLAT.input, FLAT.border)
			edit:SetFont(STANDARD_TEXT_FONT, 10)
			edit:SetAutoFocus(false)
			edit:SetText(opt.get and tostring(opt.get()) or "")
			edit:SetScript("OnEnterPressed", function()
				edit.textCommitted = true
				local val = tonumber(this:GetText())
				if val and opt.set then
					opt.set(val)
				end
				this:ClearFocus()
			end)
			edit:SetScript("OnEscapePressed", function()
				edit.textCommitted = true
				this:ClearFocus()
			end)
			edit:SetScript("OnEditFocusLost", function()
				if edit.textCommitted then
					edit.textCommitted = false
					return
				end
				local val = tonumber(this:GetText())
				if val and opt.set then
					opt.set(val)
				end
			end)
			edit:Show()
		elseif typ == "execute" then
			local labelText = opt.name or "执行"
			local btn, btnText = CreateFlatButton(row, 50, 20, labelText)
			-- 按文字宽度动态调整按钮宽度（左右各 12px 内边距，最小 50，最大 200）
			local btnWidth = (btnText:GetStringWidth() or 0) + 24
			if btnWidth < 50 then
				btnWidth = 50
			end
			if btnWidth > 200 then
				btnWidth = 200
			end
			btn:SetWidth(btnWidth)
			btn:SetPoint("RIGHT", row, "RIGHT", -6, 0)
			btn:SetScript("OnClick", function()
				if opt.func then
					opt.func()
				end
			end)
			btn:Show()
		elseif typ == "color" then
			-- 颜色选择器：色块按钮 + ColorPickerFrame
			local swatch = CreateFrame("Button", nil, row)
			swatch.autoType = "color"
			swatch:SetPoint("RIGHT", row, "RIGHT", -6, 0)
			swatch:SetWidth(40)
			swatch:SetHeight(16)
			ApplyFlatBackdrop(swatch, FLAT.input, FLAT.border)
			swatch:SetScript("OnEnter", function()
				swatch:SetBackdropColor(0.12, 0.40, 0.58, 1)
				GameTooltip:SetOwner(swatch, "ANCHOR_RIGHT")
				GameTooltip:SetText(caption, 1, 1, 1)
				if rowTooltipDesc and rowTooltipDesc ~= "" then
					GameTooltip:AddLine(rowTooltipDesc, 0.7, 0.7, 0.7, 1)
				end
				GameTooltip:Show()
			end)
			swatch:SetScript("OnLeave", function()
				swatch:SetBackdropColor(FLAT.input[1], FLAT.input[2], FLAT.input[3], FLAT.input[4])
				GameTooltip:Hide()
			end)

			-- 颜色预览纹理
			local colorTex = swatch:CreateTexture(nil, "OVERLAY")
			colorTex:SetPoint("TOPLEFT", swatch, "TOPLEFT", 2, -2)
			colorTex:SetPoint("BOTTOMRIGHT", swatch, "BOTTOMRIGHT", -2, 2)

			-- 设置初始颜色
			local cr, cg, cb, ca
			if opt.get then
				cr, cg, cb, ca = opt.get()
			end
			cr = cr or 1
			cg = cg or 1
			cb = cb or 1
			ca = ca or 1
			colorTex:SetTexture(cr, cg, cb, ca)

			swatch:SetScript("OnClick", function()
				-- 读取当前颜色作为初始值和取消回退值
				local pr, pg, pb, pa
				if opt.get then
					pr, pg, pb, pa = opt.get()
				end
				pr = pr or 1
				pg = pg or 1
				pb = pb or 1
				pa = pa or 1

				local hasAlpha = opt.hasAlpha
				ColorPickerFrame.hasOpacity = hasAlpha
				ColorPickerFrame:SetColorRGB(pr, pg, pb)
				if hasAlpha and ColorPickerFrame.SetOpacity then
					ColorPickerFrame:SetOpacity(pa)
				end

				-- 确定颜色时的回调
				ColorPickerFrame.func = function()
					local nr, ng, nb = ColorPickerFrame:GetColorRGB()
					local na = 1
					if hasAlpha and ColorPickerFrame.opacity then
						na = ColorPickerFrame.opacity
					end
					colorTex:SetTexture(nr, ng, nb, na)
					if opt.set then
						opt.set(nr, ng, nb, na)
					end
				end

				-- 拖动透明度滑块时的回调
				ColorPickerFrame.opacityFunc = function()
					local nr, ng, nb = ColorPickerFrame:GetColorRGB()
					local na = 1
					if ColorPickerFrame.opacity then
						na = ColorPickerFrame.opacity
					end
					colorTex:SetTexture(nr, ng, nb, na)
					if opt.set then
						opt.set(nr, ng, nb, na)
					end
				end

				-- 取消时的回退
				ColorPickerFrame.cancelFunc = function()
					colorTex:SetTexture(pr, pg, pb, pa)
					if opt.set then
						opt.set(pr, pg, pb, pa)
					end
				end

				ColorPickerFrame:Show()
			end)
			swatch:Show()
		elseif typ == "group" then
			-- 小项标题：显示组名 + 背景，子项缩进展开
			local groupTitle = opt.name or entryKey
			if groupTitle and groupTitle ~= "" then
				label:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
				label:SetTextColor(FLAT.accent[1], FLAT.accent[2], FLAT.accent[3])
				label:SetText("▸ " .. groupTitle)
				local groupBg = row:CreateTexture(nil, "BACKGROUND")
				groupBg:SetTexture(0.10, 0.13, 0.18, 0.8)
				groupBg:SetAllPoints()
				row:SetHeight(20)
				yOffset = yOffset - row:GetHeight() - 2
			else
				row:SetHeight(0)
			end

			-- 子项
			local args = opt.args
			if args then
				local subIndent = indent + 16
				local subOrder = {}
				for k, v in pairs(args) do
					table.insert(subOrder, { key = k, data = v })
				end
				table.sort(subOrder, function(a, b)
					return (a.data.order or 999) < (b.data.order or 999)
				end)
				for _, subEntry in ipairs(subOrder) do
					local subOpt = subEntry.data
					local subCaption = subOpt.name or subEntry.key
					AddControl(subCaption, subEntry.key, subOpt, subIndent)
				end
			end
			-- 组后加间距
			yOffset = yOffset - 3
			return row
		else
			local info = row:CreateFontString(nil, "OVERLAY", "GameFontWhite")
			info:SetFont(STANDARD_TEXT_FONT, 9)
			info:SetJustifyH("RIGHT")
			info:SetPoint("RIGHT", row, "RIGHT", -6, 0)
			info:SetText("(未知类型)")
		end

		-- 给子控件也挂悬停提示（子控件会拦截鼠标事件，row 的 OnEnter 不触发）
		if rowTooltipDesc and rowTooltipDesc ~= "" then
			for _, child in ipairs({ row:GetChildren() }) do
				local ctyp = child:GetObjectType()
				if (ctyp == "Button" or ctyp == "EditBox" or ctyp == "CheckButton") and child.autoType ~= "color" then
					AttachTooltip(child, caption, rowTooltipDesc)
				end
			end
		end

		yOffset = yOffset - row:GetHeight() - 2
		return row
	end

	local order = module._optionOrder or {}
	for _, entry in ipairs(order) do
		local opt = entry.data
		AddControl(opt.name or entry.key, entry.key, opt, 0)
	end

	container:SetHeight(-yOffset + 10)
	UpdateScrollBar(rightPanel.settingsScroll, rightPanel.settingsSlider, -yOffset + 10)
end

function Automaton:ClearSettingsContainer(container)
	if not container then
		container = self.mainFrame.settingsContainer
	end
	for i = container:GetNumChildren(), 1, -1 do
		local child = select(i, container:GetChildren())
		child:Hide()
		child:SetParent(nil)
	end
	container:SetHeight(1)
	if self.mainFrame and self.mainFrame.settingsScroll then
		UpdateScrollBar(self.mainFrame.settingsScroll, self.mainFrame.settingsSlider, 1)
	end
end

---------------------------------
--      窗口切换               --
---------------------------------

function Automaton:ToggleMainWindow()
	if not self.mainFrame then
		self:CreateMainWindow()
	end
	if self.mainFrame:IsShown() then
		self.mainFrame:Hide()
		-- 关闭窗口时清理可能残留的拖拽状态，避免预览块/落点线卡在界面上
		if self.dragGhost then
			self.dragGhost:Hide()
		end
		if self.dropIndicator then
			self.dropIndicator:Hide()
		end
		self._dragging = false
		self._dragModule = nil
		self._dragRow = nil
		self._dropIndex = nil
		self._lastDragEndTime = nil
	else
		self.mainFrame:Show()
		self:PopulateModuleList()
		-- 清除搜索框焦点，避免光标一直停在搜索框
		if self.mainFrame.leftPanel and self.mainFrame.leftPanel.searchBox then
			self.mainFrame.leftPanel.searchBox:ClearFocus()
		end
		if self.selectedModule then
			if self.selectedModule == HOME_KEY then
				self:ShowHomePage()
			else
				self:RefreshModuleSettings(self.selectedModule)
			end
		else
			self:SelectModule(self:GetInitialModule())
		end
	end
end

---------------------------------
--      FuBar 插件支持         --
---------------------------------

Automaton.name = "主页"
Automaton.hasIcon = "Interface\\Icons\\Trade_Engineering"
Automaton.hideWithoutStandby = true
Automaton.tooltipHiddenWhenEmpty = true

function Automaton:SetPluginSide(side)
	self.db.profile.position = side
end

function Automaton:GetPluginSide()
	return self.db.profile.position or "LEFT"
end

Automaton.OnClick = function()
	Automaton:ToggleMainWindow()
end

---------------------------------
--      模块可见性更新（兼容）--
---------------------------------

function Automaton:UpdateModuleVisibility()
	if self.mainFrame and self.mainFrame:IsShown() then
		self:PopulateModuleList()
	end
end

---------------------------------
--      加载提示               --
---------------------------------

if DEFAULT_CHAT_FRAME then
	DEFAULT_CHAT_FRAME:AddMessage(
		"|cffffcc00[|r|cff00ffffAutomaton|r|cffffcc00]|r 设置界面已加载，输入 /auto 打开配置窗口"
	)
end
