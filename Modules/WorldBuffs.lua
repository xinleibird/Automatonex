assert(Automaton, "Automaton not found!")

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_WorldBuffs = Automaton:NewModule("WorldBuffs")
Automaton_WorldBuffs.modulename = "世界BUFF通告"
Automaton_WorldBuffs.moduledesc = "世界BUFF通告倒计时"
Automaton_WorldBuffs.options = {
	sound = {
		type = "toggle",
		name = "播放提示音",
		desc = "触发时播放提示音",
		order = 2,
		get = function()
			return Automaton_WorldBuffs.db.profile.sound
		end,
		set = function(v)
			Automaton_WorldBuffs.db.profile.sound = v
		end,
	},
	showbar = {
		type = "toggle",
		name = "倒计时提醒",
		desc = "屏幕中央闪烁倒计时提醒",
		order = 3,
		get = function()
			return Automaton_WorldBuffs.db.profile.showbar
		end,
		set = function(v)
			Automaton_WorldBuffs.db.profile.showbar = v
		end,
	},
	guild = {
		type = "toggle",
		name = "公会通告",
		desc = "触发时在公会通告",
		order = 4,
		get = function()
			return Automaton_WorldBuffs.db.profile.guild
		end,
		set = function(v)
			Automaton_WorldBuffs.db.profile.guild = v
		end,
	},
	showhotel = {
		type = "toggle",
		name = "显示炉石按钮",
		desc = "当龙头信息倒计时出现的时候弹出炉石按钮，方便快速回城\n当计时小于10秒后自动隐藏。",
		order = 5,
		get = function()
			return Automaton_WorldBuffs.db.profile.showhotel
		end,
		set = function(v)
			Automaton_WorldBuffs.db.profile.showhotel = v
		end,
	},
	autoLogout = {
		type = "toggle",
		name = "自动登出",
		desc = "获得世界BUFF后自动登出游戏",
		order = 6,
		get = function()
			return Automaton_WorldBuffs.db.profile.autoLogout
		end,
		set = function(v)
			Automaton_WorldBuffs.db.profile.autoLogout = v
		end,
	},
	autoExit = {
		type = "toggle",
		name = "自动退出游戏",
		desc = "获得世界BUFF后自动退出游戏",
		order = 7,
		get = function()
			return Automaton_WorldBuffs.db.profile.autoExit
		end,
		set = function(v)
			Automaton_WorldBuffs.db.profile.autoExit = v
		end,
	},
}

------------------------------
--      Initialization      --
------------------------------
local config = {}
local pattern = "^MPWB:(.+):(.+)$"
local icon = [[Interface\Icons\INV_Misc_Head_Dragon_01]]
local hotelicon = [[Interface\Icons\INV_Misc_Rune_01]]
local timer
local SOUND_PATH = "Interface\\AddOns\\Automatonex\\Sound\\sound1.ogg" -- 定义音效路径

-- 自动下线相关变量
Automaton_WorldBuffs.logoutAt = nil
Automaton_WorldBuffs.logoutFrame = nil

if GetLocale() == "zhCN" then
	config = {
		Alliance = {
			Onyxia = { name = "玛丁雷少校", yell = "向我们的英雄们致敬", msg = "【联盟】黑龙" },
			Nefarian = {
				name = "艾法希比元帅",
				yell = "黑石之王已经被干掉了",
				msg = "【联盟】奈法",
			},
		},
		Horde = {
			Onyxia = { name = "伦萨克", yell = "奥妮克希亚已经被斩杀了", msg = "【部落】黑龙" },
			Nefarian = { name = "萨鲁法尔大王", yell = "奈法利安被杀掉了", msg = "【部落】奈法" },
		},
	}
else
	config = {
		Alliance = {
			Onyxia = { name = "Major Mattingly", yell = "history has been made", msg = "【联盟】黑龙" },
			Nefarian = {
				name = "Field Marshal Afrasiabi",
				yell = "the Lord of Blackrock is slain",
				msg = "【联盟】奈法",
			},
		},
		Horde = {
			Onyxia = { name = "Overlord Runthak", yell = "Onyxia, has been slain", msg = "【部落】黑龙" },
			Nefarian = { name = "High Overlord Saurfang", yell = "NEFARIAN IS SLAIN", msg = "【部落】奈法" },
		},
	}
end

-- 自定义音效播放函数
local function PlayCustomSound()
	if Automaton_WorldBuffs.db.profile.sound then
		-- 使用WoW标准函数播放自定义音效
		PlaySoundFile(SOUND_PATH, "Master")
	end
end

-- 通过物品ID查找物品
local function FindItemByID(itemID)
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			local itemLink = GetContainerItemLink(bag, slot)
			if itemLink then
				local foundID = tonumber(string.match(itemLink, "item:(%d+):"))
				if foundID and foundID == itemID then
					return bag, slot
				end
			end
		end
	end
