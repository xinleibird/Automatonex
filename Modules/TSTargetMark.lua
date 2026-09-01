assert(Automaton, "Automaton not found!")

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_TSTargetMark = Automaton:NewModule("TSTargetMark")
Automaton_TSTargetMark.modulename = "目标标记箭头"
Automaton_TSTargetMark.moduledesc =
	"在目标姓名板上方显示标记箭头，支持浮动动画效果，并依据朝向变色"

------------------------------
--      Local Variables      --
------------------------------

-- 普通模式参数
local OFFSET_X = 0 -- 箭头X轴坐标位置
local OFFSET_Y = 5 -- 箭头Y轴坐标位置
local TEXTURE_SIZE = 50 -- 箭头大小

-- 特殊模式参数（固定不可调整）
local OFFSET_X_L = -3 -- 左箭头X轴坐标位置
local OFFSET_Y_L = 0 -- 左箭头y轴坐标位
local OFFSET_X_R = -OFFSET_X_L - 2 -- 右箭头X轴坐标位置
local OFFSET_Y_R = OFFSET_Y_L -- 右箭头y轴坐标位置
local SPECIAL_TEXTURE_SIZE = 18 -- 箭头大小

-- 浮动动画配置
local FLOAT_CONFIG = {
	enabled = true, -- 默认禁用浮动动画
	speed = 3, -- 浮动速度 (数值越大越快)
	amplitude = 15, -- 浮动幅度 (像素)
	smooth = true, -- 是否使用平滑动画
}

-- 朝向颜色配置
local FACING_COLOR_ENABLED = true
local FRONT_COLOR = { 1, 0, 0, 1 } -- 红色（正面）
local BACK_COLOR = { 0, 1, 0, 1 } -- 绿色（背面）
local DEFAULT_COLOR = { 1, 1, 1, 1 } -- 白色（无变化）

local MediaPath = "Interface\\AddOns\\Automatonex\\TGA\\"
local TargetArrow -- 箭头图片材质（动态初始化）
local TargetArrowL = MediaPath .. "Arrow26_左" -- 特殊模式左箭头
local TargetArrowR = MediaPath .. "Arrow26_右" -- 特殊模式右箭头

-- 自身高亮相关变量
local selfHighlightIcon = nil
local SELF_HIGHLIGHT_TEXTURE = MediaPath .. "SELF.TGA" -- 需要将 SELF.TGA 放入 Automatonex\TGA 目录

local parentcount = 0
local prevcount = 0
local cache = {}

-- 动画数据存储
local animationData = {
	time = 0,
	arrows = {}, -- 存储每个箭头的动画数据
	specialArrows = {}, -- 存储特殊模式箭头的动画数据
}

------------------------------
--      Local Functions      --
------------------------------

local function IsNamePlateFrame(frame)
	if frame:GetObjectType() ~= "Button" then
		return false
	end
	local overlayRegion = frame:GetRegions()
	if
		not overlayRegion
		or overlayRegion:GetObjectType() ~= "Texture"
		or overlayRegion:GetTexture() ~= "Interface\\Tooltips\\Nameplate-Border"
	then
		return false
	end
	return true
end

-- 获取目标朝向状态（正面/背面）
-- UnitXP 是一个函数，调用方式：UnitXP("behind", "player", "target")
local function GetTargetFacingStatus()
	if type(UnitXP) ~= "function" then
		return nil
	end
	local success, behind = pcall(UnitXP, "behind", "player", "target")
	if success then
		return behind and "back" or "front"
	end
	return nil
end

-- 设置箭头颜色（普通模式）
local function SetArrowColor(arrow, status)
	if not arrow then
		return
	end
	if not FACING_COLOR_ENABLED then
		arrow:SetVertexColor(DEFAULT_COLOR[1], DEFAULT_COLOR[2], DEFAULT_COLOR[3], DEFAULT_COLOR[4])
		return
	end
	if status == "back" then
		arrow:SetVertexColor(BACK_COLOR[1], BACK_COLOR[2], BACK_COLOR[3], BACK_COLOR[4])
	else
		-- 正面或未知状态：使用默认颜色（白色），显示纹理原始颜色
		arrow:SetVertexColor(DEFAULT_COLOR[1], DEFAULT_COLOR[2], DEFAULT_COLOR[3], DEFAULT_COLOR[4])
	end
