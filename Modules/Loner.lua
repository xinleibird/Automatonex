assert(Automaton, "Automaton not found!")

------------------------------
--      Are you local?      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_StrangerDecline")

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function()
	return {
		["StrangerDecline"] = "i人模式（拒绝邀请）",
		["Decline invites from strangers."] = "自动拒绝所有陌生人的邀请(非好友，非公会成员都判定为陌生人)",

		-- 组队邀请相关
		["PartyInvites"] = "拒绝陌生人组队邀请",
		["Decline party invites from strangers."] = "只接受好友和公会成员的组队邀请",
		["Declining party invite from %s (not friend/guild member)..."] = "i人模式生效中，自动拒绝来自陌生人|cffCCCCCC %s|cffFFFF00 的组队邀请。如想临时与非好友非同公会玩家组队，可点击Roll点旁边的|cffCCCCCC拒|cffFFFF00字临时禁用，或到Automaton工具箱永久禁用。",
		["Enable auto-decline party invites"] = "启用自动拒绝陌生人组队邀请",

		-- 公会邀请相关
		["GuildInvites"] = "拒绝陌生人公会邀请",
		["Decline guild invites from strangers."] = "只接受好友的公会入会邀请",
		["Declining guild invite from %s (not friend)..."] = "i人模式生效中，自动拒绝来自陌生人 %s 的公会邀请",
		["Canceling petition..."] = "正在取消邀请...",
		["Enable auto-decline guild invites"] = "启用自动拒绝陌生人公会邀请",

		-- 临时启用/禁用相关
		["ToggleMode"] = "i人模式临时开关",
		["StrangerDecline disabled"] = "临时禁用i人模式，允许接受所有邀请。",
		["StrangerDecline enabled"] = "临时启用i人模式，自动拒绝陌生人邀请。",

		-- 自定义列表相关
		["Custom List"] = "自定义例外名单",
		["Accept invites from players in custom list even if they are not friends/guildmates."] = "接受自定义名单中玩家的邀请，即使他们不是好友或公会成员。",
		["Black List"] = "自定义黑名单",
		["Decline invites from players in black list even if they are friends/guildmates."] = "拒绝黑名单中玩家的邀请，即使他们是好友或公会成员。",
		["Add Player to White List"] = "添加玩家到例外名单",
		["<player name>"] = "玩家名称",
		["Remove Player from White List"] = "从例外名单移除玩家",
		["List White List"] = "显示例外名单",
		["Purge White List"] = "清空例外名单",
		["Add Player to Black List"] = "添加玩家到黑名单",
		["Remove Player from Black List"] = "从黑名单移除玩家",
		["List Black List"] = "显示黑名单",
		["Purge Black List"] = "清空黑名单",
		["White list is empty"] = "例外名单为空",
		["Black list is empty"] = "黑名单为空",
		["White list contains:"] = "例外名单包含:",
		["Black list contains:"] = "黑名单包含:",
		["Purged %d names from white list"] = "已从例外名单清除 %d 个名称",
		["Purged %d names from black list"] = "已从黑名单清除 %d 个名称",
		["Player %s added to white list"] = "玩家 %s 已添加到例外名单",
		["Player %s removed from white list"] = "玩家 %s 已从例外名单移除",
		["Player %s added to black list"] = "玩家 %s 已添加到黑名单",
		["Player %s removed from black list"] = "玩家 %s 已从黑名单移除",
		["Player not found in white list"] = "玩家不在例外名单中",
		["Player not found in black list"] = "玩家不在黑名单中",
		["Declining invite from blacklisted player: %s"] = "拒绝黑名单玩家 %s 的邀请",
		["Enable Black List"] = "启用黑名单功能",
		["Enable White List"] = "启用白名单功能",

		-- 关键字匹配相关
		["Enable Keyword Match"] = "启用关键字匹配",
		["Match invites from players whose names contain keywords in black list."] = "匹配玩家名称中包含黑名单中关键字的邀请",
		["Add Keyword to Black List"] = "添加关键字到黑名单",
		["<keyword>"] = "关键字",
		["Remove Keyword from Black List"] = "从黑名单移除关键字",
		["Keyword %s added to black list"] = "关键字 %s 已添加到黑名单",
		["Keyword %s removed from black list"] = "关键字 %s 已从黑名单移除",
		["Keyword not found in black list"] = "关键字不在黑名单中",
		["Keyword matching: %s"] = "关键字匹配: %s",
		["Enable keyword matching for black list"] = "启用黑名单关键字匹配",
	}
