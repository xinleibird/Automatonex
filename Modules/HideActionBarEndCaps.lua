assert(Automaton, "Automaton not found!")

------------------------------
--      Are you local?      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_HideActionBarEndCaps")

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function()
	return {
		["Hide ActionBar End Caps"] = "隐藏动作条狮鹫",
		["Hides the left and right griffin end caps of the main action bar."] = "隐藏主动作条左右两侧的狮鹫装饰",
	}
end)

L:RegisterTranslations("zhCN", function()
	return {
		["Hide ActionBar End Caps"] = "隐藏动作条狮鹫",
		["Hides the left and right griffin end caps of the main action bar."] = "隐藏主动作条左右两侧的狮鹫装饰",
	}
end)

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_HideActionBarEndCaps = Automaton:NewModule("HideActionBarEndCaps")
Automaton_HideActionBarEndCaps.modulename = L["Hide ActionBar End Caps"]
Automaton_HideActionBarEndCaps.moduledesc = L["Hides the left and right griffin end caps of the main action bar."]
Automaton_HideActionBarEndCaps.options = {}

------------------------------
--      Initialization      --
------------------------------

function Automaton_HideActionBarEndCaps:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("HideActionBarEndCaps")
	Automaton:RegisterDefaults("HideActionBarEndCaps", "profile", {
		disabled = true,
	})
	Automaton:SetDisabledAsDefault(self, "HideActionBarEndCaps")
	self:RegisterOptions(self.options)
end

function Automaton_HideActionBarEndCaps:OnEnable()
	-- 隐藏左右狮鹫装饰
	if MainMenuBarLeftEndCap then
		MainMenuBarLeftEndCap:Hide()
	end
	if MainMenuBarRightEndCap then
		MainMenuBarRightEndCap:Hide()
	end
end

function Automaton_HideActionBarEndCaps:OnDisable()
	-- 显示左右狮鹫装饰
	if MainMenuBarLeftEndCap then
		MainMenuBarLeftEndCap:Show()
	end
	if MainMenuBarRightEndCap then
		MainMenuBarRightEndCap:Show()
	end
end
