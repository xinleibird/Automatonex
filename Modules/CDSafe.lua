assert(Automaton, "Automaton not found!")

----------------------------------
--      Module Declaration      --
----------------------------------
Automaton_CDSafe = Automaton:NewModule("CDSafe")
Automaton_CDSafe.modulename = "副本进度安全提示"
Automaton_CDSafe.moduledesc = "在副本门口检测团长和自身的副本锁定状态，避免误黑进度"

-- 选项定义
Automaton_CDSafe.options = {
	showPanel = {
		type = "execute",
		name = "打开状态面板",
		desc = "显示副本进度状态面板",
		func = function()
			Automaton_CDSafe:ShowPanel()
		end,
	},
}

------------------------------
--      Constants & Data    --
------------------------------
local ADDON_PREFIX = "CDSafe"
local BROADCAST_INTERVAL = 90
local REQUEST_INTERVAL = 20
local LEADER_SYNC_TIMEOUT = 5
local LEADER_SYNC_REQUEST_JITTER_MIN = 1
local LEADER_SYNC_REQUEST_JITTER_MAX = 3
local RAID_INFO_REQUEST_INTERVAL = 30

-- 本地化字符串（中文硬编码）
local L = {
	STATUS_LOCKED = "已锁定",
	STATUS_OPEN = "未锁定",
	STATUS_UNKNOWN = "未知",
	UNKNOWN = "未知",
	YOU = "你",
	PLAYER = "玩家",
	LEADER = "团长",
	LEADER_DATA_SOURCE_LOCAL = "团长数据来源：本地",
	LEADER_SYNC_TIME = "团长同步时间",
	WAITING_FOR_SYNC = "等待同步...",
	NOT_IN_RAID = "不在团队中",
	PANEL_TITLE = "CDSafe - 副本锁定状态",
	HEADER_RAID = "副本",
	HEADER_LEADER = "团长",
	HEADER_YOU = "你",
	HELP_MINIMAP = "提示：通过插件配置界面打开面板。",
	MUTE_ZONE_ON = "区域屏蔽已启用：聊天和屏幕中心警报已静音。",
	MUTE_ZONE_OFF = "区域屏蔽已禁用。",
	MUTE_ZONE_AUTO_OFF = "离开屏蔽区域：警报自动恢复。",
	WARNING_LEADER_FALLBACK = "团长",
	WARNING_TEXT_TEMPLATE = "团长 [%s] 已锁定 [%s]。请不要进入，以免黑掉空CD。",
	WARNING_LEADER_UNKNOWN = "提醒：[%s] 的团长进度未知，请与团长确认。",
	WARNING_LEADER_SELF_TEMPLATE = "你已锁定 [%s]。带队前请确认，以免黑掉团员进度。",
	INFO_SAFE_ENTER_TEMPLATE = "信息：团长没有 [%s] 的锁定，你可以进入。",
	INFO_SHARED_LOCKOUT_TEMPLATE = "信息：与团长共享 [%s] 的进度，可以进入。", -- 新增
	LEADER_SYNC_TIMEOUT_TEXT = "未收到团长同步（团长可能没有安装该插件）。",
	RETRY = "重试",
	RAID_REPORT_TEMPLATE = "[CDSafe] %s | 团长(%s): %s | 你(%s): %s",
	RAID_REPORT_LEADER_ONLY_TEMPLATE = "[CDSafe] %s | 团长(%s): %s",
	RESET_MINIMAP = "小地图图标位置已重置。",
	INSTANCE_ID_LABEL = "ID",
	STATUS_WITH_ID_TEMPLATE = "%s (%s: %s)",
	TEMP_MUTE_BUTTON = "静音5m",
	TEMP_MUTE_MSG = "提醒已临时禁用 %d 分钟。",
	TEMP_MUTE_REMAINING = "提醒已静音，剩余 %d 分钟",
}

local RAID_DISPLAY = {
	moltencore = "熔火之心",
	blackwinglair = "黑翼之巢",
	zulgurub = "祖尔格拉布",
	onyxia = "奥妮克希亚的巢穴",
	aq20 = "安其拉废墟",
	aq40 = "安其拉神殿",
	naxxramas = "纳克萨玛斯",
	lowerkarazhanhalls = "卡拉赞下层大厅",
	towerofkarazhan = "卡拉赞之塔",
	emeraldsanctum = "翡翠圣地",
	timbermawhold = "木喉要塞",
}

-- 优化后的监测区域定义：移除了过于宽泛的 zone-only 规则，改用精确的 subzone 规则
local WARNING_AREAS = {
	moltencore = {
		-- 精确门口子区域：黑石深渊
		{ subzone = "Blackrock Depths" },
		{ subzone = "黑石深渊" },
		-- 以下为副本内部名称，会被自动过滤，保留无妨
		{ subzone = "Molten Core" },
		{ subzone = "熔火之心" },
	},
	blackwinglair = {
		-- 精确门口子区域：黑石塔
		{ subzone = "Blackrock Spire" },
		{ subzone = "黑石塔" },
		{ subzone = "Blackwing Lair" },
		{ subzone = "黑翼之巢" },
	},
	zulgurub = {
		{ subzone = "Zul'Gurub" },
		{ subzone = "祖尔格拉布" },
		{ zone = "Stranglethorn Vale", subzone = "Zul'Gurub" },
		{ zone = "荆棘谷", subzone = "祖尔格拉布" },
	},
	onyxia = {
		{ subzone = "Wyrmbog" },
		{ subzone = "巨龙沼泽" },
		{ subzone = "Onyxia's Lair" },
		{ subzone = "奥妮克希亚的巢穴" },
	},
	aq20 = {
		{ zone = "安其拉之门" },
		{ zone = "The Scarab Wall" },
		{ zone = "Ahn'Qiraj: The Fallen Kingdom" },
	},
	aq40 = {
		{ zone = "安其拉之门" },
		{ zone = "The Scarab Wall" },
		{ zone = "Ahn'Qiraj: The Fallen Kingdom" },
	},
	lowerkarazhanhalls = {
		{ zone = "Karazhan" },
		{ zone = "卡拉赞" },
		{ subzone = "Lower Karazhan Halls" },
		{ subzone = "卡拉赞下层大厅" },
		{ zone = "Deadwind Pass", subzone = "Karazhan" },
		{ zone = "逆风小径", subzone = "卡拉赞" },
	},
	towerofkarazhan = {
		{ zone = "Karazhan" },
		{ zone = "卡拉赞" },
		{ subzone = "Tower of Karazhan" },
		{ subzone = "卡拉赞之塔" },
		{ zone = "Deadwind Pass", subzone = "Karazhan" },
		{ zone = "逆风小径", subzone = "卡拉赞" },
	},
	emeraldsanctum = {
		{ zone = "Hyjal", subzone = "The Emerald Gateway" },
		{ zone = "海加尔山", subzone = "翡翠之门" },
	},
	naxxramas = {
		{ subzone = "Plaguewood" },
		{ subzone = "病木林" },
		{ subzone = "Naxxramas" },
		{ subzone = "纳克萨玛斯" },
	},
	timbermawhold = {
		{ subzone = "timbermawhold" },
		{ subzone = "木喉要塞" },
		{ subzone = "timbermawhold" },
		{ subzone = "木喉要塞" },
	},
}

local STATUS_LOCKED = "|cffff4040" .. L.STATUS_LOCKED .. "|r"
local STATUS_OPEN = "|cff40ff40" .. L.STATUS_OPEN .. "|r"
local STATUS_UNKNOWN = "|cffb0b0b0" .. L.STATUS_UNKNOWN .. "|r"