end)

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_StrangerDecline = Automaton:NewModule("StrangerDecline")
Automaton_StrangerDecline.modulename = L["StrangerDecline"]
Automaton_StrangerDecline.moduledesc = L["Decline invites from strangers."]
Automaton_StrangerDecline.options = {
	party = {
		type = "toggle",
		name = L["PartyInvites"],
		desc = L["Enable auto-decline party invites"],
		get = function()
			return Automaton_StrangerDecline.db.profile.partyEnabled
		end,
		set = function(v)
			Automaton_StrangerDecline.db.profile.partyEnabled = v
			if v then
				Automaton_StrangerDecline:RegisterEvent("PARTY_INVITE_REQUEST")
			else
				Automaton_StrangerDecline:UnregisterEvent("PARTY_INVITE_REQUEST")
			end
		end,
	},
	guild = {
		type = "toggle",
		name = L["GuildInvites"],
		desc = L["Enable auto-decline guild invites"],
		get = function()
			return Automaton_StrangerDecline.db.profile.guildEnabled
		end,
		set = function(v)
			Automaton_StrangerDecline.db.profile.guildEnabled = v
			if v then
				Automaton_StrangerDecline:RegisterEvent("GUILD_INVITE_REQUEST")
				Automaton_StrangerDecline:RegisterEvent("PETITION_SHOW")
			else
				Automaton_StrangerDecline:UnregisterEvent("GUILD_INVITE_REQUEST")
				Automaton_StrangerDecline:UnregisterEvent("PETITION_SHOW")
			end
		end,
	},
	enableBlackList = {
		type = "toggle",
		name = L["Enable Black List"],
		desc = L["Decline invites from players in black list even if they are friends/guildmates."],
		order = 3,
		get = function()
			return Automaton_StrangerDecline.db.profile.enableBlackList
		end,
		set = function(v)
			Automaton_StrangerDecline.db.profile.enableBlackList = v
		end,
	},
	enableWhiteList = {
		type = "toggle",
		name = L["Enable White List"],
		desc = L["Accept invites from players in custom list even if they are not friends/guildmates."],
		order = 4,
		get = function()
			return Automaton_StrangerDecline.db.profile.enableWhiteList
		end,
		set = function(v)
			Automaton_StrangerDecline.db.profile.enableWhiteList = v
		end,
	},
	enableKeywordMatch = {
		type = "toggle",
		name = L["Enable Keyword Match"],
		desc = L["Enable keyword matching for black list"],
		order = 5,
		get = function()
			return Automaton_StrangerDecline.db.profile.enableKeywordMatch
		end,
		set = function(v)
			Automaton_StrangerDecline.db.profile.enableKeywordMatch = v
		end,
	},
	custom = {
		type = "group",
		name = L["Custom List"],
		desc = L["Accept invites from players in custom list even if they are not friends/guildmates."],
		order = 10,
		disabled = function()
			return not Automaton_StrangerDecline.db.profile.enableWhiteList
				and not Automaton_StrangerDecline.db.profile.enableBlackList
		end,
		args = {
			whiteList = {
				type = "group",
				name = L["Custom List"],
				desc = L["Accept invites from players in custom list even if they are not friends/guildmates."],
				order = 1,
				disabled = function()
					return not Automaton_StrangerDecline.db.profile.enableWhiteList
				end,
				args = {
					addWhite = {
						type = "text",
						name = L["Add Player to White List"],
						desc = L["Add Player to White List"],
						order = 1,
						usage = L["<player name>"],
						get = false,
						set = function(v)
							Automaton_StrangerDecline:AddWhiteListName(v)
						end,
					},
					removeWhite = {
						type = "text",
						name = L["Remove Player from White List"],
						desc = L["Remove Player from White List"],
						order = 2,
						usage = L["<player name>"],
						get = false,
						set = function(v)
							Automaton_StrangerDecline:RemoveWhiteListName(v)
						end,
					},
					listWhite = {
						type = "execute",
						name = L["List White List"],
						desc = L["List White List"],
						order = 3,
						func = function()
							Automaton_StrangerDecline:ListWhiteList()
						end,
					},
					purgeWhite = {
						type = "execute",
						name = L["Purge White List"],
						desc = L["Purge White List"],
						order = 4,
						func = function()
							Automaton_StrangerDecline:PurgeWhiteList()
						end,
					},
				},
			},
			blackList = {
				type = "group",
				name = L["Black List"],
				desc = L["Decline invites from players in black list even if they are friends/guildmates."],
				order = 2,
				disabled = function()
					return not Automaton_StrangerDecline.db.profile.enableBlackList
				end,
				args = {
					addBlack = {
						type = "text",
						name = L["Add Player to Black List"],
						desc = L["Add Player to Black List"],
						order = 1,
						usage = L["<player name>"],
						get = false,
						set = function(v)
							Automaton_StrangerDecline:AddBlackListName(v)
						end,
					},
					removeBlack = {
						type = "text",
						name = L["Remove Player from Black List"],
						desc = L["Remove Player from Black List"],
						order = 2,
						usage = L["<player name>"],
						get = false,
						set = function(v)
							Automaton_StrangerDecline:RemoveBlackListName(v)
						end,
					},
					addKeyword = {
						type = "text",
						name = L["Add Keyword to Black List"],
						desc = L["Add Keyword to Black List"],
						order = 3,
						usage = L["<keyword>"],
						get = false,
						set = function(v)
							Automaton_StrangerDecline:AddKeywordToBlackList(v)
						end,
					},
					removeKeyword = {
						type = "text",
						name = L["Remove Keyword from Black List"],
						desc = L["Remove Keyword from Black List"],
						order = 4,
						usage = L["<keyword>"],
						get = false,
						set = function(v)
							Automaton_StrangerDecline:RemoveKeywordFromBlackList(v)
						end,
					},
					listBlack = {
						type = "execute",
						name = L["List Black List"],
						desc = L["List Black List"],
						order = 5,
						func = function()
							Automaton_StrangerDecline:ListBlackList()
						end,
					},
					purgeBlack = {
						type = "execute",
						name = L["Purge Black List"],
						desc = L["Purge Black List"],
						order = 6,
						func = function()
							Automaton_StrangerDecline:PurgeBlackList()
						end,
					},
				},
			},
		},
	},
}

