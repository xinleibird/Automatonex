function ToggleGather()
	-- For Herbalism the icon is "INV_Misc_Flower_02"
	prof = GetTrackingTexture()
	if prof then
		if string.find(prof, "Spell_Nature_Earthquake") then
			CastSpellByName("寻找草药")
		else
			CastSpellByName("寻找矿物")
		end
	else
		CastSpellByName("寻找矿物")
	end
end

-- Key Bindings
BINDING_HEADER_TOGGLEGATHER = "切换采集"

BINDING_NAME_TOGGLEGATHER = "切换寻找草药/矿物"
