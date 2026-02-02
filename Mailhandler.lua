local frame = CreateFrame("Frame")
frame:RegisterEvent("MAIL_INBOX_UPDATE")

-- Checkt, ob der Absender "sicher" ist (man selbst, Gildenkollege oder Blizzard)
local function IsSafeSender(index)
    -- Wir holen uns die wichtigen Daten direkt über den Index
    -- 3: sender, 11: isGM
    local _, _, sender, _, _, _, _, _, _, _, isGM = GetInboxHeaderInfo(index)

    -- 1. Blizzard/System Check (isGM ist true bei offizieller Post)
    if isGM then return true end

    -- 2. Falls kein Sender existiert, ist es meist eine System-Mail
    if not sender or sender == "" then return true end

    -- 3. Eigen-Check
    if sender == UnitName("player") then return true end

    -- 4. Gilden-Check
    local numGuild = GetNumGuildMembers()
    for i = 1, numGuild do
        local fullName = GetGuildRosterInfo(i)
        if fullName then
            local shortName = fullName:match("([^%-]+)")
            if shortName == sender or fullName == sender then return true end
        end
    end

    return false
end

-- Eigenes Warn-Popup, wenn man auf eine "fremde" Mail klickt
StaticPopupDialogs["CONFIRM_DELETE_NON_GUILD_MAIL"] = {
    text = "|cffff0000HINWEIS:|r Post von Nicht-Gildenmitglied!\n\nDiese Post muss gelöscht werden.",
    button1 = "Löschen",
    button2 = "Abbrechen",
    OnAccept = function(_, data)
        if data and data.slot then
            if not data.itemCount or data.itemCount == 0 then
                DeleteInboxItem(data.slot)
            else
                local mailButton = _G["MailItem"..data.slot.."Button"]
                if mailButton then
                    -- Hide the guard temporarily to allow the original click handler to work
                    if mailButton.mailGuard then
                        mailButton.mailGuard:Hide()
                    end

                    -- Click the button to open the mail
                    mailButton:Click()

                    -- Kurz warten, bis das Fenster offen ist, dann Blizzards Lösch-Button triggern
                    C_Timer.After(0.3, function()
                        if OpenMailFrame:IsVisible() then
                            OpenMailDeleteButton:Click()

                            -- Falls Blizzard nochmal nachfragt (bei Items/Geld), bestätigen wir das auch automatisch
                            C_Timer.After(0.2, function()
                                for j = 1, 4 do
                                    local f = _G["StaticPopup"..j]
                                    if f and f:IsVisible() and (f.which == "DELETE_MAIL" or f.which == "CONFIRM_DELETE_ITEM") then
                                        _G["StaticPopup"..j.."Button1"]:Click()
                                    end
                                end
                            end)
                        end
                    end)
                end
            end
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

-- Macht "Alle öffnen"-Buttons unbrauchbar, um Unfälle zu vermeiden
local function KillButton(btn)
    if not btn or btn.isDead then return end
    btn:Disable()
    btn:SetAlpha(0.3)

    -- Wir legen einen unsichtbaren Blocker drüber, damit auch andere Addons nicht drankommen
    local blocker = CreateFrame("Button", nil, btn)
    blocker:SetAllPoints()
    blocker:SetFrameLevel(btn:GetFrameLevel() + 2)
    blocker:EnableMouse(true)
    blocker:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("|cffff0000Dieser Button ist gesperrt!", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    blocker:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Verhindert, dass der Button wieder aktiviert wird
    hooksecurefunc(btn, "Enable", function() btn:Disable() end)
    btn.isDead = true
end

-- Geht die aktuelle Post-Seite durch
local function UniversalScan()
    if not MailFrame:IsVisible() then return end

    local numItems, _ = GetInboxNumItems()
    for i = 1, numItems do
        local item = _G["MailItem"..i]
        local senderText = _G["MailItem"..i.."Sender"]
        local button = _G["MailItem"..i.."Button"]

        if item and button then
            local _, _, _, _, _, _, _, itemCount = GetInboxHeaderInfo(i)
            if not IsSafeSender(i) then
                -- Fremder Absender: Name wird rot
                senderText:SetTextColor(1, 0, 0)

                -- Create guard overlay if it doesn't exist
                if not button.mailGuard then
                    button.mailGuard = CreateFrame("Button", nil, button)
                    button.mailGuard:SetAllPoints()
                    button.mailGuard:SetFrameLevel(button:GetFrameLevel() + 10)
                    button.mailGuard:EnableMouse(true)
                end

                -- Set up the guard's click handler
                button.mailGuard:SetScript("OnClick", function()
                    local id = i
                    local d = StaticPopup_Show("CONFIRM_DELETE_NON_GUILD_MAIL")
                    if d then d.data = {slot = id, itemCount = itemCount} end
                end)
                button.mailGuard:Show()
            else
                -- Gildenkollege: Alles okay, Button freigeben
                if senderText then senderText:SetTextColor(1, 0.8, 0) end
                if button.mailGuard then button.mailGuard:Hide() end
            end
        end
    end

    -- Sucht nach "Open All" Buttons (nur im Mailbox-Bereich) und deaktiviert sie
    if MailFrame and MailFrame:IsVisible() then
        -- Check known mail addon buttons
        local mailButtons = {
            "OpenAllMail",              -- Common addon button
            "PostalOpenAllButton",      -- Postal: Open All
            "PostalSelectOpenButton",   -- Postal: Open Selected (main bypass method)
            "PostalSelectReturnButton", -- Postal: Return Selected
            "Postal_OpenAllMenuButton", -- Postal: Menu
            "Postal_ModuleMenuButton",  -- Postal: Module menu
            "AutoLootMailButton"
        }

        for _, btnName in ipairs(mailButtons) do
            local btn = _G[btnName]
            if btn and btn:IsVisible() then
                KillButton(btn)
            end
        end

        -- Scan only frames that are children of MailFrame
        local f = MailFrame:GetChildren()
        if f then
            for i = 1, select("#", MailFrame:GetChildren()) do
                local child = select(i, MailFrame:GetChildren())
                if child and child:IsObjectType("Button") and child:IsVisible() then
                    local txt = child.GetText and child:GetText()
                    local name = child.GetName and child:GetName() or ""
                    if txt and (txt:find("Open All") or txt:find("Alle öffnen")) or
                       name:find("OpenAll") then
                        if not name:find("MailItem") then
                            KillButton(child)
                        end
                    end
                end
            end
        end

        -- Disable Postal checkboxes to prevent selecting mail
        for i = 1, 7 do -- 7 visible mail items per page
            local cb = _G["PostalInboxCB"..i]
            if cb then
                cb:Hide()
                cb:Disable()
            end
        end
    end
end

frame:SetScript("OnEvent", function(_, event)
    if event == "MAIL_INBOX_UPDATE" then
        UniversalScan()
    end
end)