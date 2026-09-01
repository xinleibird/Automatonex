assert(Automaton, "Automaton not found!")

------------------------------
--      Are you local?      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_Summon")
local seconds
local abacus = AceLibrary("Abacus-2.0")
----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function()
	return {

		["Summon"] = "自动接受术士召唤",
		["Options for accepting summons."] = "自动接受术士的召唤",
		["Delay"] = "延迟设置",
		["With this option enabled, automatic summons are delayed."] = "延迟接受召唤",
		["Delay Time"] = "延迟时间",
		["Set the time in seconds to delay automatic summon acceptance."] = "设置接受召唤的延迟时间",
		["Combat Delay"] = "战斗中延迟",
		["If summoned while in combat, accept the summon after combat ends."] = "退出战斗后接受召唤",
		["Combat Delay Time"] = "战斗中延迟时间",
		["Set the time in seconds to delay automatic summon acceptance after combat ends."] = "设置退出战斗后接受召唤的延迟时间",
		["Be Quiet!"] = "保持冷静!",
		["Suppress chat frame output from the Summon module."] = "召唤时如果对方在战斗则提示他.",
		["Cancelling summon..."] = "取消召唤...",
		["In combat! Accepting summon after combat ends..."] = "在战斗中! 战斗结束后接受召唤...",
		["Left combat. Accepting summon in %s..."] = "离开战斗 %s 秒后接受召唤 ",
		["Summon expired!"] = "召唤过期!",
		["Accepting summon in %s..."] = "在 %s 秒后接受召唤",
		["Accepting summon..."] = "接受召唤...",
	}
end)

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_Summon = Automaton:NewModule("Summon")
Automaton_Summon.modulename = L["Summon"]
Automaton_Summon.moduledesc = L["Options for accepting summons."]
Automaton_Summon.options = {
	delay = {
		type = "toggle",
		name = L["Delay"],
		desc = L["With this option enabled, automatic summons are delayed."],
		order = 2,
		get = function()
			return Automaton_Summon.db.profile.delay
		end,
		set = function(v)
			Automaton_Summon.db.profile.delay = v
		end,
	},
	delayTime = {
		type = "range",
		name = L["Delay Time"],
		desc = L["Set the time in seconds to delay automatic summon acceptance."],
		order = 3,
		get = function()
			return Automaton_Summon.db.profile.delayTime
		end,
		set = function(v)
			Automaton_Summon.db.profile.delayTime = v
		end,
		min = 5,
		max = 100,
		step = 1,
		bigStep = 5,
	},
	combatDelay = {
		type = "toggle",
		name = L["Combat Delay"],
		desc = L["If summoned while in combat, accept the summon after combat ends."],
		order = 4,
		get = function()
			return Automaton_Summon.db.profile.combatDelay
		end,
		set = function(v)
			Automaton_Summon.db.profile.combatDelay = v
		end,
	},
	combatDelayTime = {
		type = "range",
		name = L["Combat Delay Time"],
		desc = L["Set the time in seconds to delay automatic summon acceptance after combat ends."],
		order = 5,
		get = function()
			return Automaton_Summon.db.profile.combatDelayTime
		end,
		set = function(v)
			Automaton_Summon.db.profile.combatDelayTime = v
		end,
		min = 5,
		max = 30,
		step = 1,
		bigStep = 5,
	},
	quiet = {
		type = "toggle",
		name = L["Be Quiet!"],
		desc = L["Suppress chat frame output from the Summon module."],
		order = 6,
		get = function()
			return Automaton_Summon.db.profile.quiet
		end,
		set = function(v)
			Automaton_Summon.db.profile.quiet = v
		end,
	},
}

------------------------------
--      Initialization      --
------------------------------

function Automaton_Summon:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("Summon")
	Automaton:RegisterDefaults("Summon", "profile", {
		disabled = true,
		delay = true,
		delayTime = 20,
		combatDelay = true,
		combatDelayTime = 20,
		quiet = false,
	})
	Automaton:SetDisabledAsDefault(self, "Summon")

	self:RegisterOptions(self.options)
end

function Automaton_Summon:OnEnable()
	self:RegisterEvent("CONFIRM_SUMMON")

	StaticPopupDialogs["CONFIRM_SUMMON"].OnHide = function()
		if Automaton_Summon:IsEventScheduled("Automaton_SummonAccept") then
			Automaton_Summon:CancelScheduledEvent("Automaton_SummonAccept")
			Automaton_Summon:Print(L["Cancelling summon..."])
		end
		if Automaton_Summon:IsEventScheduled("Automaton_SummonTimeout") then
			Automaton_Summon:CancelScheduledEvent("Automaton_SummonTimeout")
		end
	end
end

function Automaton_Summon:OnDisable()
	self:UnregisterAllEvents()

	StaticPopupDialogs["CONFIRM_SUMMON"].OnHide = nil
end

------------------------------
--      Event Handlers      --
------------------------------

function Automaton_Summon:Spam(text)
	if not Automaton_Summon.db.profile.quiet then
		self:print(text)
	end
end

function Automaton_Summon:Confirm()
	if UnitAffectingCombat("player") then
		self:Spam(L["In combat! Accepting summon after combat ends..."])
		self:RegisterEvent("PLAYER_REGEN_ENABLED", "LeaveCombat")
		self:ScheduleEvent("Automaton_SummonTimeout", self.Timeout, GetSummonConfirmTimeLeft(), self)
		return
	end
	if self:IsEventScheduled("Automaton_SummonTimeout") then
		self:CancelScheduledEvent("Automaton_SummonTimeout")
	end
	ConfirmSummon()
	StaticPopup_Hide("CONFIRM_SUMMON")
end

function Automaton_Summon:LeaveCombat()
	seconds = Automaton_Summon.db.profile.combatDelayTime
	self:Spam(format(L["Left combat. Accepting summon in %s..."], abacus:FormatDurationExtended(seconds)))
	self:ScheduleEvent("Automaton_SummonAccept", self.Confirm, seconds, self)
	if self:IsEventRegistered("PLAYER_REGEN_ENABLED") then
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	end
end

function Automaton_Summon:Timeout()
	self:Spam(L["Summon expired!"])
	if self:IsEventScheduled("Automaton_SummonAccept") then
		self:CancelScheduledEvent("Automaton_SummonAccept")
	end
	if self:IsEventRegistered("PLAYER_REGEN_ENABLED") then
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	end
end

function Automaton_Summon:CONFIRM_SUMMON()
	if Automaton_Summon.db.profile.delay and not self:IsEventScheduled("Automaton_SummonAccept") then
		seconds = Automaton_Summon.db.profile.delayTime
		self:Spam(format(L["Accepting summon in %s..."], abacus:FormatDurationExtended(seconds)))
		self:ScheduleEvent("Automaton_SummonAccept", self.Confirm, seconds, self)
	elseif not self:IsEventScheduled("Automaton_SummonAccept") then
		self:Spam(L["Accepting summon..."])
		self:Confirm()
	end
end
