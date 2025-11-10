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

	local leftPadding = 20
	local contentWidth = parentFrame:GetWidth() - (leftPadding * 2)

	tabFrame.motdLabel = SchlingelInc.UIHelpers:CreateLabel(tabFrame, "Gilden-MOTD:", leftPadding, -20)

	tabFrame.motdTextDisplay = SchlingelInc.UIHelpers:CreateText(tabFrame, {
		text = "Lade MOTD...",
		point = {"TOPLEFT", leftPadding, -20 - tabFrame.motdLabel:GetHeight() - 7},
		width = contentWidth,
		height = 100,
		justifyH = "LEFT",
		justifyV = "TOP"
	})

	local rulesY = -20 - tabFrame.motdLabel:GetHeight() - 7 - 120
	tabFrame.rulesLabel = SchlingelInc.UIHelpers:CreateLabel(tabFrame, "Regeln der Gilden:", leftPadding, rulesY)

	local ruleTextContent = ""
	for i, value in ipairs(Rulestext) do
		ruleTextContent = ruleTextContent .. "• " .. value
		if i < #Rulestext then
			ruleTextContent = ruleTextContent .. "\n\n"
		else
			ruleTextContent = ruleTextContent .. "\n"
		end
	end
	tabFrame.rulesTextDisplay = SchlingelInc.UIHelpers:CreateText(tabFrame, {
		text = ruleTextContent,
		point = {"TOPLEFT", leftPadding, rulesY - tabFrame.rulesLabel:GetHeight() - 7},
		width = contentWidth,
		height = 150,
		justifyH = "LEFT",
		justifyV = "TOP"
	})

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
