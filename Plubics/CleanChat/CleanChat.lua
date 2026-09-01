local PURGE_INTERVAL = 60 * 5 -- every 5 minutes remove names which are timed out.
local nextPurgeCheck = GetTime() + PURGE_INTERVAL
--local Gratuity = AceLibrary("Gratuity-2.0")
local loc = GetLocale()
local whoTimestamp = 0
local HC_LEVEL_RANGE = 5
local HCFSpam = ""
local strsub = string.sub
local RANDOM_ROLL_RESULT = "(.+)掷出(%d+)（(%d+)%-(%d+)）"
local EVENTS_EMOTES = {
	["CHAT_MSG_BG_SYSTEM_ALLIANCE"] = true,
	["CHAT_MSG_BG_SYSTEM_HORDE"] = true,
	["CHAT_MSG_BG_SYSTEM_NEUTRAL"] = true,
	["CHAT_MSG_EMOTE"] = true,
	["CHAT_MSG_TEXT_EMOTE"] = true,
	["CHAT_MSG_MONSTER_EMOTE"] = true,
	["CHAT_MSG_MONSTER_SAY"] = true,
	["CHAT_MSG_MONSTER_WHISPER"] = true,
	["CHAT_MSG_MONSTER_YELL"] = true,
	["CHAT_MSG_RAID_BOSS_EMOTE"] = true,
}
local CHANNELE_MSG_EVENT = {
	CHAT_MSG_CHANNEL = true,
	CHAT_MSG_YELL = true,
	CHAT_MSG_SAY = true,
	CHAT_MSG_GUILD = true,
	--CHAT_MSG_HARDCORE = true,
	CHAT_MSG_WHISPER = true,
	CHAT_MSG_HARDCORE = true,
	CHAT_MSG_LOOT = true, -- 添加战利品消息
	CHAT_MSG_PARTY = true, -- 队伍频道（供频道选择使用）
	CHAT_MSG_PARTY_LEADER = true, -- 队长说话（并入队伍频道）
}
-- local FACTION_COLOR = {
--   ["BL"] = fontRed,
--   ["LM"] = fontBlue,
-- }

-- ========== 修正1：变量名拼写错误 fiter → filter ==========
local filter = {
	"Delete your WDB",
	"If you want to",
	"Discord server",
	"All gold transactions are heavily",
	"Tune in to Everlook",
	"We encourage everyone to change",
	"Welcome to Turtle WoW! ",
	"/join world to connect with the community around you!",
}

-- 默认颜色定义
local DEFAULT_COLORS = {
	highlight = { 0.2, 1.0, 0.8 }, -- 对应33ffcc
	hardcore = { 0.9, 0.8, 0.5 }, -- 对应e6cd80
	roll = { 0.0, 1.0, 1.0 }, -- 对应00FFFF
}

-----------------------------------------------------------------------
---                   公调函数
-----------------------------------------------------------------------
local function firstToUpper(str)
	return (gsub(str, "^%l", string.upper))
end

-- 辅助函数：将RGB值转换为十六进制颜色字符串
local function RGBToHex(rgb)
	local r = math.floor(rgb[1] * 255 + 0.5)
	local g = math.floor(rgb[2] * 255 + 0.5)
	local b = math.floor(rgb[3] * 255 + 0.5)
	return string.format("%02x%02x%02x", r, g, b)
end

-- 防重复弹窗机制
local lastPopupTime = 0
local lastPopupMessage = ""
local POPUP_COOLDOWN = 0.5 -- 0.5秒的冷却时间，防止重复弹窗
local SERVER_RESTART_COOLDOWN = 10 -- 服务器重启弹窗冷却（秒），避免倒计时每秒刷屏
local lastServerRestartPopup = 0

local function ShouldShowPopup(message)
	local currentTime = GetTime()
	if message == lastPopupMessage and (currentTime - lastPopupTime) < POPUP_COOLDOWN then
		return false
	end
	lastPopupTime = currentTime
	lastPopupMessage = message
	return true
end

-- 频道识别：把聊天事件映射为与"自动喊话"一致的频道 key（服务器基本就这几个频道）
-- channelName 取全局 arg9（1.12 里 CHAT_MSG_CHANNEL 的 arg9 是不带编号的频道名，如 "世界"/"World"）
local function CleanChat_GetChannelKey(event, channelName)
	if event == "CHAT_MSG_YELL" then
		return "yell"
	end
	if event == "CHAT_MSG_SAY" then
		return "say"
	end
	if event == "CHAT_MSG_PARTY" or event == "CHAT_MSG_PARTY_LEADER" then
		return "party"
	end
	if event == "CHAT_MSG_GUILD" then
		return "guild"
	end
	if event == "CHAT_MSG_HARDCORE" then
		return "Hardcore"
	end
	if event == "CHAT_MSG_CHANNEL" then
		local name = channelName or ""
		local nameLower = string.lower(name)
		-- 世界频道：精确匹配或前缀匹配（排除防务频道）
		if nameLower == "世界" or nameLower == "world" or nameLower == "世界频道" then
			return "world"
		end
		if string.find(nameLower, "^世界") or string.find(nameLower, "^world") then
			if not (string.find(nameLower, "防务") or string.find(nameLower, "defense")) then
				return "world"
			end
		end
		return "channel" -- 其它自定义频道（交易/综合/组队频道等）
	end
	return nil
end

