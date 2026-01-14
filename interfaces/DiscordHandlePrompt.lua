-- Pending handle storage (not saved, session-only)
local pendingDiscordHandle = nil

-- Get the account-wide Discord handle
function SchlingelInc:GetDiscordHandle()
    return DiscordHandle
end

-- Set the account-wide Discord handle
function SchlingelInc:SetDiscordHandle(handle)
    DiscordHandle = handle
    if handle and handle ~= "" then
        SchlingelInc:UpdateGuildNote(handle, CharacterDeaths or 0)
    end
end

-- Update guild note with handle and death count
function SchlingelInc:UpdateGuildNote(handle, deaths)
    local playerName = UnitName("player")

    C_Timer.After(2, function()
        local numMembers = GetNumGuildMembers()
        local noteText = string.format("%s (Tode: %d)", handle, deaths)

        for i = 1, numMembers do
            local name = GetGuildRosterInfo(i)
            if name then
                local shortName = SchlingelInc:RemoveRealmFromName(name)
                if shortName == playerName then
                    GuildRosterSetPublicNote(i, noteText)
                    return
                end
            end
        end
    end)
end

local DiscordPromptFrame

-- Create the prompt frame
local function CreateDiscordHandlePrompt()
    local frame = CreateFrame("Frame", "SchlingelIncDiscordPrompt", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    frame:SetSize(320, 280)
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
    title:SetText("Willkommen, Schlingel!")
    title:SetTextColor(1, 0.82, 0, 1)

    -- Description
    local desc = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    desc:SetPoint("TOP", title, "BOTTOM", 0, -10)
    desc:SetWidth(280)
    desc:SetJustifyH("CENTER")
    desc:SetText("Gib bitte deinen Discord Handle ein.\nEr wird mit deinen Toden in der Gildennotiz gespeichert.")

    -- Input box
    local editBox = CreateFrame("EditBox", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
    editBox:SetSize(240, 28)
    editBox:SetPoint("TOP", desc, "BOTTOM", 0, -15)
    editBox:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    editBox:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    editBox:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    editBox:SetFontObject("GameFontHighlight")
    editBox:SetTextInsets(8, 8, 0, 0)
    editBox:SetAutoFocus(false)
    editBox:SetMaxLetters(50)

    -- Shared save logic
    local function SaveAndClose()
        local handle = editBox:GetText()
        if handle and handle ~= "" then
            SchlingelInc:SetDiscordHandle(handle)
            frame:Hide()
            -- Check if player needs guild invite prompt
            SchlingelInc:CheckAndShowGuildJoinPrompt()
        end
    end

    editBox:SetScript("OnEnterPressed", SaveAndClose)

    -- Save button
    local saveButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    saveButton:SetSize(120, 26)
    saveButton:SetPoint("TOP", editBox, "BOTTOM", 0, -12)
    saveButton:SetText("Speichern")
    saveButton:SetScript("OnClick", SaveAndClose)

    return frame
end

-- Show the prompt if needed
function SchlingelInc:ShowDiscordHandlePromptIfNeeded()
    if not UnitName("player") then
        return
    end

    local handle = SchlingelInc:GetDiscordHandle()

    -- If handle is set and not empty, update guild note silently and check for guild
    if handle and handle ~= "" then
        SchlingelInc:UpdateGuildNote(handle, CharacterDeaths or 0)
        -- Check if player needs guild invite prompt (handle set but not in guild)
        SchlingelInc:CheckAndShowGuildJoinPrompt()
    -- Show prompt if no handle is set (nil means never asked)
    elseif handle == nil then
        DiscordPromptFrame = DiscordPromptFrame or CreateDiscordHandlePrompt()
        DiscordPromptFrame:Show()
    end
end

-- Initialize and register events
function SchlingelInc:InitializeDiscordHandlePrompt()
    SchlingelInc.EventManager:RegisterHandler("PLAYER_ENTERING_WORLD", function()
        SchlingelInc:ShowDiscordHandlePromptIfNeeded()
        SchlingelInc.EventManager:UnregisterHandler("PLAYER_ENTERING_WORLD", "DiscordHandlePrompt")
    end, 0, "DiscordHandlePrompt")

    -- Handle pending Discord handle updates when guild roster updates
    SchlingelInc.EventManager:RegisterHandler("GUILD_ROSTER_UPDATE", function()
        if pendingDiscordHandle then
            SchlingelInc:UpdateGuildNote(pendingDiscordHandle, CharacterDeaths or 0)
            pendingDiscordHandle = nil
        end
    end, 0, "DiscordHandlePending")

    -- Slash command to set Discord handle: /setHandle <handle>
    SLASH_SETHANDLE1 = '/setHandle'
    SLASH_SETHANDLE2 = '/sethandle'
    SlashCmdList["SETHANDLE"] = function(msg)
        local handle = msg:match("^%s*(.-)%s*$") -- Trim whitespace
        if handle and handle ~= "" then
            SchlingelInc:SetDiscordHandle(handle)
            SchlingelInc:Print(SchlingelInc.Constants.COLORS.SUCCESS ..
                "Discord Handle gesetzt: " .. handle .. "|r")
        else
            local currentHandle = SchlingelInc:GetDiscordHandle()
            if currentHandle and currentHandle ~= "" then
                SchlingelInc:Print("Aktueller Discord Handle: " .. currentHandle)
            else
                SchlingelInc:Print(SchlingelInc.Constants.COLORS.WARNING ..
                    "Verwendung: /setHandle <dein Discord Handle>|r")
            end
        end
    end
end
