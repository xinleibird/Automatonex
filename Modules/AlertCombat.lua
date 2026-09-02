assert(Automaton, "Automaton not found!")

----------------------------------
--      Module Declaration      --
----------------------------------

Automaton_AlertCombat = Automaton:NewModule("AlertCombat")
Automaton_AlertCombat.modulename = "战斗提示"
Automaton_AlertCombat.moduledesc = "战斗时屏幕打印提示"
Automaton_AlertCombat.options = {
	header1 = {
		type = "header",
		name = "战斗提示",
		order = 10,
	},
	enableSound = {
		type = "toggle",
		name = "进入战斗提示音",
		order = 11,
		desc = "进入战斗时是否播放提示音",
		get = function()
			return Automaton_AlertCombat.db.profile.enableSound
		end,
		set = function(v)
			Automaton_AlertCombat.db.profile.enableSound = v
			if Automaton.SaveDatabase then
				Automaton.SaveDatabase("AutomatonDB")
			end
		end,
	},
	enableDeathAlert = {
		type = "toggle",
		name = "死亡娱乐消息",
		desc = "死亡时是否显示幽默/鼓励性提示消息",
		order = 12,
		get = function()
			return Automaton_AlertCombat.db.profile.enableDeathAlert
		end,
		set = function(v)
			Automaton_AlertCombat.db.profile.enableDeathAlert = v
			if Automaton.SaveDatabase then
				Automaton.SaveDatabase("AutomatonDB")
			end
		end,
	},
	enablePetAlert = {
		type = "toggle",
		name = "宠物血量预警",
		desc = "宠物血量过低时提示",
		order = 13,
		get = function()
			return Automaton_AlertCombat.db.profile.enablePetAlert
		end,
		set = function(v)
			Automaton_AlertCombat.db.profile.enablePetAlert = v
			if Automaton.SaveDatabase then
				Automaton.SaveDatabase("AutomatonDB")
			end
		end,
	},
	enablePetHappiness = {
		type = "toggle",
		name = "宠物快乐值预警",
		desc = "宠物快乐值低时提示",
		order = 14,
		get = function()
			return Automaton_AlertCombat.db.profile.enablePetHappiness
		end,
		set = function(v)
			Automaton_AlertCombat.db.profile.enablePetHappiness = v
			if Automaton.SaveDatabase then
				Automaton.SaveDatabase("AutomatonDB")
			end
		end,
	},
	-- ========== 新增仇恨预警选项 ==========
	header2 = {
		type = "header",
		name = "仇恨预警",
		order = 20,
	},
	enableAggroAlert = {
		type = "toggle",
		name = "仇恨预警（需Superwow模组）",
		order = 21,
		desc = "当怪物目标为你时在屏幕中央显示警告",
		get = function()
			return Automaton_AlertCombat.db.profile.enableAggroAlert
		end,
		set = function(v)
			Automaton_AlertCombat.db.profile.enableAggroAlert = v
			if Automaton.SaveDatabase then
				Automaton.SaveDatabase("AutomatonDB")
			end
			-- 动态启用/禁用检查（仅当友方盯梢提醒也未开启时才停止）
			if v then
				Automaton_AlertCombat:StartAggroCheck()
			elseif not Automaton_AlertCombat.db.profile.enableFriendlyTargetAlert then
				Automaton_AlertCombat:StopAggroCheck()
			end
		end,
	},
	aggroAutoFade = {
		type = "toggle",
		name = "自动渐隐术",
		desc = "检测到仇恨时自动施放渐隐术（仅牧师）",
		order = 22,
		get = function()
			return Automaton_AlertCombat.db.profile.aggroAutoFade
		end,
		set = function(v)
			Automaton_AlertCombat.db.profile.aggroAutoFade = v
			if Automaton.SaveDatabase then
				Automaton.SaveDatabase("AutomatonDB")
			end
		end,
	},
	aggroCooldown = {
		type = "range",
		name = "预警冷却(秒)",
		desc = "两次预警之间的最短间隔",
		order = 23,
		min = 5,
		max = 60,
		step = 1,
		get = function()
			return Automaton_AlertCombat.db.profile.aggroCooldown
		end,
		set = function(v)
			Automaton_AlertCombat.db.profile.aggroCooldown = v
			if Automaton.SaveDatabase then
				Automaton.SaveDatabase("AutomatonDB")
			end
		end,
	},
	aggroSound = {
		type = "toggle",
		name = "预警提示音",
		desc = "预警时播放提示音",
		order = 24,
		get = function()
			return Automaton_AlertCombat.db.profile.aggroSound
		end,
		set = function(v)
			Automaton_AlertCombat.db.profile.aggroSound = v
			if Automaton.SaveDatabase then
				Automaton.SaveDatabase("AutomatonDB")
			end
		end,
	},
	-- ========== 新增：友方盯梢提醒（友方目标是你时提示「有人偷瞄了你」） ==========
	enableFriendlyTargetAlert = {
		type = "toggle",
		name = "友方盯梢提醒",
		desc = "当友方玩家目标是你时，提示「有人偷瞄了你」",
		order = 25,
		get = function()
			return Automaton_AlertCombat.db.profile.enableFriendlyTargetAlert
		end,
		set = function(v)
			Automaton_AlertCombat.db.profile.enableFriendlyTargetAlert = v
			if Automaton.SaveDatabase then
				Automaton.SaveDatabase("AutomatonDB")
			end
			-- 动态启用/禁用检查（仅当 OT 预警也未开启时才停止）
			if v then
				Automaton_AlertCombat:StartAggroCheck()
			elseif not Automaton_AlertCombat.db.profile.enableAggroAlert then
				Automaton_AlertCombat:StopAggroCheck()
			end
		end,
	},
}

