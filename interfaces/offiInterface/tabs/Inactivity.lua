SchlingelInc.Tabs = SchlingelInc.Tabs or {}

SchlingelInc.Tabs.Inactivity = {
	scrollFrame = nil,
	scrollChild = nil,
	inactiveListUIElements = {},
}

function SchlingelInc.Tabs.Inactivity:CreateUI(parentFrame)
	local tabFrame = CreateFrame("Frame", nil, parentFrame)
	tabFrame:SetAllPoints()

	local titleText = string.format("Inaktive Mitglieder (> %d Tage)", SchlingelInc.Constants.INACTIVE_DAYS_THRESHOLD)
	SchlingelInc.UIHelpers:CreateLabel(tabFrame, titleText, 10, -20)

	local scrollFrame, scrollChild = SchlingelInc.UIHelpers:CreateScrollFrame(tabFrame, {
		width = 560,
		height = 350,
		point = {"TOPLEFT", 10, -45},
		childWidth = 560 - 10,
		childHeight = 1
	})
	self.scrollFrame = scrollFrame
	self.scrollChild = scrollChild

	-- Column Headers
	local headers = CreateFrame("Frame", nil, scrollChild)
	headers:SetPoint("TOPLEFT", 5, -5)
	headers:SetSize(550, 20)

	SchlingelInc.UIHelpers:CreateStyledText(headers, "Name", "GameFontHighlightSmall",
		"TOPLEFT", headers, "TOPLEFT", 0, 0, 150, nil, "LEFT")
	SchlingelInc.UIHelpers:CreateStyledText(headers, "Level", "GameFontHighlightSmall",
		"LEFT", headers, "LEFT", 160, 0, 40, nil, "CENTER")
	SchlingelInc.UIHelpers:CreateStyledText(headers, "Rang", "GameFontHighlightSmall",
		"LEFT", headers, "LEFT", 210, 0, 120, nil, "LEFT")
	SchlingelInc.UIHelpers:CreateStyledText(headers, "Offline Seit", "GameFontHighlightSmall",
		"LEFT", headers, "LEFT", 340, 0, 80, nil, "LEFT")

	self.inactiveListUIElements = {}
	self:UpdateData()

	return tabFrame
end

