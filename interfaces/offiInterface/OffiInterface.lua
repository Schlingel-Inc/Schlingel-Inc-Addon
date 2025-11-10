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

	SchlingelInc.UIHelpers:CreateHeader(offiFrame, "Schlingel Inc - Offi Interface")
	SchlingelInc.UIHelpers:CreateCloseButton(offiFrame)

	SchlingelInc.UIHelpers:CreateTabSystem(offiFrame, {
		tabConfig = TAB_CONFIG,
		namespace = SchlingelInc.Tabs,
		containerBounds = {top = -50, left = 10, right = -10, bottom = 10},
		tabButtonWidth = 125,
		tabButtonSpacing = 10,
		initialXOffset = 15,
		onTabSelect = function(tabIndex, _)
			local config = TAB_CONFIG[tabIndex]
			local module = SchlingelInc.Tabs[config.module]
			if module and module.UpdateData then
				module:UpdateData()
			end
		end
	})

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

		-- Update all tabs when opening
		for _, config in ipairs(TAB_CONFIG) do
			local module = SchlingelInc.Tabs[config.module]
			if module and module.UpdateData then
				module:UpdateData()
			end
		end
	end
end
