SchlingelInc.Tabs = SchlingelInc.Tabs or {}

SchlingelInc.Tabs.Stats = {
	mainScrollChild = nil,
	leftColumn = nil,
	rightColumn = nil,
	classText = nil,
	levelText = nil,
	rankText = nil,
}

function SchlingelInc.Tabs.Stats:CreateUI(parentFrame)
	local tabFrame = CreateFrame("Frame", nil, parentFrame)
	tabFrame:SetAllPoints()

	SchlingelInc.UIHelpers:CreateStyledText(tabFrame, "Gildenstatistiken - Verteilungen", "GameFontNormal",
		"TOPLEFT", tabFrame, "TOPLEFT", 10, -20)

	local mainScrollFrame = CreateFrame("ScrollFrame", nil, tabFrame, "UIPanelScrollFrameTemplate")
	mainScrollFrame:SetPoint("TOPLEFT", tabFrame, "TOPLEFT", 10, -45)
	mainScrollFrame:SetPoint("BOTTOMRIGHT", tabFrame, "BOTTOMRIGHT", -10, 10)

	local mainScrollChild = CreateFrame("Frame", nil, mainScrollFrame)
	mainScrollChild:SetWidth(mainScrollFrame:GetWidth() - 20)
	mainScrollChild:SetHeight(1)
	mainScrollFrame:SetScrollChild(mainScrollChild)
	self.mainScrollChild = mainScrollChild

	local availableWidth = mainScrollChild:GetWidth()
	local columnWidth = (availableWidth / 2) - 10

	-- Left Column
	local leftColumn = CreateFrame("Frame", nil, mainScrollChild)
	leftColumn:SetPoint("TOPLEFT", 0, -10)
	leftColumn:SetWidth(columnWidth)
	leftColumn:SetHeight(1)
	self.leftColumn = leftColumn

	local classText = SchlingelInc.UIHelpers:CreateStyledText(leftColumn, "Lade Klassenverteilung...", "GameFontNormal",
		"TOPLEFT", leftColumn, "TOPLEFT", 0, 0, columnWidth, nil, "LEFT")
	self.classText = classText

	-- Right Column
	local rightColumn = CreateFrame("Frame", nil, mainScrollChild)
	rightColumn:SetPoint("TOPLEFT", leftColumn, "TOPRIGHT", 15, 0)
	rightColumn:SetWidth(columnWidth)
	rightColumn:SetHeight(1)
	self.rightColumn = rightColumn

	local levelText = SchlingelInc.UIHelpers:CreateStyledText(rightColumn, "Lade Levelverteilung...", "GameFontNormal",
		"TOPLEFT", rightColumn, "TOPLEFT", 0, 0, columnWidth, nil, "LEFT")
	self.levelText = levelText

	local rankText = SchlingelInc.UIHelpers:CreateStyledText(rightColumn, "Lade Rangverteilung...", "GameFontNormal",
		"TOPLEFT", levelText, "BOTTOMLEFT", 0, -15, columnWidth, nil, "LEFT")
	self.rankText = rankText

	self:UpdateData()
	return tabFrame
end