local Automaton_CleanChat = Automaton:NewModule("CleanChat")
Automaton_CleanChat.modulename = "聊天增强"
Automaton_CleanChat.moduledesc = "聊天增强，包含很多实用的功能，可以单独开启关闭。"
Automaton_CleanChat.options = {
	-- ===== 硬核频道 =====
	header_hc = {
		type = "header",
		name = "硬核频道",
		order = 10,
	},
	HCFFrame = {
		type = "text",
		name = "设置HC显示窗口",
		desc = "指定HC频道消息显示在第一个聊天窗口1-9",
		order = 11,
		get = function()
			return Automaton_CleanChat.db.profile.HCFFrame
		end,
		set = function(v)
			Automaton_CleanChat.db.profile.HCFFrame = tonumber(v)
		end,
	},
	onoff = {
		type = "toggle",
		name = "关闭HC频道消息",
		desc = "关闭HC频道消息，不再显示",
		order = 12,
		get = function()
			return Automaton_CleanChat.db.profile.onoff
		end,
		set = function(v)
			Automaton_CleanChat.db.profile.onoff = v
		end,
	},
	hcDeathPopup = {
		type = "toggle",
		name = "硬核死亡弹窗",
		desc = "当有硬核玩家死亡时在屏幕中央弹窗显示",
		order = 13,
		get = function()
			return Automaton_CleanChat.db.profile.hcDeathPopup
		end,
		set = function(v)
			Automaton_CleanChat.db.profile.hcDeathPopup = v
		end,
	},
	hcColour = {
		type = "color",
		name = "硬核频道颜色",
		desc = "设置硬核频道消息的颜色",
		order = 14,
		hasAlpha = false,
		get = function()
			return unpack(Automaton_CleanChat.db.profile.hcColour)
		end,
		set = function(r, g, b, a)
			Automaton_CleanChat.db.profile.hcColour = { r, g, b }
			Automaton_CleanChat:Print("硬核频道颜色已更新")
		end,
	},

	-- ===== 弹窗提醒 =====
	header_popup = {
		type = "header",
		name = "弹窗提醒",
		order = 20,
	},
	tradePopup = {
		type = "toggle",
		name = "交易消息弹窗提醒",
		desc = "当有玩家交易物品时，在屏幕中央弹窗高亮显示",
		order = 21,
		get = function()
			return Automaton_CleanChat.db.profile.tradePopup
		end,
		set = function(v)
			Automaton_CleanChat.db.profile.tradePopup = v
		end,
	},
	CleanChat_Popup = {
		type = "toggle",
		name = "弹窗显示有自己名字的聊天",
		desc = "当聊天中包含自己的名字时屏幕中间弹窗显示",
		order = 22,
		get = function()
			return Automaton_CleanChat.db.profile.CleanChat_Popup
		end,
		set = function(v)
			Automaton_CleanChat.db.profile.CleanChat_Popup = v
		end,
	},
	showpopup = {
		type = "toggle",
		name = "关键字屏幕中央提醒",
		desc = "当出现关键字时在屏幕中央显示整句聊天内容",
		order = 23,
		get = function()
			return Automaton_CleanChat.db.profile.showpopup
		end,
		set = function(v)
			Automaton_CleanChat.db.profile.showpopup = v
		end,
	},
	keywordChannel = {
		type = "text",
		name = "关键字监听频道",
		desc = '选择关键字高亮和弹窗提醒监听的频道，选"全部频道"则监听所有频道',
		order = 24,
		get = function()
			return Automaton_CleanChat.db.profile.keywordChannel
		end,
		set = function(v)
			Automaton_CleanChat.db.profile.keywordChannel = v
		end,
		validate = {
			["all"] = "全部频道",
			["yell"] = "喊话频道",
			["say"] = "说",
			["party"] = "队伍",
			["guild"] = "公会",
			["world"] = "世界频道",
			["Hardcore"] = "硬核",
		},
	},

	-- ===== 关键字管理 =====
	header_keyword = {
		type = "header",
		name = "关键字管理",
		order = 30,
	},
	highlightColour = {
		type = "color",
		name = "高亮关键字颜色",
		desc = "设置高亮关键字的颜色",
		order = 31,
		hasAlpha = false,
		get = function()
			return unpack(Automaton_CleanChat.db.profile.highlightColour)
		end,
		set = function(r, g, b, a)
			Automaton_CleanChat.db.profile.highlightColour = { r, g, b }
			Automaton_CleanChat:Print("高亮颜色已更新")
		end,
	},
	HighlightText = {
		type = "group",
		name = "高亮关键字",
		desc = "聊天内容会高亮显示的关键字",
		order = 32,
		args = {
			list = {
				type = "execute",
				name = "打印关键字列表",
				desc = "打印输出所有已经保持的关键字列表",
				order = 1,
				func = function()
					Automaton_CleanChat:ListKeyworld(Automaton_CleanChat.db.profile.THighlightText)
				end,
			},
			add = {
				type = "text",
				name = "添加关键字（按回车确认）",
				desc = "添加指定关键字，一次添加一个关键字，可以说是一个字也可以是词语，按回车确认输入",
				order = 2,
				usage = "<一次一个关键字>",
				get = false,
				set = function(v)
					Automaton_CleanChat:AddKeyword(Automaton_CleanChat.db.profile.THighlightText, v)
				end,
			},
			remove = {
				type = "text",
				name = "删除关键字（按回车确认）",
				desc = "删除指定关键字...",
				order = 3,
				usage = "<一次一个关键字>",
				get = false,
				set = function(v)
					Automaton_CleanChat:RemoveKeyword(Automaton_CleanChat.db.profile.THighlightText, v)
				end,
			},
			purge = {
				type = "execute",
				name = "清除全部关键字",
				desc = "清除全部关键字，清空关键字列表。",
				order = 4,
				func = function()
					Automaton_CleanChat:PurgeTHighlightText()
				end,
			},
		},
	},
	FilterKeyworld = {
		type = "group",
		name = "屏蔽关键字",
		desc = "屏蔽聊天内容的关键字",
		order = 33,
		args = {
			hasunitname = {
				type = "toggle",
				name = "关键字对角色名有效",
				desc = "屏蔽聊天内容的关键字是对包含关键字的角色名生效",
				order = 1,
				get = function()
					return Automaton_CleanChat.db.profile.hasunitname
				end,
				set = function(v)
					Automaton_CleanChat.db.profile.hasunitname = v
				end,
			},
			list = {
				type = "execute",
				name = "打印关键字列表",
				desc = "打印输出所有已经保持的关键字列表",
				order = 2,
				func = function()
					Automaton_CleanChat:ListKeyworld(Automaton_CleanChat.db.profile.TFilterKeyworld)
				end,
			},
			add = {
				type = "text",
				name = "添加关键字（按回车确认）",
				desc = "添加指定关键字，一次添加一个关键字，可以说是一个字也可以是词语，按回车确认输入",
				order = 3,
				usage = "<一次一个关键字>",
				get = false,
				set = function(v)
					Automaton_CleanChat:AddKeyword(Automaton_CleanChat.db.profile.TFilterKeyworld, v)
				end,
			},
			remove = {
				type = "text",
				name = "删除关键字（按回车确认）",
				desc = "删除指定关键字，一次添加一个关键字，按回车确认输入（必须于输入时相同）",
				order = 4,
				usage = "<一次一个关键字>",
				get = false,
				set = function(v)
					Automaton_CleanChat:RemoveKeyword(Automaton_CleanChat.db.profile.TFilterKeyworld, v)
				end,
			},
			purge = {
				type = "execute",
				name = "清除全部关键字",
				desc = "清除全部关键字，清空关键字列表。",
				order = 5,
				func = function()
					Automaton_CleanChat:PurgeTFilterKeyworld()
				end,
			},
		},
	},

	-- ===== ROLL点与组队 =====
	header_roll = {
		type = "header",
		name = "ROLL点与组队",
		order = 40,
	},
	highlightroll = {
		type = "toggle",
		name = "高亮自己的ROLL点信息",
		desc = "高亮显示自己的roll点信息，装绑自动ROLL点和自己手动ROLL点信息",
		order = 41,
		get = function()
			return Automaton_CleanChat.db.profile.highlightroll
		end,
		set = function(v)
			Automaton_CleanChat.db.profile.highlightroll = v
		end,
	},
	rollColour = {
		type = "color",
		name = "ROLL点高亮颜色",
		desc = "设置自己ROLL点信息的高亮颜色",
		order = 42,
		hasAlpha = false,
		get = function()
			return unpack(Automaton_CleanChat.db.profile.rollColour)
		end,
		set = function(r, g, b, a)
			Automaton_CleanChat.db.profile.rollColour = { r, g, b }
			Automaton_CleanChat:Print("ROLL点颜色已更新")
		end,
	},
	clickinvite = {
		type = "toggle",
		name = "关键字组队链接",
		desc = "聊天中包含INV,组我等关键字时生成组队链接",
		order = 43,
		get = function()
			return Automaton_CleanChat.db.profile.clickinvite
		end,
		set = function(v)
			Automaton_CleanChat.db.profile.clickinvite = v
		end,
	},

	-- ===== 战利品庆祝 =====
	header_loot = {
		type = "header",
		name = "战利品庆祝",
		order = 50,
	},
	lootCelebration = {
		type = "toggle",
		name = "战利品庆祝",
		desc = "获得特定物品时自动庆祝",
		order = 51,
		get = function()
			return Automaton_CleanChat.db.profile.lootCelebration
		end,
		set = function(v)
			Automaton_CleanChat.db.profile.lootCelebration = v
		end,
	},
	lootCelebrationItems = {
		type = "group",
		name = "庆祝物品列表",
		desc = "设置获得哪些物品时庆祝",
		order = 52,
		args = {
			addItem = {
				type = "text",
				name = "添加庆祝物品",
				desc = "输入物品名称（按回车确认）",
				order = 1,
				usage = "<物品名称>",
				get = false,
				set = function(v)
					Automaton_CleanChat:AddLootCelebrationItem(v)
				end,
			},
			removeItem = {
				type = "text",
				name = "删除庆祝物品",
				desc = "删除物品名称（按回车确认）",
				order = 2,
				usage = "<物品名称>",
				get = false,
				set = function(v)
					Automaton_CleanChat:RemoveLootCelebrationItem(v)
				end,
			},
			listItems = {
				type = "execute",
				name = "列出所有庆祝物品",
				desc = "显示当前设置的庆祝物品列表",
				order = 3,
				func = function()
					Automaton_CleanChat:ListLootCelebrationItems()
				end,
			},
			resetItems = {
				type = "execute",
				name = "重置为默认列表",
				desc = "重置庆祝物品列表为默认值",
				order = 4,
				func = function()
					Automaton_CleanChat.db.profile.lootCelebrationItems = {
						"正义宝珠",
						"骨火",
						"黑莲花",
						"奥术水晶",
						"恶魔布",
						"提布的炽炎长剑",
						"克罗之刃",
						"失落遗骸",
					}
					Automaton_CleanChat:Print("庆祝物品列表已重置为默认值")
				end,
			},
		},
	},

	-- ===== 外观设置 =====
	header_appearance = {
		type = "header",
		name = "外观设置",
		order = 60,
	},
	chatFontHeights = {
		type = "text",
		name = "聊天字号范围",
		desc = "设置可用字号列表，用英文逗号分隔，例如：10,12,14,16,18,20,22,24",
		order = 61,
		get = function()
			return Automaton_CleanChat.db.profile.chatFontHeightsString
		end,
		set = function(v)
			Automaton_CleanChat.db.profile.chatFontHeightsString = v
			Automaton_CleanChat:ApplyChatFontHeights(v)
			Automaton_CleanChat:Print("聊天字号范围已更新: " .. v)
		end,
	},
	resetColors = {
		type = "execute",
		name = "重置颜色",
		desc = "将所有颜色重置为默认值",
		order = 62,
		func = function()
			Automaton_CleanChat.db.profile.highlightColour = { unpack(DEFAULT_COLORS.highlight) }
			Automaton_CleanChat.db.profile.hcColour = { unpack(DEFAULT_COLORS.hardcore) }
			Automaton_CleanChat.db.profile.rollColour = { unpack(DEFAULT_COLORS.roll) }
			Automaton_CleanChat:Print("所有颜色已重置为默认值")
		end,
	},
}