end

-- 浮动动画更新函数
local function UpdateFloatAnimation(elapsed)
	if not FLOAT_CONFIG.enabled then
		return
	end

	animationData.time = animationData.time + (elapsed or 0.016)

	-- 更新普通模式箭头的浮动动画（垂直方向）
	for namePlate, arrowData in pairs(animationData.arrows) do
		if namePlate.Arrow and namePlate.Arrow:IsVisible() then
			local currentTime = GetTime()
			local elapsed = currentTime - arrowData.startTime

			-- 计算浮动偏移（垂直方向）
			local floatOffset = 0
			if FLOAT_CONFIG.smooth then
				-- 平滑的正弦波动画
				floatOffset = math.sin(elapsed * FLOAT_CONFIG.speed) * FLOAT_CONFIG.amplitude
			else
				-- 简单的上下浮动
				floatOffset = math.sin(elapsed * FLOAT_CONFIG.speed * 2) * FLOAT_CONFIG.amplitude * 0.5
			end

			-- 应用浮动偏移（垂直方向）
			local newY = arrowData.baseY + floatOffset
			namePlate.Arrow:ClearAllPoints()
			namePlate.Arrow:SetPoint("BOTTOM", namePlate, "TOP", OFFSET_X, newY)
		end
	end

	-- 更新特殊模式箭头的浮动动画（水平方向）
	for namePlate, arrowData in pairs(animationData.specialArrows) do
		if namePlate.ArrowL and namePlate.ArrowL:IsVisible() and namePlate.ArrowR and namePlate.ArrowR:IsVisible() then
			local currentTime = GetTime()
			local elapsed = currentTime - arrowData.startTime

			-- 计算浮动偏移（水平方向）
			local floatOffset = 0
			if FLOAT_CONFIG.smooth then
				floatOffset = math.sin(elapsed * FLOAT_CONFIG.speed) * FLOAT_CONFIG.amplitude
			else
				floatOffset = math.sin(elapsed * FLOAT_CONFIG.speed * 2) * FLOAT_CONFIG.amplitude * 0.5
			end

			-- 应用浮动偏移到左右箭头（水平方向）
			-- 左箭头向左浮动，右箭头向右浮动
			local newX_L = arrowData.baseX_L - floatOffset
			local newX_R = arrowData.baseX_R + floatOffset

			namePlate.ArrowL:ClearAllPoints()
			namePlate.ArrowL:SetPoint("Right", namePlate.name, "Left", newX_L, OFFSET_Y_L)

			namePlate.ArrowR:ClearAllPoints()
			namePlate.ArrowR:SetPoint("Left", namePlate.name, "Right", newX_R, OFFSET_Y_R)
		end
	end
end

-- 自身高亮图标初始化
local function InitializeSelfHighlightIcon()
	if not selfHighlightIcon then
		selfHighlightIcon = CreateFrame("Frame", "TSTargetMarkSelfHighlight", UIParent)
		local size = Automaton_TSTargetMark.db.profile.selfHighlightSize or 200
		selfHighlightIcon:SetWidth(size)
		selfHighlightIcon:SetHeight(size)
		selfHighlightIcon:SetPoint("CENTER", 0, -30) -- 临时位置，后面会根据偏移配置重新设置
		local texture = selfHighlightIcon:CreateTexture(nil, "ARTWORK")
		texture:SetAllPoints()
		texture:SetTexture(SELF_HIGHLIGHT_TEXTURE)
		texture:SetBlendMode("ADD")
		texture:SetAlpha(0.8)
		selfHighlightIcon:Hide()
	end
end