local RAID_DEFS = {
	{
		key = "zulgurub",
		short = "ZG",
		display = "Zul'Gurub",
		aliases = { "Zul'Gurub", "祖尔格拉布" },
		entranceSubzones = { "Zul'Gurub", "祖尔格拉布" },
	},
	{
		key = "aq20",
		short = "AQ20",
		display = "Ruins of Ahn'Qiraj",
		aliases = { "Ruins of Ahn'Qiraj", "Ahn'Qiraj Ruins", "安其拉废墟" },
		entranceSubzones = {
			"Ruins of Ahn'Qiraj",
			"安其拉废墟",
			"Ahn'Qiraj",
			"安其拉",
			"Ahn'Qiraj: The Fallen Kingdom",
			"The Scarab Wall",
			"安其拉之墙",
			"安其拉：堕落王国",
		},
	},
	{
		key = "lowerkarazhanhalls",
		short = "Kara-L",
		display = "Lower Karazhan Halls",
		aliases = { "Lower Karazhan Halls", "卡拉赞下层大厅" },
		entranceSubzones = { "Lower Karazhan Halls", "卡拉赞下层大厅", "Karazhan", "卡拉赞" },
	},
	{
		key = "moltencore",
		short = "MC",
		display = "Molten Core",
		aliases = { "Molten Core", "熔火之心" },
		entranceSubzones = {
			"Molten Core",
			"熔火之心",
			"Blackrock Depths",
			"黑石深渊",
			"Blackrock Mountain",
			"黑石山",
		},
	},
	{
		key = "blackwinglair",
		short = "BWL",
		display = "Blackwing Lair",
		aliases = { "Blackwing Lair", "黑翼之巢" },
		entranceSubzones = {
			"Blackwing Lair",
			"黑翼之巢",
			"Blackrock Spire",
			"黑石塔",
			"Blackrock Mountain",
			"黑石山",
		},
	},
	{
		key = "onyxia",
		short = "Ony",
		display = "Onyxia's Lair",
		aliases = { "Onyxia's Lair", "奥妮克希亚的巢穴" },
		entranceSubzones = { "Onyxia's Lair", "奥妮克希亚的巢穴", "Wyrmbog", "巨龙沼泽" },
	},
	{
		key = "emeraldsanctum",
		short = "ES",
		display = "Emerald Sanctum",
		aliases = { "Emerald Sanctum", "翡翠圣地" },
		entranceSubzones = { "Hyjal", "海加尔山", "The Emerald Gateway", "翡翠之门" },
	},
	{
		key = "aq40",
		short = "AQ40",
		display = "Temple of Ahn'Qiraj",
		aliases = { "Temple of Ahn'Qiraj", "Ahn'Qiraj Temple", "安其拉神殿" },
		entranceSubzones = {
			"Temple of Ahn'Qiraj",
			"安其拉神殿",
			"Ahn'Qiraj",
			"安其拉",
			"Ahn'Qiraj: The Fallen Kingdom",
			"The Scarab Wall",
			"安其拉之墙",
			"安其拉：堕落王国",
		},
	},
	{
		key = "naxxramas",
		short = "Naxx",
		display = "Naxxramas",
		aliases = { "Naxxramas", "纳克萨玛斯" },
		entranceSubzones = { "Naxxramas", "纳克萨玛斯", "Plaguewood", "病木林" },
	},
	{
		key = "towerofkarazhan",
		short = "Kara-T",
		display = "Tower of Karazhan",
		aliases = { "Tower of Karazhan", "卡拉赞之塔" },
		entranceSubzones = { "Tower of Karazhan", "卡拉赞之塔", "Karazhan", "卡拉赞" },
	},
	{
		key = "timbermawhold",
		short = "TMH",
		display = "Timbermaw Hold",
		aliases = { "Timbermaw Hold", "木喉要塞" },
		entranceSubzones = { "Timbermaw Hold", "木喉要塞", "Timbermaw Hold", "木喉要塞" },
	},
}

-- 辅助函数：table.getn兼容
local tgetn = table.getn
if not tgetn then
	tgetn = function(t)
		local n = 0
		while t[n + 1] ~= nil do
			n = n + 1
		end
		return n
	end
end

local function NormalizeText(text)
	if not text or text == "" then
		return ""
	end
	text = string.lower(text)
	text = string.gsub(text, "%s+", "")
	text = string.gsub(text, "[%p%c]", "")
	return text
end

local function StripRealm(name)
	if not name then
		return nil
	end
	local dash = string.find(name, "-", 1, true)
	if not dash then
		return name
	end
	return string.sub(name, 1, dash - 1)
end

local function NormalizePlayerName(name)
	return NormalizeText(StripRealm(name))
end

local function GetRaidDisplayName(def)
	if def and RAID_DISPLAY[def.key] then
		return RAID_DISPLAY[def.key]
	end
	return def and def.display or ""
end

-- 构建别名查找表
local RAID_DEF_BY_KEY = {}
local RAID_ALIAS_TO_KEY = {}
local WARNING_AREA_RULES = {}
local RAID_SELF_AREA_NAME_SET = {}

local function AddKeyToLookup(lookup, text, key)
	local normalized = NormalizeText(text)
	if normalized == "" then
		return
	end
	lookup[normalized] = key
end

local function AddNameToSet(set, text)
	local normalized = NormalizeText(text)
	if normalized == "" then
		return
	end
	set[normalized] = true
end

for i = 1, tgetn(RAID_DEFS) do
	local def = RAID_DEFS[i]
	RAID_DEF_BY_KEY[def.key] = def
	AddKeyToLookup(RAID_ALIAS_TO_KEY, def.key, def.key)
	AddKeyToLookup(RAID_ALIAS_TO_KEY, def.display, def.key)
	AddKeyToLookup(RAID_ALIAS_TO_KEY, def.short, def.key)
	for j = 1, tgetn(def.aliases or {}) do
		AddKeyToLookup(RAID_ALIAS_TO_KEY, def.aliases[j], def.key)
	end
	local selfNames = {}
	AddNameToSet(selfNames, def.display)
	AddNameToSet(selfNames, GetRaidDisplayName(def))
	for j = 1, tgetn(def.aliases or {}) do
		AddNameToSet(selfNames, def.aliases[j])
	end
	RAID_SELF_AREA_NAME_SET[def.key] = selfNames
end

local function AddWarningAreaRule(raidKey, zoneText, subzoneText)
	local zone = NormalizeText(zoneText)
	local subzone = NormalizeText(subzoneText)
	if zone == "" and subzone == "" then
		return
	end
	table.insert(WARNING_AREA_RULES, { key = raidKey, zone = zone, subzone = subzone })
end

local function IsRaidSelfAreaRule(raidKey, zoneText, subzoneText)
	local selfNames = RAID_SELF_AREA_NAME_SET[raidKey]
	if not selfNames then
		return false
	end
	local zone = NormalizeText(zoneText)
	local subzone = NormalizeText(subzoneText)
	local hasZone = zone ~= ""
	local hasSubzone = subzone ~= ""
	if (not hasZone) and not hasSubzone then
		return false
	end
	local zoneIsSelf = hasZone and selfNames[zone] and true or false
	local subzoneIsSelf = hasSubzone and selfNames[subzone] and true or false
	if hasZone and hasSubzone then
		return zoneIsSelf and subzoneIsSelf
	end
	if hasZone then
		return zoneIsSelf
	end
	return subzoneIsSelf
end

for raidKey, areaList in pairs(WARNING_AREAS) do
	if RAID_DEF_BY_KEY[raidKey] and type(areaList) == "table" then
		for i = 1, tgetn(areaList) do
			local area = areaList[i]
			if type(area) == "table" then
				if not IsRaidSelfAreaRule(raidKey, area.zone, area.subzone) then
					AddWarningAreaRule(raidKey, area.zone, area.subzone)
				end
			end
		end
	end
end

------------------------------
--      Module Methods      --
------------------------------
function Automaton_CDSafe:OnInitialize()
	self.db = AutomatonDB or {}
	self.db.profile = self.db.profile or {}
	-- 小地图相关已移除，不再初始化角度

	self:RegisterOptions(self.options)

	-- 初始化状态
	self.state = {
		playerName = "",
		inRaid = false,
		isLeader = false,
		leaderName = nil,
		savedRaidKeys = {},
		savedRaidNames = {},
		savedRaidNameByKey = {},
		savedRaidInstanceIdByKey = {},
		savedHash = "",
		leaderRaidKeys = nil,
		leaderRaidNameByKey = nil,
		leaderRaidInstanceIdByKey = nil,
		leaderSyncAt = nil,
		leaderSyncAttemptStartAt = nil,
		leaderSyncTimedOut = false,
		leaderSyncRequestDueAt = nil,
		leaderSyncRequestSent = false,
		lastBroadcastAt = 0,
		lastRequestAt = 0,
		lastRaidInfoRequestAt = 0,
		nextZoneCheckAt = 0,
		activeCenterWarningText = nil,
		activeCenterWarningR = nil,
		activeCenterWarningG = nil,
		activeCenterWarningB = nil,
		mutedWarningZoneSignature = nil,
		pendingSyncFromReq = false,
		updateBucket = 0,
		temporaryMuteUntil = 0, -- 新增：临时静音截止时间
	}

	-- UI元素（移除了小地图按钮相关）
	self.ui = {
		panel = nil,
		syncInfoText = nil,
		syncRetryButton = nil,
		headerLeaderText = nil,
		headerPlayerText = nil,
		rows = {},
		centerWarningFrame = nil,
		centerWarningText = nil,
		helpButton = nil,
		helpFrame = nil,
		helpBodyText = nil,
		muteStatusText = nil, -- 新增：静音剩余时间文本
	}

	-- 定时器句柄
	self.ticker = nil

	-- 注册斜杠命令
	self:RegisterSlashCommands()
