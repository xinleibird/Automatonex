assert(Automaton, "Automaton not found!")

local Automaton_zTip = Automaton:NewModule("zTip")
Automaton_zTip.modulename = "鼠标提示增强"
Automaton_zTip.moduledesc =
	"鼠标提示增强，显示更多信息（职业图标、军衔、采集等级、抗性等）"

-- 采集数据（保持不变）
local gatheringData = {
	-- 草药
	["宁神花"] = 1,
	["银叶草"] = 1,
	["地根草"] = 15,
	["魔皇草"] = 50,
	["石南草"] = 70,
	["荆棘藻"] = 85,
	["跌打草"] = 100,
	["野钢花"] = 115,
	["墓地苔"] = 120,
	["皇血草"] = 125,
	["活根草"] = 150,
	["枯叶草"] = 160,
	["金棘草"] = 170,
	["卡德加的胡须"] = 185,
	["冬针草"] = 195,
	["火焰花"] = 205,
	["紫莲花"] = 210,
	["太阳草"] = 230,
	["盲目草"] = 235,
	["幽灵菇"] = 245,
	["格罗姆之血"] = 250,
	["阿尔萨斯之泪"] = 255,
	["黄金参"] = 260,
	["梦叶草"] = 270,
	["山鼠草"] = 280,
	["瘟疫花"] = 285,
	["冰盖草"] = 290,
	["黑莲花"] = 300,
	-- 矿物
	["铜矿"] = 1,
	["锡矿"] = 65,
	["银矿"] = 75,
	["铁矿"] = 125,
	["铁矿石"] = 125,
	["金矿"] = 155,
	["金矿石"] = 155,
	["秘银矿脉"] = 175,
	["真银矿脉"] = 230,
	["真银矿石"] = 230,
	["瑟银矿脉"] = 245,
	["黑铁矿脉"] = 230,
	["富瑟银矿"] = 275,
	["宝石矿脉"] = 310,
	["软泥覆盖的瑟银矿脉"] = 245,
	["软泥覆盖的富瑟银矿脉"] = 275,
	["软泥覆盖的真银矿脉"] = 230,
	["软泥覆盖的秘银矿脉"] = 175,
	["普通树"] = 5,
	["亮木树"] = 125,
	["影木树"] = 175,
	["热带树"] = 225,
	["枯木树"] = 250,
	["星木树"] = 270,
}

-- 本地化（保持不变）
local locRare, locTargeting, locYOU, locSelf, locNotSpecified, locSpecified
local tmp = GetLocale()
if tmp == "zhCN" then
	locRare = "稀有"
	locTargeting = "目标"
	locYOU = ">> 你 <<"
	locSelf = "自己"
	locNotSpecified = "未指定"
	locSpecified = "变异生物"
elseif tmp == "zhTW" then
	locRare = "稀有"
	locTargeting = "目標"
	locYOU = ">> 你 <<"
	locSelf = "自己"
	locNotSpecified = "未指定"
	locSpecified = "變異生物"
else
	locRare = "Rare"
	locTargeting = "Targeting"
	locYOU = ">> U <<"
	locSelf = "Self"
	locNotSpecified = "Not specified"
	locSpecified = "Freak"
end

-- 模块内部变量（将由配置动态更新）
local zAnchor = 3 -- 偏移模式：0禁用，1-5对应不同模式
local zOffsetX = 50 -- X偏移
local zOffsetY = 50 -- Y偏移
local zOrigPosX = 100 -- 系统默认位置X偏移
local zOrigPosY = 150 -- 系统默认位置Y偏移
local zScale = 1 -- 缩放比例
local zScaleEnabled = false -- 是否启用缩放
local zGuildColorAlpha = 0.86 -- 公会明暗度
local zGuildColorAlphaEnabled = false -- 是否启用公会明暗度
local zFade = false -- 是否渐隐
local zDisplayPvPRank = 3 -- 军衔显示：0不显示，1文字，2图标，3两者
local zClassIcon = true -- 是否显示职业图标
local zShowIsPlayer = true -- 等级行显示“玩家”字样
local zDisplayFaction = true -- 显示NPC声望等级
local zTargetOfMouse = true -- 显示对象的目标
local zShowBar = true -- 显示生命/法力条
local zShowBarText = true -- 显示生命/法力条数值
local zShowGatheringLevel = true -- 显示采集等级

-- 新增配置项
local zShowItemID = true -- 显示物品ID
local zShowSpellID = false -- 显示法术ID
local zShowDamageAndSpeed = false -- 显示目标伤害和攻速
local zShowImpression = false -- 显示玩家印象
local zShowPetHappiness = true -- 显示自己宠物快乐度
local zShowPetFood = true -- 显示自己宠物食物需求
local zShowPetExp = true -- 显示自己宠物经验（60级不显示）

-- 3D模型配置（新增）
local zShow3DModel = false -- 是否启用3D模型
local zModelSize = 120 -- 模型大小（像素）
local zModelPosition = 0 -- 模型位置：0=顶部，1=底部，2=左侧，3=右侧
local zModelOffsetX = 10 -- X偏移
local zModelOffsetY = 10 -- Y偏移
local zModelRotation = true -- 是否允许鼠标旋转
local zModelEdge = true -- 是否边缘修正

-- 保存原始函数指针（改为模块成员，避免钩子捕获）
Automaton_zTip.orig_GameTooltip_UnitColor = nil
Automaton_zTip.orig_UnitFrame_OnEnter = nil
Automaton_zTip.orig_UnitFrame_OnLeave = nil
Automaton_zTip.orig_GameTooltip_SetDefaultAnchor = nil
Automaton_zTip.orig_GameTooltip_OnShow = nil
Automaton_zTip.orig_HealthBar_OnValueChanged = nil

-- 物品/法术相关原始函数（作为模块成员）
Automaton_zTip.orig_SetHyperlink = nil
Automaton_zTip.orig_SetBagItem = nil
Automaton_zTip.orig_SetQuestLogItem = nil
Automaton_zTip.orig_SetQuestItem = nil
Automaton_zTip.orig_SetLootItem = nil
Automaton_zTip.orig_SetInventoryItem = nil
Automaton_zTip.orig_SetPlayerBuff = nil
Automaton_zTip.orig_SetPlayerDebuff = nil
Automaton_zTip.orig_SetUnitBuff = nil
Automaton_zTip.orig_SetUnitDebuff = nil

-- 模块帧，用于处理事件和更新
local moduleFrame

-- 纹理/图标
local z_ClassIcon, RankIcon

-- 目标行相关
local targetlinenum
local ShowChallenges_timer = 0
local mouseTarget
local zTargetLineAdded = false -- 防止重复添加目标行
local zIsOnUnitFrame = nil -- 标记是否在单位框体上

-- 3D模型相关（模块成员，在OnInitialize中初始化）
Automaton_zTip.modelFrame = nil
Automaton_zTip.modelRotationEnabled = false
Automaton_zTip.modelRotationSpeed = 0
Automaton_zTip.modelLastUpdate = 0

