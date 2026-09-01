assert(Automaton, "Automaton not found!")

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_ItemLinkEnUS = Automaton:NewModule("ItemLinkEnUS")
local self = Automaton_ItemLinkEnUS

-- 本地化配置
local L = AceLibrary("AceLocale-2.2"):new("Automaton_ItemLinkEnUS")
L:RegisterTranslations("zhCN", function()
	return {
		["ItemLinkEnUS"] = "物品链接英文转换",
		["Convert item links to English when using Alt+Click"] = "Alt+点击时将物品链接转换为英文名称",
	}
end)

-- 模块基本信息
Automaton_ItemLinkEnUS.modulename = L["ItemLinkEnUS"]
Automaton_ItemLinkEnUS.moduledesc = L["Convert item links to English when using Alt+Click"]
Automaton_ItemLinkEnUS.options = {} -- 该模块无额外配置项

----------------------------------
--      Local Functions        --
----------------------------------

local I_enUS = LibStub("LibItem-enUS-1.0")

local function EditBox_Alt_Left(button)
	if ChatFrameEditBox:IsVisible() and IsAltKeyDown() and button == "LeftButton" then
		return true
	end
	return false
end

local function ChatEdit_InsertLink(quality, link, id)
	if I_enUS.Item_enUS[id] then
		ChatFrameEditBox:Insert(
			format("%s|H%s|h[%s]|h|r", ITEM_QUALITY_COLORS[quality].hex, link, I_enUS.Item_enUS[id])
		)
		if CursorHasItem() then
			ClearCursor()
		end
	end
end

----------------------------------
--      Hook Registrations      --
----------------------------------

local function RegisterHooks()
	-- 角色装备栏
	hooksecurefunc("PaperDollItemSlotButton_OnClick", function(button, ignoreShift)
		if EditBox_Alt_Left(button) then
			local Itemlink = GetInventoryItemLink("player", this:GetID())
			local id = GetItemID(Itemlink)
			local _, link, quality = GetItemInfo(id)
			if link then
				ChatEdit_InsertLink(quality, link, id)
			end
		end
	end)

	-- 背包物品
	hooksecurefunc("ContainerFrameItemButton_OnClick", function(button, ignoreShift)
		if EditBox_Alt_Left(button) then
			local bagID = this:GetParent():GetID()
			local slot = this:GetID()
			local id = GetItemID(GetContainerItemLink(bagID, slot))
			local _, link, quality = GetItemInfo(id)
			if link then
				ChatEdit_InsertLink(quality, link, id)
			end
		end
	end)

	-- 商人物品
	hooksecurefunc("MerchantItemButton_OnClick", function(button)
		if EditBox_Alt_Left(button) then
			local Itemlink = GetMerchantItemLink(this:GetID())
			local id = GetItemID(Itemlink)
			local _, link, quality = GetItemInfo(id)
			if link then
				ChatEdit_InsertLink(quality, link, id)
			end
		end
	end)

	-- 拾取物品
	hooksecurefunc("LootFrameItem_OnClick", function(button)
		if EditBox_Alt_Left(button) then
			local Itemlink = GetLootSlotLink(this.slot)
			local id = GetItemID(Itemlink)
			local _, link, quality = GetItemInfo(id)
			if link then
				ChatEdit_InsertLink(quality, link, id)
			end
		end
	end)

	-- 聊天框物品链接
	hooksecurefunc("SetItemRef", function(link, text, button)
		if EditBox_Alt_Left(button) then
			local linkType = string.split(":", link)
			if linkType == "item" then
				local id = GetItemID(link)
				local _, link, quality = GetItemInfo(id)
				if link then
					ChatEdit_InsertLink(quality, link, id)
					if ItemRefTooltip:IsVisible() then
						ItemRefCloseButton:Click()
					end
				end
			end
		end
	end)
end

----------------------------------
--      Module Events          --
----------------------------------

function Automaton_ItemLinkEnUS:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("ItemLinkEnUS")
	Automaton:RegisterDefaults("ItemLinkEnUS", "profile", {
		disabled = false,
	})
	Automaton:SetDisabledAsDefault(self, "ItemLinkEnUS")
	self:RegisterOptions(self.options)
end

function Automaton_ItemLinkEnUS:OnEnable()
	RegisterHooks() -- 启用模块时注册钩子
end

function Automaton_ItemLinkEnUS:OnDisable()
	-- 由于钩子无法直接移除，禁用模块时可添加状态判断
	-- 这里保留空实现以符合模块规范
end
