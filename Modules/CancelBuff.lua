assert(Automaton, "Automaton not found!")

------------------------------
--      Are you local?      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_CancelBuff")
local gratuity = AceLibrary("Gratuity-2.0")
----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function()
	return {

		["CancelBuff"] = "自动取消指定buff",
		["Auto cancel your buff that you not want keep its"] = "自动取消你不想保留的buff",
		["Add buff"] = "增加buff",
		["Add new buff"] = "增加你不想保留的buff名称",
		["List"] = "列表",
		["Print all buffs  name to the screen."] = "打印所有添加的buff名称到屏幕.",
		["Add a new buff name that you want aoto cancel, accepts mount buff name. Name must be exact, and is case sensitive."] = "添加一个buff名称, 名字必须精确并且是区分大小写.",
		["<Buff name>"] = "<buff名称>",
		["Remove buff"] = "删除BUFF",
		["Removes a buff in list. It must be entered exactly as it was added."] = "从新增的buff列表中删除对象.名称必须和添加时一样",
		["Purge"] = "全部清除",
		["Remove all from the buff list."] = "从buff列表中移除所有项目",
		["No buff"] = "没有添加buff",
		["These buff name:"] = "您添加的buff:",
		[" buffs purged."] = " 个buff被清除",
	}
end)

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_CancelBuff = Automaton:NewModule("CancelBuff")
Automaton_CancelBuff.modulename = L["CancelBuff"]
Automaton_CancelBuff.moduledesc = L["Auto cancel your buff that you not want keep its"]
Automaton_CancelBuff.options = {
	ignore = {
		type = "group",
		name = L["Add buff"],
		desc = L["Add new buff"],
		args = {
			list = {
				type = "execute",
				name = L["List"],
				desc = L["Print all buffs  name to the screen."],
				func = function()
					Automaton_CancelBuff:ListBuffs()
				end,
			},
			add = {
				type = "text",
				name = L["Add buff"],
				desc = L["Add a new buff name that you want aoto cancel, accepts mount buff name. Name must be exact, and is case sensitive."],
				order = 1,
				usage = L["<Buff name>"],
				get = false,
				set = function(v)
					Automaton_CancelBuff:NewBuff(v)
				end,
			},
			remove = {
				type = "text",
				name = L["Remove buff"],
				desc = L["Removes a buff in list. It must be entered exactly as it was added."],
				order = 2,
				usage = L["<Buff name>"],
				get = false,
				set = function(v)
					Automaton_CancelBuff:RemoveBuffs(v)
				end,
			},
			purge = {
				type = "execute",
				name = L["Purge"],
				desc = L["Remove all from the buff list."],
				func = function()
					Automaton_CancelBuff:PurgeBuffs()
				end,
			},
		},
	},
}

------------------------------
--      Initialization      --
------------------------------

function Automaton_CancelBuff:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("CancelBuff")
	-- 将 "profile" 改为 "char" 以实现按角色保存配置
	Automaton:RegisterDefaults("CancelBuff", "char", {
		useGarbageFu = false,
		buffs = {},
	})
	self:RegisterOptions(self.options)
end

function Automaton_CancelBuff:OnEnable()
	self:RegisterEvent("PLAYER_AURAS_CHANGED")
end

function Automaton_CancelBuff:OnDisable()
	self:UnregisterAllEvents()
end

------------------------------
--      Event Handlers      --
------------------------------
function Automaton_CancelBuff:CancelBuff()
	-- 访问 char 表而不是 profile 表
	for k, v in pairs(self.db.char.buffs) do
		for i = 0, 31, 1 do
			gratuity:SetPlayerBuff(i)
			local name = gratuity:GetLine(1)
			if not name then
				break
			end
			if name == v then
				CancelPlayerBuff(i)
			end
		end
	end
end

function Automaton_CancelBuff:PLAYER_AURAS_CHANGED()
	self:CancelBuff()
end

function Automaton_CancelBuff:NewBuff(mountbuff)
	-- 访问 char 表而不是 profile 表
	tinsert(self.db.char.buffs, mountbuff)
	self:CancelBuff()
end

function Automaton_CancelBuff:RemoveBuffs(mountbuff)
	-- 访问 char 表而不是 profile 表
	for k, v in pairs(self.db.char.buffs) do
		if v == mountbuff then
			self.db.char.buffs[k] = nil
		end
	end
end

function Automaton_CancelBuff:ListBuffs()
	-- 访问 char 表而不是 profile 表
	if table.getn(self.db.char.buffs) == 0 then
		Automaton_CancelBuff:Print(L["No buff"]) -- 使用全局Print函数
	else
		Automaton_CancelBuff:Print(L["These buff name:"]) -- 使用全局Print函数
		for k, v in pairs(self.db.char.buffs) do
			Automaton_CancelBuff:Print(string.format("- %s", v)) -- 使用全局Print函数并格式化输出
		end
	end
end

function Automaton_CancelBuff:PurgeBuffs()
	-- 访问 char 表而不是 profile 表
	Automaton_CancelBuff:Print(table.getn(self.db.char.buffs) .. L[" buffs purged."]) -- 使用全局Print函数
	self.db.char.buffs = {}
end
