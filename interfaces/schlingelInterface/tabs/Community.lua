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
	SchlingelInc.UIHelpers:CreateLabel(tabFrame, "Gildenbeitritt:", col1X, currentY_Labels)
	local currentY_Col1_Buttons = currentY_Buttons

	SchlingelInc.UIHelpers:CreateActionButton(tabFrame, "Schlingel Inc beitreten",
		function() SchlingelInc.GuildRecruitment:SendGuildRequest() end,
		col1X, currentY_Col1_Buttons, buttonWidth, buttonHeight)
	currentY_Col1_Buttons = currentY_Col1_Buttons - buttonHeight - buttonSpacingY

	-- Column 2: Channels
	SchlingelInc.UIHelpers:CreateLabel(tabFrame, "Chatkanäle:", col2X, currentY_Labels)
	local currentY_Col2_Buttons = currentY_Buttons

	SchlingelInc.UIHelpers:CreateActionButton(tabFrame, "Globale Kanäle verlassen",
		function()
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
		end,
		col2X, currentY_Col2_Buttons, buttonWidth, buttonHeight)
	currentY_Col2_Buttons = currentY_Col2_Buttons - buttonHeight - buttonSpacingY

	SchlingelInc.UIHelpers:CreateActionButton(tabFrame, "Schlingel-Chats beitreten",
		function()
			if not ChatFrame1 then
				return
			end
			local cID = ChatFrame1:GetID()
			JoinChannelByName("SchlingelTrade", nil, cID, false)
			JoinChannelByName("SchlingelGroup", nil, cID, false)
			SchlingelInc:Print("Versuche Schlingel-Chats beizutreten.")
		end,
		col2X, currentY_Col2_Buttons, buttonWidth, buttonHeight)

	-- Info section
	local infoY = math.min(currentY_Col1_Buttons, currentY_Col2_Buttons) - buttonHeight - (buttonSpacingY * 2)
	local infoWidth = (buttonWidth * 2) + 30

	tabFrame.discordText = SchlingelInc.UIHelpers:CreateText(tabFrame, {
		text = "Discord: ...",
		point = {"TOPLEFT", col1X, infoY},
		width = infoWidth,
		justifyH = "CENTER"
	})
	infoY = infoY - 25

	tabFrame.versionText = SchlingelInc.UIHelpers:CreateText(tabFrame, {
		text = "Version: ...",
		point = {"TOPLEFT", col1X, infoY},
		width = infoWidth,
		justifyH = "CENTER"
	})

	tabFrame.Update = function(selfTab)
		selfTab.discordText:SetText("Discord: " .. (SchlingelInc.discordLink or "N/A"))
		selfTab.versionText:SetText("Version: " .. (SchlingelInc.version or "N/A"))
	end
	return tabFrame
end
