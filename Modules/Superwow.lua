if not SUPERWOW_VERSION then
	return
end
assert(Automaton, "Automaton not found!")

local L = AceLibrary("AceLocale-2.2"):new("SuperAPI")

L:RegisterTranslations("enUS", function()
	return {
		["No SuperWoW detected"] = true,
		["%d/511 Characters Used"] = true,
		["Shows whisper, party, raid, and battleground chat text in speech bubbles above characters' heads."] = true,
		["Show Whisper and Group Chat Bubbles"] = true,
		["|cffffcc00SuperAPI|cffffaaaa Loaded.  Check the minimap icon for options."] = true,
		["Raw GUID logging enabled."] = true,
		["Raw GUID logging disabled."] = true,

		["Always on"] = true,
		["Always off"] = true,
		["Shift to toggle on"] = true,
		["Shift to toggle off"] = true,
		["Default - incomplete circle"] = true,
		["Full circle (must download texture)"] = true,
		["Full circle with arrow for facing direction (must download texture)"] = true,
		["Classic incomplete circle oriented in facing direction"] = true,
		["Autoloot (Read tooltip)"] = true,
		["Specifies autoloot behavior.  If using Vanilla Tweaks quickloot all of these will be reversed (always on will actually be always off, Shift to toggle on will be Shift to toggle off etc)."] = true,
		["Clickthrough corpses"] = true,
		["Allows you to click through corpses to loot corpses underneath them."] = true,
		["Field of view (Requires reload)"] = true,
		["Changes the field of view of the game.  Requires reload to take effect."] = true,
		["Selection circle style"] = true,
		["Changes the style of the selection circle."] = true,
		["Background sound"] = true,
		["Allows game sound to play even when the window is in the background."] = true,
		["Uncapped sounds"] = true,
		["Allows more game sounds to play at the same time by removing hardcoded limit.  This will also set SoundSoftwareChannels and SoundMaxHardwareChannels to 64.  If you experience any weird crashes you may want to turn this off."] = true,
		["Loot Sparkle"] = true,
		["Toggle loot sparkle effect on lootable treasure."] = true,
		["GUID Combat Log"] = true,
		["Changes the combat log to print GUIDs instead of names, will break a lot of addons."] = true,

		["Healing Text"] = true,
		["Toggle the display of healing feedback text in the game world."] = true,
		["Nameplate Settings"] = true,
		["Settings related to nameplates."] = true,
		["Nameplate Range"] = true,
		["Changes the distance at which nameplates are shown."] = true,
		["Nameplate Motion"] = true,
		["Changes how nameplates move when they overlap."] = true,
		["0=Overlap, 1=Default, 2=Smart, 3=Compact"] = true,
		["Nameplate Motion is disabled while pfUI nameplates are active (pfUI owns stacking)."] = true,
		["Chat Bubble Settings"] = true,
		["Settings related to chat bubbles above units."] = true,
		["Chat Bubble Range"] = true,
		["Changes the distance at which chat bubbles are visible."] = true,
		["Say/Yell Chat Bubbles"] = true,
		["Toggle chat bubbles for say and yell messages."] = true,
		["Party Chat Bubbles"] = true,
		["Toggle chat bubbles for party messages."] = true,
		["Raid Chat Bubbles"] = true,
		["Toggle chat bubbles for raid messages."] = true,
		["Battleground Chat Bubbles"] = true,
		["Toggle chat bubbles for battleground messages."] = true,
		["Whisper Chat Bubbles"] = true,
		["Toggle chat bubbles for whisper messages."] = true,
		["Creature Chat Bubbles"] = true,
		["Toggle chat bubbles for creature (NPC) messages."] = true,
		["Auto open clams and boxes"] = true,
		["Automatically opens clams and right-click containers (boxes) in your bags. Locked lockboxes that need pick locking are skipped."] = true,
	}
end)

