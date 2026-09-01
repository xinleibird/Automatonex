assert(Automaton, "Automaton not found!")

----------------------------------
--      Module Declaration      --
----------------------------------

Automaton_ShaguStance = Automaton:NewModule("ShaguStance")
Automaton_ShaguStance.modulename = "自动姿态切换"
Automaton_ShaguStance.moduledesc = "根据技能需要自动切换战士和德鲁伊的姿态"
Automaton_ShaguStance.options = {}

------------------------------
--      Initialization      --
------------------------------

-- 辅助函数：分割字符串（原模块已有）
local function strsplit(delimiter, subject)
	local delimiter, fields = delimiter or ":", {}
	local pattern = string.format("([^%s]+)", delimiter)
	string.gsub(subject, pattern, function(c)
		fields[table.getn(fields) + 1] = c
	end)
	return unpack(fields)
end

-- 形态名称映射（原模块已有）
local formatstr = {
	["豹形态"] = "猎豹形态",
}

-- 检测是否为乌龟服（新增）
local function checkTurtle()
	local build = GetBuildInfo()
	local function mysplit(inputstr, sep)
		if sep == nil then
			sep = "%s"
		end
		local t = {}
		for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
			table.insert(t, str)
		end
		return t
	end
	local s = mysplit(build, ".")
	return tonumber(s[2]) >= 16
end

function Automaton_ShaguStance:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("ShaguStance")
	Automaton:RegisterDefaults("ShaguStance", "profile", {
		disabled = true,
	})
	Automaton:SetDisabledAsDefault(self, "ShaguStance")
	self:RegisterOptions(self.options)
	self.scanString = string.gsub(SPELL_FAILED_ONLY_SHAPESHIFT, "%%s", "(.+)")

	-- 新增：乌龟服标识
	self.isTurtle = checkTurtle()
end

function Automaton_ShaguStance:OnEnable()
	self:RegisterEvent("UI_ERROR_MESSAGE")
	self.DoCast = CastSpellByName
	self:Hook("CastSpell")
	self:Hook("CastSpellByName")
	self:Hook("UseAction")
	self.lastError = ""

	-- 新增：为德鲁伊创建专用的 Tooltip
	if select(2, UnitClass("player")) == "DRUID" then
		self.tip = CreateFrame("GameTooltip", "Automaton_ShaguStance_Tip", nil, "GameTooltipTemplate")
		self.tip:SetOwner(UIParent, "ANCHOR_NONE")
	end
end

function Automaton_ShaguStance:OnDisable()
	self:UnregisterAllEvents()
	self:UnhookAll()
	self.lastError = ""

	-- 清理 Tooltip
	if self.tip then
		self.tip:Hide()
		self.tip = nil
	end
end

------------------------------
--      Event Handlers      --
------------------------------

function Automaton_ShaguStance:UI_ERROR_MESSAGE()
	self.lastError = arg1
end

-- 原切换函数：基于错误信息（保留作为后备）
function Automaton_ShaguStance:SwitchStance()
	for stances in string.gfind(self.lastError, self.scanString) do
		for _, stance in pairs({ strsplit(",", stances) }) do
			self.DoCast(string.gsub(formatstr[stance] or stance, "^%s*(.-)%s*$", "%1"))
		end
	end
	self.lastError = ""
end

-- ========== 新增：德鲁伊主动形态切换逻辑 ==========
-- 解除当前形态
function Automaton_ShaguStance:Unshapeshift()
	for i = 1, GetNumShapeshiftForms() do
		local active = select(3, GetShapeshiftFormInfo(i))
		if active then
			CastShapeshiftForm(i)
			break
		end
	end
end

-- 检查并切换德鲁伊形态（在施法前调用）
function Automaton_ShaguStance:CheckAndSwitchDruidForm(spellName)
	-- 仅德鲁伊处理
	if select(2, UnitClass("player")) ~= "DRUID" then
		return
	end
	if not spellName or spellName == "" then
		return
	end
	if not self.tip then
		return
	end

	local powerType = UnitPowerType("player")
	local i = 1
	while true do
		local name = GetSpellName(i, BOOKTYPE_SPELL)
		if not name then
			break
		end
		if name == spellName then
			self.tip:ClearLines()
			self.tip:SetSpell(i, BOOKTYPE_SPELL)

			-- 检查第3、4行（形态需求）
			for j = 3, 4 do
				local reqText = _G[self.tip:GetName() .. "TextLeft" .. j]:GetText()
				if reqText then
					-- 中文客户端常用需求文本，可根据需要扩展
					if reqText == "需要熊形态, 巨熊形态" and powerType ~= 1 then
						CastShapeshiftForm(1) -- 切换到熊形态
						return
					elseif reqText == "需要豹形态" and powerType ~= 3 then
						CastShapeshiftForm(3) -- 切换到豹形态
						return
					end
				end
			end

			-- 检查第2行（法力消耗）
			local manaText = _G[self.tip:GetName() .. "TextLeft2"]:GetText()
			if manaText and string.find(manaText, MANA_COST) and powerType ~= 0 then
				-- 乌龟服特殊处理：自然之握（熊形态可用）和重整（可能？）
				if
					self.isTurtle
					and (
						(string.find(spellName, "自然之握") and powerType == 1) or string.find(spellName, "重整")
					)
				then
				-- 不做解除，保持当前形态
				else
					self:Unshapeshift() -- 解除形态回到人形/施法形态
				end
			end
			break
		end
		i = i + 1
	end
end
-- =================================================

-- 以下为 Hook 函数，已在原函数执行前插入德鲁伊主动检查
function Automaton_ShaguStance:CastSpell(spellId, spellbookTabNum)
	-- 新增：德鲁伊主动形态检查
	local spellName = GetSpellName(spellId, spellbookTabNum)
	self:CheckAndSwitchDruidForm(spellName)

	-- 原逻辑（基于错误的后备）
	self:SwitchStance()
	return self.hooks.CastSpell(spellId, spellbookTabNum)
end

function Automaton_ShaguStance:CastSpellByName(spellName, onSelf)
	-- 新增：德鲁伊主动形态检查
	local _, _, rawName = string.find(spellName, "^([^%(]+)") -- 去除等级后缀
	self:CheckAndSwitchDruidForm(rawName or spellName)

	self:SwitchStance()
	return self.hooks.CastSpellByName(spellName, onSelf)
end

function Automaton_ShaguStance:UseAction(slot, checkCursor, onSelf)
	-- 新增：德鲁伊主动形态检查
	local spellName = nil
	if not GetActionText(slot) then
		if self.tip then
			self.tip:ClearLines()
			self.tip:SetAction(slot)
			spellName = _G[self.tip:GetName() .. "TextLeft1"]:GetText()
		end
	end
	self:CheckAndSwitchDruidForm(spellName)

	self:SwitchStance()
	return self.hooks.UseAction(slot, checkCursor, onSelf)
end