-- ==================== 分类选项表 ====================
Automaton_zTip.options = {
	["位置与偏移"] = {
		type = "group",
		name = "位置与偏移",
		desc = "鼠标提示框的位置与偏移设置",
		order = 1,
		args = {
			zAnchor = {
				type = "range",
				name = "偏移模式",
				desc = "0=禁用偏移，1=人物跟随鼠标（非人物用默认位置），2=屏幕上方，3=全部跟随鼠标，4=屏幕上方+非人物对象右上，5=全部跟随鼠标并向上延展",
				min = 0,
				max = 5,
				step = 1,
				order = 1,
				get = function()
					return Automaton_zTip.db.profile.zAnchor
				end,
				set = function(v)
					Automaton_zTip.db.profile.zAnchor = v
					Automaton_zTip:UpdateConfig()
					if v == 0 then
						GameTooltip_SetDefaultAnchor = Automaton_zTip.orig_GameTooltip_SetDefaultAnchor
					else
						GameTooltip_SetDefaultAnchor = function(t, p)
							Automaton_zTip:SetDefaultAnchor(t, p)
						end
					end
				end,
			},
			zOffsetX = {
				type = "range",
				name = "X偏移量",
				desc = "水平偏移（像素）",
				min = -200,
				max = 200,
				step = 1,
				order = 2,
				get = function()
					return Automaton_zTip.db.profile.zOffsetX
				end,
				set = function(v)
					Automaton_zTip.db.profile.zOffsetX = v
					Automaton_zTip:UpdateConfig()
				end,
			},
			zOffsetY = {
				type = "range",
				name = "Y偏移量",
				desc = "垂直偏移（像素）",
				min = -200,
				max = 200,
				step = 1,
				order = 3,
				get = function()
					return Automaton_zTip.db.profile.zOffsetY
				end,
				set = function(v)
					Automaton_zTip.db.profile.zOffsetY = v
					Automaton_zTip:UpdateConfig()
				end,
			},
		},
	},
	["缩放与外观"] = {
		type = "group",
		name = "缩放与外观",
		desc = "鼠标提示框的缩放与外观设置",
		order = 2,
		args = {
			zScale = {
				type = "range",
				name = "缩放比例",
				desc = "提示框缩放比例 (0.1-2.0)",
				min = 0.1,
				max = 2.0,
				step = 0.1,
				order = 1,
				get = function()
					return Automaton_zTip.db.profile.zScale
				end,
				set = function(v)
					Automaton_zTip.db.profile.zScale = v
					Automaton_zTip:UpdateConfig()
				end,
			},
			zScaleEnabled = {
				type = "toggle",
				name = "启用缩放",
				order = 2,
				get = function()
					return Automaton_zTip.db.profile.zScaleEnabled
				end,
				set = function(v)
					Automaton_zTip.db.profile.zScaleEnabled = v
					Automaton_zTip:UpdateConfig()
				end,
			},
			zGuildColorAlpha = {
				type = "range",
				name = "公会明暗度",
				desc = "公会名称的透明度/亮度",
				min = 0,
				max = 1,
				step = 0.01,
				order = 3,
				get = function()
					return Automaton_zTip.db.profile.zGuildColorAlpha
				end,
				set = function(v)
					Automaton_zTip.db.profile.zGuildColorAlpha = v
					Automaton_zTip:UpdateConfig()
				end,
			},
			zGuildColorAlphaEnabled = {
				type = "toggle",
				name = "启用公会明暗度",
				order = 4,
				get = function()
					return Automaton_zTip.db.profile.zGuildColorAlphaEnabled
				end,
				set = function(v)
					Automaton_zTip.db.profile.zGuildColorAlphaEnabled = v
					Automaton_zTip:UpdateConfig()
				end,
			},
			zFade = {
				type = "toggle",
				name = "渐隐",
				desc = "鼠标离开时提示是否渐隐",
				order = 5,
				get = function()
					return Automaton_zTip.db.profile.zFade
				end,
				set = function(v)
					Automaton_zTip.db.profile.zFade = v
					Automaton_zTip:UpdateConfig()
				end,
			},
		},
	},
	separator_display = {
		type = "header",
		name = "显示内容",
		order = 10,
	},
	["单位信息"] = {
		type = "group",
		name = "单位信息",
		desc = "鼠标悬停单位时提示框中显示的信息",
		order = 20,
		args = {
			zDisplayPvPRank = {
				type = "range",
				name = "军衔显示",
				desc = "0=不显示，1=文字，2=图标，3=两者",
				min = 0,
				max = 3,
				step = 1,
				order = 1,
				get = function()
					return Automaton_zTip.db.profile.zDisplayPvPRank
				end,
				set = function(v)
					Automaton_zTip.db.profile.zDisplayPvPRank = v
					Automaton_zTip:UpdateConfig()
				end,
			},
			zClassIcon = {
				type = "toggle",
				name = "职业图标",
				order = 2,
				get = function()
					return Automaton_zTip.db.profile.zClassIcon
				end,
				set = function(v)
					Automaton_zTip.db.profile.zClassIcon = v
					Automaton_zTip:UpdateConfig()
				end,
			},
			zShowIsPlayer = {
				type = "toggle",
				name = "显示'玩家'字样",
				order = 3,
				get = function()
					return Automaton_zTip.db.profile.zShowIsPlayer
				end,
				set = function(v)
					Automaton_zTip.db.profile.zShowIsPlayer = v
					Automaton_zTip:UpdateConfig()
				end,
			},
			zDisplayFaction = {
				type = "toggle",
				name = "显示NPC声望",
				order = 4,
				get = function()
					return Automaton_zTip.db.profile.zDisplayFaction
				end,
				set = function(v)
					Automaton_zTip.db.profile.zDisplayFaction = v
					Automaton_zTip:UpdateConfig()
				end,
			},
			zTargetOfMouse = {
				type = "toggle",
				name = "显示对象的目标",
				order = 5,
				get = function()
					return Automaton_zTip.db.profile.zTargetOfMouse
				end,
				set = function(v)
					Automaton_zTip.db.profile.zTargetOfMouse = v
					Automaton_zTip:UpdateConfig()
				end,
			},
			zShowBar = {
				type = "toggle",
				name = "显示法力条",
				order = 6,
				get = function()
					return Automaton_zTip.db.profile.zShowBar
				end,
				set = function(v)
					Automaton_zTip.db.profile.zShowBar = v
					Automaton_zTip:UpdateConfig()
				end,
			},
			zShowBarText = {
				type = "toggle",
				name = "显示生命/法力数值",
				order = 7,
				get = function()
					return Automaton_zTip.db.profile.zShowBarText
				end,
				set = function(v)
					Automaton_zTip.db.profile.zShowBarText = v
					Automaton_zTip:UpdateConfig()
				end,
			},
			zShowGatheringLevel = {
				type = "toggle",
				name = "显示采集等级",
				order = 8,
				get = function()
					return Automaton_zTip.db.profile.zShowGatheringLevel
				end,
				set = function(v)
					Automaton_zTip.db.profile.zShowGatheringLevel = v
					Automaton_zTip:UpdateConfig()
				end,
			},
		},
	},
	["扩展信息"] = {
		type = "group",
		name = "扩展信息",
		desc = "物品、法术与目标的扩展信息显示",
		order = 30,
		args = {
			zShowItemID = {
				type = "toggle",
				name = "显示物品ID",
				desc = "在物品提示中显示物品ID",
				order = 1,
				get = function()
					return Automaton_zTip.db.profile.zShowItemID
				end,
				set = function(v)
					Automaton_zTip.db.profile.zShowItemID = v
					Automaton_zTip:UpdateConfig()
				end,
			},
			zShowSpellID = {
				type = "toggle",
				name = "显示法术ID",
				desc = "在法术、Buff、Debuff提示中显示法术ID，需Superwow模组",
				order = 2,
				get = function()
					return Automaton_zTip.db.profile.zShowSpellID
				end,
				set = function(v)
					Automaton_zTip.db.profile.zShowSpellID = v
					Automaton_zTip:UpdateConfig()
				end,
			},
			zShowDamageAndSpeed = {
				type = "toggle",
				name = "显示目标伤害和攻速",
				desc = "在敌对/中立非玩家单位提示中显示伤害范围和攻击速度",
				order = 3,
				get = function()
					return Automaton_zTip.db.profile.zShowDamageAndSpeed
				end,
				set = function(v)
					Automaton_zTip.db.profile.zShowDamageAndSpeed = v
					Automaton_zTip:UpdateConfig()
				end,
			},
			zShowImpression = {
				type = "toggle",
				name = "显示玩家印象",
				desc = "在玩家提示中显示印象信息（需 SpiritSenseRec灵应录支持）",
				order = 4,
				get = function()
					return Automaton_zTip.db.profile.zShowImpression
				end,
				set = function(v)
					Automaton_zTip.db.profile.zShowImpression = v
					Automaton_zTip:UpdateConfig()
				end,
			},
			zShowPetHappiness = {
				type = "toggle",
				name = "宠物快乐度",
				desc = "鼠标提示显示自己宠物的快乐度（不高兴/满足/快乐 及对应伤害加成）",
				order = 5,
				get = function()
					return Automaton_zTip.db.profile.zShowPetHappiness
				end,
				set = function(v)
					Automaton_zTip.db.profile.zShowPetHappiness = v
					Automaton_zTip:UpdateConfig()
				end,
			},
			zShowPetFood = {
				type = "toggle",
				name = "宠物食物需求",
				desc = "鼠标提示显示自己宠物能吃的食物类型",
				order = 6,
				get = function()
					return Automaton_zTip.db.profile.zShowPetFood
				end,
				set = function(v)
					Automaton_zTip.db.profile.zShowPetFood = v
					Automaton_zTip:UpdateConfig()
				end,
			},
			zShowPetExp = {
				type = "toggle",
				name = "宠物经验",
				desc = "鼠标提示显示自己宠物的当前经验（宠物满级60级时不显示）",
				order = 7,
				get = function()
					return Automaton_zTip.db.profile.zShowPetExp
				end,
				set = function(v)
					Automaton_zTip.db.profile.zShowPetExp = v
					Automaton_zTip:UpdateConfig()
				end,
			},
		},
	},
	["3D模型"] = {
		type = "group",
		name = "3D模型",
		desc = "玩家提示框中3D模型的显示设置",
		order = 40,
		args = {
			zShow3DModel = {
				type = "toggle",
				name = "显示3D模型",
				desc = "在玩家提示中显示3D模型",
				order = 1,
				get = function()
					return Automaton_zTip.db.profile.zShow3DModel
				end,
				set = function(v)
					Automaton_zTip.db.profile.zShow3DModel = v
					Automaton_zTip:UpdateConfig()
				end,
			},
			zModelSize = {
				type = "range",
				name = "模型大小",
				desc = "3D模型的宽度/高度（像素）",
				min = 50,
				max = 300,
				step = 1,
				order = 2,
				get = function()
					return Automaton_zTip.db.profile.zModelSize
				end,
				set = function(v)
					Automaton_zTip.db.profile.zModelSize = v
					Automaton_zTip:UpdateConfig()
				end,
			},
			zModelPosition = {
				type = "range",
				name = "模型位置",
				desc = "0=顶部，1=底部，2=左侧，3=右侧",
				min = 0,
				max = 3,
				step = 1,
				order = 3,
				get = function()
					return Automaton_zTip.db.profile.zModelPosition
				end,
				set = function(v)
					Automaton_zTip.db.profile.zModelPosition = v
					Automaton_zTip:UpdateConfig()
				end,
			},
			zModelOffsetX = {
				type = "range",
				name = "模型X偏移",
				desc = "水平偏移（像素）",
				min = -200,
				max = 200,
				step = 1,
				order = 4,
				get = function()
					return Automaton_zTip.db.profile.zModelOffsetX
				end,
				set = function(v)
					Automaton_zTip.db.profile.zModelOffsetX = v
					Automaton_zTip:UpdateConfig()
				end,
			},
			zModelOffsetY = {
				type = "range",
				name = "模型Y偏移",
				desc = "垂直偏移（像素）",
				min = -200,
				max = 200,
				step = 1,
				order = 5,
				get = function()
					return Automaton_zTip.db.profile.zModelOffsetY
				end,
				set = function(v)
					Automaton_zTip.db.profile.zModelOffsetY = v
					Automaton_zTip:UpdateConfig()
				end,
			},
			zModelRotation = {
				type = "toggle",
				name = "允许鼠标旋转",
				desc = "鼠标悬停在模型上时可拖动旋转",
				order = 6,
				get = function()
					return Automaton_zTip.db.profile.zModelRotation
				end,
				set = function(v)
					Automaton_zTip.db.profile.zModelRotation = v
					Automaton_zTip:UpdateConfig()
				end,
			},
			zModelEdge = {
				type = "toggle",
				name = "边缘修正",
				desc = "自动调整模型位置避免超出屏幕",
				order = 7,
				get = function()
					return Automaton_zTip.db.profile.zModelEdge
				end,
				set = function(v)
					Automaton_zTip.db.profile.zModelEdge = v
					Automaton_zTip:UpdateConfig()
				end,
			},
		},
	},
}

