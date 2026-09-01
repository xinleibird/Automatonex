assert(Automaton, "Automaton not found!")

------------------------------
--      Are you local?      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_AutoShout")
local timer = nil
local playerName = UnitName("player")

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function()
	return {
		["AutoShout"] = "AutoShout",
		["Automatically send messages to specified channel at intervals"] = "Automatically send messages to specified channel at intervals",
		["Enable AutoShout"] = "Enable AutoShout",
		["Turn on/off automatic shouting"] = "Turn on/off automatic shouting",
		["Message"] = "Message",
		["Set the message to be sent"] = "Set the message to be sent",
		["Interval"] = "Interval (sec)",
		["Set the interval between messages (in seconds)"] = "Set the interval between messages (in seconds)",
		["In Combat"] = "In Combat (Shout)",
		["Allow shouting while in combat"] = "Allow shouting while in combat",
		["Channel"] = "Channel",
		["Select the channel to send messages"] = "Select the channel to send messages",
		["Yell"] = "Yell",
		["Say"] = "Say",
		["Party"] = "Party",
		["Guild"] = "Guild",
		["World"] = "World",
		["Hardcore"] = "Hardcore",
		["Container ID"] = "Container ID",
		["Set the container ID where the item is located (backpack is usually 0)"] = "Set the container ID where the item is located (backpack is usually 0)",
		["Item Slot"] = "Item Slot",
		["Set the slot number of the item (starts from 1)"] = "Set the slot number of the item (starts from 1)",
		["Item List"] = "Item List",
		["Configure up to 5 items to include in messages"] = "Configure up to 5 items to include in messages",
		["AutoReply"] = "AutoReply",
		["Settings for automatic whisper reply"] = "Settings for automatic whisper reply",
		["Enable AutoReply"] = "Enable AutoReply",
		["Turn on/off automatic whisper reply"] = "Turn on/off automatic whisper reply",
		["Reply Message"] = "Reply Message",
		["Set the message to reply with (supports {item1}~{item5})"] = "Set the message to reply with (supports {item1}~{item5})",
		["Reply in Combat"] = "Reply in Combat",
		["Allow replying while in combat"] = "Allow replying while in combat",
	}
end)