------------------------------
--      Initialization      --
------------------------------
function Automaton_AlertCombat:OnInitialize()
	-- 确保全局变量正确初始化并赋回全局，否则首次加载时数据无法持久化到 SavedVariables
	AutomatonDB = AutomatonDB or {}
	self.db = AutomatonDB
	self.db.profile = self.db.profile
		or {
			enableSound = false,
			enableDeathAlert = true,
			enablePetAlert = true,
			enablePetHappiness = true,
			-- 宠物食物相关字段已迁移到角色专属，不再在此处定义默认值
			-- 新增仇恨预警默认值
			enableAggroAlert = false,
			aggroAutoFade = true,
			aggroCooldown = 30,
			aggroSound = true,
			-- 友方盯梢提醒默认值（关闭）
			enableFriendlyTargetAlert = false,
		}

	-- ====== 角色专属存储 ======
	-- 关键：必须把新表赋回全局 AutomatonDBChar，否则数据写入了局部新表、
	-- 退出时 WoW 保存的全局变量仍是 nil，食物设置无法按角色保存
	AutomatonDBChar = AutomatonDBChar or {}
	self.dbChar = AutomatonDBChar
	if not self.dbChar.AlertCombat then
		self.dbChar.AlertCombat = {}
	end

	-- 迁移旧数据（从全局到角色专属）
	if self.db.profile.petFoodName and not self.dbChar.AlertCombat.petFoodName then
		self.dbChar.AlertCombat.petFoodName = self.db.profile.petFoodName
		self.dbChar.AlertCombat.petFoodTexture = self.db.profile.petFoodTexture
		self.dbChar.AlertCombat.feedButtonPosition = self.db.profile.feedButtonPosition
		-- 清除旧全局数据
		self.db.profile.petFoodName = nil
		self.db.profile.petFoodTexture = nil
		self.db.profile.feedButtonPosition = nil
		if Automaton.SaveDatabase then
			Automaton.SaveDatabase("AutomatonDB")
		end
	end
	-- 如果角色专属没有位置信息，设置默认位置
	if not self.dbChar.AlertCombat.feedButtonPosition then
		self.dbChar.AlertCombat.feedButtonPosition = {
			point = "CENTER",
			relativePoint = "CENTER",
			xOfs = 0,
			yOfs = -100,
		}
	end

	-- 死亡提示消息列表
	self.deathMessages = {
		"你菜得就像蔡徐坤",
		"你的操作真是下饭",
		"建议删除角色重新开始",
		"这波操作我给0分",
		"队友看了直摇头",
		"你的装备是纸糊的吗？",
		"建议去新手村再练练",
		"BOSS都看不下去了",
		"你的走位真是风骚",
		"这都能死？",
		"你的技术有待提高",
		"建议换个游戏玩",
		"你的操作让我想起了我奶奶",
		"这波操作堪称经典反面教材",
		"队友：带不动带不动",
		"你的血量像过山车一样刺激",
		"建议找个师傅带带",
		"你的技术真是稳定发挥",
		"这波操作可以上搞笑集锦了",
		"你的走位真是精准接技能",
		"没关系，失败是成功之母",
		"站起来，勇士！",
		"下次一定会更好！",
		"这只是暂时的挫折",
		"休息一下，再战！",
		"你已经很努力了",
		"每一次失败都是成长的机会",
		"不要气馁，继续加油！",
		"这只是游戏，享受过程",
		"你的坚持值得赞赏",
		"站起来，继续战斗！",
		"每一次倒下都是为了更好的站起",
		"你已经进步了很多",
		"不要放弃，胜利就在前方",
		"这只是小挫折，你能行！",
		"你的勇气令人敬佩",
		"休息一下，调整状态再战",
		"失败是通往成功的阶梯",
		"你已经做得很好了",
		"继续努力，你会变得更强大",
	}

	-- 用局部变量捕获模块对象，用于所有回调
	local module = self

	self:RegisterOptions(self.options)
	self.frame = CreateFrame("Frame")
	self.frame:Hide()
	self.frame.Bg = self.frame:CreateTexture(nil, "BACKGROUND")
	self.frame.Bg:SetTexture("Interface\\AddOns\\Automatonex\\Texture\\CombatBG.blp")
	self.frame.Bg:Show()
	self.frame.Bg:SetPoint("TOP", "UIParent", 0, -170)
	self.frame.Bg:SetWidth(150)
	self.frame.Bg:SetHeight(65)
	self.frame.Bg:SetVertexColor(1, 1, 0, 0.6)
	self.frame.text = self.frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	self.frame.text:SetFont(STANDARD_TEXT_FONT, 20)
	self.frame.text:SetPoint("CENTER", self.frame.Bg, "CENTER", 0, 3)

	self.stimer = 0
	self.totalTime = 5
	self.lastShowTime = 0
	self.lastPetAlert = 0
	self.lastPetHappinessAlert = 0
	self.lastPetDeathAlert = 0
	self.isDead = false

	-- ========== 创建仇恨预警专用框架 ==========
	self.aggroFrame = CreateFrame("Frame", nil, UIParent)
	self.aggroFrame:SetWidth(700)
	self.aggroFrame:SetHeight(80)
	self.aggroFrame:SetPoint("TOP", UIParent, "TOP", 0, -60)
	self.aggroFrame:SetFrameStrata("HIGH")
	self.aggroFrame:Hide()

	self.aggroText = self.aggroFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	self.aggroText:SetPoint("CENTER", self.aggroFrame, "CENTER", 0, 0)
	self.aggroText:SetFont("Fonts\\FRIZQT__.TTF", 22, "OUTLINE")
	self.aggroText:SetTextColor(1, 0.9, 0, 1)

	self.aggroSubText = self.aggroFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	self.aggroSubText:SetPoint("TOP", self.aggroText, "BOTTOM", 0, -4)
	self.aggroSubText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
	self.aggroSubText:SetTextColor(1, 0.5, 0.1, 1)

	self.aggroFadeTimer = 0
	self.lastAggroAlert = 0
	self.lastFriendlyAlert = 0

	self.aggroFrame:SetScript("OnUpdate", function()
		if self.aggroFadeTimer > 0 then
			self.aggroFadeTimer = self.aggroFadeTimer - arg1
			if self.aggroFadeTimer <= 0 then
				self.aggroFrame:Hide()
				self.aggroText:SetText("")
				self.aggroSubText:SetText("")
			end
		end
	end)

	self:InitPetFeeding()
