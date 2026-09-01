assert(Automaton, "Automaton not found!")

------------------------------
--      Are you local?      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_Dismount")

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function()
	return {
		["Dismount"] = true,
		["Automatically dismount when casting spells or interacting with flight masters"] = true,
	}
end)

L:RegisterTranslations("zhCN", function()
	return {
		["Dismount"] = "自动下马（PFUI请禁用）",
		["Automatically dismount when casting spells or interacting with flight masters"] = "施法或与飞行管理员对话时自动下马",
	}
end)

----------------------------------
--      Module Declaration      --
----------------------------------

Automaton_Dismount = Automaton:NewModule("Dismount")
Automaton_Dismount.modulename = L["Dismount"]
Automaton_Dismount.moduledesc = L["Automatically dismount when casting spells or interacting with flight masters"]
Automaton_Dismount.options = {}

------------------------------
--      Initialization      --
------------------------------

function Automaton_Dismount:OnInitialize()
	self:RegisterOptions(self.options)
end

function Automaton_Dismount:OnEnable()
	self:RegisterEvent("UI_ERROR_MESSAGE")
	self:RegisterEvent("TAXIMAP_OPENED")
end

function Automaton_Dismount:OnDisable()
	self:UnregisterAllEvents()
end

------------------------------
--      Core Logic          --
------------------------------

-- 坐骑/形态检测配置
local config = {
	-- 工具提示速度关键词（支持多语言）
	mountPatterns = {
		-- deDE
		"^Erhöht Tempo um (.+)%%",
		-- enUS
		"^Increases speed by (.+)%%",
		-- esES
		"^Aumenta la velocidad en un (.+)%%",
		-- frFR
		"^Augmente la vitesse de (.+)%%",
		-- ruRU
		"^Скорость увеличена на (.+)%%",
		-- koKR
		"^이동 속도 (.+)%%만큼 증가",
		-- zhCN
		"^速度提高(.+)%%",

		-- turtle-wow
		"speed based on",
		"Slow and steady...",
		"Riding",
		"根据您的骑行技能提高速度。",
		"根据骑术技能提高速度。",
		"又慢又稳......",
	},

	-- 需要取消的形态图标（小写匹配）
	shapeshiftIcons = {
		"ability_racial_bearform", -- 熊形态
		"ability_druid_catform", -- 猎豹形态
		"ability_druid_travelform", -- 旅行形态
		"spell_nature_spiritwolf", -- 幽灵狼
		"spell_shadow_shadowform", -- 暗影形态（牧师）
		"ability_druid_aquaticform", -- 水栖形态
	},

	-- 触发下马的错误消息列表
	errorMessages = {
		SPELL_FAILED_NOT_MOUNTED, -- 未上马时尝试下马
		ERR_ATTACK_MOUNTED, -- 马上攻击
		ERR_TAXIPLAYERALREADYMOUNTED, -- 马上使用飞行点
		SPELL_FAILED_NOT_SHAPESHIFT, -- 需要特定形态
		ERR_NOT_WHILE_SHAPESHIFTED, -- 形态限制
		ERR_TAXIPLAYERSHAPESHIFTED, -- 形态下使用飞行点
	},
}

-- 创建工具提示扫描器
local scanner = CreateFrame("GameTooltip", "DismountScanner", nil, "GameTooltipTemplate")
scanner:SetOwner(UIParent, "ANCHOR_NONE")

-- 核心下马逻辑
local function SmartDismount(msg)
	for i = 0, 31 do -- 遍历所有buff栏位
		local texture = GetPlayerBuffTexture(i)

		if texture then
			-- 通过工具提示检测坐骑

			scanner:ClearLines()
			scanner:SetPlayerBuff(i)
			local tipText = DismountScannerTextLeft2:GetText()
			-- 匹配速度描述关键词
			for _, pattern in ipairs(config.mountPatterns) do
				if tipText and string.find(tipText, pattern) then
					CancelPlayerBuff(i)
					return
				end
			end

			if msg and strfind(msg, "你正在变形状态下") then
				-- 匹配形态图标
				local lowerTexture = string.lower(texture)
				for _, icon in ipairs(config.shapeshiftIcons) do
					if string.find(lowerTexture, icon) then
						CancelPlayerBuff(i)
						return
					end
				end
			end
		end
	end
end

------------------------------
--      Event Handlers      --
------------------------------

function Automaton_Dismount:UI_ERROR_MESSAGE(msg)
	-- 匹配错误消息
	for _, errorMsg in ipairs(config.errorMessages) do
		if msg == errorMsg then
			SmartDismount(msg)
			return
		end
	end

	-- 自动站立功能（原auto-dismount.lua功能）
	if msg == SPELL_FAILED_NOT_STANDING then
		SitOrStand()
	end
end

function Automaton_Dismount:TAXIMAP_OPENED()
	-- 打开飞行点时强制下马
	SmartDismount()
end
