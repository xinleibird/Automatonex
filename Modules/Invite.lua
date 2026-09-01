assert(Automaton, "Automaton not found!")

------------------------------
--      Are you local?      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_Invite")

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function()
	return {
		["Invite"] = "组队密语邀请",
		["Accept from"] = "自定义邀请名单",
		["Accept invites from these people"] = "接受指定人的邀请",
		["Friends"] = "自动接受好友的邀请",
		["Allow invite requests from players on your friends list"] = "允许来自好友列表中玩家的邀请请求",
		["Guildmates"] = "自动接受工会的邀请",
		["Allow invite requests from guildmates"] = "允许公会成员的邀请请求",
		["Custom list"] = "自定义列表",
		["Specify a custom list to accept from"] = "指定要接受邀请的自定义列表",
		["List"] = "打印列表",
		["Print all names in the custom list."] = "打印自定义列表中的所有名称。",
		["Add Player"] = "添加玩家",
		["Add a player to the custom list."] = "添加玩家到自定义列表",
		["<player name>"] = "玩家名称",
		["Remove Player"] = "移除指定玩家",
		["Removes a player from the custom list."] = "从自定义列表中删除指定玩家。",
		["Purge"] = "重置列表",
		["Remove all names from the custom list."] = "从自定义列表中删除所有名称",
		["Everyone"] = "允许任何人邀请",
		["Allow invite requests from everyone"] = "允许所有人的组队邀请请求",

		["Options for sending out party invites."] = "自动邀请密语你关键字的玩家",
		["Invite text"] = "关键字",
		["The text users send to trigger an invite."] = "密语关键字",
		["keyword invite"] = "关键字邀请",
		["Ignore case"] = "模糊关键字",
		["Disable case sensitivity for the invite text"] = "模糊关键字的匹配(不论大小写等)",

		["Auto turn raid"] = "自动转为团队",
		["Turn Raid when your team more than 5 person"] = "当小队人数超过5人时自动转换为团队",
		["Auto kick blacklist"] = "自动踢出黑名单玩家",
		["Automatically kick blacklisted players from party/raid"] = "自动将黑名单中的玩家踢出队伍/团队",
		["Kick interval"] = "检查间隔",
		["Interval in seconds to check for blacklisted players"] = "检查黑名单玩家的间隔（秒）",
		["Blacklist source"] = "黑名单来源",
		["Choose where to get blacklist from"] = "选择黑名单来源",
		["SI_Global"] = "SI_Global插件",
		["Use SI_Global's banned players list"] = "使用SI_Global插件的封禁玩家列表",
		["Ignore list"] = "游戏忽略列表",
		["Use WoW's built-in ignore list"] = "使用游戏内置的忽略列表",
		["Both"] = "两者都用",
		["Use both SI_Global and ignore list"] = "同时使用SI_Global和游戏忽略列表",
		["Debug blacklist"] = "调试黑名单",
		["Print debug information about blacklist"] = "打印黑名单的调试信息",

		["Can't invite"] = "不能邀请",
		[",you are not leader"] = "，你不是队长或团队助理",
		["Automatically converted to Raid"] = "|cffff0000>>|r已自动转换到团队|cffff0000<<|r",
		[",Raid is full."] = "，团队已满",
		[",Party is full."] = "，小队已满",
		["Inviting to raid"] = "正在邀请玩家加入团队",
		["Converting to raid for 6th player"] = "队伍已满，转为团队以邀请更多玩家",
		[" kicked from party/raid (blacklisted)"] = " 已被踢出队伍/团队（黑名单）",
		["Blacklist check disabled"] = "黑名单检查已禁用",
		["Blacklist check enabled"] = "黑名单检查已启用",
		["No blacklisted players found"] = "未发现黑名单玩家",
		["Found blacklisted players: "] = "发现黑名单玩家：",
		["SI_Global structure not found"] = "未找到SI_Global结构",
		["No blacklist data available"] = "无黑名单数据可用",
	}
