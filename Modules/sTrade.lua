assert(Automaton, "Automaton not found!")
--STradeDB
local sTrade = {}
STradeDB = {}
local sTradeLOGa = "序号"
local sTradeLOGb = "时间"
local sTradeLOGc = "地点"
local sTradeLOGd = "姓名"
local sTradeLOGe = "我方"
local sTradeLOGf = "对方"
local sTradeLOGg = "结果"
local sTradePlayerPay
local sTradeTargetPay
local CURRENT_sTRADE
local function sTradeLLRR(frm, f, w, h, t, u, x, y)
	--字块模板
	frm:SetFont(f, 14)
	frm:SetWidth(w)
	frm:SetHeight(h)
	if t ~= "" then
		frm:SetText(t)
	end
	frm:ClearAllPoints()
	frm:SetJustifyH("LEFT")
	frm:SetPoint("TOPLEFT", u, "TOPLEFT", x, y)
end

if GetLocale("zhCN") then
	sTrade = {
		a1 = "交易错误",
		a2 = "交易取消",
		a3 = "交易完成",
		b1 = " 在 ",
		b2 = " 与 ",
		b3 = " 的交易: ",
		b4 = "交易结果: ",
		b5 = "原因: ",
		c1 = "金",
		c2 = "银",
		c3 = "铜",
	}
else
	sTrade = {
		a1 = "Trade Error",
		a2 = "Trade Cancelled",
		a3 = "Trade Complete",
		b1 = " at ",
		b2 = " with ",
		b3 = " trade list: ",
		b4 = " Result: ",
		b5 = " Reason: ",
		c1 = " Gold ",
		c2 = " Silver ",
		c3 = " Copper ",
	}
end

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_sTrade = Automaton:NewModule("sTrade")
Automaton_sTrade.modulename = "交易通告"
Automaton_sTrade.moduledesc = "交易通告"
Automaton_sTrade.options = {
	purge = {
		type = "execute",
		name = "显示金币交易记录",
		desc = "显示金币交易记录",
		func = function()
			Automaton_sTrade:sTrade_SlashHandler()
		end,
	},
}

------------------------------
--      Initialization      --
------------------------------

function Automaton_sTrade:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("sTrade")
	Automaton:RegisterDefaults("sTrade", "profile", {
		disabled = false,
	})
	Automaton:SetDisabledAsDefault(self, "sTrade")

	self:RegisterOptions(self.options)

	STradeDB = STradeDB or {}
end

function Automaton_sTrade:OnEnable()
	self:RegisterEvent("TRADE_SHOW")
	--self:RegisterEvent("TRADE_CLOSED");
	self:RegisterEvent("TRADE_REQUEST_CANCEL")
	self:RegisterEvent("PLAYER_TRADE_MONEY")
	self:RegisterEvent("TRADE_MONEY_CHANGED")
	self:RegisterEvent("TRADE_PLAYER_ITEM_CHANGED") --this is an uncertain problem, seems TRADE_PLAYER_ITEM_CHANGED always fire 2 times?
	self:RegisterEvent("TRADE_TARGET_ITEM_CHANGED")
	self:RegisterEvent("TRADE_ACCEPT_UPDATE")
	self:RegisterEvent("PLAYER_TRADE_MONEY")
	self:RegisterEvent("UI_INFO_MESSAGE")
	self:RegisterEvent("UI_ERROR_MESSAGE")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	--self:RegisterEvent("VARIABLES_LOADED")
	--self:RegisterEvent("")
	self.open = true
	self:CreateFrame()
end

function Automaton_sTrade:OnDisable()
	self:UnregisterAllEvents()
	self.open = nil
end

