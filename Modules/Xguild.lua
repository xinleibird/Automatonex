assert(Automaton, "Automaton not found!")

------------------------------
--      Are you local?      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_XGuild")

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function()
	return {
		["XGuild"] = "彩色列表",
		["Color guild, whois and friends lists"] = "为公会、查询和好友列表着色",
		["Color Guild List"] = "彩色公会列表",
		["Enable color for guild list"] = "启用公会列表彩色显示",
		["Color WhoIs List"] = "彩色查询列表",
		["Enable color for whois list"] = "启用查询列表彩色显示",
		["Color Friends List"] = "彩色好友列表",
		["Enable color for friends list"] = "启用好友列表彩色显示",
	}
end)

L:RegisterTranslations("zhCN", function()
	return {
		["XGuild"] = "彩色列表",
		["Color guild, whois and friends lists"] = "为公会、查询和好友列表着色",
		["Color Guild List"] = "彩色公会列表",
		["Enable color for guild list"] = "启用公会列表彩色显示",
		["Color WhoIs List"] = "彩色查询列表",
		["Enable color for whois list"] = "启用查询列表彩色显示",
		["Color Friends List"] = "彩色好友列表",
		["Enable color for friends list"] = "启用好友列表彩色显示",
	}
end)

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_XGuild = Automaton:NewModule("XGuild")
Automaton_XGuild.modulename = L["XGuild"]
Automaton_XGuild.moduledesc = L["Color guild, whois and friends lists"]

-- 保存原始函数引用
local oldGuildStatus_Update, oldWhoList_Update, oldFriendsList_Update

-- 职业本地化字符串
local XGUILD_LOC_CLASS_WARRIOR = "Warrior"
local XGUILD_LOC_CLASS_MAGE = "Mage"
local XGUILD_LOC_CLASS_ROGUE = "Rogue"
local XGUILD_LOC_CLASS_DRUID = "Druid"
local XGUILD_LOC_CLASS_HUNTER = "Hunter"
local XGUILD_LOC_CLASS_SHAMAN = "Shaman"
local XGUILD_LOC_CLASS_PRIEST = "Priest"
local XGUILD_LOC_CLASS_WARLOCK = "Warlock"
local XGUILD_LOC_CLASS_PALADIN = "Paladin"

if GetLocale() == "zhCN" then
	XGUILD_LOC_CLASS_DRUID = "德鲁伊"
	XGUILD_LOC_CLASS_HUNTER = "猎人"
	XGUILD_LOC_CLASS_MAGE = "法师"
	XGUILD_LOC_CLASS_PALADIN = "圣骑士"
	XGUILD_LOC_CLASS_PRIEST = "牧师"
	XGUILD_LOC_CLASS_ROGUE = "盗贼"
	XGUILD_LOC_CLASS_SHAMAN = "萨满祭司"
	XGUILD_LOC_CLASS_WARLOCK = "术士"
	XGUILD_LOC_CLASS_WARRIOR = "战士"
end

local colourList = {
	[XGUILD_LOC_CLASS_WARRIOR] = "WARRIOR",
	[XGUILD_LOC_CLASS_MAGE] = "MAGE",
	[XGUILD_LOC_CLASS_ROGUE] = "ROGUE",
	[XGUILD_LOC_CLASS_DRUID] = "DRUID",
	[XGUILD_LOC_CLASS_HUNTER] = "HUNTER",
	[XGUILD_LOC_CLASS_SHAMAN] = "SHAMAN",
	[XGUILD_LOC_CLASS_PRIEST] = "PRIEST",
	[XGUILD_LOC_CLASS_WARLOCK] = "WARLOCK",
	[XGUILD_LOC_CLASS_PALADIN] = "PALADIN",
}

------------------------------
--      Module Options       --
------------------------------

Automaton_XGuild.options = {
	colorGuild = {
		type = "toggle",
		name = L["Color Guild List"],
		desc = L["Enable color for guild list"],
		order = 2,
		get = function()
			return Automaton_XGuild.db.profile.colorGuild
		end,
		set = function(v)
			Automaton_XGuild.db.profile.colorGuild = v
			Automaton_XGuild:UpdateGuildListHook(v)
		end,
	},
	colorWhoIs = {
		type = "toggle",
		name = L["Color WhoIs List"],
		desc = L["Enable color for whois list"],
		order = 3,
		get = function()
			return Automaton_XGuild.db.profile.colorWhoIs
		end,
		set = function(v)
			Automaton_XGuild.db.profile.colorWhoIs = v
			Automaton_XGuild:UpdateWhoListHook(v)
		end,
	},
	colorFriends = {
		type = "toggle",
		name = L["Color Friends List"],
		desc = L["Enable color for friends list"],
		order = 4,
		get = function()
			return Automaton_XGuild.db.profile.colorFriends
		end,
		set = function(v)
			Automaton_XGuild.db.profile.colorFriends = v
			Automaton_XGuild:UpdateFriendsListHook(v)
		end,
	},
}

------------------------------
--      Initialization      --
------------------------------