end)

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_Invite = Automaton:NewModule("Invite")
Automaton_Invite.modulename = L["Invite"]
Automaton_Invite.moduledesc = L["Options for sending out party invites."]
Automaton_Invite.options = {
	inviteString = {
		type = "text",
		name = L["Invite text"],
		desc = L["The text users send to trigger an invite."],
		order = 3,
		usage = L["keyword invite"],
		get = function()
			return Automaton_Invite.db.profile.inviteString
		end,
		set = function(v)
			Automaton_Invite.db.profile.inviteString = v
		end,
	},
	ignoreCase = {
		type = "toggle",
		name = L["Ignore case"],
		desc = L["Disable case sensitivity for the invite text"],
		order = 2,
		get = function()
			return Automaton_Invite.db.profile.ignoreCase
		end,
		set = function(v)
			Automaton_Invite.db.profile.ignoreCase = v
		end,
	},
	isguild = {
		type = "toggle",
		name = "支持工会频道",
		desc = "工会频道关键字识别也会邀请进组",
		order = 2,
		get = function()
			return Automaton_Invite.db.profile.isguild
		end,
		set = function(v)
			Automaton_Invite.db.profile.isguild = v
		end,
	},
	autoRaid = {
		type = "toggle",
		name = L["Auto turn raid"],
		desc = L["Turn Raid when your team more than 5 person"],
		order = 5,
		get = function()
			return Automaton_Invite.db.profile.autoRaid
		end,
		set = function(v)
			Automaton_Invite.db.profile.autoRaid = v
		end,
	},
	kickBlacklist = {
		type = "toggle",
		name = L["Auto kick blacklist"],
		desc = L["Automatically kick blacklisted players from party/raid"],
		order = 6,
		get = function()
			return Automaton_Invite.db.profile.kickBlacklist
		end,
		set = function(v)
			Automaton_Invite.db.profile.kickBlacklist = v
		end,
	},
	kickInterval = {
		type = "range",
		name = L["Kick interval"],
		desc = L["Interval in seconds to check for blacklisted players"],
		order = 7,
		min = 1,
		max = 60,
		step = 1,
		get = function()
			return Automaton_Invite.db.profile.kickInterval
		end,
		set = function(v)
			Automaton_Invite.db.profile.kickInterval = v
		end,
		disabled = function()
			return not Automaton_Invite.db.profile.kickBlacklist
		end,
	},
	blacklistSource = {
		type = "text",
		name = L["Blacklist source"],
		desc = L["Choose where to get blacklist from"],
		order = 8,
		validate = { "SI_Global", "Ignore list", "Both" },
		get = function()
			return Automaton_Invite.db.profile.blacklistSource
		end,
		set = function(v)
			Automaton_Invite.db.profile.blacklistSource = v
		end,
		disabled = function()
			return not Automaton_Invite.db.profile.kickBlacklist
		end,
	},
	debugBlacklist = {
		type = "execute",
		name = L["Debug blacklist"],
		desc = L["Print debug information about blacklist"],
		order = 9,
		func = function()
			Automaton_Invite:DebugBlacklist()
		end,
		disabled = function()
			return not Automaton_Invite.db.profile.kickBlacklist
		end,
	},
	accept = {
		type = "group",
		name = L["Accept from"],
		desc = L["Accept invites from these people"],
		order = 4,
		args = {
			friends = {
				type = "toggle",
				name = L["Friends"],
				desc = L["Allow invite requests from players on your friends list"],
				order = 2,
				get = function()
					return Automaton_Invite.db.profile.friends
				end,
				set = function(v)
					Automaton_Invite.db.profile.friends = v
				end,
				disabled = function()
					if Automaton_Invite.db.profile.anyone then
						return true
					end
				end,
			},
			guild = {
				type = "toggle",
				name = L["Guildmates"],
				desc = L["Allow invite requests from guildmates"],
				order = 3,
				get = function()
					return Automaton_Invite.db.profile.guild
				end,
				set = function(v)
					Automaton_Invite.db.profile.guild = v
				end,
				disabled = function()
					if Automaton_Invite.db.profile.anyone then
						return true
					end
				end,
			},
			custom = {
				type = "group",
				name = L["Custom list"],
				desc = L["Specify a custom list to accept from"],
				order = 20,
				disabled = function()
					if Automaton_Invite.db.profile.anyone then
						return true
					end
				end,
				args = {
					list = {
						type = "execute",
						name = L["List"],
						desc = L["Print all names in the custom list."],
						func = function()
							Automaton_Invite:ListCustom()
						end,
					},
					add = {
						type = "text",
						name = L["Add Player"],
						desc = L["Add a player to the custom list."],
						order = 1,
						usage = L["<player name>"],
						get = false,
						set = function(v)
							Automaton_Invite:AddCustomName(v)
						end,
					},
					remove = {
						type = "text",
						name = L["Remove Player"],
						desc = L["Removes a player from the custom list."],
						order = 2,
						usage = L["<player name>"],
						get = false,
						set = function(v)
							Automaton_Invite:RemoveCustomName(v)
						end,
					},
					purge = {
						type = "execute",
						name = L["Purge"],
						desc = L["Remove all names from the custom list."],
						func = function()
							Automaton_Invite:PurgeCustomList()
						end,
					},
				},
			},
			anyone = {
				type = "toggle",
				name = L["Everyone"],
				desc = L["Allow invite requests from everyone"],
				order = 1,
				get = function()
					return Automaton_Invite.db.profile.anyone
				end,
				set = function(v)
					Automaton_Invite.db.profile.anyone = v
					Automaton_Invite.options.accept.args.friends.disabled = v
					Automaton_Invite.options.accept.args.guild.disabled = v
					Automaton_Invite.options.accept.args.custom.disabled = v
				end,
			},
		},
	},
}