end

function Automaton_CDSafe:RegisterSlashCommands()
	SLASH_CDSAFE1 = "/cdsafe"
	SLASH_CDSAFE2 = "/cds"
	SlashCmdList["CDSAFE"] = function(msg)
		self:HandleSlashCommand(msg)
	end
end

function Automaton_CDSafe:HandleSlashCommand(msg)
	msg = msg or ""
	msg = string.lower(msg)
	msg = string.gsub(msg, "^%s+", "")
	msg = string.gsub(msg, "%s+$", "")

	if msg == "show" or msg == "显示" then
		self:ShowPanel()
		return
	end
	if msg == "hide" or msg == "隐藏" then
		if self.ui.panel then
			self.ui.panel:Hide()
		end
		return
	end
	if msg == "reset" or msg == "重置" then
		-- 重置小地图位置已移除，忽略或提示
		self:PrintMessage(L.RESET_MINIMAP)
		return
	end

	-- 处理静音命令: silence [分钟] 或 mute [分钟]
	local minutes = tonumber(string.match(msg, "^mute%s+(%d+)$")) or tonumber(string.match(msg, "^silence%s+(%d+)$"))
	if minutes then
		self:TemporaryMute(minutes)
		return
	end
	if msg == "mute" or msg == "silence" then
		self:TemporaryMute(5) -- 默认5分钟
		return
	end

	-- 默认：切换面板显示
	self:ToggleStatusPanel()
end

function Automaton_CDSafe:TemporaryMute(minutes)
	minutes = minutes or 5
	self.state.temporaryMuteUntil = GetTime() + minutes * 60
	self:PrintMessage(string.format(L.TEMP_MUTE_MSG, minutes))
	self:RefreshStatusPanel()
	self:EvaluateWarning() -- 立即清除当前警告
end

function Automaton_CDSafe:OnEnable()
	self.state.playerName = StripRealm(UnitName("player")) or ""

	-- 注册事件
	self:RegisterEvent("PLAYER_LOGIN")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("RAID_ROSTER_UPDATE")
	self:RegisterEvent("UPDATE_INSTANCE_INFO")
	self:RegisterEvent("CHAT_MSG_ADDON")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("ZONE_CHANGED")
	self:RegisterEvent("ZONE_CHANGED_INDOORS")
	self:RegisterEvent("MINIMAP_ZONE_CHANGED")

	-- 创建UI（不包含小地图按钮）
	self:CreateStatusPanel()
	self:EnsureCenterWarningFrame()

	-- 启动定时器（每秒执行）
	self.ticker = C_Timer.NewTicker(1, function()
		self:OnTick()
	end)

	-- 初始化请求
	self:RequestRaidInfoThrottled(true)
	self:RefreshGroupState()
	if self.state.isLeader then
		self:BroadcastSync(true)
	elseif self.state.inRaid then
		self:BeginLeaderSyncAttempt(true)
	end
	self:RefreshStatusPanel()
	self:EvaluateWarning()
end

function Automaton_CDSafe:OnDisable()
	self:UnregisterAllEvents()
	if self.ticker then
		self.ticker:Cancel()
		self.ticker = nil
	end
	-- 隐藏UI
	if self.ui.panel then
		self.ui.panel:Hide()
	end
	if self.ui.centerWarningFrame then
		self.ui.centerWarningFrame:Hide()
	end
end

------------------------------
--      Event Handlers      --
------------------------------
function Automaton_CDSafe:PLAYER_LOGIN()
	self:RefreshGroupState()
	self:UpdateSavedRaids()
	self:RequestRaidInfoThrottled(true)
	if self.state.isLeader then
		self:BroadcastSync(true)
	elseif self.state.inRaid then
		self:BeginLeaderSyncAttempt(true)
	end
	self:RefreshStatusPanel()
	self:EvaluateWarning()
end

function Automaton_CDSafe:PLAYER_ENTERING_WORLD()
	self:RefreshGroupState()
	self:RequestRaidInfoThrottled(true)
	if
		not self.state.isLeader
		and self.state.inRaid
		and not self.state.leaderRaidKeys
		and not self.state.leaderSyncTimedOut
		and not self.state.leaderSyncAttemptStartAt
	then
		self:BeginLeaderSyncAttempt(true)
	end
	self:RefreshStatusPanel()
	self:EvaluateWarning()
end

function Automaton_CDSafe:RAID_ROSTER_UPDATE()
	local leaderChanged = self:RefreshGroupState()
	self:RequestRaidInfoThrottled(false)
	if self.state.isLeader then
		if leaderChanged then
			self:BroadcastSync(false)
		end
	elseif self.state.inRaid then
		if leaderChanged then
			self:BeginLeaderSyncAttempt(false)
		elseif
			not self.state.leaderRaidKeys
			and not self.state.leaderSyncTimedOut
			and not self.state.leaderSyncAttemptStartAt
		then
			self:BeginLeaderSyncAttempt(true)
		end
	end
	self:RefreshStatusPanel()
	self:EvaluateWarning()
end

function Automaton_CDSafe:UPDATE_INSTANCE_INFO()
	local changed = self:UpdateSavedRaids()
	if self.state.isLeader and changed then
		self:BroadcastSync(true)
	end
	self:RefreshStatusPanel()
end

function Automaton_CDSafe:CHAT_MSG_ADDON(prefix, message, channel, sender)
	if prefix ~= ADDON_PREFIX then
		return
	end
	if not message or message == "" then
		return
	end
	if not self.state.inRaid then
		return
	end

	local command = string.match(message, "^([^;]+)")
	if command == "SYNC" then
		self:OnSyncMessage(message, sender)
	elseif command == "REQ" then
		if self.state.isLeader then
			self:BroadcastSync(true)
			self.state.pendingSyncFromReq = false
		elseif
			not self.state.leaderRaidKeys
			and self.state.leaderSyncAttemptStartAt
			and not self.state.leaderSyncTimedOut
		then
			self.state.leaderSyncRequestDueAt = nil
			self.state.leaderSyncRequestSent = true
			self.state.leaderSyncAttemptStartAt = GetTime() or 0
		end
	end
end

function Automaton_CDSafe:OnSyncMessage(message, sender)
	local leaderInPayload, syncStamp, payload = string.match(message, "^SYNC;([^;]*);([^;]*);(.*)$")
	if not leaderInPayload then
		return
	end
	if not self.state.inRaid then
		return
	end
	if channel and channel ~= "RAID" then
		return
	end

	local senderName = StripRealm(sender or "")
	local currentLeader = self.state.leaderName
	if currentLeader and currentLeader ~= "" then
		if NormalizePlayerName(senderName) ~= NormalizePlayerName(currentLeader) then
			return
		end
	end

	self.state.leaderName = (senderName ~= "" and senderName) or leaderInPayload
	self.state.leaderRaidKeys, self.state.leaderRaidNameByKey, self.state.leaderRaidInstanceIdByKey =
		self:DeserializeRaidData(payload)
	self.state.leaderSyncAt = tonumber(syncStamp) or time()
	self.state.leaderSyncAttemptStartAt = nil
	self.state.leaderSyncTimedOut = false
	self.state.leaderSyncRequestDueAt = nil
	self.state.leaderSyncRequestSent = false

	self:RefreshStatusPanel()
	self:EvaluateWarning()
end

function Automaton_CDSafe:ZONE_CHANGED_NEW_AREA()
	self:OnWorldOrZoneChanged()
end
function Automaton_CDSafe:ZONE_CHANGED()
	self:OnWorldOrZoneChanged()
end
function Automaton_CDSafe:ZONE_CHANGED_INDOORS()
	self:OnWorldOrZoneChanged()
end
function Automaton_CDSafe:MINIMAP_ZONE_CHANGED()
	self:OnWorldOrZoneChanged()
end

