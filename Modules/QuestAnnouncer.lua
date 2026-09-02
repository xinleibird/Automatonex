assert(Automaton, "Automaton not found!")

local QuestAnnouncer = Automaton:NewModule("QuestAnnouncer")
QuestAnnouncer.modulename = "任务进度通告"
QuestAnnouncer.moduledesc = "任务进度小队通告"
QuestAnnouncer.options = {
	soloAnnounce = {
		type = "toggle",
		name = "单人时也通报",
		desc = "即使没有小队成员，也发送任务进度通报",
		get = function()
			return QuestAnnouncer.db.profile.soloAnnounce
		end,
		set = function(v)
			QuestAnnouncer.db.profile.soloAnnounce = v
		end,
	},
}

function QuestAnnouncer:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("QuestAnnouncer")
	Automaton:RegisterDefaults("QuestAnnouncer", "profile", {
		disabled = false,
		soloAnnounce = false, -- 默认关闭单人通报
	})
	Automaton:SetDisabledAsDefault(self, "QuestAnnouncer")
	self:RegisterOptions(self.options)
end

function QuestAnnouncer:OnEnable()
	self:Hook(UIErrorsFrame, "AddMessage")
end

function QuestAnnouncer:OnDisable()
	self:UnhookAll()
end

-- 根据进度计算颜色 (0-1范围，0=红色，1=绿色)
local function GetProgressColor(progress)
	local r, g, b

	if progress <= 0.5 then
		-- 从红色到黄色
		r = 1.0
		g = progress * 2
		b = 0.0
	else
		-- 从黄色到绿色
		r = 2.0 - (progress * 2)
		g = 1.0
		b = 0.0
	end

	-- 转换为十六进制颜色代码
	return string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
end

function FromatQuestsMsg(message)
	local strUnitname, strItemName, iNumItems, iNumNeeded
	local outstr = message
	-- 尝试匹配任务怪物击杀进度
	if strfind(message, "已杀死") then
		strUnitname, iNumItems, iNumNeeded = Automaton.Deformat:Deformat(message, QUEST_MONSTERS_KILLED)
	else
		-- 尝试匹配任务物品收集进度
		strItemName, iNumItems, iNumNeeded = Automaton.Deformat:Deformat(message, QUEST_OBJECTS_FOUND)
	end

	if strUnitname or strItemName then
		local cnname = strItemName or strUnitname
		local progress = iNumItems / iNumNeeded
		local progressColor = GetProgressColor(progress)
		local stillneeded = iNumNeeded - iNumItems
		local result = ""

		-- 完成状态提示
		if stillneeded < 1 then
			result = "|cffFFFF00 已完成|r"
		end

		-- 构建输出字符串，使用渐变色显示进度
		outstr = "|cffFFFF00任务进度：|r|cffffffff"
			.. cnname
			.. "|r "
			.. progressColor
			.. iNumItems
			.. "/"
			.. iNumNeeded
			.. "|r"
			.. result

		-- 发送消息条件：有小队成员 或 开启了单人通报选项
		local hasParty = GetNumPartyMembers() > 0
		local soloAnnounce = QuestAnnouncer.db.profile.soloAnnounce
		-- if (hasParty or soloAnnounce) and outstr then
		--     SendChatMessage(outstr, hasParty and "PARTY" or "SAY")
		-- end
		if hasParty then
			-- 有队伍时发送到队伍频道
			SendChatMessage(outstr, "PARTY")
		elseif soloAnnounce then
			-- 单人模式时显示在本地聊天框（不打扰他人）
			DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[任务通知]|r " .. outstr)
		end
		return outstr
	end
	return message
end

function QuestAnnouncer:AddMessage(f, message, a1, a2, a3, a4)
	message = FromatQuestsMsg(message)
	self.hooks[UIErrorsFrame].AddMessage(f, message, a1, a2, a3, a4)
end
