SchlingelInc = SchlingelInc or {}
SchlingelInc.Tabs = SchlingelInc.Tabs or {}

-- Tab-Konfiguration: ID, Titel, Modulname
local TAB_CONFIG = {
	{id = 1, title = "Gildeninfo", module = "GuildInfo"},
	{id = 2, title = "Statistik", module = "Stats"},
	{id = 3, title = "Inaktiv", module = "Inactivity"},
}

function SchlingelInc:CreateOffiWindow()
	if self.OffiWindow then return end

	local offiFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	offiFrame:SetSize(600, 500)
	offiFrame:SetPoint("RIGHT", -50, 25)
	offiFrame:SetBackdrop(SchlingelInc.Constants.BACKDROP)
	offiFrame:SetMovable(true)
	offiFrame:EnableMouse(true)
	offiFrame:RegisterForDrag("LeftButton")
	offiFrame:SetScript("OnDragStart", offiFrame.StartMoving)
	offiFrame:SetScript("OnDragStop", offiFrame.StopMovingOrSizing)
	offiFrame:Hide()

	-- Close Button
	SchlingelInc.UIHelpers:CreateStyledButton(offiFrame, nil, 22, 22,
		"TOPRIGHT", offiFrame, "TOPRIGHT", -5, -5, "UIPanelCloseButton",
		function() offiFrame:Hide() end)

	-- Title
	SchlingelInc.UIHelpers:CreateStyledText(offiFrame, "Schlingel Inc - Offi Interface", "GameFontHighlightLarge",
		"TOP", offiFrame, "TOP", 0, -20)

	-- Tab Content Container
	local tabContentContainer = CreateFrame("Frame", nil, offiFrame)
	tabContentContainer:SetPoint("TOPLEFT", offiFrame, "TOPLEFT", 10, -50)
	tabContentContainer:SetPoint("BOTTOMRIGHT", offiFrame, "BOTTOMRIGHT", -10, 10)

	local tabButtons = {}
	local tabContentFrames = {}

	-- Tab Selection Function
	local function SelectTab(tabIndex)
		for i, button in ipairs(tabButtons) do
			if button and tabContentFrames[i] then
				if i == tabIndex then
					PanelTemplates_SelectTab(button)
					tabContentFrames[i]:Show()

					-- Update data for selected tab
					local config = TAB_CONFIG[i]
					local module = SchlingelInc.Tabs[config.module]
					if module and module.UpdateData then
						module:UpdateData()
					end
				else
					PanelTemplates_DeselectTab(button)
					tabContentFrames[i]:Hide()
				end
			end
		end
	end

	-- Create Tab Buttons and Content Frames
	for _, config in ipairs(TAB_CONFIG) do
		local buttonWidth = 125
		local buttonSpacing = 10
		local startX = 15

		-- Create Button
		local button = CreateFrame("Button", nil, offiFrame, "OptionsFrameTabButtonTemplate")
		button:SetID(config.id)
		button:SetText(config.title)
		button:SetPoint("BOTTOMLEFT", offiFrame, "BOTTOMLEFT", startX + (config.id - 1) * (buttonWidth + buttonSpacing), 10)
		button:SetWidth(buttonWidth)
		button:GetFontString():SetPoint("CENTER", 0, 2)
		button:SetScript("OnClick", function() SelectTab(config.id) end)
		PanelTemplates_DeselectTab(button)
		tabButtons[config.id] = button

		-- Create Content Frame
		local module = SchlingelInc.Tabs[config.module]
		if module and module.CreateUI then
			tabContentFrames[config.id] = module:CreateUI(tabContentContainer)
		else
			SchlingelInc:Print("Fehler: Tab Modul '" .. config.module .. "' nicht geladen oder CreateUI fehlt!")
			tabContentFrames[config.id] = CreateFrame("Frame", nil, tabContentContainer)
			tabContentFrames[config.id]:SetAllPoints()
			tabContentFrames[config.id]:Hide()
		end
	end

	self.OffiWindow = offiFrame
	SelectTab(1)
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

		-- Update all tabs when opening
		for _, config in ipairs(TAB_CONFIG) do
			local module = SchlingelInc.Tabs[config.module]
			if module and module.UpdateData then
				module:UpdateData()
			end
		end
	end
end
