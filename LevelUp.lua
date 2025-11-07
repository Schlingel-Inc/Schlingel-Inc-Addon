SchlingelInc.LevelUps = {}

function SchlingelInc.LevelUps:Initialize()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_LEVEL_UP") -- Registriere Event für Level-Up
    frame:SetScript("OnEvent", function(_, event, level)
        if event == "PLAYER_LEVEL_UP" then
            for _, lvl in pairs(SchlingelInc.Constants.LEVEL_MILESTONES) do
                if level == lvl then
                    local player = UnitName("player")
                    local Message = player .. " hat Level " .. level .. " erreicht! Schlingel! Schlingel! Schlingel!"
                    SendChatMessage(Message, "GUILD")
                end
            end
        end
    end)
end
