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

	local col1, col2 = SchlingelInc.UIHelpers:CreateTwoColumnLayout(contentFrame, {
		leftX = 0,
		rightX = contentFrame:GetWidth() * 0.55,
		startY = 0,
		lineHeight = 22
	})

	-- Column 1
	tabFrame.playerNameText = col1:AddLabel("Name: ...")
	tabFrame.levelText = col1:AddLabel("Level: ...")
	tabFrame.classText = col1:AddLabel("Klasse: ...")
	tabFrame.raceText = col1:AddLabel("Rasse: ...")
	tabFrame.zoneText = col1:AddLabel("Zone: ...")
	tabFrame.deathCountText = col1:AddLabel("Tode: ...")

	-- Column 2
	tabFrame.moneyText = col2:AddLabel("Geld: ...")
	tabFrame.xpText = col2:AddLabel("XP: ...")
	tabFrame.timePlayedTotalText = col2:AddLabel("Spielzeit (Gesamt): Lade...")
	tabFrame.timePlayedLevelText = col2:AddLabel("Spielzeit (Level): Lade...")

	-- Guild Info (below both columns)
	local guildYStart = math.min(col1:GetCurrentY(), col2:GetCurrentY()) - 22
	tabFrame.guildNameText = SchlingelInc.UIHelpers:CreateLabel(contentFrame, "Gilde: ...", 0, guildYStart)
	guildYStart = guildYStart - 22
	tabFrame.guildRankText = SchlingelInc.UIHelpers:CreateLabel(contentFrame, "Gildenrang: ...", 0, guildYStart)
	guildYStart = guildYStart - 22
	tabFrame.guildMembersText = SchlingelInc.UIHelpers:CreateLabel(contentFrame, "Mitglieder: ...", 0, guildYStart)

	tabFrame.Update = function(selfTab)

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