------------------------------
--      Initialization      --
------------------------------

function Automaton_StrangerDecline:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("StrangerDecline")
	Automaton:RegisterDefaults("StrangerDecline", "profile", {
		disabled = true,
		partyEnabled = false,
		guildEnabled = false,
		enableBlackList = true,
		enableWhiteList = true,
		enableKeywordMatch = true, -- 默认启用关键字匹配
		whiteList = {},
		blackList = {},
		keywordList = {}, -- 新增：关键字列表
	})
	Automaton:SetDisabledAsDefault(self, "StrangerDecline")
	self:RegisterOptions(self.options)

	-- 注册切换命令
	SLASH_ACCEPTSTRANGERS1 = "/接受陌生人邀请"
	SlashCmdList["ACCEPTSTRANGERS"] = function()
		self:ToggleModule()
	end

	-- 初始化临时禁用状态
	self.isDisabled = false
end

function Automaton_StrangerDecline:OnEnable()
	-- 总是注册事件，让黑名单功能独立工作
	self:RegisterEvent("PARTY_INVITE_REQUEST")
	self:RegisterEvent("GUILD_INVITE_REQUEST")
	self:RegisterEvent("PETITION_SHOW")
end

function Automaton_StrangerDecline:OnDisable()
	self:UnregisterAllEvents()