------------------------------
--      Initialization      --
------------------------------

function Automaton_Invite:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("Invite")
	Automaton:RegisterDefaults("Invite", "profile", {
		disabled = false,
		inviteString = "invite",
		ignoreCase = true,
		friends = true,
		guild = true,
		isguild = false,
		autoRaid = true,
		kickBlacklist = true,
		kickInterval = 5,
		blacklistSource = "Both",
		custom = {},
	})
	Automaton:SetDisabledAsDefault(self, "Invite")

	self:RegisterOptions(self.options)

	-- 初始化黑名单检查相关变量
	self.lastKickCheck = 0
	self.kickFrame = CreateFrame("Frame")
end

function Automaton_Invite:OnEnable()
	self:RegisterEvent("CHAT_MSG_WHISPER")
	self:RegisterEvent("CHAT_MSG_GUILD")

	-- 设置黑名单检查的OnUpdate脚本
	self.kickFrame:SetScript("OnUpdate", function()
		Automaton_Invite:OnUpdateKickCheck()
	end)
end

function Automaton_Invite:OnDisable()
	self:UnregisterAllEvents()

	-- 移除黑名单检查的OnUpdate脚本
	self.kickFrame:SetScript("OnUpdate", nil)
end

------------------------------
--      Blacklist Functions --
------------------------------

-- 获取当前服务器的SI_Global黑名单
function Automaton_Invite:GetServerBlacklist()
	local blacklist = {}
	local currentRealm = GetRealmName()

	if
		SI_Global
		and SI_Global.DataByRealm
		and SI_Global.DataByRealm[currentRealm]
		and SI_Global.DataByRealm[currentRealm].BannedPlayers
	then
		local bannedPlayers = SI_Global.DataByRealm[currentRealm].BannedPlayers

		for _, bannedEntry in ipairs(bannedPlayers) do
			local playerName = bannedEntry[1]
			if playerName and playerName ~= "" then
				blacklist[playerName] = true
			end
		end
	end

	return blacklist
end

-- 获取游戏内忽略列表
function Automaton_Invite:GetIgnoreBlacklist()
	local blacklist = {}
	local numIgnores = GetNumIgnores()

	for i = 1, numIgnores do
		local name = GetIgnoreName(i)
		if name and name ~= "" then
			blacklist[name] = true
		end
	end

	return blacklist
end

-- 根据设置获取黑名单
function Automaton_Invite:GetAllBlacklist()
	local blacklist = {}
	local source = self.db.profile.blacklistSource

	if source == "SI_Global" or source == "Both" then
		local serverBlacklist = self:GetServerBlacklist()
		for name, _ in pairs(serverBlacklist) do
			blacklist[name] = true
		end
	end

	if source == "Ignore list" or source == "Both" then
		local ignoreBlacklist = self:GetIgnoreBlacklist()
		for name, _ in pairs(ignoreBlacklist) do
			blacklist[name] = true
		end
	end

	return blacklist
end

