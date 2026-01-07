-- Global table for the addon
SchlingelInc = {}

-- Addon name
SchlingelInc.name = "SchlingelInc"

-- Chat message prefix
-- This prefix is used to identify addon-internal messages.
SchlingelInc.prefix = "SchlingelInc"

-- Color code for chat text
-- Determines the color in which addon messages are displayed in chat.
SchlingelInc.colorCode = "|cFFF48CBA"

-- Version from TOC file
-- Loads the addon version from the .toc file. If not available, "Unknown" is used.
SchlingelInc.version = GetAddOnMetadata("SchlingelInc", "Version") or "Unknown"

-- Playtime variables are updated in Main.lua via TIME_PLAYED_MSG event
-- and displayed in SchlingelInterface.lua.
SchlingelInc.GameTimeTotal = 0
SchlingelInc.GameTimePerLevel = 0

function SchlingelInc:CountTable(table)
    local count = 0
    for _ in pairs(table) do
        count = count + 1
    end
    return count
end

-- Stores the timestamp of the last PvP warning for each player.
SchlingelInc.lastPvPAlert = {}

-- Global module initialization
SchlingelInc.Global = {}

function SchlingelInc.Global:Initialize()
	-- Register addon message prefix
	C_ChatInfo.RegisterAddonMessagePrefix(SchlingelInc.prefix)

	-- PLAYER_TARGET_CHANGED for PvP warnings
	SchlingelInc.EventManager:RegisterHandler("PLAYER_TARGET_CHANGED",
		function()
			if SchlingelOptionsDB["pvp_alert"] == false then
				return
			end
			if not SchlingelInc:IsInBattleground() then
				SchlingelInc:CheckTargetPvP()
			end
		end, 0, "PvPTargetChecker")

	-- Version checking handler
	local newestVersionSeen = SchlingelInc.version
	SchlingelInc.EventManager:RegisterHandler("CHAT_MSG_ADDON",
		function(_, prefix, message, _, sender)
			if prefix == SchlingelInc.prefix then
				local incomingVersion = message:match("^VERSION:(.+)$")
				if incomingVersion then
					-- Store version of guild member
					if sender then
						SchlingelInc.guildMemberVersions[sender] = incomingVersion
					end

					-- Check if incoming version is newer than the currently known newest version
					if SchlingelInc:CompareVersions(incomingVersion, newestVersionSeen) > 0 then
						newestVersionSeen = incomingVersion
						SchlingelInc:Print("A newer addon version was detected: " ..
							newestVersionSeen .. ". Please update your addon!")
					end
				end
			end
		end, 0, "VersionChecker")

	-- Send version to guild chat
	if IsInGuild() then
		C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "VERSION:" .. SchlingelInc.version, "GUILD")
	end
    C_GuildInfo.GuildRoster() -- Fetch guild roster to build cache.
end

-- Outputs a formatted message in chat.
function SchlingelInc:Print(message)
    print(SchlingelInc.colorCode .. "[" .. SchlingelInc.name .. "]|r " .. message)
end

-- Checks if the player is in a battleground.
function SchlingelInc:IsInBattleground()
    local inInstance, instanceType = IsInInstance()
    return inInstance and instanceType == SchlingelInc.Constants.INSTANCE_TYPES.PVP
end

function SchlingelInc:IsInRaid()
    local inInstance, instanceType = IsInInstance()
    return inInstance and instanceType == SchlingelInc.Constants.INSTANCE_TYPES.RAID
end

function SchlingelInc:ParseVersion(v)
    local major, minor, patch = string.match(v, "(%d+)%.(%d+)%.?(%d*)")
    return tonumber(major or 0), tonumber(minor or 0), tonumber(patch or 0)
end

-- Compares two version numbers (e.g. "1.2.3" with "1.3.0").
-- Returns >0 if version1 > version2; <0 if version1 < version2; 0 if equal.
function SchlingelInc:CompareVersions(version1, version2)
    local major1, minor1, patch1 = SchlingelInc:ParseVersion(version1)
    local major2, minor2, patch2 = SchlingelInc:ParseVersion(version2)

    if major1 ~= major2 then return major1 - major2 end -- Compare major version.
    if minor1 ~= minor2 then return minor1 - minor2 end -- Compare minor version.
    return patch1 - patch2                              -- Compare patch version.
end


-- Stores addon versions of guild members (sender name -> version).
SchlingelInc.guildMemberVersions = {}

-- Chat filter function (defined once, reused if already registered)
local function GuildChatVersionFilter(_, _, msg, sender, ...)
    -- Function only executes if show_version option is enabled.
    if SchlingelOptionsDB["show_version"] == false then
        return false, msg, sender, ... -- Pass message through unchanged.
    end

    local version = SchlingelInc.guildMemberVersions[sender] -- Get stored version of sender.
    local modifiedMessage = msg                              -- Default to original message.

    -- If a version is known for the sender, add it to the message.
    if version then
        modifiedMessage = SchlingelInc.colorCode .. "[" .. version .. "]|r " .. msg
    end
    -- 'false' means the message is not suppressed but passed through (possibly modified).
    return false, modifiedMessage, sender, ...
end

-- Add filter for guild chat messages (only once).
if not SchlingelInc.guildChatFilterRegistered then
    ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", GuildChatVersionFilter)
    SchlingelInc.guildChatFilterRegistered = true
end

-- Removes the realm name from a full player name (e.g. "Player-Realm" -> "Player").
-- Uses the Blizzard API function Ambiguate.
function SchlingelInc:RemoveRealmFromName(fullName)
    return Ambiguate(fullName, "short")
end

-- Sanitizes text to prevent UI injection via escape codes
-- Removes texture, color, and hyperlink escape sequences
function SchlingelInc:SanitizeText(text)
    if not text or type(text) ~= "string" then
        return text
    end
    -- Remove texture escape sequences |Tpath:height:width:...|t
    text = text:gsub("|T[^|]*|t", "")
    -- Remove color escape sequences |cFFFFFFFF...|r
    text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
    text = text:gsub("|r", "")
    -- Remove hyperlink escape sequences |Htype:data|h...|h
    text = text:gsub("|H[^|]*|h", "")
    text = text:gsub("|h", "")
    return text
end

-- Validates that an addon message sender is a guild member
-- Uses GuildCache for fast lookup to prevent spoofed messages
function SchlingelInc:IsValidGuildSender(sender)
    if not sender then return false end
    local shortName = self:RemoveRealmFromName(sender)
    return SchlingelInc.GuildCache:IsGuildMember(shortName)
end
