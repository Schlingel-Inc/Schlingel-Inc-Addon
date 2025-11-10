SchlingelInc.Tabs = SchlingelInc.Tabs or {}

SchlingelInc.Tabs.GuildInfo = {
	InfoText = nil,
}

function SchlingelInc.Tabs.GuildInfo:CreateUI(parentFrame)
	local tabFrame = CreateFrame("Frame", nil, parentFrame)
	tabFrame:SetAllPoints()

	local infoText = SchlingelInc.UIHelpers:CreateText(tabFrame, {
		text = "Lade Gildeninfos ...",
		point = {"TOPLEFT", 10, -25},
		width = 560,
		height = 480,
		justifyH = "LEFT",
		justifyV = "TOP"
	})

	self.InfoText = infoText
	self:UpdateData()

	return tabFrame
end

function SchlingelInc.Tabs.GuildInfo:UpdateData()
	if not self.InfoText then return end

	local playerName, playerRealm = UnitName("player")
	local playerLevel = UnitLevel("player")
	local playerClassLocalized, _ = UnitClass("player")
	local guildName, guildRankName, _, _ = GetGuildInfo("player")

	local infoTextContent = ""

	if not guildName then
		infoTextContent = string.format(
			"|cff69ccf0Spielerinformationen:|r\n" ..
			"  Name: %s%s\n" ..
			"  Level: %d\n" ..
			"  Klasse: %s\n\n" ..
			"Nicht in einer Gilde.",
			playerName or "Unbekannt",
			playerRealm and (" - " .. playerRealm) or "",
			playerLevel or 0,
			playerClassLocalized or "Unbekannt"
		)
	else
		local totalGuildMembers, onlineGuildMembers = GetNumGuildMembers()
		totalGuildMembers = totalGuildMembers or 0
		onlineGuildMembers = onlineGuildMembers or 0

		local totalLevelSum = 0
		local membersCountedForAverageLevel = 0

		if totalGuildMembers > 0 then
			for i = 1, totalGuildMembers do
				local nameRoster, _, _, levelRoster, _, _, _, _, _, _, _, _, _, _ = GetGuildRosterInfo(i)
				if nameRoster and levelRoster and levelRoster > 0 then
					totalLevelSum = totalLevelSum + levelRoster
					membersCountedForAverageLevel = membersCountedForAverageLevel + 1
				end
			end
		end

		local averageLevelText = "N/A"
		if membersCountedForAverageLevel > 0 then
			averageLevelText = string.format("%d", math.floor(totalLevelSum / membersCountedForAverageLevel))
		elseif totalGuildMembers > 0 then
			averageLevelText = "0 (Leveldaten fehlen)"
		else
			averageLevelText = "N/A (Keine Mitglieder)"
		end

		infoTextContent = string.format(
			"|cff69ccf0Spielerinformationen:|r\n" ..
			"  Name: %s%s\n" ..
			"  Level: %d\n" ..
			"  Klasse: %s\n" ..
			"  Gildenrang: %s\n\n" ..
			"|cff69ccf0Gildeninformationen:|r\n" ..
			"  Gildenname: %s\n" ..
			"  Mitglieder (Gesamt): %d\n" ..
			"  Mitglieder (Online): %d\n" ..
			"  Durchschnittslevel (Gilde): %s",
			playerName or "Unbekannt",
			playerRealm and (" - " .. playerRealm) or "",
			playerLevel or 0,
			playerClassLocalized or "Unbekannt",
			guildRankName or "Unbekannt",
			guildName or "Unbekannt",
			totalGuildMembers,
			onlineGuildMembers,
			averageLevelText
		)
	end

	self.InfoText:SetText(infoTextContent)
end
