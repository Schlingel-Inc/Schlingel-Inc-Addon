local UIHelpers = {}

-- ============================================================================
-- BASIC UI ELEMENTS (with options tables)
-- ============================================================================

function UIHelpers:CreateText(parent, options)
	options = options or {}
	local fs = parent:CreateFontString(nil, "OVERLAY", options.font or "GameFontNormal")

	-- Handle point as table {point, x, y} or {point, relativeTo, relativePoint, x, y}
	if options.point then
		if type(options.point) == "table" then
			local p = options.point
			if #p == 3 then
				fs:SetPoint(p[1], parent, p[1], p[2], p[3])
			elseif #p == 5 then
				fs:SetPoint(p[1], p[2], p[3], p[4], p[5])
			end
		else
			fs:SetPoint(options.point, parent, options.point, options.x or 0, options.y or 0)
		end
	end

	if options.text then fs:SetText(options.text) end
	if options.width and options.height then fs:SetSize(options.width, options.height) end
	if options.justifyH then fs:SetJustifyH(options.justifyH) end
	if options.justifyV then fs:SetJustifyV(options.justifyV) end

	return fs
end

function UIHelpers:CreateButton(parent, options)
	options = options or {}
	local btn = CreateFrame("Button", nil, parent, options.template or "UIPanelButtonTemplate")

	if options.text then btn:SetText(options.text) end
	if options.width and options.height then
		btn:SetSize(options.width, options.height)
	end

	-- Handle point as table {point, x, y} or {point, relativeTo, relativePoint, x, y}
	if options.point then
		if type(options.point) == "table" then
			local p = options.point
			if #p == 3 then
				btn:SetPoint(p[1], parent, p[1], p[2], p[3])
			elseif #p == 5 then
				btn:SetPoint(p[1], p[2], p[3], p[4], p[5])
			end
		else
			btn:SetPoint(options.point, parent, options.point, options.x or 0, options.y or 0)
		end
	end

	if options.onClick then btn:SetScript("OnClick", options.onClick) end

	return btn
end

-- ============================================================================
-- SPECIALIZED HELPERS
-- ============================================================================

function UIHelpers:CreateHeader(parent, text, yOffset)
	local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
	fs:SetPoint("TOP", parent, "TOP", 0, yOffset or -15)
	fs:SetText(text)
	return fs
end

function UIHelpers:CreateLabel(parent, text, x, y)
	local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
	fs:SetText(text)
	return fs
end

function UIHelpers:CreateActionButton(parent, text, onClick, x, y, width, height)
	local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	btn:SetText(text)
	btn:SetSize(width or 220, height or 30)
	btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
	if onClick then btn:SetScript("OnClick", onClick) end
	return btn
end

function UIHelpers:CreateCloseButton(parent, onClose)
	local btn = CreateFrame("Button", nil, parent, "UIPanelCloseButton")
	btn:SetSize(22, 22)
	btn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -7, -7)
	if onClose then
		btn:SetScript("OnClick", onClose)
	else
		btn:SetScript("OnClick", function() parent:Hide() end)
	end
	return btn
end

-- ============================================================================
-- LAYOUT HELPERS
-- ============================================================================

function UIHelpers:CreateTwoColumnLayout(parent, options)
	options = options or {}
	local leftX = options.leftX or 0
	local rightX = options.rightX or (parent:GetWidth() * 0.55)
	local startY = options.startY or 0
	local lineHeight = options.lineHeight or 22

	local leftColumn = {
		parent = parent,
		x = leftX,
		currentY = startY,
		lineHeight = lineHeight,
	}

	local rightColumn = {
		parent = parent,
		x = rightX,
		currentY = startY,
		lineHeight = lineHeight,
	}

	function leftColumn:AddLabel(text)
		local fs = self.parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		fs:SetPoint("TOPLEFT", self.parent, "TOPLEFT", self.x, self.currentY)
		fs:SetText(text)
		self.currentY = self.currentY - self.lineHeight
		return fs
	end

	function rightColumn:AddLabel(text)
		local fs = self.parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		fs:SetPoint("TOPLEFT", self.parent, "TOPLEFT", self.x, self.currentY)
		fs:SetText(text)
		self.currentY = self.currentY - self.lineHeight
		return fs
	end

	function leftColumn:GetCurrentY()
		return self.currentY
	end

	function rightColumn:GetCurrentY()
		return self.currentY
	end

	return leftColumn, rightColumn
