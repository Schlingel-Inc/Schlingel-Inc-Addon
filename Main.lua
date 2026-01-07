local function MuteGroupInviteSounds()
	-- Mute party invite sound (the "whoosh" when receiving/sending invites)
	MuteSoundFile(567275) -- IG_PLAYER_INVITE file ID
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

-- SchlingelInc:OnLoad() function - executes when the addon is loaded.
function SchlingelInc:OnLoad()
    -- Initialize EventManager first
    SchlingelInc.EventManager:Initialize()

    -- Initialize core addon modules.
    SchlingelInc.Global:Initialize()
    SchlingelInc.GuildCache:Initialize()
    SchlingelInc.Death:Initialize()
    SchlingelInc.Rules:Initialize()
    SchlingelInc.LevelUps:Initialize()
    SchlingelInc.GuildRecruitment:Initialize()
    SchlingelInc.Debug:Initialize()

    SchlingelInc:InitializeOptionsDB()

    -- Create and initialize the PvP warning frame.
    SchlingelInc:CreatePvPWarningFrame()

    -- Initialize minimap icon functionality.
    SchlingelInc:InitMinimapIcon()

    -- Output confirmation message that addon was loaded, including version.
    SchlingelInc:Print("Addon version " .. SchlingelInc.version .. " loaded")

    -- QoL: Hide mail icon and mute annoying sounds
    HideMinimapMail()
    MuteGroupInviteSounds()
end

-- --- Event registrations via the central EventManager ---

-- ADDON_LOADED is still handled manually since EventManager is initialized after it
local addonLoadedFrame = CreateFrame("Frame", "SchlingelIncAddonLoadedFrame")
addonLoadedFrame:RegisterEvent("ADDON_LOADED")
addonLoadedFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == SchlingelInc.name then
        SchlingelInc:OnLoad()

        -- Register all other events after initialization
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