end

------------------------------
--      工具函数           --
------------------------------

-- 获取数组长度的安全函数
function Automaton_StrangerDecline:TableLength(t)
	if not t then
		return 0
	end
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

-- 获取好友列表中的玩家
function Automaton_StrangerDecline:GetFriendsList()
	local friends = {}
	for i = 1, GetNumFriends() do
		local name = GetFriendInfo(i)
		if name then
			tinsert(friends, name)
		end
	end
	return friends
end

-- 获取公会成员列表
function Automaton_StrangerDecline:GetGuildMembersList()
	local guildmates = {}
	GuildRoster()
	for i = 1, GetNumGuildMembers() do
		local name = GetGuildRosterInfo(i)
		if name then
			tinsert(guildmates, name)
		end
	end
	return guildmates
end

-- 检查玩家是否在列表中（大小写不敏感）
function Automaton_StrangerDecline:IsInList(name, list)
	if not name or not list then
		return false
	end
	local nameLower = string.lower(name)
	for _, v in pairs(list) do
		if v and string.lower(v) == nameLower then
			return true
		end
	end
	return false
end

-- 检查名字是否包含关键字
function Automaton_StrangerDecline:MatchesKeyword(name, keyword)
	if not name or not keyword then
		return false
	end
	local nameLower = string.lower(name)
	local keywordLower = string.lower(keyword)
	return string.find(nameLower, keywordLower, 1, true) ~= nil
end

-- 检查是否是好友
function Automaton_StrangerDecline:IsFriend(name)
	local friends = self:GetFriendsList()
	return self:IsInList(name, friends)
end

-- 检查是否是公会成员
function Automaton_StrangerDecline:IsGuildMember(name)
	local guildmates = self:GetGuildMembersList()
	return self:IsInList(name, guildmates)
end

-- 检查是否在白名单中
function Automaton_StrangerDecline:IsInWhiteList(name)
	return self.db.profile.enableWhiteList and self:IsInList(name, self.db.profile.whiteList)
end

-- 检查是否在黑名单中（现在支持关键字匹配）
function Automaton_StrangerDecline:IsInBlackList(name)
	if not self.db.profile.enableBlackList then
		return false
	end
	if not name then
		return false
	end

	-- 1. 先检查精确匹配（玩家名字）
	if self:IsInList(name, self.db.profile.blackList) then
		return true
	end

	-- 2. 如果启用了关键字匹配，检查关键字匹配
	if self.db.profile.enableKeywordMatch then
		for _, keyword in pairs(self.db.profile.keywordList) do
			if keyword and self:MatchesKeyword(name, keyword) then
				return true
			end
		end
	end

	return false
end

------------------------------
--      自定义列表管理     --
------------------------------

-- 白名单相关函数保持不变
function Automaton_StrangerDecline:AddWhiteListName(name)
	if name and name ~= "" and not self:IsInWhiteList(name) then
		tinsert(self.db.profile.whiteList, name)
		self:print(string.format("|cff00FF00" .. L["Player %s added to white list"], name) .. "|r")
	end
end

function Automaton_StrangerDecline:RemoveWhiteListName(name)
	if name and name ~= "" then
		local newList = {}
		local removed = false
		for _, v in pairs(self.db.profile.whiteList) do
			if string.lower(v) ~= string.lower(name) then
				tinsert(newList, v)
			else
				removed = true
			end
		end
		self.db.profile.whiteList = newList
		if removed then
			self:print(string.format("|cff00FF00" .. L["Player %s removed from white list"], name) .. "|r")
		else
			self:print("|cffFF0000" .. L["Player not found in white list"] .. "|r")
		end
	end
