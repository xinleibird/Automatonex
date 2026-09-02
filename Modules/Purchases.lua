assert(Automaton, "Automaton not found!")

------------------------------
--      Are you local?      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_Purchases")

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function()
	return {
		["Purchases"] = "自动购买材料",
		["Purchases1"] = "自动购买材料1",
		["Purchases2"] = "自动购买材料2",
		["Automatically restock items"] = "与商人对话时，自动补充特定材料",
		["Reagent"] = "施法材料",
		["Set item to buy"] = "设置购买项目",
		["Quantity"] = "数量",
		["Set the number of purchased items"] = "设置购买物品的数量",
		["Bought "] = "买了 ",
		[" items."] = " 物品.",
		["Already have "] = "已有 ",
		["List"] = "打印全部列表",
		["Add Item"] = "添加物品ID：(回车确认，一次添加一个)",
		["Remove Item"] = "移除物品ID(按回车确认，一次添加一个)",
		["Purge"] = "清空列表",
		["Purged list for "] = "已清空列表：",

		["Invalid item ID"] = "无效的物品ID",
		["Item info not loaded, please try again later"] = "物品信息未加载，请稍后再试",
	}
end)

L:RegisterTranslations("zhCN", function()
	return {
		["Purchases"] = "自动购买材料",
		["Purchases1"] = "自动购买材料1",
		["Purchases2"] = "自动购买材料2",
		["Automatically restock items"] = "与商人对话时，自动补充特定材料",
		["Reagent"] = "施法材料",
		["Set item to buy"] = "设置购买项目",
		["Quantity"] = "数量",
		["Set the number of purchased items"] = "设置购买物品的数量",
		["Bought "] = "买了 ",
		[" items."] = " 物品.",
		["Already have "] = "已有 ",
		["List"] = "打印全部列表",
		["Add Item"] = "添加物品ID：(回车确认，一次添加一个)",
		["Remove Item"] = "移除物品ID(按回车确认，一次添加一个)",
		["Purge"] = "清空列表",
		["Purged list for "] = "已清空列表：",

		["Invalid item ID"] = "无效的物品ID",
		["Item info not loaded, please try again later"] = "物品信息未加载，请稍后再试",
	}
end)

----------------------------------
--      Module Declaration      --
----------------------------------
-- 使用角色名+服务器名作为唯一标识
local playerName = UnitName("player")
local realmName = GetRealmName()
local playerKey = playerName .. "-" .. realmName

local Automaton_Purchases = Automaton:NewModule("Purchases")
Automaton_Purchases.modulename = L["Purchases"]
Automaton_Purchases.moduledesc = L["Automatically restock items"]

-- 生成类别配置的工具函数
local function createCategoryOptions(category)
	return {
		list = {
			type = "execute",
			name = L["List"],
			desc = "打印" .. L[category] .. "的自动购买列表",
			func = function()
				local reagents = Automaton_Purchases.db.profile[category .. "_reagents"][playerKey] or {}
				Automaton_Purchases:Print(L[category] .. " 自动购买列表:")
				if next(reagents) then
					for itemId, itemName in pairs(reagents) do
						Automaton_Purchases:Print(string.format("- %s (ID: %s)", itemName, itemId))
					end
				else
					Automaton_Purchases:Print("列表为空")
				end
			end,
		},
		add = {
			type = "text",
			name = L["Add Item"],
			desc = "添加需要自动购买的物品ID(直接输入ID).|N一次只能添加一个物品",
			order = 1,
			usage = "物品ID",
			get = false,
			set = function(v)
				if v and v ~= "" then
					local itemId = tostring(v)
					local itemIdNum = tonumber(itemId)
					if not itemIdNum then
						Automaton_Purchases:Print(L["Invalid item ID"])
						return
					end

					local itemName = GetItemInfo(itemIdNum)
					if not itemName then
						Automaton_Purchases:Print(L["Item info not loaded, please try again later"])
						return
					end

					Automaton_Purchases.db.profile[category .. "_reagents"][playerKey][itemId] = itemName
					Automaton_Purchases:Print(string.format(L[category] .. " 已添加: %s (ID: %s)", itemName, itemId))
				end
			end,
		},
		remove = {
			type = "text",
			name = L["Remove Item"],
			desc = "输入物品ID移除自动购买物品",
			order = 2,
			usage = "物品ID",
			get = false,
			set = function(v)
				if v and v ~= "" then
					local itemId = tostring(v)
					local reagents = Automaton_Purchases.db.profile[category .. "_reagents"][playerKey] or {}
					local itemName = reagents[itemId]
					if itemName then
						reagents[itemId] = nil
						Automaton_Purchases:Print(
							string.format(L[category] .. " 已移除: %s (ID: %s)", itemName, itemId)
						)
					else
						Automaton_Purchases:Print(L[category] .. " 未找到物品ID: " .. itemId)
					end
				end
			end,
		},
		purge = {
			type = "execute",
			name = L["Purge"],
			desc = "清空" .. L[category] .. "的自动购买列表.",
			func = function()
				Automaton_Purchases.db.profile[category .. "_reagents"][playerKey] = {}
				Automaton_Purchases:Print(L["Purged list for "] .. L[category])
			end,
		},
		quantity = {
			type = "range",
			name = L["Quantity"],
			desc = L["Set the number of purchased items"],
			order = 3,
			get = function()
				return Automaton_Purchases.db.profile[category .. "_quantity"][playerKey]
					or Automaton_Purchases.db.profile[category .. "_quantity"].default
			end,
			set = function(v)
				Automaton_Purchases.db.profile[category .. "_quantity"][playerKey] = v
				Automaton_Purchases:Print(string.format(L[category] .. " 购买数量已设置为: %d", v))
			end,
			min = 0,
			max = 300,
			step = 5,
			bigStep = 10,
		},
	}