L:RegisterTranslations("zhCN", function()
	return {
		["AutoShout"] = "自动喊话",
		["Automatically send messages to specified channel at intervals"] = "按指定间隔自动向指定频道发送消息",
		["Enable AutoShout"] = "启用自动喊话",
		["Turn on/off automatic shouting"] = "开启/关闭自动喊话功能",
		["Message"] = "消息内容",
		["Set the message to be sent"] = "设置要发送的消息内容，{item1}{item2}为物品链接格式",
		["Interval"] = "间隔时间(秒)",
		["Set the interval between messages (in seconds)"] = "设置消息发送间隔时间(秒)",
		["In Combat"] = "战斗中喊话",
		["Allow shouting while in combat"] = "允许在战斗中继续发送喊话消息",
		["Channel"] = "目标频道",
		["Select the channel to send messages"] = "选择发送消息的目标频道",
		["Yell"] = "喊话频道",
		["Say"] = "说",
		["Party"] = "队伍",
		["Guild"] = "公会",
		["World"] = "世界频道",
		["Hardcore"] = "硬核",
		["Container ID"] = "容器ID",
		["Set the container ID where the item is located (backpack is usually 0)"] = "设置物品所在的容器ID（默认背包为0）",
		["Item Slot"] = "物品槽位",
		["Set the slot number of the item (starts from 1)"] = "设置物品所在的槽位（从1开始）",
		["Item List"] = "物品列表",
		["Configure up to 5 items to include in messages"] = "配置最多5个要包含在消息中的物品",
		["AutoReply"] = "自动回复",
		["Settings for automatic whisper reply"] = "自动回复密语的设置",
		["Enable AutoReply"] = "启用自动回复",
		["Turn on/off automatic whisper reply"] = "开启/关闭自动回复密语功能",
		["Reply Message"] = "回复内容",
		["Set the message to reply with (supports {item1}~{item5})"] = "设置自动回复的内容（支持{item1}~{item5}物品链接）",
		["Reply in Combat"] = "战斗中回复",
		["Allow replying while in combat"] = "允许在战斗中自动回复密语",
	}
end)

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_AutoShout = Automaton:NewModule("AutoShout")
Automaton_AutoShout.modulename = L["AutoShout"]
Automaton_AutoShout.moduledesc = L["Automatically send messages to specified channel at intervals"]
Automaton_AutoShout.options = {
	shoutEnabled = {
		type = "toggle",
		name = L["Enable AutoShout"],
		desc = L["Turn on/off automatic shouting"],
		order = 1,
		get = function()
			return Automaton_AutoShout.db.profile.shoutEnabled
		end,
		set = function(v)
			Automaton_AutoShout.db.profile.shoutEnabled = v
			if v then
				Automaton_AutoShout:StartTimer()
			else
				Automaton_AutoShout:StopTimer()
			end
		end,
	},
	message = {
		type = "text",
		name = L["Message"],
		desc = L["Set the message to be sent"],
		order = 2,
		get = function()
			return Automaton_AutoShout.db.profile.messages[playerName]
				or Automaton_AutoShout.db.profile.messages.default
		end,
		set = function(v)
			Automaton_AutoShout.db.profile.messages[playerName] = v
			Automaton_AutoShout:print("已设置喊话内容: " .. v, "自动喊话")
		end,
	},
	interval = {
		type = "range",
		name = L["Interval"],
		desc = L["Set the interval between messages (in seconds)"],
		order = 3,
		min = 60,
		max = 300,
		step = 5,
		get = function()
			return Automaton_AutoShout.db.profile.intervals[playerName]
				or Automaton_AutoShout.db.profile.intervals.default
		end,
		set = function(v)
			Automaton_AutoShout.db.profile.intervals[playerName] = v
			Automaton_AutoShout:RestartTimer()
		end,
	},
	channel = {
		type = "text",
		name = L["Channel"],
		desc = L["Select the channel to send messages"],
		order = 4,
		get = function()
			return Automaton_AutoShout.db.profile.channel
		end,
		set = function(v)
			Automaton_AutoShout.db.profile.channel = v
		end,
		validate = {
			["yell"] = L["Yell"],
			["say"] = L["Say"],
			["party"] = L["Party"],
			["guild"] = L["Guild"],
			["world"] = L["World"],
			["Hardcore"] = L["Hardcore"],
		},
	},
	inCombat = {
		type = "toggle",
		name = L["In Combat"],
		desc = L["Allow shouting while in combat"],
		order = 5,
		get = function()
			return Automaton_AutoShout.db.profile.inCombat
		end,
		set = function(v)
			Automaton_AutoShout.db.profile.inCombat = v
		end,
	},
	items = {
		type = "group",
		name = L["Item List"],
		desc = L["Configure up to 5 items to include in messages"],
		order = 6,
		args = {},
	},
	autoReply = {
		type = "group",
		name = L["AutoReply"],
		desc = L["Settings for automatic whisper reply"],
		order = 7,
		args = {
			enabled = {
				type = "toggle",
				name = L["Enable AutoReply"],
				desc = L["Turn on/off automatic whisper reply"],
				order = 1,
				get = function()
					return Automaton_AutoShout.db.profile.autoReplyEnabled
				end,
				set = function(v)
					Automaton_AutoShout.db.profile.autoReplyEnabled = v
				end,
			},
			message = {
				type = "text",
				name = L["Reply Message"],
				desc = L["Set the message to reply with (supports {item1}~{item5})"],
				order = 2,
				get = function()
					return Automaton_AutoShout.db.profile.autoReplyMessages[playerName]
						or Automaton_AutoShout.db.profile.autoReplyMessages.default
				end,
				set = function(v)
					Automaton_AutoShout.db.profile.autoReplyMessages[playerName] = v
					Automaton_AutoShout:print("已设置自动回复内容: " .. v, "自动回复")
				end,
			},
			inCombat = {
				type = "toggle",
				name = L["Reply in Combat"],
				desc = L["Allow replying while in combat"],
				order = 3,
				get = function()
					return Automaton_AutoShout.db.profile.autoReplyInCombat
				end,
				set = function(v)
					Automaton_AutoShout.db.profile.autoReplyInCombat = v
				end,
			},
		},
	},
}