--------------------------------------------------------------
----------------------functions ------------------------------
function Automaton_sTrade:CreateFrame()
	--窗体视图
	local f, t
	f, _, _ = GameFontNormal:GetFont()
	--主窗体
	self.sTradeLLFrame = {}
	self.sTradeLLFrame.main = CreateFrame("Frame", "sTradeLLMainFrame", UIParent)
	self.sTradeLLFrame.main:Hide()
	self.sTradeLLFrame.main:SetWidth(740)
	self.sTradeLLFrame.main:SetHeight(400)
	self.sTradeLLFrame.main:SetPoint("CENTER", 0, 0)
	self.sTradeLLFrame.main:SetMovable(true)
	self.sTradeLLFrame.main:EnableMouse(true)
	Automaton.ApplyFlatBackdrop(self.sTradeLLFrame.main, Automaton.FLAT.window, Automaton.FLAT.border)
	self.sTradeLLFrame.main:SetScript("OnMouseDown", function()
		self.sTradeLLFrame.main:StartMoving()
	end)
	self.sTradeLLFrame.main:SetScript("OnMouseUp", function()
		self.sTradeLLFrame.main:StopMovingOrSizing()
	end)
	--标题栏（扁平背景条 + 金色标题）
	local titleBg = self.sTradeLLFrame.main:CreateTexture(nil, "NORMAL")
	titleBg:SetTexture(0.07, 0.10, 0.16, 0.9)
	titleBg:SetHeight(24)
	titleBg:SetPoint("TOPLEFT", 2, -2)
	titleBg:SetPoint("TOPRIGHT", -2, -2)
	self.sTradeLLFrame.header = self.sTradeLLFrame.main:CreateFontString(nil, "OVERLAY")
	self.sTradeLLFrame.header:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
	self.sTradeLLFrame.header:SetText("金币交易记录")
	self.sTradeLLFrame.header:SetTextColor(Automaton.FLAT.title[1], Automaton.FLAT.title[2], Automaton.FLAT.title[3])
	self.sTradeLLFrame.header:ClearAllPoints()
	self.sTradeLLFrame.header:SetPoint("CENTER", titleBg, "CENTER", 0, 0)
	--底部栏
	self.sTradeLLFrame.bottoma = self.sTradeLLFrame.main:CreateFontString(nil, "OVERLAY")
	sTradeLLRR(self.sTradeLLFrame.bottoma, f, 390, 16, "小计", self.sTradeLLFrame.main, 20, -370)
	self.sTradeLLFrame.bottoma:SetTextColor(Automaton.FLAT.title[1], Automaton.FLAT.title[2], Automaton.FLAT.title[3])
	self.sTradeLLFrame.bottoma:SetJustifyH("CENTER")
	self.sTradeLLFrame.bottomb = self.sTradeLLFrame.main:CreateFontString(nil, "OVERLAY")
	sTradeLLRR(self.sTradeLLFrame.bottomb, f, 120, 16, "", self.sTradeLLFrame.main, 410, -370)
	self.sTradeLLFrame.bottomb:SetTextColor(Automaton.FLAT.title[1], Automaton.FLAT.title[2], Automaton.FLAT.title[3])
	self.sTradeLLFrame.bottomc = self.sTradeLLFrame.main:CreateFontString(nil, "OVERLAY")
	sTradeLLRR(self.sTradeLLFrame.bottomc, f, 120, 16, "", self.sTradeLLFrame.main, 530, -370)
	self.sTradeLLFrame.bottomc:SetTextColor(Automaton.FLAT.title[1], Automaton.FLAT.title[2], Automaton.FLAT.title[3])
	--各列
	self.sTradeLLFrame.titlesa = self.sTradeLLFrame.main:CreateFontString(nil, "OVERLAY")
	sTradeLLRR(self.sTradeLLFrame.titlesa, f, 40, 16, "序号", self.sTradeLLFrame.main, 20, -25)
	self.sTradeLLFrame.titlesb = self.sTradeLLFrame.main:CreateFontString(nil, "OVERLAY")
	sTradeLLRR(self.sTradeLLFrame.titlesb, f, 120, 16, "时间", self.sTradeLLFrame.main, 60, -25)
	self.sTradeLLFrame.titlesc = self.sTradeLLFrame.main:CreateFontString(nil, "OVERLAY")
	sTradeLLRR(self.sTradeLLFrame.titlesc, f, 120, 16, "地点", self.sTradeLLFrame.main, 180, -25)
	self.sTradeLLFrame.titlesd = self.sTradeLLFrame.main:CreateFontString(nil, "OVERLAY")
	sTradeLLRR(self.sTradeLLFrame.titlesd, f, 110, 16, "姓名", self.sTradeLLFrame.main, 300, -25)
	self.sTradeLLFrame.titlese = self.sTradeLLFrame.main:CreateFontString(nil, "OVERLAY")
	sTradeLLRR(self.sTradeLLFrame.titlese, f, 120, 16, "我方", self.sTradeLLFrame.main, 410, -25)
	self.sTradeLLFrame.titlesf = self.sTradeLLFrame.main:CreateFontString(nil, "OVERLAY")
	sTradeLLRR(self.sTradeLLFrame.titlesf, f, 120, 16, "对方", self.sTradeLLFrame.main, 530, -25)
	self.sTradeLLFrame.titlesg = self.sTradeLLFrame.main:CreateFontString(nil, "OVERLAY")
	sTradeLLRR(self.sTradeLLFrame.titlesg, f, 60, 16, "交易结果", self.sTradeLLFrame.main, 650, -25)
	--列标题统一金色
	for _, ttl in ipairs({
		self.sTradeLLFrame.titlesa,
		self.sTradeLLFrame.titlesb,
		self.sTradeLLFrame.titlesc,
		self.sTradeLLFrame.titlesd,
		self.sTradeLLFrame.titlese,
		self.sTradeLLFrame.titlesf,
		self.sTradeLLFrame.titlesg,
	}) do
		ttl:SetTextColor(Automaton.FLAT.title[1], Automaton.FLAT.title[2], Automaton.FLAT.title[3])
	end
	--顶部按钮a-关闭（红色扁平按钮）
	self.sTradeLLFrame.buttona = CreateFrame("Button", nil, self.sTradeLLFrame.main)
	self.sTradeLLFrame.buttona.owner = self
	self.sTradeLLFrame.buttona:SetWidth(60)
	self.sTradeLLFrame.buttona:SetHeight(20)
	self.sTradeLLFrame.buttona:SetPoint("TOPRIGHT", self.sTradeLLFrame.main, "TOPRIGHT", -20, -8)
	Automaton.ApplyFlatBackdrop(self.sTradeLLFrame.buttona, { 0.35, 0.08, 0.08, 0.98 }, Automaton.FLAT.border)
	Automaton.AddFlatBorder(self.sTradeLLFrame.buttona, Automaton.FLAT.border)
	self.sTradeLLFrame.buttonatext = self.sTradeLLFrame.buttona:CreateFontString(nil, "OVERLAY")
	self.sTradeLLFrame.buttonatext:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
	self.sTradeLLFrame.buttonatext:SetTextColor(1, 0.82, 0.82)
	self.sTradeLLFrame.buttonatext:SetText("关闭")
	self.sTradeLLFrame.buttonatext:SetAllPoints(self.sTradeLLFrame.buttona)
	self.sTradeLLFrame.buttona:SetScript("OnEnter", function()
		self.sTradeLLFrame.buttona:SetBackdropColor(0.65, 0.12, 0.12, 1)
	end)
	self.sTradeLLFrame.buttona:SetScript("OnLeave", function()
		self.sTradeLLFrame.buttona:SetBackdropColor(0.35, 0.08, 0.08, 0.98)
	end)
	self.sTradeLLFrame.buttona:SetScript("OnClick", function()
		self.sTradeLLFrame.main:Hide()
	end)
	--顶部按钮b-清除（蓝色扁平按钮）
	self.sTradeLLFrame.buttonb, self.sTradeLLFrame.buttonbtext =
		Automaton.CreateFlatButton(self.sTradeLLFrame.main, 60, 20, "清除")
	self.sTradeLLFrame.buttonb.owner = self
	self.sTradeLLFrame.buttonb:SetPoint("TOPLEFT", self.sTradeLLFrame.main, "TOPLEFT", 20, -8)
	self.sTradeLLFrame.buttonb:SetScript("OnClick", function()
		STradeDB = nil
		sTrade_InitializeSetup()
	end)
	--滚动窗体
	self.sTradeLLFrame.sframe =
		CreateFrame("ScrollFrame", "sTradeLLScrollFrame", self.sTradeLLFrame.main, "FauxScrollFrameTemplate")
	self.sTradeLLFrame.sframe.owner = self
	self.sTradeLLFrame.sframe:SetWidth(700)
	self.sTradeLLFrame.sframe:SetHeight(300)
	self.sTradeLLFrame.sframe:SetPoint("TOPLEFT", self.sTradeLLFrame.main, "TOPLEFT", 20, -50)
	self.sTradeLLFrame.sframe:SetScript("OnVerticalScroll", function()
		FauxScrollFrame_OnVerticalScroll(16, function()
			self:sTradeLLUpdate()
		end)
	end)

	--在主窗体上部署要显示的字块
	self.sTradeLLFrame.scollsa = {}
	self.sTradeLLFrame.scollsb = {}
	self.sTradeLLFrame.scollsc = {}
	self.sTradeLLFrame.scollsd = {}
	self.sTradeLLFrame.scollse = {}
	self.sTradeLLFrame.scollsf = {}
	self.sTradeLLFrame.scollsg = {}
	for i = 1, 15 do
		self.sTradeLLFrame.scollsa[i] = self.sTradeLLFrame.main:CreateFontString(nil, "ARTWORK")
		sTradeLLRR(self.sTradeLLFrame.scollsa[i], f, 40, 16, "", self.sTradeLLFrame.sframe, 0, -(i - 1) * 20 - 5)
		self.sTradeLLFrame.scollsa[i]:SetJustifyH("CENTER")
		self.sTradeLLFrame.scollsb[i] = self.sTradeLLFrame.main:CreateFontString(nil, "ARTWORK")
		sTradeLLRR(self.sTradeLLFrame.scollsb[i], f, 120, 16, "", self.sTradeLLFrame.sframe, 40, -(i - 1) * 20 - 5)
		self.sTradeLLFrame.scollsc[i] = self.sTradeLLFrame.main:CreateFontString(nil, "ARTWORK")
		sTradeLLRR(self.sTradeLLFrame.scollsc[i], f, 120, 16, "", self.sTradeLLFrame.sframe, 160, -(i - 1) * 20 - 5)
		self.sTradeLLFrame.scollsd[i] = self.sTradeLLFrame.main:CreateFontString(nil, "ARTWORK")
		sTradeLLRR(self.sTradeLLFrame.scollsd[i], f, 110, 16, "", self.sTradeLLFrame.sframe, 280, -(i - 1) * 20 - 5)
		self.sTradeLLFrame.scollse[i] = self.sTradeLLFrame.main:CreateFontString(nil, "ARTWORK")
		sTradeLLRR(self.sTradeLLFrame.scollse[i], f, 120, 16, "", self.sTradeLLFrame.sframe, 390, -(i - 1) * 20 - 5)
		self.sTradeLLFrame.scollsf[i] = self.sTradeLLFrame.main:CreateFontString(nil, "ARTWORK")
		sTradeLLRR(self.sTradeLLFrame.scollsf[i], f, 120, 16, "", self.sTradeLLFrame.sframe, 510, -(i - 1) * 20 - 5)
		self.sTradeLLFrame.scollsg[i] = self.sTradeLLFrame.main:CreateFontString(nil, "ARTWORK")
		sTradeLLRR(self.sTradeLLFrame.scollsg[i], f, 60, 16, "", self.sTradeLLFrame.sframe, 630, -(i - 1) * 20 - 5)
	end
