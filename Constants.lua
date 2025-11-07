-- Constants.lua
-- Zentrale Konstanten für das SchlingelInc Addon

SchlingelInc.Constants = {}

-- Maximales Level (TBC = 70)
SchlingelInc.Constants.MAX_LEVEL = 70

-- Level Meilensteine für Ankündigungen
SchlingelInc.Constants.LEVEL_MILESTONES = {10, 20, 30, 40, 50, 60, 70}

-- Geschlecht Konstanten
SchlingelInc.Constants.GENDER = {
	MALE = 2,
	FEMALE = 3
}

-- Instanz-Typen
SchlingelInc.Constants.INSTANCE_TYPES = {
	PVP = "pvp",
	RAID = "raid",
	DUNGEON = "party"
}

-- Sound IDs
SchlingelInc.Constants.SOUNDS = {
	PVP_ALERT = 8174,  -- Horde Flag Sound
	DEATH_ANNOUNCEMENT = 8959
}

-- Farben für Nachrichten
SchlingelInc.Constants.COLORS = {
	ADDON_PREFIX = "|cFFF48CBA",
	ERROR = "|cffff0000",
	SUCCESS = "|cff00ff00",
	WARNING = "|cffffaa00",
	INFO = "|cff88ccff"
}

-- Cooldowns (in Sekunden)
SchlingelInc.Constants.COOLDOWNS = {
	PVP_ALERT = 10,
	INVITE_REQUEST = 300,  -- 5 Minuten
	GUILD_ROSTER_CACHE = 60  -- 1 Minute
}

-- Combat Log Events für Schadenserkennung
SchlingelInc.Constants.DAMAGE_EVENTS = {
	"SWING_DAMAGE",
	"RANGE_DAMAGE",
	"SPELL_DAMAGE",
	"SPELL_PERIODIC_DAMAGE"
}

-- Pronomen für Geschlechter
SchlingelInc.Constants.PRONOUNS = {
	[2] = "der",  -- Male
	[3] = "die"   -- Female
}

-- Gildenränge mit Einladungsrechten (für Guild Recruitment)
-- Diese Ränge erhalten Guild Invite Requests per Addon Message
SchlingelInc.Constants.OFFICER_RANKS = {
	"Devschlingel",      -- Developer
	"Pfundschlingel",    -- Officers
	"Großschlingel",     -- Officers
	-- Füge hier weitere Ränge hinzu, die Einladungsrechte haben sollen
}

-- Fallback Officer Character Names für Spieler außerhalb der Gilde
-- Wird verwendet, wenn der Spieler noch nicht in der Gilde ist (Level 1 Requests)
-- Diese Liste sollte die Haupt-Charaktere der aktiven Officers enthalten
SchlingelInc.Constants.FALLBACK_OFFICERS = {
	-- Dev-Schlingel
	"Pudidev",
	"Cricksumage",
	"Devschlingel",
	-- Gildenleitung
	"Kurtibrown",
	"Dörtchen",
	"Totanka",
	-- Füge hier die Main-Characters der aktiven Officers hinzu
}