-- 工具函数（原样保留）
local function zGetHexColor(color)
	if not color then
		return "FFFFFF"
	end
	return string.format("%2x%2x%2x", color.r * 255, color.g * 255, color.b * 255)
end

local function zGetUnitFaction(unit)
	local id = UnitReaction(unit, "player")
	if not id then
		return ""
	end
	if id > 6 then
		local label
		for i = GameTooltip:NumLines(), 1, -1 do
			label = getglobal("GameTooltipTextLeft" .. i):GetText()
			if label and label ~= PVP_ENABLED then
				break
			end
		end
		local name, standingId, isHeader
		for i = 1, GetNumFactions() do
			name, _, standingId, _, _, _, _, _, isHeader, _, _ = GetFactionInfo(i)
			if isHeader == nil and name == label then
				id = standingId
				break
			end
		end
	end
	local ret = GetText("FACTION_STANDING_LABEL" .. id, UnitSex("player"))
	if id == 5 then
		ret = format("|cff33CC33%s|r", ret)
	elseif id == 6 then
		ret = format("|cff33CCCC%s|r", ret)
	elseif id == 7 then
		ret = format("|cffFF6633%s|r", ret)
	elseif id == 8 then
		ret = format("|cffDD33DD%s|r", ret)
	end
	return ret
end

local function GetDifficultyColor(level)
	-- 从FastQuest复制
	local lDiff = level - UnitLevel("player")
	if lDiff >= 0 then
		for i = 1.00, 0.10, -0.10 do
			local color = { r = 1.00, g = i, b = 0.00 }
			if (i / 0.10) == (10 - lDiff) then
				return color
			end
		end
	elseif -lDiff < GetQuestGreenRange() then
		for i = 0.90, 0.10, -0.10 do
			local color = { r = i, g = 1.00, b = 0.00 }
			if (9 - i / 0.10) == (-1 * lDiff) then
				return color
			end
		end
	elseif -lDiff == GetQuestGreenRange() then
		return { r = 0.50, g = 1.00, b = 0.50 }
	else
		return { r = 0.75, g = 0.75, b = 0.75 }
	end
end

-- 血条染色（直接替换的函数）
local function HealthBar_OnValueChanged_Replacement(value, smooth)
	if not value then
		return
	end
	if this == GameTooltipStatusBar then
		this:SetStatusBarColor(SetPercentColor(UnitHealth("mouseover"), UnitHealthMax("mouseover")))
	end
	-- 调用原始函数（如果存在）
	if Automaton_zTip.orig_HealthBar_OnValueChanged then
		Automaton_zTip.orig_HealthBar_OnValueChanged(value, smooth)
	end
end

-- 鼠标提示格式化核心函数
function Automaton_zTip:FormatUnit(unit)
	-- 修复：如果单位不存在（例如悬停在物品上），直接返回白色，不修改提示内容
	if not UnitExists(unit) then
		return 1, 1, 1
	end

	-- 设置 GameTooltip.unit 以便法力条等能正确获取单位
	GameTooltip.unit = unit

	local r, g, b
	local isplayer = UnitIsPlayer(unit)
	local bdead = UnitHealth(unit) <= 0 and (not isplayer or UnitIsDeadOrGhost(unit))
	local tapped = UnitIsTapped(unit) and (not UnitIsTappedByPlayer(unit))
	local reaction = UnitReaction(unit, "player")

	local tip, text, levelline, tmp, tmp2

	-- 查找等级行并清理PVP字符
	for i = 2, GameTooltip:NumLines() do
		text = getglobal(GameTooltip:GetName() .. "TextLeft" .. i)
		tip = text:GetText()
		if tip then
			if tip == PVP_ENABLED then
				text:SetText()
			elseif string.find(tip, LEVEL) then
				if not levelline then
					levelline = i
				end
			elseif tip == TAMEABLE then
				text:SetText(format("|cff00FF00%s|r", tip))
			elseif tip == NOT_TAMEABLE then
				text:SetText(format("|cffFF6035%s|r", tip))
			end
		end
	end

	-- 重写等级行
	if levelline then
		tmp = UnitLevel(unit)
		if bdead then
			if tmp > 0 then
				tmp2 = format("|cff888888等级 %d %s|r", tmp, CORPSE)
			else
				tmp2 = format("|cff888888等级 ?? %s|r", CORPSE)
			end
		elseif tmp > 0 then
			if UnitCanAttack("player", unit) or UnitCanAttack(unit, "player") then
				tmp2 = format("|cff%s等级 %d|r", zGetHexColor(GetDifficultyColor(tmp)), tmp)
			else
				tmp2 = format("|cff3377CC等级 %d|r", tmp)
			end
		else
			tmp2 = "|cffFF0000等级  ??|r"
		end

		if UnitRace(unit) and isplayer then
			if UnitFactionGroup(unit) == UnitFactionGroup("player") then
				tmp = "00FF33"
			else
				tmp = "FF3300"
			end
			tmp2 = format("%s |cff%s%s|r", tmp2, tmp, UnitRace(unit))
			_, tmp = UnitClass(unit)
			tmp = zGetHexColor(RAID_CLASS_COLORS[(tmp or "")])
			tmp2 = format("%s |cff%s%s|r", tmp2, tmp, UnitClass(unit))
		elseif UnitPlayerControlled(unit) then
			tmp2 = format("%s %s ", tmp2, (UnitCreatureFamily(unit) or UnitCreatureType(unit) or ""))
		elseif UnitCreatureType(unit) then
			if zDisplayFaction and reaction and reaction > 4 then
				tmp2 = format("%s |cffFFFFFF%s|r %s ", tmp2, UnitCreatureType(unit), zGetUnitFaction(unit))
			elseif UnitCreatureType(unit) == locNotSpecified then
				tmp2 = format("%s %s ", tmp2, locSpecified)
			else
				tmp2 = format("%s %s ", tmp2, UnitCreatureType(unit))
			end
		else
			tmp2 = format("%s %s ", tmp2, UKNOWNBEING)
		end
		tip = tmp2

		tmp = nil
		tmp2 = ""
		if isplayer then
			if zShowIsPlayer then
				tmp2 = format("(%s)", PLAYER)
			end
		elseif not UnitPlayerControlled(unit) then
			tmp = UnitClassification(unit)
			if tmp and tmp ~= "normal" and UnitHealth(unit) > 0 then
				if tmp == "elite" then
					tmp2 = format("|cffFFFF33(%s)|r", ELITE)
				elseif tmp == "worldboss" then
					tmp2 = format("|cffFF0000(%s)|r", BOSS)
				elseif tmp == "rare" then
					tmp2 = format("|cffFF66FF(%s)|r", locRare)
				elseif tmp == "rareelite" then
					tmp2 = format("|cffFFAAFF(%s %s)|r", locRare, ELITE)
				else
					tmp2 = format("(%s)", tmp)
				end
			end
		end
		getglobal("GameTooltipTextLeft" .. levelline):SetText(tip .. tmp2)
	end

	-- 第一行：名字处理（职业图标、军衔）
	text = GameTooltipTextLeft1
	tip = text:GetText()
	if isplayer then
		if zClassIcon then
			z_ClassIcon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
			local coord = CLASS_ICON_TCOORDS[select(2, UnitClass(unit))]
			if coord then
				z_ClassIcon:SetTexCoord(unpack(coord))
			end
			z_ClassIcon:Show()
			text1 = "    "
		else
			z_ClassIcon:Hide()
			text1 = ""
		end

		local pvpRank = UnitPVPRank(unit)
		local rankName, rankIndex = GetPVPRankInfo(pvpRank, unit)
		if zDisplayPvPRank > 1 and pvpRank > 0 then
			RankIcon:Show()
			RankIcon:SetTexture(format("%s%02d", "Interface\\PvPRankBadges\\PvPRank", rankIndex))
			if rankIndex > 5 then
				RankIcon:SetAlpha(1)
			else
				RankIcon:SetAlpha(0.66)
			end
			text2 = "    "
		else
			RankIcon:Hide()
			text2 = ""
		end

		local titletext = UnitPVPName(unit)
		if titletext then
			if pvpRank > 0 then
				titletext = string.gsub(titletext, rankName, "")
			end
			titletext = string.gsub(titletext, UnitName(unit), "")
		else
			titletext = ""
		end

		-- [MODIFIED] 将玩家名字染为职业颜色
		local playerName = UnitName(unit)
		local _, class = UnitClass(unit)
		local classColorHex = zGetHexColor(RAID_CLASS_COLORS[(class or "")])
		playerName = format("|cff%s%s|r", classColorHex, playerName)

		if zDisplayPvPRank == 2 then
			text:SetText(text1 .. text2 .. playerName .. titletext)
		elseif pvpRank > 0 and zDisplayPvPRank >= 1 then
			text:SetText(text1 .. text2 .. playerName .. "|CFFCCCC33 " .. rankName .. "|r" .. titletext)
		else
			text:SetText(text1 .. text2 .. playerName .. titletext)
		end
	end

	-- 第二行：仅显示公会（服务器信息已移除）
	tip = nil
	if isplayer then
		local guild = GetGuildInfo(unit)
		if guild then
			tip = "<" .. guild .. ">"
		end
	end
	if tip then
		local lines = GameTooltip:NumLines()
		GameTooltip:AddLine("zTip -- placeholder")
		for i = lines, 2, -1 do
			getglobal("GameTooltipTextLeft" .. i + 1):SetText(getglobal("GameTooltipTextLeft" .. i):GetText())
		end
		GameTooltipTextLeft2:SetText(tip)
	end

	-- 显示抗性
	self:GetMouseoverResist()

	-- 着色
	if tapped or bdead then
		r, g, b = 0.55, 0.55, 0.55
	elseif isplayer or UnitPlayerControlled(unit) then
		if UnitCanAttack(unit, "player") then
			if not UnitCanAttack("player", unit) then
				r, g, b = 1.0, 0.4, 1.0
			else
				r, g, b = 1.0, 0.0, 0.0
			end
		elseif UnitCanAttack("player", unit) then
			r, g, b = 1.0, 1.0, 0.0
		elseif UnitIsPVP(unit) then
			r, g, b = 0.0, 1.0, 0.0
		else
			r, g, b = 0.0, 0.7, 1.0
		end
	elseif reaction then
		if reaction < 4 then
			r, g, b = 1.0, 0.3, 0.22
		elseif reaction > 4 then
			r, g, b = 0.0, 1.0, 0.0
		else
			r, g, b = 1.0, 1.0, 0.0
		end
	else
		r, g, b = 1.0, 1.0, 1.0
	end

	if tip or (levelline and levelline > 2) then
		if bdead or tapped then
			GameTooltipTextLeft2:SetTextColor(0.55, 0.55, 0.55)
		else
			GameTooltipTextLeft2:SetTextColor(r * zGuildColorAlpha, g * zGuildColorAlpha, b * zGuildColorAlpha)
		end
	end

	if isplayer and GetGuildInfo(unit) == GetGuildInfo("player") then
		GameTooltipTextLeft2:SetTextColor(0.9, 0.5, 0.9)
	end

	GameTooltip:Show()
	return r, g, b