------------------------------
--      Initialization      --
------------------------------

local playerName = UnitName("player")
function Automaton_CleanChat:OnInitialize()
	--AceLibrary("AceHook-2.1"):embed(Automaton_CleanChat)
	self.db = Automaton:AcquireDBNamespace("CleanChat")
	Automaton:RegisterDefaults("CleanChat", "profile", {
		disabled = false,
		CleanChat_Popup = true,
		ShowChatTime = false,

		clickinvite = true,
		hasunitname = false,
		CopyChatTime = true,
		whispersound = false,
		HighlightText = true,
		FilterKeyworld = true,

		highlightroll = true,
		showpopup = true,
		hcDeathPopup = true, -- 添加硬核死亡弹窗开关，默认开启
		tradePopup = true, -- 交易消息弹窗开关，默认开启
		keywordChannel = "all", -- 关键字高亮/弹窗监听的频道，默认全部
		THighlightText = {},
		TFilterKeyworld = {},

		onoff = false,
		HCFFrame = 1,
		--HCFLevelFilter = true,

		-- 战利品庆祝功能
		lootCelebration = true,
		lootCelebrationItems = {
			"正义宝珠",
			"骨火",
			"黑莲花",
			"奥术水晶",
			"恶魔布",
			"提布的炽炎长剑",
			"瑞文戴尔之剑",
			"克罗之刃",
		},

		-- 添加颜色配置
		highlightColour = { unpack(DEFAULT_COLORS.highlight) },
		hcColour = { unpack(DEFAULT_COLORS.hardcore) },
		rollColour = { unpack(DEFAULT_COLORS.roll) },
		-- 新增：聊天字号范围默认值
		chatFontHeightsString = "10,12,14,16,18,20,22,24",
	})
	Automaton:SetDisabledAsDefault(self, "CleanChat")
	self:RegisterOptions(self.options)
	self:HideButtons() --隐藏无用按钮
	self:SetupPrefix() --频道缩写
	self:SetupMouseWheel() --初始化鼠标滚轮
	-- 应用字号范围设置
	self:ApplyChatFontHeights()
	--移除无效缓存
	--self:CacheRemoveOlderEntries();
	--self._AddMessage = ChatFrame1.AddMessage
end

function Automaton_CleanChat:OnEnable()
	self:Hook("ChatFrame_OnEvent")
	self:RegisterEvent("VARIABLES_LOADED", "OnEvent") -- 监听变量加载事件，确保小退后重新应用
	self:ApplyChatFontHeights() -- 再次应用，确保生效
end

function Automaton_CleanChat:OnDisable()
	self:UnhookAll()
	self:UnregisterAllEvents()
end

-- 新增：事件处理
function Automaton_CleanChat:OnEvent(event, ...)
	if event == "VARIABLES_LOADED" then
		self:ApplyChatFontHeights()
	end
end

function Automaton_CleanChat:ListKeyworld(t)
	if table.getn(t) == 0 then
		self:Print("关键字列表为空")
	else
		self:Print("关键字为:")
		for k, v in pairs(t) do
			self:Print(v)
		end
	end
end

-- ========== 修改1：AddKeyword 过滤空字符串 ==========
function Automaton_CleanChat:AddKeyword(t, v)
	if not v then
		return
	end
	v = gsub(v, "^%s*(.-)%s*$", "%1") -- 去除首尾空格
	if v ~= "" then
		tinsert(t, v)
	end
end

-- ========== 修改2：RemoveKeyword 使用 table.remove 保持紧凑 ==========
function Automaton_CleanChat:RemoveKeyword(t, item)
	if not item or item == "" then
		return
	end
	for i = table.getn(t), 1, -1 do
		if t[i] == item then
			table.remove(t, i)
		end
	end
end

function Automaton_CleanChat:PurgeTFilterKeyworld()
	self:Print("共清理关键字：" .. table.getn(Automaton_CleanChat.db.profile.TFilterKeyworld) .. " 个")
	Automaton_CleanChat.db.profile.TFilterKeyworld = {}
end

function Automaton_CleanChat:PurgeTHighlightText(t)
	self:Print("共清理关键字：" .. table.getn(Automaton_CleanChat.db.profile.THighlightText) .. " 个")
	Automaton_CleanChat.db.profile.THighlightText = {}
end

