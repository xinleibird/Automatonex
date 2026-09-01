assert(Automaton, "Automaton not found!")

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_AutoOpenBag = Automaton:NewModule("AutoOpenBag")
Automaton_AutoOpenBag.modulename = "自动打开背包"
Automaton_AutoOpenBag.moduledesc =
	"交易、邮箱的时候自动打开背包（Bgn/Succ），Onebag/乾坤袋可能是反向开关"
Automaton_AutoOpenBag.options = {}

------------------------------
--      Initialization      --
------------------------------

function Automaton_AutoOpenBag:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("AutoOpenBag")
	Automaton:RegisterDefaults("AutoOpenBag", "profile", {
		disabled = false,
	})
	Automaton:SetDisabledAsDefault(self, "AutoOpenBag")

	self:RegisterOptions(self.options)
end

function Automaton_AutoOpenBag:OnEnable()
	self:RegisterEvent("MAIL_SHOW", "SHOW")
	self:RegisterEvent("MAIL_CLOSED", "CLOSED")
	self:RegisterEvent("TRADE_CLOSED", "CLOSED")
	self:RegisterEvent("TRADE_SHOW", "SHOW")
	--self:Hook('SpellButton_OnClick')
end

function Automaton_AutoOpenBag:OnDisable()
	self:UnregisterAllEvents()
end

------------------------------
--      Event Handlers      --
------------------------------

function Automaton_AutoOpenBag:CLOSED()
	-- 默认背包
	if IsBagOpen(0) then
		ToggleBag(0)
	end
	-- SUCC-bag 插件
	if IsAddOnLoaded("SUCC-bag") then
		if SUCC_bag:IsVisible() then
			ToggleBag(0)
		end
	end
	-- Bagnon 插件
	if IsAddOnLoaded("Bagnon") then
		if Bagnon:IsVisible() then
			ToggleBag(0)
		end
	end
	-- OneBag 插件
	if IsAddOnLoaded("OneBag") then
		if OneBag.frame and OneBag.frame:IsVisible() then
			ToggleBag(0)
		end
	end
end

function Automaton_AutoOpenBag:SHOW()
	-- 默认背包
	if not IsBagOpen(0) then
		ToggleBag(0)
	end
	-- SUCC-bag 插件
	if IsAddOnLoaded("SUCC-bag") then
		if not SUCC_bag:IsVisible() then
			ToggleBag(0)
		end
	end
	-- OneBag 插件
	if IsAddOnLoaded("OneBag") then
		if not OneBag.frame or not OneBag.frame:IsVisible() then
			ToggleBag(0)
		end
	end
end

function Automaton_AutoOpenBag:SpellButton_OnClick(drag)
	local id = SpellBook_GetSpellID(this:GetID())
	if id > MAX_SPELLS then
		return
	end
	if IsShiftKeyDown() then
		if ChatFrameEditBox:IsVisible() then
			local spellname = GetSpellInfo(id, SpellBookFrame.bookType)
			spellname = SpellNametoen(spellname) or spellname
			local spelllink = "|CFF71d5ff|Hspell:"
				.. id
				.. ":0:"
				.. UnitName("player")
				.. ":|h["
				.. spellname
				.. "]|h|r"
			ChatFrameEditBox:Insert(spelllink)
			-- PickupSpell(id, SpellBookFrame.bookType )
			return
		end
	end
	return self.hooks.SpellButton_OnClick(drag)
end
