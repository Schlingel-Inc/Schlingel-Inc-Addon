-- GuildJoinPrompt.lua
-- Popup to encourage non-guild players to request an invite

local GuildJoinFrame

-- Create the prompt frame
local function CreateGuildJoinPrompt()
    local frame = CreateFrame("Frame", "SchlingelIncGuildJoinPrompt", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    frame:SetSize(320, 220)
    frame:SetPoint("CENTER")
    frame:SetBackdrop(SchlingelInc.Constants.BACKDROP)
    frame:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    -- Icon (centered at top)
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\AddOns\\SchlingelInc\\media\\SI_Transp_512_x_512_px.tga")
    icon:SetSize(80, 80)
    icon:SetPoint("TOP", frame, "TOP", 0, -20)

    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", icon, "BOTTOM", 0, -12)
    title:SetText("Noch kein Schlingel?")
    title:SetTextColor(1, 0.82, 0, 1)

    -- Description
    local desc = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    desc:SetPoint("TOP", title, "BOTTOM", 0, -10)
    desc:SetWidth(280)
    desc:SetJustifyH("CENTER")
    desc:SetText("Du bist noch nicht in der Gilde!\nSende eine Beitrittsanfrage an unsere Offiziere.")

    -- Join button
    local joinButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    joinButton:SetSize(180, 28)
    joinButton:SetPoint("TOP", desc, "BOTTOM", 0, -15)
    joinButton:SetText("Beitrittsanfrage senden")
    joinButton:SetScript("OnClick", function()
        SchlingelInc.GuildRecruitment:SendGuildRequest()
        frame:Hide()
    end)

    -- Close button (smaller, below join button)
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    closeButton:SetSize(100, 22)
    closeButton:SetPoint("TOP", joinButton, "BOTTOM", 0, -8)
    closeButton:SetText("Schliessen")
    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)

    return frame
end

-- Show the guild join prompt
function SchlingelInc:ShowGuildJoinPrompt()
    if IsInGuild() then
        return
    end

    GuildJoinFrame = GuildJoinFrame or CreateGuildJoinPrompt()
    GuildJoinFrame:Show()
end

-- Check if player needs the guild join prompt (called after DiscordHandlePrompt closes or on login)
function SchlingelInc:CheckAndShowGuildJoinPrompt()
    if not UnitName("player") then
        return
    end

    -- Don't show if player is already in a guild
    if IsInGuild() then
        return
    end

    -- Show the prompt
    SchlingelInc:ShowGuildJoinPrompt()
end
