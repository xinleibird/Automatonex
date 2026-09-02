assert(Automaton, "Automaton not found!")

------------------------------
--      Are you local?      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_Repair")

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function()
	return {
		["Repair"] = true,
		["Automatically repair all inventory items when at merchant"] = true,
		["RepairYouMessage"] = "|CFFDD66DDRepair cost you|R",
		["NotEnoughMoneyMessage"] = "|CFFFF0000Sorry, not enough money!|R",
	}
end)

L:RegisterTranslations("zhCN", function()
	return {
		["Repair"] = "自动修理",
		["Automatically repair all inventory items when at merchant"] = "与商人对话时，自动修理所有破损的装备",
		["RepairYouMessage"] = "|CFFDD66DD修理花费|R",
		["NotEnoughMoneyMessage"] = "|CFFFF0000没有足够的资金修理!|R",
	}
end)

----------------------------------
--      Module Declaration      --
----------------------------------

Automaton_Repair = Automaton:NewModule("Repair")
Automaton_Repair.modulename = L["Repair"]
Automaton_Repair.moduledesc = L["Automatically repair all inventory items when at merchant"]
Automaton_Repair.options = {}

------------------------------
--      Initialization      --
------------------------------

function Automaton_Repair:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("Repair")
	Automaton:RegisterDefaults("Repair", "profile", {
		disabled = false,
	})
	Automaton:SetDisabledAsDefault(self, "Repair")

	self:RegisterOptions(self.options)
end

function Automaton_Repair:OnEnable()
	self:RegisterEvent("MERCHANT_SHOW")
end

function Automaton_Repair:OnDisable()
	self:UnregisterAllEvents()
end

------------------------------
--      Event Handlers      --
------------------------------
function parseMoney(total)
	local gold, Temp, silver, copper --lots of rounding
	gold = floor(total / 10000)
	Temp = total - (gold * 10000)
	silver = floor(Temp / 100)
	copper = Temp - (silver * 100)

	local message = ""
	if gold > 0 then
		message = gold .. "|cffffd700金|R"
	end

	if silver > 0 then
		message = message .. silver .. "|cffc7c7cf银|R"
	elseif silver == 0 and gold > 0 then
		message = message .. silver .. "|cffc7c7cf银|R"
	end

	if copper > 0 then
		message = message .. copper .. "|cffeda55f铜|R"
	elseif copper == 0 and (silver > 0 or gold > 0) then
		message = message .. copper .. "|cffeda55f铜|R"
	end

	return message
end

function Automaton_Repair:MERCHANT_SHOW()
	if not CanMerchantRepair() then
		return
	end
	local yourFunds = GetMoney()
	local cost, canRepair = GetRepairAllCost()
	local finalCost = parseMoney(cost)
	if canRepair then
		if yourFunds < cost then
			DEFAULT_CHAT_FRAME:AddMessage(L["NotEnoughMoneyMessage"])
		elseif cost > 0 then
			RepairAllItems()
			DEFAULT_CHAT_FRAME:AddMessage(L["RepairYouMessage"] .. " " .. finalCost .. " ")
		end
	end
end