end

-- 采集等级显示
function Automaton_zTip:ShowGatheringLevel()
	if not zShowGatheringLevel then
		return
	end
	local firstLineText = GameTooltipTextLeft1:GetText()
	local gatherLevel = gatheringData[firstLineText]
	if gatherLevel then
		local r, g, b = GameTooltipTextLeft2:GetTextColor()
		if r > 0.8 and g < 0.3 then
			return
		end
		local tiptext = GameTooltipTextLeft2:GetText()
		if tiptext then
			GameTooltipTextLeft2:SetText(tiptext .. " " .. gatherLevel)
		end
		GameTooltip:Show()
	end
end

-- 抗性/护甲显示
function Automaton_zTip:GetMouseoverResist()
	local mo = "mouseover"
	local _, GetHoly = UnitResistance(mo, 1)
	local _, GetShadow = UnitResistance(mo, 5)
	local _, GetFire = UnitResistance(mo, 2)
	local _, GetFrost = UnitResistance(mo, 4)
	local _, GetNature = UnitResistance(mo, 3)
	local _, GetArcane = UnitResistance(mo, 6)
	local _, GetArmor = UnitResistance(mo, 0)

	if GetFire ~= 0 and GetFrost == 0 then
		GameTooltip:AddLine("|cffFF0000火抗" .. GetFire)
	elseif GetFire == 0 and GetFrost ~= 0 then
		GameTooltip:AddLine("|cff4AE8F5冰抗" .. GetFrost)
	elseif GetFire ~= 0 and GetFrost ~= 0 then
		GameTooltip:AddLine("|cffFF0000火抗" .. GetFire .. " " .. "|cff4AE8F5冰抗" .. GetFrost)
	end

	if GetNature ~= 0 and GetArcane == 0 then
		GameTooltip:AddLine("|cff00FF00自抗" .. GetNature)
	elseif GetNature == 0 and GetArcane ~= 0 then
		GameTooltip:AddLine("|cffF241FF奥抗" .. GetArcane)
	elseif GetNature ~= 0 and GetArcane ~= 0 then
		GameTooltip:AddLine("|cff00FF00自抗" .. GetNature .. " " .. "|cffF241FF奥抗" .. GetArcane)
	end

	if GetHoly ~= 0 and GetShadow == 0 then
		GameTooltip:AddLine("|cffFFFE91圣抗" .. GetHoly)
	elseif GetHoly == 0 and GetShadow ~= 0 then
		GameTooltip:AddLine("|cff87248F暗抗" .. GetShadow)
	elseif GetHoly ~= 0 and GetShadow ~= 0 then
		GameTooltip:AddLine("|cffFFFE91圣抗" .. GetHoly .. " " .. "|cff87248F暗抗" .. GetShadow)
	end

	if GetArmor ~= 0 then
		GameTooltip:AddLine("护甲" .. GetArmor)
	end
end

-- 显示目标伤害和攻速
function Automaton_zTip:ShowDamageAndSpeed(unit)
	if not zShowDamageAndSpeed then
		return
	end
	local reaction = UnitReaction(unit, "player")
	local isHostileOrNeutral = reaction and (reaction <= 4) -- 4及以下为中立或敌对
	if isHostileOrNeutral and not UnitIsPlayer(unit) then
		local minDmg, maxDmg = UnitDamage(unit)
		local attackSpeed = UnitAttackSpeed(unit)
		if minDmg and maxDmg then
			GameTooltip:AddLine(string.format("伤害范围: %.0f - %.0f", minDmg, maxDmg))
		end
		if attackSpeed then
			GameTooltip:AddLine(string.format("攻击速度: %.2f", attackSpeed))
		end
	end
end

-- 显示玩家印象
function Automaton_zTip:ShowImpression(unit)
	if not zShowImpression then
		return
	end
	if UnitIsPlayer(unit) then
		local playerName = UnitName(unit)
		if SpiritSenseRecData and type(SpiritSenseRecData) == "table" then
			local impression = SpiritSenseRecData[playerName]
			if impression then
				local impressionText
				if type(impression) == "table" then
					impressionText = table.concat(impression, ", ")
				else
					impressionText = tostring(impression)
				end
				GameTooltip:AddLine(string.format("印象: %s", impressionText))
			end
		end
	end
end

-- 显示自己宠物信息（快乐度/食物需求/经验）
function Automaton_zTip:ShowPetInfo(unit)
	if not (zShowPetHappiness or zShowPetFood or zShowPetExp) then
		return
	end
	if not UnitIsUnit(unit, "pet") then
		return
	end

	-- 快乐度（GetPetHappiness 仅猎人宠物返回有效值，术士宠物等返回 nil 自动跳过）
	if zShowPetHappiness and GetPetHappiness then
		local happiness = GetPetHappiness()
		if happiness then
			local labels = {
				[1] = "|cffff3333不高兴 (伤害75%)|r",
				[2] = "|cffffff00满足 (伤害100%)|r",
				[3] = "|cff33ff33快乐 (伤害125%)|r",
			}
			GameTooltip:AddLine("快乐度: " .. (labels[happiness] or tostring(happiness)))
		end
	end

	-- 食物需求（客户端返回的已是本地化字符串，如：肉、鱼、水果）
	if zShowPetFood and GetPetFoodTypes then
		local foods = { GetPetFoodTypes() }
		if foods and table.getn(foods) > 0 then
			GameTooltip:AddLine("食物需求: |cff66ccff" .. table.concat(foods, "、") .. "|r")
		end
	end

	-- 经验（宠物满级 60 级时不显示）
	if zShowPetExp then
		local level = UnitLevel("pet")
		if level and level ~= 60 then
			-- 1.12 宠物经验必须用 GetPetExperience()（UnitXP("pet") 本客户端不可靠，返回 nil/0）
			local cur, max
			if GetPetExperience then
				cur, max = GetPetExperience()
			end
			if not cur or not max then
				cur, max = UnitXP("pet"), UnitXPMax("pet")
			end
			if cur and max and max > 0 then
				GameTooltip:AddLine(string.format("经验: %d/%d (%d%%)", cur, max, math.floor(cur / max * 100)))
			end
		end
	end
end

-- 自定义锚点设置（统一处理系统偏移和用户偏移）
function Automaton_zTip:SetDefaultAnchor(tooltip, owner)
	if tooltip ~= GameTooltip then
		self.orig_GameTooltip_SetDefaultAnchor(tooltip, owner)
		return
	end

	-- 临时修改系统偏移量以实现“系统默认位置偏移”
	local origX, origY = CONTAINER_OFFSET_X, CONTAINER_OFFSET_Y
	CONTAINER_OFFSET_X, CONTAINER_OFFSET_Y = zOrigPosX, zOrigPosY

	if owner == UIParent then
		if UnitExists("mouseover") then
			if zAnchor == 1 or zAnchor == 3 then
				tooltip:SetOwner(owner, "ANCHOR_NONE")
			elseif zAnchor ~= 0 then
				local scale = UIParent:GetScale() or 1
				local tipScale = GameTooltip:GetScale() or 1
				local x = zOffsetX / tipScale / scale
				local y = zOffsetY / tipScale / scale
				tooltip:SetOwner(owner, "ANCHOR_NONE")
				tooltip:SetPoint("TOP", UIParent, "TOP", x, -y)
			end
		else
			local x, y = GetCursorPosition()
			local scale = UIParent:GetScale() or 1
			local tipScale = GameTooltip:GetScale() or 1
			x = (x + zOffsetX) / tipScale / scale
			y = (y - zOffsetY) / tipScale / scale
			tooltip:SetOwner(owner, "ANCHOR_NONE")
			tooltip:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
		end
	else
		if zAnchor ~= 0 and (zAnchor > 2 or zIsOnUnitFrame or owner:GetParent() == RaidFrame) then
			tooltip:SetOwner(owner, "ANCHOR_RIGHT")
		else
			self.orig_GameTooltip_SetDefaultAnchor(tooltip, owner)
		end
	end

	-- 恢复系统偏移
	CONTAINER_OFFSET_X, CONTAINER_OFFSET_Y = origX, origY
end

-- 事件处理函数（用于GameTooltip的OnEvent）
function Automaton_zTip:OnTooltipEvent(event)
	if event == "UPDATE_MOUSEOVER_UNIT" then
		-- 重置目标行标志和挑战计时器
		ShowChallenges_timer = 0
		zTargetLineAdded = false
		targetlinenum = nil
		mouseTarget = nil

		-- 强制使用 SetUnit 刷新整个提示框（仅当鼠标下有单位时）
		if UnitExists("mouseover") then
			GameTooltip:SetUnit("mouseover")
		end
	end