-- ===== 新增：应用聊天字号范围 =====
function Automaton_CleanChat:ApplyChatFontHeights(str)
	if not str then
		str = self.db.profile.chatFontHeightsString
	end
	local nums = {}
	for num in string.gmatch(str, "[^,]+") do
		local n = tonumber(num)
		if n then
			table.insert(nums, n)
		end
	end
	-- 使用 table.getn 替代 # 避免解析错误
	if table.getn(nums) > 0 then
		CHAT_FONT_HEIGHTS = nums
	else
		self:Print("无效的字号列表，请用英文逗号分隔数字")
	end
end

-- works only for numbers between 0-255;
local CLEANCHAT_HEX = { [0] = "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f" }

function Automaton_CleanChat:HideButtons()
	for i = 1, NUM_CHAT_WINDOWS do
		getglobal("ChatFrame" .. i .. "DownButton"):Hide()
		getglobal("ChatFrame" .. i .. "UpButton"):Hide()
		--getglobal("ChatFrame" .. i .. "BottomButton"):Show();
	end
end

--  keep channels between editbox use
for _, v in pairs({
	ChatTypeInfo.SAY,
	ChatTypeInfo.EMOTE,
	ChatTypeInfo.YELL,
	ChatTypeInfo.PARTY,
	ChatTypeInfo.GUILD,
	ChatTypeInfo.OFFICER,
	ChatTypeInfo.RAID,
	ChatTypeInfo.RAID_WARNING,
	ChatTypeInfo.BATTLEGROUND,
	ChatTypeInfo.WHISPER,
	ChatTypeInfo.CHANNEL,
}) do
	v.sticky = 1
end
local function CleanChat_UnlinkMessage(linkmessage)
	local message = linkmessage
	local links = { "quest:", "item:", "spell:" }
	for _, v in pairs(links) do
		if strfind(message, "|H" .. v) ~= nil then
			for pat1, pat2, pat3 in string.gfind(message, "(.+)|H.+|h(.+)|h(.+)") do
				if pat1 and pat2 and pat3 then
					message = pat1 .. pat2 .. pat3
				end
			end
		end
	end
	return gsub(gsub(message, "/", "/1"), "|", "/2")
end

-- generate color string from current Blizzard raid colors
local function CleanChat_HashString(name)
	local hash = 17
	for i = 1, string.len(name) do
		hash = hash * 37 * string.byte(name, i)
	end
	return hash
end

--添加函数，来自cleachat,随机颜色用的
local function CleanChat_ToHex(number)
	if number <= 0 then
		return "00"
	end
	if number >= 255 then
		return "ff"
	end
	if math.fmod then
		return CLEANCHAT_HEX[math.floor(number / 16)] .. CLEANCHAT_HEX[math.fmod(number, 16)]
	end
	return CLEANCHAT_HEX[math.floor(number / 16)] .. CLEANCHAT_HEX[math.mod(number, 16)]
end

function CleanChat_ChatAddTime(t, msg)
	if Automaton_CleanChat.db.profile.ShowChatTime then
		local time = date("%H:%M")
		local timestamp = time
		if Automaton_CleanChat.db.profile.CopyChatTime then
			timestamp = "|Hezc:" .. (CleanChat_UnlinkMessage(t)) .. "|h[" .. time .. "]|h"
			t = "|cffffc800" .. timestamp .. "|r " .. t
		else
			t = "|cffffc800[" .. timestamp .. "]|r " .. t
		end
	end
	return t
end

-----------------------------------------------------------------------
--                 HOOK FUNC
-----------------------------------------------------------------------

-- local HookChatFrame_OnHyperlinkShow = ChatFrame_OnHyperlinkShow
-- function ChatFrame_OnHyperlinkShow(link, text, button)
-- return HookChatFrame_OnHyperlinkShow(link, text, button);
-- end
local HookSetItemRef = SetItemRef
function SetItemRef(link, text, button)
	if string.sub(link, 1, 3) == "inv" then
		InviteByName(string.sub(link, 5))
	elseif string.sub(link, 1, 3) == "ezc" then
		EasyCopyText:SetText("")
		local txt = gsub(gsub(strsub(link, 5), "/2", "|"), "/1", "/")
		EasyCopyText:SetText(txt)
		EasyCopy:Show()
	else
		HookSetItemRef(link, text, button)
	end
end