L:RegisterTranslations("zhCN", function()
	return {
		["No SuperWoW detected"] = "未发现SuperWoW",
		["%d/511 Characters Used"] = "已使用 %d/511 个字符",
		["Shows whisper, party, raid, and battleground chat text in speech bubbles above characters' heads."] = "显示密语、小队、团队和战场聊天文本在角色头顶的气泡中。",
		["Show Whisper and Group Chat Bubbles"] = "显示密语和团队聊天气泡",
		["|cffffcc00SuperAPI|cffffaaaa Loaded.  Check the minimap icon for options."] = "|cffffcc00SuperAPI|cffffaaaa 已加载。使用小地图图标配置选项。",
		["Raw GUID logging enabled."] = "原始 GUID 日志记录已启用。",
		["Raw GUID logging disabled."] = "原始 GUID 日志记录已禁用。",

		["Always on"] = "始终开启",
		["Always off"] = "始终关闭",
		["Shift to toggle on"] = "按Shift键开启",
		["Shift to toggle off"] = "按Shift键关闭",
		["Default - incomplete circle"] = "默认 - 不完整的圆，只显示视角方向的部分",
		["Full circle (must download texture)"] = "完整圆形（必须下载纹理）",
		["Full circle with arrow for facing direction (must download texture)"] = "带箭头指示方向的完整圆形（必须下载纹理）",
		["Classic incomplete circle oriented in facing direction"] = "经典不完整圆形，朝向方向",
		["Autoloot (Read tooltip)"] = "自动拾取",
		["Specifies autoloot behavior.  If using Vanilla Tweaks quickloot all of these will be reversed (always on will actually be always off, Shift to toggle on will be Shift to toggle off etc)."] = "自动拾取，如果已使用登录器或者龟壳的自动拾取，这些设置将会相反（开启自动拾取将会是不自动拾取，按Shift键开启将会是按Shift键关闭等）。",
		["Clickthrough corpses"] = "点击穿透尸体",
		["Allows you to click through corpses to loot corpses underneath them."] = "允许你点击穿透尸体以拾取下面的尸体。",
		["Field of view (Requires reload)"] = "视野范围（需要重载）",
		["Changes the field of view of the game.  Requires reload to take effect."] = "改变游戏的视野范围。需要重载才能生效。",
		["Selection circle style"] = "选择目标脚下光圈样式",
		["Changes the style of the selection circle."] = "改变目标光圈的样式。",
		["Background sound"] = "背景声音",
		["Allows game sound to play even when the window is in the background."] = "即使窗口位于后台，也允许游戏声音播放。",
		["Uncapped sounds"] = "无限制声音",
		["Allows more game sounds to play at the same time by removing hardcoded limit.  This will also set SoundSoftwareChannels and SoundMaxHardwareChannels to 64.  If you experience any weird crashes you may want to turn this off."] = "通过移除硬编码限制，允许更多游戏声音同时播放。这也将设置SoundSoftwareChannels和SoundMaxHardwareChannels为64。如果你遇到任何奇怪的崩溃，你可能想要关闭这个。",
		["Loot Sparkle"] = "战利品闪光效果",
		["Toggle loot sparkle effect on lootable treasure."] = "切换战利品闪光效果。",
		["GUID Combat Log"] = "GUID战斗日志",
		["Changes the combat log to print GUIDs instead of names, will break a lot of addons."] = "将战斗日志更改为打印GUID而不是名称，将会破坏很多插件。",

		["Healing Text"] = "浮动治疗文字",
		["Toggle the display of healing feedback text in the game world."] = "开关游戏世界中治疗反馈文字的显示。",
		["Nameplate Settings"] = "姓名板设置",
		["Settings related to nameplates."] = "与姓名板相关的一组设置",
		["Nameplate Range"] = "姓名板距离",
		["Changes the distance at which nameplates are shown."] = "更改姓名板的显示距离。",
		["Nameplate Motion"] = "姓名板运动方式",
		["Changes how nameplates move when they overlap."] = "更改姓名板移动时的行为。",
		["0=Overlap, 1=Default, 2=Smart, 3=Compact"] = "0=重叠, 1=默认分散, 2=智能分散, 3=紧凑分散",
		["Nameplate Motion is disabled while pfUI nameplates are active (pfUI owns stacking)."] = "PFUI 姓名板激活时此选项自动失效（堆叠由 PFUI 接管）。",
		["Chat Bubble Settings"] = "聊天气泡设置",
		["Settings related to chat bubbles above units."] = "与单位头顶聊天气泡相关的一组设置",
		["Chat Bubble Range"] = "聊天气泡距离",
		["Changes the distance at which chat bubbles are visible."] = "更改聊天气泡的显示距离。",
		["Say/Yell Chat Bubbles"] = "说/喊话聊天气泡",
		["Toggle chat bubbles for say and yell messages."] = "开关说和喊话的聊天气泡",
		["Party Chat Bubbles"] = "小队聊天气泡",
		["Toggle chat bubbles for party messages."] = "开关小队聊天气泡",
		["Raid Chat Bubbles"] = "团队聊天气泡",
		["Toggle chat bubbles for raid messages."] = "开关团队聊天气泡",
		["Battleground Chat Bubbles"] = "战场聊天气泡",
		["Toggle chat bubbles for battleground messages."] = "开关战场聊天气泡",
		["Whisper Chat Bubbles"] = "私聊聊天气泡",
		["Toggle chat bubbles for whisper messages."] = "开关私聊聊天气泡",
		["Creature Chat Bubbles"] = "生物聊天气泡",
		["Toggle chat bubbles for creature (NPC) messages."] = "开关生物（NPC）的聊天气泡",
		["Auto open clams and boxes"] = "自动开蚌壳和箱子",
		["Automatically opens clams and right-click containers (boxes) in your bags. Locked lockboxes that need pick locking are skipped."] = "自动开启背包里右击可开启的容器（蚌壳、箱子）。锁着的箱子（需开锁）不会被自动开启。",
	}
end)

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_Superwow = Automaton:NewModule("Superwow")
Automaton_Superwow.modulename = "SuperWoW [自动拾取]"
Automaton_Superwow.moduledesc = "SuperWoW模组的高级设置"

