assert(Automaton, "Automaton not found!")

------------------------------
--      Are you local?      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_Group")

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function()
	return {
		["Group"] = "组队自动进组",
		["Who"] = "自动查询陌生人",
		["Perform a /who on incoming party invites from unknown sources."] = "来自陌生人的消息，自动/Who查询",
		["Delay"] = "延迟设置",
		["With this option enabled, automatic joining or declining is delayed for 55 seconds."] = "启用此选项后，自动加入/拒绝将延迟55秒。",
		["Declining party invitation..."] = "拒绝邀请。。。",
		["Accepting invite in 55..."] = "55秒后自动接受邀请。。。",
		["Declining invite in 55..."] = "55秒后自动拒绝邀请。。。",

		["Options for accepting or declining group invites."] = "自动接受/拒绝组队邀请（好友及工会）",
		["Decline"] = "总是拒绝（好友及工会以外的）",
		["Decline party invites from unknown sources."] = "自动拒绝组队邀请",
	}
end)

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_Group = Automaton:NewModule("Group")
Automaton_Group.modulename = L["Group"]
Automaton_Group.moduledesc = L["Options for accepting or declining group invites."]
Automaton_Group.options = {
	who = {
		type = "toggle",
		name = L["Who"],
		desc = L["Perform a /who on incoming party invites from unknown sources."],
		order = 2,
		get = function()
			return Automaton_Group.db.profile.who
		end,
		set = function(v)
			Automaton_Group.db.profile.who = v
		end,
	},
	decline = {
		type = "toggle",
		name = L["Decline"],
		desc = L["Decline party invites from unknown sources."],
		order = 3,
		get = function()
			return Automaton_Group.db.profile.decline
		end,
		set = function(v)
			Automaton_Group.db.profile.decline = v
		end,
	},
	delay = {
		type = "toggle",
		name = L["Delay"],
		desc = L["With this option enabled, automatic joining or declining is delayed for 55 seconds."],
		order = 4,
		get = function()
			return Automaton_Group.db.profile.delay
		end,
		set = function(v)
			Automaton_Group.db.profile.delay = v
		end,
	},
}

------------------------------
--      Initialization      --
------------------------------

function Automaton_Group:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("Group")
	Automaton:RegisterDefaults("Group", "profile", {
		who = true,
		decline = false,
		delay = false,
		disabled = true,
	})
	Automaton:SetDisabledAsDefault(self, "Group")

	self:RegisterOptions(self.options)
end

function Automaton_Group:OnEnable()
	self:RegisterEvent("PARTY_INVITE_REQUEST")
end

function Automaton_Group:OnDisable()
	self:UnregisterAllEvents()
end

------------------------------
--      Event Handlers      --
------------------------------

function Automaton_Group:ProcessInvite(accept)
	if accept then
		self:Debug("Accepting an invite")
		AcceptGroup()
		self:RegisterEvent("PARTY_MEMBERS_CHANGED")
	else
		self:print(L["Declining party invitation..."])
		DeclineGroup()
		-- 添加强制关闭邀请对话框的代码
		StaticPopup_Hide("PARTY_INVITE")
	end
end

function Automaton_Group:PARTY_MEMBERS_CHANGED()
	StaticPopup_Hide("PARTY_INVITE")
	self:Debug("Trying to close the window")
	self:UnregisterEvent("PARTY_MEMBERS_CHANGED")
end

function Automaton_Group:PARTY_INVITE_REQUEST(from)
	self:Debug("Processing invite...")
	--local from = arg1
	local acceptFrom = {}
	GuildRoster()

	for i = 1, GetNumGuildMembers() do
		local name = GetGuildRosterInfo(i)
		tinsert(acceptFrom, name)
	end

	for i = 1, GetNumFriends() do
		local name = GetFriendInfo(i)
		tinsert(acceptFrom, name)
	end

	if foreachi(acceptFrom, function(i, v)
		if v == from then
			return true
		end
	end) then
		if self.db.profile.delay then
			self:print(L["Accepting invite in 55..."])
			self:ScheduleEvent("Automaton_GroupAccept", self.ProcessInvite, 55, self, true)
		else
			self:ProcessInvite(true)
		end
		return
	end

	if self.db.profile.decline then
		if self.db.profile.delay then
			self:print(L["Declining invite in 55..."])
			self:ScheduleEvent("Automaton_GroupDecline", self.ProcessInvite, 55, self, false)
		else
			self:ProcessInvite(false)
		end
	elseif self.db.profile.who then
		SendWho('n-"' .. from .. '"')
	end
end
