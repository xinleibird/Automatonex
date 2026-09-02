assert(Automaton, "Automaton not found!")

------------------------------
--      Are you local?      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_Queue")

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function()
	return {

		["Queue"] = "战场自动排队",
		["Options for accepting Battleground queues."] = "自动加入战场队列",
		["Delay"] = "进场延迟",
		["With this option enabled, automatic battleground entry is delayed for 100 seconds."] = "启用此选项后，自动战场进入延迟100秒",
		["Join"] = "自动加入列队",
		["Joins battleground queues when the battlefield window is displayed."] = "当战场窗口打开时自动加入战场队列",
		["Joining %s in 1:00..."] = "加入 %s  1:00...",
		["Joining %s..."] = "加入中 %s...",
	}
end)

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_Queue = Automaton:NewModule("Queue")
Automaton_Queue.modulename = L["Queue"]
Automaton_Queue.moduledesc = L["Options for accepting Battleground queues."]
Automaton_Queue.options = {
	delay = {
		type = "toggle",
		name = L["Delay"],
		desc = L["With this option enabled, automatic battleground entry is delayed for 100 seconds."],
		order = 2,
		get = function()
			return Automaton_Queue.db.profile.delay
		end,
		set = function(v)
			Automaton_Queue.db.profile.delay = v
		end,
	},
	join = {
		type = "toggle",
		name = L["Join"],
		desc = L["Joins battleground queues when the battlefield window is displayed."],
		order = 3,
		get = function()
			return Automaton_Queue:IsEventRegistered("BATTLEFIELDS_SHOW")
		end,
		set = function(v)
			if v then
				Automaton_Queue:RegisterEvent("BATTLEFIELDS_SHOW")
			else
				Automaton_Queue:UnregisterEvent("BATTLEFIELDS_SHOW")
			end
			Automaton_Queue.db.profile.join = v
		end,
	},
}

------------------------------
--      Initialization      --
------------------------------

function Automaton_Queue:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("Queue")
	Automaton:RegisterDefaults("Queue", "profile", {
		disabled = true,
		join = true,
		delay = true,
	})
	Automaton:SetDisabledAsDefault(self, "Queue")

	self:RegisterOptions(self.options)
end

function Automaton_Queue:OnEnable()
	if Automaton_Queue.db.profile.join then
		Automaton_Queue:RegisterEvent("BATTLEFIELDS_SHOW")
	end
	self:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
end

function Automaton_Queue:OnDisable()
	self:UnregisterAllEvents()
end

------------------------------
--      Event Handlers      --
------------------------------

function Automaton_Queue:UPDATE_BATTLEFIELD_STATUS()
	local active, confirm, map
	for i = 1, MAX_BATTLEFIELD_QUEUES do
		local status, mapName, instanceID = GetBattlefieldStatus(i)
		if status == "active" then
			active = true
		elseif status == "confirm" then
			confirm = i
			map = mapName .. " " .. instanceID
		end
	end

	if not confirm then
		return
	end

	if Automaton_Queue.db.profile.delay or active then
		self:print(format(L["Joining %s in 1:00..."], map))
		self:ScheduleEvent("Automaton_Queue" .. confirm, AcceptBattlefieldPort, 60, confirm, 1)
	elseif not self:IsEventScheduled("Automaton_Queue" .. confirm) then
		self:print(format(L["Joining %s..."], map))
		AcceptBattlefieldPort(confirm, 1)
	end
end

function Automaton_Queue:BATTLEFIELDS_SHOW()
	if IsShiftKeyDown() then
		return
	end
	if IsPartyLeader() or IsRaidLeader() then
		JoinBattlefield(0, 1)
	else
		JoinBattlefield(0)
	end
	HideUIPanel(BattlefieldFrame)
end