end

-- 挑战项目相关（保留原有逻辑）
function Automaton_zTip:UpdateChallenges(player)
	if GameTooltip.challenges then
		return
	end
	local playerChallenges = Turtle_ChallengesCache[GetRealmName()][player]
	if playerChallenges and table.getn(playerChallenges) > 1 then
		local mask = playerChallenges[2]
		if mask then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(ACTIVE_CHALLENGES)
			for i, challenge in ipairs(Turtle_AvailableChallenges) do
				if math.mod(math.floor(mask / 2 ^ (i - 1)), 2) == 1 then
					GameTooltip:AddLine(challenge.name, 1, 1, 1, true)
				end
			end
		end
		GameTooltip.challenges = true
		GameTooltip:Show()
	end
end

function Automaton_zTip:CheckChallenges(unit)
	if PLAYER_CHALLENGES == "0" or not unit or not UnitIsPlayer(unit) or UnitIsUnit("target", "player") then
		return
	end
	local realm = GetRealmName()
	local name = UnitName(unit)
	local level = UnitLevel(unit)
	if name then
		local playerChallenges = Turtle_ChallengesCache[realm][name]
		if playerChallenges and playerChallenges[1] <= level then
			Turtle_ChallengesCache[realm][name][1] = level
			self:UpdateChallenges(name)
		else
			Turtle_ChallengesCache[realm][name] = { level }
			SendAddonMessage("TW_UI", "REQUEST_PLAYER_CHALLENGES;" .. name, "GUILD")
		end
	end
end

-- ==================== 物品ID钩子（模块方法，已修复返回值）====================
function Automaton_zTip:HookSetHyperlink(tooltip, itemstring)
	local ret
	if self.orig_SetHyperlink then
		ret = self.orig_SetHyperlink(tooltip, itemstring)
	end
	-- 如果启用了物品ID，则尝试添加ID行
	if zShowItemID and tooltip.itemLink then
		local _, _, itemId = strfind(tooltip.itemLink, ".*item:(%d+):[%d:]+|h%[(.+)%]|h|.*")
		if itemId then
			tooltip:AddDoubleLine("物品ID：", itemId)
			tooltip:Show()
		end
	end
	return ret
end

function Automaton_zTip:HookSetBagItem(tooltip, container, slot)
	local ret
	if self.orig_SetBagItem then
		ret = self.orig_SetBagItem(tooltip, container, slot)
	end
	tooltip.itemLink = GetContainerItemLink(container, slot)
	return ret
end

function Automaton_zTip:HookSetQuestLogItem(tooltip, itemType, index)
	local ret
	if self.orig_SetQuestLogItem then
		ret = self.orig_SetQuestLogItem(tooltip, itemType, index)
	end
	tooltip.itemLink = GetQuestLogItemLink(itemType, index)
	return ret
end

function Automaton_zTip:HookSetQuestItem(tooltip, itemType, index)
	local ret
	if self.orig_SetQuestItem then
		ret = self.orig_SetQuestItem(tooltip, itemType, index)
	end
	tooltip.itemLink = GetQuestItemLink(itemType, index)
	return ret
end

function Automaton_zTip:HookSetLootItem(tooltip, slot)
	local ret
	if self.orig_SetLootItem then
		ret = self.orig_SetLootItem(tooltip, slot)
	end
	tooltip.itemLink = GetLootSlotLink(slot)
	return ret
end

function Automaton_zTip:HookSetInventoryItem(tooltip, unit, slot)
	local ret
	if self.orig_SetInventoryItem then
		ret = self.orig_SetInventoryItem(tooltip, unit, slot)
	end
	tooltip.itemLink = GetInventoryItemLink(unit, slot)
	return ret
end

-- ==================== 法术ID钩子（模块方法，已修复返回值）====================
function Automaton_zTip:HookSetPlayerBuff(tooltip, index)
	local ret
	if self.orig_SetPlayerBuff then
		ret = self.orig_SetPlayerBuff(tooltip, index)
	end
	if zShowSpellID then
		local spellId = GetPlayerBuffID(index)
		if spellId then
			tooltip:AddDoubleLine("法术ID：", spellId)
			tooltip:Show()
		end
	end
	return ret
end

function Automaton_zTip:HookSetPlayerDebuff(tooltip, index)
	local ret
	if self.orig_SetPlayerDebuff then
		ret = self.orig_SetPlayerDebuff(tooltip, index)
	end
	if zShowSpellID then
		local _, _, _, spellId = UnitDebuff("player", index)
		if spellId then
			tooltip:AddDoubleLine("法术ID：", spellId)
			tooltip:Show()
		end
	end
	return ret
end

function Automaton_zTip:HookSetUnitBuff(tooltip, unit, index)
	local ret
	if self.orig_SetUnitBuff then
		ret = self.orig_SetUnitBuff(tooltip, unit, index)
	end
	if zShowSpellID then
		local _, _, _, _, _, _, spellId = UnitBuff(unit, index)
		if spellId then
			tooltip:AddDoubleLine("法术ID：", spellId)
			tooltip:Show()
		end
	end
	return ret
end

function Automaton_zTip:HookSetUnitDebuff(tooltip, unit, index)
	local ret
	if self.orig_SetUnitDebuff then
		ret = self.orig_SetUnitDebuff(tooltip, unit, index)
	end
	if zShowSpellID then
		local _, _, _, _, _, _, spellId = UnitDebuff(unit, index)
		if spellId then
			tooltip:AddDoubleLine("法术ID：", spellId)
			tooltip:Show()
		end
	end
	return ret
end

-- ==================== 3D模型相关函数（新增）====================
function Automaton_zTip:Create3DModelFrame()
	if self.modelFrame then
		return
	end
	self.modelFrame = CreateFrame("PlayerModel", "Automaton_zTip_Model", GameTooltip)
	local p = self.db.profile
	self.modelFrame:SetWidth(p.zModelSize)
	self.modelFrame:SetHeight(p.zModelSize)
	self.modelFrame:SetFrameStrata("TOOLTIP")
	self.modelFrame:SetFrameLevel(GameTooltip:GetFrameLevel() + 1)
	self.modelFrame:SetAlpha(0.9)
	self.modelFrame:Hide()

	if p.zModelRotation then
		self.modelFrame:EnableMouse(true)
		self.modelRotationEnabled = false
		self.modelRotationSpeed = 0
		self.modelLastUpdate = 0
		self.modelFrame:SetScript("OnUpdate", function(frame, elapsed)
			if not self.modelRotationEnabled then
				return
			end
			if not elapsed then
				return
			end -- 防御：如果elapsed为nil则退出
			self.modelLastUpdate = (self.modelLastUpdate or 0) + elapsed
			if self.modelLastUpdate >= 0.016 then
				if self.modelRotationSpeed ~= 0 then
					local facing = frame:GetFacing()
					frame:SetFacing(facing + self.modelRotationSpeed * 0.1)
				end
				self.modelLastUpdate = 0
			end
		end)
		self.modelFrame:SetScript("OnEnter", function()
			self.modelRotationEnabled = true
		end)
		self.modelFrame:SetScript("OnLeave", function()
			self.modelRotationEnabled = false
		end)
	else
		self.modelFrame:EnableMouse(false)
	end
end

function Automaton_zTip:UpdateModelPosition()
	if not self.modelFrame or not self.modelFrame:IsShown() then
		return
	end
	local p = self.db.profile
	local pos = p.zModelPosition
	local offX = p.zModelOffsetX
	local offY = p.zModelOffsetY
	local attachPoint, relativePoint
	if pos == 0 then -- TOP
		attachPoint = "BOTTOM"
		relativePoint = "TOP"
	elseif pos == 1 then -- BOTTOM
		attachPoint = "TOP"
		relativePoint = "BOTTOM"
	elseif pos == 2 then -- LEFT
		attachPoint = "RIGHT"
		relativePoint = "LEFT"
	elseif pos == 3 then -- RIGHT
		attachPoint = "LEFT"
		relativePoint = "RIGHT"
	else
		attachPoint = "BOTTOM"
		relativePoint = "TOP"
	end
	self.modelFrame:ClearAllPoints()
	self.modelFrame:SetPoint(attachPoint, GameTooltip, relativePoint, offX, offY)

	if p.zModelEdge then
		local screenWidth, screenHeight = GetScreenWidth(), GetScreenHeight()
		local left, right, bottom, top =
			self.modelFrame:GetLeft(), self.modelFrame:GetRight(), self.modelFrame:GetBottom(), self.modelFrame:GetTop()
		if left and right and bottom and top then
			local offsetX, offsetY = 0, 0
			if left < 0 then
				offsetX = -left + 5
			end
			if right > screenWidth then
				offsetX = screenWidth - right - 5
			end
			if bottom < 0 then
				offsetY = -bottom + 5
			end
			if top > screenHeight then
				offsetY = screenHeight - top - 5
			end
			if offsetX ~= 0 or offsetY ~= 0 then
				self.modelFrame:SetPoint(attachPoint, GameTooltip, relativePoint, offX + offsetX, offY + offsetY)
			end
		end
	end
end

function Automaton_zTip:ShowModelForUnit(unit)
	local p = self.db.profile
	if not p.zShow3DModel then
		if self.modelFrame then
			self.modelFrame:Hide()
		end
		return
	end
	if not unit or not UnitExists(unit) or not UnitIsPlayer(unit) then
		if self.modelFrame then
			self.modelFrame:Hide()
		end
		return
	end

	if not self.modelFrame then
		self:Create3DModelFrame()
	end

	if self.modelFrame and UnitIsVisible(unit) then
		self.modelFrame:SetUnit(unit)
		self.modelFrame:SetFacing(0)
		self.modelFrame:SetWidth(p.zModelSize)
		self.modelFrame:SetHeight(p.zModelSize)
		self.modelFrame:Show()
		self:UpdateModelPosition()
	else
		if self.modelFrame then
			self.modelFrame:Hide()
		end
	end