-- 动态生成5个物品的配置项
for i = 1, 5 do
	Automaton_AutoShout.options.items.args["item" .. i] = {
		type = "group",
		name = "物品" .. i,
		inline = true,
		args = {
			["container" .. i] = {
				type = "range",
				name = L["Container ID"],
				desc = L["Set the container ID where the item is located (backpack is usually 0)"],
				min = 0,
				max = 10,
				step = 1,
				get = (function(index)
					return function()
						return Automaton_AutoShout.db.profile.items[index].container
					end
				end)(i),
				set = (function(index)
					return function(v)
						Automaton_AutoShout.db.profile.items[index].container = v
					end
				end)(i),
			},
			["slot" .. i] = {
				type = "range",
				name = L["Item Slot"],
				desc = L["Set the slot number of the item (starts from 1)"],
				min = 1,
				max = 36,
				step = 1,
				get = (function(index)
					return function()
						return Automaton_AutoShout.db.profile.items[index].slot
					end
				end)(i),
				set = (function(index)
					return function(v)
						Automaton_AutoShout.db.profile.items[index].slot = v
					end
				end)(i),
			},
		},
	}
end

------------------------------
--      Initialization      --
------------------------------

function Automaton_AutoShout:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("AutoShout")
	Automaton:RegisterDefaults("AutoShout", "profile", {
		shoutEnabled = false, -- 自动喊话默认关闭
		messages = {
			default = "{item1}自动喊话测试，乌龟服真好玩",
		},
		intervals = {
			default = 60,
		},
		channel = "yell",
		inCombat = false,
		items = {
			{ container = 0, slot = 1 },
			{ container = 0, slot = 2 },
			{ container = 0, slot = 3 },
			{ container = 0, slot = 4 },
			{ container = 0, slot = 5 },
		},
		autoReplyEnabled = false,
		autoReplyInCombat = false,
		autoReplyMessages = {
			default = "我正在忙，稍后回复你。",
		},
	})

	-- 设置模块总开关默认禁用（由 Automaton 框架管理）
	Automaton:SetDisabledAsDefault(self, "AutoShout")

	-- 兼容旧配置：如果存在旧的 disabled 配置，可忽略（已移除）

	-- 初始化当前角色的配置
	if not self.db.profile.messages[playerName] then
		self.db.profile.messages[playerName] = self.db.profile.messages.default
	end
	if not self.db.profile.intervals[playerName] then
		self.db.profile.intervals[playerName] = self.db.profile.intervals.default
	end
	if not self.db.profile.autoReplyMessages[playerName] then
		self.db.profile.autoReplyMessages[playerName] = self.db.profile.autoReplyMessages.default
	end

	self:RegisterOptions(self.options)
end

function Automaton_AutoShout:OnEnable()
	-- 模块总开关已打开，注册必要事件
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("CHAT_MSG_WHISPER") -- 始终注册密语事件，内部由 autoReplyEnabled 控制

	-- 根据 shoutEnabled 启动喊话定时器
	if self.db.profile.shoutEnabled then
		self:StartTimer()
	end
end

function Automaton_AutoShout:OnDisable()
	self:UnregisterAllEvents()
	self:StopTimer()
end

------------------------------
--      Timer Functions      --
------------------------------