----------------------------------
--      Auto open clams/boxes   --
----------------------------------

-- 允许自动开启的容器白名单（仅右击可开启的；锁着的箱子需要开锁，不在其中）
local AutoOpenIDs = {
	-- 蚌壳
	[5523] = true, -- 小藤壶蚌 Small Barnacled Clam
	[5524] = true, -- 厚壳蚌 Thick-shelled Clam
	[7973] = true, -- 大嘴蚌 Big-mouth Clam
	[15874] = true, -- 软壳蚌 Soft-shelled Clam
	[9276] = true, -- 蛛网蚌 Webbed Clam
	-- 箱子（采矿/任务奖励，右击开启）
	[4632] = true, -- 铁箱 Iron Box
	[7974] = true, -- 秘银箱 Mithril Box
	[12043] = true, -- 真银箱 Truesilver Box
	[16023] = true, -- 瑟银箱 Thorium Box
}

local AutoOpenScanTip = nil
local AutoOpenBusy = false -- 正在执行开启，防止重入
local AutoOpenPending = false -- 已安排延迟开启，防止 BAG_UPDATE 抖动风暴
local AutoOpenCustomSet = {} -- 用户自定义自动开启物品ID集合（由 autoopen_custom 解析）

-- 把设置里的自定义ID表（key=物品ID字符串）重建为查找表；兼容旧版字符串格式
local function AutoOpenRebuildCustom()
	AutoOpenCustomSet = {}
	local dbp = Automaton_Superwow.db and Automaton_Superwow.db.profile
	if not dbp then
		return
	end
	local tbl = dbp.autoopen_custom
	if type(tbl) ~= "table" then
		tbl = {}
		dbp.autoopen_custom = tbl
	end
	for idStr in pairs(tbl) do
		local idNum = tonumber(idStr)
		if idNum then
			AutoOpenCustomSet[idNum] = true
		end
	end
end

-- 从物品链接里取 itemID（兼容本客户端短链接 item:ID:0:0:0）
local function AutoOpenLinkID(link)
	if not link then
		return nil
	end
	local _, _, id = string.find(link, "item:(%d+)")
	return tonumber(id)
end

-- 用隐藏 tooltip 确认该格物品确实可开启（避免误开锁定物）
local function AutoOpenCanOpen(bag, slot)
	if not ITEM_OPENABLE then
		return true
	end -- 客户端未定义该全局时信任白名单
	if not AutoOpenScanTip then
		AutoOpenScanTip = CreateFrame("GameTooltip", "AutomatonSuperwowOpenTip", UIParent, "GameTooltipTemplate")
		AutoOpenScanTip:SetOwner(UIParent, "ANCHOR_NONE")
	end
	AutoOpenScanTip:ClearLines()
	local ok = pcall(AutoOpenScanTip.SetBagItem, AutoOpenScanTip, bag, slot)
	if not ok then
		return true
	end -- 读不出就信任白名单
	local n = AutoOpenScanTip:NumLines() or 0
	if n == 0 then
		return true
	end -- tooltip 为空，信任白名单
	for i = 1, n do
		local left = getglobal("AutomatonSuperwowOpenTipTextLeft" .. i)
		if left then
			local text = left:GetText()
			if text and text == ITEM_OPENABLE then
				return true
			end
		end
	end
	return false -- 明确读到内容但非“可开启”，不开
end

-- 这些界面打开时不要自动开容器，避免误操作
local function AutoOpenForbidden()
	if
		(LootFrame and LootFrame:IsVisible())
		or (TradeFrame and TradeFrame:IsVisible())
		or (BankFrame and BankFrame:IsVisible())
		or (MailFrame and MailFrame:IsVisible())
		or (MerchantFrame and MerchantFrame:IsVisible())
		or (AuctionFrame and AuctionFrame:IsVisible())
	then
		return true
	end
	return false
end

