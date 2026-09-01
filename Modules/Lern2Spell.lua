assert(Automaton, "Automaton not found!")

----------------------------
--      Localization      --
----------------------------

local L = AceLibrary("AceLocale-2.2"):new("Lern2Spell")

L:RegisterTranslations("zhCN", function()
	return {
		upgrade = "编号#%s按钮 更新技能为 %s (%s)",
	}
end)

------------------------------
--      Are you local?      --
------------------------------

local gratuity = AceLibrary("Gratuity-2.0")

----------------------------------
--  已学物品标记：颜色与工具提示  --
----------------------------------

local COLOR = { r = 0.1, g = 1.0, b = 0.1 }

local tooltip = CreateFrame("GameTooltip")
tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

local IsAlreadyKnown, IsQuest
do
	local lines = {}
	for i = 1, 40 do
		lines[i] = tooltip:CreateFontString()
		tooltip:AddFontStrings(lines[i], tooltip:CreateFontString())
	end

	function IsAlreadyKnown(itemLink)
		if not itemLink then
			return
		end

		tooltip:ClearLines()
		local item = string.gsub(itemLink, ".*(item:%d+:%d+:%d+:%d+).*", "%1", 1)
		tooltip:SetHyperlink(item)
		for i = 1, tooltip:NumLines() do
			if lines[i]:GetText() == ITEM_SPELL_KNOWN then
				return true
			end
		end
	end

	function IsQuest(itemLink)
		if not itemLink then
			return
		end

		tooltip:ClearLines()
		local item = string.gsub(itemLink, ".*(item:%d+:%d+:%d+:%d+).*", "%1", 1)
		tooltip:SetHyperlink(item)
		for i = 1, tooltip:NumLines() do
			if lines[i]:GetText() == ITEM_BIND_QUEST then
				return true
			end
		end
	end
end

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_Lern2Spell = Automaton:NewModule("Lern2Spell")
Automaton_Lern2Spell.modulename = "技能与物品管理"
Automaton_Lern2Spell.moduledesc =
	"新学技能后自动更新动作条到最高等级，并在拍卖行/商人界面标记已学物品和任务物品"
Automaton_Lern2Spell.options = {
	upgradeSpells = {
		type = "toggle",
		name = "技能更新",
		desc = "新学技能后自动更新动作条到最高等级",
		order = 2,
		get = function()
			return Automaton_Lern2Spell.db.profile.upgradeSpells
		end,
		set = function(v)
			Automaton_Lern2Spell.db.profile.upgradeSpells = v
		end,
	},
	markKnown = {
		type = "toggle",
		name = "已学物品标记",
		desc = "在拍卖行/商人界面标记已学物品和任务物品",
		order = 3,
		get = function()
			return Automaton_Lern2Spell.db.profile.markKnown
		end,
		set = function(v)
			Automaton_Lern2Spell.db.profile.markKnown = v
		end,
	},
}

------------------------------
--      Initialization      --
------------------------------

function Automaton_Lern2Spell:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("Lern2Spell")
	Automaton:RegisterDefaults("Lern2Spell", "profile", {
		upgradeSpells = true,
		markKnown = true,
	})
	self:RegisterOptions(self.options)
end

function Automaton_Lern2Spell:OnEnable()
	-- 技能更新：加载 Gratuity 库，注册新学技能事件
	self.gratuity = gratuity
	self:RegisterEvent("SpecialEvents_LearnedSpell")

	-- 已学物品标记：拍卖行钩子
	hooksecurefunc("AuctionFrame_LoadUI", function()
		if AuctionFrameBrowse_Update then
			hooksecurefunc("AuctionFrameBrowse_Update", function()
				if not Automaton_Lern2Spell.db.profile.markKnown then
					return
				end
				local numItems = GetNumAuctionItems("list")
				local offset = FauxScrollFrame_GetOffset(BrowseScrollFrame)

				for i = 1, NUM_BROWSE_TO_DISPLAY do
					local index = offset + i
					if index > numItems then
						return
					end

					local texture = _G["BrowseButton" .. i .. "ItemIconTexture"]
					if texture and texture:IsShown() then
						local _, _, _, _, canUse = GetAuctionItemInfo("list", index)
						if canUse and IsAlreadyKnown(GetAuctionItemLink("list", index)) then
							texture:SetVertexColor(COLOR.r, COLOR.g, COLOR.b)
						end
					end
				end
			end)
		end
	end)

	-- 已学物品标记：商人钩子
	hooksecurefunc("MerchantFrame_Update", function()
		if not Automaton_Lern2Spell.db.profile.markKnown then
			return
		end
		local numItems = GetMerchantNumItems()

		for i = 1, MERCHANT_ITEMS_PER_PAGE do
			local index = (MerchantFrame.page - 1) * MERCHANT_ITEMS_PER_PAGE + i
			if index > numItems then
				return
			end

			local merchantButton = _G["MerchantItem" .. i]
			local itemButton = _G["MerchantItem" .. i .. "ItemButton"]
			if itemButton and itemButton:IsShown() then
				local _, _, _, _, numAvailable, isUsable = GetMerchantItemInfo(index)
				if isUsable and IsAlreadyKnown(GetMerchantItemLink(index)) then
					local r, g, b = COLOR.r, COLOR.g, COLOR.b
					if numAvailable == 0 then
						r, g, b = r * 0.5, g * 0.5, b * 0.5
					end
					SetItemButtonNameFrameVertexColor(merchantButton, r, g, b)
					SetItemButtonSlotVertexColor(merchantButton, r, g, b)
					SetItemButtonTextureVertexColor(itemButton, r, g, b)
					SetItemButtonNormalTextureVertexColor(itemButton, r, g, b)
				end
				if isUsable and IsQuest(GetMerchantItemLink(index)) then
					SetItemButtonNameFrameVertexColor(merchantButton, 1, 1, 0)
					SetItemButtonSlotVertexColor(merchantButton, 1, 1, 0)
					SetItemButtonTextureVertexColor(itemButton, 1, 1, 0)
					SetItemButtonNormalTextureVertexColor(itemButton, 1, 1, 0)
				end
			end
		end
	end)
end

function Automaton_Lern2Spell:OnDisable()
	self:UnregisterAllEvents()
end

------------------------------
--      技能更新逻辑        --
------------------------------

function Automaton_Lern2Spell:SpecialEvents_LearnedSpell(spell, rank)
	if not self.db.profile.upgradeSpells then
		return
	end
	for btn = 1, 120 do
		local n, r = self:ActionIsSpell(btn)
		if n and n == spell and ((r or "") ~= rank) then
			local i = self:GetSpellIndex(spell, rank)
			if not i then
				return
			end

			local n, r = GetSpellName(i, BOOKTYPE_SPELL)
			self:Print(L.upgrade, btn, n, r or "??")
			PickupSpell(i, BOOKTYPE_SPELL)
			PlaceAction(btn)

			repeat
				if CursorHasItem() or CursorHasSpell() then
					PickupSpell(1, BOOKTYPE_SPELL)
				end
			until not CursorHasItem() and not CursorHasSpell()
		end
	end
end

function Automaton_Lern2Spell:GetSpellIndex(spell, rank)
	assert(spell, "No spell passed")

	local i, n, r = 1
	repeat
		n, r = GetSpellName(i, BOOKTYPE_SPELL)
		if n and n == spell and r == rank then
			return i
		end
		i = i + 1
	until not n
end

function Automaton_Lern2Spell:ActionIsSpell(id)
	if not id or GetActionText(id) then
		return
	end

	self.gratuity:SetAction(id)
	return self.gratuity:GetLine(1)
end