end

function Automaton_WorldBuffs:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("WorldBuffs")
	Automaton:RegisterDefaults("WorldBuffs", "profile", {
		disabled = false,
		showbar = true,
		sound = true,
		guild = false,
		showhotel = true,
		autoLogout = false,
		autoExit = false,
	})
	Automaton:SetDisabledAsDefault(self, "WorldBuffs")
	self:RegisterOptions(self.options)

	-- 创建自动下线框架
	self.logoutFrame = CreateFrame("Frame")
	self.logoutFrame:Hide()
	self.logoutFrame:SetScript("OnUpdate", function()
		self:LogoutFrame_OnUpdate()
	end)
end

function Automaton_WorldBuffs:OnEnable()
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("CHAT_MSG_CHANNEL")
	self.logoutFrame:Show()
end

function Automaton_WorldBuffs:OnDisable()
	self:UnregisterAllEvents()
	self.logoutFrame:Hide()
	self.logoutAt = nil
end

-- 自动下线框架的OnUpdate处理
function Automaton_WorldBuffs:LogoutFrame_OnUpdate()
	if (self.db.profile.autoLogout or self.db.profile.autoExit) and self.logoutAt and GetTime() >= self.logoutAt then
		self.logoutAt = nil

		if self.db.profile.autoLogout then
			self:Print("正在登出...")
			Logout() -- 执行登出
		else
			self:Print("正在退出游戏...")
			Quit() -- 执行退出游戏
		end

		-- 自动禁用功能并提示
		if self.db.profile.autoLogout then
			self.db.profile.autoLogout = false
		end

		if self.db.profile.autoExit then
			self.db.profile.autoExit = false
		end
	end
end

------------------------------
--      Event Handlers      --
------------------------------
-- 只监控自己阵容的NPC喊话
function Automaton_WorldBuffs:CHAT_MSG_MONSTER_YELL()
	if not self.faction then
		self.faction = UnitFactionGroup("player")
	end
	for name, info in pairs(config[self.faction]) do
		if arg2 == info.name and strfind(arg1, info.yell) then
			SendChatMessage("MPWB:" .. name .. ":" .. self.faction, "CHANNEL", nil, GetChannelName("LFT"))
		end
	end
end

-- 提醒框架
local caution = CreateFrame("Frame", "AutomatonWorldBuffsCaution", UIParent)
caution.string = caution:CreateFontString("AutomatonWorldBuffsText", "BACKGROUND")
caution.string:SetPoint("CENTER", UIParent, "CENTER", 0, 260)
caution.string:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
caution.string:SetDrawLayer("ARTWORK")
caution.string:SetTextHeight(20)
caution:Hide()

-- 炉石按钮
local hotelButton

-- 创建炉石按钮（无边框版本）
local function CreateHotelButton()
	hotelButton = CreateFrame("Button", "AutomatonWorldBuffsHotel", UIParent)
	hotelButton:SetWidth(40)
	hotelButton:SetHeight(40)
	hotelButton:SetPoint("CENTER", UIParent, "CENTER", 0, 200)

	-- 创建图标纹理，不使用ActionButtonTemplate
	local iconTexture = hotelButton:CreateTexture(nil, "BACKGROUND")
	iconTexture:SetAllPoints()
	iconTexture:SetTexture(hotelicon)

	-- 添加鼠标悬停效果
	hotelButton:SetScript("OnEnter", function()
		iconTexture:SetAlpha(0.8)
	end)

	hotelButton:SetScript("OnLeave", function()
		iconTexture:SetAlpha(1.0)
	end)

	hotelButton:SetScript("OnMouseDown", function()
		iconTexture:SetAlpha(0.6)
	end)

	hotelButton:SetScript("OnMouseUp", function()
		iconTexture:SetAlpha(0.8)
	end)

	hotelButton:SetScript("OnClick", function()
		-- 优先使用物品ID 6948查找炉石
		local bag, slot = FindItemByID(6948)

		-- 如果没有找到，则使用名称查找
		if not bag then
			for bag = 0, NUM_BAG_SLOTS do
				for slot = 1, GetContainerNumSlots(bag) do
					local itemLink = GetContainerItemLink(bag, slot)
					if itemLink then
						local name = GetItemInfo(itemLink)
						if name and (name == "炉石" or name == "Hearthstone") then
							UseContainerItem(bag, slot)
							return
						end
					end
				end
			end
		else
			UseContainerItem(bag, slot)
		end
	end)
	hotelButton:Hide()
end

-- 显示炉石按钮
local function ShowHotelButton()
	if not hotelButton then
		CreateHotelButton()
	end

	if Automaton_WorldBuffs.db.profile.showhotel then
		hotelButton:Show()

		-- 10秒后自动隐藏
		C_Timer.After(10, function()
			if hotelButton then
				hotelButton:Hide()
			end
		end)
	end
