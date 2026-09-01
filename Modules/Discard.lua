assert(Automaton, "Automaton not found!")
----------------------------------
--      Module Declaration      --
----------------------------------
local title = "自动丢弃物品"
local Automaton_Discard = Automaton:NewModule("Discard")
Automaton_Discard.modulename = title
Automaton_Discard.moduledesc =
	"自动丢弃背包中的指定物品（仅灰色/白色品质）及管理术士灵魂碎片"
Automaton_Discard.options = {
	discard = {
		type = "group",
		name = "自动丢弃列表",
		desc = "自动丢弃指定物品",
		args = {
			-- 新增打印开关选项
			printEnabled = {
				type = "toggle",
				name = "启用丢弃提示",
				desc = "开启/关闭丢弃物品时的提示信息",
				order = 0,
				get = function()
					return Automaton_Discard.db.profile.printEnabled
				end,
				set = function(v)
					Automaton_Discard.db.profile.printEnabled = v
				end,
			},
			list = {
				type = "execute",
				name = "打印列表",
				desc = "列出所有自动丢弃的物品",
				func = function()
					Automaton:Print(title .. " 列表:")
					for itemId, itemName in pairs(Automaton_Discard.db.profile.discard) do
						Automaton:Print(string.format("- %s (ID: %s)", itemName, itemId))
					end
				end,
			},
			add = {
				type = "text",
				name = "添加物品（ID）",
				desc = "添加物品ID到自动丢弃列表",
				order = 1,
				usage = "<ItemId>",
				get = false,
				set = function(v)
					if v and v ~= "" then
						local itemId = tostring(v)
						local itemIdNum = tonumber(itemId)
						if not itemIdNum then
							Automaton:Print("无效的物品ID")
							return
						end

						local itemName, _, itemQuality = GetItemInfo(itemIdNum)
						if not itemName then
							Automaton:Print("物品信息未加载，请稍后再试")
							return
						end

						-- 只允许添加灰色(0)和白色(1)品质的物品
						if itemQuality and itemQuality > 1 then
							Automaton:Print("只能添加灰色或白色品质的物品")
							return
						end

						Automaton_Discard.db.profile.discard[itemId] = itemName
						Automaton:Print(string.format("已添加: %s (ID: %s) 到丢弃列表", itemName, itemId))
					end
				end,
			},
			remove = {
				type = "text",
				name = "移除物品（ID）",
				desc = "从自动丢弃列表中移除物品",
				order = 2,
				usage = "<ItemId>",
				get = false,
				set = function(v)
					if v and v ~= "" then
						local itemId = tostring(v)
						local itemName = Automaton_Discard.db.profile.discard[itemId]
						if itemName then
							Automaton_Discard.db.profile.discard[itemId] = nil
							Automaton:Print(string.format("已移除: %s (ID: %s) 从丢弃列表", itemName, itemId))
						else
							Automaton:Print("未找到物品ID: " .. itemId)
						end
					end
				end,
			},
			purge = {
				type = "execute",
				name = "清空列表",
				desc = "清空所有自动丢弃物品",
				func = function()
					Automaton_Discard.db.profile.discard = {}
					Automaton:Print(title .. " 列表已清空")
				end,
			},
			-- 新增灵魂碎片管理配置
			soulShardGroup = {
				type = "group",
				name = "灵魂碎片自动管理",
				desc = "设置术士灵魂碎片的自动丢弃规则（3个一组）",
				order = 10,
				args = {
					soulShardEnabled = {
						type = "toggle",
						name = "启用灵魂碎片管理",
						desc = "开启/关闭自动丢弃多余灵魂碎片功能",
						get = function()
							return Automaton_Discard.db.profile.soulShardEnabled
						end,
						set = function(v)
							Automaton_Discard.db.profile.soulShardEnabled = v
						end,
					},
					soulShardLimit = {
						type = "range",
						name = "灵魂碎片保留数量",
						desc = "最多保留的灵魂碎片数量",
						min = 3,
						max = 84,
						step = 1,
						get = function()
							return Automaton_Discard.db.profile.soulShardLimit
						end,
						set = function(v)
							Automaton_Discard.db.profile.soulShardLimit = v
						end,
					},
				},
			},
		},
	},
}

