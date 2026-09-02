assert(Automaton, "Automaton not found!")

------------------------------
--      Are you local?      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_ClearCache")

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function()
	return {

		["ClearCache"] = "自动清理游戏缓存",
		["Decline all incoming duels. Like the ClearCache you are."] = "定时清理游戏缓存，会解决部分卡顿问题，也会带来卡顿问题，自行选择使用。",
		["Delay Time"] = "多大缓存垃圾清理一次（单位：m）",
		["Set the time, in seconds"] = "设置当缓存垃圾多大时清理一次缓存垃圾，数值越小清理频率越高。",
	}
end)

----------------------------------
--      Module Declaration      --
----------------------------------

Automaton_ClearCache = Automaton:NewModule("ClearCache")
Automaton_ClearCache.modulename = L["ClearCache"]
Automaton_ClearCache.moduledesc = L["Decline all incoming duels. Like the ClearCache you are."]
Automaton_ClearCache.options = {
	optmem = {
		type = "range",
		name = L["Delay Time"],
		desc = L["Set the time, in seconds"],
		get = function()
			return Automaton_ClearCache.db.profile.optmem
		end,
		set = function(v)
			Automaton_ClearCache.db.profile.optmem = v
		end,
		min = 5,
		max = 25,
		step = 1,
		bigStep = 5,
	},
}

------------------------------
--      Initialization      --
------------------------------

function Automaton_ClearCache:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("ClearCache")
	Automaton:RegisterDefaults("ClearCache", "profile", {
		disabled = false,
		optmem = 10,
	})
	Automaton:SetDisabledAsDefault(self, "ClearCache")
	self:RegisterOptions(self.options)
	self.f = CreateFrame("Frame")
	self.lasttime = GetTime()
	self.lastMem = gcinfo()
end

function Automaton_ClearCache:OnEnable()
	self:HookScript(self.f, "OnUpdate", "OnUpdate")
end

function Automaton_ClearCache:OnDisable()
	self:UnhookAll()
end
function Automaton_ClearCache:OnUpdate()
	local curtime = GetTime()
	self.curMem = gcinfo()
	if self.curMem - self.lastMem > self.db.profile.optmem * 1024 then
		collectgarbage()
		self.lastMem = gcinfo()
	end
end