--local HookChatFrame_OnEvent = ChatFrame_OnEvent
function Automaton_CleanChat:ChatFrame_OnEvent(event)
	--聊天关键字高亮shaguchat
	this.CleanChat_UnitName = arg2 ~= "" and arg2
	this.event = event

	-- 特殊事件处理（添加到这里）
	if event == "CHAT_MSG_SYSTEM" and arg1 then
		local msg = arg1

		-- 副本重置相关处理
		if (string.find(msg, "已被重置")) and (GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0) then
			SendChatMessage("副本可以进了！", "PARTY")
		end

		if (string.find(msg, "该副本中仍有玩家")) and (GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0) then
			SendChatMessage("正在重置副本，请尽快出本！", "PARTY")
		end

		-- 服务器重启倒计时弹窗（无需开关，10 秒内只弹一次避免刷屏）
		if string.find(msg, "即将重启动") or string.find(msg, "即将重启") then
			local now = GetTime()
			if (now - lastServerRestartPopup) >= SERVER_RESTART_COOLDOWN then
				lastServerRestartPopup = now
				-- 兼容 "剩余时间25 Second" / "剩余时间 25 Second" / "25 Second"
				local sec = string.match(msg, "剩余时间%s*(%d+)%s*[Ss]econds?")
				if not sec then
					sec = string.match(msg, "(%d+)%s*[Ss]econds?")
				end
				local display = sec and ("服务器即将重启：剩余 " .. sec .. " 秒") or "服务器即将重启"
				UIErrorsFrame:AddMessage(display, 1.0, 0.2, 0.2, 1.0, 5.0) -- 红色，持续 5 秒
				PlaySound("FriendJoinGame")
			end
		end
	end

	-- 处理战利品消息
	if event == "CHAT_MSG_LOOT" and arg1 then
		local msg = arg1
		self:ProcessLootMessage(msg)
		arg1 = self:ChatMsgLootRoll(arg1)
	end

	-- if arg1 and strfind(arg1,"你的.*被抵抗") then
	--   Print(arg1..event)
	-- end
	-- if arg9 == "YELL" and arg1 then
	-- Print(arg9..arg1) end
	if CHANNELE_MSG_EVENT[event] and arg2 and arg1 and not (arg9 and string.lower(arg9) == "lft") then
		if self:FilterKeyworld(arg1, arg2) then
			return
		end
		local selectedChannel = self.db.profile.keywordChannel or "all"
		if selectedChannel == "all" or CleanChat_GetChannelKey(event, arg9) == selectedChannel then
			arg1 = self:HighlightText(arg1)
		end
		arg1 = self:SpellLink(arg1)
		self:HighlightSelfText(arg1, arg2)
	end
	if event == "CHAT_MSG_SYSTEM" then
		arg1 = self:LFT(arg1)
		arg1 = self:AuxFilter(arg1)
		arg1 = self:ChatMsgSystemHCMsg(arg1)
		arg1 = self:ChatMsgSystemRoll(arg1) -- 确保这一行存在
		arg1 = self:CharacterDisplaying(arg1)
		-- 交易消息弹窗提醒（新增）
		self:PopupTradeMessage(arg1)
		if not arg1 then
			return
		end
	end
	if event == "CHAT_MSG_LOOT" then
		arg1 = self:ChatMsgLootRoll(arg1)
		--dprint(msg..this.event)
	end
	--
	-- Hook AddMessage
	if not this.CleanChat_AddMessage_Org then
		this.CleanChat_AddMessage_Org = this.AddMessage
		this.AddMessage = CleanChat_AddMessage
	end
	--Save event data
	--this.msg = arg1;

	---@type string|nil
	local strippedChannelName
	if event == "CHAT_MSG_HARDCORE" then
		strippedChannelName = "Hardcore"
		if HCFSpam == arg1 then --or FilterOut(arg1) then
			return false
		end

		-- 使用配置的硬核频道颜色
		local hcHex = RGBToHex(self.db.profile.hcColour)
		-- 正文里物品/任务链接、关键词高亮都自带 |r，会把后续文字重置回白色基础色；
		-- 在每个 |r 后补回硬核色 (参考 pfUI 对密语的处理 chat.lua:811)
		local body = string.gsub(arg1, "|r", "|r|cff" .. hcHex)
		local msg = "|cff" .. hcHex .. body .. "|r" -- 只对消息内容应用颜色
		local output = "|cff" .. hcHex .. "[核] |Hplayer:" .. arg2 .. "|h[" .. arg2 .. "]|h " .. msg

		if self.db.profile.onoff then
			arg1 = nil
			--HCFSpam = arg1
			return false
		end
		if self.db.profile.HCFFrame == 1 then
			ChatFrame1:AddMessage(output)
		elseif self.db.profile.HCFFrame == 2 then
			ChatFrame2:AddMessage(output)
		elseif self.db.profile.HCFFrame == 3 then
			ChatFrame3:AddMessage(output)
		elseif self.db.profile.HCFFrame == 4 then
			ChatFrame4:AddMessage(output)
		elseif self.db.profile.HCFFrame == 5 then
			ChatFrame5:AddMessage(output)
		elseif self.db.profile.HCFFrame == 6 then
			ChatFrame6:AddMessage(output)
		elseif self.db.profile.HCFFrame == 7 then
			ChatFrame7:AddMessage(output)
		elseif self.db.profile.HCFFrame == 8 then
			ChatFrame8:AddMessage(output)
		elseif self.db.profile.HCFFrame == 9 then
			ChatFrame9:AddMessage(output)
		end
		HCFSpam = arg1
		return false
	elseif arg9 and event ~= "CHAT_MSG_CHANNEL_NOTICE" then
		local _, _, mat = string.find(arg9, "([%aé]*)")
		strippedChannelName = --[[---@type string]]
			mat
	end

	if strippedChannelName ~= nil then
		if CLEANCHAT_CHANNELS[strippedChannelName] then
			this.CleanChat_Channelname = firstToUpper(strippedChannelName)
			this.CleanChatShort_Channelname = CLEANCHAT_CHANNELS[strippedChannelName]
		elseif arg9 and arg9 ~= "" then
			this.CleanChat_Channelname = arg9
		end
	end
	if event == "WHO_LIST_UPDATE" then
		whoTimestamp = GetTime()
	end
	-- Call original handler, if not a who response to our latest sendwho request
	if
		event
		and not (
			event == "CHAT_MSG_SYSTEM"
			and GetTime() - whoTimestamp < 3
			and (string.find(arg1, CLEANCHAT_CHATPATTERN1) or string.find(arg1, CLEANCHAT_WHO_RESULTS_PATTERN))
		)
	then
		--return self.hooks.ChatFrame_OnEvent(event);
	end
	if (event == "CHAT_MSG_WHISPER") and self.db.profile.whispersound then
		PlaySoundFile([[interface\Addons\Automatonex\Sound\3.mp3]])
	end
	self.hooks.ChatFrame_OnEvent(event)
end

function Automaton_CleanChat:CharacterDisplaying(t)
	for k, j in pairs(CLEANCAHT_CHAT_MSG_SYSTEM) do
		if string.find(t, k) then
			t = gsub(t, k, j)
			return t
		end
	end
	return t
end

function Automaton_CleanChat:SpellLink(t, num)
	if not num then
		num = 1
	end
	local _, last, spellstr, spellname = strfind(t or "", "|Hspell:([%d:]+)|h%[([%a%p%d]+)%]|hr", num)
	if spellstr and spellname and not IsCn(spellname) then
		local cnspellname = Localization_SpellNametocn(spellname)
		if cnspellname then
			t = gsub(t, spellname, cnspellname)
		end
		t = self:SpellLink(t, last)
	end
	return t
end

--- 高亮自己信息--20240623 end
function Automaton_CleanChat:HighlightSelfText(msg, unit)
	if
		Automaton_CleanChat.db.profile.CleanChat_Popup
		and unit
		and unit ~= ""
		and unit ~= playerName
		and not EVENTS_EMOTES[this.event]
		and (string.find(msg, playerName)) --not perfect atm
	then
		-- 使用UIErrorsFrame显示弹窗，与关键字弹窗保持一致
		-- 高亮消息中的玩家名字
		local hexColor = RGBToHex(self.db.profile.highlightColour)
		local highlightedMsg = string.gsub(msg, playerName, "|cff" .. hexColor .. playerName .. "|r")
		local displayMsg = "|cffff8800[提到我]|r |cffffdd00" .. unit .. "|r: " .. highlightedMsg

		-- 检查是否应该显示弹窗
		if ShouldShowPopup(displayMsg) then
			UIErrorsFrame:AddMessage(displayMsg, 1.0, 0.8, 0.0, 1.0, 5.0) -- 橙色，持续5秒
			PlaySound("FriendJoinGame")
		end
	end
end

function Automaton_CleanChat:LFT(t)
	-- 暂时不处理，直接返回原字符串
	return t
end