end

function Automaton_AlertCombat:OnEnable()
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_DEAD")
	self:RegisterEvent("PLAYER_ALIVE")
	self:RegisterEvent("UNIT_AURA")
	self:RegisterEvent("UNIT_HEALTH")
	self:RegisterEvent("UNIT_MAXHEALTH")
	self:RegisterEvent("UNIT_HAPPINESS")
	self:RegisterEvent("UNIT_PET")
	self:RegisterEvent("BAG_UPDATE") -- 新增：监听背包变化，实时刷新喂食按钮数量

	self.checkTimer = C_Timer.NewTicker(0.1, function()
		self:CheckHideAlert()
	end)

	self.petCheckTimer = C_Timer.NewTicker(1, function()
		self:CheckPetHealth()
		self:CheckPetHappiness()
		self:CheckPetDeath()
	end)

	-- ========== 启动仇恨检查（OT预警 或 友方盯梢提醒 任一开启即启动） ==========
	if self.db.profile.enableAggroAlert or self.db.profile.enableFriendlyTargetAlert then
		self:StartAggroCheck()
	end
end

function Automaton_AlertCombat:OnDisable()
	self:UnregisterAllEvents()
	if self.checkTimer then
		self.checkTimer:Cancel()
	end
	if self.petCheckTimer then
		self.petCheckTimer:Cancel()
	end
	if self.aggroCheckTimer then
		self.aggroCheckTimer:Cancel()
	end
	if self.feedButton then
		self.feedButton:Hide()
	end
	if self.feedButtonFrame then
		self.feedButtonFrame:Hide()
	end
	if self.aggroFrame then
		self.aggroFrame:Hide()
	end
end

function Automaton_AlertCombat:StartAggroCheck()
	if self.aggroCheckTimer then
		self.aggroCheckTimer:Cancel()
	end
	self.aggroCheckTimer = C_Timer.NewTicker(0.5, function()
		self:CheckAggro()
	end)
end

function Automaton_AlertCombat:StopAggroCheck()
	if self.aggroCheckTimer then
		self.aggroCheckTimer:Cancel()
		self.aggroCheckTimer = nil
	end
end

-- ========== 友方玩家盯梢扫描（不依赖名字板） ==========
-- 根因说明：本客户端 frame:GetName(1) 返回的是名字板单位 GUID（Nampower v2.28+），
-- 即只有显示了名字板的单位才会被帧扫描看到；pfUI 友方名字板默认关闭(showfriendly=0)，
-- 友方玩家永远扫不到。此处改用标准 unit token（目标/悬停/小队/团队）做可靠扫描。
function Automaton_AlertCombat:ScanFriendlyWatchers()
	local playerName = UnitName("player")
	if not playerName then
		return nil
	end

	-- 候选单位：当前目标、鼠标悬停、小队、团队
	local candidates = { "target", "mouseover" }
	local n = GetNumPartyMembers() or 0
	for i = 1, n do
		table.insert(candidates, "party" .. i)
	end
	local rn = GetNumRaidMembers() or 0
	for i = 1, rn do
		table.insert(candidates, "raid" .. i)
	end

	for i = 1, table.getn(candidates) do
		local unit = candidates[i]
		local oku, exists = pcall(UnitExists, unit)
		if oku and exists then
			-- 排除自己（如自己目标了自己）
			local oku2, isSelf = pcall(UnitIsUnit, unit, "player")
			if not (oku2 and isSelf) then
				-- 友方判定用 UnitIsFriend（对玩家/NPC/宠物均可靠），不要依赖 UnitCanAttack
				local okf, isFriend = pcall(UnitIsFriend, "player", unit)
				if okf and isFriend then
					local okt, texists = pcall(UnitExists, unit .. "target")
					if okt and texists then
						local tname = UnitName(unit .. "target")
						if tname == playerName then
							return UnitName(unit) or "某人"
						end
					end
				end
			end
		end
	end
	return nil