-- 更新自身高亮图标（显示/隐藏、大小、位置）
local function UpdateSelfHighlight()
	if not Automaton_TSTargetMark.db.profile.selfHighlightEnabled then
		if selfHighlightIcon then
			selfHighlightIcon:Hide()
		end
		return
	end

	InitializeSelfHighlightIcon()

	-- 更新大小
	local size = Automaton_TSTargetMark.db.profile.selfHighlightSize
	if size and size ~= selfHighlightIcon:GetWidth() then
		selfHighlightIcon:SetWidth(size)
		selfHighlightIcon:SetHeight(size)
	end

	-- 更新位置偏移
	local offsetX = Automaton_TSTargetMark.db.profile.selfHighlightOffsetX or 0
	local offsetY = Automaton_TSTargetMark.db.profile.selfHighlightOffsetY or -30
	selfHighlightIcon:ClearAllPoints()
	selfHighlightIcon:SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY)

	selfHighlightIcon:Show()
end

-- 普通模式函数
local function NormalArrowShow(namePlate)
	namePlate.Arrow:ClearAllPoints()
	namePlate.Arrow:SetPoint("BOTTOM", namePlate, "TOP", OFFSET_X, OFFSET_Y)
	namePlate.Arrow:Show()

	-- 初始化动画数据
	if not animationData.arrows[namePlate] then
		animationData.arrows[namePlate] = {
			startTime = GetTime(),
			baseY = OFFSET_Y,
		}
	end
end

local function NormalArrowHide(namePlate)
	if namePlate.Arrow then
		namePlate.Arrow:Hide()
	end
	-- 清理动画数据
	if animationData.arrows[namePlate] then
		animationData.arrows[namePlate] = nil
	end
end

-- 特别模式函数
local function SpecialArrowShow(namePlate)
	namePlate.ArrowL:ClearAllPoints()
	namePlate.ArrowL:SetPoint("Right", namePlate.name, "Left", OFFSET_X_L, OFFSET_Y_L)
	namePlate.ArrowL:Show()
	namePlate.ArrowR:ClearAllPoints()
	namePlate.ArrowR:SetPoint("Left", namePlate.name, "Right", OFFSET_X_R, OFFSET_Y_R)
	namePlate.ArrowR:Show()

	-- 初始化特殊模式动画数据（水平浮动）
	if not animationData.specialArrows[namePlate] then
		animationData.specialArrows[namePlate] = {
			startTime = GetTime(),
			baseX_L = OFFSET_X_L, -- 左箭头基准X位置
			baseX_R = OFFSET_X_R, -- 右箭头基准X位置
		}
	end
end

local function SpecialArrowHide(namePlate)
	if namePlate.ArrowL then
		namePlate.ArrowL:Hide()
	end
	if namePlate.ArrowR then
		namePlate.ArrowR:Hide()
	end
	-- 清理动画数据
	if animationData.specialArrows[namePlate] then
		animationData.specialArrows[namePlate] = nil
	end
end

