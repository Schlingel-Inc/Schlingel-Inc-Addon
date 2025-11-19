-- Lädt benötigte Bibliotheken für das Minimap-Icon. 'true' unterdrückt Fehler, falls nicht gefunden.
local LDB = LibStub("LibDataBroker-1.1", true)
local DBIcon = LibStub("LibDBIcon-1.0", true)

-- Datenobjekt für das Minimap Icon (OnClick wird später gesetzt, falls benötigt).
if LDB then                                                                -- Fährt nur fort, wenn LibDataBroker verfügbar ist.
    SchlingelInc.minimapDataObject = LDB:NewDataObject(SchlingelInc.name, {
        type = "launcher",                                                 -- Typ des LDB-Objekts: Startet eine UI oder Funktion.
        label = SchlingelInc.name,                                         -- Text neben dem Icon (oft nur im LDB Display Addon sichtbar).
        icon = "Interface\\AddOns\\SchlingelInc\\media\\icon-minimap.tga", -- Pfad zum Icon.
        OnClick = function(clickedFrame, button)
            if button == "LeftButton" then
                if IsShiftKeyDown() then
                    SchlingelInc:ToggleDeathLogWindow()
                    return
                end
                if SchlingelInc.ToggleInfoWindow then
                    SchlingelInc:ToggleInfoWindow()
                    return
                end
            elseif button == "RightButton" then
                if CanGuildInvite() then
                    if SchlingelInc.ToggleInactivityWindow then
                        SchlingelInc:ToggleInactivityWindow()
                    end
                end
            end
        end,

        -- OnClick = function... (WURDE HIER ENTFERNT, kann später hinzugefügt werden)
        OnEnter = function(selfFrame)                                                          -- Wird ausgeführt, wenn die Maus über das Icon fährt.
            GameTooltip:SetOwner(selfFrame, "ANCHOR_RIGHT")                                    -- Positioniert den Tooltip rechts vom Icon.
            GameTooltip:AddLine(SchlingelInc.name, 1, 0.7, 0.9)                                -- Addon-Name im Tooltip.
            GameTooltip:AddLine("Version: " .. (SchlingelInc.version or "Unbekannt"), 1, 1, 1) -- Version im Tooltip.
            GameTooltip:AddLine("Linksklick: Info anzeigen", 1, 1, 1)                          -- Hinweis für Linksklick.
            GameTooltip:AddLine("Shift + Linksklick: Deathlog", 1, 1, 1)                       -- Hinweis für Shift + Linksklick.
            if CanGuildInvite() then
                GameTooltip:AddLine("Rechtsklick: Inaktive Mitglieder", 0.8, 0.8, 0.8)         -- Hinweis für Rechtsklick.
            end
            GameTooltip:Show()                                                                 -- Zeigt den Tooltip an.
        end,
        OnLeave = function()                                                                   -- Wird ausgeführt, wenn die Maus das Icon verlässt.
            GameTooltip:Hide()                                                                 -- Versteckt den Tooltip.
        end
    })
else
    -- Gibt eine Meldung aus, falls LibDataBroker nicht gefunden wurde.
    SchlingelInc:Print("LibDataBroker-1.1 nicht gefunden. Minimap-Icon wird nicht erstellt.")
end

-- Initialisierung des Minimap Icons.
function SchlingelInc:InitMinimapIcon()
    -- Bricht ab, falls LibDBIcon oder das LDB Datenobjekt nicht vorhanden sind.
    if not DBIcon or not SchlingelInc.minimapDataObject then
        SchlingelInc:Print("LibDBIcon-1.0 oder LDB-Datenobjekt nicht gefunden. Minimap-Icon wird nicht initialisiert.")
        return
    end

    -- Registriert das Icon nur einmal.
    if not SchlingelInc.minimapRegistered then
        -- Initialisiert die Datenbank für Minimap-Einstellungen, falls nicht vorhanden.
        SchlingelInc.db = SchlingelInc.db or {}
        SchlingelInc.db.minimap = SchlingelInc.db.minimap or { hide = false } -- Standardmäßig nicht versteckt.

        -- Registriert das Icon bei LibDBIcon.
        DBIcon:Register(SchlingelInc.name, SchlingelInc.minimapDataObject, SchlingelInc.db.minimap)
        SchlingelInc.minimapRegistered = true -- Markiert das Icon als registriert.
        SchlingelInc:Print("Minimap-Icon registriert.")
    end
end