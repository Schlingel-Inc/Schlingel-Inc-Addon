SchlingelInc.SITabs = SchlingelInc.SITabs or {}

local function FormatSeconds(totalSeconds)
	if totalSeconds and totalSeconds > 0 then
		local d = math.floor(totalSeconds / 86400)
		local h = math.floor((totalSeconds % 86400) / 3600)
		local m = math.floor((totalSeconds % 3600) / 60)
		return string.format("%dd %dh %dm", d, h, m)
	elseif totalSeconds == 0 then
		return "0d 0h 0m"
	else
		return "Lade..."
	end
end

SchlingelInc.SITabs.Character = {}

function SchlingelInc.SITabs.Character:CreateUI(parentFrame)
	local tabFrame = CreateFrame("Frame", nil, parentFrame)
	tabFrame:SetAllPoints()

	local contentFrame = CreateFrame("Frame", nil, tabFrame)
	contentFrame:SetPoint("TOPLEFT", 20, -20)
	contentFrame:SetPoint("BOTTOMRIGHT", -20, 20)

	local xCol1 = 0
	local xCol2 = contentFrame:GetWidth() * 0.55
	local lineHeight = 22
	local currentY_Col1 = 0
	local currentY_Col2 = 0

	-- Column 1
	tabFrame.playerNameText = SchlingelInc.UIHelpers:CreateStyledText(contentFrame, "Name: ...", "GameFontNormal", "TOPLEFT",
		contentFrame, "TOPLEFT", xCol1, currentY_Col1)
	currentY_Col1 = currentY_Col1 - lineHeight
	tabFrame.levelText = SchlingelInc.UIHelpers:CreateStyledText(contentFrame, "Level: ...", "GameFontNormal", "TOPLEFT", contentFrame,
		"TOPLEFT", xCol1, currentY_Col1)
	currentY_Col1 = currentY_Col1 - lineHeight
	tabFrame.classText = SchlingelInc.UIHelpers:CreateStyledText(contentFrame, "Klasse: ...", "GameFontNormal", "TOPLEFT",
		contentFrame, "TOPLEFT", xCol1, currentY_Col1)
	currentY_Col1 = currentY_Col1 - lineHeight
	tabFrame.raceText = SchlingelInc.UIHelpers:CreateStyledText(contentFrame, "Rasse: ...", "GameFontNormal", "TOPLEFT", contentFrame,
		"TOPLEFT", xCol1, currentY_Col1)
	currentY_Col1 = currentY_Col1 - lineHeight
	tabFrame.zoneText = SchlingelInc.UIHelpers:CreateStyledText(contentFrame, "Zone: ...", "GameFontNormal", "TOPLEFT", contentFrame,
		"TOPLEFT", xCol1, currentY_Col1)
	currentY_Col1 = currentY_Col1 - lineHeight
	tabFrame.deathCountText = SchlingelInc.UIHelpers:CreateStyledText(contentFrame, "Tode: ...", "GameFontNormal", "TOPLEFT",
		contentFrame, "TOPLEFT", xCol1, currentY_Col1)

	-- Column 2
	tabFrame.moneyText = SchlingelInc.UIHelpers:CreateStyledText(contentFrame, "Geld: ...", "GameFontNormal", "TOPLEFT", contentFrame,
		"TOPLEFT", xCol2, currentY_Col2)
	currentY_Col2 = currentY_Col2 - lineHeight
	tabFrame.xpText = SchlingelInc.UIHelpers:CreateStyledText(contentFrame, "XP: ...", "GameFontNormal", "TOPLEFT", contentFrame,
		"TOPLEFT", xCol2, currentY_Col2)
	currentY_Col2 = currentY_Col2 - lineHeight
	tabFrame.timePlayedTotalText = SchlingelInc.UIHelpers:CreateStyledText(contentFrame, "Spielzeit (Gesamt): Lade...",
		"GameFontNormal", "TOPLEFT", contentFrame, "TOPLEFT", xCol2, currentY_Col2)
	currentY_Col2 = currentY_Col2 - lineHeight
	tabFrame.timePlayedLevelText = SchlingelInc.UIHelpers:CreateStyledText(contentFrame, "Spielzeit (Level): Lade...",
		"GameFontNormal", "TOPLEFT", contentFrame, "TOPLEFT", xCol2, currentY_Col2)

	-- Guild Info
	local guildYStart = math.min(currentY_Col1, currentY_Col2) - (lineHeight * 2)
	tabFrame.guildNameText = SchlingelInc.UIHelpers:CreateStyledText(contentFrame, "Gilde: ...", "GameFontNormal", "TOPLEFT",
		contentFrame, "TOPLEFT", xCol1, guildYStart)
	guildYStart = guildYStart - lineHeight
	tabFrame.guildRankText = SchlingelInc.UIHelpers:CreateStyledText(contentFrame, "Gildenrang: ...", "GameFontNormal", "TOPLEFT",
		contentFrame, "TOPLEFT", xCol1, guildYStart)
	guildYStart = guildYStart - lineHeight
	tabFrame.guildMembersText = SchlingelInc.UIHelpers:CreateStyledText(contentFrame, "Mitglieder: ...", "GameFontNormal", "TOPLEFT",
		contentFrame, "TOPLEFT", xCol1, guildYStart)

	tabFrame.Update = function(selfTab)
		xCol2 = contentFrame:GetWidth() * 0.55
		selfTab.moneyText:ClearAllPoints()
		selfTab.moneyText:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", xCol2, 0)

		local currentY_Col2_Update = 0 - lineHeight
		selfTab.xpText:ClearAllPoints()
		selfTab.xpText:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", xCol2, currentY_Col2_Update)

		currentY_Col2_Update = currentY_Col2_Update - lineHeight
		selfTab.timePlayedTotalText:ClearAllPoints()
		selfTab.timePlayedTotalText:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", xCol2, currentY_Col2_Update)

		currentY_Col2_Update = currentY_Col2_Update - lineHeight
		selfTab.timePlayedLevelText:ClearAllPoints()
		selfTab.timePlayedLevelText:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", xCol2, currentY_Col2_Update)

		local pName = UnitName("player") or "Unbekannt"
		local pLevel = UnitLevel("player") or 0
		local pClassLoc, pClassToken = UnitClass("player")
		pClassLoc = pClassLoc or "Unbekannt"
		local pRaceLoc, _ = UnitRace("player")
		pRaceLoc = pRaceLoc or "Unbekannt"
		local currentZone = GetZoneText() or "Unbekannt"
		local pMoney = GetMoneyString(GetMoney(), true) or "0c"

		selfTab.playerNameText:SetText("Name: " .. pName)
		selfTab.levelText:SetText("Level: " .. pLevel)

		local classColor = pClassToken and RAID_CLASS_COLORS[pClassToken]
		if classColor then
			selfTab.classText:SetText(string.format("Klasse: |cff%02x%02x%02x%s|r", classColor.r * 255, classColor.g *
				255, classColor.b * 255, pClassLoc))
		else
			selfTab.classText:SetText("Klasse: " .. pClassLoc)
		end
		selfTab.raceText:SetText("Rasse: " .. pRaceLoc)
		selfTab.zoneText:SetText("Zone: " .. currentZone)
		selfTab.moneyText:SetText("Geld: " .. pMoney)

		local deaths = CharacterDeaths or 0
		selfTab.deathCountText:SetText("Tode: " .. deaths)

		local currentXP = UnitXP("player")
		local maxXP = UnitXPMax("player")
		local restXP = GetXPExhaustion()
		if pLevel == SchlingelInc.Constants.MAX_LEVEL then
			selfTab.xpText:SetText("XP: Max Level")
		else
			local xpString = string.format("XP: %s / %s", currentXP, maxXP)
			if restXP and restXP > 0 then
				xpString = xpString .. string.format(" (|cff80c0ff+%.0f Erholt|r)", restXP)
			end
			selfTab.xpText:SetText(xpString)
		end

		local timePlayedTotalSeconds = SchlingelInc.GameTimeTotal
		local timePlayedLevelSeconds = SchlingelInc.GameTimePerLevel

		selfTab.timePlayedTotalText:SetText("Spielzeit (Gesamt): " .. FormatSeconds(timePlayedTotalSeconds))
		selfTab.timePlayedLevelText:SetText("Spielzeit (Level): " .. FormatSeconds(timePlayedLevelSeconds))

		local gName, gRank = GetGuildInfo("player")
		if gName then
			local numTotal, numOnline = GetNumGuildMembers()
			selfTab.guildNameText:SetText("Gilde: " .. gName)
			selfTab.guildRankText:SetText("Gildenrang: " .. (gRank or "Unbekannt"))
			selfTab.guildMembersText:SetText(string.format("Mitglieder: %d (%d Online)", numTotal or 0, numOnline or 0))
			selfTab.guildNameText:Show()
			selfTab.guildRankText:Show()
			selfTab.guildMembersText:Show()
		else
			selfTab.guildNameText:SetText("Gilde: Nicht in einer Gilde")
			selfTab.guildRankText:Hide()
			selfTab.guildMembersText:Hide()
		end
	end
	return tabFrame
end
