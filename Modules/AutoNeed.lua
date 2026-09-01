assert(Automaton, "Automaton not found!")

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_AutoNeed = Automaton:NewModule("AutoNeed")
local self = Automaton_AutoNeed
local needvaule = { ["需求"] = 1, ["贪婪"] = 2, ["放弃"] = 0 }
local function set(field, value)
	self.db.char[field] = value
end
local function get(field)
	-- 优先读 char，未初始化时回退到 profile 默认值（如 rolltype 默认"贪婪"）
	return self.db.char[field] or self.db.profile[field]
end

-- 兼容布局差异：quality 两布局都在第 3 位；equipLoc 扫描 "INVTYPE_" 字符串
local function GetItemQualityAndEquipLoc(itemID)
	local info = { GetItemInfo(itemID) }
	local quality = info[3]
	local equipLoc
	for i = 1, table.getn(info) do
		local v = info[i]
		if type(v) == "string" and (v == "" or string.sub(v, 1, 8) == "INVTYPE_") then
			equipLoc = v
		end
	end
	return quality, equipLoc
end

Automaton_AutoNeed.modulename = "自动需求物品"
Automaton_AutoNeed.moduledesc = "队伍/团队拾取时自动需求指定物品"
Automaton_AutoNeed.options = {

	["按品质自动需求"] = {
		type = "group",
		name = "按品质自动需求",
		desc = "按装备品质（紫/蓝/绿）自动需求可装备物品；开启后对所有可装备物品生效",
		order = 2,
		args = {
			enable = {
				name = "模组开关",
				desc = "开启按品质自动需求功能（紫/蓝/绿通用装备，默认关闭）",
				type = "toggle",
				order = 1,
				get = function()
					return self.db.char["品质_enable"]
				end,
				set = function(v)
					self.db.char["品质_enable"] = v
				end,
			},
			purple = {
				name = "紫装需求类型",
				desc = "紫色（史诗）可装备物品的默认需求类型（需求/贪婪/放弃）",
				type = "text",
				order = 2,
				get = get,
				set = set,
				validate = { "需求", "贪婪", "放弃" },
				passValue = "紫装_rolltype",
			},
			blue = {
				name = "蓝装需求类型",
				desc = "蓝色（稀有）可装备物品的默认需求类型（需求/贪婪/放弃）",
				type = "text",
				order = 3,
				get = get,
				set = set,
				validate = { "需求", "贪婪", "放弃" },
				passValue = "蓝装_rolltype",
			},
			green = {
				name = "绿装需求类型",
				desc = "绿色（优秀）可装备物品的默认需求类型（需求/贪婪/放弃）",
				type = "text",
				order = 4,
				get = get,
				set = set,
				validate = { "需求", "贪婪", "放弃" },
				passValue = "绿装_rolltype",
			},
		},
	},

	["自定义物品管理"] = {
		type = "group",
		name = "自定义物品管理",
		desc = "自定义物品的默认需求类型与管理",
		order = 3,
		args = {
			rolltype = {
				name = "默认需求类型",
				desc = "未单独设置物品的默认需求类型（需求/贪婪/放弃）",
				type = "text",
				order = 1,
				get = get,
				set = set,
				validate = { "需求", "贪婪", "放弃" },
				passValue = "rolltype",
			},
			custom_item_add = {
				type = "text",
				name = "添加自定义物品",
				desc = "输入物品ID添加到自动需求列表",
				order = 2,
				get = false,
				set = function(v)
					self:AddItem(v)
				end,
				usage = "输入物品ID后按回车",
			},
			custom_item_remove = {
				type = "text",
				name = "移除自定义物品",
				desc = "输入物品ID从自动需求列表中移除",
				order = 3,
				get = false,
				set = function(v)
					self:DelItem(v)
				end,
				usage = "输入物品ID后按回车",
			},
			custom_item_list = {
				type = "execute",
				name = "查看自定义物品列表",
				desc = "显示所有已添加的自定义物品",
				order = 4,
				func = function()
					self:PrintAll()
				end,
			},
			custom_item_clear = {
				type = "execute",
				name = "清除所有自定义物品",
				desc = "一键清除所有自定义物品设置",
				order = 5,
				func = function()
					self.db.char.autoneedsDB = {}
					print("|cffffff00已清除所有自定义物品！|r", "automaton")
				end,
			},
		},
	},

	separator1 = {
		type = "header",
		name = "物品分类设置",
		order = 10,
	},

	["杂项"] = {
		type = "group",
		name = "杂项",
		desc = "杂项物品自动需求设置",
		order = 20,
		args = {
			enable = {
				name = "开启杂项",
				desc = "开启杂项物品自动需求",
				type = "toggle",
				order = 1,
				get = function()
					return self.db.char["杂项_enable"]
				end,
				set = function(v)
					self.db.char["杂项_enable"] = v
				end,
			},
			-- 每件物品单独配置
			item_4500 = {
				name = "旅行者背包",
				desc = "旅行者背包需求类型",
				type = "text",
				order = 5,
				get = function()
					return self.db.char["item_4500"] or "需求"
				end,
				set = function(v)
					self.db.char["item_4500"] = v
				end,
				validate = { "需求", "贪婪", "放弃" },
			},
			item_51217 = {
				name = "幻化币",
				desc = "幻化币需求类型",
				type = "text",
				order = 10,
				get = function()
					return self.db.char["item_51217"] or "需求"
				end,
				set = function(v)
					self.db.char["item_51217"] = v
				end,
				validate = { "需求", "贪婪", "放弃" },
			},
			item_12843 = {
				name = "堕落者的天灾石",
				desc = "堕落者的天灾石需求类型",
				type = "text",
				order = 15,
				get = function()
					return self.db.char["item_12843"] or "需求"
				end,
				set = function(v)
					self.db.char["item_12843"] = v
				end,
				validate = { "需求", "贪婪", "放弃" },
			},
			item_61197 = {
				name = "褪色的梦境碎片",
				desc = "褪色的梦境碎片需求类型",
				type = "text",
				order = 20,
				get = function()
					return self.db.char["item_61197"] or "需求"
				end,
				set = function(v)
					self.db.char["item_61197"] = v
				end,
				validate = { "需求", "贪婪", "放弃" },
			},
			item_61198 = {
				name = "小型梦境碎片",
				desc = "小型梦境碎片需求类型",
				type = "text",
				order = 30,
				get = function()
					return self.db.char["item_61198"] or "需求"
				end,
				set = function(v)
					self.db.char["item_61198"] = v
				end,
				validate = { "需求", "贪婪", "放弃" },
			},
			item_61199 = {
				name = "明亮梦境碎片",
				desc = "明亮梦境碎片需求类型",
				type = "text",
				order = 40,
				get = function()
					return self.db.char["item_61199"] or "需求"
				end,
				set = function(v)
					self.db.char["item_61199"] = v
				end,
				validate = { "需求", "贪婪", "放弃" },
			},
			item_20381 = {
				name = "梦幻龙鳞",
				desc = "梦幻龙鳞需求类型",
				type = "text",
				order = 50,
				get = function()
					return self.db.char["item_20381"] or "需求"
				end,
				set = function(v)
					self.db.char["item_20381"] = v
				end,
				validate = { "需求", "贪婪", "放弃" },
			},
			item_12662 = {
				name = "恶魔符文",
				desc = "恶魔符文需求类型",
				type = "text",
				order = 60,
				get = function()
					return self.db.char["item_12662"] or "需求"
				end,
				set = function(v)
					self.db.char["item_12662"] = v
				end,
				validate = { "需求", "贪婪", "放弃" },
			},
			item_50203 = {
				name = "腐化之沙",
				desc = "腐化之沙需求类型",
				type = "text",
				order = 70,
				get = function()
					return self.db.char["item_50203"] or "需求"
				end,
				set = function(v)
					self.db.char["item_50203"] = v
				end,
				validate = { "需求", "贪婪", "放弃" },
			},
			item_7082 = {
				name = "空气精华",
				desc = "空气精华需求类型",
				type = "text",
				order = 80,
				get = function()
					return self.db.char["item_7082"] or "需求"
				end,
				set = function(v)
					self.db.char["item_7082"] = v
				end,
				validate = { "需求", "贪婪", "放弃" },
			},
		},
	},
	["卡拉赞"] = {
		type = "group",
		name = "卡拉赞",
		desc = "卡拉赞自动需求设置",
		order = 25,
		args = {
			enable = {
				name = "开启",
				desc = "开启卡拉赞自动需求",
				type = "toggle",
				order = 1,
				get = function()
					return self.db.char["卡拉赞_enable"]
				end,
				set = function(v)
					self.db.char["卡拉赞_enable"] = v
				end,
			},
			arcane = {
				name = "奥术精华需求类型",
				desc = "卡拉赞奥术精华需求类型",
				type = "text",
				order = 2,
				get = function()
					return self.db.char["卡拉赞_arcane"] or "需求"
				end,
				set = function(v)
					self.db.char["卡拉赞_arcane"] = v
				end,
				validate = { "需求", "贪婪", "放弃" },
			},
			overloaded = {
				name = "过载魔法能量需求类型",
				desc = "卡拉赞过载魔法能量需求类型",
				type = "text",
				order = 3,
				get = function()
					return self.db.char["卡拉赞_overloaded"] or "需求"
				end,
				set = function(v)
					self.db.char["卡拉赞_overloaded"] = v
				end,
				validate = { "需求", "贪婪", "放弃" },
			},
		},
	},
	["祖尔格拉布"] = {
		type = "group",
		name = "祖尔格拉布",
		desc = "祖尔格拉布自动需求设置",
		order = 30,
		args = {
			enable = {
				name = "开启",
				desc = "开启祖尔格拉布自动需求",
				type = "toggle",
				order = 1,
				get = function()
					return self.db.char["祖尔格拉布_enable"]
				end,
				set = function(v)
					self.db.char["祖尔格拉布_enable"] = v
				end,
			},
			coins = {
				name = "硬币需求类型",
				desc = "祖尔格拉布硬币需求类型",
				type = "text",
				order = 2,
				get = function()
					return self.db.char["祖尔格拉布_coins"] or "需求"
				end,
				set = function(v)
					self.db.char["祖尔格拉布_coins"] = v
				end,
				validate = { "需求", "贪婪", "放弃" },
			},
			gems = {
				name = "宝石需求类型",
				desc = "祖尔格拉布宝石需求类型",
				type = "text",
				order = 3,
				get = function()
					return self.db.char["祖尔格拉布_gems"] or "需求"
				end,
				set = function(v)
					self.db.char["祖尔格拉布_gems"] = v
				end,
				validate = { "需求", "贪婪", "放弃" },
			},
		},
	},
	["安其拉废墟/神殿"] = {
		type = "group",
		name = "安其拉废墟/神殿",
		desc = "安其拉废墟/神殿自动需求设置",
		order = 40,
		args = {
			enable = {
				name = "开启",
				desc = "开启安其拉废墟/神殿自动需求",
				type = "toggle",
				order = 1,
				get = function()
					return self.db.char["安其拉废墟_enable"]
				end,
				set = function(v)
					self.db.char["安其拉废墟_enable"] = v
				end,
			},
			beetle = {
				name = "甲虫需求类型",
				desc = "安其拉废墟甲虫需求类型",
				type = "text",
				order = 2,
				get = function()
					return self.db.char["安其拉废墟_beetle"] or "需求"
				end,
				set = function(v)
					self.db.char["安其拉废墟_beetle"] = v
				end,
				validate = { "需求", "贪婪", "放弃" },
			},
			idol = {
				name = "雕像需求类型",
				desc = "安其拉废墟雕像需求类型",
				type = "text",
				order = 3,
				get = function()
					return self.db.char["安其拉废墟_idol"] or "需求"
				end,
				set = function(v)
					self.db.char["安其拉废墟_idol"] = v
				end,
				validate = { "需求", "贪婪", "放弃" },
			},
			-- 新增：虫子坐骑选项
			mount = {
				name = "虫子坐骑需求类型",
				desc = "安其拉虫子坐骑需求类型（黄色/绿色/蓝色其拉作战坦克，红色除外）",
				type = "text",
				order = 4,
				get = function()
					return self.db.char["安其拉废墟_mount"] or "需求"
				end,
				set = function(v)
					self.db.char["安其拉废墟_mount"] = v
				end,
				validate = { "需求", "贪婪", "放弃" },
			},
		},
	},
	["熔火之心"] = {
		type = "group",
		name = "熔火之心",
		desc = "熔火之心自动需求设置",
		order = 50,
		args = {
			enable = {
				name = "开启",
				desc = "开启熔火之心自动需求",
				type = "toggle",
				order = 1,
				get = function()
					return self.db.char["熔火之心_enable"]
				end,
				set = function(v)
					self.db.char["熔火之心_enable"] = v
				end,
			},
			lavacore = {
				name = "熔岩之核需求类型",
				desc = "熔火之心熔岩之核需求类型",
				type = "text",
				order = 2,
				get = function()
					return self.db.char["熔火之心_lavacore"] or "需求"
				end,
				set = function(v)
					self.db.char["熔火之心_lavacore"] = v
				end,
				validate = { "需求", "贪婪", "放弃" },
			},
			fierycore = {
				name = "炽热之核需求类型",
				desc = "熔火之心炽热之核需求类型",
				type = "text",
				order = 3,
				get = function()
					return self.db.char["熔火之心_fierycore"] or "需求"
				end,
				set = function(v)
					self.db.char["熔火之心_fierycore"] = v
				end,
				validate = { "需求", "贪婪", "放弃" },
			},
			earthessence = {
				name = "大地精华需求类型",
				desc = "熔火之心大地精华需求类型",
				type = "text",
				order = 4,
				get = function()
					return self.db.char["熔火之心_earthessence"] or "需求"
				end,
				set = function(v)
					self.db.char["熔火之心_earthessence"] = v
				end,
				validate = { "需求", "贪婪", "放弃" },
			},
			fireessence = {
				name = "火焰精华需求类型",
				desc = "熔火之心火焰精华需求类型",
				type = "text",
				order = 5,
				get = function()
					return self.db.char["熔火之心_fireessence"] or "需求"
				end,
				set = function(v)
					self.db.char["熔火之心_fireessence"] = v
				end,
				validate = { "需求", "贪婪", "放弃" },
			},
			sulfuron = {
				name = "萨弗隆铁锭需求类型",
				desc = "熔火之心萨弗隆铁锭需求类型",
				type = "text",
				order = 6,
				get = function()
					return self.db.char["熔火之心_sulfuron"] or "需求"
				end,
				set = function(v)
					self.db.char["熔火之心_sulfuron"] = v
				end,
				validate = { "需求", "贪婪", "放弃" },
			},
		},
	},
	["纳克萨玛斯"] = {
		type = "group",
		name = "纳克萨玛斯",
		desc = "纳克萨玛斯自动需求设置",
		order = 60,
		args = {
			enable = {
				name = "开启",
				desc = "开启纳克萨玛斯自动需求",
				type = "toggle",
				order = 1,
				get = function()
					return self.db.char["纳克萨玛斯_enable"]
				end,
				set = function(v)
					self.db.char["纳克萨玛斯_enable"] = v
				end,
			},
			cloth = {
				name = "布衣碎片需求类型",
				desc = "纳克萨玛斯布衣碎片需求类型",
				type = "text",
				order = 2,
				get = function()
					return self.db.char["纳克萨玛斯_cloth"] or "需求"
				end,
				set = function(v)
					self.db.char["纳克萨玛斯_cloth"] = v
				end,
				validate = { "需求", "贪婪", "放弃" },
			},
			leather = {
				name = "皮甲碎片需求类型",
				desc = "纳克萨玛斯皮甲碎片需求类型",
				type = "text",
				order = 3,
				get = function()
					return self.db.char["纳克萨玛斯_leather"] or "需求"
				end,
				set = function(v)
					self.db.char["纳克萨玛斯_leather"] = v
				end,
				validate = { "需求", "贪婪", "放弃" },
			},
			mail = {
				name = "锁甲碎片需求类型",
				desc = "纳克萨玛斯锁甲碎片需求类型",
				type = "text",
				order = 4,
				get = function()
					return self.db.char["纳克萨玛斯_mail"] or "需求"
				end,
				set = function(v)
					self.db.char["纳克萨玛斯_mail"] = v
				end,
				validate = { "需求", "贪婪", "放弃" },
			},
			plate = {
				name = "板甲碎片需求类型",
				desc = "纳克萨玛斯板甲碎片需求类型",
				type = "text",
				order = 5,
				get = function()
					return self.db.char["纳克萨玛斯_plate"] or "需求"
				end,
				set = function(v)
					self.db.char["纳克萨玛斯_plate"] = v
				end,
				validate = { "需求", "贪婪", "放弃" },
			},
			frozenrune = {
				name = "冰冻符文需求类型",
				desc = "纳克萨玛斯冰冻符文需求类型",
				type = "text",
				order = 6,
				get = function()
					return self.db.char["纳克萨玛斯_frozenrune"] or "需求"
				end,
				set = function(v)
					self.db.char["纳克萨玛斯_frozenrune"] = v
				end,
				validate = { "需求", "贪婪", "放弃" },
			},
		},
	},
}

