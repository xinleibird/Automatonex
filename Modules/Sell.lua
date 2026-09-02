assert(Automaton, "Automaton not found!")

------------------------------
--      Are you local?      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_Sell")

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function()
	return {
		["Sell"] = true,
		["Automatically sell all grey inventory items when at merchant"] = true,
		["Ignore"] = true,
		["Items that should never be sold."] = true,
		["List"] = true,
		["Print all items being ignored by Sell to the screen."] = true,
		["Print all items being sold by Sell to the screen."] = true,
		["Add Item"] = true,
		["Add an item to be ignored by item ID. You can input the item ID."] = true,
		["Add an item to always be sold by item ID. You can input the item ID."] = true,
		["<item id>"] = true,
		["Remove Item"] = true,
		["Removes an item from the ignore list by its ID."] = true,
		["Removes an item from the always sell list by its ID."] = true,
		["Purge"] = true,
		["Remove all items from the ignore list."] = true,
		["Remove all items from the always sell list."] = true,
		[" items purged."] = true,
		["Always sell"] = true,
		["Items that should always be sold."] = true,
		["Ignoring no items."] = true,
		["Ignoring these items:"] = true,
		["No items are specified to always be sold."] = true,
		["Always selling these items:"] = true,
	}
end)

L:RegisterTranslations("zhCN", function()
	return {
		["Sell"] = "自动售卖",
		["Automatically sell all grey inventory items when at merchant"] = "与商人对话时，自动售卖所有灰色物品",
		["Ignore"] = "忽略",
		["Items that should never be sold."] = "不自动出售的物品",
		["List"] = "列表",
		["Print all items being ignored by Sell to the screen."] = "显示所有被忽略的物品到屏幕",
		["Print all items being sold by Sell to the screen."] = "显示所有物品出售给屏幕",
		["Add Item"] = "增加物品ID",
		["Add an item to be ignored by item ID. You can input the item ID."] = "通过物品ID添加忽略物品，输入ID即可",
		["Add an item to always be sold by item ID. You can input the item ID."] = "通过物品ID添加总是售卖的物品，输入ID即可",
		["<item id>"] = "<物品ID>",
		["Remove Item"] = "删除物品ID",
		["Removes an item from the ignore list by its ID."] = "通过ID从忽略列表中删除对象",
		["Removes an item from the always sell list by its ID."] = "通过ID从总是卖列表中删除对象",
		["Purge"] = "清除",
		["Remove all items from the ignore list."] = "从“忽略列表”中移除所有项目",
		["Remove all items from the always sell list."] = "从“总是卖”中移除所有项目",
		[" items purged."] = " 物品清除",
		["Always sell"] = "总是售卖",
		["Items that should always be sold."] = "总是要自动出售的物品",
		["Ignoring no items."] = "没有忽略任何物品",
		["Ignoring these items:"] = "忽略以下物品:",
		["No items are specified to always be sold."] = "没有指定总是售卖的物品",
		["Always selling these items:"] = "总是售卖以下物品:",
	}
end)

----------------------------------
--      Module Declaration      --
----------------------------------

Automaton_Sell = Automaton:NewModule("Sell")
Automaton_Sell.modulename = L["Sell"]
Automaton_Sell.moduledesc = L["Automatically sell all grey inventory items when at merchant"]
Automaton_Sell.options = {
	ignore = {
		type = "group",
		name = L["Ignore"],
		desc = L["Items that should never be sold."],
		args = {
			list = {
				type = "execute",
				name = L["List"],
				desc = L["Print all items being ignored by Sell to the screen."],
				func = function()
					Automaton_Sell:ListIgnored()
				end,
			},
			add = {
				type = "text",
				name = L["Add Item"],
				desc = L["Add an item to be ignored by item ID. You can input the item ID."],
				order = 1,
				usage = L["<item id>"],
				get = false,
				set = function(v)
					Automaton_Sell:IgnoreItem(v)
				end,
			},
			remove = {
				type = "text",
				name = L["Remove Item"],
				desc = L["Removes an item from the ignore list by its ID."],
				order = 2,
				usage = L["<item id>"],
				get = false,
				set = function(v)
					Automaton_Sell:RemoveIgnore(v)
				end,
			},
			purge = {
				type = "execute",
				name = L["Purge"],
				desc = L["Remove all items from the ignore list."],
				func = function()
					Automaton_Sell:PurgeIgnored()
				end,
			},
		},
	},
	custom = {
		type = "group",
		name = L["Always sell"],
		desc = L["Items that should always be sold."],
		args = {
			list = {
				type = "execute",
				name = L["List"],
				desc = L["Print all items being sold by Sell to the screen."],
				func = function()
					Automaton_Sell:ListAlwaysSell()
				end,
			},
			add = {
				type = "text",
				name = L["Add Item"],
				desc = L["Add an item to always be sold by item ID. You can input the item ID."],
				order = 1,
				usage = L["<item id>"],
				get = false,
				set = function(v)
					Automaton_Sell:AlwaysSellItem(v)
				end,
			},
			remove = {
				type = "text",
				name = L["Remove Item"],
				desc = L["Removes an item from the always sell list by its ID."],
				order = 2,
				usage = L["<item id>"],
				get = false,
				set = function(v)
					Automaton_Sell:RemoveAlwaysSell(v)
				end,
			},
			purge = {
				type = "execute",
				name = L["Purge"],
				desc = L["Remove all items from the always sell list."],
				func = function()
					Automaton_Sell:PurgeAlwaysSell()
				end,
			},
		},
	},
}

