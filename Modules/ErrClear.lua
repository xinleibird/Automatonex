assert(Automaton, "Automaton not found!")

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_ErrClear = Automaton:NewModule("ErrClear")
Automaton_ErrClear.modulename = "错误信息屏蔽"
Automaton_ErrClear.moduledesc =
	"屏蔽一些错误信息例如：物品还没准备好，距离太远（支持自定义错误文本）"
Automaton_ErrClear.options = {
	ignore = {
		type = "group",
		name = "自定义错误管理",
		desc = "添加/删除需要屏蔽的错误文本",
		args = {
			list = {
				type = "execute",
				name = "列表",
				desc = "显示所有已添加的自定义错误文本",
				func = function()
					Automaton_ErrClear:ListErrors()
				end,
			},
			add = {
				type = "text",
				name = "添加错误",
				desc = "添加需要屏蔽的错误文本（精确匹配，区分大小写）",
				order = 1,
				usage = "<错误文本>",
				get = false,
				set = function(v)
					Automaton_ErrClear:NewError(v)
				end,
			},
			remove = {
				type = "text",
				name = "删除错误",
				desc = "删除已添加的错误文本（必须与添加时完全一致）",
				order = 2,
				usage = "<错误文本>",
				get = false,
				set = function(v)
					Automaton_ErrClear:RemoveError(v)
				end,
			},
			purge = {
				type = "execute",
				name = "清空全部",
				desc = "清空所有自定义错误文本",
				func = function()
					Automaton_ErrClear:PurgeErrors()
				end,
			},
		},
	},
}

------------------------------
--      Initialization      --
------------------------------

-- 内置默认错误列表（保持不变）
local defaultErrList = {
	ERR_ITEM_COOLDOWN,
	ERR_ABILITY_COOLDOWN,
	ERR_SPELL_COOLDOWN,
	ERR_POTION_COOLDOWN,
	"不能在移动中",
	"你还不能那么做",
	"怒气不足",
	"你无法观察那个单位",
	SPELL_FAILED_MOVING,
	ERR_NOEMOTEWHILERUNNING,
	ERR_USE_TOO_FAR,
	ERR_UNIT_NOT_FOUND,
	ERR_VENDOR_TOO_FAR,
	ERR_SPELL_OUT_OF_RANGE,
	ERR_OUT_OF_ENERGY,
	ERR_GENERIC_NO_TARGET,
	SPELL_FAILED_NO_COMBO_POINTS,
	ERR_INVALID_ATTACK_TARGET,
	ERR_NO_ATTACK_TARGET,
	SPELL_FAILED_BAD_TARGETS,
	"未知",
	SPELL_FAILED_INTERRUPTED,
	SPELL_FAILED_SPELL_IN_PROGRESS,
	ERR_UNIT_NOT_FOUND, -- 重复项，无影响
	ERR_SPELL_FAILED_ANOTHER_IN_PROGRESS,
	SPELL_FAILED_TOO_CLOSE,
	ERR_BADATTACKPOS,
	ERR_OUT_OF_MANA,
}

function Automaton_ErrClear:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("ErrClear")
	-- 使用 char 命名空间实现按角色保存自定义错误列表
	Automaton:RegisterDefaults("ErrClear", "char", {
		disabled = false, -- 模块总开关（继承自原设计）
		customErrors = {}, -- 用户自定义错误文本列表
	})
	Automaton:SetDisabledAsDefault(self, "ErrClear")

	self:RegisterOptions(self.options)
end

function Automaton_ErrClear:OnEnable()
	self:Hook(UIErrorsFrame, "AddMessage")
end

function Automaton_ErrClear:OnDisable()
	self:UnregisterAllEvents()
end

------------------------------
--      Error Filter        --
------------------------------

function Automaton_ErrClear:AddMessage(f, message, a1, a2, a3, a4)
	-- 先检查内置默认列表
	for _, v in pairs(defaultErrList) do
		if strfind(message, v) then
			return -- 屏蔽该错误
		end
	end
	-- 再检查用户自定义列表
	for _, v in pairs(self.db.char.customErrors) do
		if strfind(message, v) then
			return
		end
	end
	-- 未匹配任何规则，正常显示
	self.hooks[UIErrorsFrame].AddMessage(f, message, a1, a2, a3, a4)
end

------------------------------
--   Custom Error Management--
------------------------------

function Automaton_ErrClear:NewError(errorText)
	if not errorText or errorText == "" then
		self:Print("错误文本不能为空")
		return
	end
	tinsert(self.db.char.customErrors, errorText)
	self:Print("已添加错误屏蔽: " .. errorText)
end

function Automaton_ErrClear:RemoveError(errorText)
	for k, v in pairs(self.db.char.customErrors) do
		if v == errorText then
			table.remove(self.db.char.customErrors, k)
			self:Print("已删除错误屏蔽: " .. errorText)
			return
		end
	end
	self:Print("未找到匹配的错误文本: " .. errorText)
end

function Automaton_ErrClear:ListErrors()
	local count = table.getn(self.db.char.customErrors)
	if count == 0 then
		self:Print("当前没有自定义错误文本")
	else
		self:Print("当前自定义错误列表：")
		for i, v in ipairs(self.db.char.customErrors) do
			self:Print(string.format("%d. %s", i, v))
		end
	end
end

function Automaton_ErrClear:PurgeErrors()
	local count = table.getn(self.db.char.customErrors)
	self.db.char.customErrors = {}
	self:Print(string.format("已清空 %d 个自定义错误文本", count))
end