end

local function C_to_GSC(coppers)
	--金银铜换算
	local g, s, c
	g = math.floor(coppers / 10000)
	s = math.floor(coppers / 100) - g * 100
	c = coppers - (g * 100 + s) * 100
	return g .. sTrade.c1 .. s .. sTrade.c2 .. c .. sTrade.c3
end
local function sTrade_GetTradeList(unit, items, a)
	--交易物品列表
	local list = " "
	local funcInfo = getglobal("GetTrade" .. unit .. "ItemInfo")
	local funcLink = getglobal("GetTrade" .. unit .. "ItemLink")
	local name, texture, numItems, quality, isUsable, enchantment
	local count = 0
	for i = 1, 6 do
		if unit == "Target" then
			name, texture, numItems, quality, isUsable, enchantment = funcInfo(i)
		else
			name, texture, numItems, quality, enchantment = funcInfo(i)
		end
		if name then
			count = count + 1
			local itemLink = funcLink(i)

			items[i] = {
				name = name,
				numItems = numItems,
				itemLink = itemLink,
			}
			local tmp = items[i].itemLink
			if items[i].numItems > 1 then
				tmp = tmp .. "x" .. items[i].numItems
			end
			if count > a and count <= a + 3 then
				list = list .. tmp .. " "
			end
		end
	end
	return list
