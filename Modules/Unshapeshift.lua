assert(Automaton, "Automaton not found!")

------------------------------
--      Are you local?      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Unshapeshift")
local _, class = UnitClass("player")

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function()
	return {
		["Unshapeshift"] = true,
		["Automatically unshapeshift when you receive error messages about being shapeshifted"] = true,
	}
end)

L:RegisterTranslations("zhCN", function()
	return {
		["Unshapeshift"] = "自动解除形态（pfui禁用）",
		["Automatically unshapeshift when you receive error messages about being shapeshifted"] = "当报错提示时自动取消德鲁伊当前形态、萨满幽灵狼、牧师暗影形态",
	}
end)

----------------------------------
--      Module Declaration      --
----------------------------------

Unshapeshift = Automaton:NewModule("Unshapeshift")
Unshapeshift.modulename = L["Unshapeshift"]
Unshapeshift.moduledesc = L["Automatically unshapeshift when you receive error messages about being shapeshifted"]
Unshapeshift.options = {}

------------------------------
--      Initialization      --
------------------------------

function Unshapeshift:OnInitialize()
	self:RegisterOptions(self.options)
end

function Unshapeshift:OnEnable()
	self:RegisterEvent("UI_ERROR_MESSAGE")
end

function Unshapeshift:OnDisable()
	self:UnregisterAllEvents()
end

------------------------------
--      Event Handlers      --
------------------------------

messages = {
	[ERR_CANT_INTERACT_SHAPESHIFTED] = true,
	[ERR_NOT_WHILE_SHAPESHIFTED] = true,
	[SPELL_FAILED_NOT_SHAPESHIFT] = true,
	[SPELL_FAILED_ONLY_UNDERWATER] = true,
	[ERR_NO_ITEMS_WHILE_SHAPESHIFTED] = true,
	[SPELL_FAILED_NO_ITEMS_WHILE_SHAPESHIFTED] = true,
	[ERR_MOUNT_SHAPESHIFTED] = true,
	[SPELL_FAILED_MOVING] = true,
}

function Unshapeshift:UI_ERROR_MESSAGE(msg)
	if class == "PRIEST" and msg == messages[ERR_CANT_INTERACT_WHILE_SHAPESHIFTED] then
		return
	end
	if messages[msg] and strfind(msg, "在变形状态") then
		self:Unshapeshift()
	end
end

function Unshapeshift:Unshapeshift()
	if class == "DRUID" then
		for i = 1, GetNumShapeshiftForms() do
			local _, name, active = GetShapeshiftFormInfo(i)
			if active then
				CastShapeshiftForm(i)
				break
			end
		end
	elseif class == "SHAMAN" then
		for i = 0, 31, 1 do
			currBuffTex = GetPlayerBuffTexture(i)
			if currBuffTex then
				if string.find(string.lower(currBuffTex), "spell_nature_spiritwolf") then
					CancelPlayerBuff(i)
				end
			end
		end
	elseif class == "PRIEST" then
		for i = 0, 31, 1 do
			currBuffTex = GetPlayerBuffTexture(i)
			if currBuffTex then
				if string.find(string.lower(currBuffTex), "spell_shadow_shadowform") then
					CancelPlayerBuff(i)
				end
			end
		end
	end
end