function Automaton_CDSafe:OnWorldOrZoneChanged()
	if self.state.mutedWarningZoneSignature and not self:IsCurrentZoneMuted() then
		self:ClearZoneMute(true)
	end
	self:EvaluateWarning()
end

function Automaton_CDSafe:OnTick()
	local now = GetTime() or 0

	if self.state.inRaid then
		if self.state.isLeader and self.state.pendingSyncFromReq then
			if self:BroadcastSync(false) then
				self.state.pendingSyncFromReq = false
			end
		end

		if self.state.isLeader and (now - self.state.lastBroadcastAt >= BROADCAST_INTERVAL) then
			self:RequestRaidInfoThrottled(true)
			self:BroadcastSync(true)
		elseif
			not self.state.isLeader
			and not self.state.leaderRaidKeys
			and self.state.leaderSyncAttemptStartAt
			and not self.state.leaderSyncTimedOut
		then
			if self.state.leaderSyncRequestSent then
				if now - self.state.leaderSyncAttemptStartAt >= LEADER_SYNC_TIMEOUT then
					self.state.leaderSyncAttemptStartAt = nil
					self.state.leaderSyncTimedOut = true
					self.state.leaderSyncRequestDueAt = nil
					self.state.leaderSyncRequestSent = false
					self:RefreshStatusPanel()
				end
			elseif self.state.leaderSyncRequestDueAt then
				if now >= self.state.leaderSyncRequestDueAt then
					self:RequestSync(true)
					self.state.leaderSyncRequestSent = true
					self.state.leaderSyncRequestDueAt = nil
					self.state.leaderSyncAttemptStartAt = now
				end
			elseif now - self.state.leaderSyncAttemptStartAt >= LEADER_SYNC_TIMEOUT then
				self.state.leaderSyncRequestDueAt = now + self:GetLeaderSyncRequestJitter()
			end
		end
	end

	if now - self.state.lastRaidInfoRequestAt >= RAID_INFO_REQUEST_INTERVAL then
		self:RequestRaidInfoThrottled(true)
	end

	if now >= self.state.nextZoneCheckAt then
		self.state.nextZoneCheckAt = now + 3
		self:EvaluateWarning()
	end
end

------------------------------
--      Core Functions      --
------------------------------
function Automaton_CDSafe:RefreshGroupState()
	local oldLeader = self.state.leaderName
	self.state.inRaid = self:IsInRaidGroup()
	self.state.leaderName = self.state.inRaid and self:GetRaidLeaderName() or nil
	self.state.isLeader = self.state.inRaid
		and (NormalizePlayerName(self.state.leaderName) == NormalizePlayerName(self.state.playerName))

	local leaderChanged = NormalizePlayerName(oldLeader) ~= NormalizePlayerName(self.state.leaderName)

	if not self.state.inRaid then
		self.state.leaderRaidKeys = nil
		self.state.leaderRaidNameByKey = nil
		self.state.leaderRaidInstanceIdByKey = nil
		self.state.leaderSyncAt = nil
		self.state.leaderSyncAttemptStartAt = nil
		self.state.leaderSyncTimedOut = false
		self.state.leaderSyncRequestDueAt = nil
		self.state.leaderSyncRequestSent = false
		self.state.pendingSyncFromReq = false
		self:ClearCenterWarning()
	elseif leaderChanged and not self.state.isLeader then
		self.state.leaderRaidKeys = nil
		self.state.leaderRaidNameByKey = nil
		self.state.leaderRaidInstanceIdByKey = nil
		self.state.leaderSyncAt = nil
		self.state.leaderSyncAttemptStartAt = nil
		self.state.leaderSyncTimedOut = false
		self.state.leaderSyncRequestDueAt = nil
		self.state.leaderSyncRequestSent = false
		self.state.pendingSyncFromReq = false
		self:ClearCenterWarning()
	elseif self.state.isLeader then
		self.state.leaderSyncAttemptStartAt = nil
		self.state.leaderSyncTimedOut = false
		self.state.leaderSyncRequestDueAt = nil
		self.state.leaderSyncRequestSent = false
	end

	return leaderChanged
end

function Automaton_CDSafe:IsInRaidGroup()
	if not GetNumRaidMembers then
		return false
	end
	return (GetNumRaidMembers() or 0) > 0
end

function Automaton_CDSafe:GetRaidLeaderName()
	if not self:IsInRaidGroup() then
		return nil
	end
	local total = GetNumRaidMembers() or 0
	for i = 1, total do
		local name, rank = GetRaidRosterInfo(i)
		if name and rank == 2 then
			return StripRealm(name)
		end
	end
	return nil
end

function Automaton_CDSafe:UpdateSavedRaids()
	local keys, names, nameByKey, instanceIdByKey = self:BuildSavedRaids()
	local newHash = self:BuildHashFromNames(names)
	local changed = newHash ~= self.state.savedHash

	self.state.savedRaidKeys = keys
	self.state.savedRaidNames = names
	self.state.savedRaidNameByKey = nameByKey
	self.state.savedRaidInstanceIdByKey = instanceIdByKey
	self.state.savedHash = newHash

	return changed
end

function Automaton_CDSafe:BuildSavedRaids()
	local keys = {}
	local names = {}
	local nameByKey = {}
	local instanceIdByKey = {}

	if not GetNumSavedInstances or not GetSavedInstanceInfo then
		return keys, names, nameByKey, instanceIdByKey
	end

	local total = GetNumSavedInstances() or 0
	for i = 1, total do
		local name, instanceId = GetSavedInstanceInfo(i)
		if name and name ~= "" then
			local key = self:GetRaidKey(name)
			if key and key ~= "" then
				keys[key] = true
				if not nameByKey[key] then
					nameByKey[key] = tostring(name)
				end
				instanceId = tonumber(instanceId)
				if instanceId and instanceId > 0 then
					instanceIdByKey[key] = instanceId
				end
			end
			table.insert(names, tostring(name))
		end
	end

	return keys, names, nameByKey, instanceIdByKey
end

function Automaton_CDSafe:BuildHashFromNames(names)
	local sorted = {}
	for i = 1, tgetn(names) do
		sorted[i] = names[i]
	end
	table.sort(sorted)
	return table.concat(sorted, "|")
end

function Automaton_CDSafe:GetRaidKey(name)
	local normalized = NormalizeText(name)
	if normalized == "" then
		return ""
	end
	return RAID_ALIAS_TO_KEY[normalized] or normalized
end

function Automaton_CDSafe:SerializeRaidData(keys, nameByKey, instanceIdByKey)
	local serialized = {}
	local orderedKeys = {}
	for key, _ in pairs(keys or {}) do
		table.insert(orderedKeys, key)
	end
	table.sort(orderedKeys)

	for i = 1, tgetn(orderedKeys) do
		local key = orderedKeys[i]
		local name = (nameByKey and nameByKey[key]) or key
		local instanceId = tonumber((instanceIdByKey and instanceIdByKey[key]) or 0)
		key = string.gsub(tostring(key or ""), "[;|,~]", "")
		name = string.gsub(tostring(name or ""), "[;|,~]", "")
		if key ~= "" then
			table.insert(serialized, key .. "~" .. tostring(instanceId) .. "~" .. name)
		end
	end
	return table.concat(serialized, ",")
end

function Automaton_CDSafe:DeserializeRaidData(payload)
	local keys = {}
	local nameByKey = {}
	local instanceIdByKey = {}

	if not payload or payload == "" then
		return keys, nameByKey, instanceIdByKey
	end

	for token in string.gmatch(payload, "([^,|]+)") do
		if token and token ~= "" then
			local rawKey, rawId, rawName = string.match(token, "^([^~]*)~([^~]*)~(.*)$")
			local key, nameForKey
			if rawKey and rawKey ~= "" then
				key = self:GetRaidKey(rawKey)
			else
				key = ""
			end
			if (not key) or key == "" then
				key = self:GetRaidKey(rawName)
			end
			if (not key) or key == "" then
				key = self:GetRaidKey(token)
			end

			if key and key ~= "" then
				keys[key] = true
				nameForKey = rawName
				if not nameForKey or nameForKey == "" then
					nameForKey = token
				end
				if not nameByKey[key] then
					nameByKey[key] = nameForKey
				end
				local instanceId = tonumber(rawId)
				if instanceId and instanceId > 0 then
					instanceIdByKey[key] = instanceId
				end
			end
		end
	end

	return keys, nameByKey, instanceIdByKey