function Automaton_Superwow:AutoOpenContainers()
	if not self.db.profile.autoopen then
		return
	end
	if AutoOpenBusy or AutoOpenPending then
		return
	end -- 已在处理或已排程，跳过
	AutoOpenPending = true
	local function run()
		AutoOpenPending = false
		if not self.db.profile.autoopen then
			return
		end
		if AutoOpenForbidden() then
			return
		end -- 拾取/交易/银行等界面打开时不自动开
		AutoOpenBusy = true
		for bag = 0, 4 do
			local size = GetContainerNumSlots(bag)
			if size and size > 0 then
				for slot = 1, size do
					local link = GetContainerItemLink(bag, slot)
					local id = AutoOpenLinkID(link)
					if id and (AutoOpenIDs[id] or AutoOpenCustomSet[id]) and AutoOpenCanOpen(bag, slot) then
						UseContainerItem(bag, slot)
					end
				end
			end
		end
		AutoOpenBusy = false
	end
	-- 延迟 0.25s 再开，把 UseContainerItem 移出 BAG_UPDATE 同步上下文，避免卡拾取/事件风暴
	if type(C_Timer) == "table" and C_Timer.After then
		C_Timer.After(0.25, run)
	else
		run() -- 无 C_Timer 时回退同步执行（busy 锁仍防重入）
	end
end

-- 完全安全的 CVar 操作，用 pcall 捕获任何错误
local function SafeGetCVar(name, default)
	local ok, val = pcall(GetCVar, name)
	if ok and val ~= nil then
		return val
	end
	return default
end

local function SafeSetCVar(name, value)
	pcall(SetCVar, name, value)
end

-- PFUI 拥有自己的姓名板堆叠/定位实现（C.nameplates.overlap 等），
-- 而它从不设置引擎层的 NameplateMotion CVar。当 PFUI 的 nameplates
-- 模块激活时，引擎自带的 NameplateMotion 会与 PFUI 的手动定位/堆叠
-- 打架。因此 Automatonex 应让位给 PFUI：由 PFUI 全权负责姓名板堆叠。
local function PfuiControlsNameplates()
	if not _G.pfUI then
		return false
	end
	local cfg = _G.pfUI_config
	-- PFUI 允许单独禁用 nameplates 模块；禁用时引擎运动方式可正常生效
	if cfg and cfg.disabled and cfg.disabled["nameplates"] == "1" then
		return false
	end
	return true
end

