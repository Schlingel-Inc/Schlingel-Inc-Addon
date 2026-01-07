-- Initialize the Death module in the SchlingelInc namespace
SchlingelInc.Death = {
	lastChatMessage = "",
	lastAttackSource = "",
	MAX_LOG_ENTRIES = 50  -- Maximum number of stored deaths
}

-- Initialize CharacterDeaths to avoid nil reference
CharacterDeaths = CharacterDeaths or 0

-- Session-based death log (NOT persisted, only during session)
-- This prevents out-of-sync issues when players are offline
SchlingelInc.DeathLogData = {}

-- Function to add an entry to the death log with rotation
function SchlingelInc.Death:AddLogEntry(entry)
	table.insert(SchlingelInc.DeathLogData, 1, entry)

	-- Rotation: Keep only the last MAX_LOG_ENTRIES entries
	while #SchlingelInc.DeathLogData > SchlingelInc.Death.MAX_LOG_ENTRIES do
		table.remove(SchlingelInc.DeathLogData)
	end
end

-- Initializes the Death module and registers events
function SchlingelInc.Death:Initialize()
	local playerName = UnitName("player")

	-- PLAYER_DEAD event handler
	SchlingelInc.EventManager:RegisterHandler("PLAYER_DEAD",
		function()
			-- If in raid or battleground, skip everything because we neither track nor announce the death
			if SchlingelInc:IsInBattleground() or SchlingelInc:IsInRaid() then return end

			local name = UnitName("player")
			if not name then return end

			local _, rank = GetGuildInfo("player")
			local class = UnitClass("player")
			local level = UnitLevel("player")
			local sex = UnitSex("player")

			-- Safe zone query with error handling
			local zone, mapID
			if IsInInstance() then
				zone = GetInstanceInfo()
			else
				mapID = C_Map.GetBestMapForUnit("player")
				if mapID then
					local mapInfo = C_Map.GetMapInfo(mapID)
					zone = mapInfo and mapInfo.name or "Unknown"
				else
					zone = "Unknown"
				end
			end

			local pronoun = SchlingelInc.Constants.PRONOUNS[sex] or "der"

			local messageFormat = "%s %s %s ist mit Level %s in %s gestorben. Schande!"
			local messageFormatWithRank = "Ewiger Schlingel %s, %s %s ist mit Level %s in %s gestorben. Schande!"
			if (rank ~= nil and rank == "EwigerSchlingel") then
				messageFormat = messageFormatWithRank
			end
			local messageString = messageFormat:format(name, pronoun, class, level, zone)

			if SchlingelInc.Death.lastAttackSource and SchlingelInc.Death.lastAttackSource ~= "" then
				messageString = string.format("%s Gestorben an %s", messageString, SchlingelInc.Death.lastAttackSource)
				SchlingelInc.Death.lastAttackSource = ""
			end

			if SchlingelInc.Death.lastChatMessage and SchlingelInc.Death.lastChatMessage ~= "" then
				messageString = string.format('%s. Die letzten Worte: "%s"', messageString, SchlingelInc.Death.lastChatMessage)
			end

			local popupMessageFormat = "SCHLINGEL_DEATH:%s:%s:%s:%s"
			local popupMessageString = popupMessageFormat:format(name, class, level, zone)

			SendChatMessage(messageString, "GUILD")
			C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, popupMessageString, "GUILD")
			CharacterDeaths = CharacterDeaths + 1
		end, 0, "DeathTracker")

	-- Chat message tracker for last words
	SchlingelInc.EventManager:RegisterHandler("CHAT_MSG_SAY", function(_, msg, sender)
		if sender == playerName or sender:match("^" .. playerName .. "%-") then
			SchlingelInc.Death.lastChatMessage = msg
		end
	end, 0, "LastWordsSay")

	SchlingelInc.EventManager:RegisterHandler("CHAT_MSG_GUILD", function(_, msg, sender)
		if sender == playerName or sender:match("^" .. playerName .. "%-") then
			SchlingelInc.Death.lastChatMessage = msg
		end
	end, 0, "LastWordsGuild")

	SchlingelInc.EventManager:RegisterHandler("CHAT_MSG_PARTY", function(_, msg, sender)
		if sender == playerName or sender:match("^" .. playerName .. "%-") then
			SchlingelInc.Death.lastChatMessage = msg
		end
	end, 0, "LastWordsParty")

	SchlingelInc.EventManager:RegisterHandler("CHAT_MSG_RAID", function(_, msg, sender)
		if sender == playerName or sender:match("^" .. playerName .. "%-") then
			SchlingelInc.Death.lastChatMessage = msg
		end
	end, 0, "LastWordsRaid")

	-- Combat log for last attack source
	SchlingelInc.EventManager:RegisterHandler("COMBAT_LOG_EVENT_UNFILTERED",
		function()
			local _, subevent, _, _, sourceName, _, _, destGUID = CombatLogGetCurrentEventInfo()

			if destGUID ~= UnitGUID("player") then return end
			if not subevent:match("_DAMAGE$") then return end

			SchlingelInc.Death.lastAttackSource = sourceName or "Unknown"
		end, 0, "LastAttackTracker")

	-- Addon message popup tracker
	SchlingelInc.EventManager:RegisterHandler("CHAT_MSG_ADDON",
		function(_, prefix, msg)
			if prefix == SchlingelInc.prefix and msg:find("SCHLINGEL_DEATH") then
				local success, name, class, level, zone = pcall(function()
					return msg:match("^SCHLINGEL_DEATH:([^:]+):([^:]+):([^:]+):([^:]+)$")
				end)

				if success and name and class and level and zone then
					local messageFormat = "%s der %s ist mit Level %s in %s gestorben."
					local messageString = messageFormat:format(name, class, level, zone)
					SchlingelInc.DeathAnnouncement:ShowDeathMessage(messageString)

					-- Capture the current lastAttackSource for this specific death
					-- Note: This is the attack source from the SENDER's death, not the receiver's
					-- Since this is an addon message about someone else's death, we use "Unknown"
					local deathEntry = {
						name = name,
						class = class,
						level = tonumber(level),
						zone = zone,
						cause = "Unknown",  -- Remote death, we don't know the actual cause
						timestamp = time()
					}

					-- Add entry to persistent log (automatically added to DeathLogData)
					SchlingelInc.Death:AddLogEntry(deathEntry)

					-- Update UI if open
					SchlingelInc:UpdateMiniDeathLog()
				end
			end
		end, 0, "DeathAnnouncementReceiver")
end

-- Define slash command
SLASH_DEATHSET1 = '/deathset'
SlashCmdList["DEATHSET"] = function(msg)
	local inputValue = tonumber(msg)

	-- If user didn't provide a number, show error message with instructions
	if not inputValue then
		SchlingelInc:Print(SchlingelInc.Constants.COLORS.ERROR .. "Invalid input. Use: /deathset <number>|r")
		return
	end

	-- Validation: Number must be in a reasonable range
	if inputValue < 0 or inputValue > 999999 then
		SchlingelInc:Print(SchlingelInc.Constants.COLORS.ERROR .. "Value must be between 0 and 999999|r")
		return
	end

	CharacterDeaths = inputValue
	SchlingelInc:Print(SchlingelInc.Constants.COLORS.SUCCESS .. "Death counter set to " .. CharacterDeaths .. "|r")
end