function Automaton_XGuild:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("XGuild")
	Automaton:RegisterDefaults("XGuild", "profile", {
		colorGuild = true,
		colorWhoIs = true,
		colorFriends = true,
		disabled = false,
	})
	Automaton:SetDisabledAsDefault(self, "XGuild")
	self:RegisterOptions(self.options)
end

function Automaton_XGuild:OnEnable()
	-- 应用保存的设置
	if self.db.profile.colorGuild then
		self:UpdateGuildListHook(true)
	end
	if self.db.profile.colorWhoIs then
		self:UpdateWhoListHook(true)
	end
	if self.db.profile.colorFriends then
		self:UpdateFriendsListHook(true)
	end
end

function Automaton_XGuild:OnDisable()
	-- 恢复原始函数
	self:UpdateGuildListHook(false)
	self:UpdateWhoListHook(false)
	self:UpdateFriendsListHook(false)
end

------------------------------
--      Hook Management      --
------------------------------

function Automaton_XGuild:UpdateGuildListHook(enable)
	if enable and not oldGuildStatus_Update then
		oldGuildStatus_Update = GuildStatus_Update
		GuildStatus_Update = function()
			Automaton_XGuild:XGuild_GuildStatusUpdate()
		end
	elseif not enable and oldGuildStatus_Update then
		GuildStatus_Update = oldGuildStatus_Update
		oldGuildStatus_Update = nil
	end
end

function Automaton_XGuild:UpdateWhoListHook(enable)
	if enable and not oldWhoList_Update then
		oldWhoList_Update = WhoList_Update
		WhoList_Update = function()
			Automaton_XGuild:XGuild_WhoList_Update()
		end
	elseif not enable and oldWhoList_Update then
		WhoList_Update = oldWhoList_Update
		oldWhoList_Update = nil
	end
end

function Automaton_XGuild:UpdateFriendsListHook(enable)
	if enable and not oldFriendsList_Update then
		oldFriendsList_Update = FriendsList_Update
		FriendsList_Update = function()
			Automaton_XGuild:XGuild_FriendsList_Update()
		end
	elseif not enable and oldFriendsList_Update then
		FriendsList_Update = oldFriendsList_Update
		oldFriendsList_Update = nil
	end
end

------------------------------
--      Original Functions      --
------------------------------

-- 公会等级着色
function Automaton_XGuild:XGuild_ColorGuildRank(rankIndex)
	local red = RED_FONT_COLOR -- 1.0, 0.10, 0.1
	local yellow = NORMAL_FONT_COLOR -- 1.0, 0.82, 0.0
	local green = GREEN_FONT_COLOR -- 0.1, 1.00, 0.1
	local nRanks = GuildControlGetNumRanks()
	local pct = ((rankIndex * 100) / nRanks) / 100
	local r, g, b

	if rankIndex == 0 then
		r = red.r
		g = red.g
		b = red.b
	elseif rankIndex == (nRanks / 2) then
		r = yellow.r
		g = yellow.g
		b = yellow.b
	elseif rankIndex == nRanks then
		r = green.r
		g = green.g
		b = green.b
	elseif rankIndex > (nRanks / 2) then
		local pctmod = (1.0 - pct) * 2
		r = (yellow.r - green.r) * pctmod + green.r
		g = (yellow.g - green.g) * pctmod + green.g
		b = (yellow.b - green.b) * pctmod + green.b
	elseif rankIndex < (nRanks / 2) then
		local pctmod = (0.5 - pct) * 2
		r = (red.r - yellow.r) * pctmod + yellow.r
		g = (red.g - yellow.g) * pctmod + yellow.g
		b = (red.b - yellow.b) * pctmod + yellow.b
	end

	return r, g, b
end

-- 获取职业颜色
function Automaton_XGuild:XGuild_GetClassColour(class)
	if class then
		local color = RAID_CLASS_COLORS[class]
		if color then
			return color
		end
	end
	return { r = 0.5, g = 0.5, b = 1 }
end