end

function Automaton_StrangerDecline:ListWhiteList()
	local count = self:TableLength(self.db.profile.whiteList)
	if count == 0 then
		self:print("|cffFFFF00" .. L["White list is empty"] .. "|r")
	else
		self:print("|cff00FF00" .. L["White list contains:"] .. " (" .. count .. ")|r")
		for _, name in pairs(self.db.profile.whiteList) do
			self:print("  " .. name)
		end
	end
end

function Automaton_StrangerDecline:PurgeWhiteList()
	local count = self:TableLength(self.db.profile.whiteList)
	self.db.profile.whiteList = {}
	self:print(string.format("|cff00FF00" .. L["Purged %d names from white list"], count) .. "|r")
end

-- 黑名单相关函数（添加关键字管理）
function Automaton_StrangerDecline:AddBlackListName(name)
	if name and name ~= "" and not self:IsInList(name, self.db.profile.blackList) then
		tinsert(self.db.profile.blackList, name)
		self:print(string.format("|cff00FF00" .. L["Player %s added to black list"], name) .. "|r")
	end
end

function Automaton_StrangerDecline:RemoveBlackListName(name)
	if name and name ~= "" then
		local newList = {}
		local removed = false
		for _, v in pairs(self.db.profile.blackList) do
			if string.lower(v) ~= string.lower(name) then
				tinsert(newList, v)
			else
				removed = true
			end
		end
		self.db.profile.blackList = newList
		if removed then
			self:print(string.format("|cff00FF00" .. L["Player %s removed from black list"], name) .. "|r")
		else
			self:print("|cffFF0000" .. L["Player not found in black list"] .. "|r")
		end
	end
end

-- 添加关键字到黑名单
function Automaton_StrangerDecline:AddKeywordToBlackList(keyword)
	if keyword and keyword ~= "" and not self:IsInList(keyword, self.db.profile.keywordList) then
		tinsert(self.db.profile.keywordList, keyword)
		self:print(string.format("|cff00FF00" .. L["Keyword %s added to black list"], keyword) .. "|r")
	end
end

-- 从黑名单移除关键字
function Automaton_StrangerDecline:RemoveKeywordFromBlackList(keyword)
	if keyword and keyword ~= "" then
		local newList = {}
		local removed = false
		for _, v in pairs(self.db.profile.keywordList) do
			if string.lower(v) ~= string.lower(keyword) then
				tinsert(newList, v)
			else
				removed = true
			end
		end
		self.db.profile.keywordList = newList
		if removed then
			self:print(string.format("|cff00FF00" .. L["Keyword %s removed from black list"], keyword) .. "|r")
		else
			self:print("|cffFF0000" .. L["Keyword not found in black list"] .. "|r")
		end
	end
end

function Automaton_StrangerDecline:ListBlackList()
	local playerCount = self:TableLength(self.db.profile.blackList)
	local keywordCount = self:TableLength(self.db.profile.keywordList)

	if playerCount == 0 and keywordCount == 0 then
		self:print("|cffFFFF00" .. L["Black list is empty"] .. "|r")
	else
		-- 显示玩家名单
		if playerCount > 0 then
			self:print("|cff00FF00黑名单玩家 (" .. playerCount .. "):|r")
			for _, name in pairs(self.db.profile.blackList) do
				self:print("  " .. name)
			end
		end

		-- 显示关键字名单
		if keywordCount > 0 then
			self:print("|cff00FF00黑名单关键字 (" .. keywordCount .. "):|r")
			for _, keyword in pairs(self.db.profile.keywordList) do
				self:print("  " .. keyword .. " |cff888888(关键字匹配)|r")
			end
		end
	end
end

