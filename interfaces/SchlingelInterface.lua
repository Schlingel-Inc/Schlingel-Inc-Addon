SchlingelInc = SchlingelInc or {}

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

function SchlingelInc:CreateInfoWindow()
	if self.infoWindow then
		self.infoWindow:Show()
		if self.infoWindow.Update then
			self.infoWindow:Update()
		end
		return
	end

	local mainFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	mainFrame:SetSize(500, 320)
	mainFrame:SetPoint("CENTER")
	mainFrame:SetBackdrop(SchlingelInc.Constants.BACKDROP)
	mainFrame:SetMovable(true)
	mainFrame:EnableMouse(true)
	mainFrame:RegisterForDrag("LeftButton")
	mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
	mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)
	mainFrame:SetFrameStrata("MEDIUM")
	mainFrame:Hide()

	-- Header
	local header = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
	header:SetPoint("TOP", mainFrame, "TOP", 0, -15)
	header:SetText("Schlingel Inc Interface")

	-- Close Button
	local closeBtn = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
	closeBtn:SetSize(22, 22)
	closeBtn:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -7, -7)
	closeBtn:SetScript("OnClick", function() mainFrame:Hide() end)

	-- Content Frame
	local contentFrame = CreateFrame("Frame", nil, mainFrame)
	contentFrame:SetPoint("TOPLEFT", 15, -45)
	contentFrame:SetPoint("BOTTOMRIGHT", -15, 15)

	local yOffset = -5

	-- Guild Rules Section (at top)
	local rulesHeader = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	rulesHeader:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, yOffset)
	rulesHeader:SetText("|cffffff00Gildenregeln|r")
	yOffset = yOffset - 20

	local rulesText = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	rulesText:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 5, yOffset)
	rulesText:SetWidth(contentFrame:GetWidth() - 10)
	rulesText:SetJustifyH("LEFT")
	rulesText:SetJustifyV("TOP")
	rulesText:SetText(
		"• Briefkasten verboten\n" ..
		"• Auktionshaus verboten\n" ..
		"• Handeln außerhalb der Gilden verboten"
	)
	yOffset = yOffset - rulesText:GetStringHeight() - 20

	-- Guild MOTD Section
	local motdHeader = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	motdHeader:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, yOffset)
	motdHeader:SetText("|cffffff00Gilden-MOTD|r")
	yOffset = yOffset - 20

	mainFrame.motdText = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	mainFrame.motdText:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 5, yOffset)
	mainFrame.motdText:SetWidth(contentFrame:GetWidth() - 10)
	mainFrame.motdText:SetJustifyH("LEFT")
	mainFrame.motdText:SetJustifyV("TOP")
	mainFrame.motdText:SetText("Lade MOTD...")
	yOffset = yOffset - 35

	-- Two-column layout: Buttons (left) and Statistics (right)
	local leftColumnX = 5
	local rightColumnX = 245
	local columnStartY = yOffset

	-- Left Column: Community Buttons
	local communityHeader = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	communityHeader:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", leftColumnX, columnStartY)
	communityHeader:SetText("|cffffff00Community|r")
	yOffset = columnStartY - 25

	local buttonWidth = 220
	local buttonHeight = 26
	local buttonSpacing = 8

	-- Guild Join Button (only show if not in guild)
	mainFrame.guildJoinBtn = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
	mainFrame.guildJoinBtn:SetSize(buttonWidth, buttonHeight)
	mainFrame.guildJoinBtn:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", leftColumnX, yOffset)
	mainFrame.guildJoinBtn:SetText("Schlingel Inc beitreten")
	mainFrame.guildJoinBtn:SetScript("OnClick", function()
		SchlingelInc.GuildRecruitment:SendGuildRequest()
	end)

	-- Leave Global Channels Button (only show if in guild)
	mainFrame.leaveChannelsBtn = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
	mainFrame.leaveChannelsBtn:SetSize(buttonWidth, buttonHeight)
	mainFrame.leaveChannelsBtn:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", leftColumnX, yOffset)
	mainFrame.leaveChannelsBtn:SetText("Globale Kanäle verlassen")
	mainFrame.leaveChannelsBtn:SetScript("OnClick", function()
		local channelsToLeave = {
			"Allgemein", "General", "Handel", "Trade",
			"LokaleVerteidigung", "LocalDefense",
			"SucheNachGruppe", "LookingForGroup",
			"WeltVerteidigung", "WorldDefense"
		}
		for _, channelName in ipairs(channelsToLeave) do
			LeaveChannelByName(channelName)
		end
		SchlingelInc:Print("Globale Kanäle verlassen.")
	end)
	yOffset = yOffset - buttonHeight - buttonSpacing

	-- Join Schlingel Channels Button (only show if in guild)
	mainFrame.joinSchlingelBtn = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
	mainFrame.joinSchlingelBtn:SetSize(buttonWidth, buttonHeight)
	mainFrame.joinSchlingelBtn:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", leftColumnX, yOffset)
	mainFrame.joinSchlingelBtn:SetText("Schlingel-Chats beitreten")
	mainFrame.joinSchlingelBtn:SetScript("OnClick", function()
		if not ChatFrame1 then return end
		local cID = ChatFrame1:GetID()
		JoinChannelByName("SchlingelTrade", nil, cID, false)
		JoinChannelByName("SchlingelGroup", nil, cID, false)
		SchlingelInc:Print("Versuche Schlingel-Chats beizutreten.")
	end)

	-- Right Column: Statistics
	local statsYOffset = columnStartY

	local statsHeader = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	statsHeader:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", rightColumnX, statsYOffset)
	statsHeader:SetText("|cffffff00Statistiken|r")
	statsYOffset = statsYOffset - 20

	mainFrame.deathCountText = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	mainFrame.deathCountText:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", rightColumnX, statsYOffset)
	mainFrame.deathCountText:SetText("Tode: ...")
	statsYOffset = statsYOffset - 18

	mainFrame.timePlayedTotalText = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	mainFrame.timePlayedTotalText:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", rightColumnX, statsYOffset)
	mainFrame.timePlayedTotalText:SetText("Spielzeit (Gesamt): Lade...")
	statsYOffset = statsYOffset - 18

	mainFrame.timePlayedLevelText = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	mainFrame.timePlayedLevelText:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", rightColumnX, statsYOffset)
	mainFrame.timePlayedLevelText:SetText("Spielzeit (Level): Lade...")

	-- Update function
	local function UpdateWindow()
		-- Death count
		local deaths = CharacterDeaths or 0
		mainFrame.deathCountText:SetText("Tode: " .. deaths)

		-- Time played
		local timePlayedTotal = SchlingelInc.GameTimeTotal
		local timePlayedLevel = SchlingelInc.GameTimePerLevel
		mainFrame.timePlayedTotalText:SetText("Spielzeit (Gesamt): " .. FormatSeconds(timePlayedTotal))
		mainFrame.timePlayedLevelText:SetText("Spielzeit (Level): " .. FormatSeconds(timePlayedLevel))

		-- Guild MOTD
		local guildMOTD = GetGuildRosterMOTD()
		if guildMOTD and guildMOTD ~= "" then
			mainFrame.motdText:SetText(guildMOTD)
		else
			mainFrame.motdText:SetText("Keine Gilden-MOTD festgelegt.")
		end

		-- Show/hide buttons and resize window based on guild membership
		local guildName = GetGuildInfo("player")
		if guildName then
			-- In guild: show chat buttons, hide join button
			mainFrame.guildJoinBtn:Hide()
			mainFrame.leaveChannelsBtn:Show()
			mainFrame.joinSchlingelBtn:Show()
			mainFrame:SetSize(500, 320)
		else
			-- Not in guild: show join button, hide chat buttons
			mainFrame.guildJoinBtn:Show()
			mainFrame.leaveChannelsBtn:Hide()
			mainFrame.joinSchlingelBtn:Hide()
			mainFrame:SetSize(500, 260)
		end
	end

	mainFrame.Update = UpdateWindow

	self.infoWindow = mainFrame
	UpdateWindow()
	mainFrame:Show()
end

function SchlingelInc:ToggleInfoWindow()
	if not self.infoWindow then
		self:CreateInfoWindow()
	elseif self.infoWindow:IsShown() then
		self.infoWindow:Hide()
	else
		self.infoWindow:Show()
		if self.infoWindow.Update then
			self.infoWindow:Update()
		end
	end
end