-- 公会列表更新
function Automaton_XGuild:XGuild_GuildStatusUpdate()
	oldGuildStatus_Update()

	local myZone = GetRealZoneText()
	local guildOffset = FauxScrollFrame_GetOffset(GuildListScrollFrame)

	for i = 1, GUILDMEMBERS_TO_DISPLAY, 1 do
		local guildIndex = guildOffset + i
		local button = getglobal("GuildFrameButton" .. i)
		button.guildIndex = guildIndex
		local name, rank, rankIndex, level, class, zone, note, officernote, online = GetGuildRosterInfo(guildIndex)
		if not name then
			break
		end

		class = colourList[class]

		if class then
			local color = self:XGuild_GetClassColour(class)
			if color then
				if online then
					getglobal("GuildFrameButton" .. i .. "Class"):SetTextColor(color.r, color.g, color.b)
					getglobal("GuildFrameButton" .. i .. "Name"):SetTextColor(color.r, color.g, color.b)
					getglobal("GuildFrameGuildStatusButton" .. i .. "Name"):SetTextColor(color.r, color.g, color.b)
				else
					getglobal("GuildFrameButton" .. i .. "Class"):SetTextColor(color.r / 2, color.g / 2, color.b / 2)
					getglobal("GuildFrameButton" .. i .. "Name"):SetTextColor(color.r / 2, color.g / 2, color.b / 2)
					getglobal("GuildFrameGuildStatusButton" .. i .. "Name"):SetTextColor(
						color.r / 2,
						color.g / 2,
						color.b / 2
					)
				end
			end
		end

		local r, g, b = self:XGuild_ColorGuildRank(rankIndex)
		if rank then
			if online then
				getglobal("GuildFrameGuildStatusButton" .. i .. "Rank"):SetTextColor(r, g, b)
			else
				getglobal("GuildFrameGuildStatusButton" .. i .. "Rank"):SetTextColor(r / 2, g / 2, b / 2)
			end
		end

		if note then
			getglobal("GuildFrameGuildStatusButton" .. i .. "Note"):SetTextColor(0.54, 0.54, 0.54)
		end

		if zone == myZone then
			if online then
				getglobal("GuildFrameButton" .. i .. "Zone"):SetTextColor(0, 1, 0)
			else
				getglobal("GuildFrameButton" .. i .. "Zone"):SetTextColor(0, 0.5, 0)
			end
		end

		local color = GetDifficultyColor(level)
		if online then
			getglobal("GuildFrameButton" .. i .. "Level"):SetTextColor(color.r, color.g, color.b)
		else
			getglobal("GuildFrameButton" .. i .. "Level"):SetTextColor(color.r / 2, color.g / 2, color.b / 2)
		end
	end
end

-- Who列表更新
function Automaton_XGuild:XGuild_WhoList_Update()
	oldWhoList_Update()

	local numWhos, totalCount = GetNumWhoResults()
	local whoOffset = FauxScrollFrame_GetOffset(WhoListScrollFrame)
	local myZone = GetRealZoneText()
	local myRace = UnitRace("player")
	local myGuild = GetGuildInfo("player")

	for i = 1, WHOS_TO_DISPLAY, 1 do
		local name, guild, level, race, class, zone = GetWhoInfo(whoOffset + i)
		if not name then
			break
		end

		if UIDropDownMenu_GetSelectedID(WhoFrameDropDown) == 1 then
			-- 区域匹配
			if zone == myZone then
				getglobal("WhoFrameButton" .. i .. "Variable"):SetTextColor(0, 1, 0)
			else
				getglobal("WhoFrameButton" .. i .. "Variable"):SetTextColor(1, 1, 1)
			end
		elseif UIDropDownMenu_GetSelectedID(WhoFrameDropDown) == 2 then
			-- 公会匹配
			if guild == myGuild then
				getglobal("WhoFrameButton" .. i .. "Variable"):SetTextColor(0, 1, 0)
			else
				getglobal("WhoFrameButton" .. i .. "Variable"):SetTextColor(1, 1, 1)
			end
		elseif UIDropDownMenu_GetSelectedID(WhoFrameDropDown) == 3 then
			-- 种族匹配
			if race == myRace then
				getglobal("WhoFrameButton" .. i .. "Variable"):SetTextColor(0, 1, 0)
			else
				getglobal("WhoFrameButton" .. i .. "Variable"):SetTextColor(1, 1, 1)
			end
		end

		class = colourList[class]
		if class then
			local color = self:XGuild_GetClassColour(class)
			if color then
				getglobal("WhoFrameButton" .. i .. "Class"):SetTextColor(color.r, color.g, color.b)
				getglobal("WhoFrameButton" .. i .. "Name"):SetTextColor(color.r, color.g, color.b)
			end
		end

		local color = GetDifficultyColor(level)
		getglobal("WhoFrameButton" .. i .. "Level"):SetTextColor(color.r, color.g, color.b)
	end
end

-- 好友列表更新
function Automaton_XGuild:XGuild_FriendsList_Update()
	oldFriendsList_Update()

	local numFriends = GetNumFriends()
	local friendOffset = FauxScrollFrame_GetOffset(FriendsFrameFriendsScrollFrame)
	local myZone = GetRealZoneText()

	for i = 1, FRIENDS_TO_DISPLAY, 1 do
		local name, level, class, zone, online = GetFriendInfo(friendOffset + i)
		if not name then
			break
		end

		local nameLocationText = getglobal("FriendsFrameFriendButton" .. i .. "ButtonTextNameLocation")
		local infoText = getglobal("FriendsFrameFriendButton" .. i .. "ButtonTextInfo")

		if online then
			if zone == myZone then
				infoText:SetTextColor(0, 1, 0)
			else
				infoText:SetTextColor(1, 1, 1)
			end

			class = colourList[class]
			if class then
				local color = self:XGuild_GetClassColour(class)
				if color then
					nameLocationText:SetTextColor(color.r, color.g, color.b)
				end
			end
		else
			infoText:SetTextColor(0.5, 0.5, 0.5)
		end
	end
end