end

local function sTrade_NewTrade()
	--
	local trade = {
		id = nil,
		when = nil,
		where = nil,
		who = nil,
		player = UnitName("player"),
		playerMoney = 0,
		targetMoney = 0,
		playerItems = {},
		targetItems = {},
		playerItemsList = "",
		playerItemsList2 = "",
		targetItemsList = "",
		targetItemsList2 = "",
		events = {}, --for analysing cancel reason
		toofar = nil, --for further analysing cancel reason
		result = nil, --[cancelled | complete | error]
		reason = nil, --["this" | "thisrunaway" | "toofar" | "other" | "thishideui" | ERR_TRADE_BAG_FULL | ERR_TRADE_MAX_COUNT_EXCEEDED | ERR_TRADE_TARGET_BAG_FULL | ERR_TRADE_TARGET_MAX_COUNT_EXCEEDED]
	}
	return trade
end

local function curr()
	if not CURRENT_sTRADE then
		CURRENT_sTRADE = sTrade_NewTrade()
	end
	return CURRENT_sTRADE
end

-- function sTrade_OnLoad()
-- 	-- SlashCmdList["sTrade"] = sTrade_SlashHandler;
-- 	-- SLASH_sTrade1 = "/stg";
-- 	-- DEFAULT_CHAT_FRAME:AddMessage(LOAD_STRADE_VERSION,true);
-- 	-- DEFAULT_CHAT_FRAME:AddMessage("$$$ 输入/stg 显示金币交易记录 $$$",0.5,0,1);
-- end