------------------------------
--      Initialization      --
------------------------------

local default = {
	["杂项"] = {
		{ itemID = 4500, rolltype = "item_4500" }, -- 旅行者背包
		{ itemID = 51217, rolltype = "item_51217" }, --幻化币
		{ itemID = 12843, rolltype = "item_12843" }, --堕落者的天灾石
		{ itemID = 61197, rolltype = "item_61197" }, --褪色的梦境碎片
		{ itemID = 61198, rolltype = "item_61198" }, --小型梦境碎片
		{ itemID = 61199, rolltype = "item_61199" }, --明亮梦境碎片
		{ itemID = 20381, rolltype = "item_20381" }, --梦幻龙鳞
		{ itemID = 12662, rolltype = "item_12662" }, --恶魔符文
		{ itemID = 50203, rolltype = "item_50203" }, --腐化之沙
		{ itemID = 7082, rolltype = "item_7082" }, --空气精华
	},
	["卡拉赞"] = {
		{ itemID = 61673, rolltype = "arcane" }, --奥术精华
		{ itemID = 61674, rolltype = "overloaded" }, --过载魔法能量
	},
	--ZGLoot-data
	["祖尔格拉布"] = {
		-- 硬币
		{ itemID = 19698, rolltype = "coins" },
		{ itemID = 19699, rolltype = "coins" },
		{ itemID = 19700, rolltype = "coins" },
		{ itemID = 19701, rolltype = "coins" },
		{ itemID = 19702, rolltype = "coins" },
		{ itemID = 19703, rolltype = "coins" },
		{ itemID = 19704, rolltype = "coins" },
		{ itemID = 19705, rolltype = "coins" },
		{ itemID = 19706, rolltype = "coins" },
		-- 宝石
		{ itemID = 19707, rolltype = "gems" },
		{ itemID = 19708, rolltype = "gems" },
		{ itemID = 19709, rolltype = "gems" },
		{ itemID = 19710, rolltype = "gems" },
		{ itemID = 19711, rolltype = "gems" },
		{ itemID = 19712, rolltype = "gems" },
		{ itemID = 19713, rolltype = "gems" },
		{ itemID = 19714, rolltype = "gems" },
		{ itemID = 19715, rolltype = "gems" },
	},
	--ZGLoot-data
	["安其拉废墟/神殿"] = {
		-- 甲虫
		{ itemID = 20858, rolltype = "beetle" },
		{ itemID = 20859, rolltype = "beetle" },
		{ itemID = 20860, rolltype = "beetle" },
		{ itemID = 20861, rolltype = "beetle" },
		{ itemID = 20862, rolltype = "beetle" },
		{ itemID = 20863, rolltype = "beetle" },
		{ itemID = 20864, rolltype = "beetle" },
		{ itemID = 20865, rolltype = "beetle" },
		-- 雕像 - 已取消职业限制
		{ itemID = 20866, rolltype = "idol" },
		{ itemID = 20868, rolltype = "idol" },
		{ itemID = 20869, rolltype = "idol" },
		{ itemID = 20870, rolltype = "idol" },
		{ itemID = 20871, rolltype = "idol" },
		{ itemID = 20872, rolltype = "idol" },
		{ itemID = 20873, rolltype = "idol" },
		{ itemID = 20867, rolltype = "idol" },
		{ itemID = 20879, rolltype = "idol" },
		{ itemID = 20877, rolltype = "idol" },
		{ itemID = 20881, rolltype = "idol" },
		{ itemID = 20882, rolltype = "idol" },
		{ itemID = 20878, rolltype = "idol" },
		{ itemID = 20876, rolltype = "idol" },
		{ itemID = 20875, rolltype = "idol" },
		{ itemID = 20874, rolltype = "idol" },
		-- 新增：虫子坐骑
		{ itemID = 21218, rolltype = "mount" }, -- 蓝色其拉作战坦克
		{ itemID = 21324, rolltype = "mount" }, -- 黄色其拉作战坦克
		{ itemID = 21323, rolltype = "mount" }, -- 绿色其拉作战坦克
	},
	--ZGLoot-data
	["熔火之心"] = {
		{ itemID = 17011, rolltype = "lavacore" }, --熔岩之核
		{ itemID = 17010, rolltype = "fierycore" }, --炽热之核
		{ itemID = 7076, rolltype = "earthessence" }, --大地精华
		{ itemID = 7078, rolltype = "fireessence" }, --火焰精华
		{ itemID = 17203, rolltype = "sulfuron" }, --萨弗隆铁锭
	},
	["纳克萨玛斯"] = {
		{ itemID = 22376, rolltype = "cloth" }, -- 布衣碎片
		{ itemID = 22373, rolltype = "leather" }, -- 皮甲碎片
		{ itemID = 22374, rolltype = "mail" }, -- 锁甲碎片
		{ itemID = 22375, rolltype = "plate" }, -- 板甲碎片
		{ itemID = 22682, rolltype = "frozenrune" }, -- 冰冻符文
	},
}

