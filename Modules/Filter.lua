assert(Automaton, "Automaton not found!")

------------------------------
--      Are you local?      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_Filter")

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function()
	return {
		["Filter"] = "职业技能过滤",
		["Show only available skills at trainers by default."] = "只显示职业训练师可学技能，可通过职业训练师的过滤器查看全部技能",
	}
end)

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_Filter = Automaton:NewModule("Filter")
Automaton_Filter.modulename = L["Filter"]
Automaton_Filter.moduledesc = L["Show only available skills at trainers by default."]
Automaton_Filter.options = {}

------------------------------
--      Initialization      --
------------------------------

function Automaton_Filter:OnInitialize()
	self:RegisterOptions(self.options)
end

function Automaton_Filter:OnEnable()
	self:RegisterEvent("TRAINER_SHOW")
end

function Automaton_Filter:OnDisable()
	self:UnregisterAllEvents()
end

------------------------------
--      Event Handlers      --
------------------------------

function Automaton_Filter:TRAINER_SHOW()
	SetTrainerServiceTypeFilter("unavailable", 0)
end