end

-- ========== 仇恨检查核心 ==========
function Automaton_AlertCombat:CheckAggro()
	if not self.db.profile.enableAggroAlert and not self.db.profile.enableFriendlyTargetAlert then
		return
	end
	if UnitIsDeadOrGhost("player") then
		return
	end

	local now = GetTime()
	local cooldown = self.db.profile.aggroCooldown or 30

	local playerName = UnitName("player")
	local mobName = ""
	local friendlyName = ""
	local foundHostile = false
	local foundFriendly = false

	local f = EnumerateFrames()
	while f do
		if f.IsVisible and f:IsVisible() then
			local unitToken = f.GetName and f:GetName(1)
			if unitToken then
				-- 安全检测单位是否存在
				local ok, exists = pcall(UnitExists, unitToken)
				if ok and exists then
					-- 阵营判定：友方(UnitIsFriend)优先，绝不进 OT 分支
					-- 注意：pcall 返回 (success, value1, ...)，第二个返回值才是 API 的真正结果
					local okf, isFriend = pcall(UnitIsFriend, "player", unitToken)
					local okc, canAttack = pcall(UnitCanAttack, "player", unitToken)
					local targetUnit = unitToken .. "target"
					local ok2, targetExists = pcall(UnitExists, targetUnit)
					if ok2 and targetExists then
						local targetName = UnitName(targetUnit)
						if targetName == playerName then
							if okf and isFriend then
								-- 友方单位（玩家/NPC/宠物）目标是你 → 偷瞄提醒，绝不显示 OT
								if unitToken ~= "player" then
									friendlyName = UnitName(unitToken) or "某人"
									foundFriendly = true
								end
							elseif okc and canAttack then
								-- 敌对/可攻击单位（怪物）目标是你 → OT 警告
								mobName = UnitName(unitToken) or "未知目标"
								foundHostile = true
							end
						end
					end
				end
			end
		end
		f = EnumerateFrames(f)
	end

	-- 友方玩家盯梢补充扫描：
	-- 帧扫描只能看到有名字板的单位（友方名字板默认关闭），所以再用
	-- 当前目标/鼠标悬停/小队/团队 等 unit token 做一次可靠扫描
	if not foundFriendly and self.db.profile.enableFriendlyTargetAlert then
		local watcher = self:ScanFriendlyWatchers()
		if watcher then
			friendlyName = watcher
			foundFriendly = true
		end
	end

	-- 优先显示危险的 OT 警告；否则若友方盯梢提醒开启则显示「有人偷瞄了你」
	if foundHostile and self.db.profile.enableAggroAlert then
		if now - (self.lastAggroAlert or 0) >= cooldown then
			self:ShowAggroAlert(mobName)
		end
	elseif foundFriendly and self.db.profile.enableFriendlyTargetAlert then
		if now - (self.lastFriendlyAlert or 0) >= cooldown then
			self:ShowFriendlyTargetAlert(friendlyName)
		end
	end
end

function Automaton_AlertCombat:ShowAggroAlert(mobName)
	self.lastAggroAlert = GetTime()

	-- 设置显示文本
	self.aggroText:SetText("【OT警告】" .. mobName .. " 目标是你！")
	self.aggroSubText:SetText("立刻停手  /  开保命技能")
	self.aggroFadeTimer = 5 -- 显示5秒后淡出
	self.aggroFrame:Show()

	-- 播放提示音（如果启用）
	if self.db.profile.aggroSound then
		PlaySoundFile("Interface\\AddOns\\Automatonex\\Sound\\targetyou.ogg")
	end

	-- 自动渐隐术（仅牧师且选项开启）
	if self.db.profile.aggroAutoFade and UnitClass("player") == "牧师" then
		-- 检查是否已学会渐隐术
		local isKnown = false
		for i = 1, 150 do
			local spellName = GetSpellName(i, "spell")
			if spellName == "渐隐术" then
				isKnown = true
				break
			end
		end
		if isKnown then
			SpellStopCasting()
			CastSpellByName("渐隐术")
		end
	end
end

