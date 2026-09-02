assert(Automaton, "Automaton not found!")

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_InterPlayerLink = Automaton:NewModule("InterPlayerLink")
Automaton_InterPlayerLink.modulename = "发送角色链接"
Automaton_InterPlayerLink.moduledesc =
	"按住Shift点击聊天框角色名，发送该角色名到已打开的聊天框内"
Automaton_InterPlayerLink.options = {}

------------------------------
--      Initialization      --
------------------------------

function Automaton_InterPlayerLink:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("InterPlayerLink")
	Automaton:RegisterDefaults("InterPlayerLink", "profile", {
		disabled = false,
	})
	Automaton:SetDisabledAsDefault(self, "InterPlayerLink")

	self:RegisterOptions(self.options)
end

function Automaton_InterPlayerLink:OnEnable()
	self:Hook("SetItemRef")
end

function Automaton_InterPlayerLink:OnDisable()
	self:UnhookAll()
end

------------------------------
--      Event Handlers      --
------------------------------

function Automaton_InterPlayerLink:SetItemRef(link, text, button)
	local playerlink = strsub(link, 1, 6) == "player"
	if playerlink then
		local name = strsub(link, 8)
		if name and (strlen(name) > 0) then
			name = string.match(name, "([^:]+)")
			name = gsub(name, "([^%s]*)%s+([^%s]*)%s+([^%s]*)", "%3")
			name = gsub(name, "([^%s]*)%s+([^%s]*)", "%2")
			if IsShiftKeyDown() and ChatFrameEditBox:IsVisible() then
				ChatFrameEditBox:Insert("|cffffffff|Hplayer:" .. name .. "|h[" .. name .. "]|h|r")
				return
			end
		end
	end
	self.hooks.SetItemRef(link, text, button)
end
