local function MuteGroupInviteSounds()
	-- Mute party invite sound (the "whoosh" when receiving/sending invites)
	MuteSoundFile(567275) -- IG_PLAYER_INVITE file ID
	-- Mute LFG role check sound
	MuteSoundFile(567478) -- ReadyCheck/RoleCheck "wom wom wommm" sound
end

local function HideMinimapMail()
	local mail = MiniMapMailFrame or MiniMapMailIcon
	if not mail then return end

	-- Stop Blizzard from updating/showing it
	if mail.UnregisterAllEvents then
		mail:UnregisterAllEvents()
	end

	-- Hide it now
	mail:Hide()

	-- Make it non-interactive
	mail:SetAlpha(0)
	mail:SetScript("OnEnter", nil)
	mail:SetScript("OnLeave", nil)

	-- Prevent future :Show() calls
	if mail.Show then
		mail.Show = function() end
	end
end

-- SchlingelInc:OnLoad() Funktion - wird ausgeführt, wenn das Addon selbst geladen wird.
function SchlingelInc:OnLoad()
    -- Initialisiere EventManager zuerst
    SchlingelInc.EventManager:Initialize()

    -- Initialisiert Kernmodule des Addons.
    SchlingelInc.Global:Initialize()
    SchlingelInc.GuildCache:Initialize()
    SchlingelInc.Death:Initialize()
    SchlingelInc.Rules:Initialize()
    SchlingelInc.LevelUps:Initialize()
    SchlingelInc.GuildRecruitment:Initialize()
    SchlingelInc.Debug:Initialize()

    SchlingelInc:InitializeOptionsDB()

    -- Erstellt und initialisiert den PvP-Warn-Frame.
    SchlingelInc:CreatePvPWarningFrame()

    -- Initialisiert die Minimap-Icon-Funktionalität.
    SchlingelInc:InitMinimapIcon()

    -- Gibt eine Bestätigungsnachricht aus, dass das Addon geladen wurde, inklusive Version.
    SchlingelInc:Print("Addon version " .. SchlingelInc.version .. " geladen")

    -- QoL: Verstecke Mail-Icon und mute störende Sounds
    HideMinimapMail()
    MuteGroupInviteSounds()
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