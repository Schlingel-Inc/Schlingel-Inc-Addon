-- Globale Tabelle für das Addon
SchlingelInc = {}

-- Addon-Name
SchlingelInc.name = "SchlingelInc"

-- Gildenmitglieder
SchlingelInc.guildMembers = {}

-- Discord Link
SchlingelInc.discordLink = "https://discord.gg/KXkyUZW"

-- Chat-Nachrichten-Prefix
-- Dieser Prefix wird verwendet, um Addon-interne Nachrichten zu identifizieren.
SchlingelInc.prefix = "SchlingelInc"

-- ColorCode für den Chat-Text
-- Bestimmt die Farbe, in der Addon-Nachrichten im Chat angezeigt werden.
SchlingelInc.colorCode = "|cFFF48CBA"

-- Version aus der TOC-Datei
-- Lädt die Version des Addons aus der .toc-Datei. Falls nicht vorhanden, wird "Unbekannt" verwendet.
SchlingelInc.version = GetAddOnMetadata("SchlingelInc", "Version") or "Unbekannt"

-- Spielzeit-Variablen werden in Main.lua per TIME_PLAYED_MSG Event aktualisiert
-- und in SchlingelInterface.lua angezeigt.
SchlingelInc.GameTimeTotal = 0
SchlingelInc.GameTimePerLevel = 0

function SchlingelInc:CountTable(table)
    local count = 0
    for _ in pairs(table) do
        count = count + 1
    end
    return count
end

-- Speichert den Zeitpunkt der letzten PvP-Warnung für jeden Spieler.
SchlingelInc.lastPvPAlert = {}

-- Global Module Initialisierung
SchlingelInc.Global = {}

function SchlingelInc.Global:Initialize()
	-- Registriere Addon Message Prefix
	C_ChatInfo.RegisterAddonMessagePrefix(SchlingelInc.prefix)

	-- PLAYER_TARGET_CHANGED für PvP-Warnungen
	SchlingelInc.EventManager:RegisterHandler("PLAYER_TARGET_CHANGED",
		function()
			if SchlingelOptionsDB["pvp_alert"] == false then
				return
			end
			if not SchlingelInc:IsInBattleground() then
				SchlingelInc:CheckTargetPvP()
			end
		end, 0, "PvPTargetChecker")

	-- Version Checking Handler
	local highestSeenVersion = SchlingelInc.version
	SchlingelInc.EventManager:RegisterHandler("CHAT_MSG_ADDON",
		function(_, prefix, message, _, sender)
			if prefix == SchlingelInc.prefix then
				local receivedVersion = message:match("^VERSION:(.+)$")
				if receivedVersion then
					-- Speichere Version für Guild Member Versions
					if sender then
						SchlingelInc.guildMemberVersions[sender] = receivedVersion
					end

					-- Prüfe ob neuere Version verfügbar
					if SchlingelInc:CompareVersions(receivedVersion, highestSeenVersion) > 0 then
						highestSeenVersion = receivedVersion
						SchlingelInc:Print("Eine neuere Addon-Version wurde entdeckt: " ..
							highestSeenVersion .. ". Bitte aktualisiere dein Addon!")
					end
				end
			end
		end, 0, "VersionChecker")

	-- Sende Version bei Guild Chat
	local major, minor, patch, channel = SchlingelInc:ParseVersion(SchlingelInc.version)
	if IsInGuild() and channel == "stable" then
		C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "VERSION:" .. SchlingelInc.version, "GUILD")
	end
    C_GuildInfo.GuildRoster() -- Guild Roster fetchen um Cache aufzubauen.
end

-- Gibt eine formatierte Nachricht im Chat aus.
function SchlingelInc:Print(message)
    print(SchlingelInc.colorCode .. "[" .. SchlingelInc.name .. "]|r " .. message)
end

-- Überprüft, ob sich der Spieler in einem relevanten Schlachtfeld befindet.
function SchlingelInc:IsInBattleground()
    local inInstance, instanceType = IsInInstance()
    return inInstance and instanceType == SchlingelInc.Constants.INSTANCE_TYPES.PVP
end

function SchlingelInc:IsInRaid()
    local inInstance, instanceType = IsInInstance()
    return inInstance and instanceType == SchlingelInc.Constants.INSTANCE_TYPES.RAID
end

function SchlingelInc:ParseVersion(v)
    local major, minor, patch, channel = string.match(v, "(%d+)%.(%d+)%.?(%d*)%-?(%w*)")
    return tonumber(major or 0), tonumber(minor or 0), tonumber(patch or 0), tostring(channel or "stable")
end

-- Vergleicht zwei Versionsnummern (z.B. "1.2.3" mit "1.3.0").
-- Gibt >0 zurück, wenn v1 > v2; <0 wenn v1 < v2; 0 wenn v1 == v2.
function SchlingelInc:CompareVersions(v1, v2)
    -- Hilfsfunktion, um einen Versionsstring in Major, Minor, Patch Zahlen zu zerlegen.
    local a1, a2, a3, channel = SchlingelInc:ParseVersion(v1) -- Parsed v1.
    local b1, b2, b3, channel = SchlingelInc:ParseVersion(v2) -- Parsed v2.

    if a1 ~= b1 then return a1 - b1 end                       -- Vergleiche Major-Version.
    if a2 ~= b2 then return a2 - b2 end                       -- Vergleiche Minor-Version.
    return a3 - b3                                            -- Vergleiche Patch-Version.
end


-- Speichert die Addon-Versionen von Gildenmitgliedern (Sendername -> Version).
SchlingelInc.guildMemberVersions = {}

-- Fügt einen Filter für Gilden-Chat-Nachrichten hinzu.
ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", function(self, event, msg, sender, ...)
    -- Funktion wird nur ausgeführt, wenn der Spieler Gildenmitglieder einladen darf (eine Art Berechtigungsprüfung).
    if SchlingelOptionsDB["show_version"] == false then
        return false, msg, sender, ... -- Nachricht unverändert durchlassen.
    end

    local version = SchlingelInc.guildMemberVersions[sender] or nil -- Holt die gespeicherte Version des Senders.
    local modifiedMessage = msg                                     -- Standardmäßig die Originalnachricht.

    -- Wenn eine Version für den Sender bekannt ist, füge sie der Nachricht hinzu.
    if version ~= nil then
        modifiedMessage = SchlingelInc.colorCode .. "[" .. version .. "]|r " .. msg
    end
    -- 'false' bedeutet, die Nachricht wird nicht unterdrückt, sondern weiterverarbeitet (mit ggf. modifizierter Nachricht).
    return false, modifiedMessage, sender, ...
end)

-- Entfernt den Realm-Namen von einem vollständigen Spielernamen (z.B. "Spieler-Realm" -> "Spieler").
function SchlingelInc:RemoveRealmFromName(fullName)
    local dashPosition = string.find(fullName, "-")      -- Findet die Position des Bindestrichs.
    if dashPosition then
        return string.sub(fullName, 1, dashPosition - 1) -- Gibt den Teil vor dem Bindestrich zurück.
    else
        return fullName                                  -- Kein Bindestrich gefunden, gibt den vollen Namen zurück.
    end
end