local _, enclass = UnitClass("player")

function Automaton_AutoNeed:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("AutoNeed")
	Automaton:RegisterDefaults("AutoNeed", "profile", {
		disabled = true,
		rolltype = "贪婪",
		-- 杂项
		["杂项_enable"] = false,
		["item_4500"] = "需求",
		["item_51217"] = "需求",
		["item_12843"] = "需求",
		["item_61197"] = "需求",
		["item_61198"] = "需求",
		["item_61199"] = "需求",
		["item_20381"] = "需求",
		["item_12662"] = "需求",
		["item_50203"] = "需求",
		["item_7082"] = "需求",
		-- 卡拉赞
		["卡拉赞_enable"] = false,
		["卡拉赞_arcane"] = "需求",
		["卡拉赞_overloaded"] = "需求",
		-- 祖尔格拉布
		["祖尔格拉布_enable"] = false,
		["祖尔格拉布_coins"] = "需求",
		["祖尔格拉布_gems"] = "需求",
		-- 安其拉废墟/神殿
		["安其拉废墟_enable"] = false,
		["安其拉废墟_beetle"] = "需求",
		["安其拉废墟_idol"] = "需求",
		["安其拉废墟_mount"] = "需求",
		-- 熔火之心
		["熔火之心_enable"] = false,
		["熔火之心_lavacore"] = "需求",
		["熔火之心_fierycore"] = "需求",
		["熔火之心_earthessence"] = "需求",
		["熔火之心_fireessence"] = "需求",
		["熔火之心_sulfuron"] = "需求",
		-- 纳克萨玛斯
		["纳克萨玛斯_enable"] = false,
		["纳克萨玛斯_cloth"] = "需求",
		["纳克萨玛斯_leather"] = "需求",
		["纳克萨玛斯_mail"] = "需求",
		["纳克萨玛斯_plate"] = "需求",
		["纳克萨玛斯_frozenrune"] = "需求",
		-- 按品质自动需求（蓝/绿/紫，统一模组开关）
		["品质_enable"] = false,
		["蓝装_rolltype"] = "贪婪",
		["绿装_rolltype"] = "贪婪",
		["紫装_rolltype"] = "贪婪",
	})
	Automaton:SetDisabledAsDefault(self, "AutoNeed")
	self:RegisterOptions(self.options)

	-- 确保 autoneedsDB 字段存在
	if not self.db.char.autoneedsDB then
		self.db.char.autoneedsDB = {}
	end

	-- ========== 新增：将 profile 默认值合并到 char ==========
	local defaultProfile = self.db.profile -- 此时 profile 已有默认值
	for key, value in pairs(defaultProfile) do
		-- 排除不需要合并的键（如 autoneedsDB、disabled 等）
		if key ~= "autoneedsDB" and key ~= "disabled" and key ~= "ver" then
			if self.db.char[key] == nil then
				self.db.char[key] = value
			end
		end
	end
	-- ====================================================

	-- 兼容旧版：原 蓝装_enable / 绿装_enable 任一开启则迁移到统一模组开关
	if self.db.char["蓝装_enable"] or self.db.char["绿装_enable"] then
		self.db.char["品质_enable"] = true
	end
