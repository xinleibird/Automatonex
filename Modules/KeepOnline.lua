assert(Automaton, "Automaton not found!")

------------------------------
--      Are you local?      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("KeepOnline")

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function()
	return {
		["KeepOnline"] = true,
		["Keep you online when you AFK(tips:please leave the rest area)"] = true,
	}
end)

L:RegisterTranslations("zhCN", function()
	return {
		["KeepOnline"] = "自动挂机",
		["Keep you online when you AFK(tips:please leave the rest area)"] = "当你AKF弹出小退窗口后自动取消（提示：若开启此功能请离开休息区）",
	}
end)

----------------------------------
--      Module Declaration      --
----------------------------------

KeepOnline = Automaton:NewModule("KeepOnline")
KeepOnline.modulename = L["KeepOnline"]
KeepOnline.moduledesc = L["Keep you online when you AFK(tips:please leave the rest area)"]
KeepOnline.options = {}

------------------------------
--      Initialization      --
------------------------------

function KeepOnline:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("KeepOnline")
	Automaton:RegisterDefaults("KeepOnline", "profile", {
		disabled = true,
	})
	Automaton:SetDisabledAsDefault(self, "KeepOnline")

	self:RegisterOptions(self.options)
end

function KeepOnline:OnEnable()
	self:RegisterEvent("PLAYER_CAMPING")
end

function KeepOnline:OnDisable()
	self:UnregisterAllEvents()
end

------------------------------
--      Event Handlers      --
------------------------------
local function CloseCamping()
	for i = 1, STATICPOPUP_NUMDIALOGS do
		local KeepOnlineFrame = getglobal("StaticPopup" .. i)
		if KeepOnlineFrame:IsVisible() then
			getglobal("StaticPopup" .. i .. "Button1"):Click()
		end
	end
end

function KeepOnline:PLAYER_CAMPING()
	QueueFunction(CloseCamping)
end
