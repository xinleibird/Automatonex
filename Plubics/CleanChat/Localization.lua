--[[
P5 
"A tragedy has occured. Inferno character Houbaoqs (level 60) died of natural causes in Stormwind City. They laughed in the face of death, but have learnt that death always has the last laugh."

]]
CLEANCHAT_T = {}
CLEANCHAT_NAME = "CleanChat"
CLEANCHAT_VERSION = "v20"
CLEANCHAT_CHATMESSAGE = NORMAL_FONT_COLOR_CODE .. CLEANCHAT_NAME .. ": " .. LIGHTYELLOW_FONT_COLOR_CODE .. "%s"

BINDING_HEADER_CLEANCHAT = CLEANCHAT_NAME

CLEANCHAT_CHATPATTERN1 = "(.-)%s-: (.- .-) ([^<%-]*) "

function CleanChat_StripRealm(name)
	-- Player names from other realms in BG have this format:
	-- <Playername>-<Realm>, eg. Dadude-Frostmoure
	-- This func should strip the Realm part if variable 'name' contains one, otherwise leave untouched.
	local _
	if string.find(name, "%-") then
		_, _, name = string.find(name, "(.-)%-")
	end
	return name
end

function CleanChat_EscapeRealm(name)
	-- Variable 'name' is used in a regex, so if it is a cross realm name we need to escape the '-' sign within it.
	-- As it is a special regex instruction, we need to escape otherwise will not work.
	-- This func should escape the Realm part in variable 'name' contains one, otherwise leave untouched.
	return string.gsub(name, "%-", "%%%-")
end

-- CleanChat_StripRealm = CleanChat_Europe_StripRealm;
-- CleanChat_EscapeRealm = CleanChat_Europe_EscapeRealm;
-- URL window
CLEANCHAT_URL_TITLE = "URL list"
BINDING_NAME_CLEANCHAT_URL = "Toggle URL list"
CLEANCHAT_URL_STATUS1 = "左键单击选择URL."
CLEANCHAT_URL_STATUS2 = "CTRL+ C 复制内容."
CLEANCHAT_NO_URL = "-- No URL --"

CLEANCHAT_WHO_RESULTS_PATTERN = "%d+ player[s]? total"

CLEANCHAT_TRANSLATE_CLASS = {
	["Hunter"] = 1,
	["Warlock"] = 2,
	["Priest"] = 3,
	["Paladin"] = 4,
	["Mage"] = 5,
	["Rogue"] = 6,
	["Druid"] = 7,
	["Shaman"] = 8,
	["Warrior"] = 9,
}

CLEANCHAT_LOADED = " loaded."
CLEANCHAT_LOADED_CACHE = CLEANCHAT_VERSION .. " loaded (%d names cached)."

CLEANCHAT_MYADDONS_DESCRIPTION = "Colorize names, shows level, shortens channel names and more."
CLEANCHAT_CHANNELS = {
	-- Channel names are shown.
	["__PREFIX"] = "%d%. ",
	["General"] = "综",
	["综合"] = "综",
	["Trade"] = "交",
	["交易"] = "交",
	["LocalDefense"] = "防",
	["WorldDefense"] = "世",
	["World"] = "世",
	["world"] = "世",
	["LookingForGroup"] = "寻",
	["GuildRecruitment"] = "GuildRecruitment",
	["China"] = "中",
	["china"] = "中",
	["中国"] = "中",
	["Hardcore"] = "HC",
}

--CLEANCHAT_HELP = { HIGHLIGHT_FONT_COLOR_CODE .. "/cleanchat" .. LIGHTYELLOW_FONT_COLOR_CODE .. "- 显示设置." };

CLEANCHAT_STATUS3 = {
	"显示频道名称.",
	"隐藏频道“综合”和“交易”.",
	"Channel names General, Trade, LookingForGroup and Defense are not shown.",
	"隐藏全部频道名称.",
	"使用频道缩写: 综 - General, 交 - Trade, HC - Hardcore.",
	"使用缩写并隐藏其他频道名称.",
}

