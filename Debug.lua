-- Debug.lua
-- Zentrales Debug-Modul für Entwickler
-- Alle Debug-Befehle sind nur für Spieler mit dem Gildenrang "Devschlingel" verfügbar

SchlingelInc.Debug = {}

-- Prüft, ob der Spieler Debug-Berechtigung hat
function SchlingelInc.Debug:HasPermission()
	local _, rank = GetGuildInfo("player")
	return rank == "Devschlingel"
end

-- Zeigt eine Berechtigung-Fehlermeldung an
local function ShowPermissionError()
	SchlingelInc:Print(SchlingelInc.Constants.COLORS.ERROR ..
		"Dieser Befehl ist nur für Devschlingel verfügbar.|r")
end

-- Initialisiert das Debug-Modul
function SchlingelInc.Debug:Initialize()
	-- Debug-Modus Toggle
	SchlingelInc.Debug.enabled = false

	-- Hauptbefehl: /schlingeldebug
	SLASH_SCHLINGELDEBUG1 = '/schlingeldebug'
	SlashCmdList["SCHLINGELDEBUG"] = function(msg)
		if not SchlingelInc.Debug:HasPermission() then
			ShowPermissionError()
			return
		end

		local args = {}
		for word in msg:gmatch("%S+") do
			table.insert(args, word)
		end

		local command = args[1] or "help"

		if command == "help" then
			SchlingelInc.Debug:ShowHelp()
		elseif command == "toggle" then
			SchlingelInc.Debug:ToggleDebugMode()
		elseif command == "eventdebug" then
			SchlingelInc.EventManager:DebugInfo()
		elseif command == "deathframe" then
			SchlingelInc.Debug:TestDeathFrame()
		elseif command == "deathset" then
			local value = tonumber(args[2])
			if value then
				SchlingelInc.Debug:SetDeathCount(value)
			else
				SchlingelInc:Print(SchlingelInc.Constants.COLORS.ERROR ..
					"Ungültige Zahl. Benutze: /schlingeldebug deathset <Zahl>|r")
			end
		elseif command == "guildrequest" then
			SchlingelInc.Debug:TestGuildRequest(args[2])
		elseif command == "cachestats" then
			SchlingelInc.Debug:ShowCacheStats()
		elseif command == "cacherefresh" then
			SchlingelInc.GuildCache:ForceRefresh()
			SchlingelInc:Print(SchlingelInc.Constants.COLORS.SUCCESS .. "Guild Cache Refresh erzwungen|r")
		else
			SchlingelInc:Print(SchlingelInc.Constants.COLORS.WARNING ..
				"Unbekannter Befehl. Nutze /schlingeldebug help für Hilfe.|r")
		end
	end

	-- Alias: /sdebug
	SLASH_SDEBUG1 = '/sdebug'
	SlashCmdList["SDEBUG"] = SlashCmdList["SCHLINGELDEBUG"]
end

-- Zeigt die Debug-Hilfe an
function SchlingelInc.Debug:ShowHelp()
	print(SchlingelInc.Constants.COLORS.INFO .. "=== SchlingelInc Debug-Befehle ===" .. "|r")
	print(SchlingelInc.colorCode .. "/schlingeldebug help" .. "|r - Zeigt diese Hilfe")
	print(SchlingelInc.colorCode .. "/schlingeldebug toggle" .. "|r - Aktiviert/Deaktiviert Debug-Modus")
	print(SchlingelInc.colorCode .. "/schlingeldebug eventdebug" .. "|r - Zeigt EventManager Debug-Info")
	print(SchlingelInc.colorCode .. "/schlingeldebug deathframe" .. "|r - Test Death Announcement Frame")
	print(SchlingelInc.colorCode .. "/schlingeldebug deathset <zahl>" .. "|r - Setzt den Tod-Counter")
	print(SchlingelInc.colorCode .. "/schlingeldebug guildrequest <name>" .. "|r - Testet Guild Request an einen Officer")
	print(SchlingelInc.colorCode .. "/schlingeldebug cachestats" .. "|r - Zeigt Guild Cache Statistiken")
	print(SchlingelInc.colorCode .. "/schlingeldebug cacherefresh" .. "|r - Erzwingt Guild Cache Refresh")
	print(SchlingelInc.Constants.COLORS.WARNING .. "Alias: /sdebug <befehl>" .. "|r")
end

