-- GuildInvites.lua
-- Displays popup for incoming guild invite requests (for officers)

SchlingelInc.GuildInvites = {}

-- Frame for the message
local InviteMessageFrame = CreateFrame("Frame", "InviteMessageFrame", UIParent, "BackdropTemplate")
InviteMessageFrame:SetSize(350, 125)
InviteMessageFrame:SetPoint("RIGHT", UIParent, "RIGHT", -50, -200)
InviteMessageFrame:SetFrameStrata("FULLSCREEN_DIALOG")
InviteMessageFrame:SetFrameLevel(1000)
InviteMessageFrame:Hide()

-- Background
InviteMessageFrame:SetBackdrop(SchlingelInc.Constants.POPUPBACKDROP)
InviteMessageFrame:SetBackdropColor(0, 0, 0, 0.8)

-- Icon
local icon = InviteMessageFrame:CreateTexture(nil, "ARTWORK")
icon:SetSize(32, 32)
icon:SetPoint("TOPLEFT", InviteMessageFrame, "TOPLEFT", -15, -10)
icon:SetTexture("Interface\\Icons\\inv_letter_18")

-- Header
local header = InviteMessageFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
header:SetPoint("TOPLEFT", icon, "TOPRIGHT", 0, -2)
header:SetText("Neue Gildenanfrage!")
header:SetTextColor(1, 1, 1, 1)

-- Text
InviteMessageFrame.text = InviteMessageFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
InviteMessageFrame.text:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
InviteMessageFrame.text:SetPoint("RIGHT", InviteMessageFrame, -10, 0)
InviteMessageFrame.text:SetJustifyH("LEFT")
InviteMessageFrame.text:SetJustifyV("TOP")
InviteMessageFrame.text:SetTextColor(1, 1, 1, 1)
InviteMessageFrame.text:SetShadowColor(0, 0, 0, 1)
InviteMessageFrame.text:SetShadowOffset(1, -1)

-- Buttons
local function HandleAcceptClick()
    SchlingelInc.GuildRecruitment:HandleAcceptRequest(InviteMessageFrame.playerName)
    SchlingelInc.GuildInvites:HideInviteMessage()
end
local acceptBtn = CreateFrame("Button", nil, InviteMessageFrame, "UIPanelButtonTemplate")
acceptBtn:SetSize(75, 25)
acceptBtn:SetPoint("LEFT", InviteMessageFrame, "LEFT", 15, -35)
acceptBtn:SetText("Annehmen")
acceptBtn:SetScript("OnClick", HandleAcceptClick)

local function HandleDeclineClick()
    SchlingelInc.GuildRecruitment:HandleDeclineRequest(InviteMessageFrame.playerName)
    SchlingelInc.GuildInvites:HideInviteMessage()
end
local declineBtn = CreateFrame("Button", nil, InviteMessageFrame, "UIPanelButtonTemplate")
declineBtn:SetSize(75, 25)
declineBtn:SetPoint("LEFT", InviteMessageFrame, "LEFT", 100, -35)
declineBtn:SetText("Ablehnen")
declineBtn:SetScript("OnClick", HandleDeclineClick)

-- Prepare animation
local animGroup = InviteMessageFrame:CreateAnimationGroup()
local fadeIn = animGroup:CreateAnimation("Alpha")
fadeIn:SetDuration(0.3)
fadeIn:SetFromAlpha(0)
fadeIn:SetToAlpha(1)
fadeIn:SetSmoothing("IN")

-- Shows the invite request message
function SchlingelInc.GuildInvites:ShowInviteMessage(message, requestData)
    if InviteMessageFrame:IsShown() then return
    end

    InviteMessageFrame.playerName = requestData["name"]
    InviteMessageFrame.text:SetText(message)
    InviteMessageFrame:Show()
    animGroup:Stop()
    animGroup:Play()
end

-- Hides the invite request message
function SchlingelInc.GuildInvites:HideInviteMessage()
    InviteMessageFrame:Hide()
end