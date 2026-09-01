assert(Automaton, "Automaton not found!")

------------------------------
--      Are you local?      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_LootBOP")

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function()
	return {
		["LootBOP"] = "团队拾取确认",
		["Ignore BOP confirm message when not in a party or raid"] = "小队或团队中装绑拾取确认自动确认",
	}
end)

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_LootBOP = Automaton:NewModule("LootBOP")
Automaton_LootBOP.modulename = L["LootBOP"]
Automaton_LootBOP.moduledesc = L["Ignore BOP confirm message when not in a party or raid"]
Automaton_LootBOP.options = {}

------------------------------
--      Initialization      --
------------------------------

function Automaton_LootBOP:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("LootBOP")
	Automaton:RegisterDefaults("LootBOP", "profile", {
		disabled = true,
	})
	Automaton:SetDisabledAsDefault(self, "LootBOP")

	self:RegisterOptions(self.options)
end

function Automaton_LootBOP:OnEnable()
	self:RegisterEvent("LOOT_BIND_CONFIRM")
end

function Automaton_LootBOP:OnDisable()
	self:UnregisterAllEvents()
end

------------------------------
--      Event Handlers      --
------------------------------

function Automaton_LootBOP:LOOT_BIND_CONFIRM(slot)
	if GetNumPartyMembers() == 0 and GetNumRaidMembers() == 0 then
		self:Debug("Looting...")
		local dialog = StaticPopup_Show("LOOT_BIND")
		if dialog then
			dialog.data = arg1
			StaticPopup1Button1:Click()
		end
	end
end