CLEANCHAT_STATUS4 = "的自定义颜色 %s%s %s%s"
CLEANCHAT_STATUS5 = { "公会成员", "好友", "其他", "队伍", "团队", "未指定", "自己" }
CLEANCHAT_STATUS6 = "未识别职业使用彩虹色."

-- GUI
BINDING_NAME_CLEANCHAT_GUI = "切换界面"
--CLEANCHAT_CHECKBOX_PREFIX = "隐藏聊天前缀 [Party], [Raid], [Guild] und [Officer]\n缩写为团队和战场 prefix.";
CLEANCHAT_CHANNELS_LABEL = "频道名称:"
--CLEANCHAT_COLORIZE_NICKS = "频道姓名着色";
--CLEANCHAT_USE_CLASS_COLORS = "使用职业色";
CLEANCHAT_USE_CURSORKEYS = "键入消息时激活光标键 (无需按住ALT键)"
--CLEANCHAT_HIDE_CHATBUTTONS = "隐藏按钮.";
--CLEANCHAT_COLLECTDATA = "允许使用/who 命令."
-- CleanChat_Config.ShowLevel = "显示人物等级.";
-- CleanChat_Config.ShowFaction = "显示阵营."
-- CLEANCHAT_MOUSEWHEEL = "支持鼠标滚轮翻页."; --默认开启
-- CLEANCHAT_PERSISTENT = "保存聊天数据."; --默认关闭
CLEANCHAT_SHOWCHATTIME = "显示聊天时间戳"
CLEANCHAT_POPUP = "如果包含您的姓名，则在屏幕上显示聊天信息."
CLEANCHAT_IGNORE_EMOTES = "不在表情中给名字上色."
--来自ChatMod 凡人插件版
CleanChat_STRIPCHAN = {}
if MRBCATLOC == "enUS" then
	CleanChat_STRIPCHAN[1] = "Guild"
	CleanChat_STRIPCHAN[2] = "Raid"
	CleanChat_STRIPCHAN[3] = "Party"
	CleanChat_STRIPCHAN[4] = "LocalDefense"
	CleanChat_STRIPCHAN[5] = "WorldDefense"
	CleanChat_STRIPCHAN[6] = "LookingForGroup"
	CleanChat_STRIPCHAN[7] = "Trade"
	CleanChat_STRIPCHAN[8] = "General"
	CleanChat_STRIPCHAN[9] = "World"
	CleanChat_STRIPCHAN[10] = "China"
else
	CleanChat_STRIPCHAN[1] = "工会"
	CleanChat_STRIPCHAN[2] = "团队"
	CleanChat_STRIPCHAN[3] = "小队"
	CleanChat_STRIPCHAN[4] = "世界防务"
	CleanChat_STRIPCHAN[5] = "官员"
	CleanChat_STRIPCHAN[6] = "交易"
	CleanChat_STRIPCHAN[7] = "综合"
	CleanChat_STRIPCHAN[8] = "World"
	CleanChat_STRIPCHAN[9] = "China"
end
CleanChat_CUSTOM_INV = {}
CleanChat_CUSTOM_INV[0] = "邀请"
CleanChat_CUSTOM_INV[1] = "组"
CleanChat_CUSTOM_INV[2] = "组我"
CleanChat_CUSTOM_INV[3] = "组下"
CleanChat_CUSTOM_INV[4] = "组一下"