-- ========== 修改3：HighlightText 增加 nil 检查，跳过空关键字 ==========
function Automaton_CleanChat:HighlightText(msg)
	if
		self.db.profile.HighlightText
		and self.db.profile.THighlightText
		and table.getn(self.db.profile.THighlightText) > 0
	then
		-- 使用配置的高亮颜色
		local hexColor = RGBToHex(self.db.profile.highlightColour)
		local keywordColor = "|cff" .. hexColor
		local endColor = "|r"
		local foundKeyword = false
		local originalMsg = msg

		-- 提前将关键字列表转换为小写，同时过滤掉 nil 或空字符串
		local lowerKeywords = {}
		for i = 1, table.getn(self.db.profile.THighlightText) do
			local keyword = self.db.profile.THighlightText[i]
			if keyword and keyword ~= "" then
				lowerKeywords[table.getn(lowerKeywords) + 1] = string.lower(keyword)
			end
		end
		if table.getn(lowerKeywords) == 0 then
			return msg
		end -- 没有有效关键字则直接返回

		-- 提前将消息转换为小写
		local lowerMsg = string.lower(msg)

		local parts = {}
		local currentIndex = 1

		-- 遍历所有关键字
		for i = 1, table.getn(lowerKeywords) do
			local lowerScan = lowerKeywords[i]
			local startIndex, endIndex = string.find(lowerMsg, lowerScan, currentIndex)
			while startIndex do
				-- 标记找到了关键字
				foundKeyword = true

				-- 提取关键字之前的部分
				local before = string.sub(msg, currentIndex, startIndex - 1)
				-- 提取关键字部分
				local keyword = string.sub(msg, startIndex, endIndex)

				-- 添加关键字之前的部分和带颜色的关键字到 parts 表中
				parts[table.getn(parts) + 1] = before
				parts[table.getn(parts) + 1] = keywordColor .. keyword .. endColor

				-- 更新当前索引
				currentIndex = endIndex + 1

				-- 继续查找消息中是否还有其他匹配的关键字
				startIndex, endIndex = string.find(lowerMsg, lowerScan, currentIndex)
			end
		end

		-- 添加最后一部分消息
		parts[table.getn(parts) + 1] = string.sub(msg, currentIndex)

		-- 使用 table.concat 组合所有部分
		msg = table.concat(parts)

		-- 在找到关键字时显示屏幕提示
		if foundKeyword and self.db.profile.showpopup then
			-- 创建更明显的弹窗消息
			local speaker = arg2 or "未知"
			local highlightedMsg = originalMsg

			-- 高亮关键字（使用过滤后的列表）
			for i = 1, table.getn(lowerKeywords) do
				local lowerScan = lowerKeywords[i]
				local startPos, endPos = string.find(string.lower(highlightedMsg), lowerScan)
				while startPos do
					local keyword = string.sub(highlightedMsg, startPos, endPos)
					highlightedMsg = string.sub(highlightedMsg, 1, startPos - 1)
						.. keywordColor
						.. keyword
						.. "|r"
						.. string.sub(highlightedMsg, endPos + 1)

					-- 调整后续查找的起始位置，考虑添加的颜色代码长度
					local offset = string.len(keywordColor) + string.len("|r")
					startPos, endPos = string.find(string.lower(highlightedMsg), lowerScan, endPos + offset)
				end
			end

			-- 使用更显眼的格式显示在屏幕中央
			local fullMessage = "|cffff8800[关键字提醒]|r |cffffdd00" .. speaker .. "|r: " .. highlightedMsg

			-- 检查是否应该显示弹窗
			if ShouldShowPopup(fullMessage) then
				UIErrorsFrame:AddMessage(fullMessage, 1.0, 0.8, 0.0, 1.0, 5.0) -- 橙色，持续5秒

				-- 可选：添加音效提醒
				PlaySound("FriendJoinGame")
			end
		end
	end
	return msg
end

-- ========== 修改4：FilterKeyworld 增加 nil 检查 ==========
function Automaton_CleanChat:FilterKeyworld(msg, unit)
	-- 修改：自身发出的信息不受屏蔽关键字影响
	if unit == playerName then
		return false
	end

	if Automaton_CleanChat.db.profile.FilterKeyworld then
		local texts = msg
		if Automaton_CleanChat.db.profile.hasunitname then
			texts = unit .. msg
		end
		for _, text in pairs(Automaton_CleanChat.db.profile.TFilterKeyworld) do
			if text and text ~= "" and strfind(texts, text) then
				return true
			end
		end
	end
	return false
end

function Automaton_CleanChat:ChatMsgSystemRoll(t)
	-- 检查是否开启高亮ROLL点功能
	if not self.db.profile.highlightroll then
		return t
	end

	local who, roll, from, to = string.match(t, RANDOM_ROLL_RESULT)
	if who == playerName then
		-- 使用配置的ROLL点颜色
		local rollHex = RGBToHex(self.db.profile.rollColour)
		t = format("|CFF%s%s|r掷出|CFF%s%d|r（%d-%d）", rollHex, who, rollHex, roll, from, to)
	end
	return t
end

function Automaton_CleanChat:ChatMsgLootRoll(msg)
	local _, _, typ, roll, item, name = strfind(msg, "（(.+)）(%d+)点：(.+)（(.+)）")
	if name == playerName then
		-- 使用配置的ROLL点颜色
		local rollHex = RGBToHex(self.db.profile.rollColour)
		msg = format("（%s）|CFF%s%d|r点： %s （|CFF%s%s|r）", typ, rollHex, roll, item, rollHex, name)
	end
	return msg
end

-- 处理战利品消息
function Automaton_CleanChat:ProcessLootMessage(msg)
	-- 如果未开启战利品庆祝，直接返回
	if not self.db.profile.lootCelebration then
		return
	end

	-- 检查用户配置的物品列表
	if self.db.profile.lootCelebrationItems and table.getn(self.db.profile.lootCelebrationItems) > 0 then
		-- 从消息中提取实际拾取的物品名（物品链接 [名字] 中的完整名字）
		local lootedName = string.match(msg, "%[(.-)%]")

		-- 检查是否是自己拾取
		if string.find(msg, "你获得了物品：", 1, true) or string.find(msg, "你得到了物品：", 1, true) then
			if lootedName then
				for _, itemName in ipairs(self.db.profile.lootCelebrationItems) do
					-- 精确匹配：物品名完全相等才庆祝（避免"恶魔布"误命中"恶魔布披风"）
					if lootedName == itemName then
						DoEmote("CHEER")
						PlaySoundFile("Interface\\AddOns\\Automatonex\\Sound\\ding.ogg")
						break
					end
				end
			end
		end

		-- 处理队友拾取（可选）
		local playerNameFound, itemLink = string.match(msg, "(.+)拾取了物品：(.+)")
		if playerNameFound and itemLink and playerNameFound ~= UnitName("player") then
			local mateLootedName = string.match(itemLink, "%[(.-)%]") or itemLink
			for _, item in ipairs(self.db.profile.lootCelebrationItems) do
				if mateLootedName == item then
					DEFAULT_CHAT_FRAME:AddMessage(
						format(
							"|cffffcc00[恭喜]|r |cff00ffff%s|r 获得了稀有物品: |cff00ff00%s|r！",
							playerNameFound,
							item
						)
					)
					break
				end
			end
		end
	end
end

-- 添加庆祝物品管理函数
function Automaton_CleanChat:AddLootCelebrationItem(itemName)
	if not self.db.profile.lootCelebrationItems then
		self.db.profile.lootCelebrationItems = {}
	end

	-- 检查是否已存在
	for _, item in ipairs(self.db.profile.lootCelebrationItems) do
		if item == itemName then
			self:Print("物品已存在: " .. itemName)
			return
		end
	end

	table.insert(self.db.profile.lootCelebrationItems, itemName)
	self:Print("已添加庆祝物品: " .. itemName)
end

function Automaton_CleanChat:RemoveLootCelebrationItem(itemName)
	if not self.db.profile.lootCelebrationItems then
		return
	end

	for i, item in ipairs(self.db.profile.lootCelebrationItems) do
		if item == itemName then
			table.remove(self.db.profile.lootCelebrationItems, i)
			self:Print("已删除庆祝物品: " .. itemName)
			return
		end
	end

	self:Print("未找到物品: " .. itemName)
end

function Automaton_CleanChat:ListLootCelebrationItems()
	if not self.db.profile.lootCelebrationItems or table.getn(self.db.profile.lootCelebrationItems) == 0 then
		self:Print("庆祝物品列表为空")
		return
	end

	self:Print("庆祝物品列表:")
	for i, item in ipairs(self.db.profile.lootCelebrationItems) do
		self:Print(i .. ". " .. item)
	end

	-- 使用 table.getn() 替代 #
	self:Print("共 " .. table.getn(self.db.profile.lootCelebrationItems) .. " 个物品")
end