end

function Automaton_AutoNeed:OnEnable()
	self:RegisterEvent("START_LOOT_ROLL")
end

function Automaton_AutoNeed:OnDisable()
	self:UnhookAll()
	self:UnregisterAllEvents()
end

local function PrintLog(msg, itemid)
	local itemname = GetItemInfo(itemid)
	local name = ""
	if itemname then
		name = format("物品名称：[%s]", itemname)
	end
	print("|cffffff00" .. msg .. format("物品ID: %s %s", itemid, name) .. "|r", "automaton")
end

function Automaton_AutoNeed:PrintAll()
	local autoneedsDB = self.db.char.autoneedsDB or {}
	if not next(autoneedsDB) then
		print("|cffffff00自定义物品列表为空！|r", "automaton")
		return
	end

	for i, v in pairs(autoneedsDB) do
		PrintLog("序号：" .. i, v.itemID)
	end
end

function Automaton_AutoNeed:AddItem(itemid)
	local id = tonumber(itemid)
	if id then
		-- 确保 autoneedsDB 存在
		self.db.char.autoneedsDB = self.db.char.autoneedsDB or {}

		for i, k in pairs(self.db.char.autoneedsDB) do
			if k.itemID == id then
				PrintLog("已存在", id)
				return
			end
		end
		PrintLog("成功添加", id)
		table.insert(self.db.char.autoneedsDB, { itemID = id, rolltype = needvaule[self.db.char.rolltype] })
	end