CLEANCAHT_CHAT_MSG_SYSTEM = {

	["(.+) has reached level (.+) in Hardcore mode! .*"] = "|cfff86256[HC]|r 硬核玩家 |cff068fff%1|r 在硬核模式下已达到%2级。然而死亡也如影随形，伴其左右...",
	["(.+) 在硬核模式中已达到 (%d+) 级！他们的荣光将伴随他们走向不朽！.*"] = "|cfff86256[HC]|r 硬核玩家 |cff068fff%1|r 在硬核模式下已达到%2级。然而死亡也如影随形，伴其左右...",
	["服务器运行时间： (%d+) Days (%d+) Hours (%d+) Minutes (%d+) Seconds%.?"] = "服务器运行时间：%1天%2小时%3分钟%4秒",
	["服务器运行时间： (%d+) Day (%d+) Hours (%d+) Minutes (%d+) Seconds%.?"] = "服务器运行时间：%1天%2小时%3分钟%4秒",
	["服务器运行时间： (%d+) Hours (%d+) Minutes (%d+) Seconds%.?"] = "服务器运行时间：%1小时%2分钟%3秒",
	["服务器运行时间： (%d+) Minutes (%d+) Seconds%.?"] = "服务器运行时间：%1分钟%2秒",
	-- 单数 Hour 变体（1 小时时 Turtle 用 Hour 而非 Hours）
	["服务器运行时间： (%d+) Hour (%d+) Minutes (%d+) Seconds%.?"] = "服务器运行时间：%1小时%2分钟%3秒",
	["服务器运行时间： (%d+) Day (%d+) Hour (%d+) Minutes (%d+) Seconds%.?"] = "服务器运行时间：%1天%2小时%3分钟%4秒",
	["服务器运行时间： (%d+) Days (%d+) Hour (%d+) Minutes (%d+) Seconds%.?"] = "服务器运行时间：%1天%2小时%3分钟%4秒",
	-- Day 单数/复数 但小时为 0 被省略 的变体（如 "1 Day 16 Minutes 34 Seconds"）
	["服务器运行时间： (%d+) Day (%d+) Minutes (%d+) Seconds%.?"] = "服务器运行时间：%1天%2分钟%3秒",
	["服务器运行时间： (%d+) Days (%d+) Minutes (%d+) Seconds%.?"] = "服务器运行时间：%1天%2分钟%3秒",
	["Server Uptime: (%d+) Days (%d+) Hours (%d+) Minutes (%d+) Seconds%.?"] = "服务器运行时间：%1天%2小时%3分钟%4秒",
	["A tragedy has occurred. Hardcore character (.+) has fallen in PvP to (.+) at level (.+). May this sacrifice not be forgotten."] = "|cfff86256[PVP&HC]|r %3级的 |cff068fff%1|r 被玩家 %2 击杀！成功送去投胎！",
	["Server Time: Mon, (.+)"] = "服务器时间：周一, %1",
	["Server Time: Tue, (.+)"] = "服务器时间：周二, %1",
	["Server Time: Wed, (.+)"] = "服务器时间：周三, %1",
	["Server Time: Thu, (.+)"] = "服务器时间：周四, %1",
	["Server Time: Fri, (.+)"] = "服务器时间：周五, %1",
	["Server Time: Sat, (.+)"] = "服务器时间：周六, %1",
	["Server Time: Sun, (.+)"] = "服务器时间：周日, %1",
	-- 中文客户端前缀（服务器时间：）+ 英文周几缩写 变体
	["服务器时间：Mon, (.+)"] = "服务器时间：周一, %1",
	["服务器时间：Tue, (.+)"] = "服务器时间：周二, %1",
	["服务器时间：Wed, (.+)"] = "服务器时间：周三, %1",
	["服务器时间：Thu, (.+)"] = "服务器时间：周四, %1",
	["服务器时间：Fri, (.+)"] = "服务器时间：周五, %1",
	["服务器时间：Sat, (.+)"] = "服务器时间：周六, %1",
	["服务器时间：Sun, (.+)"] = "服务器时间：周日, %1",
	["Darkmoon Faire standing is now Neutral."] = "暗月马戏团活动已开放！",
	["(.+) was added to your collection."] = "%1 |CFFFF00FF已添加到收藏|R",
	-- ['Players online: (%d+). Max online: (%d+).']                                                                                                       = '当前在线：%1。最多在线：%2。',
	["(.+) has transcended death and reached level 60 .*"] = "|cfff86256[HC]|r ★恭喜★ |cff068fff%1|r 完成硬核挑战成功满级！！",
	["^(.+) 超脱生死，已经在硬核模式下达到了60级！"] = "|cfff86256[HC]|r ★恭喜★ |cff068fff%1|r 完成硬核挑战成功满级！！",
	["XP (.+) ON"] = "经验值获取：|cff00ff00开启|r",
	["XP (.+) OFF"] = "经验值获取：|cffff0000关闭|r",
	["(.+) completed (.+) quests and is now known as the Seeker of Knowledge, inspiring fellow adventurers to explore the unknown!"] = "|cfff86256[成就]|r ★恭喜★ |cff068fff%1|r 完成%2个任务，获得|CFFFF70FF博学者称号|r！",
	["(.+) has laughed in the face of death in the Hardcore challenge. (.+) has begun the Inferno Challenge!"] = "|cfff86256[HC]|r ★|cffff0000挑战|r★ |cff068fff%1|r 开启了炼狱模式！",
	["This party has members from both factions. Engaging in PvP .+"] = "队伍中有PVP玩家，参与PvP队员会强制开启PVP模式.",
	-- ['We are back online after a recent security breach. For your account security, it is MANDATORY to change your password. Use our website or the following command: .account password old_password new_password new_password']=
	-- '因为服务器遭到黑客攻击，重新上线后为了您的帐户安全，必须更改密码。通过网站或游戏内输入命令：.account password 旧密码 新密码 新密码',
	--临时活动

	-- ["Your current login streak is (.+) consecutive day%(s%)."]=
	--   '|cfff86256[活动]|r 你已连续登录 %1 天。',
	-- ['您的当前登录连续天数是 (.+) 天。'] =
	-- '|cfff86256[活动]|r 你已连续登录 %1 天。',
	-- ['The next reward will be obtainable in (.+) Hour[s]* (.+) Minute[s]* (.+) Second[s]*.'] =
	-- '|cfff86256[活动]|r 下一个奖励将在 %1 小时 %2 分 %3 秒后获得。',
	-- ['下一个奖励将在 (.+) Hour[s]+ (.+) Minute[s]* (.+) Second[s]*. 后可领取。'] =
	-- '|cfff86256[活动]|r 下一个奖励将在 %1 小时 %2 分 %3 秒后获得。',
	-- ['The streak will reset in (.+) Day (.+) Hour[s]* (.+) Minute[s]* (.+) Second[s]*.'] =
	-- '|cfff86256[活动]|r 连续登录纪录将在 %1 天 %2 小时 %3 分 %4 秒后重置。',
	--   ['连续登录记录将在 (.+) Day (.+) Hour[s]* (.+) Minute[s]* (.+) Second[s]*. 后重置。'] =
	-- '|cfff86256[活动]|r 连续登录纪录将在 %1 天 %2 小时 %3 分 %4 秒后重置。',

	-- 新增的汉化内容
	["Primary Specialization Saved."] = "天赋专精已保存。",
	["Primary Specialization Activated."] = "主天赋专精已激活。",
	["Secondary Specialization Activated."] = "副天赋专精已激活。",
	["You have a talent spec with (%d+) out of (%d+) points spent%. Using changing of specs as a free talent reset is not allowed."] = "你当前天赋专精已分配%1/%2点。不允许通过切换专精来免费重置天赋。",
	["Minimum level for Hardcore messages is now: (%d+)"] = "硬核消息的最小等级现在为：%1",
	["You paid a total of (%d+)g (%d+)s (%d+)c in Auction deposit%."] = "你在拍卖行支付了总计%1金%2银%3铜的押金。",
	["(.+) trades (.+) to (.+)%."] = "%1 将 %2 交易给了 %3。",
}
CLEANCAHT_BG_LOG_FILTER = {
	["Arathi Basin %[(.+)%].+"] = "|cfff86256[战场通知]|r 阿拉希盆地 %[%1%] 已开始！",
	["Blood Ring %[(.+)%].+"] = "|cfff86256[战场通知]|r 血环竞技场 %[%1%] 已开始！",
	["Warsong Gulch %[(.+)%].+"] = "|cfff86256[战场通知]|r 战歌峡谷 %[%1%] 已开始！",
	["Alterac Valley %[(.+)%].+"] = "|cfff86256[战场通知]|r 奥特兰克山谷 %[%1%] 已开始！",
}
CHAT_HC_MSG_P1_KEY =
	"A tragedy has occu[r]+ed. (.+) character (.+) %(level (.+)%) has fallen to (.+) %(level (.+)%) in (.-)%.%s"
