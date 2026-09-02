assert(Automaton, "Automaton not found!")

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_invall = Automaton:NewModule("invall")
Automaton_invall.modulename = "自动邀请周围玩家"
Automaton_invall.moduledesc = "自动邀请周围通过说，大喊：inv,invite,组关键的字的玩家"
Automaton_invall.options = {}

------------------------------
--      Initialization      --
------------------------------

function Automaton_invall:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("invall")
	Automaton:RegisterDefaults("invall", "profile", {
		disabled = true,
	})
	Automaton:SetDisabledAsDefault(self, "invall")

	self:RegisterOptions(self.options)
end

function Automaton_invall:OnEnable()
	self:RegisterEvent("CHAT_MSG_WHISPER", "InvUnit")
	self:RegisterEvent("CHAT_MSG_SAY", "InvUnit")
	self:RegisterEvent("CHAT_MSG_YELL", "InvUnit")
	self:RegisterEvent("ZONE_CHANGED_NEW_ARE")
	self:RegisterEvent("CHAT_MSG_SYSTEM")
end

function Automaton_invall:OnDisable()
	self:UnregisterAllEvents()
end

------------------------------
--      Event Handlers      --
------------------------------
function Automaton_invall:ZONE_CHANGED_NEW_ARE()
	self.zone = GetZoneText()
end
function Automaton_invall:CHAT_MSG_SYSTEM()
	local playername = string.match(arg1, "^(.+)加入了团队$")

	if playername then
		PromoteToAssistant(playername)
	end
end
function Automaton_invall:InvUnit(text, player)
	if not self.zone == "冬幕谷" then
		return
	end
	local groupType = UnitInRaid("player") and "raid" or "party"
	local members = groupType == "raid" and GetNumRaidMembers() or GetNumPartyMembers()
	if members == 40 then
		return
	end
	local keyword = {
		"组",
		"invite",
		"inv",
	}
	local msg = string.lower(text)
	for _, k in pairs(keyword) do
		if string.find(msg, k) then
			InviteByName(player)
			break
		end
	end
end