------------------------------
--      Initialization      --
------------------------------

function Automaton_Discard:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("Discard")
	Automaton:RegisterDefaults("Discard", "profile", {
		disabled = false,
		discard = {},
		ver = 0,
		printEnabled = true, -- 新增默认启用打印功能
		-- 新增灵魂碎片默认配置
		soulShardEnabled = false,
		soulShardLimit = 84,
	})

	self:RegisterOptions(self.options)
end

function Automaton_Discard:OnEnable()
	-- 数据库版本管理
	if self.db.profile.ver ~= Automaton.ver then
		self.db.profile.discard = {}
		self.db.profile.ver = Automaton.ver
		-- 保留版本更新提示，不受打印开关控制
		Automaton:Print(title .. " 数据库已更新到最新版本")
	end

	-- 注册事件
	self:RegisterEvent("BAG_UPDATE")
	self:RegisterEvent("LOOT_CLOSED")
	self:RegisterEvent("CHAT_MSG_LOOT")

	-- 初始化扫描状态
	self.scanScheduled = false
	self.isScanning = false
	self.retryCount = 0

	Automaton:Print(title .. " 已启用")
end

function Automaton_Discard:OnDisable()
	Automaton:Print(title .. " 已禁用")
end

---------------------------
--      Event Handlers    --
---------------------------

function Automaton_Discard:BAG_UPDATE()
	self:ScheduleScan()
end

function Automaton_Discard:LOOT_CLOSED()
	self:ScheduleScan()
end

function Automaton_Discard:CHAT_MSG_LOOT()
	self:ScheduleScan()
end

---------------------------
--      Core Functions    --
---------------------------

function Automaton_Discard:ScheduleScan()
	if self.scanScheduled or self.isScanning then
		return
	end

	self.scanScheduled = true
	C_Timer.After(0.5, function()
		self.scanScheduled = false
		self:CheckAllBags()
	end)
end

function Automaton_Discard:CheckAllBags()
	if self.isScanning then
		return
	end

	self.isScanning = true
	self.retryCount = 0
	self:DoCheckAllBags()
end

function Automaton_Discard:DoCheckAllBags()
	local foundLocked = false

	for bag = 0, 4 do -- 只扫描背包0-4
		local lockedInBag = self:ProcessBag(bag)
		if lockedInBag then
			foundLocked = true
		end
	end

	-- 新增灵魂碎片检查
	self:CheckSoulShards()

	-- 如果有锁定的物品，稍后重试（最多3次）
	if foundLocked and self.retryCount < 3 then
		self.retryCount = self.retryCount + 1
		C_Timer.After(1, function()
			self:DoCheckAllBags()
		end)
	else
		self.isScanning = false
	end
end

function Automaton_Discard:ProcessBag(bag)
	local foundLocked = false

	local numSlots = GetContainerNumSlots(bag)
	if not numSlots or numSlots <= 0 then
		return foundLocked
	end

	for slot = 1, numSlots do
		local itemLink = GetContainerItemLink(bag, slot)
		if itemLink then
			local itemId = string.match(itemLink, "item:(%d+):")
			if itemId then
				local discardName = self.db.profile.discard[itemId]
				if discardName then
					local texture, count, locked = GetContainerItemInfo(bag, slot)

					if not locked then
						local _, _, quality = GetItemInfo(itemId)
						if quality and quality <= 1 then
							ClearCursor()
							PickupContainerItem(bag, slot)
							if CursorHasItem() then
								DeleteCursorItem()
								-- 检查打印开关状态，只有开启时才打印
								if self.db.profile.printEnabled then
									Automaton:Print(title .. ": 已丢弃: " .. discardName)
								end
							end
						else
							self.db.profile.discard[itemId] = nil
							Automaton:Print(title .. ": 移除非灰色/白色物品: " .. discardName)
						end
					else
						foundLocked = true
					end
				end
			end
		end
	end

	return foundLocked
