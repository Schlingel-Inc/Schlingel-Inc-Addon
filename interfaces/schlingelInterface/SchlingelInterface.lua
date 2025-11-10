SchlingelInc = SchlingelInc or {}
SchlingelInc.UIHelpers = SchlingelInc.UIHelpers or {}
SchlingelInc.SITabs = SchlingelInc.SITabs or {}

local TAB_CONFIG = {
	{id = 1, title = "Charakter", module = "Character"},
	{id = 2, title = "Info", module = "Info"},
	{id = 3, title = "Community", module = "Community"},
}

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

	SchlingelInc.UIHelpers:CreateStyledText(mainFrame, "Schlingel Inc Interface", "GameFontHighlightLarge", "TOP", mainFrame, "TOP", 0, -15)

	local closeButtonFunc = function() mainFrame:Hide() end
	SchlingelInc.UIHelpers:CreateStyledButton(mainFrame, nil, 22, 22, "TOPRIGHT", mainFrame, "TOPRIGHT", -7, -7,
		"UIPanelCloseButton", closeButtonFunc)

	local tabContentContainer = CreateFrame("Frame", nil, mainFrame)
	tabContentContainer:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 15, -50)
	tabContentContainer:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -15, 45)

	local tabButtons = {}
	mainFrame.tabContentFrames = {}
	mainFrame.selectedTab = 1

	local function SelectTab(tabIndex)
		mainFrame.selectedTab = tabIndex
		for index, button in ipairs(tabButtons) do
			local contentFrame = mainFrame.tabContentFrames[index]
			if contentFrame then
				if index == tabIndex then
					PanelTemplates_SelectTab(button)
					contentFrame:Show()
					if contentFrame.Update then
						contentFrame:Update(contentFrame)
					end
				else
					PanelTemplates_DeselectTab(button)
					contentFrame:Hide()
				end
			end
		end
	end

	local tabButtonWidth = 130
	local tabButtonSpacing = 5
	local initialXOffsetForTabs = 20

	for _, config in ipairs(TAB_CONFIG) do
		local button = CreateFrame("Button", nil, mainFrame, "OptionsFrameTabButtonTemplate")
		button:SetID(config.id)
		button:SetText(config.title)
		button:SetWidth(tabButtonWidth)
		button:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT",
			initialXOffsetForTabs + (config.id - 1) * (tabButtonWidth + tabButtonSpacing), 12)
		button:GetFontString():SetPoint("CENTER", 0, 1)
		button:SetScript("OnClick", function() SelectTab(config.id) end)
		PanelTemplates_DeselectTab(button)
		tabButtons[config.id] = button

		local module = SchlingelInc.SITabs[config.module]
		if module and module.CreateUI then
			local newTab = module:CreateUI(tabContentContainer)
			if newTab then
				newTab:Hide()
				mainFrame.tabContentFrames[config.id] = newTab
			end
		else
			mainFrame.tabContentFrames[config.id] = CreateFrame("Frame", nil, tabContentContainer)
			mainFrame.tabContentFrames[config.id]:SetAllPoints()
			mainFrame.tabContentFrames[config.id]:Hide()
		end
	end

	self.infoWindow = mainFrame
	if #tabButtons > 0 then
		SelectTab(1)
	end
	mainFrame:Show()
end

function SchlingelInc:ToggleInfoWindow()
	if not self.infoWindow then
		self:CreateInfoWindow()
	elseif self.infoWindow:IsShown() then
		self.infoWindow:Hide()
	else
		self.infoWindow:Show()
		local activeTabIndex = self.infoWindow.selectedTab or 1
		local activeTabFrame = self.infoWindow.tabContentFrames and self.infoWindow.tabContentFrames[activeTabIndex]
		if activeTabFrame and activeTabFrame:IsShown() and activeTabFrame.Update then
			activeTabFrame:Update(activeTabFrame)
		end
	end
end