-- 修改点：将 local 去掉，改为全局函数
function sTrade_InitializeSetup()
	--读取保存的金币交易记录，如果没有记录则新建记录用的表
	if STradeDB == nil then
		STradeDB = {}
	end
	if STradeDB[sTradeLOGa] == nil then
		STradeDB[sTradeLOGa] = {}
	end
	if STradeDB[sTradeLOGb] == nil then
		STradeDB[sTradeLOGb] = {}
	end
	if STradeDB[sTradeLOGc] == nil then
		STradeDB[sTradeLOGc] = {}
	end
	if STradeDB[sTradeLOGd] == nil then
		STradeDB[sTradeLOGd] = {}
	end
	if STradeDB[sTradeLOGe] == nil then
		STradeDB[sTradeLOGe] = {}
	end
	if STradeDB[sTradeLOGf] == nil then
		STradeDB[sTradeLOGf] = {}
	end
	if STradeDB[sTradeLOGg] == nil then
		STradeDB[sTradeLOGg] = {}
	end
	local n = table.getn(STradeDB[sTradeLOGa])
	sTradePlayerPay = 0
	sTradeTargetPay = 0
	for i = 1, n do
		sTradePlayerPay = sTradePlayerPay + STradeDB[sTradeLOGe][i]
		sTradeTargetPay = sTradeTargetPay + STradeDB[sTradeLOGf][i]
	end
	--更新窗体内容
	Automaton_sTrade:sTradeLLUpdate()