-- ========== 友方盯梢提醒 ==========
function Automaton_AlertCombat:ShowFriendlyTargetAlert(name)
	self.lastFriendlyAlert = GetTime()

	-- 设置显示文本
	self.aggroText:SetText("有人偷瞄了你")
	self.aggroSubText:SetText(name and (name .. " 正在注视着你") or "有人在盯着你")
	self.aggroFadeTimer = 5 -- 显示5秒后淡出
	self.aggroFrame:Show()

	-- 播放提示音（如果启用，复用 OT 预警提示音开关）
	if self.db.profile.aggroSound then
		PlaySoundFile("Interface\\AddOns\\Automatonex\\Sound\\targetyou.ogg")
	end
end

function Automaton_AlertCombat:CheckHideAlert()
	if self.frame:IsShown() then
		self.stimer = self.stimer + 0.1
		if self.stimer > self.totalTime then
			self.frame:Hide()
		elseif self.stimer <= 0.5 then
			self.frame:SetAlpha(self.stimer * 2)
		elseif self.stimer > 2 then
			self.frame:SetAlpha(1 - self.stimer / self.totalTime)
		end
	end
end

local function IsPlayerFeignDeath()
	for i = 1, 40 do
		local buffName = UnitBuff("player", i)
		if buffName then
			local feignNames = {
				["假死"] = true,
				["Feign Death"] = true,
			}
			if feignNames[buffName] then
				return true
			end
		end
	end
	return false
end

function Automaton_AlertCombat:PLAYER_REGEN_ENABLED()
	if not self.isDead and not UnitIsGhost("player") then
		self.frame.Bg:Show()
		self.frame.text:SetText("离开战斗")
		self.frame.text:SetTextColor(0, 1, 0)
		self.frame:Show()
		self.stimer = 0
	end
end

function Automaton_AlertCombat:PLAYER_REGEN_DISABLED()
	if not self.isDead then
		self.frame.Bg:Show()
		self.frame.text:SetText("进入战斗")
		self.frame.text:SetTextColor(1, 0, 0)
		self.frame:Show()
		self.stimer = 0
		if self.db and self.db.profile and self.db.profile.enableSound then
			self:enableSound()
		end
	end
end

function Automaton_AlertCombat:enableSound()
	PlaySoundFile("Interface\\AddOns\\Automatonex\\Sound\\Enter the battle.mp3")
end

function Automaton_AlertCombat:PLAYER_DEAD()
	self.isDead = true
	self.frame.Bg:Hide()

	if not self.db.profile.enableDeathAlert then
		self.frame:Hide()
		return
	end

	local deathMessagesCount = table.getn(self.deathMessages)
	local randomIndex = math.random(1, deathMessagesCount)
	local deathMessage = self.deathMessages[randomIndex]

	if randomIndex > 20 then
		self.frame.text:SetTextColor(0, 1, 0)
	else
		self.frame.text:SetTextColor(1, 0, 0)
	end

	self.frame.text:SetText(deathMessage)
	self.frame:Show()
	self.stimer = 0
end

function Automaton_AlertCombat:PLAYER_ALIVE()
	self.isDead = false
end

function Automaton_AlertCombat:UNIT_PET()
	self:CheckPetDeath()
end

function Automaton_AlertCombat:UNIT_AURA(event, unit)
	if unit ~= "player" then
		return
	end
end

function Automaton_AlertCombat:UNIT_HEALTH(event, unit)
	if unit == "pet" then
		self:CheckPetHealth()
		self:CheckPetDeath()
	end
end

function Automaton_AlertCombat:UNIT_MAXHEALTH(event, unit)
	if unit == "pet" then
		self:CheckPetHealth()
	end
end

function Automaton_AlertCombat:UNIT_HAPPINESS(event, unit)
	if unit == "pet" then
		self:CheckPetHappiness()
	end
end

-- 新增：背包更新时刷新喂食按钮数量
function Automaton_AlertCombat:BAG_UPDATE()
	if self.feedButton and self.feedButton:IsShown() then
		self:UpdateFeedButtonCount()
	end
end

function Automaton_AlertCombat:CheckPetHealth()
	if not self.db.profile.enablePetAlert then
		return
	end
	if not UnitExists("pet") then
		return
	end
	if GetTime() - self.lastPetAlert < 10 then
		return
	end

	local health = UnitHealth("pet")
	local maxHealth = UnitHealthMax("pet")

	-- 宠物已死亡：血量为0会被误判成"血量不足0%"反复播报，这里直接跳过，死亡提示交给 CheckPetDeath
	if maxHealth <= 0 or health <= 0 or UnitIsDead("pet") then
		return
	end

	if maxHealth > 0 then
		local healthPercent = (health / maxHealth) * 100

		if healthPercent <= 20 then
			self.frame.Bg:Hide()
			self.frame.text:SetText("！！宝宝要死了！！")
			self.frame.text:SetTextColor(1, 0, 0)
			self.frame:Show()
			self.stimer = 0
			self.lastPetAlert = GetTime()
		elseif healthPercent <= 50 then
			self.frame.Bg:Hide()
			self.frame.text:SetText("宝宝需要治疗")
			self.frame.text:SetTextColor(1, 1, 0)
			self.frame:Show()
			self.stimer = 0
			self.lastPetAlert = GetTime()
		end
	end
