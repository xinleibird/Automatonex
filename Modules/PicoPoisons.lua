assert(Automaton, "Automaton not found!")

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_PicoPoisons = Automaton:NewModule("PicoPoisons")
Automaton_PicoPoisons.modulename = "毒药次数显示"
Automaton_PicoPoisons.moduledesc = "在武器附魔图标上显示毒药剩余次数"

------------------------------
--      Initialization      --
------------------------------

function Automaton_PicoPoisons:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("PicoPoisons")
	Automaton:RegisterDefaults("PicoPoisons", "char", {
		disabled = false,
	})
	Automaton:SetDisabledAsDefault(self, "PicoPoisons")

	self:RegisterOptions(self:GetOptions())

	-- 初始化毒药次数标签
	self:InitPoisonChargesLabels()
end

function Automaton_PicoPoisons:OnEnable()
	-- 保存原函数并挂钩
	self.old_BuffFrame_Enchant_OnUpdate = BuffFrame_Enchant_OnUpdate
	BuffFrame_Enchant_OnUpdate = function(elapsed)
		self:BuffFrame_Enchant_OnUpdate(elapsed)
	end

	-- 强制更新一次以立即显示次数
	if self.old_BuffFrame_Enchant_OnUpdate then
		self.old_BuffFrame_Enchant_OnUpdate(0)
	end
end

function Automaton_PicoPoisons:OnDisable()
	-- 恢复原函数
	if self.old_BuffFrame_Enchant_OnUpdate then
		BuffFrame_Enchant_OnUpdate = self.old_BuffFrame_Enchant_OnUpdate
	end

	-- 隐藏所有毒药次数标签
	for i = 1, 2 do
		local chargesLabel = getglobal("TempEnchant" .. i .. "ChargesLabel")
		if chargesLabel then
			chargesLabel:Hide()
		end
	end

	-- 强制更新一次以恢复原始显示
	if self.old_BuffFrame_Enchant_OnUpdate then
		self.old_BuffFrame_Enchant_OnUpdate(0)
	end
end

------------------------------
--      Core Functions      --
------------------------------

function Automaton_PicoPoisons:InitPoisonChargesLabels()
	-- 为附魔图标创建次数标签
	for i = 1, 2 do
		local enchantButton = getglobal("TempEnchant" .. i)
		if enchantButton and not getglobal("TempEnchant" .. i .. "ChargesLabel") then
			local label =
				enchantButton:CreateFontString(enchantButton:GetName() .. "ChargesLabel", "ARTWORK", "NumberFontNormal")
			label:SetPoint("BOTTOMLEFT", enchantButton, "BOTTOMLEFT", 1, 1)
			label:Hide()
		end
	end
end

function Automaton_PicoPoisons:BuffFrame_Enchant_OnUpdate(elapsed)
	-- 调用原函数
	if self.old_BuffFrame_Enchant_OnUpdate then
		self.old_BuffFrame_Enchant_OnUpdate(elapsed)
	end

	-- 只有在模块启用时才显示毒药次数
	if not Automaton:IsModuleActive("PicoPoisons") then
		return
	end

	local hasMainHandEnchant, mainHandExpiration, mainHandCharges, hasOffHandEnchant, offHandExpiration, offHandCharges =
		GetWeaponEnchantInfo()
	local buttonIndex = 1

	-- 更新副手毒药次数
	if hasOffHandEnchant then
		local chargesLabel = getglobal("TempEnchant" .. buttonIndex .. "ChargesLabel")
		if chargesLabel then
			chargesLabel:SetText(offHandCharges)
			if offHandCharges > 0 then
				chargesLabel:Show()
			else
				chargesLabel:Hide()
			end
		end
		buttonIndex = buttonIndex + 1
	end

	-- 更新主手毒药次数
	if hasMainHandEnchant then
		local chargesLabel = getglobal("TempEnchant" .. buttonIndex .. "ChargesLabel")
		if chargesLabel then
			chargesLabel:SetText(mainHandCharges)
			if mainHandCharges > 0 then
				chargesLabel:Show()
			else
				chargesLabel:Hide()
			end
		end
		buttonIndex = buttonIndex + 1
	end

	-- 隐藏未使用的标签
	for i = buttonIndex, 2 do
		local chargesLabel = getglobal("TempEnchant" .. i .. "ChargesLabel")
		if chargesLabel then
			chargesLabel:Hide()
		end
	end
end

------------------------------
--      Options Panel        --
------------------------------

function Automaton_PicoPoisons:GetOptions()
	return {
		enabled = {
			order = 1,
			type = "toggle",
			name = "启用毒药次数显示",
			desc = "在武器附魔图标上显示毒药剩余次数",
			get = function()
				return Automaton:IsModuleActive("PicoPoisons")
			end,
			set = function(info, v)
				Automaton:ToggleModuleActive("PicoPoisons", v)
			end,
		},
	}
end
