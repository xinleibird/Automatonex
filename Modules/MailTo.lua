assert(Automaton, "Automaton not found!")

local Automaton_MailTo = Automaton:NewModule("MailTo")
Automaton_MailTo.modulename = "邮箱记录收件人"
Automaton_MailTo.moduledesc = "记录邮箱收件人"
Automaton_MailTo.options = {}
-- Message text
local L = {
	TOOLTIP = "点击选择收件人",
	LISTFULL = "警告:收件人列表已满",
	ADDED = " 添加到收件人列表",
	REMOVED = " 从收件人列表中移除",
	F_ADD = "(添加 %s)",
	F_REMOVE = "(移除 %s)",
}
local Selected, Name, SavedName, Server, playerName

------------------------------
--      Initialization      --
------------------------------

local MailToDropDownMenu = CreateFrame("Button", "MailToDropDownMenu", SendMailNameEditBox)
MailToDropDownMenu:Hide()
MailToDropDownMenu:SetWidth(24)
MailToDropDownMenu:SetHeight(24)
MailToDropDownMenu:SetPoint("RIGHT", SendMailNameEditBox, "RIGHT", 6, 0)
MailToDropDownMenu:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
MailToDropDownMenu:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
MailToDropDownMenu:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
function Automaton_MailTo:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("MailTo")
	Automaton:RegisterDefaults("MailTo", "profile", {
		disabled = false,
		MailToDB = {},
	})
	Automaton:SetDisabledAsDefault(self, "MailTo")
	self.MailTo = MailToDropDownMenu
	self:RegisterOptions(self.options)
	MailToDropDownMenu.displayMode = "MENU"

	playerName = UnitName("player")
	Server = GetRealmName()

	if not self.db.profile.MailToDB[Server] then
		self.db.profile.MailToDB[Server] = {}
	end
	if not self.db.profile.MailToDB[Server][playerName] then
		self.db.profile.MailToDB[Server][playerName] = {}
	end
end

function Automaton_MailTo:OnEnable()
	self:HookScript(self.MailTo, "OnShow", "OnShow")
	self:HookScript(self.MailTo, "OnHide", "OnHide")
	self:HookScript(self.MailTo, "OnClick", "OnClick")
	self:HookScript(self.MailTo, "OnEnter", "OnEnter")
	self:HookScript(self.MailTo, "OnLeave", "OnLeave")
	self.MailTo:Show()
end

function Automaton_MailTo:OnDisable()
	self:UnhookAll()
	self.MailTo:Hide()
end

------------------------------
--      Event Handlers      --
------------------------------

-- 选择收件人
local function ListSelect()
	local value = this.value

	if value then
		SendMailNameEditBox:SetText(Automaton_MailTo.db.profile.MailToDB[Server][playerName][value])
		SendMailNameEditBox:HighlightText(0, -1)
		SendMailSubjectEditBox:SetText(format("[%s] %s", playerName, date("%Y-%m-%d")))
		SendMailSubjectEditBox:SetFocus()
	end
end

-- 增加收件人
local function ListAdd(name)
	if not name then
		name = Name
	end
	tinsert(Automaton_MailTo.db.profile.MailToDB[Server][playerName], name)
	sort(Automaton_MailTo.db.profile.MailToDB[Server][playerName])
	print("|cff00FAFA" .. name .. L.ADDED, "MailTo")
end

-- 移除收件人
local function ListRemove()
	tremove(Automaton_MailTo.db.profile.MailToDB[Server][playerName], Selected)
	print("|cff00FAFA" .. Name .. L.REMOVED, "MailTo")
end

-- 获取收件人姓名
local function InList(MCname)
	local LCname = string.lower(MCname)
	for key, name in Automaton_MailTo.db.profile.MailToDB[Server][playerName] do
		if LCname == string.lower(name) then
			return key
		end
	end
end

-- 下拉菜单
local function ToList_Init()
	local info = { value = 0, notCheckable = 1 }
	Name = SendMailNameEditBox:GetText()
	if Name ~= "" then
		Selected = InList(Name)
		if Selected then
			info.text = string.format(L.F_REMOVE, Name)
			info.func = ListRemove
		elseif table.getn(Automaton_MailTo.db.profile.MailToDB[Server][playerName]) < UIDROPDOWNMENU_MAXBUTTONS then
			info.text = string.format(L.F_ADD, Name)
			info.func = ListAdd
		else
			info = nil
			print("|cffff4040" .. L.LISTFULL, "MailTo")
		end
		if info then
			UIDropDownMenu_AddButton(info)
		end
	end
	for key, name in Automaton_MailTo.db.profile.MailToDB[Server][playerName] do
		info = { text = name, value = key, func = ListSelect }
		if key == Selected then
			info.checked = 1
		end
		UIDropDownMenu_AddButton(info)
	end
end
function Automaton_MailTo:OnShow()
	if not self.S_Menu then
		self.S_Menu = CreateFrame("Button", "S_Menu", self.MailTo, "UIDropDownMenuTemplate")
		self.S_Menu:Hide()
		self.S_Menu.point = "TOPRIGHT"
		self.S_Menu.relativeTo = SendMailNameEditBox
		self.S_Menu.relativePoint = "BOTTOMRIGHT"
		self.S_Menu.xOffset = 0
		self.S_Menu.yOffset = 0
		UIDropDownMenu_Initialize(self.S_Menu, ToList_Init, "MENU")
	end
end

function Automaton_MailTo:OnHide()
	CloseDropDownMenus()
end

function Automaton_MailTo:OnClick()
	ToggleDropDownMenu(nil, nil, self.S_Menu)
	PlaySound("igMainMenuOptionCheckBoxOn")
end

function Automaton_MailTo:OnEnter()
	GameTooltip:SetOwner(self.MailTo, "ANCHOR_TOPRIGHT")
	GameTooltip:SetText(L.TOOLTIP)
	GameTooltip:Show()
end

function Automaton_MailTo:OnLeave()
	GameTooltip:Hide()
end
