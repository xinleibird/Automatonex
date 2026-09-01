assert(Automaton, "Automaton not found!")

------------------------------
--      Are you local?      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_follow")

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function()
	return {
		["follow"] = "组队自动跟随（挂机不要用，危险！！！！）",
		["Options for sending out party follows."] = "仅在队伍聊天中匹配关键字自动跟随",
		["follow text"] = "关键字",
		["The text users send to trigger an follow."] = "聊天关键字",
		["keyword follow"] = "关键字跟随",
		["Ignore case"] = "模糊关键字",
		["Disable case sensitivity for the follow text"] = "模糊关键字的匹配(不论大小写等)",
	}
end)

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_follow = Automaton:NewModule("follow")
Automaton_follow.modulename = L["follow"]
Automaton_follow.moduledesc = L["Options for sending out party follows."]
Automaton_follow.options = {
	["触发设置"] = {
		type = "group",
		name = "触发设置",
		desc = "自动跟随的触发条件",
		order = 1,
		args = {
			keyword = {
				type = "text",
				name = L["follow text"],
				desc = L["The text users send to trigger an follow."],
				order = 1,
				usage = L["keyword follow"],
				get = function()
					return Automaton_follow.db.profile.followString
				end,
				set = function(v)
					Automaton_follow.db.profile.followString = v
				end,
			},
			case = {
				type = "toggle",
				name = L["Ignore case"],
				desc = L["Disable case sensitivity for the follow text"],
				order = 2,
				get = function()
					return Automaton_follow.db.profile.ignoreCase
				end,
				set = function(v)
					Automaton_follow.db.profile.ignoreCase = v
				end,
			},
		},
	},
	["回复设置"] = {
		type = "group",
		name = "回复设置",
		desc = "收到跟随指令后的回复",
		order = 2,
		args = {
			Reply = {
				type = "toggle",
				name = "收到跟随指令后密语回复",
				desc = "收到跟随指令后是否密语回复",
				order = 1,
				get = function()
					return Automaton_follow.db.profile.reply
				end,
				set = function(v)
					Automaton_follow.db.profile.reply = v
				end,
			},
		},
	},
}

------------------------------
--      Initialization      --
------------------------------

function Automaton_follow:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("follow")
	Automaton:RegisterDefaults("follow", "profile", {
		disabled = true,
		followString = "跟随我",
		ignoreCase = false,
		reply = true,
		turnraid = false,
	})
	Automaton:SetDisabledAsDefault(self, "follow")
	self:RegisterOptions(self.options)
end

function Automaton_follow:OnEnable()
	-- 仅保留队伍聊天事件监听
	self:RegisterEvent("CHAT_MSG_PARTY")
end

function Automaton_follow:OnDisable()
	self:UnregisterAllEvents()
end

------------------------------
--      Event Handlers      --
------------------------------

-- 仅保留队伍聊天频道的处理逻辑
function Automaton_follow:CHAT_MSG_PARTY(text, from)
	local keyword = Automaton_follow.db.profile.followString
	local msg = text

	if Automaton_follow.db.profile.ignoreCase then
		keyword = string.lower(keyword)
		msg = string.lower(msg)
	end

	-- 匹配关键字且排除自身发送的消息
	if string.find(msg, format("^%s$", keyword)) and from ~= UnitName("player") then
		FollowByName(from)
		if Automaton_follow.db.profile.reply then
			SendChatMessage("收到跟随指令，正在跟随!", "WHISPER", nil, from)
		end
		AssistByName(from)
	end
end
