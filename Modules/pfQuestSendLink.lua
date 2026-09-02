local Automaton_pfQuestSendLink = Automaton:NewModule("pfQuestSendLink")
Automaton_pfQuestSendLink.modulename = "任务英文链接"
Automaton_pfQuestSendLink.moduledesc = "按住Ctrl点击任务标题发送英文名字的任务Link到聊天框"
Automaton_pfQuestSendLink.options = {}

------------------------------
--      Initialization      --
------------------------------

function Automaton_pfQuestSendLink:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("pfQuestSendLink")
	Automaton:RegisterDefaults("pfQuestSendLink", "profile", {
		disabled = true,
	})
	Automaton:SetDisabledAsDefault(self, "pfQuestSendLink")
	self:RegisterOptions(self.options)
end

function Automaton_pfQuestSendLink:OnEnable()
	if IsAddOnLoaded("pfQuest") then
		self:Hook("QuestLogTitleButton_OnClick")
	else
		self:print("|CFFFF0000pfQuest任务插件未启用，英文任务Link功能无效。|R")
	end
end

function Automaton_pfQuestSendLink:OnDisable()
	self:UnhookAll()
end

function Automaton_pfQuestSendLink:QuestLogTitleButton_OnClick(button)
	local scrollFrame = EQL3_QuestLogListScrollFrame or ShaguQuest_QuestLogListScrollFrame or QuestLogListScrollFrame
	local questIndex = this:GetID() + FauxScrollFrame_GetOffset(scrollFrame)
	local questName, questLevel = pfQuestCompat.GetQuestLogTitle(questIndex)
	local questids = pfDatabase:GetQuestIDs(questIndex)
	local questid = questids and tonumber(questids[1]) or 0

	if IsControlKeyDown() and not this.isHeader and ChatFrameEditBox:IsVisible() then
		self:InsertQuestLink_enUS(questid, questName)
		QuestLog_SetSelection(questIndex)
		--QuestLog_Update()
		return
	end
	self.hooks.QuestLogTitleButton_OnClick(button)
end
function Automaton_pfQuestSendLink:InsertQuestLink_enUS(questid, name)
	local questid = questid or 0
	local fallback = name or UNKNOWN
	local level = pfDB["quests"]["data"][questid] and pfDB["quests"]["data"][questid]["lvl"] or 0
	local name = pfDB["quests"]["enUS"][questid] and pfDB["quests"]["enUS"][questid]["T"] or fallback
	--mrbcat20230811
	local hex = pfUI.api.rgbhex(GetDifficultyColor(level))
	ChatFrameEditBox:Show()
	if pfQuest_config["questlinks"] == "1" then
		ChatFrameEditBox:Insert(hex .. "|Hquest:" .. questid .. ":" .. level .. "|h[" .. name .. "]|h|r")
	else
		ChatFrameEditBox:Insert("[" .. name .. "]")
	end
end