local function UpdateAllArrows()
	if not Automaton_TSTargetMark.db then
		return
	end

	local specialMode = Automaton_TSTargetMark.db.profile.specialMode
	local facingStatus = GetTargetFacingStatus() -- 获取朝向状态

	if (ShaguPlates and ShaguPlates.nameplates) or (pfUI and pfUI.nameplates) then
		local index = 1
		while _G["pfNamePlate" .. index] do
			local pfNamePlate = _G["pfNamePlate" .. index]
			if specialMode then
				-- 特别模式：隐藏普通箭头，显示特别箭头
				NormalArrowHide(pfNamePlate)

				if not pfNamePlate.ArrowL then
					pfNamePlate.ArrowL = pfNamePlate.health:CreateTexture(nil, "OVERLAY")
					pfNamePlate.ArrowL:SetTexture(TargetArrowL)
					pfNamePlate.ArrowL:SetWidth(SPECIAL_TEXTURE_SIZE)
					pfNamePlate.ArrowL:SetHeight(SPECIAL_TEXTURE_SIZE)
					pfNamePlate.ArrowL:Hide()
				end
				if not pfNamePlate.ArrowR then
					pfNamePlate.ArrowR = pfNamePlate.health:CreateTexture(nil, "OVERLAY")
					pfNamePlate.ArrowR:SetTexture(TargetArrowR)
					pfNamePlate.ArrowR:SetWidth(SPECIAL_TEXTURE_SIZE)
					pfNamePlate.ArrowR:SetHeight(SPECIAL_TEXTURE_SIZE)
					pfNamePlate.ArrowR:Hide()
				end
				if pfNamePlate.istarget then
					SpecialArrowShow(pfNamePlate)
					-- 设置左右箭头颜色
					SetArrowColor(pfNamePlate.ArrowL, facingStatus)
					SetArrowColor(pfNamePlate.ArrowR, facingStatus)
				else
					SpecialArrowHide(pfNamePlate)
				end
			else
				-- 普通模式：隐藏特别箭头，显示普通箭头
				SpecialArrowHide(pfNamePlate)

				if not pfNamePlate.Arrow then
					pfNamePlate.Arrow = pfNamePlate.health:CreateTexture(nil, "OVERLAY")
					pfNamePlate.Arrow:SetTexture(TargetArrow)
					pfNamePlate.Arrow:SetWidth(TEXTURE_SIZE)
					pfNamePlate.Arrow:SetHeight(TEXTURE_SIZE + 10)
					pfNamePlate.Arrow:Hide()
				end
				if pfNamePlate.istarget then
					NormalArrowShow(pfNamePlate)
					-- 设置箭头颜色
					SetArrowColor(pfNamePlate.Arrow, facingStatus)
				else
					NormalArrowHide(pfNamePlate)
				end
			end
			index = index + 1
		end
	else
		parentcount = WorldFrame:GetNumChildren()
		if prevcount < parentcount then
			local frames = { WorldFrame:GetChildren() }
			for _, namePlate in ipairs(frames) do
				if IsNamePlateFrame(namePlate) and not cache[namePlate] then
					cache[namePlate] = namePlate
				end
			end
			prevcount = parentcount
		end

		for namePlate in cache do
			local HealthBar = namePlate:GetChildren()
			if specialMode then
				-- 特别模式：隐藏普通箭头，显示特别箭头
				NormalArrowHide(namePlate)

				if not namePlate.ArrowL then
					namePlate.ArrowL = namePlate:CreateTexture(nil, "OVERLAY")
					namePlate.ArrowL:SetTexture(TargetArrowL)
					namePlate.ArrowL:SetWidth(SPECIAL_TEXTURE_SIZE)
					namePlate.ArrowL:SetHeight(SPECIAL_TEXTURE_SIZE + 10)
					namePlate.ArrowL:Hide()
				end
				if not namePlate.ArrowR then
					namePlate.ArrowR = namePlate:CreateTexture(nil, "OVERLAY")
					namePlate.ArrowR:SetTexture(TargetArrowR)
					namePlate.ArrowR:SetWidth(SPECIAL_TEXTURE_SIZE)
					namePlate.ArrowR:SetHeight(SPECIAL_TEXTURE_SIZE + 10)
					namePlate.ArrowR:Hide()
				end
				if UnitExists("target") and HealthBar:GetAlpha() == 1 then
					SpecialArrowShow(namePlate)
					SetArrowColor(namePlate.ArrowL, facingStatus)
					SetArrowColor(namePlate.ArrowR, facingStatus)
				else
					SpecialArrowHide(namePlate)
				end
			else
				-- 普通模式：隐藏特别箭头，显示普通箭头
				SpecialArrowHide(namePlate)

				if not namePlate.Arrow then
					namePlate.Arrow = namePlate:CreateTexture(nil, "OVERLAY")
					namePlate.Arrow:SetTexture(TargetArrow)
					namePlate.Arrow:SetWidth(TEXTURE_SIZE)
					namePlate.Arrow:SetHeight(TEXTURE_SIZE + 10)
					namePlate.Arrow:Hide()
				end
				if UnitExists("target") and HealthBar:GetAlpha() == 1 then
					NormalArrowShow(namePlate)
					SetArrowColor(namePlate.Arrow, facingStatus)
				else
					NormalArrowHide(namePlate)
				end
			end
		end
	end