function Automaton_StrangerDecline:PurgeBlackList()
	local playerCount = self:TableLength(self.db.profile.blackList)
	local keywordCount = self:TableLength(self.db.profile.keywordList)
	local totalCount = playerCount + keywordCount

	self.db.profile.blackList = {}
	self.db.profile.keywordList = {}

	self:print(
		string.format(
			"|cff00FF00已从黑名单清除 %d 个条目 (%d 玩家, %d 关键字)|r",
			totalCount,
			playerCount,
			keywordCount
		)
	)
end

------------------------------
--      Event Handlers      --
------------------------------

function Automaton_StrangerDecline:ToggleModule()
	if self:IsActive() then
		self:ToggleActive(false)
		self:print("|cffFFFF00" .. L["StrangerDecline disabled"] .. "|r")
	else
		self:ToggleActive(true)
		self:print("|cffFFFF00" .. L["StrangerDecline enabled"] .. "|r")
	end
end

function Automaton_StrangerDecline:ToggleStrangerDecline()
	self.isDisabled = not self.isDisabled
	if self.isDisabled then
		self:print("|cffFFFF00" .. L["StrangerDecline disabled"] .. "|r")
	else
		self:print("|cffFFFF00" .. L["StrangerDecline enabled"] .. "|r")
	end
end

-- 检查玩家是否匹配关键字（用于提示信息）
function Automaton_StrangerDecline:CheckKeywordMatch(name)
	if not name or not self.db.profile.enableKeywordMatch then
		return nil
	end

	for _, keyword in pairs(self.db.profile.keywordList) do
		if keyword and self:MatchesKeyword(name, keyword) then
			return keyword
		end
	end
	return nil
end

-- 事件处理函数
function Automaton_StrangerDecline:PARTY_INVITE_REQUEST()
	local inviter = arg1

	-- 检查黑名单（最高优先级，独立于其他设置）
	if inviter and self:IsInBlackList(inviter) then
		-- 检查是否是关键字匹配
		local matchedKeyword = self:CheckKeywordMatch(inviter)

		if matchedKeyword then
			DeclineGroup()
			StaticPopup_Hide("PARTY_INVITE")
			C_Timer.After(0.5, function()
				self:print(
					"|cffFF0000"
						.. string.format(L["Declining invite from blacklisted player: %s"], inviter)
						.. " |cff888888("
						.. string.format(L["Keyword matching: %s"], matchedKeyword)
						.. ")|r"
				)
			end)
		else
			DeclineGroup()
			StaticPopup_Hide("PARTY_INVITE")
			C_Timer.After(0.5, function()
				self:print(
					"|cffFF0000" .. string.format(L["Declining invite from blacklisted player: %s"], inviter) .. "|r"
				)
			end)
		end
		return
	end

	-- 检查白名单
	if inviter and self:IsInWhiteList(inviter) then
		return -- 在白名单中，允许邀请
	end

	-- 如果临时禁用，直接返回（允许邀请）
	if self.isDisabled then
		return
	end

	-- 如果"拒绝陌生人组队邀请"功能未启用，允许邀请
	if not self.db.profile.partyEnabled then
		return
	end

	-- 检查是否是好友
	if inviter and self:IsFriend(inviter) then
		return -- 是好友，允许邀请
	end

	-- 检查是否是公会成员
	if inviter and self:IsGuildMember(inviter) then
		return -- 是公会成员，允许邀请
	end

	-- 既不在白名单也不是好友也不是公会成员，拒绝邀请
	if inviter then
		DeclineGroup()
		StaticPopup_Hide("PARTY_INVITE")
		C_Timer.After(0.5, function()
			self:print(
				"|cffFFFF00"
					.. string.format(L["Declining party invite from %s (not friend/guild member)..."], inviter)
					.. "|r"
			)
		end)
	end
end