end

-- 新增灵魂碎片处理核心函数（3个一组处理）
function Automaton_Discard:CheckSoulShards()
	-- 检查是否启用功能
	if not self.db.profile.soulShardEnabled then
		return
	end

	-- 检查职业是否为术士
	local playerClass = select(2, UnitClass("player"))
	if playerClass ~= "WARLOCK" then
		return
	end

	local soulShardId = "6265" -- 灵魂碎片物品ID
	local soulShardName = GetItemInfo(6265) or "灵魂碎片"
	local shardStackSize = 3 -- 灵魂碎片堆叠数量（3个一组）
	local limit = self.db.profile.soulShardLimit
	local totalCount = 0
	local shardLocations = {} -- 存储所有灵魂碎片的位置 {bag, slot, count}

	-- 收集所有灵魂碎片信息
	for bag = 0, 4 do
		local numSlots = GetContainerNumSlots(bag)
		if numSlots and numSlots > 0 then
			for slot = 1, numSlots do
				local itemLink = GetContainerItemLink(bag, slot)
				if itemLink then
					local itemId = string.match(itemLink, "item:(%d+):")
					if itemId == soulShardId then
						local _, count, locked = GetContainerItemInfo(bag, slot)
						if count then
							totalCount = totalCount + count
							table.insert(shardLocations, {
								bag = bag,
								slot = slot,
								count = count,
								locked = locked,
							})
						end
					end
				end
			end
		end
	end

	-- 计算需要丢弃的数量
	local excess = totalCount - limit
	if excess <= 0 then
		return
	end

	-- 按3个一组优先丢弃整组，再处理剩余单个
	for _, loc in ipairs(shardLocations) do
		if excess <= 0 then
			break
		end

		if not loc.locked and loc.count > 0 then
			-- 优先计算可丢弃的整组数
			local stacksToDiscard = math.floor(excess / shardStackSize)
			-- 单个堆叠中最多可丢弃的整组数（不超过当前堆叠数量）
			local maxStacksFromThisSlot = math.floor(loc.count / shardStackSize)
			local actualStacks = math.min(stacksToDiscard, maxStacksFromThisSlot)

			if actualStacks > 0 then
				-- 丢弃整组
				local discardCount = actualStacks * shardStackSize
				for i = 1, actualStacks do
					ClearCursor()
					PickupContainerItem(loc.bag, loc.slot)
					if CursorHasItem() then
						DeleteCursorItem()
						excess = excess - shardStackSize
						-- 打印提示
						if self.db.profile.printEnabled then
							Automaton:Print(
								string.format(
									"%s: 已丢弃1组%s（%d个），当前保留数量: %d",
									self.modulename,
									soulShardName,
									shardStackSize,
									(totalCount - (discardCount - excess))
								)
							)
						end
						if excess <= 0 then
							break
						end
					end
				end
			else
				-- 处理剩余不足一组的数量
				local singleToDiscard = math.min(excess, loc.count)
				for i = 1, singleToDiscard do
					ClearCursor()
					PickupContainerItem(loc.bag, loc.slot)
					if CursorHasItem() then
						DeleteCursorItem()
						excess = excess - 1
						-- 打印提示
						if self.db.profile.printEnabled then
							Automaton:Print(
								string.format(
									"%s: 已丢弃1个%s，当前保留数量: %d",
									self.modulename,
									soulShardName,
									(totalCount - (singleToDiscard - excess))
								)
							)
						end
						if excess <= 0 then
							break
						end
					end
				end
			end
		end
	end
end