Automaton_Superwow.options = {
	header1 = {
		type = "header",
		name = "拾取",
		order = 10,
	},
	autoloot = {
		type = "toggle",
		name = L["Autoloot (Read tooltip)"],
		order = 11,
		desc = L["Specifies autoloot behavior.  If using Vanilla Tweaks quickloot all of these will be reversed (always on will actually be always off, Shift to toggle on will be Shift to toggle off etc)."],
		get = function()
			return Automaton_Superwow.db.profile.autoloot
		end,
		set = function(v)
			if v then
				Automaton_Superwow.db.profile.shiftloot = false
			end
			Automaton_Superwow.db.profile.autoloot = v
			Automaton_Superwow:TurnOnAutoloot()
		end,
	},
	shiftloot = {
		type = "toggle",
		name = L["Shift to toggle on"] .. "手动拾取",
		desc = "按住Shift拾取物品，不按shift就自动拾取。\n如果非必要建议开启自动拾取模式。",
		order = 12,
		get = function()
			return Automaton_Superwow.db.profile.shiftloot
		end,
		set = function(v)
			if v then
				Automaton_Superwow.db.profile.autoloot = false
			end
			Automaton_Superwow.db.profile.shiftloot = v
			Automaton_Superwow:TurnOnAutoloot()
		end,
	},
	clickthrough = {
		type = "toggle",
		name = L["Clickthrough corpses"],
		desc = L["Allows you to click through corpses to loot corpses underneath them."],
		order = 13,
		get = function()
			return Automaton_Superwow.db.profile.clickthrough
		end,
		set = function(v)
			if v then
				Clickthrough(1)
			else
				Clickthrough(0)
			end
			Automaton_Superwow.db.profile.clickthrough = v
		end,
	},
	autoopen = {
		type = "toggle",
		name = L["Auto open clams and boxes"],
		desc = L["Automatically opens clams and right-click containers (boxes) in your bags. Locked lockboxes that need pick locking are skipped."],
		order = 14,
		get = function()
			return Automaton_Superwow.db.profile.autoopen
		end,
		set = function(v)
			Automaton_Superwow.db.profile.autoopen = v
			if v then
				Automaton_Superwow:RegisterEvent("BAG_UPDATE", "AutoOpenContainers")
				Automaton_Superwow:RegisterEvent("LOOT_CLOSED", "AutoOpenContainers")
				Automaton_Superwow:RegisterEvent("MAIL_CLOSED", "AutoOpenContainers")
				Automaton_Superwow:RegisterEvent("TRADE_CLOSED", "AutoOpenContainers")
				Automaton_Superwow:RegisterEvent("BANKFRAME_CLOSED", "AutoOpenContainers")
				Automaton_Superwow:AutoOpenContainers()
			else
				Automaton_Superwow:UnregisterAllEvents()
			end
		end,
	},
	autoopen_custom = {
		type = "group",
		name = "自定义自动开启列表",
		desc = "管理自定义自动开启的容器/箱子物品ID（仅右键可直接开启的生效，需要开锁的会被跳过）",
		order = 15,
		args = {
			add = {
				type = "text",
				name = "添加物品（ID）",
				desc = "添加物品ID到自动开启列表",
				order = 1,
				usage = "<ItemId>",
				get = false,
				set = function(v)
					if v and v ~= "" then
						local idNum = tonumber(v)
						if not idNum then
							Automaton:Print("无效的物品ID")
							return
						end
						local key = tostring(idNum)
						Automaton_Superwow.db.profile.autoopen_custom[key] = true
						AutoOpenRebuildCustom()
						Automaton:Print("已添加自动开启物品ID: " .. key)
						if Automaton_Superwow.db.profile.autoopen then
							Automaton_Superwow:AutoOpenContainers()
						end
					end
				end,
			},
			remove = {
				type = "text",
				name = "移除物品（ID）",
				desc = "从自动开启列表移除物品ID",
				order = 2,
				usage = "<ItemId>",
				get = false,
				set = function(v)
					if v and v ~= "" then
						local idNum = tonumber(v)
						if not idNum then
							Automaton:Print("无效的物品ID")
							return
						end
						local key = tostring(idNum)
						if Automaton_Superwow.db.profile.autoopen_custom[key] then
							Automaton_Superwow.db.profile.autoopen_custom[key] = nil
							AutoOpenRebuildCustom()
							Automaton:Print("已移除自动开启物品ID: " .. key)
						else
							Automaton:Print("未找到物品ID: " .. key)
						end
					end
				end,
			},
			list = {
				type = "execute",
				name = "打印列表",
				desc = "列出所有自定义自动开启的物品ID",
				order = 3,
				func = function()
					Automaton:Print("自定义自动开启物品ID:")
					local n = 0
					for idStr in pairs(Automaton_Superwow.db.profile.autoopen_custom) do
						Automaton:Print("- " .. idStr)
						n = n + 1
					end
					if n == 0 then
						Automaton:Print("(空)")
					end
				end,
			},
			purge = {
				type = "execute",
				name = "清空列表",
				desc = "清空所有自定义自动开启物品ID",
				order = 4,
				func = function()
					Automaton_Superwow.db.profile.autoopen_custom = {}
					AutoOpenRebuildCustom()
					Automaton:Print("自定义自动开启列表已清空")
				end,
			},
		},
	},
	header2 = {
		type = "header",
		name = "画面与音效",
		order = 20,
	},
	fov = {
		type = "range",
		name = L["Field of view (Requires reload)"],
		desc = L["Changes the field of view of the game.  Requires reload to take effect."],
		order = 21,
		min = 0.1,
		max = 3.14,
		step = 0.05,
		get = function()
			return Automaton_Superwow.db.profile.fov
		end,
		set = function(v)
			Automaton_Superwow.db.profile.fov = v
			SafeSetCVar("FoV", v)
		end,
	},
	backgroundsound = {
		type = "toggle",
		name = L["Background sound"],
		desc = L["Allows game sound to play even when the window is in the background."],
		order = 22,
		get = function()
			return Automaton_Superwow.db.profile.backgroundsound
		end,
		set = function(v)
			SafeSetCVar("BackgroundSound", v and "1" or "0")
			Automaton_Superwow.db.profile.backgroundsound = v
		end,
	},
	uncappedsounds = {
		type = "toggle",
		name = L["Uncapped sounds"],
		order = 23,
		desc = L["Allows more game sounds to play at the same time by removing hardcoded limit.  This will also set SoundSoftwareChannels and SoundMaxHardwareChannels to 64.  If you experience any weird crashes you may want to turn this off."],
		get = function()
			return SafeGetCVar("UncapSounds", "0") == "1"
		end,
		set = function(v)
			if v then
				SafeSetCVar("UncapSounds", "1")
				SafeSetCVar("SoundSoftwareChannels", "64")
				SafeSetCVar("SoundMaxHardwareChannels", "64")
			else
				SafeSetCVar("UncapSounds", "0")
				SafeSetCVar("SoundSoftwareChannels", "12")
				SafeSetCVar("SoundMaxHardwareChannels", "12")
			end
			Automaton_Superwow.db.profile.uncappedsounds = v
		end,
	},
	LootSparkle = {
		type = "toggle",
		name = L["Loot Sparkle"],
		order = 24,
		desc = L["Toggle loot sparkle effect on lootable treasure."],
		get = function()
			return Automaton_Superwow.db.profile.LootSparkle
		end,
		set = function(v)
			SafeSetCVar("LootSparkle", v and "1" or "0")
			Automaton_Superwow.db.profile.LootSparkle = v
		end,
	},
	SelectionCircleStyle = {
		type = "range",
		name = L["Selection circle style"],
		order = 25,
		desc = L["Changes the style of the selection circle."],
		min = 1,
		max = 4,
		step = 1,
		get = function()
			return Automaton_Superwow.db.profile.SelectionCircleStyle
		end,
		set = function(v)
			Automaton_Superwow.db.profile.SelectionCircleStyle = v
			SafeSetCVar("SelectionCircleStyle", tostring(v))
		end,
	},
	healingtext = {
		type = "toggle",
		name = L["Healing Text"],
		order = 26,
		desc = L["Toggle the display of healing feedback text in the game world."],
		get = function()
			return SafeGetCVar("HealingText", Automaton_Superwow.db.profile.healingtext) == "1"
		end,
		set = function(v)
			SafeSetCVar("HealingText", v and "1" or "0")
			Automaton_Superwow.db.profile.healingtext = v
		end,
	},
	nameplates = {
		type = "group",
		name = L["Nameplate Settings"],
		desc = L["Settings related to nameplates."],
		order = 30,
		args = {
			nameplaterange = {
				type = "range",
				name = L["Nameplate Range"],
				order = 1,
				desc = L["Changes the distance at which nameplates are shown."],
				min = 10,
				max = 80,
				step = 1,
				get = function()
					return tonumber(SafeGetCVar("NameplateRange", Automaton_Superwow.db.profile.nameplaterange)) or 40
				end,
				set = function(v)
					SafeSetCVar("NameplateRange", v)
					Automaton_Superwow.db.profile.nameplaterange = v
				end,
			},
			nameplatemotion = {
				type = "range",
				name = L["Nameplate Motion"],
				order = 2,
				desc = L["Changes how nameplates move when they overlap."]
					.. " "
					.. L["0=Overlap, 1=Default, 2=Smart, 3=Compact"]
					.. " "
					.. L["Nameplate Motion is disabled while pfUI nameplates are active (pfUI owns stacking)."],
				min = 0,
				max = 3,
				step = 1,
				get = function()
					return Automaton_Superwow.db.profile.nameplatemotion or 0
				end,
				set = function(v)
					Automaton_Superwow.db.profile.nameplatemotion = v
					if PfuiControlsNameplates() then
						-- PFUI 为主：禁用引擎自带的运动/堆叠，避免与 PFUI 的 overlap 实现冲突
						SafeSetCVar("NameplateMotion", "0")
					else
						SafeSetCVar("NameplateMotion", tostring(v))
					end
				end,
			},
		},
	},
	chatbubbles = {
		type = "group",
		name = L["Chat Bubble Settings"],
		desc = L["Settings related to chat bubbles above units."],
		order = 40,
		args = {
			chatbubblerange = {
				type = "range",
				name = L["Chat Bubble Range"],
				order = 1,
				desc = L["Changes the distance at which chat bubbles are visible."],
				min = 10,
				max = 200,
				step = 5,
				get = function()
					return tonumber(SafeGetCVar("ChatBubbleRange", Automaton_Superwow.db.profile.chatbubblerange)) or 80
				end,
				set = function(v)
					SafeSetCVar("ChatBubbleRange", v)
					Automaton_Superwow.db.profile.chatbubblerange = v
				end,
			},
			togglesay = {
				type = "toggle",
				name = L["Say/Yell Chat Bubbles"],
				order = 2,
				desc = L["Toggle chat bubbles for say and yell messages."],
				get = function()
					return SafeGetCVar("ChatBubbles", Automaton_Superwow.db.profile.togglesay) == "1"
				end,
				set = function(v)
					SafeSetCVar("ChatBubbles", v and "1" or "0")
					Automaton_Superwow.db.profile.togglesay = v
				end,
			},
			togglepartybubbles = {
				type = "toggle",
				name = L["Party Chat Bubbles"],
				order = 3,
				desc = L["Toggle chat bubbles for party messages."],
				get = function()
					return SafeGetCVar("ChatBubblesParty", Automaton_Superwow.db.profile.togglepartybubbles) == "1"
				end,
				set = function(v)
					SafeSetCVar("ChatBubblesParty", v and "1" or "0")
					Automaton_Superwow.db.profile.togglepartybubbles = v
				end,
			},
			toggleraidbubbles = {
				type = "toggle",
				name = L["Raid Chat Bubbles"],
				order = 4,
				desc = L["Toggle chat bubbles for raid messages."],
				get = function()
					return SafeGetCVar("ChatBubblesRaid", Automaton_Superwow.db.profile.toggleraidbubbles) == "1"
				end,
				set = function(v)
					SafeSetCVar("ChatBubblesRaid", v and "1" or "0")
					Automaton_Superwow.db.profile.toggleraidbubbles = v
				end,
			},
			togglebgbubbles = {
				type = "toggle",
				name = L["Battleground Chat Bubbles"],
				order = 5,
				desc = L["Toggle chat bubbles for battleground messages."],
				get = function()
					return SafeGetCVar("ChatBubblesBattleground", Automaton_Superwow.db.profile.togglebgbubbles) == "1"
				end,
				set = function(v)
					SafeSetCVar("ChatBubblesBattleground", v and "1" or "0")
					Automaton_Superwow.db.profile.togglebgbubbles = v
				end,
			},
			togglewhisperbubbles = {
				type = "toggle",
				name = L["Whisper Chat Bubbles"],
				order = 6,
				desc = L["Toggle chat bubbles for whisper messages."],
				get = function()
					return SafeGetCVar("ChatBubblesWhisper", Automaton_Superwow.db.profile.togglewhisperbubbles) == "1"
				end,
				set = function(v)
					SafeSetCVar("ChatBubblesWhisper", v and "1" or "0")
					Automaton_Superwow.db.profile.togglewhisperbubbles = v
				end,
			},
			togglecreaturebubbles = {
				type = "toggle",
				name = L["Creature Chat Bubbles"],
				order = 7,
				desc = L["Toggle chat bubbles for creature (NPC) messages."],
				get = function()
					return SafeGetCVar("ChatBubblesCreatures", Automaton_Superwow.db.profile.togglecreaturebubbles)
						== "1"
				end,
				set = function(v)
					SafeSetCVar("ChatBubblesCreatures", v and "1" or "0")
					Automaton_Superwow.db.profile.togglecreaturebubbles = v
				end,
			},
		},
	},
}