function Automaton_StrangerDecline:GUILD_INVITE_REQUEST()
	local inviter = arg1

	-- 检查黑名单（最高优先级，独立于其他设置）
	if inviter and self:IsInBlackList(inviter) then
		-- 检查是否是关键字匹配
		local matchedKeyword = self:CheckKeywordMatch(inviter)

		if matchedKeyword then
			DeclineGuild()
			StaticPopup_Hide("GUILD_INVITE")
			C_Timer.After(0.5, function()
				self:print(
					"|cffFF0000"
						.. string.format(L["Declining invite from blacklisted player: %s"], inviter)
						.. " |cff888888("
						.. string.format(L["Keyword matching: %s"], matchedKeyword)
						.. ")|r"
				)
			end)
		else
			DeclineGuild()
			StaticPopup_Hide("GUILD_INVITE")
			C_Timer.After(0.5, function()
				self:print(
					"|cffFF0000" .. string.format(L["Declining invite from blacklisted player: %s"], inviter) .. "|r"
				)
			end)
		end
		return
	end

	-- 检查白名单
	if inviter and self:IsInWhiteList(inviter) then
		return -- 在白名单中，允许邀请
	end

	-- 如果临时禁用，直接返回（允许邀请）
	if self.isDisabled then
		return
	end

	-- 如果"拒绝陌生人公会邀请"功能未启用，允许邀请
	if not self.db.profile.guildEnabled then
		return
	end

	-- 检查是否是好友
	if inviter and self:IsFriend(inviter) then
		return -- 是好友，允许邀请
	end

	-- 不是好友，拒绝邀请
	if inviter then
		DeclineGuild()
		StaticPopup_Hide("GUILD_INVITE")
		C_Timer.After(0.5, function()
			self:print(
				"|cffFFFF00" .. string.format(L["Declining guild invite from %s (not friend)..."], inviter) .. "|r"
			)
		end)
	end
end

function Automaton_StrangerDecline:PETITION_SHOW()
	-- 尝试获取邀请者信息
	local inviter = nil

	-- 尝试通过不同方式获取邀请者信息
	if C_PetitionInfo and C_PetitionInfo.GetPetitionInfo then
		local petitionInfo = C_PetitionInfo.GetPetitionInfo()
		if petitionInfo and petitionInfo.ownerName then
			inviter = petitionInfo.ownerName
		end
	end

	-- 如果无法获取邀请者，直接取消
	if not inviter then
		-- 检查黑名单设置，如果启用则取消
		if self.db.profile.enableBlackList then
			ClosePetition()
			C_Timer.After(0.5, function()
				self:print("|cffFFFF00" .. L["Canceling petition..."] .. "|r")
			end)
		end
		return
	end

	-- 检查黑名单（最高优先级，独立于其他设置）
	if self:IsInBlackList(inviter) then
		-- 检查是否是关键字匹配
		local matchedKeyword = self:CheckKeywordMatch(inviter)

		if matchedKeyword then
			ClosePetition()
			C_Timer.After(0.5, function()
				self:print(
					"|cffFF0000"
						.. string.format(L["Declining invite from blacklisted player: %s"], inviter)
						.. " |cff888888("
						.. string.format(L["Keyword matching: %s"], matchedKeyword)
						.. ")|r"
				)
			end)
		else
			ClosePetition()
			C_Timer.After(0.5, function()
				self:print(
					"|cffFF0000" .. string.format(L["Declining invite from blacklisted player: %s"], inviter) .. "|r"
				)
			end)
		end
		return
	end

	-- 检查白名单
	if self:IsInWhiteList(inviter) then
		return -- 在白名单中，允许
	end

	-- 如果临时禁用，直接返回（允许）
	if self.isDisabled then
		return
	end

	-- 如果"拒绝陌生人公会邀请"功能未启用，允许
	if not self.db.profile.guildEnabled then
		return
	end

	-- 检查是否是好友
	if self:IsFriend(inviter) then
		return -- 是好友，允许
	end

	-- 不在白名单也不是好友，取消
	ClosePetition()
	C_Timer.After(0.5, function()
		self:print("|cffFFFF00" .. L["Canceling petition..."] .. "|r")
	end)
end