------------------------------
--      Initialization      --
------------------------------

local VERSION = 2 -- 当前模块数据版本
local showmoney, income_sell -- 记录本次售卖前后金钱变化

function Automaton_Sell:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("Sell")
	Automaton:RegisterDefaults("Sell", "profile", {
		useGarbageFu = false,
		ignore = {}, -- 字典：key = 物品ID(string)，value = 物品名称
		custom = {}, -- 字典：key = 物品ID(string)，value = 物品名称
		ver = VERSION,
	})

	self:RegisterOptions(self.options)
end

function Automaton_Sell:OnEnable()
	-- 检查旧数据格式（数组）并重置为字典
	local reset = false
	if type(self.db.profile.ignore) == "table" then
		for k, _ in pairs(self.db.profile.ignore) do
			if type(k) == "number" then
				reset = true
				break
			end
		end
	end
	if not reset and type(self.db.profile.custom) == "table" then
		for k, _ in pairs(self.db.profile.custom) do
			if type(k) == "number" then
				reset = true
				break
			end
		end
	end
	if reset then
		self.db.profile.ignore = {}
		self.db.profile.custom = {}
		self.db.profile.ver = VERSION
		self:Print("Sell module data has been reset to new version (ID-based).")
	elseif self.db.profile.ver ~= VERSION then
		self.db.profile.ver = VERSION
	end

	-- 初始化金钱记录
	showmoney = 0
	income_sell = 0

	self:RegisterEvent("MERCHANT_SHOW")
	self:RegisterEvent("MERCHANT_CLOSED")
end

function Automaton_Sell:OnDisable()
	self:UnregisterAllEvents()
end

------------------------------
--      Event Handlers      --
------------------------------

local sellTimer = CreateFrame("Frame") -- 解决N服端快速卖垃圾掉线的问题
sellTimer.timeSinceLast = 0
sellTimer:Hide()
sellTimer:SetScript("OnUpdate", function()
	if not MerchantFrame:IsVisible() then
		sellTimer:Hide()
		return
	end
	sellTimer.timeSinceLast = sellTimer.timeSinceLast + arg1
	if sellTimer.timeSinceLast > TOOLTIP_UPDATE_TIME then
		sellTimer.timeSinceLast = 0
		local count = table.getn(sellTimer.junk)
		if count > 0 then
			local bag, slot = sellTimer.junk[count][1], sellTimer.junk[count][2]
			PickupContainerItem(bag, slot)
			MerchantItemButton_OnClick("LeftButton")
			table.remove(sellTimer.junk, count)
		else
			sellTimer:Hide()
		end
	end
end)

function Automaton_Sell:MERCHANT_SHOW()
	sellTimer.junk = {}
	for bag = 0, 4 do
		if GetContainerNumSlots(bag) > 0 then
			for slot = 0, GetContainerNumSlots(bag) do
				local texture, itemCount, locked, quality = GetContainerItemInfo(bag, slot)
				if (quality == 0) or (quality == -1) then
					local linkcolor = self:ProcessLink(GetContainerItemLink(bag, slot))
					if (linkcolor > 0) or (linkcolor == 1) then
						table.insert(sellTimer.junk, { bag, slot })
					end
				end
			end
		end
	end
	if table.getn(sellTimer.junk) > 0 then
		sellTimer:Show()
	end

	showmoney, income_sell = GetMoney(), 0
end

function Automaton_Sell:ProcessLink(link)
	-- 防御：如果link不是字符串，直接返回0（不处理）
	if type(link) ~= "string" then
		return 0
	end

	-- 提取物品ID（使用显式函数调用避免冒号语法）
	local itemId = string.match(link, "item:(%d+):")
	if itemId then
		-- 检查忽略列表
		if self.db.profile.ignore[itemId] then
			return 0
		end
		-- 检查自定义售卖列表
		if self.db.profile.custom[itemId] then
			return 1
		end
	end

	-- 从链接中提取颜色判断是否为灰色
	for color, name in string.gmatch(link, "(|c%x+)|Hitem:.+|h%[(.-)%]|h|r") do
		if color == ITEM_QUALITY_COLORS[0].hex then
			return 1
		end
	end
	return 0
end

------------------------------
--      Ignore 列表操作     --
------------------------------