------------------------------
--      Initialization      --
------------------------------

function Automaton_Superwow:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("Superwow")
	Automaton:RegisterDefaults("Superwow", "profile", {
		disabled = false,
		autoloot = true,
		clickthrough = false,
		autoopen = false,
		autoopen_custom = {},
		shiftloot = false,
		fov = 1.5,
		backgroundsound = false,
		SelectionCircleStyle = 1,
		LootSparkle = true,
		uncappedsounds = false,
		healingtext = true,
		nameplaterange = 40,
		nameplatemotion = 1,
		chatbubblerange = 80,
		togglesay = true,
		togglepartybubbles = true,
		toggleraidbubbles = true,
		togglebgbubbles = true,
		togglewhisperbubbles = true,
		togglecreaturebubbles = true,
	})
	Automaton:SetDisabledAsDefault(self, "Superwow")
	self:RegisterOptions(self.options)
end

function Automaton_Superwow:OnEnable()
	if not self.superwowver then
		self.superwowver = SUPERWOW_VERSION
	end
	if self.superwowver ~= SUPERWOW_VERSION then
		print("SuperWoW有最新版<" .. SUPERWOW_VERSION .. ">需要升级!")
	end
	MACROFRAME_CHAR_LIMIT = L["%d/511 Characters Used"]
	OPTION_TOOLTIP_PARTY_CHAT_BUBBLES =
		L["Shows whisper, party, raid, and battleground chat text in speech bubbles above characters' heads."]
	PARTY_CHAT_BUBBLES_TEXT = L["Show Whisper and Group Chat Bubbles"]

	-- 应用所有选项（通过 set 方法，内部已使用 SafeSetCVar）
	self.options.clickthrough.set(self.db.profile.clickthrough)
	self.options.LootSparkle.set(self.db.profile.LootSparkle)
	self.options.SelectionCircleStyle.set(self.db.profile.SelectionCircleStyle)
	self.options.backgroundsound.set(self.db.profile.backgroundsound)
	self.options.uncappedsounds.set(self.db.profile.uncappedsounds)
	self.options.healingtext.set(self.db.profile.healingtext)
	self.options.fov.set(self.db.profile.fov)

	self.options.nameplates.args.nameplaterange.set(self.db.profile.nameplaterange)
	self.options.nameplates.args.nameplatemotion.set(self.db.profile.nameplatemotion)

	-- 处理加载顺序：若 pfUI 之后才加载，需在 pfUI 就绪后重新评估姓名板归属
	self:WatchPfUINameplateOwnership()

	self.options.chatbubbles.args.chatbubblerange.set(self.db.profile.chatbubblerange)
	self.options.chatbubbles.args.togglesay.set(self.db.profile.togglesay)
	self.options.chatbubbles.args.togglepartybubbles.set(self.db.profile.togglepartybubbles)
	self.options.chatbubbles.args.toggleraidbubbles.set(self.db.profile.toggleraidbubbles)
	self.options.chatbubbles.args.togglebgbubbles.set(self.db.profile.togglebgbubbles)
	self.options.chatbubbles.args.togglewhisperbubbles.set(self.db.profile.togglewhisperbubbles)
	self.options.chatbubbles.args.togglecreaturebubbles.set(self.db.profile.togglecreaturebubbles)

	AutoOpenRebuildCustom()

	self:TurnOnAutoloot()

	if self.db.profile.autoopen then
		self:RegisterEvent("BAG_UPDATE", "AutoOpenContainers")
		self:RegisterEvent("LOOT_CLOSED", "AutoOpenContainers")
		self:RegisterEvent("MAIL_CLOSED", "AutoOpenContainers")
		self:RegisterEvent("TRADE_CLOSED", "AutoOpenContainers")
		self:RegisterEvent("BANKFRAME_CLOSED", "AutoOpenContainers")
	end

	if CombatText_AddMessage then
		self:Hook("CombatText_AddMessage")
	end
	self:Hook("SpellButton_OnClick")
	self:Hook("SetItemRef")
	self:Hook("UnitFrame_OnEnter")
	self:Hook("UnitFrame_OnLeave")