end

function Automaton_CDSafe:BroadcastSync(force)
	if not self.state.isLeader or not self.state.inRaid or not SendAddonMessage then
		return false
	end

	local now = GetTime() or 0
	if not force and (now - self.state.lastBroadcastAt < 5) then
		return false
	end

	local payload = self:SerializeRaidData(
		self.state.savedRaidKeys or {},
		self.state.savedRaidNameByKey or {},
		self.state.savedRaidInstanceIdByKey or {}
	)
	local message = "SYNC;" .. (self.state.playerName or "") .. ";" .. tostring(time()) .. ";" .. payload
	SendAddonMessage(ADDON_PREFIX, message, "RAID")
	self.state.lastBroadcastAt = now
	return true
end

function Automaton_CDSafe:RequestSync(force)
	if self.state.isLeader or not self.state.inRaid or not SendAddonMessage then
		return
	end
	if self.state.leaderSyncTimedOut and not force then
		return
	end
	local now = GetTime() or 0
	if not force and (now - self.state.lastRequestAt < REQUEST_INTERVAL) then
		return
	end
	SendAddonMessage(ADDON_PREFIX, "REQ;" .. (self.state.playerName or ""), "RAID")
	self.state.lastRequestAt = now
end

function Automaton_CDSafe:BeginLeaderSyncAttempt(sendImmediateRequest)
	if self.state.isLeader or not self.state.inRaid then
		self.state.leaderSyncAttemptStartAt = nil
		self.state.leaderSyncTimedOut = false
		self.state.leaderSyncRequestDueAt = nil
		self.state.leaderSyncRequestSent = false
		self:RefreshStatusPanel()
		return
	end
	self.state.leaderSyncTimedOut = false
	self.state.leaderSyncAttemptStartAt = GetTime() or 0
	self.state.leaderSyncRequestDueAt = nil
	self.state.leaderSyncRequestSent = false
	if sendImmediateRequest then
		self:RequestSync(true)
		self.state.leaderSyncRequestSent = true
	end
	self:RefreshStatusPanel()
end

function Automaton_CDSafe:GetLeaderSyncRequestJitter()
	local minDelay = LEADER_SYNC_REQUEST_JITTER_MIN
	local maxDelay = LEADER_SYNC_REQUEST_JITTER_MAX
	if maxDelay <= minDelay then
		return minDelay
	end
	return math.random(minDelay, maxDelay)
end

function Automaton_CDSafe:RequestRaidInfoThrottled(force)
	if not RequestRaidInfo then
		return
	end
	local now = GetTime() or 0
	if force or (now - self.state.lastRaidInfoRequestAt >= RAID_INFO_REQUEST_INTERVAL) then
		RequestRaidInfo()
		self.state.lastRaidInfoRequestAt = now
	end
end

function Automaton_CDSafe:GetCurrentZoneSignature()
	local zoneText = GetRealZoneText and GetRealZoneText() or ""
	if zoneText == "" and GetZoneText then
		zoneText = GetZoneText() or ""
	end
	local zone = NormalizeText(zoneText)
	local subzone = NormalizeText((GetSubZoneText and GetSubZoneText()) or "")
	return zone .. "|" .. subzone
end

function Automaton_CDSafe:IsCurrentZoneMuted()
	return self.state.mutedWarningZoneSignature
		and self.state.mutedWarningZoneSignature ~= ""
		and self.state.mutedWarningZoneSignature == self:GetCurrentZoneSignature()
end

function Automaton_CDSafe:ClearZoneMute(isAuto)
	if not self.state.mutedWarningZoneSignature then
		return
	end
	self.state.mutedWarningZoneSignature = nil
	if isAuto then
		self:PrintMessage(L.MUTE_ZONE_AUTO_OFF)
	else
		self:PrintMessage(L.MUTE_ZONE_OFF)
	end
end

function Automaton_CDSafe:ToggleZoneMuteForCurrentArea()
	local signature = self:GetCurrentZoneSignature()
	if self.state.mutedWarningZoneSignature and self.state.mutedWarningZoneSignature == signature then
		self:ClearZoneMute(false)
		return
	end
	self.state.mutedWarningZoneSignature = signature
	self:ClearCenterWarning()
	self:PrintMessage(L.MUTE_ZONE_ON)
end

function Automaton_CDSafe:PrintMessage(text)
	if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
		DEFAULT_CHAT_FRAME:AddMessage("|cffff4040CDSafe|r: " .. text)
	end
end

------------------------------
--      Warning Logic       --
------------------------------
function Automaton_CDSafe:DetectRaidContext()
	local keys = {}
	local seen = {}
	local zone = GetRealZoneText() or ""
	local subzone = (GetSubZoneText and GetSubZoneText()) or ""
	local zoneNormalized = NormalizeText(zone)
	local subzoneNormalized = NormalizeText(subzone)

	for i = 1, tgetn(WARNING_AREA_RULES) do
		local rule = WARNING_AREA_RULES[i]
		local zoneMatched = (rule.zone == "") or (rule.zone == zoneNormalized)
		local subzoneMatched = (rule.subzone == "") or (rule.subzone == subzoneNormalized)
		if zoneMatched and subzoneMatched and not seen[rule.key] then
			seen[rule.key] = true
			table.insert(keys, rule.key)
		end
	end
	return keys, zone, subzone
end

function Automaton_CDSafe:BuildDisplayNameForKey(key)
	local def = RAID_DEF_BY_KEY[key]
	if def then
		return GetRaidDisplayName(def)
	end
	if self.state.leaderRaidNameByKey and self.state.leaderRaidNameByKey[key] then
		return self.state.leaderRaidNameByKey[key]
	end
	if self.state.savedRaidNameByKey and self.state.savedRaidNameByKey[key] then
		return self.state.savedRaidNameByKey[key]
	end
	return key
end

function Automaton_CDSafe:BuildRaidListText(keys)
	local names = {}
	for i = 1, tgetn(keys) do
		names[i] = self:BuildDisplayNameForKey(keys[i])
	end
	table.sort(names)
	return table.concat(names, " / ")
end

function Automaton_CDSafe:EvaluateWarning()
	-- 检查临时静音
	if self.state.temporaryMuteUntil and GetTime() < self.state.temporaryMuteUntil then
		self:ClearCenterWarning()
		return
	end

	if not self.state.inRaid then
		self:ClearCenterWarning()
		return
	end

	if self.state.mutedWarningZoneSignature then
		if self:IsCurrentZoneMuted() then
			self:ClearCenterWarning()
			return
		end
		self:ClearZoneMute(true)
	end

	if IsInInstance then
		local inInstance, instanceType = IsInInstance()
		if inInstance and instanceType == "raid" then
			self:ClearCenterWarning()
			return
		end
	end

	local contextKeys = self:DetectRaidContext()
	if tgetn(contextKeys) == 0 then
		self:ClearCenterWarning()
		return
	end

	if self.state.isLeader then
		local leaderLocked = {}
		for i = 1, tgetn(contextKeys) do
			local key = contextKeys[i]
			if self.state.savedRaidKeys and self.state.savedRaidKeys[key] then
				table.insert(leaderLocked, key)
			end
		end
		if tgetn(leaderLocked) == 0 then
			self:ClearCenterWarning()
			return
		end
		table.sort(leaderLocked)
		local raidList = self:BuildRaidListText(leaderLocked)
		local text = string.format(L.WARNING_LEADER_SELF_TEMPLATE, raidList)
		self:UpdateCenterWarning(text)
		return
	end

	if not self.state.leaderRaidKeys then
		local unknownRaidList = self:BuildRaidListText(contextKeys)
		local text = string.format(L.WARNING_LEADER_UNKNOWN, unknownRaidList)
		self:UpdateCenterWarning(text)
		return
	end

	local locked = {}
	for i = 1, tgetn(contextKeys) do
		local key = contextKeys[i]
		if self.state.leaderRaidKeys[key] then
			local leaderInstanceId =
				tonumber((self.state.leaderRaidInstanceIdByKey and self.state.leaderRaidInstanceIdByKey[key]) or 0)
			local playerLocked = self.state.savedRaidKeys and self.state.savedRaidKeys[key] and true or false
			local playerInstanceId =
				tonumber((self.state.savedRaidInstanceIdByKey and self.state.savedRaidInstanceIdByKey[key]) or 0)
			local sameLockoutId = playerLocked
				and leaderInstanceId > 0
				and playerInstanceId > 0
				and leaderInstanceId == playerInstanceId
			if not sameLockoutId then
				table.insert(locked, key)
			end
		end
	end

	if tgetn(locked) == 0 then
		local safeRaidList = self:BuildRaidListText(contextKeys)
		-- 检查是否有共享进度的副本
		local hasSharedLockout = false
		for i = 1, tgetn(contextKeys) do
			local key = contextKeys[i]
			if self.state.leaderRaidKeys and self.state.leaderRaidKeys[key] then
				local leaderInstanceId =
					tonumber((self.state.leaderRaidInstanceIdByKey and self.state.leaderRaidInstanceIdByKey[key]) or 0)
				local playerLocked = self.state.savedRaidKeys and self.state.savedRaidKeys[key] and true or false
				local playerInstanceId =
					tonumber((self.state.savedRaidInstanceIdByKey and self.state.savedRaidInstanceIdByKey[key]) or 0)
				if
					playerLocked
					and leaderInstanceId > 0
					and playerInstanceId > 0
					and leaderInstanceId == playerInstanceId
				then
					hasSharedLockout = true
					break
				end
			end
		end

		local safeText
		if hasSharedLockout then
			safeText = string.format(L.INFO_SHARED_LOCKOUT_TEMPLATE, safeRaidList)
		else
			safeText = string.format(L.INFO_SAFE_ENTER_TEMPLATE, safeRaidList)
		end
		self:UpdateCenterWarning(safeText, 0.2, 1.0, 0.2)
		return
	end

	table.sort(locked)
	local leaderName = self.state.leaderName or L.WARNING_LEADER_FALLBACK
	local raidList = self:BuildRaidListText(locked)
	local text = string.format(L.WARNING_TEXT_TEMPLATE, leaderName, raidList)
	self:UpdateCenterWarning(text)
