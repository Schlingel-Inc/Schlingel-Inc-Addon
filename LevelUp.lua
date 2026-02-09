-- LevelUp.lua
-- Handles level-up milestone announcements to guild chat

SchlingelInc.LevelUps = {}

-- Registers level-up event handler
-- Announces to guild when player reaches a milestone level
function SchlingelInc.LevelUps:Initialize()
	SchlingelInc.EventManager:RegisterHandler("PLAYER_LEVEL_UP",
		function(_, level)
			CheckForMilestone(level)
			SchlingelInc.LevelUps:CheckForCap(level)
		end, 0, "LevelUpEvents")
end

function CheckForMilestone(level)
	for _, lvl in pairs(SchlingelInc.Constants.LEVEL_MILESTONES) do
		if level == lvl then
			local player = UnitName("player")
			local Message = player .. " hat Level " .. level .. " erreicht! Schlingel! Schlingel! Schlingel!"
			SendChatMessage(Message, "GUILD")
		end
	end
end

function SchlingelInc.LevelUps:CheckForCap(level)
	if level >= SchlingelInc.Rules.CurrentCap then
		local playerExp = UnitXP("player")
		local levelUpXP = UnitXPMax("player")
		local currentXPPercent = playerExp / levelUpXP * 100
		SchlingelInc.Popup:Show({
        title = "Level Cap erreicht",
        message = string.format("Du bist bei %d%% XP von Level %d.\nDas aktuelle Cap ist %d.\n Achte auf die Level Schande!", currentXPPercent, level + 1, SchlingelInc.Rules.CurrentCap),
		displayTime = 5
	})
	end
end