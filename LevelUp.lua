SchlingelInc.LevelUps = {}

function SchlingelInc.LevelUps:Initialize()
	SchlingelInc.EventManager:RegisterHandler("PLAYER_LEVEL_UP",
		function(_, level)
			for _, lvl in pairs(SchlingelInc.Constants.LEVEL_MILESTONES) do
				if level == lvl then
					local player = UnitName("player")
					local Message = player .. " hat Level " .. level .. " erreicht! Schlingel! Schlingel! Schlingel!"
					SendChatMessage(Message, "GUILD")
				end
			end
		end, 0, "LevelMilestoneAnnounce")
end