function SchlingelInc.Tabs.Inactivity:UpdateData()
	if not self.scrollChild or not self.inactiveListUIElements or not self.scrollFrame then
		return
	end

	local scrollChild = self.scrollChild
	local uiElements = self.inactiveListUIElements
	local scrollFrame = self.scrollFrame

	-- Clear old UI elements
	for _, elementGroup in ipairs(uiElements) do
		if elementGroup.rowFrame then
			elementGroup.rowFrame:Hide()
			elementGroup.rowFrame:SetParent(nil)
		end
	end
	wipe(uiElements)

	local totalGuildMembers, _ = GetNumGuildMembers()
	totalGuildMembers = totalGuildMembers or 0

	local inactiveMembers = {}

	if totalGuildMembers > 0 then
		for i = 1, totalGuildMembers do
			local name, rankName, _, level, _, _, publicNote, _, isOnline, _, _, _, _, _ = GetGuildRosterInfo(i)

			if name and not isOnline then
				local yearsOffline, monthsOffline, daysOffline, hoursOffline = GetGuildRosterLastOnline(i)

				local isInactive = false
				local displayDuration = "Unbekannt"
				local totalDays = 0

				yearsOffline = yearsOffline or 0
				monthsOffline = monthsOffline or 0
				daysOffline = daysOffline or 0
				hoursOffline = hoursOffline or 0

				totalDays = (yearsOffline * 365) + (monthsOffline * 30) + daysOffline + (hoursOffline / 24)

				if yearsOffline > 0 then
					isInactive = true
					displayDuration = string.format("%d J", yearsOffline)
				elseif monthsOffline > 0 then
					isInactive = true
					displayDuration = string.format("%d M", monthsOffline)
				elseif daysOffline >= SchlingelInc.Constants.INACTIVE_DAYS_THRESHOLD then
					isInactive = true
					displayDuration = string.format("%d T", daysOffline)
				elseif SchlingelInc.Constants.INACTIVE_DAYS_THRESHOLD == 0 then
					isInactive = true
					if daysOffline > 0 then
						displayDuration = string.format("%d T", daysOffline)
					elseif hoursOffline > 0 then
						displayDuration = string.format("%d Std", hoursOffline)
					else
						displayDuration = "<1 Std"
					end
				end

				if isInactive then
					table.insert(inactiveMembers, {
						name = name,
						level = level or 0,
						rank = rankName or "Unbekannt",
						note = publicNote or "",
						displayDuration = displayDuration,
						sortableDays = totalDays
					})
				end
			end
		end
	end

	-- Sort: longest offline first, then by level
	table.sort(inactiveMembers, function(a, b)
		if a.sortableDays == b.sortableDays then
			return (a.level or 0) > (b.level or 0)
		end
		return a.sortableDays > b.sortableDays
	end)

	local yOffset = -25
	local rowHeight = 20
	local xOffsets = { name = 5, level = 160, rank = 210, duration = 340, kick = 430 }
	local colWidths = { name = 150, level = 40, rank = 120, duration = 80, kick = 80 }

	if #inactiveMembers > 0 then
		for i, member in ipairs(inactiveMembers) do
			local rowFrame = CreateFrame("Frame", nil, scrollChild)
			rowFrame:SetSize(scrollChild:GetWidth(), rowHeight)
			rowFrame:SetPoint("TOPLEFT", 0, yOffset)

			local nameText = member.name
			if SchlingelInc and SchlingelInc.RemoveRealmFromName then
				nameText = SchlingelInc:RemoveRealmFromName(member.name)
			end

			SchlingelInc.UIHelpers:CreateStyledText(rowFrame, nameText, "GameFontNormal",
				"TOPLEFT", rowFrame, "TOPLEFT", xOffsets.name, 0, colWidths.name, nil, "LEFT", "MIDDLE")
			SchlingelInc.UIHelpers:CreateStyledText(rowFrame, member.level, "GameFontNormal",
				"TOPLEFT", rowFrame, "TOPLEFT", xOffsets.level, 0, colWidths.level, nil, "CENTER", "MIDDLE")
			SchlingelInc.UIHelpers:CreateStyledText(rowFrame, member.rank, "GameFontNormal",
				"TOPLEFT", rowFrame, "TOPLEFT", xOffsets.rank, 0, colWidths.rank, nil, "LEFT", "MIDDLE")
			SchlingelInc.UIHelpers:CreateStyledText(rowFrame, member.displayDuration, "GameFontNormal",
				"TOPLEFT", rowFrame, "TOPLEFT", xOffsets.duration, 0, colWidths.duration, nil, "LEFT", "MIDDLE")

			if CanGuildRemove("player") then
				local kickButton = SchlingelInc.UIHelpers:CreateStyledButton(rowFrame, "Entfernen", colWidths.kick, rowHeight - 2,
					"TOPLEFT", rowFrame, "TOPLEFT", xOffsets.kick, 0, "UIPanelButtonTemplate")
				kickButton:SetScript("OnClick", function()
					StaticPopup_Show("CONFIRM_GUILD_KICK", member.name, nil, { memberName = member.name })
				end)
			end

			table.insert(uiElements, { rowFrame = rowFrame })
			yOffset = yOffset - rowHeight
		end
		scrollChild:SetHeight(math.max(1, (#inactiveMembers * rowHeight) + 30))
	else
		local noInactiveText = SchlingelInc.UIHelpers:CreateStyledText(scrollChild,
			"Keine inaktiven Mitglieder (> ".. SchlingelInc.Constants.INACTIVE_DAYS_THRESHOLD .." T) gefunden.", "GameFontNormal",
			"TOP", scrollChild, "TOP", 0, yOffset, scrollChild:GetWidth() - 10, nil, "CENTER")
		table.insert(uiElements, { rowFrame = noInactiveText })
		scrollChild:SetHeight(noInactiveText:GetStringHeight() + 30)
	end

	scrollFrame:SetVerticalScroll(0)
end
