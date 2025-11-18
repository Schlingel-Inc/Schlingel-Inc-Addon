SchlingelInc = SchlingelInc or {}

function SchlingelInc:CreateOffiWindow()
	if self.OffiWindow then return end

	local offiFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	offiFrame:SetSize(650, 550)
	offiFrame:SetPoint("RIGHT", -50, 25)
	offiFrame:SetBackdrop(SchlingelInc.Constants.BACKDROP)
	offiFrame:SetMovable(true)
	offiFrame:EnableMouse(true)
	offiFrame:RegisterForDrag("LeftButton")
	offiFrame:SetScript("OnDragStart", offiFrame.StartMoving)
	offiFrame:SetScript("OnDragStop", offiFrame.StopMovingOrSizing)
	offiFrame:Hide()

	-- Header
	local header = offiFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
	header:SetPoint("TOP", offiFrame, "TOP", 0, -15)
	header:SetText("Schlingel Inc - Offi Interface")

	-- Close Button
	local closeBtn = CreateFrame("Button", nil, offiFrame, "UIPanelCloseButton")
	closeBtn:SetSize(22, 22)
	closeBtn:SetPoint("TOPRIGHT", offiFrame, "TOPRIGHT", -7, -7)
	closeBtn:SetScript("OnClick", function() offiFrame:Hide() end)

	-- Create main scroll frame
	local scrollFrame = CreateFrame("ScrollFrame", nil, offiFrame, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", offiFrame, "TOPLEFT", 15, -50)
	scrollFrame:SetPoint("BOTTOMRIGHT", offiFrame, "BOTTOMRIGHT", -30, 15)

	local scrollChild = CreateFrame("Frame", nil, scrollFrame)
	scrollChild:SetWidth(scrollFrame:GetWidth() - 20)
	scrollChild:SetHeight(1)
	scrollFrame:SetScrollChild(scrollChild)

	local yOffset = -10

	-- Guild Average Level Section
	local avgLevelHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	avgLevelHeader:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, yOffset)
	avgLevelHeader:SetText("|cffffff00Durchschnittslevel|r")
	yOffset = yOffset - 25

	offiFrame.avgLevelText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	offiFrame.avgLevelText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
	offiFrame.avgLevelText:SetText("Lade...")
	yOffset = yOffset - 35

	-- Statistics Section Header
	local statsHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	statsHeader:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, yOffset)
	statsHeader:SetText("|cffffff00Gildenstatistiken|r")
	yOffset = yOffset - 30

	-- Two-column layout for stats
	local columnWidth = (scrollChild:GetWidth() / 2) - 15
	local leftX = 10
	local rightX = scrollChild:GetWidth() / 2 + 5

	-- Left column: Class Distribution
	offiFrame.classStatsText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	offiFrame.classStatsText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", leftX, yOffset)
	offiFrame.classStatsText:SetWidth(columnWidth)
	offiFrame.classStatsText:SetJustifyH("LEFT")
	offiFrame.classStatsText:SetJustifyV("TOP")
	offiFrame.classStatsText:SetText("Lade Klassenverteilung...")

	-- Right column: Level and Rank Distribution
	offiFrame.levelRankStatsText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	offiFrame.levelRankStatsText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", rightX, yOffset)
	offiFrame.levelRankStatsText:SetWidth(columnWidth)
	offiFrame.levelRankStatsText:SetJustifyH("LEFT")
	offiFrame.levelRankStatsText:SetJustifyV("TOP")
	offiFrame.levelRankStatsText:SetText("Lade Level- und Rangverteilung...")

	yOffset = yOffset - 300 -- Space for stats content

	-- Inactive Members Section
	local inactiveHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	inactiveHeader:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, yOffset)
	inactiveHeader:SetText(string.format("|cffffff00Inaktive Mitglieder (> %d Tage)|r", SchlingelInc.Constants.INACTIVE_DAYS_THRESHOLD))
	yOffset = yOffset - 30

	-- Inactive members table headers
	local inactiveHeaders = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	inactiveHeaders:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
	inactiveHeaders:SetWidth(scrollChild:GetWidth() - 20)
	inactiveHeaders:SetJustifyH("LEFT")
	inactiveHeaders:SetText("Name                       Level    Rang                    Offline Seit")
	yOffset = yOffset - 20

	-- Container for inactive member rows
	offiFrame.inactiveContainer = CreateFrame("Frame", nil, scrollChild)
	offiFrame.inactiveContainer:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
	offiFrame.inactiveContainer:SetWidth(scrollChild:GetWidth() - 20)
	offiFrame.inactiveContainer:SetHeight(1)

	offiFrame.inactiveRows = {}

	-- Update function
	local function UpdateOffiWindow()
		-- Calculate average guild level
		local totalGuildMembers, _ = GetNumGuildMembers()
		totalGuildMembers = totalGuildMembers or 0

		if totalGuildMembers == 0 then
			offiFrame.avgLevelText:SetText("Keine Mitglieder in der Gilde.")
			offiFrame.classStatsText:SetText("|cff69ccf0Klassenverteilung:|r\nKeine Mitglieder.")
			offiFrame.levelRankStatsText:SetText("|cff69ccf0Level-Verteilung:|r\nKeine Mitglieder.")
		else
			local totalLevelSum = 0
			local membersCountedForAvg = 0
			local classDistribution = {}
			local classLevelSums = {}
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
			local inactiveMembers = {}

			for i = 1, totalGuildMembers do
				local name, rankName, _, level, classDisplayName, _, _, _, isOnline, _, classToken, _, _, _ = GetGuildRosterInfo(i)

				if name and level and level > 0 then
					totalLevelSum = totalLevelSum + level
					membersCountedForAvg = membersCountedForAvg + 1

					-- Class distribution
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
						classLevelSums[classToken].totalLevel = classLevelSums[classToken].totalLevel + level
						classLevelSums[classToken].memberCount = classLevelSums[classToken].memberCount + 1
					end

					-- Level brackets
					for _, bracket in ipairs(levelBrackets) do
						if level >= bracket.minLevel and level <= bracket.maxLevel then
							bracket.count = bracket.count + 1
							break
						end
					end
				end

				-- Rank distribution
				if rankName and rankName ~= "" then
					rankDistribution[rankName] = (rankDistribution[rankName] or 0) + 1
				end

				-- Inactive members
				if name and not isOnline then
					local yearsOffline, monthsOffline, daysOffline, hoursOffline = GetGuildRosterLastOnline(i)
					yearsOffline = yearsOffline or 0
					monthsOffline = monthsOffline or 0
					daysOffline = daysOffline or 0
					hoursOffline = hoursOffline or 0

					local totalDays = (yearsOffline * 365) + (monthsOffline * 30) + daysOffline + (hoursOffline / 24)
					local isInactive = false
					local displayDuration = "Unbekannt"

					if yearsOffline > 0 then
						isInactive = true
						displayDuration = string.format("%d J", yearsOffline)
					elseif monthsOffline > 0 then
						isInactive = true
						displayDuration = string.format("%d M", monthsOffline)
					elseif daysOffline >= SchlingelInc.Constants.INACTIVE_DAYS_THRESHOLD then
						isInactive = true
						displayDuration = string.format("%d T", daysOffline)
					end

					if isInactive then
						local displayName = name
						if SchlingelInc and SchlingelInc.RemoveRealmFromName then
							displayName = SchlingelInc:RemoveRealmFromName(name)
						end
						table.insert(inactiveMembers, {
							name = displayName,
							fullName = name,
							level = level or 0,
							rank = rankName or "Unbekannt",
							displayDuration = displayDuration,
							sortableDays = totalDays
						})
					end
				end
			end

			-- Update average level
			local avgLevelText = "N/A"
			if membersCountedForAvg > 0 then
				avgLevelText = string.format("%d", math.floor(totalLevelSum / membersCountedForAvg))
			end
			offiFrame.avgLevelText:SetText("Durchschnittslevel der Gilde: " .. avgLevelText)

			-- Build class stats text
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

			local classText = "|cff69ccf0Klassenverteilung:|r\n"
			if #sortedClasses == 0 then
				classText = classText .. "Keine Daten verfügbar.\n"
			else
				for _, classEntry in ipairs(sortedClasses) do
					local classColor = (RAID_CLASS_COLORS and RAID_CLASS_COLORS[classEntry.classToken]) or {r=1,g=1,b=1}
					local colorHex = string.format("|cff%02x%02x%02x", classColor.r*255, classColor.g*255, classColor.b*255)
					local percentage = (classEntry.count / totalGuildMembers) * 100
					classText = classText .. string.format("%s%s|r: %d (%.1f%%, Ø %d)\n",
						colorHex, classEntry.localizedName, classEntry.count, percentage, classEntry.averageLevel)
				end
			end
			offiFrame.classStatsText:SetText(classText)

			-- Build level and rank stats text
			local levelRankText = "|cff69ccf0Level-Verteilung:|r\n"
			for _, bracket in ipairs(levelBrackets) do
				levelRankText = levelRankText .. string.format("Level %s: %d\n", bracket.label, bracket.count)
			end

			local sortedRanks = {}
			for rankName, count in pairs(rankDistribution) do
				table.insert(sortedRanks, { name = rankName, count = count })
			end
			table.sort(sortedRanks, function(a,b) return a.count > b.count end)

			levelRankText = levelRankText .. "\n|cff69ccf0Rang-Verteilung:|r\n"
			if #sortedRanks == 0 then
				levelRankText = levelRankText .. "Keine Daten verfügbar.\n"
			else
				for _, rankData in ipairs(sortedRanks) do
					levelRankText = levelRankText .. string.format("%s: %d\n", rankData.name, rankData.count)
				end
			end
			offiFrame.levelRankStatsText:SetText(levelRankText)

			-- Update inactive members list
			-- Clear old rows
			for _, row in ipairs(offiFrame.inactiveRows) do
				row:Hide()
				row:SetParent(nil)
			end
			wipe(offiFrame.inactiveRows)

			-- Sort inactive members
			table.sort(inactiveMembers, function(a, b)
				if a.sortableDays == b.sortableDays then
					return (a.level or 0) > (b.level or 0)
				end
				return a.sortableDays > b.sortableDays
			end)

			local rowYOffset = 0
			local rowHeight = 20

			if #inactiveMembers > 0 then
				for i, member in ipairs(inactiveMembers) do
					local rowFrame = CreateFrame("Frame", nil, offiFrame.inactiveContainer)
					rowFrame:SetSize(offiFrame.inactiveContainer:GetWidth(), rowHeight)
					rowFrame:SetPoint("TOPLEFT", 0, rowYOffset)

					-- Name (truncate if too long)
					local nameText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
					nameText:SetPoint("TOPLEFT", rowFrame, "TOPLEFT", 0, 0)
					nameText:SetWidth(150)
					nameText:SetJustifyH("LEFT")
					nameText:SetText(member.name)

					-- Level
					local levelText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
					levelText:SetPoint("TOPLEFT", rowFrame, "TOPLEFT", 160, 0)
					levelText:SetWidth(40)
					levelText:SetJustifyH("CENTER")
					levelText:SetText(member.level)

					-- Rank
					local rankText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
					rankText:SetPoint("TOPLEFT", rowFrame, "TOPLEFT", 210, 0)
					rankText:SetWidth(120)
					rankText:SetJustifyH("LEFT")
					rankText:SetText(member.rank)

					-- Offline Duration
					local durationText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
					durationText:SetPoint("TOPLEFT", rowFrame, "TOPLEFT", 340, 0)
					durationText:SetWidth(80)
					durationText:SetJustifyH("LEFT")
					durationText:SetText(member.displayDuration)

					-- Kick button (if player has permission)
					if CanGuildRemove() then
						local kickBtn = CreateFrame("Button", nil, rowFrame, "UIPanelButtonTemplate")
						kickBtn:SetSize(80, rowHeight - 2)
						kickBtn:SetPoint("TOPLEFT", rowFrame, "TOPLEFT", 430, 0)
						kickBtn:SetText("Entfernen")
						kickBtn:SetScript("OnClick", function()
							StaticPopup_Show("CONFIRM_GUILD_KICK", member.fullName, nil, { memberName = member.fullName })
						end)
					end

					table.insert(offiFrame.inactiveRows, rowFrame)
					rowYOffset = rowYOffset - rowHeight
				end
				offiFrame.inactiveContainer:SetHeight(math.max(1, #inactiveMembers * rowHeight))
			else
				local noInactiveText = offiFrame.inactiveContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
				noInactiveText:SetPoint("TOP", offiFrame.inactiveContainer, "TOP", 0, 0)
				noInactiveText:SetText("Keine inaktiven Mitglieder gefunden.")
				table.insert(offiFrame.inactiveRows, noInactiveText)
				offiFrame.inactiveContainer:SetHeight(20)
			end
		end

		-- Calculate total scroll height
		local totalHeight = math.max(
			offiFrame.classStatsText:GetStringHeight(),
			offiFrame.levelRankStatsText:GetStringHeight()
		) + offiFrame.inactiveContainer:GetHeight() + 500

		scrollChild:SetHeight(math.max(scrollFrame:GetHeight(), totalHeight))
		scrollFrame:SetVerticalScroll(0)
	end

	offiFrame.Update = UpdateOffiWindow

	self.OffiWindow = offiFrame
end

function SchlingelInc:ToggleOffiWindow()
	if not self.OffiWindow then
		self:CreateOffiWindow()
	end

	if not self.OffiWindow then
		SchlingelInc:Print("OffiWindow konnte nicht erstellt/gefunden werden!")
		return
	end

	if self.OffiWindow:IsShown() then
		self.OffiWindow:Hide()
	else
		self.OffiWindow:Show()
		if self.OffiWindow.Update then
			self.OffiWindow:Update()
		end
	end
end
