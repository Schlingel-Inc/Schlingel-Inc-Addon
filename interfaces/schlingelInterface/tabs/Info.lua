SchlingelInc.SITabs = SchlingelInc.SITabs or {}

local Rulestext = {
	"Die Nutzung des Briefkastens ist verboten!",
	"Die Nutzung des Auktionshauses ist verboten!",
	"Handeln mit Spielern außerhalb der Gilden ist verboten!"
}

SchlingelInc.SITabs.Info = {}

function SchlingelInc.SITabs.Info:CreateUI(parentFrame)
	local tabFrame = CreateFrame("Frame", nil, parentFrame)
	tabFrame:SetAllPoints()

	local currentY = -20
	local leftPadding = 20
	local contentWidth = parentFrame:GetWidth() - (leftPadding * 2)

	tabFrame.motdLabel = SchlingelInc.UIHelpers:CreateStyledText(tabFrame, "Gilden-MOTD:", "GameFontNormal", "TOPLEFT", tabFrame,
		"TOPLEFT", leftPadding, currentY)
	currentY = currentY - tabFrame.motdLabel:GetHeight() - 7

	tabFrame.motdTextDisplay = SchlingelInc.UIHelpers:CreateStyledText(tabFrame, "Lade MOTD...", "GameFontNormal", "TOPLEFT", tabFrame,
		"TOPLEFT", leftPadding, currentY, contentWidth, 100, "LEFT", "TOP")
	currentY = currentY - 120

	tabFrame.rulesLabel = SchlingelInc.UIHelpers:CreateStyledText(tabFrame, "Regeln der Gilden:", "GameFontNormal", "TOPLEFT",
		tabFrame, "TOPLEFT", leftPadding, currentY)
	currentY = currentY - tabFrame.rulesLabel:GetHeight() - 7

	local ruleTextContent = ""
	for i, value in ipairs(Rulestext) do
		ruleTextContent = ruleTextContent .. "• " .. value
		if i < #Rulestext then
			ruleTextContent = ruleTextContent .. "\n\n"
		else
			ruleTextContent = ruleTextContent .. "\n"
		end
	end
	tabFrame.rulesTextDisplay = SchlingelInc.UIHelpers:CreateStyledText(tabFrame, ruleTextContent, "GameFontNormal", "TOPLEFT",
		tabFrame, "TOPLEFT", leftPadding, currentY, contentWidth, 150, "LEFT", "TOP")

	tabFrame.Update = function(selfTab)
		local guildMOTD = GetGuildRosterMOTD()
		if guildMOTD and guildMOTD ~= "" then
			selfTab.motdTextDisplay:SetText(guildMOTD)
		else
			selfTab.motdTextDisplay:SetText("Keine Gilden-MOTD festgelegt.")
		end
	end
	return tabFrame
end