-- Aktiviert/Deaktiviert den Debug-Modus
function SchlingelInc.Debug:ToggleDebugMode()
	SchlingelInc.Debug.enabled = not SchlingelInc.Debug.enabled
	local status = SchlingelInc.Debug.enabled and "aktiviert" or "deaktiviert"
	SchlingelInc:Print(SchlingelInc.Constants.COLORS.SUCCESS ..
		"Debug-Modus " .. status .. "|r")
end

-- Testet das Death Announcement Frame
function SchlingelInc.Debug:TestDeathFrame()
	local testNames = {"Pudidev", "Cricksumage", "Totanka", "Kurtibrown"}
	local testClasses = {"Krieger", "Magier", "Schamane", "Jäger"}
	local testZones = {"Durotar", "Brachland", "Mulgore", "Tirisfal"}

	local name = testNames[math.random(#testNames)]
	local class = testClasses[math.random(#testClasses)]
	local level = math.random(1, SchlingelInc.Constants.MAX_LEVEL)
	local zone = testZones[math.random(#testZones)]

	SchlingelInc.DeathAnnouncement:ShowDeathMessage(
		string.format("%s der %s ist mit Level %s in %s gestorben.", name, class, level, zone))

	-- Füge zum Death Log hinzu
	SchlingelInc.DeathLogData = SchlingelInc.DeathLogData or {}
	table.insert(SchlingelInc.DeathLogData, {
		name = name,
		class = class,
		level = level,
		zone = zone,
		cause = "Test-Eber"
	})
	SchlingelInc:UpdateMiniDeathLog()

	SchlingelInc:Print(SchlingelInc.Constants.COLORS.SUCCESS ..
		"Test Death Frame angezeigt für " .. name .. "|r")
end

-- Setzt den Death Counter
function SchlingelInc.Debug:SetDeathCount(value)
	if value < 0 or value > 999999 then
		SchlingelInc:Print(SchlingelInc.Constants.COLORS.ERROR ..
			"Der Wert muss zwischen 0 und 999999 liegen|r")
		return
	end

	CharacterDeaths = value
	SchlingelInc:Print(SchlingelInc.Constants.COLORS.SUCCESS ..
		"Tod-Counter wurde auf " .. CharacterDeaths .. " gesetzt.|r")
end

-- Testet Guild Request
function SchlingelInc.Debug:TestGuildRequest(targetName)
	if not targetName then
		SchlingelInc:Print(SchlingelInc.Constants.COLORS.ERROR ..
			"Bitte gib einen Zielnamen an: /schlingeldebug guildrequest <name>|r")
		return
	end

	local playerName = UnitName("player")
	local playerLevel = UnitLevel("player")
	local playerExp = UnitXP("player")
	local zone = SchlingelInc.GuildRecruitment:GetPlayerZone()
	local playerGold = GetMoneyString(GetMoney(), true)

	local message = string.format("INVITE_REQUEST:%s:%d:%d:%s:%s",
		playerName, playerLevel, playerExp, zone, playerGold)

	C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, message, "WHISPER", targetName)

	SchlingelInc:Print(SchlingelInc.Constants.COLORS.SUCCESS ..
		"Test Guild Request an " .. targetName .. " gesendet|r")
end

-- Zeigt Guild Cache Statistiken
function SchlingelInc.Debug:ShowCacheStats()
	local stats = SchlingelInc.GuildCache:GetStats()

	print(SchlingelInc.Constants.COLORS.INFO .. "=== Guild Cache Statistiken ===" .. "|r")
	print(string.format("Mitglieder im Cache: %d", stats.memberCount))
	print(string.format("Letzte Aktualisierung: vor %.1f Sekunden", stats.age))
	print(string.format("Cache gültig: %s", stats.isValid and "Ja" or "Nein"))

	if stats.isValid then
		print(string.format("Cache läuft ab in: %.1f Sekunden", stats.expiresIn))
	else
		print(SchlingelInc.Constants.COLORS.WARNING .. "Cache ist abgelaufen und wird beim nächsten Zugriff aktualisiert" .. "|r")
	end

	-- Zeige einige Online-Mitglieder als Beispiel
	local onlineMembers = SchlingelInc.GuildCache:GetOnlineMembers()
	print(string.format("Online Mitglieder: %d", #onlineMembers))

	print("=======================================")
end

-- Debug-Print-Funktion (nur wenn Debug-Modus aktiviert ist)
function SchlingelInc.Debug:Print(message)
	if SchlingelInc.Debug.enabled then
		print(SchlingelInc.Constants.COLORS.WARNING .. "[DEBUG]|r " .. message)
	end
end