end

Automaton_TSTargetMark.options = {
	header1 = {
		type = "header",
		name = "箭头外观",
		order = 10,
	},
	specialMode = {
		type = "toggle",
		name = "特别模式",
		desc = "启用双箭头模式（左右各一个），不可调整",
		order = 11,
		get = function()
			return Automaton_TSTargetMark.db.profile.specialMode
		end,
		set = function(v)
			Automaton_TSTargetMark.db.profile.specialMode = v
			-- 切换模式后立即更新所有箭头
			UpdateAllArrows()
		end,
	},
	arrowSize = {
		type = "range",
		name = "箭头大小",
		desc = "设置目标箭头的显示大小",
		order = 12,
		min = 30,
		max = 100,
		step = 1,
		get = function()
			return Automaton_TSTargetMark.db.profile.arrowSize
		end,
		set = function(v)
			Automaton_TSTargetMark.db.profile.arrowSize = v
			TEXTURE_SIZE = v
			-- 实时更新所有箭头大小
			for namePlate in cache do
				if namePlate.Arrow then
					namePlate.Arrow:SetWidth(TEXTURE_SIZE)
					namePlate.Arrow:SetHeight(TEXTURE_SIZE + 10)
				end
			end
			if (ShaguPlates and ShaguPlates.nameplates) or (pfUI and pfUI.nameplates) then
				local index = 1
				while _G["pfNamePlate" .. index] do
					local pfNamePlate = _G["pfNamePlate" .. index]
					if pfNamePlate.Arrow then
						pfNamePlate.Arrow:SetWidth(TEXTURE_SIZE)
						pfNamePlate.Arrow:SetHeight(TEXTURE_SIZE + 10)
					end
					index = index + 1
				end
			end
		end,
	},
	offsetX = {
		type = "range",
		name = "X轴偏移",
		desc = "设置箭头在X轴方向的偏移量",
		order = 14,
		min = -50,
		max = 50,
		step = 1,
		get = function()
			return Automaton_TSTargetMark.db.profile.offsetX
		end,
		set = function(v)
			Automaton_TSTargetMark.db.profile.offsetX = v
			OFFSET_X = v
		end,
	},
	offsetY = {
		type = "range",
		name = "Y轴偏移",
		desc = "设置箭头在Y轴方向的偏移量",
		order = 15,
		min = 0,
		max = 50,
		step = 1,
		get = function()
			return Automaton_TSTargetMark.db.profile.offsetY
		end,
		set = function(v)
			Automaton_TSTargetMark.db.profile.offsetY = v
			OFFSET_Y = v
		end,
	},
	arrowStyle = {
		type = "range",
		name = "箭头样式",
		desc = "选择箭头的显示样式（0-25）",
		order = 13,
		min = 0,
		max = 25,
		step = 1,
		get = function()
			return Automaton_TSTargetMark.db.profile.arrowStyle
		end,
		set = function(v)
			Automaton_TSTargetMark.db.profile.arrowStyle = v
			-- 更新纹理路径
			local newTexture = MediaPath .. (v == 0 and "Arrow" or ("Arrow" .. v))
			-- 刷新所有箭头纹理
			for namePlate in cache do
				if namePlate.Arrow then
					namePlate.Arrow:SetTexture(newTexture)
				end
			end
			if (ShaguPlates and ShaguPlates.nameplates) or (pfUI and pfUI.nameplates) then
				local index = 1
				while _G["pfNamePlate" .. index] do
					local pfNamePlate = _G["pfNamePlate" .. index]
					if pfNamePlate.Arrow then
						pfNamePlate.Arrow:SetTexture(newTexture)
					end
					index = index + 1
				end
			end
		end,
	},
	header2 = {
		type = "header",
		name = "浮动动画",
		order = 20,
	},
	floatEnabled = {
		type = "toggle",
		name = "启用浮动动画",
		desc = "启用箭头浮动动画效果",
		order = 21,
		get = function()
			return Automaton_TSTargetMark.db.profile.floatEnabled
		end,
		set = function(v)
			Automaton_TSTargetMark.db.profile.floatEnabled = v
			FLOAT_CONFIG.enabled = v
		end,
	},
	floatSpeed = {
		type = "range",
		name = "浮动速度",
		desc = "设置箭头浮动动画的速度",
		order = 22,
		min = 1,
		max = 10,
		step = 0.5,
		get = function()
			return Automaton_TSTargetMark.db.profile.floatSpeed
		end,
		set = function(v)
			Automaton_TSTargetMark.db.profile.floatSpeed = v
			FLOAT_CONFIG.speed = v
		end,
	},
	floatAmplitude = {
		type = "range",
		name = "浮动幅度",
		desc = "设置箭头浮动的幅度（像素）",
		order = 23,
		min = 5,
		max = 30,
		step = 1,
		get = function()
			return Automaton_TSTargetMark.db.profile.floatAmplitude
		end,
		set = function(v)
			Automaton_TSTargetMark.db.profile.floatAmplitude = v
			FLOAT_CONFIG.amplitude = v
		end,
	},
	floatSmooth = {
		type = "toggle",
		name = "平滑动画",
		desc = "启用平滑的浮动动画效果",
		order = 24,
		get = function()
			return Automaton_TSTargetMark.db.profile.floatSmooth
		end,
		set = function(v)
			Automaton_TSTargetMark.db.profile.floatSmooth = v
			FLOAT_CONFIG.smooth = v
		end,
	},
	header3 = {
		type = "header",
		name = "自身高亮",
		order = 30,
	},
	-- 自身高亮配置
	selfHighlightEnabled = {
		type = "toggle",
		name = "启用自身高亮",
		desc = "在屏幕中央显示自身高亮图标",
		order = 31,
		get = function()
			return Automaton_TSTargetMark.db.profile.selfHighlightEnabled
		end,
		set = function(v)
			Automaton_TSTargetMark.db.profile.selfHighlightEnabled = v
			if not v and selfHighlightIcon then
				selfHighlightIcon:Hide()
			elseif v then
				UpdateSelfHighlight()
			end
		end,
	},
	selfHighlightSize = {
		type = "range",
		name = "高亮图标大小",
		desc = "设置自身高亮图标的大小",
		order = 32,
		min = 50,
		max = 400,
		step = 5,
		get = function()
			return Automaton_TSTargetMark.db.profile.selfHighlightSize
		end,
		set = function(v)
			Automaton_TSTargetMark.db.profile.selfHighlightSize = v
			if selfHighlightIcon then
				selfHighlightIcon:SetWidth(v)
				selfHighlightIcon:SetHeight(v)
			end
		end,
	},
	selfHighlightOffsetX = {
		type = "range",
		name = "高亮图标X偏移",
		desc = "设置自身高亮图标在X轴方向的偏移",
		order = 33,
		min = -500,
		max = 500,
		step = 5,
		get = function()
			return Automaton_TSTargetMark.db.profile.selfHighlightOffsetX
		end,
		set = function(v)
			Automaton_TSTargetMark.db.profile.selfHighlightOffsetX = v
			if selfHighlightIcon then
				local offsetY = Automaton_TSTargetMark.db.profile.selfHighlightOffsetY or -30
				selfHighlightIcon:ClearAllPoints()
				selfHighlightIcon:SetPoint("CENTER", UIParent, "CENTER", v, offsetY)
			end
		end,
	},
	selfHighlightOffsetY = {
		type = "range",
		name = "高亮图标Y偏移",
		desc = "设置自身高亮图标在Y轴方向的偏移",
		order = 34,
		min = -500,
		max = 500,
		step = 5,
		get = function()
			return Automaton_TSTargetMark.db.profile.selfHighlightOffsetY
		end,
		set = function(v)
			Automaton_TSTargetMark.db.profile.selfHighlightOffsetY = v
			if selfHighlightIcon then
				local offsetX = Automaton_TSTargetMark.db.profile.selfHighlightOffsetX or 0
				selfHighlightIcon:ClearAllPoints()
				selfHighlightIcon:SetPoint("CENTER", UIParent, "CENTER", offsetX, v)
			end
		end,
	},
	-- 新增：朝向颜色开关
	facingColorEnabled = {
		type = "toggle",
		name = "启用朝向颜色",
		desc = "根据目标朝向自动改变箭头颜色（正面红、背面绿）",
		order = 16,
		get = function()
			return Automaton_TSTargetMark.db.profile.facingColorEnabled
		end,
		set = function(v)
			Automaton_TSTargetMark.db.profile.facingColorEnabled = v
			FACING_COLOR_ENABLED = v
			UpdateAllArrows() -- 立即刷新颜色
		end,
	},
}

