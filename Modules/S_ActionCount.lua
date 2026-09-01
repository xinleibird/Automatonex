assert(Automaton, "Automaton not found!")

------------------------------
--      Localization      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("S_ActionCount")

L:RegisterTranslations("zhCN", function()
	return {
		["ActionCount"] = "技能材料计数",
		["Display reagent counts for action bar spells"] = "在动作条技能上显示所需材料的数量",
	}
end)

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_ActionCount = Automaton:NewModule("ActionCount")
Automaton_ActionCount.modulename = L["ActionCount"]
Automaton_ActionCount.moduledesc = L["Display reagent counts for action bar spells"]
Automaton_ActionCount.options = {} -- 该模块无配置项

------------------------------
--      Local Functions      --
------------------------------

local S_ActionCountLine = AceLibrary("Gratuity-2.0")

-- 颜色设置函数
local function ActionCountColor(text, num)
	local r, g, b

	if num == "" then
		text:SetTextColor(1.0, 1.0, 1.0)
		return
	end

	if not num then
		num = 0
	elseif num > 10 then
		num = 10
	end
	num = num / 10

	if num > 0.5 then
		r = (1.0 - num) * 2
		g = 1.0
	else
		r = 1.0
		g = num * 2
	end

	b = 0.0
	text:SetTextColor(r, g, b)
end

-- 显示材料数量
local function ShowActionSpellCount()
	local text = getglobal(this:GetName() .. "Count")
	local action = ActionButton_GetPagedID(this)

	local texture = GetActionTexture(action)
	if texture then
		S_ActionCountLine:SetAction(action)
		local _, _, Reagent = S_ActionCountLine:Find(SPELL_REAGENTS .. "(.+)")
		if Reagent then
			local count = select(5, FindItemInfo(Reagent))
			if count and count > 0 then
				text:SetText(count)
			else
				text:SetText("0")
			end
			ActionCountColor(text, count)
		end
	end
end

------------------------------
--      Module Methods      --
------------------------------

function Automaton_ActionCount:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("ActionCount")
	Automaton:RegisterDefaults("ActionCount", "profile", {
		disabled = false, -- 默认启用
	})
	Automaton:SetDisabledAsDefault(self, "ActionCount")
	self:RegisterOptions(self.options)
end

function Automaton_ActionCount:OnEnable()
	-- 注册事件钩子
	self:HookActionButtonEvents()
end

function Automaton_ActionCount:OnDisable()
	-- 移除钩子并清除显示
	self:UnhookActionButtonEvents()
	self:ClearAllCounts()
end

------------------------------
--      Event Handling      --
------------------------------

function Automaton_ActionCount:HookActionButtonEvents()
	-- 钩子动作条事件处理函数
	hooksecurefunc("ActionButton_OnEvent", function(event)
		this:RegisterEvent("BAG_UPDATE")
		if event == "BAG_UPDATE" then
			ShowActionSpellCount()
		end
		if event == "ACTIONBAR_SLOT_CHANGED" then
			if arg1 == -1 or arg1 == ActionButton_GetPagedID(this) then
				ShowActionSpellCount()
			end
		end
		if
			event == "ACTIONBAR_PAGE_CHANGED"
			or event == "PLAYER_AURAS_CHANGED"
			or event == "UPDATE_BONUS_ACTIONBAR"
		then
			ShowActionSpellCount()
		end
		if event == "UNIT_INVENTORY_CHANGED" then
			if arg1 == "player" then
				ShowActionSpellCount()
			end
		end
	end)
end

function Automaton_ActionCount:UnhookActionButtonEvents()
	-- 由于hooksecurefunc无法直接解除，这里通过禁用时清除显示来模拟
	self:ClearAllCounts()
end

function Automaton_ActionCount:ClearAllCounts()
	-- 清除所有动作条上的计数显示
	for i = 1, 12 do
		local countText = getglobal("ActionButton" .. i .. "Count")
		if countText then
			countText:SetText("")
		end
	end
end
