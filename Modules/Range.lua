assert(Automaton, "Automaton not found!")

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_Range = Automaton:NewModule("Range")
Automaton_Range.modulename = "动作条染色"
Automaton_Range.moduledesc = "动作条根据是否可用和距离染色"
Automaton_Range.options = {}

------------------------------
--      Initialization      --
------------------------------

function Automaton_Range:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("Range")
	Automaton:RegisterDefaults("Range", "profile", {
		disabled = false,
	})
	Automaton:SetDisabledAsDefault(self, "Range")

	self:RegisterOptions(self.options)
end

function Automaton_Range:OnEnable()
	self:Hook("ActionButton_OnUpdate", "ActionButton_OnUpdate")
end

function Automaton_Range:OnDisable()
	self:UnhookAll()
end
function Automaton_Range:ActionButton_OnUpdate(elapsed)
	local btn = this
	local icon = getglobal(btn:GetName() .. "Icon")
	local normal = getglobal(btn:GetName() .. "NormalTexture")
	local hotkey = getglobal(this:GetName() .. "HotKey")
	local btnId = ActionButton_GetPagedID(this)
	local isUsable = IsUsableAction(btnId)

	if btn.rangeTimer then
		btn.rangeTimer = btn.rangeTimer - elapsed
		if btn.rangeTimer < 0.2 then -- 0.1
			if IsActionInRange(btnId) == 0 then
				if not btn.a then
					btn.r, btn.g, btn.b, btn.a = 1, 0, 0, 1
				end
				hotkey:SetVertexColor(1, 1, 1)
				icon:SetVertexColor(btn.r, btn.g, btn.b, btn.a)
				normal:SetVertexColor(0.6, 0.6, 0.6)
			else
				if isUsable then
					icon:SetVertexColor(1, 1, 1)
					normal:SetVertexColor(1, 1, 1)
				else
					icon:SetVertexColor(0.4, 0.4, 0.4)
					normal:SetVertexColor(1, 1, 1)
				end
			end
			btn.rangeTimer = TOOLTIP_UPDATE_TIME
		end
	end
end
