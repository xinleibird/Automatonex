assert(Automaton, "Automaton not found!")

------------------------------
--      Localization      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_ShiQu")

L:RegisterTranslations("zhCN", function()
	return {
		["ShiQu"] = "强制拾取",
		["Automatically handle loot distribution based on predefined rules"] = "根据预设规则自动处理战利品分配，支持指定拾取目标",
		["Permission Check"] = "权限检测",
		["Toggle permission check for loot handling"] = "切换是否检查拾取权限",
		["Loot Target"] = "拾取目标",
		["Set or clear target player for loot distribution"] = "设置/清除战利品分配的目标玩家",
		["Enable Announce"] = "启用物品通报",
		["Toggle whether to announce loot items in raid"] = "切换是否在团队频道通报拾取的物品",
	}
end)

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_ShiQu = Automaton:NewModule("ShiQu")
Automaton_ShiQu.modulename = L["ShiQu"]
Automaton_ShiQu.moduledesc = L["Automatically handle loot distribution based on predefined rules"]
Automaton_ShiQu.options = {
	permissionCheck = {
		type = "toggle",
		name = L["Permission Check"],
		desc = L["Toggle permission check for loot handling"],
		order = 2,
		get = function()
			return Automaton_ShiQu.db.profile.permissionCheck
		end,
		set = function(v)
			Automaton_ShiQu.db.profile.permissionCheck = v
		end,
	},
	announceEnable = {
		type = "toggle",
		name = L["Enable Announce"],
		desc = L["Toggle whether to announce loot items in raid"],
		order = 3,
		get = function()
			return Automaton_ShiQu.db.profile.announceEnabled
		end,
		set = function(v)
			Automaton_ShiQu.db.profile.announceEnabled = v
		end,
	},
}

------------------------------
--      Initialization      --
------------------------------

-- 强制拾取的绑定物品
Automaton_ShiQu.LootedItemsTable = {}
-- 示例: Automaton_ShiQu.LootedItemsTable["银币"] = "自动捡钱"

-- 在尸体上保留的非绑定物品
Automaton_ShiQu.ExcludedItemsTable = {}

function Automaton_ShiQu:OnInitialize()
	-- 初始化数据库
	self.db = Automaton:AcquireDBNamespace("ShiQu")
	Automaton:RegisterDefaults("ShiQu", "profile", {
		disabled = true, -- 默认禁用
		permissionCheck = true, -- 权限检测默认开启
		targetPlayerName = nil, -- 拾取目标默认无
		announceEnabled = false, -- 通报默认关闭
	})
	Automaton:SetDisabledAsDefault(self, "ShiQu")
	self:RegisterOptions(self.options)

	-- 状态变量初始化（但会在OnEnable中重置）
	self.isProcessingLoot = false
	self.lastLootTime = 0

	-- 创建扫描用的tooltip
	self.scanTooltip = CreateFrame("GameTooltip", "Automaton_ShiQu_ScanTooltip", UIParent, "GameTooltipTemplate")
	self.scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")

	-- 注册命令
	SLASH_ShiQu1 = "/shiqu"
	SLASH_ShiQu2 = "/autosq"
	SLASH_ShiQu3 = "/拾取"
	SlashCmdList.ShiQu = function(cmd)
		self:ShiQuSwitch(cmd)
	end

	SLASH_LootTarget1 = "/拾取目标"
	SlashCmdList.LootTarget = function(arg)
		self:HandleLootTarget(arg)
	end
end

function Automaton_ShiQu:OnEnable()
	-- 重置状态变量，确保干净启动
	self.isProcessingLoot = false
	self.lastLootTime = 0

	-- 注册事件
	self:RegisterEvent("LOOT_OPENED")

	DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00[强制拾取] 模块已启用")
end

function Automaton_ShiQu:OnDisable()
	-- 取消事件注册前检查是否已注册，避免报错
	if self:IsEventRegistered("LOOT_OPENED") then
		self:UnregisterEvent("LOOT_OPENED")
	end

	DEFAULT_CHAT_FRAME:AddMessage("|cffFF0000[强制拾取] 模块已禁用")
end

------------------------------
--      Core Functions      --
------------------------------

-- 检查物品是否为拾取后绑定
function Automaton_ShiQu:LootSlotIsSoulbound(lootIndex)
	self.scanTooltip:ClearLines()
	self.scanTooltip:SetLootItem(lootIndex)

	-- 检查tooltip中是否有"拾取后绑定"的文本
	for i = 2, self.scanTooltip:NumLines() do
		local line = getglobal("Automaton_ShiQu_ScanTooltipTextLeft" .. i)
		if line and line:GetText() == "拾取后绑定" then
			return true
		end
	end
	return false
end

-- 决定是否自动拾取物品
function Automaton_ShiQu:ShouldAutolootItem(lootedindex)
	local lootIcon, lootName, lootQuantity, rarity = GetLootSlotInfo(lootedindex)

	if self.LootedItemsTable[lootName] then
		return 1 -- 拾取物品
	end

	if self:LootSlotIsSoulbound(lootedindex) then
		return 2 -- 留在尸体上并通告
	end

	if self.ExcludedItemsTable[lootName] then
		return 3 -- 留在尸体上，不通告
	end
	return 1