local function Arrow_OnUpdate(elapsed)
	UpdateAllArrows()
	UpdateFloatAnimation(elapsed)
	UpdateSelfHighlight()
end

-- 添加浮动动画控制命令
SLASH_TSTARGETMARK1 = "/tstargetmark"
SLASH_TSTARGETMARK2 = "/tstm"
SlashCmdList["TSTARGETMARK"] = function(msg)
	local args = {}
	if msg and msg ~= "" then
		local from = 1
		local delim_from, delim_to = string.find(msg, " ", from)
		while delim_from do
			table.insert(args, string.sub(msg, from, delim_from - 1))
			from = delim_to + 1
			delim_from, delim_to = string.find(msg, " ", from)
		end
		table.insert(args, string.sub(msg, from))
	end

	if args[1] == "float" then
		if args[2] == "on" then
			FLOAT_CONFIG.enabled = true
			Automaton_TSTargetMark.db.profile.floatEnabled = true
			print("|cff00ff00目标标记浮动动画已启用|r")
		elseif args[2] == "off" then
			FLOAT_CONFIG.enabled = false
			Automaton_TSTargetMark.db.profile.floatEnabled = false
			print("|cffff0000目标标记浮动动画已禁用|r")
		else
			print("|cffff0000使用 /tstm float on 或 /tstm float off|r")
		end
	elseif args[1] == "speed" and args[2] then
		local speed = tonumber(args[2])
		if speed and speed > 0 then
			FLOAT_CONFIG.speed = speed
			Automaton_TSTargetMark.db.profile.floatSpeed = speed
			print("|cff00ff00浮动速度设置为: " .. speed .. "|r")
		else
			print("|cffff0000无效的速度值，请输入大于0的数字|r")
		end
	elseif args[1] == "amplitude" and args[2] then
		local amplitude = tonumber(args[2])
		if amplitude and amplitude > 0 then
			FLOAT_CONFIG.amplitude = amplitude
			Automaton_TSTargetMark.db.profile.floatAmplitude = amplitude
			print("|cff00ff00浮动幅度设置为: " .. amplitude .. " 像素|r")
		else
			print("|cffff0000无效的幅度值，请输入大于0的数字|r")
		end
	elseif args[1] == "smooth" then
		if args[2] == "on" then
			FLOAT_CONFIG.smooth = true
			Automaton_TSTargetMark.db.profile.floatSmooth = true
			print("|cff00ff00平滑动画已启用|r")
		elseif args[2] == "off" then
			FLOAT_CONFIG.smooth = false
			Automaton_TSTargetMark.db.profile.floatSmooth = false
			print("|cffff0000平滑动画已禁用|r")
		else
			print("|cffff0000使用 /tstm smooth on 或 /tstm smooth off|r")
		end
	elseif args[1] == "status" then
		print("|cff00ff00目标标记浮动动画状态:|r")
		print("启用状态: " .. (FLOAT_CONFIG.enabled and "|cff00ff00是|r" or "|cffff0000否|r"))
		print("浮动速度: " .. FLOAT_CONFIG.speed)
		print("浮动幅度: " .. FLOAT_CONFIG.amplitude .. " 像素")
		print("平滑动画: " .. (FLOAT_CONFIG.smooth and "|cff00ff00是|r" or "|cffff0000否|r"))
		print("当前箭头数量: " .. (function()
			local count = 0
			for _ in pairs(animationData.arrows) do
				count = count + 1
			end
			for _ in pairs(animationData.specialArrows) do
				count = count + 1
			end
			return count
		end)())
	else
		print("|cff00ff00目标标记浮动动画命令:|r")
		print("/tstm float on/off - 启用/禁用浮动动画")
		print("/tstm speed <数值> - 设置浮动速度 (默认3.0)")
		print("/tstm amplitude <数值> - 设置浮动幅度 (默认15像素)")
		print("/tstm smooth on/off - 启用/禁用平滑动画")
		print("/tstm status - 显示当前状态")
	end