function Automaton_AutoShout:StartTimer()
	if not timer and self.db.profile.shoutEnabled then
		local interval = self.db.profile.intervals[playerName] or self.db.profile.intervals.default
		timer = self:ScheduleRepeatingEvent(self.DoShout, interval, self)
	end
end

function Automaton_AutoShout:StopTimer()
	if timer then
		self:CancelScheduledEvent(timer)
		timer = nil
	end
end

function Automaton_AutoShout:RestartTimer()
	self:StopTimer()
	self:StartTimer()
end

------------------------------
--      Event Handlers      --
------------------------------

function Automaton_AutoShout:PLAYER_REGEN_ENABLED()
	if self.db.profile.shoutEnabled then
		self:StartTimer()
	end
end

function Automaton_AutoShout:PLAYER_REGEN_DISABLED()
	if not self.db.profile.inCombat then
		self:StopTimer()
	end
end

function Automaton_AutoShout:CHAT_MSG_WHISPER(message, sender)
	-- 自动回复独立开关检查
	if not self.db.profile.autoReplyEnabled then
		return
	end

	-- 战斗中是否回复
	if UnitAffectingCombat("player") and not self.db.profile.autoReplyInCombat then
		return
	end

	local replyMsg = self.db.profile.autoReplyMessages[playerName] or self.db.profile.autoReplyMessages.default
	if not replyMsg or replyMsg == "" then
		return
	end

	-- 替换物品占位符
	for i = 1, 5 do
		local item = self.db.profile.items[i]
		local itemLink = GetContainerItemLink(item.container, item.slot)
		if itemLink then
			replyMsg = string.gsub(replyMsg, "{item" .. i .. "}", itemLink)
		else
			replyMsg = string.gsub(replyMsg, "{item" .. i .. "}", "[物品" .. i .. "缺失]")
		end
	end

	SendChatMessage(replyMsg, "WHISPER", nil, sender)
end

------------------------------
--      Channel Handling     --
------------------------------

local function GetWorldChannelID()
	for i = 1, 10 do
		local id, name = GetChannelName(i)
		if name then
			local nameLower = string.lower(name)
			-- 1. 精确匹配 "世界" / "world" / "世界频道"
			if nameLower == "世界" or nameLower == "world" or nameLower == "世界频道" then
				return id
			end
			-- 2. 前缀匹配（以"世界"或"world"开头），但排除防务频道
			if string.find(nameLower, "^世界") or string.find(nameLower, "^world") then
				if not (string.find(nameLower, "防务") or string.find(nameLower, "defense")) then
					return id
				end
			end
		end
	end
	return nil
end

------------------------------
--      Core Function       --
------------------------------

function Automaton_AutoShout:DoShout()
	local message = self.db.profile.messages[playerName] or self.db.profile.messages.default
	if not message or message == "" then
		return
	end

	if UnitAffectingCombat("player") and not self.db.profile.inCombat then
		return
	end

	for i = 1, 5 do
		local item = self.db.profile.items[i]
		local itemLink = GetContainerItemLink(item.container, item.slot)
		if itemLink then
			message = string.gsub(message, "{item" .. i .. "}", itemLink)
		else
			message = string.gsub(message, "{item" .. i .. "}", "[物品" .. i .. "缺失]")
		end
	end

	local channel = self.db.profile.channel
	if channel == "yell" then
		SendChatMessage(message, "YELL")
	elseif channel == "say" then
		SendChatMessage(message, "SAY")
	elseif channel == "party" then
		SendChatMessage(message, "PARTY")
	elseif channel == "guild" then
		SendChatMessage(message, "GUILD")
	elseif channel == "Hardcore" then
		SendChatMessage(message, "Hardcore")
	elseif channel == "world" then
		local worldChannelID = GetWorldChannelID()
		if worldChannelID then
			SendChatMessage(message, "CHANNEL", nil, worldChannelID)
		else
			self:print("无法找到世界频道，请手动加入后重试", "自动喊话")
		end
	end
end
