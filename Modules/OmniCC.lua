assert(Automaton, "Automaton not found!")

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_OmniCC = Automaton:NewModule("OmniCC")
Automaton_OmniCC.modulename = "OmniCC冷却计时"
Automaton_OmniCC.moduledesc = "动作条和BUFF上显示冷却计时和持续时间"
Automaton_OmniCC.options = {
	fontsize = {
		type = "range",
		name = "字体大小(重置界面后生效)",
		desc = "设置显示文本字体大小，需要重载界面",
		get = function()
			return Automaton_OmniCC.db.profile.fontsize
		end,
		set = function(v)
			Automaton_OmniCC.db.profile.fontsize = v
		end,
		min = 10,
		max = 30,
		step = 1,
		bigStep = 2,
	},
}

------------------------------
--      Initialization      --
------------------------------

function Automaton_OmniCC:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("OmniCC")
	Automaton:RegisterDefaults("OmniCC", "profile", {
		disabled = false,
		fontsize = 20,
	})
	Automaton:SetDisabledAsDefault(self, "OmniCC")

	self:RegisterOptions(self.options)
end

function Automaton_OmniCC:OnEnable()
	--self:RegisterEvent("DUEL_REQUESTED")
	self:Hook("CooldownFrame_SetTimer")
end

function Automaton_OmniCC:OnDisable()
	--self:UnregisterAllEvents()
	self:UnhookAll()
end

------------------------------
--      Event Handlers      --
------------------------------

function Automaton_OmniCC:DUEL_REQUESTED() end

--constants!
local DAY, HOUR, MINUTE = 86400, 3600, 60 --used for formatting text
local DAYISH, HOURISH, MINUTEHALFISH, MINUTEISH, SOONISH = 3600 * 23.5, 60 * 59.5, 89.5, 59.5, 5.5 --used for formatting text at transition points
local HALFDAYISH, HALFHOURISH, HALFMINUTEISH = DAY / 2 + 0.5, HOUR / 2 + 0.5, MINUTE / 2 + 0.5 --used for calculating next update times

--local bindings!
local floor = math.floor
--local min = math.min
local round = function(x)
	return floor(x + 0.5)
end
--local GetTime = GetTime

--returns the formatted time, scaling to use, color, and the time until the next update is needed
local function GetFormattedTime(s)
	--format text as seconds when at 90 seconds or below
	if s < MINUTEISH then
		local seconds = Round(s)
		if seconds < 1 then
			seconds = Round(s, 1)
		end

		-- if s<1 then
		-- 	seconds = round(s)
		-- end
		--Print(seconds)
		if seconds == 0 then
			return "", "", s
		end
		return seconds, "", s - (seconds - 0.51)
		--format text as minutes when below an hour
	elseif s < HOURISH then
		local minutes = round(s / MINUTE)
		return minutes, "m", minutes > 1 and (s - (minutes * MINUTE - HALFMINUTEISH)) or (s - MINUTEISH)
		--format text as hours when below a day
	elseif s < DAYISH then
		local hours = round(s / HOUR)
		return hours, "h", hours > 1 and (s - (hours * HOUR - HALFHOURISH)) or (s - HOURISH)
		--format text as days
	else
		local days = round(s / DAY)
		return days, "d", days > 1 and (s - (days * DAY - HALFDAYISH)) or (s - DAYISH)
	end
end
local function OmniCC_GetTimeScale(t, flot, frame)
	local scale = 1
	if flot ~= "" then
		if t > 9 then
			scale = 0.75
		end
	end
	return frame.btn and scale * 0.7 or scale
end
local function OmniCC_GetTimeColor(s)
	if s < SOONISH then
		return 1, 0, 0
	elseif s < MINUTEISH then
		return 1, 1, 0
	elseif s < HOURISH then
		return 1, 1, 1
	else
		return 0.7, 0.7, 0.7
	end
end
local function OmniCC_OnUpdate()
	if this.timeToNextUpdate <= 0 or (this.icon and not this.icon:IsVisible()) then --or not this.icon:IsVisible()
		local remain = this.duration - (GetTime() - this.start)
		if remain > 0 and (this.btn or this.icon:IsVisible()) then --floor(remain + 0.5) > 0 and (this.btn or this.icon:IsVisible()) then --and this.icon:IsVisible()
			local time, flot, timeToNextUpdate = GetFormattedTime(remain)
			local r, g, b = OmniCC_GetTimeColor(remain)
			local scale = OmniCC_GetTimeScale(time, flot, this)
			this.text:SetFont(STANDARD_TEXT_FONT, Automaton_OmniCC.db.profile.fontsize * scale, "OUTLINE")
			this.text:SetText(time .. (flot ~= "" and ("|CFF00FF00" .. flot .. "|r") or ""))
			this.text:SetTextColor(r, g, b)
			this.timeToNextUpdate = timeToNextUpdate
		else
			this:Hide()
		end
	else
		this.timeToNextUpdate = this.timeToNextUpdate - arg1
	end
end
function Automaton_OmniCC:CreateCooldownCount(cooldown, start, duration)
	local icon = cooldown:GetParent():GetName()
		and (
			getglobal(cooldown:GetParent():GetName() .. "Icon")
			or getglobal(cooldown:GetParent():GetName() .. "IconTexture")
			or getglobal(cooldown:GetParent():GetName() .. "_Icon")
		)
	local textFrame = CreateFrame("Frame", nil, cooldown:GetParent())
	textFrame:SetAllPoints(cooldown:GetParent())
	textFrame:SetFrameLevel(textFrame:GetFrameLevel() + 5)
	cooldown.textFrame = textFrame

	textFrame.text = textFrame:CreateFontString(nil, "OVERLAY")
	textFrame.text:SetPoint("CENTER", 0, 0)
	textFrame.text:SetJustifyH("CENTER")
	textFrame:SetAlpha(cooldown:GetParent():GetAlpha())
	textFrame:Hide()

	if icon then
		if strfind(cooldown:GetParent():GetName(), "Debuff") then
			textFrame.btn = true
		end
		textFrame.icon = icon
	else
		textFrame.btn = true
	end
	textFrame:SetScript("OnUpdate", OmniCC_OnUpdate)
	return textFrame
end

function Automaton_OmniCC:CooldownFrame_SetTimer(cooldownFrame, start, duration, enable)
	self.hooks.CooldownFrame_SetTimer(cooldownFrame, start, duration, enable)
	local cooldownCount = cooldownFrame.textFrame or self:CreateCooldownCount(cooldownFrame, start, duration)

	local MIN_DURATION = 2
	if cooldownCount.btn or cooldownFrame.zCooldownType == "NOGCD" then
		MIN_DURATION = 0.1
	end
	if start > 0 and duration > MIN_DURATION and enable > 0 then
		if cooldownCount then
			cooldownCount.start = start
			cooldownCount.duration = duration
			cooldownCount.timeToNextUpdate = 0
			cooldownCount:Show()
		end
	elseif cooldownFrame.textFrame then
		cooldownFrame.textFrame:Hide()
	end
end
