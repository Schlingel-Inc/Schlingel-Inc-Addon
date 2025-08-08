SchlingelInc.GuildInvites = {}

-- Frame für die Nachricht
local InviteMessageFrame = CreateFrame("Frame", "InviteMessageFrame", UIParent, "BackdropTemplate")
InviteMessageFrame:ClearAllPoints()
InviteMessageFrame:SetSize(350, 100)
InviteMessageFrame:SetPoint("RIGHT", UIParent, "RIGHT", -50, -200)
InviteMessageFrame:SetFrameStrata("FULLSCREEN_DIALOG")
InviteMessageFrame:SetFrameLevel(1000)
InviteMessageFrame:Hide()
InviteMessageFrame:SetAlpha(1)

-- Hintergrund
InviteMessageFrame:SetBackdrop({
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
InviteMessageFrame:SetBackdropColor(0, 0, 0, 0.8)

-- Icon
local icon = InviteMessageFrame:CreateTexture(nil, "ARTWORK")
icon:SetSize(32, 32)
icon:SetPoint("TOPLEFT", InviteMessageFrame, "TOPLEFT", 10, -10)
icon:SetTexture("Interface\\Icons\\inv_letter_18")

-- Header
local header = InviteMessageFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
header:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -2)
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
InviteMessageFrame.text:SetText("")

-- Buttons
local function HandleAcceptClick()
    SchlingelInc.GuildRecruitment:HandleAcceptRequest(InviteMessageFrame.playerName)
    SchlingelInc.GuildInvites:HideInviteMessage()
end
SchlingelInc.UIHelpers:CreateStyledButton(InviteMessageFrame, "Annehmen", 75, 25, "CENTER", InviteMessageFrame,
    "CENTER", -50, -25, "UIPanelButtonTemplate", HandleAcceptClick)

local function HandleDeclinetClick()
    SchlingelInc.GuildRecruitment:HandleDeclineRequest(InviteMessageFrame.playerName)
    SchlingelInc.GuildInvites:HideInviteMessage()
end
SchlingelInc.UIHelpers:CreateStyledButton(InviteMessageFrame, "Ablehnen", 75, 25, "CENTER", InviteMessageFrame,
    "CENTER", 50, -25, "UIPanelButtonTemplate", HandleDeclinetClick)

-- Animation vorbereiten
local animGroup = InviteMessageFrame:CreateAnimationGroup()
local fadeIn = animGroup:CreateAnimation("Alpha")
fadeIn:SetDuration(0.3)
fadeIn:SetFromAlpha(0)
fadeIn:SetToAlpha(1)
fadeIn:SetSmoothing("IN")

-- Nachricht anzeigen
function SchlingelInc.GuildInvites:ShowInviteMessage(message, requestData)
if InviteMessageFrame:IsShown() then
    print("InviteFrame already shown — skipping.")
    return
end
    InviteMessageFrame.playerName = requestData["name"]
    InviteMessageFrame.text:SetText(message)
    InviteMessageFrame:Show()
    animGroup:Play()
end

-- Nachricht verbergen
function SchlingelInc.GuildInvites:HideInviteMessage()
    InviteMessageFrame:Hide()
end