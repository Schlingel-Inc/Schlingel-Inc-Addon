SchlingelInc.SITabs = SchlingelInc.SITabs or {}

SchlingelInc.SITabs.Community = {}

function SchlingelInc.SITabs.Community:CreateUI(parentFrame)
	local tabFrame = CreateFrame("Frame", nil, parentFrame)
	tabFrame:SetAllPoints()

	local buttonWidth = 220
	local buttonHeight = 30
	local buttonSpacingY = 10
	local col1X = (parentFrame:GetWidth() - (buttonWidth * 2 + 40)) / 2
	local col2X = col1X + buttonWidth + 40
	local currentY_Labels = -20
	local currentY_Buttons = currentY_Labels - 30

	-- Column 1: Guild Join
	SchlingelInc.UIHelpers:CreateStyledText(tabFrame, "Gildenbeitritt:", "GameFontNormal", "TOPLEFT", tabFrame, "TOPLEFT", col1X,
		currentY_Labels)
	local currentY_Col1_Buttons = currentY_Buttons

	local joinMainGuildBtnFunc = function()
		SchlingelInc.GuildRecruitment:SendGuildRequest()
	end
	SchlingelInc.UIHelpers:CreateStyledButton(tabFrame, "Schlingel Inc beitreten", buttonWidth, buttonHeight, "TOPLEFT", tabFrame,
		"TOPLEFT", col1X, currentY_Col1_Buttons, "UIPanelButtonTemplate", joinMainGuildBtnFunc)
	currentY_Col1_Buttons = currentY_Col1_Buttons - buttonHeight - buttonSpacingY

	-- Column 2: Channels
	SchlingelInc.UIHelpers:CreateStyledText(tabFrame, "Chatkanäle:", "GameFontNormal", "TOPLEFT", tabFrame, "TOPLEFT", col2X,
		currentY_Labels)
	local currentY_Col2_Buttons = currentY_Buttons

	local leaveChannelsBtnFunc = function()
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
	end

	SchlingelInc.UIHelpers:CreateStyledButton(tabFrame, "Globale Kanäle verlassen", buttonWidth, buttonHeight, "TOPLEFT",
		tabFrame, "TOPLEFT", col2X, currentY_Col2_Buttons, "UIPanelButtonTemplate", leaveChannelsBtnFunc)
	currentY_Col2_Buttons = currentY_Col2_Buttons - buttonHeight - buttonSpacingY

	local joinChannelsBtnFunc = function()
		if not ChatFrame1 then
			return
		end
		local cID = ChatFrame1:GetID()
		JoinChannelByName("SchlingelTrade", nil, cID, false)
		JoinChannelByName("SchlingelGroup", nil, cID, false)
		SchlingelInc:Print("Versuche Schlingel-Chats beizutreten.")
	end
	SchlingelInc.UIHelpers:CreateStyledButton(tabFrame, "Schlingel-Chats beitreten", buttonWidth, buttonHeight, "TOPLEFT",
		tabFrame, "TOPLEFT", col2X, currentY_Col2_Buttons, "UIPanelButtonTemplate", joinChannelsBtnFunc)

	-- Info section
	local infoY = math.min(currentY_Col1_Buttons, currentY_Col2_Buttons) - buttonHeight - (buttonSpacingY * 2)
	local infoWidth = (buttonWidth * 2) + 30

	tabFrame.discordText = SchlingelInc.UIHelpers:CreateStyledText(tabFrame, "Discord: ...", "GameFontNormal",
		"TOPLEFT", tabFrame, "TOPLEFT", col1X, infoY, infoWidth, nil, "CENTER")
	infoY = infoY - 25

	tabFrame.versionText = SchlingelInc.UIHelpers:CreateStyledText(tabFrame, "Version: ...", "GameFontNormal",
		"TOPLEFT", tabFrame, "TOPLEFT", col1X, infoY, infoWidth, nil, "CENTER")

	tabFrame.Update = function(selfTab)
		selfTab.discordText:SetText("Discord: " .. (SchlingelInc.discordLink or "N/A"))
		selfTab.versionText:SetText("Version: " .. (SchlingelInc.version or "N/A"))
	end
	return tabFrame
end