end

function Automaton_zTip:HideModel()
	if self.modelFrame then
		self.modelFrame:Hide()
		self.modelFrame:ClearModel()
	end
end

function Automaton_zTip:UpdateModelConfig()
	if not self.modelFrame then
		return
	end
	local p = self.db.profile
	self.modelFrame:SetWidth(p.zModelSize)
	self.modelFrame:SetHeight(p.zModelSize)
	if p.zModelRotation then
		if not self.modelFrame:IsMouseEnabled() then
			self.modelFrame:EnableMouse(true)
			-- 重新设置脚本（覆盖之前的）
			self.modelFrame:SetScript("OnUpdate", function(frame, elapsed)
				if not self.modelRotationEnabled then
					return
				end
				if not elapsed then
					return
				end -- 防御：如果elapsed为nil则退出
				self.modelLastUpdate = (self.modelLastUpdate or 0) + elapsed
				if self.modelLastUpdate >= 0.016 then
					if self.modelRotationSpeed ~= 0 then
						local facing = frame:GetFacing()
						frame:SetFacing(facing + self.modelRotationSpeed * 0.1)
					end
					self.modelLastUpdate = 0
				end
			end)
			self.modelFrame:SetScript("OnEnter", function()
				self.modelRotationEnabled = true
			end)
			self.modelFrame:SetScript("OnLeave", function()
				self.modelRotationEnabled = false
			end)
		end
	else
		self.modelFrame:EnableMouse(false)
		self.modelFrame:SetScript("OnUpdate", nil)
		self.modelFrame:SetScript("OnEnter", nil)
		self.modelFrame:SetScript("OnLeave", nil)
	end
	if self.modelFrame:IsShown() then
		self:UpdateModelPosition()
	end
end

-- 模块启用
function Automaton_zTip:OnEnable()
	-- 从数据库加载配置到局部变量
	self:UpdateConfig()

	-- 创建模块帧（用于OnUpdate和事件）
	moduleFrame = moduleFrame or CreateFrame("Frame")
	moduleFrame:SetScript("OnUpdate", function(self, elapsed)
		Automaton_zTip:OnUpdate(elapsed)
	end)

	-- 注册事件
	moduleFrame:RegisterEvent("CHAT_MSG_ADDON")
	moduleFrame:SetScript("OnEvent", function(self, event, arg1, arg2, ...)
		if event == "CHAT_MSG_ADDON" then
			Automaton_zTip:OnChatAddon(arg1, arg2)
		end
	end)

	-- 设置GameTooltip的OnEvent（如果尚未设置）
	if not GameTooltip:GetScript("OnEvent") then
		GameTooltip:SetScript("OnEvent", function(self, event, ...)
			Automaton_zTip:OnTooltipEvent(event)
		end)
	end

	-- 保存原始函数并覆写
	self.orig_GameTooltip_UnitColor = GameTooltip_UnitColor
	GameTooltip_UnitColor = function(unit)
		return Automaton_zTip:FormatUnit(unit)
	end

	self.orig_UnitFrame_OnEnter = UnitFrame_OnEnter
	UnitFrame_OnEnter = function()
		zIsOnUnitFrame = true
		local newbieTip = SHOW_NEWBIE_TIPS
		SHOW_NEWBIE_TIPS = "0"
		Automaton_zTip.orig_UnitFrame_OnEnter()
		SHOW_NEWBIE_TIPS = newbieTip
	end

	self.orig_UnitFrame_OnLeave = UnitFrame_OnLeave
	UnitFrame_OnLeave = function()
		Automaton_zTip.orig_UnitFrame_OnLeave()
		zIsOnUnitFrame = nil
		if z_ClassIcon then
			z_ClassIcon:Hide()
		end
		if RankIcon then
			RankIcon:Hide()
		end
		if not zFade then
			GameTooltip:Hide()
		end
		-- 隐藏3D模型
		Automaton_zTip:HideModel()
	end

	-- 保存原始锚点函数并替换（统一替换，不再处理CONTAINER_OFFSET的第二次覆盖）
	self.orig_GameTooltip_SetDefaultAnchor = GameTooltip_SetDefaultAnchor
	if zAnchor ~= 0 then
		GameTooltip_SetDefaultAnchor = function(tooltip, parent)
			Automaton_zTip:SetDefaultAnchor(tooltip, parent)
		end
	else
		GameTooltip_SetDefaultAnchor = self.orig_GameTooltip_SetDefaultAnchor
	end

	-- 血条染色：直接替换函数并保存原始
	self.orig_HealthBar_OnValueChanged = HealthBar_OnValueChanged
	HealthBar_OnValueChanged = HealthBar_OnValueChanged_Replacement

	-- 创建纹理（如果尚未创建）
	if not z_ClassIcon then
		z_ClassIcon = GameTooltip:CreateTexture(nil, "ARTWORK")
		z_ClassIcon:SetWidth(14)
		z_ClassIcon:SetHeight(14)
		z_ClassIcon:SetPoint("TOPLEFT", GameTooltip, "TOPLEFT", 11, -11)
	end
	if not RankIcon then
		RankIcon = GameTooltip:CreateTexture(nil, "ARTWORK")
		RankIcon:SetWidth(14)
		RankIcon:SetHeight(14)
		RankIcon:SetPoint("TOPLEFT", z_ClassIcon, "TOPRIGHT", 2, 0)
	end

	-- ========== 修复：标记当前是否为“单位提示”，钩住 SetOwner（移除 OnTooltipCleared 钩子） ==========
	self.isUnitTipShown = false

	self.orig_SetOwner = GameTooltip.SetOwner
	GameTooltip.SetOwner = function(tooltip, owner, anchor)
		local ret = self.orig_SetOwner(tooltip, owner, anchor)
		-- 当 owner 为 UIParent 且鼠标下存在单位时，认为是单位提示
		self.isUnitTipShown = (owner == UIParent and UnitExists("mouseover"))
		return ret
	end

	-- 不再钩住 OnTooltipCleared，原版单体没有在这里重置标记
	-- ========== 修复结束 ==========

	-- 物品ID钩子（显式参数）
	self.orig_SetHyperlink = GameTooltip.SetHyperlink
	GameTooltip.SetHyperlink = function(tooltip, itemstring)
		return Automaton_zTip:HookSetHyperlink(tooltip, itemstring)
	end

	self.orig_SetBagItem = GameTooltip.SetBagItem
	GameTooltip.SetBagItem = function(tooltip, container, slot)
		return Automaton_zTip:HookSetBagItem(tooltip, container, slot)
	end

	self.orig_SetQuestLogItem = GameTooltip.SetQuestLogItem
	GameTooltip.SetQuestLogItem = function(tooltip, itemType, index)
		return Automaton_zTip:HookSetQuestLogItem(tooltip, itemType, index)
	end

	self.orig_SetQuestItem = GameTooltip.SetQuestItem
	GameTooltip.SetQuestItem = function(tooltip, itemType, index)
		return Automaton_zTip:HookSetQuestItem(tooltip, itemType, index)
	end

	self.orig_SetLootItem = GameTooltip.SetLootItem
	GameTooltip.SetLootItem = function(tooltip, slot)
		return Automaton_zTip:HookSetLootItem(tooltip, slot)
	end

	self.orig_SetInventoryItem = GameTooltip.SetInventoryItem
	GameTooltip.SetInventoryItem = function(tooltip, unit, slot)
		return Automaton_zTip:HookSetInventoryItem(tooltip, unit, slot)
	end

	-- 法术ID钩子
	self.orig_SetPlayerBuff = GameTooltip.SetPlayerBuff
	GameTooltip.SetPlayerBuff = function(tooltip, index)
		return Automaton_zTip:HookSetPlayerBuff(tooltip, index)
	end

	self.orig_SetPlayerDebuff = GameTooltip.SetPlayerDebuff
	GameTooltip.SetPlayerDebuff = function(tooltip, index)
		return Automaton_zTip:HookSetPlayerDebuff(tooltip, index)
	end

	self.orig_SetUnitBuff = GameTooltip.SetUnitBuff
	GameTooltip.SetUnitBuff = function(tooltip, unit, index)
		return Automaton_zTip:HookSetUnitBuff(tooltip, unit, index)
	end

	self.orig_SetUnitDebuff = GameTooltip.SetUnitDebuff
	GameTooltip.SetUnitDebuff = function(tooltip, unit, index)
		return Automaton_zTip:HookSetUnitDebuff(tooltip, unit, index)
	end

	-- 保存原始OnShow并覆写
	self.orig_GameTooltip_OnShow = GameTooltip:GetScript("OnShow") or function() end
	GameTooltip:SetScript("OnShow", function()
		Automaton_zTip:OnShow()
		Automaton_zTip.orig_GameTooltip_OnShow()
	end)

	-- 初始化法力条和血量条显示
	self:InitBars()
end

