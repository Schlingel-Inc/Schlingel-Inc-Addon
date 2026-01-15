-- Constants.lua
-- Central constants for the SchlingelInc addon

SchlingelInc.Constants = {}

-- Maximum level (TBC Classic = 70)
SchlingelInc.Constants.MAX_LEVEL = 70

-- Level milestones for announcements
SchlingelInc.Constants.LEVEL_MILESTONES = {10, 20, 30, 40, 50, 60, 70}

-- Instance types
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

-- Colors for messages
SchlingelInc.Constants.COLORS = {
	ADDON_PREFIX = "|cFFF48CBA",
	ERROR = "|cffff0000",
	SUCCESS = "|cff00ff00",
	WARNING = "|cffffaa00",
	INFO = "|cff88ccff"
}

-- Cooldowns (in seconds)
SchlingelInc.Constants.COOLDOWNS = {
	PVP_ALERT = 10,
	INVITE_REQUEST = 300,  -- 5 minutes
	GUILD_ROSTER_CACHE = 60  -- 1 minute
}

-- Pronouns for genders (German articles)
SchlingelInc.Constants.PRONOUNS = {
	[2] = "der",  -- Male
	[3] = "die"   -- Female
}

-- Guild ranks with invite permissions (for Guild Recruitment)
-- These ranks receive guild invite requests via addon message
SchlingelInc.Constants.OFFICER_RANKS = {
	"Devschlingel",      -- Developer
	"Pfundschlingel",    -- Officers
	"Großschlingel",     -- Officers
}

-- Fallback officer character names for players outside the guild
-- Used when the player is not yet in the guild (Level 1 requests)
-- This list should contain the main characters of active officers
SchlingelInc.Constants.FALLBACK_OFFICERS = {
	-- Officers
	"Ôny",
	"Asperra",
	"Aevela",
	"Bartzmorea",
	"HvvTrønix",
	"Moosbartfro",
	"Behaart",
	"Jeriky",
	"Merandii",
	"Korvo",
	"Ashajt",
	"Raixxen",
	"Markô",
	"Markoxak",
	"Cricksudin",
	"Pryâ",
	"HvvTronlx",
	"HwTrønix",
	-- Dev-Schlingel
	"Pudidev",
	"Cricksumage",
	"Devschlingel",
	-- Guild leadership
	"Syluri",
	"Kurtibrown",
	"Dörtchen",
	"Totanka",
}

-- UI Backdrop Settings
SchlingelInc.Constants.BACKDROP = {
	bgFile = "Interface\\BUTTONS\\WHITE8X8",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	tile = true,
	tileSize = 32,
	edgeSize = 32,
	insets = { left = 11, right = 12, top = 12, bottom = 11 }
}

-- Popup Backdrop Settings
SchlingelInc.Constants.POPUPBACKDROP = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 }
}

-- Inactivity threshold (days)
SchlingelInc.Constants.INACTIVE_DAYS_THRESHOLD = 10