end
local function sTrade_Output()
	--交易结果通告
	local msg1, msg2, msg3, msg4, msg21, msg31, pm, tm
	pm = C_to_GSC(curr().playerMoney)
	tm = C_to_GSC(curr().targetMoney)
	msg1 = curr().when .. sTrade.b1 .. curr().where .. sTrade.b2 .. curr().who .. sTrade.b3
	if curr().playerMoney == 0 then
		msg2 = "我方:" .. curr().playerItemsList
	else
		msg2 = "我方:" .. pm .. curr().playerItemsList
	end
	msg21 = "我方:" .. curr().playerItemsList2
	if curr().targetMoney == 0 then
		msg3 = "对方:" .. curr().targetItemsList
	else
		msg3 = "对方:" .. tm .. curr().targetItemsList
	end
	msg31 = "对方:" .. curr().targetItemsList2
	msg4 = sTrade.b4 .. curr().result
	--交易未成功详情. 实际运行中堆叠物品会按堆叠数量输出多次... 还是关了吧
	--	if not curr().reason == nil then msg4 = msg4 .. sTrade.b5 .. curr().reason
	--	end
	if not curr().who then
		SendChatMessage(msg1, "say")
		if string.len(msg2) ~= 8 then
			SendChatMessage(msg2, "say")
		end
		if string.len(msg21) ~= 8 then
			SendChatMessage(msg21, "say")
		end
		if string.len(msg3) ~= 8 then
			SendChatMessage(msg3, "say")
		end
		if string.len(msg31) ~= 8 then
			SendChatMessage(msg31, "say")
		end
		SendChatMessage(msg4, "say")
	else
		SendChatMessage(msg1, "whisper", nil, curr().who)
		if string.len(msg2) ~= 8 then
			SendChatMessage(msg2, "whisper", nil, curr().who)
		end
		if string.len(msg21) ~= 8 then
			SendChatMessage(msg21, "whisper", nil, curr().who)
		end
		if string.len(msg3) ~= 8 then
			SendChatMessage(msg3, "whisper", nil, curr().who)
		end
		if string.len(msg31) ~= 8 then
			SendChatMessage(msg31, "whisper", nil, curr().who)
		end
		SendChatMessage(msg4, "whisper", nil, curr().who)
	end

	--如果交易中有金币发生, 写入sTradeLOG，并更新窗体内容
	if curr().playerMoney ~= 0 or curr().targetMoney ~= 0 then
		if curr().result == "交易完成" then
			sTradePlayerPay = sTradePlayerPay + curr().playerMoney
			sTradeTargetPay = sTradeTargetPay + curr().targetMoney
			curr().result = "|c0000FF00" .. curr().result
		elseif curr().result == "交易取消" then
			curr().result = "|c00FF0000" .. curr().result
		end
		local n = getn(STradeDB[sTradeLOGa])

		STradeDB[sTradeLOGa][n + 1] = n + 1
		STradeDB[sTradeLOGb][n + 1] = curr().when
		STradeDB[sTradeLOGc][n + 1] = curr().where
		STradeDB[sTradeLOGd][n + 1] = curr().who
		STradeDB[sTradeLOGe][n + 1] = curr().playerMoney
		STradeDB[sTradeLOGf][n + 1] = curr().targetMoney
		STradeDB[sTradeLOGg][n + 1] = curr().result
		Automaton_sTrade:sTradeLLUpdate()

		-- sTradeListFrame:NewMsg(curr().when.." "..string.format("%-15s",curr().where).." "..string.format("%-21s",curr().who).."       ",string.format("%-25s",pm),string.format("%-25s",tm),curr().result,12)
		-- sTradeListFrame:NewMsg(string.format("%-64s","　　小计:　　　　　　　　　　　　　"),string.format("%-25s",C_to_GSC(sTradePlayerPay)),string.format("%-25s",C_to_GSC(sTradeTargetPay)),"",0);
	end
end
local function sTrade_CancelReason()
	--取消原因？
	local reason = "unknown" --should be unknown only when no trade window opened.
	local e = curr().events
	local n = table.getn(e)
	if n >= 3 and e[n] == "TRADE_REQUEST_CANCEL" and e[n - 1] == "TRADE_CLOSED" and e[n - 2] == "TRADE_CLOSED" then
		reason = "self"
	elseif n >= 3 and e[n] == "TRADE_REQUEST_CANCEL" and e[n - 1] == "TRADE_CLOSED" and e[n - 2] == "TRADE_SHOW" then
		reason = "selfrunaway"
	elseif n >= 3 and e[n] == "TRADE_CLOSED" and e[n - 1] == "TRADE_CLOSED" and e[n - 2] == "TRADE_REQUEST_CANCEL" then
		if curr().toofar == "yes" then
			reason = "toofar"
		elseif curr().toofar == "no" then
			reason = "other"
		else
			reason = "wrong!!" --this should not happen, if you see, contact me :p
		end
	elseif n >= 3 and e[n] == "TRADE_REQUEST_CANCEL" and e[n - 1] == "TRADE_SHOW" and e[n - 2] == "TRADE_CLOSED" then
		reason = "selfhideui"
	end

	curr().events = nil --reason analyzed, abandon it to release that tiny memory
	return reason
