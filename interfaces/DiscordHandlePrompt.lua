-- Get the account-wide Discord handle
function SchlingelInc:GetDiscordHandle()
    return DiscordHandle
end

-- Set the account-wide Discord handle
function SchlingelInc:SetDiscordHandle(handle)
    DiscordHandle = handle
    SchlingelInc:UpdateGuildNote()
end

-- Set the account-wide preferred pronouns and update guild note
function SchlingelInc:SetPreferredPronouns(pronouns)
    Pronouns = pronouns
    SchlingelInc:UpdateGuildNote()
end

-- Returns handle with pronouns appended if present: "myhandle (he/him)" or "myhandle"
-- Returns nil if no handle is set
function SchlingelInc:GetFormattedHandle()
    local handle = DiscordHandle or ""
    if handle == "" then return nil end
    local pronouns = Pronouns or ""
    if pronouns ~= "" then
        return string.format("%s (%s)", handle, pronouns)
    end
    return handle
end

-- Sync guild note from saved variables (DiscordHandle, Pronouns, CharacterDeaths)
function SchlingelInc:UpdateGuildNote()
    local handle = DiscordHandle or ""
    local pronouns = Pronouns or ""
    local deaths = CharacterDeaths or 0
    local playerName = UnitName("player")

    if handle == "" then return end

    C_Timer.After(2, function()
        local numMembers = GetNumGuildMembers()
        local noteText
        if pronouns ~= "" then
            noteText = string.format("%s (%s) Tode: %d", handle, pronouns, deaths)
        else
            noteText = string.format("%s (Tode: %d)", handle, deaths)
        end

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
local PronounPromptFrame

-- Create the pronoun prompt (yes/no + optional input)
local function CreatePronounPrompt(onDone)
    local frame = CreateFrame("Frame", "SchlingelIncPronounPrompt", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    frame:SetSize(320, 240)
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

    -- Icon
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\AddOns\\SchlingelInc\\media\\graphics\\SI_Transp_512_x_512_px.tga")
    icon:SetSize(80, 80)
    icon:SetPoint("TOP", frame, "TOP", 0, -20)

    -- Question label
    local question = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    question:SetPoint("TOP", icon, "BOTTOM", 0, -12)
    question:SetWidth(280)
    question:SetJustifyH("CENTER")
    question:SetText("Möchtest du bevorzugte Pronomen angeben?")
    question:SetTextColor(1, 0.82, 0, 1)

    local subtext = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    subtext:SetPoint("TOP", question, "BOTTOM", 0, -8)
    subtext:SetWidth(280)
    subtext:SetJustifyH("CENTER")
    subtext:SetText("z.B. er/ihm, sie/ihr, they/them")

    -- Input box (hidden until "Ja" is clicked)
    local editBox = CreateFrame("EditBox", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
    editBox:SetSize(240, 28)
    editBox:SetPoint("TOP", subtext, "BOTTOM", 0, -14)
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
    editBox:SetMaxLetters(30)
    editBox:Hide()

    local function SavePronouns()
        local pronouns = editBox:GetText():match("^%s*(.-)%s*$")
        if pronouns and pronouns ~= "" then
            SchlingelInc:SetPreferredPronouns(pronouns)
            SchlingelInc:Print(SchlingelInc.Constants.COLORS.SUCCESS ..
                "Pronomen gesetzt: " .. pronouns .. "|r")
        end
        frame:Hide()
        onDone()
    end

    editBox:SetScript("OnEnterPressed", SavePronouns)

    -- Save button (replaces Ja after click, sits left of Nein)
    local saveButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    saveButton:SetSize(120, 26)
    saveButton:SetPoint("BOTTOM", frame, "BOTTOM", -64, 20)
    saveButton:SetText("Speichern")
    saveButton:SetScript("OnClick", SavePronouns)
    saveButton:Hide()

    -- Ja button (same position as save, hidden on click)
    local yesButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    yesButton:SetSize(120, 26)
    yesButton:SetPoint("BOTTOM", frame, "BOTTOM", -64, 20)
    yesButton:SetText("Ja")
    yesButton:SetScript("OnClick", function()
        yesButton:Hide()
        frame:SetHeight(300)
        editBox:Show()
        saveButton:Show()
        editBox:SetFocus()
    end)

    -- Nein button (always visible, right of center)
    local noButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    noButton:SetSize(120, 26)
    noButton:SetPoint("BOTTOM", frame, "BOTTOM", 64, 20)
    noButton:SetText("Nein")
    noButton:SetScript("OnClick", function()
        frame:Hide()
        onDone()
    end)

    return frame
end

-- Create the discord handle prompt frame
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
    icon:SetTexture("Interface\\AddOns\\SchlingelInc\\media\\graphics\\SI_Transp_512_x_512_px.tga")
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

    local function SaveAndClose()
        local handle = editBox:GetText():match("^%s*(.-)%s*$")
        if handle and handle ~= "" then
            SchlingelInc:SetDiscordHandle(handle)
            frame:Hide()
            -- Ask for pronouns, then continue to guild join check
            PronounPromptFrame = PronounPromptFrame or CreatePronounPrompt(function()
                SchlingelInc:CheckAndShowGuildJoinPrompt()
            end)
            PronounPromptFrame:Show()
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
        SchlingelInc:UpdateGuildNote()
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

    -- Slash command to set Discord handle: /setHandle <handle>
    SLASH_SETHANDLE1 = '/setHandle'
    SLASH_SETHANDLE2 = '/sethandle'
    SlashCmdList["SETHANDLE"] = function(msg)
        local handle = msg:match("^%s*(.-)%s*$")
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

    -- Slash command to set preferred pronouns: /setPronouns <pronouns>
    -- Note: slashes within the argument (e.g. he/him) are passed as plain text and need no escaping
    SLASH_SETPRONOUNS1 = '/setPronouns'
    SLASH_SETPRONOUNS2 = '/setpronouns'
    SlashCmdList["SETPRONOUNS"] = function(msg)
        local pronouns = msg:match("^%s*(.-)%s*$")
        if pronouns and pronouns ~= "" then
            SchlingelInc:SetPreferredPronouns(pronouns)
            SchlingelInc:Print(SchlingelInc.Constants.COLORS.SUCCESS ..
                "Präferierte Pronomen gesetzt: " .. pronouns .. "|r")
        else
            SchlingelInc:Print(SchlingelInc.Constants.COLORS.WARNING ..
                "Verwendung: /setPronouns <deine präferierten Pronomen>|r")
        end
    end
end