function Automaton_Sell:IgnoreItem(itemIdStr)
	if itemIdStr and itemIdStr ~= "" then
		local itemId = tonumber(itemIdStr)
		if not itemId then
			self:Print("无效的物品ID")
			return
		end
		local itemName = GetItemInfo(itemId)
		if not itemName then
			self:Print("物品信息未加载，请稍后再试")
			return
		end
		self.db.profile.ignore[tostring(itemId)] = itemName
		self:Print(string.format("已添加忽略物品: %s (ID: %s)", itemName, itemId))
	end
end

function Automaton_Sell:RemoveIgnore(itemIdStr)
	if itemIdStr and itemIdStr ~= "" then
		local itemId = tonumber(itemIdStr)
		if not itemId then
			self:Print("无效的物品ID")
			return
		end
		local itemName = self.db.profile.ignore[tostring(itemId)]
		if itemName then
			self.db.profile.ignore[tostring(itemId)] = nil
			self:Print(string.format("已移除忽略物品: %s (ID: %s)", itemName, itemId))
		else
			self:Print("忽略列表中未找到物品ID: " .. itemIdStr)
		end
	end
end

function Automaton_Sell:ListIgnored()
	local count = 0
	for _ in pairs(self.db.profile.ignore) do
		count = count + 1
	end
	if count == 0 then
		self:Print(L["Ignoring no items."])
	else
		self:Print(L["Ignoring these items:"])
		for itemId, itemName in pairs(self.db.profile.ignore) do
			self:Print(string.format("%s (ID: %s)", itemName, itemId))
		end
	end
end

function Automaton_Sell:PurgeIgnored()
	local count = 0
	for _ in pairs(self.db.profile.ignore) do
		count = count + 1
	end
	self:Print(count .. L[" items purged."])
	self.db.profile.ignore = {}
end

------------------------------
--   Always sell 列表操作   --
------------------------------

function Automaton_Sell:AlwaysSellItem(itemIdStr)
	if itemIdStr and itemIdStr ~= "" then
		local itemId = tonumber(itemIdStr)
		if not itemId then
			self:Print("无效的物品ID")
			return
		end
		local itemName = GetItemInfo(itemId)
		if not itemName then
			self:Print("物品信息未加载，请稍后再试")
			return
		end
		self.db.profile.custom[tostring(itemId)] = itemName
		self:Print(string.format("已添加总是售卖物品: %s (ID: %s)", itemName, itemId))
	end
end

function Automaton_Sell:RemoveAlwaysSell(itemIdStr)
	if itemIdStr and itemIdStr ~= "" then
		local itemId = tonumber(itemIdStr)
		if not itemId then
			self:Print("无效的物品ID")
			return
		end
		local itemName = self.db.profile.custom[tostring(itemId)]
		if itemName then
			self.db.profile.custom[tostring(itemId)] = nil
			self:Print(string.format("已移除总是售卖物品: %s (ID: %s)", itemName, itemId))
		else
			self:Print("总是售卖列表中未找到物品ID: " .. itemIdStr)
		end
	end
end

function Automaton_Sell:ListAlwaysSell()
	local count = 0
	for _ in pairs(self.db.profile.custom) do
		count = count + 1
	end
	if count == 0 then
		self:Print(L["No items are specified to always be sold."])
	else
		self:Print(L["Always selling these items:"])
		for itemId, itemName in pairs(self.db.profile.custom) do
			self:Print(string.format("%s (ID: %s)", itemName, itemId))
		end
	end
end

function Automaton_Sell:PurgeAlwaysSell()
	local count = 0
	for _ in pairs(self.db.profile.custom) do
		count = count + 1
	end
	self:Print(count .. L[" items purged."])
	self.db.profile.custom = {}
end

------------------------------
--      收入计算辅助函数    --
------------------------------

local function GetIncomeGSC(total)
	local gold, Temp, silver, copper
	gold = floor(total / 10000)
	Temp = total - (gold * 10000)
	silver = floor(Temp / 100)
	copper = Temp - (silver * 100)

	local GSC = ""
	if gold > 0 then
		GSC = gold .. "|cffffd700金|R"
	end
	if silver > 0 then
		GSC = GSC .. silver .. "|cffe6e6e6银|R"
	elseif silver == 0 and gold > 0 then
		GSC = GSC .. silver .. "|cffe6e6e6银|R"
	end
	if copper > 0 then
		GSC = GSC .. copper .. "|cffeda55f铜|R"
	elseif copper == 0 and (silver > 0 or gold > 0) then
		GSC = GSC .. copper .. "|cffeda55f铜|R"
	end
	return GSC
end

function Automaton_Sell:MERCHANT_CLOSED()
	local sellmoney = GetMoney()
	-- 防止 showmoney 为 nil
	showmoney = showmoney or 0
	if sellmoney > showmoney then
		income_sell = sellmoney - showmoney
		showmoney = sellmoney
		DEFAULT_CHAT_FRAME:AddMessage("|cffdd66dd本次售卖收入 |r" .. GetIncomeGSC(income_sell))
	end
end