-- 执行黑名单检查
function Automaton_Invite:DoKickCheck()
	-- 快速失败条件
	if not self.db.profile.kickBlacklist then
		return
	end
	if not UnitIsPartyLeader("player") then
		return
	end

	-- 获取黑名单
	local blacklist = self:GetAllBlacklist()
	local ignoreCount = 0

	-- 计算黑名单数量
	for _ in pairs(blacklist) do
		ignoreCount = ignoreCount + 1
	end

	if ignoreCount == 0 then
		return
	end

	-- 确定队伍类型
	local isRaid = UnitInRaid("player")
	local unitPrefix = isRaid and "raid" or "party"
	local maxUnits = isRaid and 40 or 4

	-- 检查队伍中是否有黑名单玩家
	for i = 1, maxUnits do
		local unit = unitPrefix .. i
		if UnitExists(unit) then
			local name = UnitName(unit)
			if name and blacklist[name] then
				-- 发现黑名单玩家，踢出并移除标记
				UninviteByName(name)
				self:print("|cFFFF0000[自动踢出]|r: " .. name .. L[" kicked from party/raid (blacklisted)"])
				blacklist[name] = nil
				ignoreCount = ignoreCount - 1

				-- 如果所有黑名单玩家都已检查完毕，提前退出
				if ignoreCount == 0 then
					return
				end
			end
		end
	end
end

-- OnUpdate回调，定时检查黑名单
function Automaton_Invite:OnUpdateKickCheck()
	if not self.db.profile.kickBlacklist then
		return
	end

	local currentTime = GetTime()
	if currentTime - self.lastKickCheck >= self.db.profile.kickInterval then
		self.lastKickCheck = currentTime
		self:DoKickCheck()
	end
end

-- 调试黑名单功能
function Automaton_Invite:DebugBlacklist()
	local blacklist = self:GetAllBlacklist()
	local count = 0
	for _ in pairs(blacklist) do
		count = count + 1
	end

	local currentRealm = GetRealmName()
	local serverBlacklist = self:GetServerBlacklist()
	local serverCount = 0
	for _ in pairs(serverBlacklist) do
		serverCount = serverCount + 1
	end

	local ignoreBlacklist = self:GetIgnoreBlacklist()
	local ignoreCount = 0
	for _ in pairs(ignoreBlacklist) do
		ignoreCount = ignoreCount + 1
	end

	self:print("=== 黑名单调试信息 ===")
	self:print("当前服务器: " .. currentRealm)
	self:print("黑名单来源: " .. self.db.profile.blacklistSource)
	self:print("总黑名单数: " .. count)
	self:print("SI_Global黑名单数: " .. serverCount)
	self:print("游戏忽略列表数: " .. ignoreCount)

	if SI_Global and SI_Global.DataByRealm then
		if SI_Global.DataByRealm[currentRealm] then
			self:print("找到服务器数据")
			if SI_Global.DataByRealm[currentRealm].BannedPlayers then
				local bannedPlayers = SI_Global.DataByRealm[currentRealm].BannedPlayers
				self:print("SI_Global黑名单列表:")
				for i, entry in ipairs(bannedPlayers) do
					self:print("  [" .. i .. "] " .. entry[1] .. " (封禁至: " .. tostring(entry[2]) .. ")")
				end
			else
				self:print("没有找到BannedPlayers")
			end
		else
			self:print("没有找到该服务器的数据")
		end
	else
		self:print("SI_Global未找到或结构不正确")
	end
end

------------------------------
--      Event Handlers      --
------------------------------

function Automaton_Invite:ConvertToRaidIfNeeded()
	-- 检查是否是队长
	if not UnitIsPartyLeader("player") then
		return false
	end

	-- 获取队伍人数（包括自己）
	local numPartyMembers = GetNumPartyMembers()

	-- 如果已经是团队，不需要转换
	if GetNumRaidMembers() > 0 then
		return true
	end

	-- 如果队伍人数达到5人且不是团队，则转为团队
	if numPartyMembers >= 4 and GetNumRaidMembers() == 0 then
		ConvertToRaid()
		self:print(L["Automatically converted to Raid"])
		return true
	end

	return false
end

-- 判断玩家是否拥有邀请权限（队长或团队助理）
-- 单人时拥有权限；小队中只有队长；团队中团长(rank=2)或助理(rank=1)拥有权限
function Automaton_Invite:HasInviteAuthority()
	-- 如果独自一人，拥有权限
	if GetNumPartyMembers() == 0 and GetNumRaidMembers() == 0 then
		return true
	end

	-- 在团队中：团长(rank=2)或助理(rank=1)拥有权限
	if GetNumRaidMembers() > 0 then
		local name = UnitName("player")
		for i = 1, GetNumRaidMembers() do
			local raidName, rank = GetRaidRosterInfo(i)
			if raidName == name then
				return (rank == 1 or rank == 2)
			end
		end
		return false
	end

	-- 在小队中：队长拥有权限
	return UnitIsPartyLeader("player")