end

-- 渐变效果变量
local isFadingOut = true

-- 计时器变量
local countdownTime = 0
local countdownActive = false

-- 使用第一个代码的OnUpdate脚本，确保倒计时正常工作
caution:SetScript("OnUpdate", function()
	if not caution:IsShown() then
		return
	end
	if not this.elapsed then
		this.elapsed = 0
	end

	-- 处理颜色渐变
	if isFadingOut then
		this.elapsed = this.elapsed + arg1
	else
		this.elapsed = this.elapsed - arg1
	end
	if this.elapsed >= 1 then
		this.elapsed = 1
		isFadingOut = false
	elseif this.elapsed <= 0 then
		isFadingOut = true
		this.elapsed = 0
	end

	-- 处理倒计时
	if countdownActive then
		countdownTime = countdownTime - arg1
		if countdownTime <= 0 then
			countdownActive = false
			caution:Hide()
		end
		-- 更新倒计时文本
		local currentText = caution.string:GetText()
		if currentText then
			local prefix = string.match(currentText, "(.+)，还有%d+秒")
			if prefix then
				caution.string:SetText(prefix .. "，还有" .. math.floor(countdownTime) .. "秒")
			end
		end

		-- 当倒计时小于10秒时隐藏炉石按钮
		if countdownTime < 10 and hotelButton and hotelButton:IsShown() then
			hotelButton:Hide()
		end
	end

	caution.string:SetTextColor(this.elapsed, 1, 0, this.elapsed)
end)

function Automaton_WorldBuffs:CHAT_MSG_CHANNEL()
	if not self.faction then
		self.faction = UnitFactionGroup("player")
	end
	if string.lower(arg9) == "lft" then
		local _, _, name, faction = strfind(arg1, pattern)
		if name and faction and faction == self.faction then
			if timer and timer - GetTime() > 0 then
				return
			end
			timer = GetTime() + 2
			if self.db.profile.showbar then
				-- 设置倒计时并显示
				countdownTime = 18
				countdownActive = true
				local buffMsg = config[faction][name] and config[faction][name].msg or name
				caution.string:SetText(
					"注意！" .. buffMsg .. " Buff倒计时，还有" .. math.floor(countdownTime) .. "秒"
				)
				caution:Show()
			end
			if self.db.profile.sound then
				PlayCustomSound() -- 使用统一的音效播放函数
			end
			if self.db.profile.guild then
				local buffMsg = config[faction][name] and config[faction][name].msg or name
				SendChatMessage("注意！" .. buffMsg .. " Buff倒计时，还有18秒", "GUILD")
			end
			if self.db.profile.showhotel then
				ShowHotelButton()
			end

			-- 设置自动下线定时器
			if self.db.profile.autoLogout or self.db.profile.autoExit then
				local message = self.db.profile.autoExit
						and "即将获得世界BUFF，自动退出功能已启用。将在1分钟后退出游戏。"
					or "即将获得世界BUFF，自动登出功能已启用。将在1分钟后登出。"
				self:Print(message)
				self.logoutAt = GetTime() + 60 -- 60秒后执行
			end
		end
	end
end

-- 测试命令
SLASH_TESTWORLDBUFF1 = "/wbtest"
SlashCmdList["TESTWORLDBUFF"] = function(msg)
	local faction = UnitFactionGroup("player")
	local dragonType = msg and msg ~= "" and msg or "Onyxia"

	if config[faction] and config[faction][dragonType] then
		-- 设置倒计时并显示
		countdownTime = 18
		countdownActive = true
		local buffMsg = config[faction][dragonType].msg
		caution.string:SetText(
			"注意！" .. buffMsg .. " Buff倒计时，还有" .. math.floor(countdownTime) .. "秒"
		)
		caution:Show()

		PlayCustomSound() -- 测试命令也使用统一音效函数
		print("测试世界BUFF: " .. buffMsg)

		-- 测试炉石按钮
		if Automaton_WorldBuffs.db.profile.showhotel then
			ShowHotelButton()
		end

		-- 测试自动下线功能
		if Automaton_WorldBuffs.db.profile.autoLogout or Automaton_WorldBuffs.db.profile.autoExit then
			local message = Automaton_WorldBuffs.db.profile.autoExit
					and "测试自动退出功能已启用。将在1分钟后退出游戏。"
				or "测试自动登出功能已启用。将在1分钟后登出。"
			Automaton_WorldBuffs:Print(message)
			Automaton_WorldBuffs.logoutAt = GetTime() + 60
		end
	else
		print("无效的龙头类型，请使用 Onyxia 或 Nefarian")
	end
end
