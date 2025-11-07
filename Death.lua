-- Initialisiere das Death-Modul im SchlingelInc Namespace
SchlingelInc.Death = {
	lastChatMessage = "",
	lastAttackSource = "",
	MAX_LOG_ENTRIES = 50  -- Maximale Anzahl gespeicherter Tode
}

-- Initialisiere CharacterDeaths um einen Nil Verweis zu vermeiden
CharacterDeaths = CharacterDeaths or 0

-- Initialisiere persistentes Death Log (wird in SavedVariables gespeichert)
SchlingelDeathLog = SchlingelDeathLog or {}

-- Funktion zum Hinzufügen eines Eintrags zum Death Log mit Rotation
function SchlingelInc.Death:AddLogEntry(entry)
	table.insert(SchlingelDeathLog, 1, entry)

	-- Rotation: Behalte nur die letzten MAX_LOG_ENTRIES Einträge
	while #SchlingelDeathLog > SchlingelInc.Death.MAX_LOG_ENTRIES do
		table.remove(SchlingelDeathLog)
	end
end

-- Initialisiert das Death-Modul und registriert Events
function SchlingelInc.Death:Initialize()
	local playerName = UnitName("player")

	-- PLAYER_DEAD Event Handler
	SchlingelInc.EventManager:RegisterHandler("PLAYER_DEAD",
		function()
			if CharacterDeaths == nil then
				CharacterDeaths = 1
				return
			end

			local name = UnitName("player")
			if not name then return end

			local _, rank = GetGuildInfo("player")
			local class = UnitClass("player")
			local level = UnitLevel("player")
			local sex = UnitSex("player")

			-- Sichere Zone-Abfrage mit Fehlerbehandlung
			local zone, mapID
			if IsInInstance() then
				zone = GetInstanceInfo()
			else
				mapID = C_Map.GetBestMapForUnit("player")
				if mapID then
					local mapInfo = C_Map.GetMapInfo(mapID)
					zone = mapInfo and mapInfo.name or "Unbekannt"
				else
					zone = "Unbekannt"
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

			if not SchlingelInc:IsInBattleground() and not SchlingelInc:IsInRaid() then
				SendChatMessage(messageString, "GUILD")
				C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, popupMessageString, "GUILD")
				CharacterDeaths = CharacterDeaths + 1
			end
		end, 0, "DeathTracker")

	-- Chat Message Tracker für letzte Worte
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

	-- Combat Log für letzte Angriffsquelle
	SchlingelInc.EventManager:RegisterHandler("COMBAT_LOG_EVENT_UNFILTERED",
		function()
			local _, subevent, _, _, sourceName, _, _, destGUID = CombatLogGetCurrentEventInfo()

			if destGUID ~= UnitGUID("player") then return end
			if not subevent:match("_DAMAGE$") then return end

			SchlingelInc.Death.lastAttackSource = sourceName or "Unbekannt"
		end, 0, "LastAttackTracker")

	-- Addon Message Popup Tracker
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

					local cause = SchlingelInc.Death.lastAttackSource or "Unbekannt"
					local deathEntry = {
						name = name,
						class = class,
						level = tonumber(level),
						zone = zone,
						cause = cause,
						timestamp = time()
					}

					SchlingelInc.Death:AddLogEntry(deathEntry)

					SchlingelInc.DeathLogData = SchlingelInc.DeathLogData or {}
					table.insert(SchlingelInc.DeathLogData, deathEntry)

					SchlingelInc:UpdateMiniDeathLog()
				end
			end
		end, 0, "DeathAnnouncementReceiver")
end

-- Slash-Befehl definieren
SLASH_DEATHSET1 = '/deathset'
SlashCmdList["DEATHSET"] = function(msg)
	local inputValue = tonumber(msg)

	-- Kommt keine Zahl vom User, gibt es eine Fehlermeldung plus Anleitung.
	if not inputValue then
		SchlingelInc:Print(SchlingelInc.Constants.COLORS.ERROR .. "Ungültiger Input. Benutze: /deathset <Zahl>|r")
		return
	end

	-- Validierung: Zahl muss im sinnvollen Bereich liegen
	if inputValue < 0 or inputValue > 999999 then
		SchlingelInc:Print(SchlingelInc.Constants.COLORS.ERROR .. "Der Wert muss zwischen 0 und 999999 liegen|r")
		return
	end

	CharacterDeaths = inputValue
	SchlingelInc:Print(SchlingelInc.Constants.COLORS.SUCCESS .. "Tod-Counter wurde auf " .. CharacterDeaths .. " gesetzt.|r")
end

-- -- Slash-Befehl definieren zu Deugzwecken
-- SLASH_DEATHFRAME1 = '/deathframe'
-- SlashCmdList["DEATHFRAME"] = function()
-- 	SchlingelInc.DeathAnnouncement:ShowDeathMessage("Pudidev ist mit Level 100 in Mordor gestorben!")
-- 			SchlingelInc.DeathLogData = SchlingelInc.DeathLogData or {}
-- 			table.insert(SchlingelInc.DeathLogData, {
-- 			name = "Pudidev",
-- 			class = "Krieger",
-- 			level = math.random(60),
-- 			zone = "Durotar",
-- 			cause = "Eber"
-- 			})
-- 			SchlingelInc:UpdateMiniDeathLog()
-- end