end

function Automaton_AlertCombat:CheckPetDeath()
	if not UnitExists("pet") then
		self.petWasDead = false
		return
	end

	local health = UnitHealth("pet")

	-- 宠物复活/血量恢复：重置死亡标志，下次死亡可再次播报
	if health > 0 and not UnitIsDead("pet") then
		self.petWasDead = false
		return
	end

	-- 本次死亡已经播报过，不再重复刷屏
	if self.petWasDead then
		return
	end

	if not UnitAffectingCombat("player") then
		return
	end

	if health == 0 then
		self.frame.Bg:Hide()
		self.frame.text:SetText("！！主人我噶了！！")
		self.frame.text:SetTextColor(1, 0, 0)
		self.frame:Show()
		self.stimer = 0
		self.lastPetDeathAlert = GetTime()
		self.petWasDead = true

		if self.feedButton then
			self.feedButton:Hide()
		end
		if self.feedButtonFrame then
			self.feedButtonFrame:Hide()
		end
	end
end

function Automaton_AlertCombat:CheckPetHappiness()
	if not self.db.profile.enablePetHappiness then
		return
	end
	if not UnitExists("pet") then
		return
	end
	-- 宠物死亡时不播报快乐值（死亡期间喂食/心情提示无意义）
	if UnitIsDead("pet") or UnitHealth("pet") <= 0 then
		return
	end
	if GetTime() - self.lastPetHappinessAlert < 30 then
		return
	end

	local happiness = GetPetHappiness()

	-- 快乐值：1=不满(伤害75%) 2=满足(伤害100%) 3=快乐(伤害125%)
	-- "不满"(1)和"满足"(2)都提示喂食（伤害已低于满值125%），"快乐"(3)才是最佳状态
	if happiness and happiness <= 2 then
		self.frame.Bg:Hide()
		self.frame.text:SetText("主人 我不开心")
		self.frame.text:SetTextColor(1, 0.5, 0)
		self.frame:Show()
		self.stimer = 0
		self.lastPetHappinessAlert = GetTime()

		self:ShowFeedButton()
	else
		if self.feedButton then
			self.feedButton:Hide()
		end
		if self.feedButtonFrame then
			self.feedButtonFrame:Hide()
		end
	end
end

------------------------------
--      宠物喂养功能相关      --
------------------------------

-- 拦截全局 PickupContainerItem，在物品被拾取到光标时缓存信息
-- （1.12 无 GetCursorInfo，需用此方式获知光标上的物品来源）
do
	local _BasePickupContainerItem = PickupContainerItem
	function PickupContainerItem(bag, slot)
		_BasePickupContainerItem(bag, slot)
		if CursorHasItem() then
			local texture, count = GetContainerItemInfo(bag, slot)
			local link = GetContainerItemLink(bag, slot)
			-- 从 link 解析物品名
			local name = nil
			if link then
				name = string.gsub(link, "|c%x+|Hitem:.-|h%[(.-)%]|h|r", "%1")
				if name == link then
					name = nil
				end -- 未匹配则置 nil
			end
			Automaton_AlertCombat_CursorCache = {
				bag = bag,
				slot = slot,
				texture = texture,
				name = name,
			}
		end
	end
end

-- 辅助：设置按钮图标（兼容 ItemButtonTemplate 的 Icon 子控件）
local function SetFeedButtonIcon(btn, texture)
	-- ItemButtonTemplate 在 1.12 中图标子控件名为 "<ButtonName>Icon"
	local icon = getglobal(btn:GetName() .. "Icon")
	if icon then
		if texture then
			icon:SetTexture(texture)
		else
			icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
		end
	end
	-- 同时调用 SetItemButtonTexture 保持兼容
	SetItemButtonTexture(btn, texture or "Interface\\Icons\\INV_Misc_QuestionMark")
end

function Automaton_AlertCombat:InitPetFeeding()
	self.feedButton = nil
	Automaton_AlertCombat_CursorCache = nil
	-- 角色专属存储已在 OnInitialize 中初始化，无需在此迁移
	-- 但为了兼容旧版存档（如果还有旧 petFood 字段，但我们已经迁移过了）
end