end

-- 配置选项分组
Automaton_Purchases.options = {
	original = {
		type = "group",
		name = L["Purchases"],
		desc = L["Automatically restock items"],
		order = 1,
		args = createCategoryOptions("Purchases"),
	},
	category1 = {
		type = "group",
		name = L["Purchases1"],
		desc = L["Automatically restock items"],
		order = 2,
		args = createCategoryOptions("Purchases1"),
	},
	category2 = {
		type = "group",
		name = L["Purchases2"],
		desc = L["Automatically restock items"],
		order = 3,
		args = createCategoryOptions("Purchases2"),
	},
}

------------------------------
--      Initialization      --
------------------------------

function Automaton_Purchases:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("Purchases")

	-- 注册默认数据库（包含原始类别和两个新类别）
	Automaton:RegisterDefaults("Purchases", "profile", {
		disabled = true,
		-- 原始类别数据
		Purchases_quantity = {
			default = 0,
		},
		Purchases_reagents = {
			default = {},
		},
		-- 新类别1数据
		Purchases1_quantity = {
			default = 0,
		},
		Purchases1_reagents = {
			default = {},
		},
		-- 新类别2数据
		Purchases2_quantity = {
			default = 0,
		},
		Purchases2_reagents = {
			default = {},
		},
	})
	Automaton:SetDisabledAsDefault(self, "Purchases")

	self:RegisterOptions(self.options)
end

function Automaton_Purchases:OnEnable()
	-- 初始化所有类别的玩家数据存储
	local categories = { "Purchases", "Purchases1", "Purchases2" }
	for _, category in ipairs(categories) do
		self.db.profile[category .. "_reagents"][playerKey] = self.db.profile[category .. "_reagents"][playerKey] or {}
	end
	self:RegisterEvent("MERCHANT_SHOW")
end

function Automaton_Purchases:OnDisable()
	self:UnregisterAllEvents()
end

------------------------------
--      Event Handlers      --
------------------------------

-- 处理单个类别的购买逻辑
local function processCategoryPurchase(self, category)
	local quantity = self.db.profile[category .. "_quantity"][playerKey]
		or self.db.profile[category .. "_quantity"].default
	local reagents = self.db.profile[category .. "_reagents"][playerKey] or {}

	for i = 1, GetMerchantNumItems() do
		local merchantItemLink = GetMerchantItemLink(i)
		if merchantItemLink then
			local merchantItemId = string.match(merchantItemLink, "item:(%d+):")
			if merchantItemId and reagents[merchantItemId] then
				local amountInBag = tonumber(self:SearchItem(merchantItemId))
				local needed = quantity - amountInBag

				-- 特殊处理堆叠物品（如王者印记）
				if merchantItemId == "21177" then
					needed = math.ceil(needed / 20)
				end

				if needed > 0 then
					BuyMerchantItem(i, needed)
					Automaton_Purchases:print(L[category] .. L["Bought "] .. needed .. L[" items."])
				end
			end
		end
	end
end

function Automaton_Purchases:MERCHANT_SHOW()
	-- 依次处理所有类别
	processCategoryPurchase(self, "Purchases")
	processCategoryPurchase(self, "Purchases1")
	processCategoryPurchase(self, "Purchases2")
end

function Automaton_Purchases:SearchItem(itemId)
	local count = 0
	for bag = 0, 4 do
		if GetContainerNumSlots(bag) > 0 then
			for slot = 0, GetContainerNumSlots(bag) do
				if GetContainerItemLink(bag, slot) then
					local linkItemId = string.match(GetContainerItemLink(bag, slot), "item:(%d+):")
					if linkItemId == itemId then
						local _, q = GetContainerItemInfo(bag, slot)
						count = count + q
					end
				end
			end
		end
	end
	return count
end