function SchlingelInc.Tabs.Stats:UpdateData()
	if not self.classText or not self.levelText or not self.rankText or
	   not self.mainScrollChild or not self.leftColumn or not self.rightColumn then
		return
	end

	local mainScrollChild = self.mainScrollChild
	local leftColumn = self.leftColumn
	local rightColumn = self.rightColumn
	local classText = self.classText
	local levelText = self.levelText
	local rankText = self.rankText

	local totalGuildMembers, _ = GetNumGuildMembers()
	totalGuildMembers = totalGuildMembers or 0

	if totalGuildMembers == 0 then
		classText:SetText("|cffffff00Klassenverteilung:|r\nKeine Mitglieder.")
		levelText:SetText("|cffffff00Level-Verteilung:|r\nKeine Mitglieder.")
		rankText:SetText("|cffffff00Rang-Verteilung:|r\nKeine Mitglieder.")

		local minHeight = classText:GetStringHeight() + 5
		leftColumn:SetHeight(minHeight)
		rightColumn:SetHeight(minHeight * 2 + 15)
		mainScrollChild:SetHeight(math.max(leftColumn:GetHeight(), rightColumn:GetHeight()) + 20)
		return
	end

	local classDistribution = {}
	local levelBrackets = {
		{minLevel=1, maxLevel=10, count=0, label="1-10"},
		{minLevel=11, maxLevel=20, count=0, label="11-20"},
		{minLevel=21, maxLevel=30, count=0, label="21-30"},
		{minLevel=31, maxLevel=40, count=0, label="31-40"},
		{minLevel=41, maxLevel=50, count=0, label="41-50"},
		{minLevel=51, maxLevel=59, count=0, label="51-59"},
		{minLevel=60, maxLevel=60, count=0, label="60"}
	}
	local rankDistribution = {}
	local classLevelSums = {}

	for i = 1, totalGuildMembers do
		local name, rankName, _, level, classDisplayName, _, _, _, _, _, classToken, _, _, _ = GetGuildRosterInfo(i)
		if name then
			if classToken and classToken ~= "" then
				if not classDistribution[classToken] then
					local localizedName = classDisplayName
					if not localizedName or localizedName == "" then
						localizedName = (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[classToken]) or classToken
					end
					classDistribution[classToken] = {count = 0, localizedName = localizedName}
					classLevelSums[classToken] = {totalLevel = 0, memberCount = 0}
				end
				classDistribution[classToken].count = classDistribution[classToken].count + 1
				if level and level > 0 then
					classLevelSums[classToken].totalLevel = classLevelSums[classToken].totalLevel + level
					classLevelSums[classToken].memberCount = classLevelSums[classToken].memberCount + 1
				end
			end

			if level and level > 0 then
				for _, bracket in ipairs(levelBrackets) do
					if level >= bracket.minLevel and level <= bracket.maxLevel then
						bracket.count = bracket.count + 1
						break
					end
				end
			end

			if rankName and rankName ~= "" then
				rankDistribution[rankName] = (rankDistribution[rankName] or 0) + 1
			end
		end
	end

	-- Class Distribution
	local sortedClasses = {}
	for token, data in pairs(classDistribution) do
		local avgLevel = 0
		if classLevelSums[token] and classLevelSums[token].memberCount > 0 then
			avgLevel = math.floor(classLevelSums[token].totalLevel / classLevelSums[token].memberCount)
		end
		table.insert(sortedClasses, {
			classToken = token,
			localizedName = data.localizedName,
			count = data.count,
			averageLevel = avgLevel
		})
	end
	table.sort(sortedClasses, function(a,b) return a.count > b.count end)

	local classText_str = "|cffffff00Klassenverteilung:|r\n"
	if #sortedClasses == 0 then
		classText_str = classText_str .. "Konnte Klassen nicht ermitteln.\n"
	else
		for _, classEntry in ipairs(sortedClasses) do
			local classColor = (RAID_CLASS_COLORS and RAID_CLASS_COLORS[classEntry.classToken]) or {r=1,g=1,b=1}
			local colorHex = string.format("|cff%02x%02x%02x", classColor.r*255, classColor.g*255, classColor.b*255)
			local percentage = (classEntry.count / totalGuildMembers) * 100
			classText_str = classText_str .. string.format("%s%s|r: %d (|cffffcc00%.1f%%|r, Ø Lvl %d)\n",
				colorHex, classEntry.localizedName, classEntry.count, percentage, classEntry.averageLevel)
		end
	end
	classText:SetText(classText_str)
	local leftHeight = classText:GetStringHeight() + 15
	leftColumn:SetHeight(math.max(50, leftHeight))

	-- Level Distribution
	local rightText = "|cffffff00Level-Verteilung:|r\n"
	local hasLevelData = false
	for _, bracket in ipairs(levelBrackets) do
		if bracket.count > 0 then hasLevelData = true end
		rightText = rightText .. string.format("Level %s: %d\n", bracket.label, bracket.count)
	end
	if not hasLevelData then
		rightText = rightText .. "Keine Leveldaten verfügbar.\n"
	end
	levelText:SetText(rightText)

	-- Rank Distribution
	local sortedRanks = {}
	local hasRankData = false
	for rankName, count in pairs(rankDistribution) do
		table.insert(sortedRanks, { name = rankName, count = count })
		hasRankData = true
	end
	table.sort(sortedRanks, function(a,b) return a.count > b.count end)

	local rankText_str = "\n|cffffff00Rang-Verteilung:|r\n"
	if not hasRankData then
		rankText_str = rankText_str .. "Keine Rangdaten verfügbar.\n"
	else
		for _, rankData in ipairs(sortedRanks) do
			rankText_str = rankText_str .. string.format("%s: %d\n", rankData.name, rankData.count)
		end
	end
	rankText:SetText(rankText_str)
	local rightHeight = levelText:GetStringHeight() + rankText:GetStringHeight() + 30
	rightColumn:SetHeight(math.max(50, rightHeight))

	local totalHeight = math.max(leftHeight, rightHeight) + 20
	mainScrollChild:SetHeight(math.max(mainScrollChild:GetParent():GetHeight(), totalHeight))
end