function Automaton_AlertCombat:CreateFeedButton()
	if self.feedButton then
		return
	end

	local module = self

	-- 创建一个可移动的父 Frame（用于 Shift+拖动定位）
	-- ItemButtonTemplate 按钮在 1.12 中调用 StartMoving() 会导致 ERROR #132 崩溃
	-- 因此用一个普通 Frame 作为容器来承载拖动逻辑
	self.feedButtonFrame = CreateFrame("Frame", "Automaton_FeedPetButtonFrame", UIParent)
	self.feedButtonFrame:SetWidth(28)
	self.feedButtonFrame:SetHeight(28)
	self.feedButtonFrame:SetMovable(true)
	self.feedButtonFrame:EnableMouse(false) -- 鼠标事件由子按钮处理

	-- 将 ItemButtonTemplate 按钮附着到父 Frame
	self.feedButton = CreateFrame("Button", "Automaton_FeedPetButton", self.feedButtonFrame, "ItemButtonTemplate")
	self.feedButton:SetAllPoints(self.feedButtonFrame)

	-- ========== 取消宠物喂养食物的边框 ==========
	-- 隐藏 ItemButtonTemplate 默认的边框纹理
	local border = getglobal(self.feedButton:GetName() .. "Border")
	if border then
		border:Hide()
	end
	local iconBorder = getglobal(self.feedButton:GetName() .. "IconBorder")
	if iconBorder then
		iconBorder:Hide()
	end
	-- 可能存在的其他边框子对象（如 "NormalTexture" 或 "Highlight" 的边框部分，一并隐藏）
	local normalTex = self.feedButton:GetNormalTexture()
	if normalTex and normalTex:GetTexture() then
		-- 如果普通纹理包含了边框，清除它（保留高亮功能）
		normalTex:SetTexture(nil)
	end
	-- 清除按钮的 backdrop 边框（如果存在）
	self.feedButton:SetBackdrop(nil)
	-- 确保背景完全透明
	self.feedButton:SetBackdropColor(0, 0, 0, 0)
	-- ========== 边框取消结束 ==========

	self:RestoreFeedButtonPosition()

	-- 恢复已保存的食物图标（从角色专属存储）
	local foodTexture = module.dbChar.AlertCombat.petFoodTexture
	if foodTexture then
		SetFeedButtonIcon(self.feedButton, foodTexture)
	else
		SetFeedButtonIcon(self.feedButton, nil)
	end
	self:UpdateFeedButtonCount()

	-- 注册左键、右键点击及拖入事件
	self.feedButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	self.feedButton:RegisterForDrag("LeftButton")

	-- OnClick
	self.feedButton:SetScript("OnClick", function()
		if CursorHasItem() then
			module:PlaceFoodOnButton()
		elseif arg1 == "RightButton" then
			module:ClearFood()
		else
			module:FeedPet()
		end
	end)

	-- OnReceiveDrag：从背包拖入
	self.feedButton:SetScript("OnReceiveDrag", function()
		module:PlaceFoodOnButton()
	end)

	-- Shift+拖动：移动父 Frame（而非 ItemButton 本身，避免 ERROR #132）
	self.feedButton:SetScript("OnDragStart", function()
		if IsShiftKeyDown() then
			module.feedButtonFrame:StartMoving()
		end
	end)
	self.feedButton:SetScript("OnDragStop", function()
		module.feedButtonFrame:StopMovingOrSizing()
		local point, _, relativePoint, xOfs, yOfs = module.feedButtonFrame:GetPoint()
		-- 保存到角色专属存储
		module.dbChar.AlertCombat.feedButtonPosition = {
			point = point,
			relativePoint = relativePoint,
			xOfs = xOfs,
			yOfs = yOfs,
		}
		if Automaton.SaveDatabase then
			Automaton.SaveDatabase("AutomatonDBChar")
		end
	end)

	-- Tooltip
	self.feedButton:SetScript("OnEnter", function()
		GameTooltip:SetOwner(module.feedButton, "ANCHOR_TOP")
		GameTooltip:SetText("喂养宠物")
		local foodName = module.dbChar.AlertCombat.petFoodName
		if foodName then
			GameTooltip:AddLine("食物: " .. foodName, 0, 1, 0)
			local count = module:CountFoodInBags()
			GameTooltip:AddLine("背包剩余: " .. count, 1, 1, 1)
		else
			GameTooltip:AddLine("将食物拖到此处以设置", 1, 0.5, 0)
		end
		GameTooltip:AddLine("左键: 喂食", 0.7, 0.7, 0.7)
		GameTooltip:AddLine("右键: 清除食物", 0.7, 0.7, 0.7)
		GameTooltip:AddLine("Shift+拖动: 移动按钮", 0.7, 0.7, 0.7)
		GameTooltip:Show()
	end)

	self.feedButton:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
end

-- 将光标上的物品设置为喂食食物
function Automaton_AlertCombat:PlaceFoodOnButton()
	if not CursorHasItem() then
		return
	end

	-- 读取拦截缓存（由重写的 PickupContainerItem 填充）
	local cache = Automaton_AlertCombat_CursorCache
	local itemName = nil
	local itemTexture = nil
	local srcBag = nil
	local srcSlot = nil

	if cache and cache.bag and cache.slot then
		srcBag = cache.bag
		srcSlot = cache.slot
		itemTexture = cache.texture
		itemName = cache.name
	end

	-- 把光标上的物品放回背包原位（toggle 效果：再次 PickupContainerItem 同一格 = 放回）
	if srcBag and srcSlot then
		PickupContainerItem(srcBag, srcSlot)
	else
		ClearCursor()
	end
	Automaton_AlertCombat_CursorCache = nil

	if not itemName or itemName == "" then
		DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[战斗提示]|r 无法识别物品名称，请重试。", 1, 0, 0)
		return
	end

	-- 保存食物信息到角色专属存储
	self.dbChar.AlertCombat.petFoodName = itemName
	self.dbChar.AlertCombat.petFoodTexture = itemTexture
	if Automaton.SaveDatabase then
		Automaton.SaveDatabase("AutomatonDBChar")
	end

	-- 更新按钮图标和数量
	SetFeedButtonIcon(self.feedButton, itemTexture)
	self:UpdateFeedButtonCount()

	DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[战斗提示]|r 食物已设置为: " .. itemName, 1, 1, 0)