end

------------------------------
--      Module Functions      --
------------------------------

function Automaton_TSTargetMark:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("TSTargetMark")
	Automaton:RegisterDefaults("TSTargetMark", "profile", {
		disabled = false,
		arrowSize = 50,
		offsetX = 0,
		offsetY = 5,
		arrowStyle = 0, -- 默认使用Arrow纹理
		specialMode = false, -- 默认关闭特殊模式
		floatEnabled = false, -- 默认禁用浮动动画
		floatSpeed = 3,
		floatAmplitude = 15,
		floatSmooth = true,
		-- 自身高亮默认值
		selfHighlightEnabled = false,
		selfHighlightSize = 200,
		selfHighlightOffsetX = 0,
		selfHighlightOffsetY = -30,
		-- 朝向颜色默认值
		facingColorEnabled = true,
	})
	Automaton:SetDisabledAsDefault(self, "TSTargetMark")

	-- 初始化配置值
	TEXTURE_SIZE = self.db.profile.arrowSize
	OFFSET_X = self.db.profile.offsetX
	OFFSET_Y = self.db.profile.offsetY

	-- 初始化浮动动画配置
	FLOAT_CONFIG.enabled = self.db.profile.floatEnabled
	FLOAT_CONFIG.speed = self.db.profile.floatSpeed
	FLOAT_CONFIG.amplitude = self.db.profile.floatAmplitude
	FLOAT_CONFIG.smooth = self.db.profile.floatSmooth

	-- 初始化朝向颜色配置
	FACING_COLOR_ENABLED = self.db.profile.facingColorEnabled

	-- 初始化箭头纹理路径
	local style = self.db.profile.arrowStyle
	TargetArrow = MediaPath .. (style == 0 and "Arrow" or ("Arrow" .. style))

	self:RegisterOptions(self.options)
end

function Automaton_TSTargetMark:OnEnable()
	self.frame = self.frame or CreateFrame("Frame")
	self.frame:SetScript("OnUpdate", Arrow_OnUpdate)
	-- 确保自身高亮图标在启用时正确初始化（如果配置开启）
	if self.db.profile.selfHighlightEnabled then
		UpdateSelfHighlight()
	end
end

function Automaton_TSTargetMark:OnDisable()
	if self.frame then
		self.frame:SetScript("OnUpdate", nil)
	end
	-- 隐藏所有箭头
	for namePlate in cache do
		NormalArrowHide(namePlate)
		SpecialArrowHide(namePlate)
	end
	if (ShaguPlates and ShaguPlates.nameplates) or (pfUI and pfUI.nameplates) then
		local index = 1
		while _G["pfNamePlate" .. index] do
			local pfNamePlate = _G["pfNamePlate" .. index]
			NormalArrowHide(pfNamePlate)
			SpecialArrowHide(pfNamePlate)
			index = index + 1
		end
	end
	-- 清空动画数据
	animationData.arrows = {}
	animationData.specialArrows = {}
	-- 隐藏自身高亮图标
	if selfHighlightIcon then
		selfHighlightIcon:Hide()
	end
end