-- 交易消息弹窗高亮提醒（新增）
function Automaton_CleanChat:PopupTradeMessage(msg)
	if not self.db.profile.tradePopup then
		return
	end
	-- 匹配中文交易消息格式：玩家A 将 物品 交易给了 玩家B。
	local pattern = "(.+) 将 (.+) 交易给了 (.+)。"
	local playerA, item, playerB = string.match(msg, pattern)
	if playerA and item and playerB then
		-- 获取高亮颜色（十六进制）
		local hexColor = RGBToHex(self.db.profile.highlightColour)
		-- 构造带颜色的弹窗消息
		local popupMsg = string.format(
			"|cffff8800[交易提醒]|r |cff%s%s|r 将 |cff%s%s|r 交易给了 |cff%s%s|r",
			hexColor,
			playerA,
			hexColor,
			item,
			hexColor,
			playerB
		)
		-- 防重复弹窗（复用已有的ShouldShowPopup函数）
		if ShouldShowPopup(popupMsg) then
			UIErrorsFrame:AddMessage(popupMsg, 1.0, 0.5, 0.0, 1.0, 5.0) -- 橙色高亮，持续5秒
			PlaySound("FriendJoinGame") -- 播放提示音
		end
	end
end

function Automaton_CleanChat:ChatMsgSystemHCMsg(t)
	local originalMsg = t
	local isDeathMessage = false

	if strfind(t, "A tragedy has") then
		isDeathMessage = true
		if strfind(t, "has fallen to") then
			local _, _, playertype, pname, plv, tname, tlv, zone = strfind(t, CHAT_HC_MSG_P1_KEY)
			if playertype and pname and plv and tname and tlv and zone then
				-- 使用不同的颜色为玩家名字、怪物名字和地点染色
				local hcHex = RGBToHex(self.db.profile.hcColour) -- 硬核标签颜色
				local playerHex = "068fff" -- 玩家名字颜色（蓝色）
				local npcHex = "ff9900" -- 怪物名字颜色（橙色）
				local zoneHex = "00ff00" -- 地点颜色（绿色）

				t = format(
					CHAT_HC_MSG_P1_VAR,
					"|cfff86256" .. (CHAT_HC_MSG_DEATH_PLAYERTYPE[playertype] or playertype) .. "|r", -- 玩家类型
					"|cff" .. playerHex .. pname .. "|r", -- 玩家名字
					"|cff" .. zoneHex .. zone .. "|r", -- 地点
					"|cff" .. npcHex .. tlv .. "|r", -- 怪物等级
					"|cff"
						.. npcHex
						.. (Automaton and Automaton.NpcNametocn and Automaton.NpcNametocn(tname) or tname)
						.. "|r", -- 怪物名字
					"|cff" .. playerHex .. plv .. "|r"
				) -- 玩家等级
			end
		elseif strfind(t, "has fallen in PvP to") then
			local _, _, pname, plv, tname, tlv, zone = strfind(t, CHAT_HC_MSG_P3_KEY)
			if pname and plv and tname and tlv and zone then
				-- PvP死亡消息染色
				local hcHex = RGBToHex(self.db.profile.hcColour)
				local playerHex = "068fff" -- 玩家名字颜色
				local killerHex = "ff0000" -- 击杀者颜色（红色，因为是PvP）
				local zoneHex = "00ff00" -- 地点颜色

				t = format(
					CHAT_HC_MSG_P3_VAR,
					"|cff" .. playerHex .. pname .. "|r",
					"|cff" .. zoneHex .. zone .. "|r",
					"|cff" .. killerHex .. tlv .. "|r",
					"|cff"
						.. killerHex
						.. (Automaton and Automaton.NpcNametocn and Automaton.NpcNametocn(tname) or tname)
						.. "|r",
					"|cff" .. playerHex .. plv .. "|r"
				)
			end
		elseif strfind(t, CHAT_HC_MSG_P4_KEY) then
			-- 自然死亡（溺水、火烧等）
			local _, _, playertype, pname, plv, result, zone = strfind(t, CHAT_HC_MSG_P4_KEY)
			if playertype and pname and plv and result and zone then
				local hcHex = RGBToHex(self.db.profile.hcColour)
				local playerHex = "068fff"
				local zoneHex = "00ff00"
				local reasonHex = "ffcc00" -- 死亡原因颜色（黄色）

				t = format(
					CHAT_HC_MSG_P4_VAR,
					"|cfff86256" .. (CHAT_HC_MSG_DEATH_PLAYERTYPE[playertype] or playertype) .. "|r",
					"|cff" .. playerHex .. pname .. "|r",
					"|cff" .. zoneHex .. zone .. "|r",
					"|cff" .. reasonHex .. CHAT_HC_MSG_DEATH_REASOM[result] .. "|r",
					"|cff" .. playerHex .. plv .. "|r"
				)
			end
		end
	elseif strfind(t, "^悲剧发生了。") then
		isDeathMessage = true
		if strfind(t, CHAT_HC_MSG_P1_1_KEY) then
			local _, _, playertype, pname, plv, tname, tlv, zone = strfind(t, CHAT_HC_MSG_P1_1_KEY)
			if playertype and pname and plv and tname and tlv and zone then
				-- 中文版硬核死亡消息染色
				local hcHex = RGBToHex(self.db.profile.hcColour)
				local playerHex = "068fff"
				local npcHex = "ff9900"
				local zoneHex = "00ff00"

				t = format(
					CHAT_HC_MSG_P1_VAR,
					"|cfff86256" .. (CHAT_HC_MSG_DEATH_PLAYERTYPE[playertype] or playertype) .. "|r",
					"|cff" .. playerHex .. pname .. "|r",
					"|cff" .. zoneHex .. zone .. "|r",
					"|cff" .. npcHex .. tlv .. "|r",
					"|cff"
						.. npcHex
						.. (Automaton and Automaton.NpcNametocn and Automaton.NpcNametocn(tname) or tname)
						.. "|r",
					"|cff" .. playerHex .. plv .. "|r"
				)
			end
		end
		if strfind(t, CHAT_HC_MSG_P4_1_KEY) then
			local _, _, playertype, pname, plv, zone, result = strfind(t, CHAT_HC_MSG_P4_1_KEY)
			if playertype and pname and plv and result and zone then
				-- 中文版自然死亡消息染色
				local hcHex = RGBToHex(self.db.profile.hcColour)
				local playerHex = "068fff"
				local zoneHex = "00ff00"
				local reasonHex = "ffcc00"

				t = format(
					CHAT_HC_MSG_P4_VAR,
					"|cfff86256" .. (CHAT_HC_MSG_DEATH_PLAYERTYPE[playertype] or playertype) .. "|r",
					"|cff" .. playerHex .. pname .. "|r",
					"|cff" .. zoneHex .. zone .. "|r",
					"|cff" .. reasonHex .. CHAT_HC_MSG_DEATH_REASOM[result] .. "|r",
					"|cff" .. playerHex .. plv .. "|r"
				)
			end
		end
	end

	-- 如果是硬核死亡消息且开启了硬核死亡弹窗功能，则显示弹窗
	-- 使用已经染色后的消息（t），它包含了所有颜色标签
	if isDeathMessage and self.db.profile.hcDeathPopup then
		local popupMsg = t

		-- 检查是否应该显示弹窗
		if ShouldShowPopup(popupMsg) then
			UIErrorsFrame:AddMessage(popupMsg, 1.0, 1.0, 0.0, 1.0, 5.0) -- 黄色，持续5秒
			PlaySound("FriendJoinGame")
		end
	end

	return t
