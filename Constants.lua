-- Constants.lua
-- Zentrale Konstanten für das SchlingelInc Addon

SchlingelInc.Constants = {}

-- Maximales Level (Classic Era = 60)
SchlingelInc.Constants.MAX_LEVEL = 60

-- Level Meilensteine für Ankündigungen
SchlingelInc.Constants.LEVEL_MILESTONES = {10, 20, 30, 40, 50, 60}

-- Instanz-Typen
SchlingelInc.Constants.INSTANCE_TYPES = {
	PVP = "pvp",
	RAID = "raid",
	DUNGEON = "party"
}

-- Sound IDs
SchlingelInc.Constants.SOUNDS = {
	PVP_ALERT = 8174,  -- Horde Flag Sound
	DEATH_ANNOUNCEMENT = 8192
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
}

-- UI Backdrop Settings
SchlingelInc.Constants.BACKDROP = {
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	tile = true,
	tileSize = 32,
	edgeSize = 32,
	insets = { left = 11, right = 12, top = 12, bottom = 11 }
}

--Pop Up Backdrop Settings
SchlingelInc.Constants.POPUPBACKDROP = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 }
}

-- Inaktivitätsschwelle (Tage)
SchlingelInc.Constants.INACTIVE_DAYS_THRESHOLD = 10