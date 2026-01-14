-- DeathAnnouncement.lua
-- Displays animated death announcements when guild members die

SchlingelInc.DeathAnnouncement = {}

-- Frame for the message
local DeathMessageFrame = CreateFrame("Frame", "DeathMessageFrame", UIParent, "BackdropTemplate")
DeathMessageFrame:SetSize(300, 150)
DeathMessageFrame:SetPoint("TOP", UIParent, "TOP", 0, 0)
DeathMessageFrame:SetFrameStrata("FULLSCREEN_DIALOG")
DeathMessageFrame:SetFrameLevel(1000)
DeathMessageFrame:Hide()

-- Background
DeathMessageFrame:SetBackdrop(SchlingelInc.Constants.POPUPBACKDROP)
DeathMessageFrame:SetBackdropColor(0, 0, 0, 0.8)

-- Icon (centered at top)
local icon = DeathMessageFrame:CreateTexture(nil, "ARTWORK")
icon:SetSize(64, 64)
icon:SetPoint("TOP", DeathMessageFrame, "TOP", 0, -15)
icon:SetTexture("Interface\\AddOns\\SchlingelInc\\media\\Wappenrock.tga")

-- Header (centered below icon)
local header = DeathMessageFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
header:SetPoint("TOP", icon, "BOTTOM", 0, -8)
header:SetText("Schande!")
header:SetTextColor(1, 0.2, 0.2, 1)

-- Text (centered below header)
DeathMessageFrame.text = DeathMessageFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
DeathMessageFrame.text:SetPoint("TOP", header, "BOTTOM", 0, -6)
DeathMessageFrame.text:SetPoint("LEFT", DeathMessageFrame, "LEFT", 10, 0)
DeathMessageFrame.text:SetPoint("RIGHT", DeathMessageFrame, "RIGHT", -10, 0)
DeathMessageFrame.text:SetJustifyH("CENTER")
DeathMessageFrame.text:SetJustifyV("TOP")
DeathMessageFrame.text:SetTextColor(1, 0.1, 0.1, 1)
DeathMessageFrame.text:SetShadowColor(0, 0, 0, 1)
DeathMessageFrame.text:SetShadowOffset(1, -1)

-- Prepare animation
local animGroup = DeathMessageFrame:CreateAnimationGroup()
local moveDown = animGroup:CreateAnimation("Translation")
moveDown:SetDuration(0.6)
moveDown:SetOffset(0, -50)
moveDown:SetSmoothing("OUT")

local moveDownAgain = animGroup:CreateAnimation("Translation")
moveDownAgain:SetStartDelay(2)
moveDownAgain:SetDuration(0.6)
moveDownAgain:SetOffset(0, -50)
moveDownAgain:SetSmoothing("OUT")

local fadeIn = animGroup:CreateAnimation("Alpha")
fadeIn:SetDuration(0.3)
fadeIn:SetFromAlpha(0)
fadeIn:SetToAlpha(1)
fadeIn:SetSmoothing("IN")

local fadeOut = animGroup:CreateAnimation("Alpha")
fadeOut:SetStartDelay(2)
fadeOut:SetDuration(1)
fadeOut:SetFromAlpha(1)
fadeOut:SetToAlpha(0)
fadeOut:SetSmoothing("OUT")

-- Hide frame after animation completes
animGroup:SetScript("OnFinished", function()
	DeathMessageFrame:Hide()
end)

-- Shows the death message with animation
function SchlingelInc.DeathAnnouncement:ShowDeathMessage(message)
	if not SchlingelOptionsDB["deathmessages"] then
		return
	end

	DeathMessageFrame.text:SetText(SchlingelInc:SanitizeText(message))
	DeathMessageFrame:SetAlpha(0)
	DeathMessageFrame:Show()
	animGroup:Stop()
	animGroup:Play()

	if SchlingelOptionsDB["deathmessages_sound"] then
		PlaySound(SchlingelInc.Constants.SOUNDS.DEATH_ANNOUNCEMENT)
	end
end