end

function Automaton_CDSafe:UpdateCenterWarning(text, r, g, b)
	if not text or text == "" then
		self:ClearCenterWarning()
		return
	end
	r = r or 1.0
	g = g or 0.2
	b = b or 0.2
	if
		self.state.activeCenterWarningText == text
		and self.state.activeCenterWarningR == r
		and self.state.activeCenterWarningG == g
		and self.state.activeCenterWarningB == b
		and self.ui.centerWarningFrame
		and self.ui.centerWarningFrame:IsShown()
	then
		return
	end
	self.state.activeCenterWarningText = text
	self.state.activeCenterWarningR = r
	self.state.activeCenterWarningG = g
	self.state.activeCenterWarningB = b
	self:ShowCenterWarning(text, r, g, b)
end

function Automaton_CDSafe:ClearCenterWarning()
	self.state.activeCenterWarningText = nil
	self.state.activeCenterWarningR = nil
	self.state.activeCenterWarningG = nil
	self.state.activeCenterWarningB = nil
	if self.ui.centerWarningText then
		self.ui.centerWarningText:SetText("")
	end
	if self.ui.centerWarningFrame then
		self.ui.centerWarningFrame:Hide()
	end
	if RaidWarningFrame and RaidWarningFrame.Clear then
		RaidWarningFrame:Clear()
	end
end

------------------------------
--      UI Creation         --
------------------------------
function Automaton_CDSafe:EnsureCenterWarningFrame()
	if self.ui.centerWarningFrame then
		return
	end

	local frame = CreateFrame("Frame", nil, UIParent)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:SetFrameLevel(20)
	frame:SetWidth(1000)
	frame:SetHeight(80)
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, 180)
	frame:Hide()

	local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	text:SetPoint("CENTER", frame, "CENTER", 0, 0)
	text:SetWidth(980)
	text:SetJustifyH("CENTER")
	text:SetTextColor(1.0, 0.2, 0.2)
	text:SetText("")

	self.ui.centerWarningFrame = frame
	self.ui.centerWarningText = text
end

function Automaton_CDSafe:ShowCenterWarning(text, r, g, b)
	if not text or text == "" then
		return
	end
	self:EnsureCenterWarningFrame()
	if self.ui.centerWarningText then
		self.ui.centerWarningText:SetTextColor(r or 1.0, g or 0.2, b or 0.2)
		self.ui.centerWarningText:SetText(text)
	end
	if self.ui.centerWarningFrame then
		self.ui.centerWarningFrame:Show()
	end
end

