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
		return
	end

	local mainFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	mainFrame:SetSize(600, 420)
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
	contentFrame:SetPoint("TOPLEFT", 20, -50)
	contentFrame:SetPoint("BOTTOMRIGHT", -20, 20)

	local yOffset = -10

	-- Statistics Section
	local statsHeader = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	statsHeader:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, yOffset)
	statsHeader:SetText("|cffffff00Statistiken|r")
	yOffset = yOffset - 25

	mainFrame.deathCountText = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	mainFrame.deathCountText:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 10, yOffset)
	mainFrame.deathCountText:SetText("Tode: ...")
	yOffset = yOffset - 20

	mainFrame.timePlayedTotalText = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	mainFrame.timePlayedTotalText:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 10, yOffset)
	mainFrame.timePlayedTotalText:SetText("Spielzeit (Gesamt): Lade...")
	yOffset = yOffset - 20

	mainFrame.timePlayedLevelText = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	mainFrame.timePlayedLevelText:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 10, yOffset)
	mainFrame.timePlayedLevelText:SetText("Spielzeit (Level): Lade...")
	yOffset = yOffset - 30

	-- Guild Rules Section
	local rulesHeader = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	rulesHeader:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, yOffset)
	rulesHeader:SetText("|cffffff00Gildenregeln|r")
	yOffset = yOffset - 25

	local rulesText = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	rulesText:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 10, yOffset)
	rulesText:SetPoint("RIGHT", contentFrame, "RIGHT", -10, 0)
	rulesText:SetJustifyH("LEFT")
	rulesText:SetJustifyV("TOP")
	rulesText:SetText(
		"• Die Nutzung des Briefkastens ist verboten!\n\n" ..
		"• Die Nutzung des Auktionshauses ist verboten!\n\n" ..
		"• Handeln mit Spielern außerhalb der Gilden ist verboten!"
	)
	yOffset = yOffset - rulesText:GetStringHeight() - 30

	-- Guild MOTD Section
	local motdHeader = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	motdHeader:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, yOffset)
	motdHeader:SetText("|cffffff00Gilden-MOTD|r")
	yOffset = yOffset - 25

	mainFrame.motdText = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	mainFrame.motdText:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 10, yOffset)
	mainFrame.motdText:SetPoint("RIGHT", contentFrame, "RIGHT", -10, 0)
	mainFrame.motdText:SetJustifyH("LEFT")
	mainFrame.motdText:SetJustifyV("TOP")
	mainFrame.motdText:SetText("Lade MOTD...")
	yOffset = yOffset - 60

	-- Community Buttons Section
	local communityHeader = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	communityHeader:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, yOffset)
	communityHeader:SetText("|cffffff00Community|r")
	yOffset = yOffset - 30

	local buttonWidth = 250
	local buttonHeight = 30
	local buttonSpacing = 10
	local centerX = (contentFrame:GetWidth() - buttonWidth) / 2

	-- Guild Join Button
	local guildJoinBtn = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
	guildJoinBtn:SetSize(buttonWidth, buttonHeight)
	guildJoinBtn:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", centerX, yOffset)
	guildJoinBtn:SetText("Schlingel Inc beitreten")
	guildJoinBtn:SetScript("OnClick", function()
		SchlingelInc.GuildRecruitment:SendGuildRequest()
	end)
	yOffset = yOffset - buttonHeight - buttonSpacing

	-- Leave Global Channels Button
	local leaveChannelsBtn = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
	leaveChannelsBtn:SetSize(buttonWidth, buttonHeight)
	leaveChannelsBtn:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", centerX, yOffset)
	leaveChannelsBtn:SetText("Globale Kanäle verlassen")
	leaveChannelsBtn:SetScript("OnClick", function()
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

	-- Join Schlingel Channels Button
	local joinSchlingelBtn = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
	joinSchlingelBtn:SetSize(buttonWidth, buttonHeight)
	joinSchlingelBtn:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", centerX, yOffset)
	joinSchlingelBtn:SetText("Schlingel-Chats beitreten")
	joinSchlingelBtn:SetScript("OnClick", function()
		if not ChatFrame1 then return end
		local cID = ChatFrame1:GetID()
		JoinChannelByName("SchlingelTrade", nil, cID, false)
		JoinChannelByName("SchlingelGroup", nil, cID, false)
		SchlingelInc:Print("Versuche Schlingel-Chats beizutreten.")
	end)
	yOffset = yOffset - buttonHeight - 20

	-- Info Section (Discord and Version)
	mainFrame.discordText = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	mainFrame.discordText:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", centerX, yOffset)
	mainFrame.discordText:SetPoint("RIGHT", contentFrame, "RIGHT", -centerX, 0)
	mainFrame.discordText:SetJustifyH("CENTER")
	mainFrame.discordText:SetText("Discord: ...")
	yOffset = yOffset - 20

	mainFrame.versionText = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	mainFrame.versionText:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", centerX, yOffset)
	mainFrame.versionText:SetPoint("RIGHT", contentFrame, "RIGHT", -centerX, 0)
	mainFrame.versionText:SetJustifyH("CENTER")
	mainFrame.versionText:SetText("Version: ...")

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

		-- Discord and Version
		mainFrame.discordText:SetText("Discord: " .. (SchlingelInc.discordLink or "N/A"))
		mainFrame.versionText:SetText("Version: " .. (SchlingelInc.version or "N/A"))
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
