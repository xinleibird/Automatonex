local _, enclass = UnitClass("player")
if enclass ~= "HUNTER" then
	return
end
assert(Automaton, "Automaton not found!")

-- 引入 Gratuity 库用于获取 buff 名称
local gratuity = AceLibrary("Gratuity-2.0")
if not gratuity then
	Automaton:Print("CancelTiger: Gratuity-2.0 未找到，模块已禁用。")
	return
end

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_CancelTiger = Automaton:NewModule("CancelTiger")
Automaton_CancelTiger.modulename = "猎人自动取消猎豹守护"
Automaton_CancelTiger.moduledesc =
	"当开启猎豹或者豹群守护后，如果自己或队友（含宠物）受到眩晕效果，自动取消守护"
Automaton_CancelTiger.options = {
	checkparty = {
		type = "toggle",
		name = "监测队友和队友宠物",
		desc = "当队友和队友宠物受到攻击时同样取消守护",
		get = function()
			return Automaton_CancelTiger.db.profile.checkparty
		end,
		set = function(v)
			Automaton_CancelTiger.db.profile.checkparty = v
		end,
	},
}

------------------------------
--      Initialization      --
------------------------------

function Automaton_CancelTiger:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("CancelTiger")
	Automaton:RegisterDefaults("CancelTiger", "profile", {
		disabled = false,
		checkparty = true,
	})
	Automaton:SetDisabledAsDefault(self, "CancelTiger")

	self:RegisterOptions(self.options)
end

function Automaton_CancelTiger:OnEnable()
	-- 注册 debuff 事件
	self:RegisterEvent("SpecialEvents_PlayerDebuffGained", "PlayerDebuffGained")
	if self.db.profile.checkparty then
		self:RegisterEvent("SpecialEvents_UnitDebuffGained", "UnitDebuffGained")
	end
end

function Automaton_CancelTiger:OnDisable()
	self:UnregisterAllEvents()
end

------------------------------
--      Helper Functions    --
------------------------------

-- 取消猎豹守护/豹群守护（如果存在）
local function CancelTigerBuff()
	-- 如果玩家在坐骑上，不取消（避免误操作）
	if type(UnitIsMounted) == "function" and UnitIsMounted("player") then
		return
	end

	for i = 0, 31 do
		gratuity:SetPlayerBuff(i)
		local name = gratuity:GetLine(1)
		if not name then
			break
		end
		if name == "猎豹守护" or name == "豹群守护" then
			CancelPlayerBuff(i)
			return
		end
	end
end

-- 眩晕类 debuff 名称列表（可根据需要补充）
local stunDebuffs = {
	"眩晕",
	"昏迷",
	"击昏",
	-- 英文客户端
	"Stun",
	-- 其他可能的翻译
}

-- 检查 debuff 名称是否属于眩晕类
local function IsStunDebuff(debuffName)
	for _, name in ipairs(stunDebuffs) do
		if debuffName == name then
			return true
		end
	end
	return false
end

------------------------------
--      Event Handlers      --
------------------------------

function Automaton_CancelTiger:PlayerDebuffGained(debuffName)
	if IsStunDebuff(debuffName) then
		CancelTigerBuff()
	end
end

function Automaton_CancelTiger:UnitDebuffGained(unit, debuffName)
	-- 仅当监测队友且单位是队友（或队友宠物）时处理
	if self.db.profile.checkparty and strfind(unit, "^party") and IsStunDebuff(debuffName) then
		CancelTigerBuff()
	end
end
