assert(Automaton, "Automaton not found!")

------------------------------
--      Are you local?      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_Plates")

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function()
	return {
		["Plates"] = "姓名版自动管理",
		["Hides player name in city and shows name plates in combat."] = "主城隐藏玩家名字，战斗中自动显示姓名版",
		["Hide player name in city"] = "主城隐藏玩家名字",
		["Show name plates in combat"] = "战斗中显示姓名版",
	}
end)

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_Plates = Automaton:NewModule("Plates")
Automaton_Plates.modulename = L["Plates"]
Automaton_Plates.moduledesc = L["Hides player name in city and shows name plates in combat."]
Automaton_Plates.options = {
	hidePlayerNameInCity = {
		type = "toggle",
		name = L["Hide player name in city"],
		desc = "在主城中自动隐藏玩家名字",
		get = function()
			return Automaton_Plates.db.profile.hidePlayerNameInCity
		end,
		set = function(v)
			Automaton_Plates.db.profile.hidePlayerNameInCity = v
			Automaton_Plates:CheckZone()
		end,
		order = 2,
	},
	showNameplatesInCombat = {
		type = "toggle",
		name = L["Show name plates in combat"],
		desc = "战斗中自动显示姓名版，非战斗中自动隐藏",
		get = function()
			return Automaton_Plates.db.profile.showNameplatesInCombat
		end,
		set = function(v)
			local wasEnabled = Automaton_Plates.db.profile.showNameplatesInCombat
			Automaton_Plates.db.profile.showNameplatesInCombat = v

			if wasEnabled and not v then
				Automaton_Plates:RestoreNameplatesToOriginal(true)
			elseif not wasEnabled and v then
				Automaton_Plates:CheckCombatState()
			end
		end,
		order = 3,
	},
}

------------------------------
--      Initialization      --
------------------------------

function Automaton_Plates:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("Plates")
	Automaton:RegisterDefaults("Plates", "profile", {
		disabled = false,
		hidePlayerNameInCity = false,
		showNameplatesInCombat = false,
		playerNameSettingInWild = "1", -- 野外玩家名字显示设置
		playerNameSettingInCity = "0", -- 主城玩家名字显示设置
	})
	Automaton:SetDisabledAsDefault(self, "Plates")

	self:RegisterOptions(self.options)

	self.cityZones = {
		["暴风城"] = true,
		["铁炉堡"] = true,
		["达纳苏斯"] = true,
		["冬幕谷"] = true,
		["奥格瑞玛"] = true,
		["雷霆崖"] = true,
		["幽暗城"] = true,
		-- 如果需要可以添加更多主城区域
		["艾萨拉"] = false, -- 示例：非主城区域
	}

	self.currentZone = nil
	self.initialized = false
	self.hasSavedOriginalNameplates = false
	self.inCombat = false
	self.nameplatesForcedByCombat = false
	self.originalNameplateSettings = nil
end

function Automaton_Plates:OnEnable()
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")

	self.initialized = false
	-- 延迟初始化，确保游戏完全加载
	self:ScheduleEvent(function()
		self.initialized = true
		self:SaveOriginalNameplates()
		self:CheckZone()
		self:CheckCombatState()
	end, 2)
end

function Automaton_Plates:OnDisable()
	self:RestorePlayerName()
	self:RestoreNameplatesToOriginal(true)
	self:UnregisterAllEvents()
	self:CancelScheduledEvent("Automaton_Plates_CheckManualChange")
end

------------------------------
--      Event Handlers      --
------------------------------

function Automaton_Plates:ZONE_CHANGED_NEW_AREA()
	if self.initialized then
		self:CheckZone()
	end
end

function Automaton_Plates:PLAYER_ENTERING_WORLD()
	self:ScheduleEvent(function()
		if not self.initialized then
			self.initialized = true
			self:SaveOriginalNameplates()
		end
		self:CheckZone()
		self:CheckCombatState()
	end, 0.5)
end

function Automaton_Plates:PLAYER_REGEN_ENABLED()
	self.inCombat = false
	if self.initialized then
		self:CheckCombatState()
	end
end

function Automaton_Plates:PLAYER_REGEN_DISABLED()
	self.inCombat = true
	if self.initialized then
		self:CheckCombatState()
	end
end

------------------------------
--      Custom Functions    --
------------------------------

function Automaton_Plates:SaveOriginalNameplates()
	if self.hasSavedOriginalNameplates then
		return
	end
	self.originalNameplateSettings = { state = true }
	self.hasSavedOriginalNameplates = true
end

function Automaton_Plates:RestoreNameplatesToOriginal(force)
	if not force and self.db.profile.showNameplatesInCombat then
		return
	end
	ShowNameplates()
	self.nameplatesForcedByCombat = false
end

-- 检查当前区域并处理玩家名字显示
function Automaton_Plates:CheckZone()
	if not self.initialized then
		return
	end

	local zone = GetZoneText()
	local isInCity = self.cityZones[zone] or false

	-- 如果区域没有变化，不需要处理
	if self.currentZone == (isInCity and "city" or "wild") then
		return
	end

	self.currentZone = isInCity and "city" or "wild"

	-- 根据模块设置决定是否处理玩家名字显示
	if self.db.profile.hidePlayerNameInCity then
		if isInCity then
			-- 进入主城：设置玩家名字为隐藏
			SetCVar("UnitNamePlayer", self.db.profile.playerNameSettingInCity)
		else
			-- 离开主城：恢复玩家名字显示
			SetCVar("UnitNamePlayer", self.db.profile.playerNameSettingInWild)
		end
	else
		-- 模块关闭：恢复为野外设置
		SetCVar("UnitNamePlayer", self.db.profile.playerNameSettingInWild)
	end
end

-- 检查战斗状态
function Automaton_Plates:CheckCombatState()
	if not self.initialized then
		return
	end

	if self.db.profile.showNameplatesInCombat then
		if self.inCombat then
			self:ShowNameplatesInCombat()
		else
			self:HideNameplatesOutOfCombat()
		end
	else
		self:RestoreNameplatesToOriginal()
	end
end

-- 恢复玩家名字显示
function Automaton_Plates:RestorePlayerName()
	-- 总是恢复为野外设置
	SetCVar("UnitNamePlayer", self.db.profile.playerNameSettingInWild)
end

-- 显示战斗中的姓名版
function Automaton_Plates:ShowNameplatesInCombat()
	if not self.hasSavedOriginalNameplates then
		self:SaveOriginalNameplates()
	end
	ShowNameplates()
	self.nameplatesForcedByCombat = true
end

-- 非战斗中隐藏姓名版
function Automaton_Plates:HideNameplatesOutOfCombat()
	if not self.hasSavedOriginalNameplates then
		self:SaveOriginalNameplates()
	end
	HideNameplates()
	self.nameplatesForcedByCombat = true
end

-- 添加一个手动切换玩家名字的函数（可选）
function Automaton_Plates:TogglePlayerName()
	local current = GetCVar("UnitNamePlayer")
	if current == "1" then
		SetCVar("UnitNamePlayer", "0")
	else
		SetCVar("UnitNamePlayer", "1")
	end
end