CHAT_HC_MSG_P1_1_KEY =
	"悲剧发生了。(.+) (.+)（等级 (.+)）被 (.+)（等级 (%d+)）击杀。这发生在 (.+)。愿这一牺牲不会被忘记。"
CHAT_HC_MSG_P1_VAR = "|cfff86256[HC]|r %s |cff068fff%s|r 在%s被%s级%s击杀，享年%s级。"

CHAT_HC_MSG_P2_KEY = "A tragedy has occu[r]+ed. (.+) character (.+) has fallen to (.+) %(level (.+)%) at level (.-)%.%s"
CHAT_HC_MSG_P2_VAR = "|cfff86256[HC]|r %s |cff068fff%1|r 被%3级的%2成功返厂，享年%4级"
CHAT_HC_MSG_P3_KEY =
	"A tragedy has (.+) character (.+) %(level (.+)%) has fallen in PvP to (.+) %(level (.+)%) in (.-)%.%s"
CHAT_HC_MSG_P3_VAR = "|cfff86256[PVP&HC]|r 玩家 |cff068fff%s|r 在%s被%s级玩家%s击杀，享年%s级。"
CHAT_HC_MSG_P4_KEY = "A tragedy has occu[r]+ed. (.+) character (.+) %(level (.+)%) (.+) in (.-)%.%s"
CHAT_HC_MSG_P4_1_KEY = "悲剧发生了。(.+) (.+)（等级 (.+)）.+ (.+) (.+)。愿这一牺牲永不被遗忘。"
CHAT_HC_MSG_P4_VAR = "|cfff86256[HC]|r %s |cff068fff%s|r 在%s%s，享年%s级。"
--悲剧发生了。硬核角色 cvendicz(等级 53)在 Blackrock Mountain 被活活烧死。愿这一牺牲永不被遗忘
CHAT_FORMAT_MSG_COLLECTION = "was added to your collection."
CHAT_HC_MSG_DEATH_REASOM = {
	["has drowned"] = "投河自尽",
	["has burned to death"] = "葬身火海",
	["被活活烧死"] = "葬身火海",
	["年因年老而去世"] = "乌江自刎",
	["中溺亡"] = "投河自尽",
	["died of natural causes"] = "乌江自刎",
}
CHAT_HC_MSG_DEATH_PLAYERTYPE = {
	["Inferno"] = "炼狱玩家",
	["Hardcore"] = "硬核玩家",
	["硬核角色"] = "硬核玩家",
}
CHAT_HC_MSG_DEATH_PLAYERTYPE = setmetatable(CHAT_HC_MSG_DEATH_PLAYERTYPE, {
	__index = function(tab, key)
		return "玩家"
	end,
})
CLEANCHAT_T.RETTYPE = {
	-- Minutes = "[服务器重启] 剩余 |CFF00FF00%d|r 分钟",
	-- Seconds = "[服务器重启] 剩余 |CFFFF0000%d|r 秒钟",
	Minute = "[服务器重启] 剩余 |CFF00FF00%d|r 分钟",
	Second = "[服务器重启] 剩余 |CFFFF0000%d|r 秒钟",
}
CLEANCHAT_T.CLEANCHAT_RACE_TO_FACTION = {
	["Dwarf"] = "LM",
	["Gnome"] = "LM",
	["Goblin"] = "BL",
	["High Elf"] = "LM",
	["Human"] = "LM",
	["Night Elf"] = "LM",
	["Orc"] = "BL",
	["Tauren"] = "BL",
	["Troll"] = "BL",
	["Undead"] = "BL",
	["矮人"] = "LM",
	["侏儒"] = "LM",
	["地精"] = "BL",
	["高等精灵"] = "LM",
	["人类"] = "LM",
	["暗夜精灵"] = "LM",
	["兽人"] = "BL",
	["牛头人"] = "BL",
	["巨魔"] = "BL",
	["亡灵"] = "BL",
}
