-- GuildCache.lua
-- Caching-System für Guild Roster Daten zur Performance-Optimierung
-- Reduziert API-Calls durch intelligentes Caching mit 60 Sekunden Lifetime

SchlingelInc.GuildCache = {
	members = {},           -- Cached guild member list (name -> true)
	fullRoster = {},        -- Full roster data with details
	lastUpdate = 0,         -- Timestamp of last cache update
	isUpdating = false      -- Flag to prevent concurrent updates
}

-- Prüft, ob der Cache noch gültig ist
function SchlingelInc.GuildCache:IsValid()
	local now = GetTime()
	local age = now - self.lastUpdate
	return age < SchlingelInc.Constants.COOLDOWNS.GUILD_ROSTER_CACHE
end

-- Aktualisiert den Guild Roster Cache
function SchlingelInc.GuildCache:Update(force)
	-- Prüfe ob Update nötig ist
	if not force and self:IsValid() then
		SchlingelInc.Debug:Print("Guild Cache ist noch gültig, überspringe Update")
		return false
	end

	-- Verhindere parallele Updates
	if self.isUpdating then
		SchlingelInc.Debug:Print("Guild Cache Update läuft bereits")
		return false
	end

	self.isUpdating = true

	-- Fordere Roster-Daten vom Server an
	C_GuildInfo.GuildRoster()

	-- Warte auf Daten und verarbeite sie
	C_Timer.After(0.5, function()
		self:ProcessRosterData()
		self.isUpdating = false
	end)

	SchlingelInc.Debug:Print("Guild Cache Update gestartet")
	return true
end

-- Verarbeitet die Roster-Daten und füllt den Cache
function SchlingelInc.GuildCache:ProcessRosterData()
	-- Leere alte Daten
	wipe(self.members)
	wipe(self.fullRoster)

	local numTotalMembers = GetNumGuildMembers()

	for i = 1, numTotalMembers do
		local name, rankName, rankIndex, level, classDisplayName, zone,
			  publicNote, officerNote, isOnline, status, class = GetGuildRosterInfo(i)

		if name then
			-- Entferne Realm-Namen für einfacheren Vergleich
			local shortName = SchlingelInc:RemoveRealmFromName(name)

			-- Speichere in schneller Lookup-Tabelle
			self.members[shortName] = true

			-- Speichere vollständige Daten
			table.insert(self.fullRoster, {
				name = shortName,
				fullName = name,
				rank = rankName,
				rankIndex = rankIndex,
				level = level,
				class = class,
				classDisplayName = classDisplayName,
				zone = zone,
				publicNote = publicNote,
				officerNote = officerNote,
				isOnline = isOnline,
				status = status
			})
		end
	end

	self.lastUpdate = GetTime()

	SchlingelInc.Debug:Print(string.format(
		"Guild Cache aktualisiert: %d Mitglieder geladen",
		#self.fullRoster
	))
end

-- Gibt die gecachte Mitgliederliste zurück (als Dictionary für schnellen Lookup)
-- @return table Dictionary mit Spielernamen als Keys (ohne Realm)
function SchlingelInc.GuildCache:GetMembers()
	if not self:IsValid() then
		self:Update()
	end
	return self.members
end

-- Gibt die vollständige Roster-Liste zurück (als Array mit allen Details)
-- @return table Array mit vollständigen Mitgliederdaten
function SchlingelInc.GuildCache:GetFullRoster()
	if not self:IsValid() then
		self:Update()
	end
	return self.fullRoster
end

-- Prüft schnell, ob ein Spieler in der Gilde ist
-- @param playerName string Der Name des Spielers (mit oder ohne Realm)
-- @return boolean true wenn Spieler in der Gilde ist
function SchlingelInc.GuildCache:IsGuildMember(playerName)
	if not playerName then return false end

	-- Entferne Realm-Namen falls vorhanden
	local shortName = SchlingelInc:RemoveRealmFromName(playerName)

	-- Hole gecachte Daten
	local members = self:GetMembers()

	return members[shortName] == true
end

-- Gibt detaillierte Informationen über ein Gildenmitglied zurück
-- @param playerName string Der Name des Spielers
-- @return table|nil Mitgliederdaten oder nil wenn nicht gefunden
function SchlingelInc.GuildCache:GetMemberInfo(playerName)
	if not playerName then return nil end

	local shortName = SchlingelInc:RemoveRealmFromName(playerName)
	local roster = self:GetFullRoster()

	for _, member in ipairs(roster) do
		if member.name == shortName then
			return member
		end
	end

	return nil
end

-- Gibt alle Mitglieder mit einem bestimmten Rang zurück
-- @param rankName string Der Name des Rangs (z.B. "Devschlingel")
-- @return table Array mit Mitgliedern dieses Rangs
function SchlingelInc.GuildCache:GetMembersByRank(rankName)
	local roster = self:GetFullRoster()
	local result = {}

	for _, member in ipairs(roster) do
		if member.rank == rankName then
			table.insert(result, member)
		end
	end

	return result
end

-- Gibt alle online Mitglieder zurück
-- @return table Array mit online Mitgliedern
function SchlingelInc.GuildCache:GetOnlineMembers()
	local roster = self:GetFullRoster()
	local result = {}

	for _, member in ipairs(roster) do
		if member.isOnline then
			table.insert(result, member)
		end
	end

	return result
end

-- Erzwingt eine Aktualisierung des Caches
function SchlingelInc.GuildCache:ForceRefresh()
	SchlingelInc.Debug:Print("Erzwinge Guild Cache Refresh")
	return self:Update(true)
end

-- Gibt Cache-Statistiken zurück
-- @return table Statistiken über den Cache
function SchlingelInc.GuildCache:GetStats()
	local now = GetTime()
	local age = now - self.lastUpdate
	local isValid = self:IsValid()

	return {
		memberCount = #self.fullRoster,
		lastUpdate = self.lastUpdate,
		age = age,
		isValid = isValid,
		expiresIn = math.max(0, SchlingelInc.Constants.COOLDOWNS.GUILD_ROSTER_CACHE - age)
	}
end

-- Initialisiert das GuildCache Modul
function SchlingelInc.GuildCache:Initialize()
	-- Initial update beim Login
	SchlingelInc.EventManager:RegisterHandler("PLAYER_ENTERING_WORLD",
		function()
			-- Warte kurz nach dem Login, dann lade Roster
			C_Timer.After(2, function()
				SchlingelInc.GuildCache:Update()
			end)
		end, 90, "GuildCacheInit")

	-- Update bei Guild Roster Updates
	SchlingelInc.EventManager:RegisterHandler("GUILD_ROSTER_UPDATE",
		function()
			-- Markiere Cache als ungültig, wird beim nächsten Zugriff aktualisiert
			if SchlingelInc.GuildCache:IsValid() then
				SchlingelInc.Debug:Print("GUILD_ROSTER_UPDATE empfangen, markiere Cache als ungültig")
				SchlingelInc.GuildCache.lastUpdate = 0
			end
		end, 0, "GuildCacheInvalidate")

	SchlingelInc.Debug:Print("GuildCache Modul initialisiert")
end