-- 模块禁用
function Automaton_zTip:OnDisable()
	-- 取消事件和更新
	if moduleFrame then
		moduleFrame:SetScript("OnUpdate", nil)
		moduleFrame:UnregisterAllEvents()
	end

	-- 恢复原始函数
	if self.orig_GameTooltip_UnitColor then
		GameTooltip_UnitColor = self.orig_GameTooltip_UnitColor
		self.orig_GameTooltip_UnitColor = nil
	end
	if self.orig_UnitFrame_OnEnter then
		UnitFrame_OnEnter = self.orig_UnitFrame_OnEnter
		self.orig_UnitFrame_OnEnter = nil
	end
	if self.orig_UnitFrame_OnLeave then
		UnitFrame_OnLeave = self.orig_UnitFrame_OnLeave
		self.orig_UnitFrame_OnLeave = nil
	end
	if self.orig_GameTooltip_SetDefaultAnchor then
		GameTooltip_SetDefaultAnchor = self.orig_GameTooltip_SetDefaultAnchor
		self.orig_GameTooltip_SetDefaultAnchor = nil
	end
	if self.orig_HealthBar_OnValueChanged then
		HealthBar_OnValueChanged = self.orig_HealthBar_OnValueChanged
		self.orig_HealthBar_OnValueChanged = nil
	end

	-- 恢复 SetOwner 钩子（移除 OnTooltipCleared 恢复）
	if self.orig_SetOwner then
		GameTooltip.SetOwner = self.orig_SetOwner
		self.orig_SetOwner = nil
	end

	-- 恢复物品ID钩子
	local hooks = {
		"SetHyperlink",
		"SetBagItem",
		"SetQuestLogItem",
		"SetQuestItem",
		"SetLootItem",
		"SetInventoryItem",
		"SetPlayerBuff",
		"SetPlayerDebuff",
		"SetUnitBuff",
		"SetUnitDebuff",
	}
	for _, hook in ipairs(hooks) do
		local orig = self["orig_" .. hook]
		if orig then
			GameTooltip[hook] = orig
			self["orig_" .. hook] = nil
		end
	end

	-- 恢复 GameTooltip 脚本
	if self.orig_GameTooltip_OnShow then
		GameTooltip:SetScript("OnShow", self.orig_GameTooltip_OnShow)
		self.orig_GameTooltip_OnShow = nil
	end
	GameTooltip:SetScript("OnEvent", nil)

	-- 清理状态变量
	zIsOnUnitFrame = nil
	targetlinenum = nil
	mouseTarget = nil
	zTargetLineAdded = false
	GameTooltip.unit = nil
	GameTooltip.challenges = nil
	self.isUnitTipShown = false

	-- 隐藏并销毁3D模型
	self:HideModel()
	if self.modelFrame then
		self.modelFrame:Hide()
		self.modelFrame:ClearModel()
		self.modelFrame = nil
	end

	-- 隐藏创建的纹理
	if z_ClassIcon then
		z_ClassIcon:Hide()
	end
	if RankIcon then
		RankIcon:Hide()
	end
end

-- 配置更新（从db.profile加载到局部变量）
function Automaton_zTip:UpdateConfig()
	local p = self.db.profile
	zAnchor = p.zAnchor
	zOffsetX = p.zOffsetX
	zOffsetY = p.zOffsetY
	zOrigPosX = p.zOrigPosX
	zOrigPosY = p.zOrigPosY
	zScale = p.zScale
	zScaleEnabled = p.zScaleEnabled
	zGuildColorAlpha = p.zGuildColorAlpha
	zGuildColorAlphaEnabled = p.zGuildColorAlphaEnabled
	zFade = p.zFade
	zDisplayPvPRank = p.zDisplayPvPRank
	zClassIcon = p.zClassIcon
	zShowIsPlayer = p.zShowIsPlayer
	zDisplayFaction = p.zDisplayFaction
	zTargetOfMouse = p.zTargetOfMouse
	zShowBar = p.zShowBar
	zShowBarText = p.zShowBarText
	zShowGatheringLevel = p.zShowGatheringLevel
	zShowItemID = p.zShowItemID
	zShowSpellID = p.zShowSpellID
	zShowDamageAndSpeed = p.zShowDamageAndSpeed
	zShowImpression = p.zShowImpression
	zShowPetHappiness = p.zShowPetHappiness
	zShowPetFood = p.zShowPetFood
	zShowPetExp = p.zShowPetExp
	-- 3D模型配置
	zShow3DModel = p.zShow3DModel
	zModelSize = p.zModelSize
	zModelPosition = p.zModelPosition
	zModelOffsetX = p.zModelOffsetX
	zModelOffsetY = p.zModelOffsetY
	zModelRotation = p.zModelRotation
	zModelEdge = p.zModelEdge
	self:RefreshTooltipDisplay()
	-- 更新3D模型配置（如果已创建）
	self:UpdateModelConfig()
end

function Automaton_zTip:RefreshTooltipDisplay()
	-- 更新血条/法力条可见性
	if zShowBar then
		GameTooltipStatusBar:Show()
		if ManaBar then
			ManaBar:Show()
		end
	else
		GameTooltipStatusBar:Hide()
		if ManaBar then
			ManaBar:Hide()
		end
	end
	if zShowBarText then
		if tooltipStatusBar and tooltipStatusBar.HP then
			tooltipStatusBar.HP:Show()
		end
		if ManaBar and ManaBar.MP then
			ManaBar.MP:Show()
		end
	else
		if tooltipStatusBar and tooltipStatusBar.HP then
			tooltipStatusBar.HP:Hide()
		end
		if ManaBar and ManaBar.MP then
			ManaBar.MP:Hide()
		end
	end

	-- 如果当前有悬停单位，强制刷新提示框内容
	if UnitExists("mouseover") then
		-- 重置目标行添加标志，确保 OnShow 重新添加目标行
		zTargetLineAdded = false
		-- 隐藏并重新设置单位，触发 OnShow 和 FormatUnit
		GameTooltip:Hide()
		GameTooltip:SetUnit("mouseover")
	end
end

-- 模块事件处理（CHAT_MSG_ADDON等）
function Automaton_zTip:OnChatAddon(prefix, text)
	if prefix == "RESPONSE_PLAYER_CHALLENGES" then
		local s = strfind(text, ":")
		local player = strsub(text, 1, s - 1)
		if UnitName("mouseover") == player then
			local mask = strsub(text, s + 1)
			table.insert(Turtle_ChallengesCache[GetRealmName()][player], tonumber(mask))
		end
		self:UpdateChallenges(player)
	end
end

-- GameTooltip OnShow 处理（重写版，包含目标行添加）
function Automaton_zTip:OnShow()
	-- 清理PVP字符等
	local trueNum = GameTooltip:NumLines()
	for i = 3, trueNum do
		local line = getglobal("GameTooltipTextLeft" .. i)
		if line and line:GetText() == PVP_ENABLED then
			line:SetText("")
		end
	end

	-- 显示采集等级
	self:ShowGatheringLevel()

	-- 显示物品ID（如果是物品提示）
	if GameTooltip.itemLink and zShowItemID then
		local _, _, itemId = strfind(GameTooltip.itemLink, ".*item:(%d+):[%d:]+|h%[(.+)%]|h|.*")
		if itemId then
			GameTooltip:AddDoubleLine("物品ID：", itemId)
		end
	end

	-- 添加目标行（仅当悬停单位为有效单位且尚未添加）
	if UnitExists("mouseover") and zTargetOfMouse and not zTargetLineAdded then
		zTargetLineAdded = true

		-- 添加一个空行作为目标行
		GameTooltip:AddLine(" ")
		local lineNum = GameTooltip:NumLines()
		targetlinenum = lineNum -- 保存行号供OnUpdate更新使用

		local targetLine = getglobal("GameTooltipTextLeft" .. lineNum)
		if targetLine then
			if UnitExists("mouseovertarget") then
				local targetName = UnitName("mouseovertarget") or UNKNOWNOBJECT
				local tip = format("|cffFFFF00%s [|r", locTargeting)
				if UnitIsUnit("mouseovertarget", "player") then
					tip = format("%s |c00FF0000%s|r", tip, locYOU)
				elseif UnitIsUnit("mouseovertarget", "mouseover") then
					tip = format("%s |cffFFFFFF%s|r", tip, locSelf)
				elseif UnitIsPlayer("mouseovertarget") then
					-- [MODIFIED] 目标名字染为职业颜色，去掉职业名
					local _, class = UnitClass("mouseovertarget")
					local classColorHex = zGetHexColor(RAID_CLASS_COLORS[(class or "")])
					tip = format("%s |cff%s%s|r", tip, classColorHex, targetName)
				else
					tip = format("%s |cffFFFFFF%s|r", tip, targetName)
				end
				tip = tip .. " |cffFFFF00]|r"
				targetLine:SetText(tip)
				mouseTarget = targetName
			else
				targetLine:SetText("") -- 无目标时显示空行
				mouseTarget = nil
			end
		end
		-- 确保提示框刷新显示
		GameTooltip:Show()
	end

	-- 显示伤害和攻速、玩家印象、宠物信息（单位存在时）
	if UnitExists("mouseover") then
		self:ShowDamageAndSpeed("mouseover")
		self:ShowImpression("mouseover")
		self:ShowPetInfo("mouseover")
	end

	-- 显示3D模型（如果悬停单位是玩家）
	if UnitExists("mouseover") and UnitIsPlayer("mouseover") then
		self:ShowModelForUnit("mouseover")
	end
end