end

function UIHelpers:CreateScrollFrame(parent, options)
	options = options or {}
	local scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")

	if options.width and options.height then
		scrollFrame:SetSize(options.width, options.height)
	end

	if options.point then
		if type(options.point) == "table" then
			local p = options.point
			if #p == 3 then
				scrollFrame:SetPoint(p[1], parent, p[1], p[2], p[3])
			elseif #p == 5 then
				scrollFrame:SetPoint(p[1], p[2], p[3], p[4], p[5])
			end
		end
	elseif options.x and options.y then
		scrollFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", options.x, options.y)
	end

	local scrollChild = CreateFrame("Frame", nil, scrollFrame)
	scrollChild:SetSize(options.childWidth or options.width or 100, options.childHeight or 1)
	scrollFrame:SetScrollChild(scrollChild)

	return scrollFrame, scrollChild
end

-- ============================================================================
-- TAB SYSTEM HELPER
-- ============================================================================

function UIHelpers:CreateTabSystem(mainFrame, options)
	options = options or {}
	local tabConfig = options.tabConfig or {}
	local namespace = options.namespace or {}
	local onTabSelect = options.onTabSelect

	-- Create tab content container
	local container = CreateFrame("Frame", nil, mainFrame)
	if options.containerBounds then
		local b = options.containerBounds
		container:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", b.left or 15, b.top or -50)
		container:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", b.right or -15, b.bottom or 45)
	else
		container:SetAllPoints()
	end

	local tabButtons = {}
	local tabContentFrames = {}
	mainFrame.selectedTab = 1

	-- Tab selection function
	local function SelectTab(tabIndex)
		mainFrame.selectedTab = tabIndex
		for index, button in ipairs(tabButtons) do
			local contentFrame = tabContentFrames[index]
			if contentFrame then
				if index == tabIndex then
					PanelTemplates_SelectTab(button)
					contentFrame:Show()
					if onTabSelect then
						onTabSelect(tabIndex, contentFrame)
					end
				else
					PanelTemplates_DeselectTab(button)
					contentFrame:Hide()
				end
			end
		end
	end

	-- Create tab buttons
	local tabButtonWidth = options.tabButtonWidth or 130
	local tabButtonSpacing = options.tabButtonSpacing or 5
	local initialXOffset = options.initialXOffset or 20

	for _, config in ipairs(tabConfig) do
		local button = CreateFrame("Button", nil, mainFrame, "OptionsFrameTabButtonTemplate")
		button:SetID(config.id)
		button:SetText(config.title)
		button:SetWidth(tabButtonWidth)
		button:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT",
			initialXOffset + (config.id - 1) * (tabButtonWidth + tabButtonSpacing), 12)
		button:GetFontString():SetPoint("CENTER", 0, 1)
		button:SetScript("OnClick", function() SelectTab(config.id) end)
		PanelTemplates_DeselectTab(button)
		tabButtons[config.id] = button

		-- Create tab content from module
		local module = namespace[config.module]
		if module and module.CreateUI then
			local newTab = module:CreateUI(container)
			if newTab then
				newTab:Hide()
				tabContentFrames[config.id] = newTab
			end
		else
			tabContentFrames[config.id] = CreateFrame("Frame", nil, container)
			tabContentFrames[config.id]:SetAllPoints()
			tabContentFrames[config.id]:Hide()
		end
	end

	mainFrame.tabContentFrames = tabContentFrames

	-- Select first tab
	if #tabButtons > 0 then
		SelectTab(1)
	end

	return tabButtons, tabContentFrames
end

SchlingelInc.UIHelpers = UIHelpers