end

function Automaton_AutoNeed:DelItem(itemid)
	local id = tonumber(itemid)
	if id then
		-- 确保 autoneedsDB 存在
		self.db.char.autoneedsDB = self.db.char.autoneedsDB or {}

		local index
		for i, k in pairs(self.db.char.autoneedsDB) do
			if k.itemID == id then
				index = i
				break
			end
		end
		if index then
			table.remove(self.db.char.autoneedsDB, index)
			PrintLog("成功删除", id)
		end
	end
end

function Automaton_AutoNeed:CheckItem(itemid)
	-- 确保itemid是数字
	itemid = tonumber(itemid)
	if not itemid then
		return nil
	end

	-- 检查自定义物品列表
	local autoneedsDB = self.db.char.autoneedsDB or {}
	for i, v in ipairs(autoneedsDB) do
		if v.itemID == itemid then
			return v.rolltype or needvaule[self.db.char.rolltype] or 2 -- 默认为贪婪
		end
	end

	-- 检查各个分类
	for category, items in pairs(default) do
		-- 确定该分类的开关字段名称
		local enableKey
		if category == "杂项" then
			enableKey = "杂项_enable"
		elseif category == "卡拉赞" then
			enableKey = "卡拉赞_enable"
		elseif category == "祖尔格拉布" then
			enableKey = "祖尔格拉布_enable"
		elseif category == "安其拉废墟/神殿" then
			enableKey = "安其拉废墟_enable"
		elseif category == "熔火之心" then
			enableKey = "熔火之心_enable"
		elseif category == "纳克萨玛斯" then
			enableKey = "纳克萨玛斯_enable"
		else
			enableKey = category .. "_enable"
		end

		-- 如果该分类开启
		if self.db.char[enableKey] then
			for _, v in ipairs(items) do
				if v.itemID == itemid then
					-- 根据分类和rolltype获取设置
					local settingKey
					if category == "杂项" then
						-- 杂项物品使用rolltype直接作为设置键
						settingKey = v.rolltype
					else
						-- 其他分类需要构建设置键
						if category == "安其拉废墟/神殿" then
							settingKey = "安其拉废墟_" .. v.rolltype
						else
							settingKey = category .. "_" .. v.rolltype
						end
					end

					local setting = self.db.char[settingKey]
					if setting then
						return needvaule[setting] or 1
					else
						-- 未单独设置时，使用全局默认 rolltype
						local global = self.db.char.rolltype
						return needvaule[global] or 2 -- 默认贪婪（2）
					end
				end
			end
		end
	end

	-- ========== 按品质自动需求：蓝/绿/紫通用装备（统一模组开关） ==========
	-- 仅在未命中任何具体分类时生效，避免覆盖特定副本分类
	if self.db.char["品质_enable"] then
		local quality, equipLoc = GetItemQualityAndEquipLoc(itemid)
		if equipLoc and equipLoc ~= "" then
			if quality == 4 then
				local s = self.db.char["紫装_rolltype"]
				return needvaule[s] or 2
			elseif quality == 3 then
				local s = self.db.char["蓝装_rolltype"]
				return needvaule[s] or 2
			elseif quality == 2 then
				local s = self.db.char["绿装_rolltype"]
				return needvaule[s] or 2
			end
		end
	end
	-- =====================================================

	return nil -- 没有匹配项
end

function Automaton_AutoNeed:START_LOOT_ROLL(id)
	-- 使用pcall安全调用，捕获并忽略错误
	local success, result = pcall(function()
		local link = GetLootRollItemLink(id)
		local itemID = link and string.match(link, "item:(%d+):")
		if itemID then
			itemID = tonumber(itemID)
			local rolltype = self:CheckItem(itemID)
			if rolltype then
				RollOnLoot(id, rolltype)
				if rolltype == 1 or rolltype == 2 then
					C_Timer.After(0.01, function()
						-- 确保当前弹窗是掷骰确认框
						if StaticPopup1 and StaticPopup1:IsVisible() and StaticPopup1.which == "CONFIRM_LOOT_ROLL" then
							StaticPopup1Button1:Click()
						end
					end)
				end
			end
		end
	end)

	-- 可选：记录错误但不显示给用户
	if not success then
		-- 可以在这里记录错误日志，但不在UI中显示
		-- self:DebugPrint("AutoNeed错误: " .. tostring(result))
	end
end

------------------------------
--      Event Handlers      --
------------------------------