end

-- 清除已设置的食物
function Automaton_AlertCombat:ClearFood()
	self.dbChar.AlertCombat.petFoodName = nil
	self.dbChar.AlertCombat.petFoodTexture = nil
	if Automaton.SaveDatabase then
		Automaton.SaveDatabase("AutomatonDBChar")
	end
	SetFeedButtonIcon(self.feedButton, nil)
	SetItemButtonCount(self.feedButton, 0)
	DEFAULT_CHAT_FRAME:AddMessage("|cffffff00[战斗提示]|r 食物设置已清除。", 1, 1, 0)
end

-- 从背包查找物品（按 itemID 或名称）
function Automaton_AlertCombat:FindItemInBags(itemID, itemName)
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot)
			if link then
				if itemID then
					if string.find(link, "item:" .. itemID .. ":") then
						return bag, slot
					end
				elseif itemName then
					if string.find(link, itemName, 1, true) then
						return bag, slot
					end
				end
			end
		end
	end
	return nil, nil
end

-- 统计背包中食物总数量
function Automaton_AlertCombat:CountFoodInBags()
	local foodName = self.dbChar.AlertCombat.petFoodName
	if not foodName then
		return 0
	end
	local total = 0
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot)
			if link and string.find(link, foodName, 1, true) then
				local _, count = GetContainerItemInfo(bag, slot)
				total = total + (count or 1)
			end
		end
	end
	return total
end

-- 更新按钮上的数量显示（改进版，直接操作Count文本控件）
function Automaton_AlertCombat:UpdateFeedButtonCount()
	if not self.feedButton then
		return
	end
	local count = self:CountFoodInBags()
	-- 直接获取按钮上的 Count 文本控件（ItemButtonTemplate 自带）
	local countText = _G[self.feedButton:GetName() .. "Count"]
	if countText then
		if count > 0 then
			countText:SetText(count)
			countText:Show()
		else
			countText:SetText("")
			countText:Hide()
		end
	else
		-- 后备：使用原生 API
		SetItemButtonCount(self.feedButton, count)
	end
end

function Automaton_AlertCombat:RestoreFeedButtonPosition()
	if not self.feedButtonFrame then
		return
	end

	local pos = self.dbChar.AlertCombat.feedButtonPosition
	if pos then
		self.feedButtonFrame:ClearAllPoints()
		self.feedButtonFrame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOfs, pos.yOfs)
	else
		self.feedButtonFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
	end
end

-- 喂养函数（改进：增加延迟刷新）
function Automaton_AlertCombat:FeedPet()
	-- 检查宠物是否存在
	if not UnitExists("pet") then
		DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[战斗提示]|r 没有宠物！", 1, 0, 0)
		return
	end

	-- 检查宠物是否死亡
	if UnitIsDeadOrGhost("pet") then
		DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[战斗提示]|r 宠物已死亡，无法喂养！", 1, 0, 0)
		return
	end

	local foodName = self.dbChar.AlertCombat.petFoodName
	if not foodName or foodName == "" then
		DEFAULT_CHAT_FRAME:AddMessage("|cffffff00[战斗提示]|r 请先将食物拖到喂食按钮上！", 1, 1, 0)
		return
	end

	-- 在背包中查找食物
	local foundBag, foundSlot = self:FindItemInBags(nil, foodName)

	if not foundBag then
		DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[战斗提示]|r 背包中没有找到食物：" .. foodName, 1, 0, 0)
		return
	end

	-- 经典喂养流程：捡起 → 丢给宠物
	PickupContainerItem(foundBag, foundSlot)
	if CursorHasItem() then
		DropItemOnUnit("pet")
		-- 如果光标上还有物品（堆叠剩余），放回原背包槽
		if CursorHasItem() then
			PickupContainerItem(foundBag, foundSlot)
			DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[战斗提示]|r 喂养失败，物品已放回背包。", 1, 0, 0)
		else
			DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[战斗提示]|r 已喂养宠物：" .. foodName, 1, 1, 0)
		end
	else
		DEFAULT_CHAT_FRAME:AddMessage(
			"|cffff0000[战斗提示]|r 无法拾取物品，可能已被使用或消失。",
			1,
			0,
			0
		)
	end

	-- 立即刷新数量
	self:UpdateFeedButtonCount()
	-- 二次保险：0.1秒后再刷新一次（背包更新可能稍晚）
	C_Timer.After(0.1, function()
		if self.feedButton then
			self:UpdateFeedButtonCount()
		end
	end)
end

function Automaton_AlertCombat:ShowFeedButton()
	self:CreateFeedButton()
	self:UpdateFeedButtonCount()
	self.feedButtonFrame:Show()
	self.feedButton:Show()
end
