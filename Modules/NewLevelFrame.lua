assert(Automaton, "Automaton not found!")

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_NewLevelFrame = Automaton:NewModule("NewLevelFrame")
Automaton_NewLevelFrame.modulename = "升级窗口提示"
Automaton_NewLevelFrame.moduledesc = "角色升级后会显示升级成功框体，充满仪式感。"
Automaton_NewLevelFrame.options = {}

local REACHED_LEVEL_STR = "你已经达到"
local NEW_LEVEL_NUM_STR = "等级 %d"
------------------------------
--      Initialization      --
------------------------------

function Automaton_NewLevelFrame:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("NewLevelFrame")
	Automaton:RegisterDefaults("NewLevelFrame", "profile", {
		disabled = false,
	})
	Automaton:SetDisabledAsDefault(self, "NewLevelFrame")

	self:RegisterOptions(self.options)
end

function Automaton_NewLevelFrame:OnEnable()
	self:RegisterEvent("PLAYER_LOGIN")
	self:RegisterEvent("PLAYER_LEVEL_UP")
end

function Automaton_NewLevelFrame:OnDisable()
	self:UnregisterAllEvents()
end

------------------------------
--      Event Handlers      --
------------------------------

function Automaton_NewLevelFrame:ShowNewLevelFrame(level)
	self.newLevelFrame.footer:SetText(string.format(NEW_LEVEL_NUM_STR, level))
	self.newLevelFrame.timeShown = GetTime() + 5
	self.newLevelFrame:Show()
	UIFrameFadeIn(self.newLevelFrame, 2, 0, 1)
	self.newLevelFrame:SetScript("OnUpdate", function()
		if GetTime() > self.newLevelFrame.timeShown then
			UIFrameFadeOut(self.newLevelFrame, 2, 1, 0)
			self.newLevelFrame:SetScript("OnUpdate", nil)
			self.newLevelFrame.timeShown = 0
		end
	end)
end

function Automaton_NewLevelFrame:PLAYER_LOGIN()
	if not self.newLevelFrame then
		self.newLevelFrame = CreateFrame("Frame", nil, UIParent)
		self.newLevelFrame.Texture = self.newLevelFrame:CreateTexture(nil, "BACKGROUND")
		self.newLevelFrame:SetFrameStrata("BACKGROUND")
		self.newLevelFrame:SetWidth(400)
		self.newLevelFrame:SetHeight(200)
		self.newLevelFrame:SetPoint("TOP", 0, -128)
		-- setup texture
		self.newLevelFrame.Texture:SetTexture("Interface\\AddOns\\Automatonex\\Texture\\newlevel_frame")
		self.newLevelFrame.Texture:SetAllPoints(self.newLevelFrame)
		-- setup header text
		self.newLevelFrame.header = self.newLevelFrame:CreateFontString(nil, "ARTWORK")
		self.newLevelFrame.header:SetFont("Fonts\\FRIZQT__.TTF", 18)
		self.newLevelFrame.header:SetPoint("CENTER", 0, 20)
		self.newLevelFrame.header:SetText(REACHED_LEVEL_STR)
		-- setup footer text
		self.newLevelFrame.footer = self.newLevelFrame:CreateFontString(nil, "ARTWORK")
		self.newLevelFrame.footer:SetFont("Fonts\\FRIZQT__.TTF", 30)
		self.newLevelFrame.footer:SetPoint("CENTER", 0, -20)
		self.newLevelFrame.footer:SetTextColor(207 / 255, 191 / 255, 20 / 255, 1)
		-- hide frame at startup
		self.newLevelFrame:Hide()
	end
end

function Automaton_NewLevelFrame:PLAYER_LEVEL_UP()
	self:ShowNewLevelFrame(arg1)
end

function CESLEVEL()
	Automaton_NewLevelFrame:ShowNewLevelFrame(60)
end