-- OnUpdate 处理（位置更新、目标动态更新等）
function Automaton_zTip:OnUpdate(elapsed)
	-- 应用缩放
	if zScaleEnabled then
		GameTooltip:SetScale(zScale)
	end

	-- 更新图标位置（不依赖 mouseover）
	if zClassIcon then
		RankIcon:SetPoint("TOPLEFT", z_ClassIcon, "TOPRIGHT", 2, 0)
	else
		RankIcon:SetPoint("TOPLEFT", GameTooltip, "TOPLEFT", 11, -11)
	end

	-- 血条/法力条显示控制（基于 GameTooltip.unit，不依赖 mouseover）
	if GameTooltip.unit and UnitExists(GameTooltip.unit) then
		if zShowBar then
			GameTooltipStatusBar:Show()
			if ManaBar then
				ManaBar:Show()
			end
		end
	else
		GameTooltipStatusBar:Hide()
		if ManaBar then
			ManaBar:Hide()
		end
		GameTooltip.unit = nil
	end

	-- 鼠标跟随模式（依赖 mouseover）
	if UnitExists("mouseover") then
		if zAnchor == 1 or zAnchor == 3 or zAnchor == 5 then
			local x, y = GetCursorPosition()
			local scale = UIParent:GetScale()
			if scale and scale ~= 0 then
				local tipScale = GameTooltip:GetScale() or 1
				x = (x + zOffsetX) / tipScale / scale
				if zAnchor == 5 then
					y = (y + zOffsetY) / tipScale / scale
				else
					y = (y - zOffsetY) / tipScale / scale
				end
			end
			GameTooltip:ClearAllPoints()
			if zAnchor == 5 then
				GameTooltip:SetPoint("BOTTOM", UIParent, "BOTTOMLEFT", x, y)
			else
				GameTooltip:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
			end
		end
	end

	-- 处理鼠标无单位时的隐藏逻辑（不立即返回）
	local hasMouseover = UnitExists("mouseover")
	if not hasMouseover then
		if self.isUnitTipShown then
			if not zFade then
				GameTooltip:Hide()
			end
			self.isUnitTipShown = false
		end
		-- 如果提示框已被隐藏，则重置所有状态并结束
		if not GameTooltip:IsShown() then
			z_ClassIcon:Hide()
			RankIcon:Hide()
			GameTooltipStatusBar:Hide()
			if ManaBar then
				ManaBar:Hide()
			end
			GameTooltip.unit = nil
			targetlinenum = nil
			mouseTarget = nil
			zTargetLineAdded = false
			-- 隐藏3D模型
			self:HideModel()
			return
		end
		-- 提示框仍然显示（如物品提示或UI框架提示），清除与 mouseover 相关的状态
		targetlinenum = nil
		mouseTarget = nil
		zTargetLineAdded = false
		-- 注意：不返回，继续执行以允许血条显示（血条已在上面处理）
	end

	-- 图标显示控制（依赖 mouseover）
	if hasMouseover then
		local mo = "mouseover"
		if UnitIsPlayer(mo) then
			if zClassIcon then
				z_ClassIcon:Show()
			else
				z_ClassIcon:Hide()
			end
			if zDisplayPvPRank and zDisplayPvPRank > 1 and UnitPVPRank(mo) > 0 then
				RankIcon:Show()
			else
				RankIcon:Hide()
			end
		else
			z_ClassIcon:Hide()
			RankIcon:Hide()
		end
	else
		z_ClassIcon:Hide()
		RankIcon:Hide()
	end

	-- 动态更新目标行内容（依赖 mouseover）
	if hasMouseover and zTargetOfMouse and targetlinenum then
		local targetLine = getglobal("GameTooltipTextLeft" .. targetlinenum)
		if targetLine then
			local currentTarget = UnitName("mouseovertarget")
			if currentTarget ~= mouseTarget then
				mouseTarget = currentTarget or UNKNOWNOBJECT
				if UnitExists("mouseovertarget") then
					local tip = format("|cffFFFF00%s [|r", locTargeting)
					if UnitIsUnit("mouseovertarget", "player") then
						tip = format("%s |c00FF0000%s|r", tip, locYOU)
					elseif UnitIsUnit("mouseovertarget", "mouseover") then
						tip = format("%s |cffFFFFFF%s|r", tip, locSelf)
					elseif UnitIsPlayer("mouseovertarget") then
						local _, class = UnitClass("mouseovertarget")
						local classColorHex = zGetHexColor(RAID_CLASS_COLORS[(class or "")])
						tip = format("%s |cff%s%s|r", tip, classColorHex, mouseTarget)
					else
						tip = format("%s |cffFFFFFF%s|r", tip, mouseTarget)
					end
					tip = tip .. " |cffFFFF00]|r"
					targetLine:SetText(tip)
				else
					targetLine:SetText("")
				end
				GameTooltip:Show()
			end
		end
	end

	-- 挑战项目检查（依赖 mouseover）
	if hasMouseover then
		if ShowChallenges_timer < 1 then
			ShowChallenges_timer = ShowChallenges_timer + 1
		elseif ShowChallenges_timer == 1 then
			if UnitExists("mouseover") then
				self:CheckChallenges("mouseover")
			end
		end
	end

	-- 更新3D模型位置（如果模型显示）
	if self.modelFrame and self.modelFrame:IsShown() then
		self:UpdateModelPosition()
	end
end

-- 初始化血量/法力条（重写版，修复法力条数值显示）
function Automaton_zTip:InitBars()
	-- 血量条
	GameTooltipStatusBar:SetHeight(8)
	GameTooltipStatusBar:ClearAllPoints()
	GameTooltipStatusBar:SetPoint("TOPLEFT", GameTooltip, "BOTTOMLEFT", 4, -2)
	GameTooltipStatusBar:SetPoint("TOPRIGHT", GameTooltip, "BOTTOMRIGHT", -4, 2)

	-- 血量条文字
	if not tooltipStatusBar then
		tooltipStatusBar = CreateFrame("Frame", nil, GameTooltipStatusBar)
		tooltipStatusBar:SetPoint("TOPLEFT", 0, 3)
		tooltipStatusBar:SetPoint("TOPRIGHT", 0, 3)
		tooltipStatusBar:SetHeight(12)
		tooltipStatusBar.HP = tooltipStatusBar:CreateFontString("Status", "DIALOG", "GameFontWhite")
		tooltipStatusBar.HP:SetAllPoints()
		tooltipStatusBar.HP:SetNonSpaceWrap(false)
		tooltipStatusBar.HP:SetFont(STANDARD_TEXT_FONT, 12, "Outline")
		tooltipStatusBar:SetScript("OnUpdate", function()
			local hp = GameTooltipStatusBar:GetValue()
			local _, hpmax = GameTooltipStatusBar:GetMinMaxValues()
			if hp > 0 then
				tooltipStatusBar.HP:SetText(string.format("%s / %s (%s%%)", hp, hpmax, ceil(hp / hpmax * 100)))
			else
				tooltipStatusBar.HP:SetText("")
			end
		end)
	end

	-- 法力条（重写，参考旧版逻辑）
	if not ManaBar then
		ManaBar = CreateFrame("StatusBar", "TinyTipExtras_ManaBar", GameTooltip)
		ManaBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-TargetingFrame-BarFill")
		ManaBar:SetHeight(8)
		ManaBar:SetPoint("TOPLEFT", GameTooltipStatusBar, "BOTTOMLEFT", 0, 0)
		ManaBar:SetPoint("TOPRIGHT", GameTooltipStatusBar, "BOTTOMRIGHT", 0, 0)

		-- 法力条文字
		ManaBar.MP = ManaBar:CreateFontString("Status", "DIALOG", "GameFontWhite")
		ManaBar.MP:SetAllPoints()
		ManaBar.MP:SetNonSpaceWrap(false)
		ManaBar.MP:SetFont(STANDARD_TEXT_FONT, 12, "Outline")

		-- 更新函数
		local function ManaBar_Update()
			if not GameTooltip.unit then
				return
			end
			local max = UnitManaMax(GameTooltip.unit) or 100
			ManaBar:SetMinMaxValues(0, max)
			if not UnitIsConnected(GameTooltip.unit) then
				ManaBar:SetValue(max)
				ManaBar:SetStatusBarColor(0.5, 0.5, 0.5)
			else
				ManaBar:SetValue(UnitMana(GameTooltip.unit))
				local powerType = UnitPowerType(GameTooltip.unit)
				local color = ManaBarColor[powerType] or ManaBarColor[0]
				ManaBar:SetStatusBarColor(color.r, color.g, color.b)
			end
			local mp = UnitMana(GameTooltip.unit)
			local mpmax = UnitManaMax(GameTooltip.unit)
			if mp > 0 then
				ManaBar.MP:SetText(string.format("%s / %s (%s%%)", mp, mpmax, ceil(mp / mpmax * 100)))
			else
				ManaBar.MP:SetText("")
			end
			if zShowBarText then
				ManaBar.MP:Show()
			else
				ManaBar.MP:Hide()
			end
		end

		-- OnShow 时更新
		ManaBar:SetScript("OnShow", ManaBar_Update)

		-- 事件处理（正确接收参数）
		ManaBar:SetScript("OnEvent", function(self, event, unit, ...)
			if unit and unit == GameTooltip.unit then
				if event == "UNIT_DISPLAYPOWER" then
					local powerType = UnitPowerType(unit)
					local color = ManaBarColor[powerType] or ManaBarColor[0]
					ManaBar:SetStatusBarColor(color.r, color.g, color.b)
				else
					ManaBar_Update()
				end
			end
		end)

		-- 注册事件
		ManaBar:RegisterEvent("UNIT_MANA")
		ManaBar:RegisterEvent("UNIT_ENERGY")
		ManaBar:RegisterEvent("UNIT_RAGE")
		ManaBar:RegisterEvent("UNIT_DISPLAYPOWER")
	end

	-- 根据配置显示/隐藏
	if zShowBar then
		GameTooltipStatusBar:Show()
		ManaBar:Show()
	else
		GameTooltipStatusBar:Hide()
		ManaBar:Hide()
	end
	if zShowBarText then
		tooltipStatusBar.HP:Show()
		ManaBar.MP:Show()
	else
		tooltipStatusBar.HP:Hide()
		ManaBar.MP:Hide()
	end
end

-- 模块初始化
function Automaton_zTip:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("zTip")
	Automaton:RegisterDefaults("zTip", "profile", {
		zAnchor = 3,
		zOffsetX = 50,
		zOffsetY = 50,
		zScale = 1.0,
		zScaleEnabled = false,
		zGuildColorAlpha = 0.86,
		zGuildColorAlphaEnabled = false,
		zFade = false,
		zDisplayPvPRank = 3,
		zClassIcon = true,
		zShowIsPlayer = true,
		zDisplayFaction = true,
		zTargetOfMouse = true,
		zShowBar = true,
		zShowBarText = true,
		zShowGatheringLevel = true,
		-- 新增默认值
		zShowItemID = false,
		zShowSpellID = false,
		zShowDamageAndSpeed = false,
		zShowImpression = false,
		zShowPetHappiness = true,
		zShowPetFood = true,
		zShowPetExp = true,
		-- 3D模型默认值
		zShow3DModel = false,
		zModelSize = 120,
		zModelPosition = 0,
		zModelOffsetX = 0,
		zModelOffsetY = 0,
		zModelRotation = true,
		zModelEdge = true,
	})
	Automaton:SetDisabledAsDefault(self, "zTip")

	-- 注册平铺的选项表
	self:RegisterOptions(self.options)
end