function Automaton_CDSafe:CreateStatusPanel()
	if self.ui.panel then
		return
	end

	local rowCount = tgetn(RAID_DEFS)
	local panelWidth = 650
	local panelHeight = math.max(400, 138 + (rowCount * 30))
	local columnRaidX = 20
	local columnLeaderX = 262
	local columnPlayerX = 462
	local headerY = -96
	local firstRowY = -128
	local rowStep = 30
	local statusColumnWidth = 165
	local helpFrameWidth = panelWidth - 50
	local helpFrameHeight = 200
	local helpFrameGap = 8

	local panel = CreateFrame("Frame", nil, UIParent)
	panel:SetWidth(panelWidth)
	panel:SetHeight(panelHeight)
	panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	panel:SetFrameStrata("DIALOG")
	panel:SetMovable(true)
	panel:EnableMouse(true)
	panel:RegisterForDrag("LeftButton")
	panel:SetScript("OnDragStart", function()
		panel:StartMoving()
	end)
	panel:SetScript("OnDragStop", function()
		panel:StopMovingOrSizing()
	end)
	Automaton.ApplyFlatBackdrop(panel, Automaton.FLAT.window, Automaton.FLAT.border)
	panel:Hide()
	panel:SetScript("OnHide", function()
		if self.ui.helpFrame then
			self.ui.helpFrame:Hide()
		end
	end)

	-- 标题栏背景条
	local titleBg = panel:CreateTexture(nil, "NORMAL")
	titleBg:SetTexture(0.07, 0.10, 0.16, 0.9)
	titleBg:SetHeight(24)
	titleBg:SetPoint("TOPLEFT", 2, -2)
	titleBg:SetPoint("TOPRIGHT", -2, -2)

	local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
	title:SetTextColor(Automaton.FLAT.title[1], Automaton.FLAT.title[2], Automaton.FLAT.title[3])
	title:SetPoint("CENTER", titleBg, "CENTER", 0, 0)
	title:SetText(L.PANEL_TITLE)

	-- 关闭按钮（红色扁平）
	local close = CreateFrame("Button", nil, panel)
	close:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -10)
	close:SetWidth(20)
	close:SetHeight(20)
	Automaton.ApplyFlatBackdrop(close, { 0.35, 0.08, 0.08, 0.98 }, Automaton.FLAT.border)
	Automaton.AddFlatBorder(close, Automaton.FLAT.border)
	local closeLabel = close:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	closeLabel:SetFont(STANDARD_TEXT_FONT, 14)
	closeLabel:SetTextColor(1, 0.82, 0.82)
	closeLabel:SetText("X")
	closeLabel:SetAllPoints()
	close:SetScript("OnEnter", function()
		close:SetBackdropColor(0.65, 0.12, 0.12, 1)
	end)
	close:SetScript("OnLeave", function()
		close:SetBackdropColor(0.35, 0.08, 0.08, 0.98)
	end)
	close:SetScript("OnClick", function()
		panel:Hide()
	end)

	-- 帮助按钮
	local helpButton = Automaton.CreateFlatButton(panel, 56, 22, "帮助")
	helpButton:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -38, -14)
	helpButton:SetScript("OnClick", function()
		self:ToggleHelpPanel()
	end)
	self.ui.helpButton = helpButton

	-- 临时静音按钮
	local muteButton = Automaton.CreateFlatButton(panel, 60, 22, L.TEMP_MUTE_BUTTON)
	muteButton:SetPoint("RIGHT", helpButton, "LEFT", -4, 0)
	muteButton:SetScript("OnClick", function()
		self:TemporaryMute(5)
	end)

	self.ui.syncInfoText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	self.ui.syncInfoText:SetFont(STANDARD_TEXT_FONT, 11)
	self.ui.syncInfoText:SetTextColor(Automaton.FLAT.text[1], Automaton.FLAT.text[2], Automaton.FLAT.text[3])
	self.ui.syncInfoText:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, -52)
	self.ui.syncInfoText:SetText(L.LEADER_SYNC_TIME .. ": N/A")

	-- 静音剩余时间显示
	self.ui.muteStatusText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	self.ui.muteStatusText:SetFont(STANDARD_TEXT_FONT, 11)
	self.ui.muteStatusText:SetTextColor(Automaton.FLAT.dim[1], Automaton.FLAT.dim[2], Automaton.FLAT.dim[3])
	self.ui.muteStatusText:SetPoint("TOPLEFT", self.ui.syncInfoText, "BOTTOMLEFT", 0, -2)
	self.ui.muteStatusText:SetText("")

	local syncRetryButton = Automaton.CreateFlatButton(panel, 46, 18, L.RETRY)
	syncRetryButton:SetPoint("LEFT", self.ui.syncInfoText, "RIGHT", 8, 0)
	syncRetryButton:SetScript("OnClick", function()
		self:BeginLeaderSyncAttempt(true)
	end)
	syncRetryButton:Hide()
	self.ui.syncRetryButton = syncRetryButton

	local headerRaid = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	headerRaid:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
	headerRaid:SetTextColor(Automaton.FLAT.title[1], Automaton.FLAT.title[2], Automaton.FLAT.title[3])
	headerRaid:SetPoint("TOPLEFT", panel, "TOPLEFT", columnRaidX, headerY)
	headerRaid:SetText(L.HEADER_RAID)

	local headerLeader = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	headerLeader:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
	headerLeader:SetTextColor(Automaton.FLAT.title[1], Automaton.FLAT.title[2], Automaton.FLAT.title[3])
	headerLeader:SetPoint("TOPLEFT", panel, "TOPLEFT", columnLeaderX, headerY)
	headerLeader:SetWidth(statusColumnWidth)
	headerLeader:SetJustifyH("LEFT")
	headerLeader:SetText(L.HEADER_LEADER .. " - ?")
	self.ui.headerLeaderText = headerLeader

	local headerPlayer = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	headerPlayer:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
	headerPlayer:SetTextColor(Automaton.FLAT.title[1], Automaton.FLAT.title[2], Automaton.FLAT.title[3])
	headerPlayer:SetPoint("TOPLEFT", panel, "TOPLEFT", columnPlayerX, headerY)
	headerPlayer:SetWidth(statusColumnWidth)
	headerPlayer:SetJustifyH("LEFT")
	headerPlayer:SetText(L.HEADER_YOU .. " - ?")
	self.ui.headerPlayerText = headerPlayer

	for i = 1, tgetn(RAID_DEFS) do
		local def = RAID_DEFS[i]
		local y = firstRowY - ((i - 1) * rowStep)
		local rowKey = def.key

		local raidText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		raidText:SetFont(STANDARD_TEXT_FONT, 11)
		raidText:SetTextColor(Automaton.FLAT.text[1], Automaton.FLAT.text[2], Automaton.FLAT.text[3])
		raidText:SetPoint("TOPLEFT", panel, "TOPLEFT", columnRaidX, y)
		raidText:SetWidth(columnLeaderX - columnRaidX - 18)
		raidText:SetJustifyH("LEFT")

		local leaderText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		leaderText:SetFont(STANDARD_TEXT_FONT, 11)
		leaderText:SetTextColor(Automaton.FLAT.text[1], Automaton.FLAT.text[2], Automaton.FLAT.text[3])
		leaderText:SetPoint("TOPLEFT", panel, "TOPLEFT", columnLeaderX, y)
		leaderText:SetWidth(statusColumnWidth)
		leaderText:SetJustifyH("LEFT")

		local playerText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		playerText:SetFont(STANDARD_TEXT_FONT, 11)
		playerText:SetTextColor(Automaton.FLAT.text[1], Automaton.FLAT.text[2], Automaton.FLAT.text[3])
		playerText:SetPoint("TOPLEFT", panel, "TOPLEFT", columnPlayerX, y)
		playerText:SetWidth(statusColumnWidth)
		playerText:SetJustifyH("LEFT")

		local raidReportButton = CreateFrame("Button", nil, panel)
		raidReportButton:SetPoint("TOPLEFT", panel, "TOPLEFT", columnRaidX, y)
		raidReportButton:SetWidth(columnLeaderX - columnRaidX - 18)
		raidReportButton:SetHeight(18)
		raidReportButton:SetScript("OnClick", function()
			self:SendRaidStatusReportForKey(rowKey)
		end)

		local playerReportButton = CreateFrame("Button", nil, panel)
		playerReportButton:SetPoint("TOPLEFT", panel, "TOPLEFT", columnPlayerX, y)
		playerReportButton:SetWidth(statusColumnWidth)
		playerReportButton:SetHeight(18)
		playerReportButton:SetScript("OnClick", function()
			self:SendRaidStatusReportForKey(rowKey)
		end)

		self.ui.rows[def.key] = {
			raidText = raidText,
			leaderText = leaderText,
			playerText = playerText,
			raidReportButton = raidReportButton,
			playerReportButton = playerReportButton,
		}
	end

	local help = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	help:SetFont(STANDARD_TEXT_FONT, 11)
	help:SetTextColor(Automaton.FLAT.dim[1], Automaton.FLAT.dim[2], Automaton.FLAT.dim[3])
	help:SetPoint("TOPLEFT", self.ui.syncInfoText, "BOTTOMLEFT", 0, -20) -- 下移一点，避免与muteStatusText重叠
	help:SetWidth(panelWidth - 40)
	help:SetJustifyH("LEFT")
	help:SetText(L.HELP_MINIMAP)

	local helpFrame = CreateFrame("Frame", nil, UIParent)
	helpFrame:SetWidth(helpFrameWidth)
	helpFrame:SetHeight(helpFrameHeight)
	helpFrame:SetPoint("BOTTOM", panel, "TOP", 0, helpFrameGap)
	helpFrame:SetFrameStrata("DIALOG")
	helpFrame:SetFrameLevel((panel:GetFrameLevel() or 1) + 10)
	Automaton.ApplyFlatBackdrop(helpFrame, Automaton.FLAT.window, Automaton.FLAT.border)
	helpFrame:Hide()

	local helpTitle = helpFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	helpTitle:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
	helpTitle:SetTextColor(Automaton.FLAT.title[1], Automaton.FLAT.title[2], Automaton.FLAT.title[3])
	helpTitle:SetPoint("TOP", helpFrame, "TOP", 0, -16)
	helpTitle:SetText("CDSafe 逻辑说明")

	local helpClose = CreateFrame("Button", nil, helpFrame)
	helpClose:SetPoint("TOPRIGHT", helpFrame, "TOPRIGHT", -10, -10)
	helpClose:SetWidth(20)
	helpClose:SetHeight(20)
	Automaton.ApplyFlatBackdrop(helpClose, { 0.35, 0.08, 0.08, 0.98 }, Automaton.FLAT.border)
	Automaton.AddFlatBorder(helpClose, Automaton.FLAT.border)
	local helpCloseLabel = helpClose:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	helpCloseLabel:SetFont(STANDARD_TEXT_FONT, 14)
	helpCloseLabel:SetTextColor(1, 0.82, 0.82)
	helpCloseLabel:SetText("X")
	helpCloseLabel:SetAllPoints()
	helpClose:SetScript("OnEnter", function()
		helpClose:SetBackdropColor(0.65, 0.12, 0.12, 1)
	end)
	helpClose:SetScript("OnLeave", function()
		helpClose:SetBackdropColor(0.35, 0.08, 0.08, 0.98)
	end)
	helpClose:SetScript("OnClick", function()
		helpFrame:Hide()
	end)

	local helpBody = helpFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	helpBody:SetFont(STANDARD_TEXT_FONT, 11)
	helpBody:SetTextColor(Automaton.FLAT.text[1], Automaton.FLAT.text[2], Automaton.FLAT.text[3])
	helpBody:SetPoint("TOPLEFT", helpFrame, "TOPLEFT", 20, -44)
	helpBody:SetWidth(helpFrameWidth - 40)
	helpBody:SetJustifyH("LEFT")
	helpBody:SetJustifyV("TOP")
	helpBody:SetText([[团长功能：
- 进入副本门口区域时，自动检测自身进度，若已锁定则在屏幕中央红字提醒。
- 在状态面板点击副本名称或你的状态，可一键发送自身锁定状态到团队。

团员功能：
- 进入副本门口区域时，自动检测团长是否安装CDSafe。若已安装，同步团长信息并提示是否可进入。
- 若团长未安装，提示与团长确认。

临时静音：
- 点击面板上的“静音5m”按钮，可临时禁用屏幕中央提醒5分钟。
- 也可使用命令 /cds mute [分钟] 或 /cds silence [分钟] 实现相同效果。

小地图图标已移除，请通过插件配置界面打开面板。]])

	if helpBody.GetStringHeight then
		local textHeight = tonumber(helpBody:GetStringHeight()) or 0
		if textHeight > 0 then
			local desiredHeight = math.ceil(textHeight + 72)
			if desiredHeight > helpFrameHeight then
				helpFrame:SetHeight(desiredHeight)
			end
		end
	end

	self.ui.panel = panel
	self.ui.helpFrame = helpFrame
	self.ui.helpBodyText = helpBody
