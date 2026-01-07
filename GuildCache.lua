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

-- Fordert ein Roster-Update vom Server an
-- Die Daten werden automatisch über den GUILD_ROSTER_UPDATE Handler verarbeitet
function SchlingelInc.GuildCache:RequestUpdate()
	if self.isUpdating then
		return false
	end

	self.isUpdating = true
	C_GuildInfo.GuildRoster()
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

			-- Berechne Last Online Daten
			local yearsOffline, monthsOffline, daysOffline, hoursOffline = GetGuildRosterLastOnline(i)
			yearsOffline = yearsOffline or 0
			monthsOffline = monthsOffline or 0
			daysOffline = daysOffline or 0
			hoursOffline = hoursOffline or 0

			local totalDaysOffline = (yearsOffline * 365) + (monthsOffline * 30) + daysOffline + (hoursOffline / 24)

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
				status = status,
				yearsOffline = yearsOffline,
				monthsOffline = monthsOffline,
				daysOffline = daysOffline,
				hoursOffline = hoursOffline,
				totalDaysOffline = totalDaysOffline
			})
		end
	end

	self.lastUpdate = GetTime()
	self.isUpdating = false
end

-- Gibt die vollständige Roster-Liste zurück (als Array mit allen Details)
-- @return table Array mit vollständigen Mitgliederdaten
function SchlingelInc.GuildCache:GetFullRoster()
	return self.fullRoster
end

-- Prüft schnell, ob ein Spieler in der Gilde ist
-- @param playerName string Der Name des Spielers (mit oder ohne Realm)
-- @return boolean true wenn Spieler in der Gilde ist
function SchlingelInc.GuildCache:IsGuildMember(playerName)
	if not playerName then return false end

	-- Entferne Realm-Namen falls vorhanden
	local shortName = SchlingelInc:RemoveRealmFromName(playerName)

	-- Prüfe direkt im Cache
	return self.members[shortName] == true
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
	return self:RequestUpdate()
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
	-- Update bei Guild Roster Updates (wird automatisch beim Login gefeuert)
	-- Verarbeitet Roster-Daten immer wenn das Event feuert - hält Cache immer aktuell
	SchlingelInc.EventManager:RegisterHandler("GUILD_ROSTER_UPDATE",
		function()
			SchlingelInc.GuildCache:ProcessRosterData()
		end, 0, "GuildCacheAutoUpdate")

	-- Initial update beim Login
	SchlingelInc.EventManager:RegisterHandler("PLAYER_ENTERING_WORLD",
		function()
			-- Warte kurz nach dem Login, dann fordere Roster an
			C_Timer.After(2, function()
				SchlingelInc.GuildCache:RequestUpdate()
			end)
		end, 90, "GuildCacheInit")
end