end

function Automaton_Superwow:OnDisable()
	self:UnregisterAllEvents()
end

------------------------------
--      Event Handlers      --
------------------------------
function Automaton_Superwow:TurnOnAutoloot()
	if self.f then
		self.f:SetScript("OnUpdate", nil)
		self.f = nil
	end
	if self.db.profile.shiftloot then
		self.f = CreateFrame("Frame")
		self.f:SetScript("OnUpdate", function()
			if IsShiftKeyDown() then
				SetAutoloot(1)
			else
				SetAutoloot(0)
			end
		end)
	elseif self.db.profile.autoloot then
		SetAutoloot(1)
	else
		SetAutoloot(0)
	end
end

-- 当 PFUI 在 Automatonex 之后加载时，OnEnable 阶段还检测不到 pfUI，
-- 此时 NameplateMotion 会按用户设定被错误地置为非 0，与 PFUI 打架。
-- 这里监听 ADDON_LOADED(pfUI)，一旦 pfUI 就绪就重新应用姓名板运动设置，
-- 让其正确让位给 PFUI。若 pfUI 已在 OnEnable 前加载则无需监听。
function Automaton_Superwow:WatchPfUINameplateOwnership()
	if PfuiControlsNameplates() then
		return
	end -- 已经由 PFUI 接管，无需监听
	local mod = self
	local f = CreateFrame("Frame")
	f:RegisterEvent("ADDON_LOADED")
	f:SetScript("OnEvent", function()
		if arg1 == "pfUI" then
			mod.options.nameplates.args.nameplatemotion.set(mod.db.profile.nameplatemotion)
			f:UnregisterEvent("ADDON_LOADED")
			f:SetScript("OnEvent", nil)
		end
	end)
