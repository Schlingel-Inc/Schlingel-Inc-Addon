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

	SchlingelInc.UIHelpers:CreateHeader(mainFrame, "Schlingel Inc Interface")
	SchlingelInc.UIHelpers:CreateCloseButton(mainFrame)

	SchlingelInc.UIHelpers:CreateTabSystem(mainFrame, {
		tabConfig = TAB_CONFIG,
		namespace = SchlingelInc.SITabs,
		containerBounds = {top = -50, left = 15, right = -15, bottom = 45},
		onTabSelect = function(_, contentFrame)
			if contentFrame.Update then
				contentFrame:Update(contentFrame)
			end
		end
	})

	self.infoWindow = mainFrame
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
