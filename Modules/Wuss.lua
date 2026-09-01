assert(Automaton, "Automaton not found!")

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_Wuss = Automaton:NewModule("Wuss")
Automaton_Wuss.modulename = "自动拒绝决斗"
Automaton_Wuss.moduledesc = "自动拒绝所有决斗请求"
Automaton_Wuss.options = {}

------------------------------
--      Initialization      --
------------------------------

function Automaton_Wuss:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("Wuss")
	Automaton:RegisterDefaults("Wuss", "profile", {
		disabled = true,
	})
	Automaton:SetDisabledAsDefault(self, "Wuss")

	self:RegisterOptions(self.options)
end

function Automaton_Wuss:OnEnable()
	self:RegisterEvent("DUEL_REQUESTED")
end

function Automaton_Wuss:OnDisable()
	self:UnregisterAllEvents()
end

------------------------------
--      Event Handlers      --
------------------------------

function Automaton_Wuss:DUEL_REQUESTED()
	self:print(L["Canceling duel..."])
	CancelDuel()
	StaticPopup_Hide("DUEL_REQUESTED")
end
