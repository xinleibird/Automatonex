assert(Automaton, "Automaton not found!")

------------------------------
--      Are you local?      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_SelfName")

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function()
	return {

		["SelfName"] = "自定义玩家名字",
		["Decline all incoming duels. Like the SelfName you are."] = "自定义显示玩家角色名",
	}
end)

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_SelfName = Automaton:NewModule("SelfName")
Automaton_SelfName.modulename = L["SelfName"]
Automaton_SelfName.moduledesc = L["Decline all incoming duels. Like the SelfName you are."]
Automaton_SelfName.options = {
	showname = {
		type = "text",
		name = "玩家名字",
		desc = "设置需要显示的自定义玩家名字",
		order = 3,
		usage = "自定义玩家名",
		get = function()
			return Automaton_SelfName.db.profile.showname
		end,
		set = function(v)
			Automaton_SelfName.db.profile.showname = v
		end,
	},
}

------------------------------
--      Initialization      --
------------------------------

function Automaton_SelfName:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("SelfName")
	Automaton:RegisterDefaults("SelfName", "profile", {
		disabled = true,
		showname = UnitName("player"),
	})
	Automaton:SetDisabledAsDefault(self, "SelfName")

	self:RegisterOptions(self.options)
end

function Automaton_SelfName:OnEnable()
	self:RegisterEvent("WORLD_MAP_UPDATE", "SetPlayerName")
	self:RegisterEvent("VARIABLES_LOADED", "SetPlayerName")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function Automaton_SelfName:OnDisable()
	self:UnregisterAllEvents()
	PlayerName:SetText(UnitName("player"))
end
function Automaton_SelfName:SetPlayerName()
	PlayerName:SetText(self.db.profile.showname)
end
function Automaton_SelfName:PLAYER_ENTERING_WORLD()
	self:SetPlayerName()
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end