end

function Automaton_CleanChat:AuxFilter(t)
	local ahitem
	for _, str in pairs({ ERR_AUCTION_SOLD_S, ERR_AUCTION_EXPIRED_S, ERR_AUCTION_WON_S }) do
		ahitem = string.match(t, str)
		if ahitem then
			PlaySound("AuctionWindowOpen")
			return format(
				str,
				(
					Automaton
						and Automaton.ItemInfoLib
						and Automaton.ItemInfoLib.HexItemName
						and Automaton.ItemInfoLib:HexItemName(ahitem)
					or ahitem
				)
			)
		end
	end
	return t
end

local function CleanChat_ClickInvite(msg, trail)
	if
		(trail == nil or trail == " " or trail == "")
		and arg2 ~= UnitName("player")
		and this.event ~= "CHAT_MSG_RAID"
		and this.event ~= "CHAT_MSG_RAID_LEADER"
		and this.event ~= "CHAT_MSG_RAID_WARNING"
	then
		CleanChat_INVITEFOUND = true
		return " |Hinv:" .. arg2 .. "|h[|cffffff00" .. msg .. "|r]|h" .. " "
	else
		return " " .. msg .. trail
	end
end

function Automaton_CleanChat:OnMouseWheel()
	if IsShiftKeyDown() then
		if arg1 == 1 then
			this:ScrollToTop()
		else
			PlaySound("igChatBottom")
			this:ScrollToBottom()
		end
	else
		if arg1 == 1 then
			this:ScrollUp()
		else
			this:ScrollDown()
		end
	end
end

function Automaton_CleanChat:SetupMouseWheel()
	for i = 1, NUM_CHAT_WINDOWS do
		getglobal("ChatFrame" .. i):SetScript("OnMouseWheel", self.OnMouseWheel)
		getglobal("ChatFrame" .. i):EnableMouseWheel(true)
	end
end

--高亮玩家聊天
-- 移除CleanChat_PopupOnUpdated函数，不再需要

--cmd命令
function CleanChat_ChatCommand(msg)
	if CleanChatOptionsFrame:IsVisible() then
		CleanChatOptionsFrame:Hide()
	else
		CleanChatOptionsFrame:Show()
	end
end

function Automaton_CleanChat:SetupPrefix()
	CHAT_RAID_GET = "[团] %s:\32"
	CHAT_PARTY_GET = "[队] %s:\32"
	CHAT_OFFICER_GET = CHAT_OFFICER_GET
	CHAT_GUILD_GET = "[会] %s:\32"
	CHAT_RAID_LEADER_GET = "[团长] %s:\32"
	CHAT_RAID_WARNING_GET = "|cffff0000[团队通知]|r %s:\32"
	CHAT_BATTLEGROUND_GET = "[战] %s:\32"
	CHAT_BATTLEGROUND_LEADER_GET = "[领袖] %s:\32"
end

local function EmptyReturn()
	if not this then
		return
	end
	this.CleanChat_UnitName = nil
	this.CleanChat_Channelname = nil
	this.CleanChatShort_Channelname = nil
	--this.chatmsg = nil
end

-- ========== 修正2：删除原JumpCombatLog，改用IsCombatLogEvent ==========
local function IsCombatLogEvent(event)
	if not event then
		return false
	end
	return string.find(event, "CHAT_MSG_SPELL")
		or string.find(event, "CHAT_MSG_COMBAT")
		or string.find(event, "CHAT_MSG_MONSTER")
		or string.find(event, "_EMOTE")
end

-- 无用消息屏蔽（使用修正后的 filter 变量）
local function MessageFilter(msg)
	for _, v in pairs(filter) do
		if string.find(msg, v) then
			EmptyReturn()
			return false
		end
	end
	return true
end

-- ========== 修正2（续）：重写 CleanChat_AddMessage ==========
function CleanChat_AddMessage(this, msg, r, g, b, id)
	-- 1. 战斗日志事件：直接调用原始方法，跳过所有增强功能
	if IsCombatLogEvent(this.event) then
		EmptyReturn() -- 清理临时变量
		if this.CleanChat_AddMessage_Org then
			this:CleanChat_AddMessage_Org(msg, r, g, b, id)
		end
		return
	end

	-- 2. 非战斗日志事件，执行原有增强逻辑
	if MessageFilter(msg) then
		local channelName = this.CleanChat_Channelname
		if channelName == nil then
			channelName = ""
		end

		-- 频道缩写
		if msg and channelName ~= "" then
			if channelName == "Hardcore" then
				-- 使用配置的硬核频道颜色
				local hcHex = RGBToHex(Automaton_CleanChat.db.profile.hcColour)
				local text_new = string.gsub(msg, "%[(.*)%]%s", "|cff" .. hcHex .. "[核] |r")
				if text_new ~= nil and msg ~= text_new then
					msg = text_new
				end
			elseif this.CleanChatShort_Channelname and this.CleanChat_Channelname then
				local num = gsub(msg, "^%[(%d+)%..+%].*", "%1")
				local pattern = num .. ". " .. this.CleanChat_Channelname
				local replacement = this.CleanChatShort_Channelname
				msg = gsub(msg, pattern, replacement, 1)
			end
		end

		-- 点选聊天框组队
		if Automaton_CleanChat.db.profile.clickinvite and msg ~= nil and arg2 ~= nil then
			CleanChat_INVITEFOUND = nil
			if CleanChat_INVITEFOUND == nil then
				msg = string.gsub(msg, "%s+(invite)(.?)", CleanChat_ClickInvite, 1)
			end
			if CleanChat_INVITEFOUND == nil then
				msg = string.gsub(msg, "%s+(INVITE)(.?)", CleanChat_ClickInvite, 1)
			end
			if CleanChat_INVITEFOUND == nil then
				msg = string.gsub(msg, "%s+(inv)(.?)", CleanChat_ClickInvite, 1)
			end
			if CleanChat_INVITEFOUND == nil then
				msg = string.gsub(msg, "%s+(INV)(.?)", CleanChat_ClickInvite, 1)
			end
			if CleanChat_INVITEFOUND == nil and CleanChat_CUSTOM_INV ~= nil then
				for i = 0, table.getn(CleanChat_CUSTOM_INV) do
					if CleanChat_INVITEFOUND == nil then
						msg = string.gsub(msg, "%s+(" .. CleanChat_CUSTOM_INV[i] .. ")(.?)", CleanChat_ClickInvite, 1)
					end
				end
			end
		end

		if strfind(msg, ".+ was added to your collection.") then
			msg = gsub(msg, "was added to your collection.", " |CFFFF00FF已添加到收藏|R")
		end

		-- Every 5 minutes remove old entries
		if GetTime() > nextPurgeCheck then
			nextPurgeCheck = GetTime() + PURGE_INTERVAL
		end

		msg = CleanChat_ChatAddTime(msg)
	end

	-- 3. 最终调用原始方法显示消息
	if this.CleanChat_AddMessage_Org then
		this:CleanChat_AddMessage_Org(msg, r, g, b, id)
	end
	EmptyReturn()
end

-- 添加一个打印函数（如果不存在）
function Automaton_CleanChat:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc[CleanChat]|r " .. msg)
end