end

function Automaton_CDSafe:ShowPanel()
	if not self.ui.panel then
		return
	end
	self:RefreshStatusPanel()
	self.ui.panel:Show()
end

function Automaton_CDSafe:ToggleStatusPanel()
	if not self.ui.panel then
		return
	end
	if self.ui.panel:IsShown() then
		if self.ui.helpFrame then
			self.ui.helpFrame:Hide()
		end
		self.ui.panel:Hide()
	else
		self:ShowPanel()
	end
end

function Automaton_CDSafe:ToggleHelpPanel()
	if not self.ui.helpFrame then
		return
	end
	if self.ui.helpFrame:IsShown() then
		self.ui.helpFrame:Hide()
	else
		self.ui.helpFrame:Show()
	end
end

function Automaton_CDSafe:RefreshStatusPanel()
	if not self.ui.panel then
		return
	end

	-- 更新静音剩余时间显示
	if self.ui.muteStatusText then
		local remaining = self.state.temporaryMuteUntil - (GetTime() or 0)
		if remaining > 0 then
			local mins = math.ceil(remaining / 60)
			self.ui.muteStatusText:SetText(string.format(L.TEMP_MUTE_REMAINING, mins))
		else
			self.ui.muteStatusText:SetText("")
		end
	end

	local leaderNameText, leaderKnown, leaderKeys, leaderInstanceIdByKey = self:GetLeaderStatusContext()

	if self.ui.syncInfoText then
		if self.state.isLeader then
			self.ui.syncInfoText:SetText(L.LEADER_DATA_SOURCE_LOCAL)
		elseif self.state.inRaid then
			if leaderKnown then
				self.ui.syncInfoText:SetText(
					L.LEADER_SYNC_TIME .. ": " .. self:FormatTimeStamp(self.state.leaderSyncAt)
				)
			elseif self.state.leaderSyncTimedOut then
				self.ui.syncInfoText:SetText(L.LEADER_SYNC_TIMEOUT_TEXT)
			else
				self.ui.syncInfoText:SetText(L.LEADER_SYNC_TIME .. ": " .. L.WAITING_FOR_SYNC)
			end
		else
			self.ui.syncInfoText:SetText(L.LEADER_SYNC_TIME .. ": " .. L.NOT_IN_RAID)
		end
	end

	if self.ui.syncRetryButton then
		if self.state.inRaid and not self.state.isLeader and self.state.leaderSyncTimedOut then
			self.ui.syncRetryButton:Show()
		else
			self.ui.syncRetryButton:Hide()
		end
	end

	if self.ui.headerLeaderText then
		local leaderHeaderId = (leaderNameText and leaderNameText ~= "") and leaderNameText or "?"
		self.ui.headerLeaderText:SetText(L.HEADER_LEADER .. " - " .. leaderHeaderId)
	end

	if self.ui.headerPlayerText then
		local playerHeaderId = (self.state.playerName and self.state.playerName ~= "") and self.state.playerName or "?"
		self.ui.headerPlayerText:SetText(L.HEADER_YOU .. " - " .. playerHeaderId)
	end

	for i = 1, tgetn(RAID_DEFS) do
		local def = RAID_DEFS[i]
		local row = self.ui.rows[def.key]
		if row then
			local playerLocked = self.state.savedRaidKeys[def.key] and true or false
			local playerInstanceId = self.state.savedRaidInstanceIdByKey
				and self.state.savedRaidInstanceIdByKey[def.key]
			local leaderLocked = false
			local leaderInstanceId = nil
			if leaderKnown and leaderKeys then
				leaderLocked = leaderKeys[def.key] and true or false
				if leaderLocked and leaderInstanceIdByKey then
					leaderInstanceId = leaderInstanceIdByKey[def.key]
				end
			end

			row.raidText:SetText(def.short .. " - " .. GetRaidDisplayName(def))
			row.leaderText:SetText(self:FormatStatusText(leaderKnown, leaderLocked, leaderInstanceId))
			row.playerText:SetText(self:FormatStatusText(true, playerLocked, playerInstanceId))
		end
	end
end

function Automaton_CDSafe:GetLeaderStatusContext()
	local leaderNameText = self.state.leaderName or L.UNKNOWN
	local leaderKeys = self.state.leaderRaidKeys
	local leaderInstanceIdByKey = self.state.leaderRaidInstanceIdByKey
	local leaderKnown = leaderKeys ~= nil

	if self.state.isLeader then
		leaderNameText = (self.state.playerName ~= "" and self.state.playerName) or L.YOU
		leaderKeys = self.state.savedRaidKeys
		leaderInstanceIdByKey = self.state.savedRaidInstanceIdByKey
		leaderKnown = true
	end

	return leaderNameText, leaderKnown, leaderKeys, leaderInstanceIdByKey
end

function Automaton_CDSafe:FormatStatusText(known, locked, instanceId)
	if not known then
		return STATUS_UNKNOWN
	end
	if locked then
		local numericId = tonumber(instanceId)
		if numericId and numericId > 0 then
			return string.format(L.STATUS_WITH_ID_TEMPLATE, STATUS_LOCKED, L.INSTANCE_ID_LABEL, tostring(numericId))
		end
		return STATUS_LOCKED
	end
	return STATUS_OPEN
end

function Automaton_CDSafe:FormatTimeStamp(ts)
	if not ts then
		return "N/A"
	end
	if date then
		return date("%m-%d %H:%M:%S", ts)
	end
	return tostring(ts)
end

function Automaton_CDSafe:SendRaidStatusReportForKey(raidKey)
	if not self.state.inRaid then
		self:PrintMessage(L.NOT_IN_RAID)
		return
	end
	if not SendChatMessage then
		return
	end

	local def = RAID_DEF_BY_KEY[raidKey]
	if not def then
		return
	end

	local leaderNameText, leaderKnown, leaderKeys, leaderInstanceIdByKey = self:GetLeaderStatusContext()

	local playerLocked = self.state.savedRaidKeys[raidKey] and true or false
	local playerInstanceId = self.state.savedRaidInstanceIdByKey and self.state.savedRaidInstanceIdByKey[raidKey]

	local leaderLocked = false
	local leaderInstanceId = nil
	if leaderKnown and leaderKeys then
		leaderLocked = leaderKeys[raidKey] and true or false
		if leaderLocked and leaderInstanceIdByKey then
			leaderInstanceId = leaderInstanceIdByKey[raidKey]
		end
	end

	local leaderId = (leaderNameText and leaderNameText ~= "") and leaderNameText or L.UNKNOWN
	local playerId = (self.state.playerName and self.state.playerName ~= "") and self.state.playerName or L.YOU
	local leaderStatus = self:FormatReportStatusText(leaderKnown, leaderLocked, leaderInstanceId)
	local playerStatus = self:FormatReportStatusText(true, playerLocked, playerInstanceId)
	local raidName = GetRaidDisplayName(def)
	local message
	if self.state.isLeader then
		message = string.format(L.RAID_REPORT_LEADER_ONLY_TEMPLATE, raidName, leaderId, leaderStatus)
	else
		message = string.format(L.RAID_REPORT_TEMPLATE, raidName, leaderId, leaderStatus, playerId, playerStatus)
	end
	message = string.gsub(message, "|", "||")

	SendChatMessage(message, "RAID")
end

function Automaton_CDSafe:FormatReportStatusText(known, locked, instanceId)
	if not known then
		return L.STATUS_UNKNOWN
	end
	if locked then
		local numericId = tonumber(instanceId)
		if numericId and numericId > 0 then
			return string.format(L.STATUS_WITH_ID_TEMPLATE, L.STATUS_LOCKED, L.INSTANCE_ID_LABEL, tostring(numericId))
		end
		return L.STATUS_LOCKED
	end
	return L.STATUS_OPEN
end