end
local function sTrade_TradeAndReset()
	--重置记录
	curr().when = date("%Y%m%d-%H%M%S")
	curr().where = GetRealZoneText()
	if curr().result == sTrade.a1 then
		curr().reason = sTrade_CancelReason()
	elseif curr().result == sTrade.a2 then
		curr().reason = curr().reason
	end
	--在交易因为距离过远, 目标死亡等意外原因中断时, 会触发UI_INFO_MESSAGE多次, 导致多次进行输出, 并且curr().who将变为空值, 然后报错.
	if curr().who ~= nil then
		sTrade_Output()
	end
	CURRENT_sTRADE = nil
end

local function sTrade_UpdateItemInfo(id, unit, items)
	--更新交易内容
	local funcInfo = getglobal("GetTrade" .. unit .. "ItemInfo")
	local funcLink = getglobal("GetTrade" .. unit .. "ItemLink")

	local name, texture, numItems, quality, isUsable, enchantment
	--why GetTradePlayerItemInfo and GetTradeTargetItemInfo return different things?
	if unit == "Target" then
		name, texture, numItems, quality, isUsable, enchantment = funcInfo(id)
	else
		name, texture, numItems, quality, enchantment = funcInfo(id)
	end

	if not name then
		items[id] = nil
		return
	end

	local itemLink = funcLink(id)
	items[id] = {
		name = name,
		texture = texture,
		numItems = numItems,
		isUsable = isUsable,
		enchantment = enchantment,
		itemLink = itemLink,
	}
end

local function sTrade_UpdateMoney()
	--更新交易金额
	curr().playerMoney = GetPlayerTradeMoney()
	curr().targetMoney = GetTargetTradeMoney()
end
function Automaton_sTrade:sTradeLLUpdate()
	-- 修改点：增加 nil 保护，避免在 STradeDB 为 nil 时报错
	if not STradeDB then
		return
	end
	if not STradeDB[sTradeLOGa] then
		return
	end
	local j = getn(STradeDB[sTradeLOGa])
	FauxScrollFrame_Update(self.sTradeLLFrame.sframe, getn(STradeDB[sTradeLOGa]), 15, 16)
	local sTradePos = FauxScrollFrame_GetOffset(self.sTradeLLFrame.sframe)
	if j <= 15 then
		sTradePos = 0
	end
	local i
	for i = 1, 15 do
		if j >= (i + sTradePos) then
			self.sTradeLLFrame.scollsa[i]:SetText(STradeDB[sTradeLOGa][i + sTradePos])
			self.sTradeLLFrame.scollsb[i]:SetText(STradeDB[sTradeLOGb][i + sTradePos])
			self.sTradeLLFrame.scollsc[i]:SetText(STradeDB[sTradeLOGc][i + sTradePos])
			self.sTradeLLFrame.scollsd[i]:SetText(STradeDB[sTradeLOGd][i + sTradePos])
			self.sTradeLLFrame.scollse[i]:SetText(C_to_GSC(STradeDB[sTradeLOGe][i + sTradePos]))
			self.sTradeLLFrame.scollsf[i]:SetText(C_to_GSC(STradeDB[sTradeLOGf][i + sTradePos]))
			self.sTradeLLFrame.scollsg[i]:SetText(STradeDB[sTradeLOGg][i + sTradePos])
			--			self.sTradeLLFrame.scollsa[i]:Show()
			--			self.sTradeLLFrame.scollsb[i]:Show()
			--			self.sTradeLLFrame.scollsc[i]:Show()
			--			self.sTradeLLFrame.scollsd[i]:Show()
			--			self.sTradeLLFrame.scollse[i]:Show()
			--			self.sTradeLLFrame.scollsf[i]:Show()
			--			self.sTradeLLFrame.scollsg[i]:Show()
		else
			self.sTradeLLFrame.scollsa[i]:SetText("")
			self.sTradeLLFrame.scollsb[i]:SetText("")
			self.sTradeLLFrame.scollsc[i]:SetText("")
			self.sTradeLLFrame.scollsd[i]:SetText("")
			self.sTradeLLFrame.scollse[i]:SetText("")
			self.sTradeLLFrame.scollsf[i]:SetText("")
			self.sTradeLLFrame.scollsg[i]:SetText("")
		end
	end
	self.sTradeLLFrame.bottomb:SetText(C_to_GSC(sTradePlayerPay))
	self.sTradeLLFrame.bottomc:SetText(C_to_GSC(sTradeTargetPay))