end

function Automaton_Invite:CanInviteMorePlayers()
	-- 获取当前队伍状态
	local numPartyMembers = GetNumPartyMembers()
	local numRaidMembers = GetNumRaidMembers()

	-- 如果独自一人，可以邀请
	if numPartyMembers == 0 and numRaidMembers == 0 then
		return true, "可以邀请"
	end

	-- 检查是否有邀请权限（队长或团队助理）
	if not self:HasInviteAuthority() then
		return false, L[",you are not leader"]
	end

	-- 检查团队状态
	if numRaidMembers > 0 then
		-- 在团队中，检查是否满员（40人）
		if numRaidMembers >= 40 then
			return false, L[",Raid is full."]
		else
			return true, L["Inviting to raid"]
		end
	else
		-- 在小队中，检查是否满员（5人）
		if numPartyMembers >= 4 then
			-- 小队已满，但我们可以转为团队来邀请更多人
			return true, L["Converting to raid for 6th player"]
		else
			return true, "可以邀请"
		end
	end
end

function Automaton_Invite:ProcessInviteRequest(text, from)
	local keyword, msg
	local player = from
	local keyword = Automaton_Invite.db.profile.inviteString
	local msg = text
	if Automaton_Invite.db.profile.ignoreCase then
		keyword = string.lower(keyword)
		msg = string.lower(msg)
	end
	if string.find(msg, format("^%s$", keyword)) then
		-- 检查是否可以邀请更多玩家
		local canInvite, reason = self:CanInviteMorePlayers()
		if not canInvite then
			self:print(player .. reason)
			return
		end

		-- 如果需要转为团队（小队已满且不是团队）
		local numPartyMembers = GetNumPartyMembers()
		local numRaidMembers = GetNumRaidMembers()
		if self.db.profile.autoRaid and numPartyMembers >= 4 and numRaidMembers == 0 then
			self:ConvertToRaidIfNeeded()
		end

		if not self.db.profile.anyone then
			local acceptFrom = {}
			if self.db.profile.guild then
				GuildRoster()
				for i = 1, GetNumGuildMembers() do
					local name = GetGuildRosterInfo(i)
					tinsert(acceptFrom, name)
				end
			end
			if self.db.profile.friends then
				for i = 1, GetNumFriends() do
					local name = GetFriendInfo(i)
					tinsert(acceptFrom, name)
				end
			end
			if not (table.getn(self.db.profile.custom) == 0) then
				for k, v in pairs(self.db.profile.custom) do
					tinsert(acceptFrom, v)
				end
			end

			if foreachi(acceptFrom, function(i, v)
				if v == player then
					return true
				end
			end) then
				InviteByName(player)
			end
		else
			InviteByName(player)
		end
	end
end

function Automaton_Invite:CHAT_MSG_WHISPER(text, from)
	self:ProcessInviteRequest(text, from)
end

function Automaton_Invite:CHAT_MSG_GUILD(text, from)
	if not self.db.profile.isguild then
		return
	end
	self:ProcessInviteRequest(text, from)
end

function Automaton_Invite:AddCustomName(name)
	tinsert(self.db.profile.custom, string.lower(name))
end

function Automaton_Invite:RemoveCustomName(name)
	-- 修复数组删除问题，避免使用nil值
	local newCustom = {}
	for k, v in pairs(self.db.profile.custom) do
		if v ~= string.lower(name) then
			tinsert(newCustom, v)
		end
	end
	self.db.profile.custom = newCustom
end

function Automaton_Invite:ListCustom()
	if table.getn(self.db.profile.custom) == 0 then
		self:print("当前列表为空")
	else
		self:print("接受这些玩家的邀请:")
		for k, v in pairs(self.db.profile.custom) do
			self:print(v)
		end
	end
end

function Automaton_Invite:PurgeCustomList()
	self:print(table.getn(self.db.profile.custom) .. " 项已清除")
	self.db.profile.custom = {}
end
