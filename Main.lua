-- SchlingelInc:OnLoad() Funktion - wird ausgeführt, wenn das Addon selbst geladen wird.
function SchlingelInc:OnLoad()
    -- Initialisiere EventManager zuerst
    SchlingelInc.EventManager:Initialize()

    -- Initialisiert Kernmodule des Addons.
    SchlingelInc.Global:Initialize()
    SchlingelInc.Death:Initialize()
    SchlingelInc.Rules:Initialize()
    SchlingelInc.LevelUps:Initialize()
    SchlingelInc.GuildRecruitment:Initialize()

    SchlingelInc:InitializeOptionsDB()

    -- Slash-Befehle für Gildenrekrutierung (derzeit für Produktion auskommentiert).
    --SchlingelInc.GuildRecruitment:InitializeSlashCommands()

    -- Erstellt und initialisiert den PvP-Warn-Frame.
    SchlingelInc:CreatePvPWarningFrame()

    -- Initialisiert die Minimap-Icon-Funktionalität.
    SchlingelInc:InitMinimapIcon()

    -- Gibt eine Bestätigungsnachricht aus, dass das Addon geladen wurde, inklusive Version.
    SchlingelInc:Print("Addon version " .. SchlingelInc.version .. " geladen")
end

-- --- Event-Registrierungen über den zentralen EventManager ---

-- ADDON_LOADED wird noch manuell behandelt, da EventManager erst danach initialisiert wird
local addonLoadedFrame = CreateFrame("Frame", "SchlingelIncAddonLoadedFrame")
addonLoadedFrame:RegisterEvent("ADDON_LOADED")
addonLoadedFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == SchlingelInc.name then
        SchlingelInc:OnLoad()

        -- Registriere alle anderen Events nach der Initialisierung
        SchlingelInc.EventManager:RegisterHandler("PLAYER_ENTERING_WORLD",
            function()
                SchlingelInc:CheckDependencies()
                SchlingelInc:CheckAddonVersion()

                if not SchlingelInc.initialPlayTimeRequested then
                    RequestTimePlayed()
                    SchlingelInc.initialPlayTimeRequested = true
                end
            end, 100, "MainAddonInit")

        SchlingelInc.EventManager:RegisterHandler("TIME_PLAYED_MSG",
            function(_, totalTimeSeconds, levelTimeSeconds)
                SchlingelInc.GameTimeTotal = totalTimeSeconds or 0
                SchlingelInc.GameTimePerLevel = levelTimeSeconds or 0

                local charTabIndex = 1
                if SchlingelInc.infoWindow and SchlingelInc.infoWindow:IsShown() then
                    if SchlingelInc.infoWindow.tabContentFrames and
                        SchlingelInc.infoWindow.tabContentFrames[charTabIndex] and
                        SchlingelInc.infoWindow.tabContentFrames[charTabIndex]:IsShown() and
                        SchlingelInc.infoWindow.tabContentFrames[charTabIndex].Update then
                        SchlingelInc.infoWindow.tabContentFrames[charTabIndex]:Update(
                            SchlingelInc.infoWindow.tabContentFrames[charTabIndex])
                    end
                end
            end, 0, "TimePlayedUpdate")

        SchlingelInc.EventManager:RegisterHandler("PLAYER_LEVEL_UP",
            function()
                SchlingelInc.CharacterPlaytimeLevel = 0
                RequestTimePlayed()
            end, 50, "PlaytimeReset")
    end
end)