end

function Automaton_sTrade:sTrade_SlashHandler(msg)
	if not self.open then
		return
	end
	--命令行
	self.sTradeLLFrame.main:Show()
	self.sTradeLLFrame.sframe:SetVerticalScroll(34)
	self:sTradeLLUpdate()
end

------------------------------
--      Event Handlers      --
------------------------------

--function Automaton_sTrade:VARIABLES_LOADED()

--end

--DEFAULT_CHAT_FRAME:AddMessage(event,0,0,1);
function Automaton_sTrade:PLAYER_ENTERING_WORLD()
	sTrade_InitializeSetup()
end

function Automaton_sTrade:UI_ERROR_MESSAGE()
	curr().result = sTrade.a1
	curr().reason = arg1
end

function Automaton_sTrade:UI_INFO_MESSAGE()
	if ERR_TRADE_CANCELLED or arg1 == ERR_TRADE_COMPLETE then
		curr().result = (arg1 == ERR_TRADE_CANCELLED) and sTrade.a2 or sTrade.a3
		sTrade_TradeAndReset()
	end
end

function Automaton_sTrade:TRADE_PLAYER_ITEM_CHANGED()
	sTrade_UpdateItemInfo(arg1, "Player", curr().playerItems)
end

function Automaton_sTrade:TRADE_TARGET_ITEM_CHANGED()
	sTrade_UpdateItemInfo(arg1, "Target", curr().targetItems)
end

function Automaton_sTrade:TRADE_MONEY_CHANGED()
	sTrade_UpdateMoney()
end

function Automaton_sTrade:PLAYER_TRADE_MONEY()
	--		sTrade_UpdateMoney();
end

function Automaton_sTrade:TRADE_ACCEPT_UPDATE()
	--		for i = 1, 7 do
	--			sTrade_UpdateItemInfo(i, "Player", curr().playerItems);
	--			sTrade_UpdateItemInfo(i, "Target", curr().targetItems);
	--		end
	sTrade_UpdateMoney()
	--双方之一按下交易
	if arg1 == 1 or arg2 == 1 then
		local tmpWho = GetUnitName("NPC", true)
		if tmpWho and curr().who and tmpWho ~= curr().who then
			SendChatMessage(
				"交易对象 " .. tmpWho .. " 与预期目标 " .. curr().who .. " 不符!!! 取消交易!!!",
				"say"
			)
			CancelTrade()
		end
		curr().playerItemsList = sTrade_GetTradeList("Player", curr().playerItems, 0)
		curr().playerItemsList2 = sTrade_GetTradeList("Player", curr().playerItems, 3)
		curr().targetItemsList = sTrade_GetTradeList("Target", curr().targetItems, 0)
		curr().targetItemsList2 = sTrade_GetTradeList("Target", curr().targetItems, 3)
	end
end

function Automaton_sTrade:TRADE_REQUEST_CANCEL() --judge the trade distance for further analysing the cancel reason
	curr().playerItemsList = sTrade_GetTradeList("Player", curr().playerItems, 0)
	curr().playerItemsList2 = sTrade_GetTradeList("Player", curr().playerItems, 3)
	curr().targetItemsList = sTrade_GetTradeList("Target", curr().targetItems, 0)
	curr().targetItemsList2 = sTrade_GetTradeList("Target", curr().targetItems, 3)
	--			sTrade_UpdateMoney();
	if UnitName("NPC") then
		curr().toofar = CheckInteractDistance("npc", 2) and "no" or "yes"
	end
end

function Automaton_sTrade:TRADE_SHOW()
	--curr().who=GetUnitName("NPC", true):gsub(" %- ", "-");
	curr().who = GetUnitName("NPC", true)
	--		sTrade_Statue_flag=1;
end

-- local function SendChat(msg, name)
-- 	local channel = sTrade_FindAnnounceChannel(TradeLog_AnnounceChannel);
-- 	if (channel == "WHISPER") then
-- 		SendChatMessage(msg, channel, nil, name);
-- 	else
-- 		SendChatMessage(msg, channel);
-- 	end
-- end
