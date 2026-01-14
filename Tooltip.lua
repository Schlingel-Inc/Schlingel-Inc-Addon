-- Tooltip.lua
-- Shows Discord handle for guild members in tooltips

-- Helper function to extract Discord handle from guild note
local function ExtractDiscordHandle(note)
	if not note or note == "" then
		return nil
	end
	-- Guild note is just the handle itself
	return note
end

_G.GameTooltip:HookScript("OnTooltipSetUnit", function(self)
	local _, unit = self:GetUnit()
	if not unit then
		return
	end

	local guildName, rank = _G.GetGuildInfo(unit)
	if (guildName and _G.UnitExists(unit) and _G.UnitPlayerControlled(unit)) then
		_G.GameTooltip:AddLine(string.format('%s der Gilde %s', rank, guildName))

		-- Try to get Discord handle from guild note
		if IsInGuild() then
			local playerName = UnitName(unit)
			if playerName then
				-- Use GuildCache for fast lookup
				local memberInfo = SchlingelInc.GuildCache:GetMemberInfo(playerName)
				if memberInfo and memberInfo.publicNote then
					local discordHandle = ExtractDiscordHandle(memberInfo.publicNote)
					if discordHandle and discordHandle ~= "" then
						-- Sanitize handle to prevent UI injection
						local safeHandle = SchlingelInc:SanitizeText(discordHandle)
						_G.GameTooltip:AddLine(" ")
						_G.GameTooltip:AddLine("Discord:", 0.39, 0.25, 0.65)
						_G.GameTooltip:AddLine(safeHandle, 1, 1, 1)
					end
				end
			end
		end
	end
end)