end

-- 设置拾取目标
function Automaton_ShiQu:SetLootTarget()
	local targetName = UnitName("target")
	if targetName then
		self.db.profile.targetPlayerName = targetName
		DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00拾取目标已设置为: " .. targetName)
	else
		DEFAULT_CHAT_FRAME:AddMessage("|cffFF0000错误: 请先选择一个目标")
	end
end

-- 清除拾取目标
function Automaton_ShiQu:ClearLootTarget()
	self.db.profile.targetPlayerName = nil
	DEFAULT_CHAT_FRAME:AddMessage("|cffFF0000拾取目标已清除")
end

-- 处理命令切换
function Automaton_ShiQu:ShiQuSwitch(cmd)
	if cmd == "q" then
		self.db.profile.permissionCheck = false
		DEFAULT_CHAT_FRAME:AddMessage("|cffFF0000拾取权限检测已关闭")
		DEFAULT_CHAT_FRAME:AddMessage("输入 /拾取 nq 开启权限检测")
	elseif cmd == "nq" then
		self.db.profile.permissionCheck = true
		DEFAULT_CHAT_FRAME:AddMessage("|cff00FF00拾取权限检测已开启")
		DEFAULT_CHAT_FRAME:AddMessage("输入 /拾取 q 关闭权限检测")
	else
		-- 切换模块激活状态
		local newState = not Automaton:IsModuleActive("ShiQu")
		Automaton:ToggleModuleActive("ShiQu", newState)
		DEFAULT_CHAT_FRAME:AddMessage("拾取功能 " .. (newState and "|cff00FF00开启" or "|cffFF0000关闭"))
		if newState then
			DEFAULT_CHAT_FRAME:AddMessage("输入 /拾取 q 可关闭权限检测")
		end
	end
end

-- 处理拾取目标命令
function Automaton_ShiQu:HandleLootTarget(arg)
	if arg == "clear" or arg == "清除" then
		self:ClearLootTarget()
	else
		self:SetLootTarget()
	end
end

------------------------------
--      Event Handlers      --
------------------------------

-- 处理 loot 打开事件
function Automaton_ShiQu:LOOT_OPENED()
	local currentTime = GetTime()
	-- 防止重复处理：检查冷却时间和处理标志
	if self.isProcessingLoot or (currentTime - self.lastLootTime < 0.5) then
		return
	end

	self.isProcessingLoot = true
	self.lastLootTime = currentTime

	-- 使用 pcall 保护执行，确保即使出错也能重置标志
	local success, err = pcall(function()
		-- 检查模块是否激活且权限检测开启
		if Automaton:IsModuleActive("ShiQu") and self.db.profile.permissionCheck then
			local announcestring = "装备清单:"
			local itemFound = false

			-- 遍历可能的拾取者（1-40）
			for looterindex = 1, 40 do
				local candidateName = GetMasterLootCandidate(looterindex)
				if not candidateName then
					break
				end -- 无更多候选者时退出循环

				-- 优先分配给目标玩家（非绑定物品）
				if self.db.profile.targetPlayerName and candidateName == self.db.profile.targetPlayerName then
					for lootedindex = 1, GetNumLootItems() do
						local lootAction = self:ShouldAutolootItem(lootedindex)
						if lootAction == 1 and not self:LootSlotIsSoulbound(lootedindex) then
							GiveMasterLoot(lootedindex, looterindex)
						elseif lootAction == 2 then
							local link = GetLootSlotLink(lootedindex)
							if link then
								announcestring = announcestring .. " " .. link
							else
								-- 如果没有链接（如金币），用物品名代替或忽略
								local _, name = GetLootSlotInfo(lootedindex)
								announcestring = announcestring .. " " .. (name or "未知物品")
							end
							itemFound = true
						end
					end
				-- 分配给当前玩家
				elseif candidateName == UnitName("player") then
					for lootedindex = 1, GetNumLootItems() do
						local lootAction = self:ShouldAutolootItem(lootedindex)
						if lootAction == 1 then
							GiveMasterLoot(lootedindex, looterindex)
						elseif lootAction == 2 then
							local link = GetLootSlotLink(lootedindex)
							if link then
								announcestring = announcestring .. " " .. link
							else
								local _, name = GetLootSlotInfo(lootedindex)
								announcestring = announcestring .. " " .. (name or "未知物品")
							end
							itemFound = true
						end
					end
				end
			end

			-- 仅在启用通报时发送通告并播放音效
			if itemFound and self.db.profile.announceEnabled then
				SendChatMessage(announcestring, "RAID")
				PlaySound("AuctionWindowClose")
			end
		end
	end)

	if not success then
		DEFAULT_CHAT_FRAME:AddMessage("|cffFF0000[强制拾取] 处理出错: " .. tostring(err))
	end

	self.isProcessingLoot = false
end