end

function Automaton_Superwow:GetSpellLink(id)
	local spellname = SpellInfo(id)
	return "\124cffffffff\124Henchant:" .. id .. "\124h[" .. spellname .. "]\124h\124r"
end

function Automaton_Superwow:SetItemRef(link, text, button)
	link = gsub(link, "spell:", "enchant:")
	self.hooks.SetItemRef(link, text, button)
end

function Automaton_Superwow:SpellButton_OnClick(drag)
	if
		not drag
		and IsShiftKeyDown()
		and ChatFrameEditBox:IsVisible()
		and (not MacroFrame or not MacroFrame:IsVisible())
	then
		local bookId = SpellBook_GetSpellID(this:GetID())
		local _, _, spellID = GetSpellName(bookId, SpellBookFrame.bookType)
		ChatFrameEditBox:Insert(self:GetSpellLink(spellID))
	else
		self.hooks.SpellButton_OnClick(drag)
	end
end

function Automaton_Superwow:UnitFrame_OnEnter()
	self.hooks.UnitFrame_OnEnter()
	SetMouseoverUnit(this.unit)
end

function Automaton_Superwow:UnitFrame_OnLeave()
	self.hooks.UnitFrame_OnLeave()
	SetMouseoverUnit()
end

function Automaton_Superwow:CombatText_AddMessage(message, scrollFunction, r, g, b, displayType, isStaggered)
	local newMessage = gsub(message, "(%s%[)(0x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x)(%])", function(_, hex, _)
		if UnitIsUnit(hex, "player") then
			return nil
		end
		local _, class = UnitClass(hex)
		if not class then
			return " [" .. UnitName(hex) .. "]"
		end
		return " [|C" .. RAID_CLASS_COLORS[class].colorStr .. UnitName(hex) .. "|r]"
	end)
	return self.hooks.CombatText_AddMessage(newMessage, scrollFunction, r, g, b, displayType, isStaggered)
end
