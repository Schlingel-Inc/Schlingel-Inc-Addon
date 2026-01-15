-- Initialize the namespace for the guild recruitment module
SchlingelInc.GuildRecruitment = SchlingelInc.GuildRecruitment or {}
SchlingelInc.GuildRecruitment.inviteRequests = SchlingelInc.GuildRecruitment.inviteRequests or {}

-- Returns a list of all officers who have invite permissions
-- Based on ranks defined in Constants.OFFICER_RANKS
-- Only works for players who are already in the guild!
local function GetAuthorizedOfficers()
	-- Check if player is in a guild
	if not IsInGuild() then
		SchlingelInc.Debug:Print("Player is not in a guild - cannot retrieve officers")
		return {}
	end

	local officers = {}

	-- Loop through all authorized ranks
	for _, rankName in ipairs(SchlingelInc.Constants.OFFICER_RANKS) do
		local membersWithRank = SchlingelInc.GuildCache:GetMembersByRank(rankName)

		-- Add all online members of this rank to the officer list
		for _, member in ipairs(membersWithRank) do
			if member.isOnline then
				table.insert(officers, member.name)
			end
		end
	end

	SchlingelInc.Debug:Print(string.format(
		"Found online officers with invite permissions: %d", #officers
	))

	return officers
end

function SchlingelInc.GuildRecruitment:SendGuildRequest()
    local playerName = UnitName("player")
    local playerLevel = UnitLevel("player")
    local playerExp = UnitXP("player")

    if playerLevel > 1 then
        SchlingelInc:Print("Du kannst nur auf Level 1 eine Anfrage an die Gilde abschicken.")
        return
    end

    local zone = SchlingelInc.GuildRecruitment:GetPlayerZone()
    local playerGold = GetMoney()

    -- Sanitize inputs by replacing delimiters with safe characters
    -- This prevents zone names with colons from breaking the message parsing
    local safeZone = zone:gsub(":", "-"):gsub("|", "-")
    local safePlayerGold = playerGold:gsub(":", "-"):gsub("|", "-")

    local message = string.format("INVITE_REQUEST:%s:%d:%d:%s:%s", playerName, playerLevel, playerExp, safeZone, safePlayerGold)

    -- Level 1 players are ALWAYS outside the guild
    -- Use the fallback officer list from Constants
    local guildOfficers = SchlingelInc.Constants.FALLBACK_OFFICERS

    if #guildOfficers == 0 then
        return
    end

    -- Send the request to all officers via whisper
    local sentCount = 0
    for _, name in ipairs(guildOfficers) do
        C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, message, "WHISPER", name)
        sentCount = sentCount + 1
    end
end

-- Send the invite request to selected online guild members so they can
-- forward the request to guild chat (used by /schwho relay flow).
-- Uses the built-in /who to discover players of the target guild and whisper
-- them an addon relay message so they post the invite into guild chat.
function SchlingelInc.GuildRecruitment:SendGuildRequestViaGuildMembers(filter)
    local playerName = UnitName("player")
    local playerLevel = UnitLevel("player")
    local playerExp = UnitXP("player")

    if playerLevel > 1 then
        SchlingelInc:Print("Du kannst nur auf Level 1 eine Anfrage an die Gilde abschicken.")
        return
    end

    local zone = SchlingelInc.GuildRecruitment:GetPlayerZone()
    local playerGold = GetMoney()

    local safeZone = zone:gsub(":", "-"):gsub("|", "-")
    local safePlayerGold = tostring(playerGold):gsub(":", "-"):gsub("|", "-")

    local message = string.format("INVITE_REQUEST_RELAY:%s:%d:%d:%s:%s", playerName, playerLevel, playerExp, safeZone, safePlayerGold)

    -- Build who query using configured target guild name
    local targetGuild = SchlingelInc.Constants.TARGET_GUILD or "SchlingelInc"
    local whoQuery = "g-" .. targetGuild
    if filter and filter ~= "" then
        whoQuery = whoQuery .. " " .. filter
    end

    -- Store pending relay so WHO_LIST_UPDATE handler can send messages
    SchlingelInc.GuildRecruitment._pendingWhoRelay = SchlingelInc.GuildRecruitment._pendingWhoRelay or {}
    SchlingelInc.GuildRecruitment._pendingWhoRelay.message = message
    SchlingelInc.GuildRecruitment._pendingWhoRelay.sent = 0

    SendWho(whoQuery)
    SchlingelInc:Print("/who Anfrage gesendet, warte auf Ergebnisse...")
end

local function HandleAddonMessage(message)
    if message:find("^INVITE_REQUEST:") then
        local name, level, xp, zone, money = message:match("^INVITE_REQUEST:([^:]+):(%d+):(%d+):([^:]+):(.+)$")
        if name and level and xp and zone and money then
            -- Validate data before using
            local levelNum = tonumber(level)
            local xpNum = tonumber(xp)

            -- Ensure values are reasonable
            if not levelNum or levelNum < 1 or levelNum > 60 then
                SchlingelInc.Debug:Print("Invalid level in guild request: " .. tostring(level))
                return
            end

            if not xpNum or xpNum < 0 then
                SchlingelInc.Debug:Print("Invalid XP in guild request: " .. tostring(xp))
                return
            end

            -- Ensure strings are not empty
            if name == "" or zone == "" or money == "" then
                SchlingelInc.Debug:Print("Empty fields received in guild request")
                return
            end

            local requestData = {
                name = name,
                level = level,
                xp = xpNum,
                zone = zone,
            }
            local displayMessage = string.format("Neue Anfrage von %s (Level %s) aus %s erhalten.",
                name, level, zone)
            SchlingelInc:Print(displayMessage)
            SchlingelInc.GuildInvites:ShowInviteMessage(displayMessage, requestData)
        end
    elseif message:find("^INVITE_SENT:") and CanGuildInvite() then
        SchlingelInc.GuildInvites:HideInviteMessage()
    elseif message:find("^INVITE_REQUEST_RELAY:") then
        -- Received a relay request from another player: post to guild chat
        if not IsInGuild() then return end
        local name, level, xp, zone, money = message:match("^INVITE_REQUEST_RELAY:([^:]+):(%d+):(%d+):([^:]+):(.+)$")
        if name and level and zone then
            local displayMessage = string.format("[Relay] Anfrage von %s (Level %s) aus %s.", name, level, zone)
            -- Post to guild chat so officers present see it
            C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, displayMessage, "GUILD")
        end
    elseif message:find("^INVITE_DECLINED:") then
        local name = message:match("^INVITE_DECLINED:(.+)$")
        if name and name ~= "" then
            SchlingelInc:Print("Ein Offi hat die Anfrage von " .. name .. " abgelehnt.")
            SchlingelInc.GuildInvites:HideInviteMessage()
        end
    end
end

function SchlingelInc.GuildRecruitment:HandleAcceptRequest(playerName)
    if not playerName then return end

    if CanGuildInvite() then
        SchlingelInc:Print("Versuche " .. playerName .. " in die Gilde einzuladen...")
        C_GuildInfo.Invite(playerName)

        -- Notify all online officers about the sent invitation
        local guildOfficers = GetAuthorizedOfficers()
        for _, name in ipairs(guildOfficers) do
            C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "INVITE_SENT:" .. playerName, "WHISPER", name)
        end
    end
end

function SchlingelInc.GuildRecruitment:HandleDeclineRequest(playerName)
    if not playerName then return end

    -- Notify all online officers about the declined request
    local guildOfficers = GetAuthorizedOfficers()
    for _, name in ipairs(guildOfficers) do
        C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "INVITE_DECLINED:" .. playerName, "WHISPER", name)
    end

    SchlingelInc:Print("Anfrage von " .. playerName .. " wurde abgelehnt.")
end

-- Initializes the GuildRecruitment module
function SchlingelInc.GuildRecruitment:Initialize()
	SchlingelInc.EventManager:RegisterHandler("CHAT_MSG_ADDON",
		function(_, prefix, message)
			if prefix == SchlingelInc.prefix then
                if message:find("INVITE_REQUEST") or message:find("INVITE_REQUEST_RELAY") or message:find("INVITE_SENT") or message:find("INVITE_DECLINED") then
                    HandleAddonMessage(message)
                end
			end
		end, 0, "GuildInviteHandler")

    -- Slash command to search online guild members and send relay requests
    SLASH_SCHWHO1 = "/schwho"
    SlashCmdList["SCHWHO"] = function(msg)
        local filter = msg and msg:match("^%s*(.-)%s*$") or ""
        SchlingelInc.GuildRecruitment:SendGuildRequestViaGuildMembers(filter)
    end

    -- Handle WHO results for relay messages
    SchlingelInc.EventManager:RegisterHandler("WHO_LIST_UPDATE",
        function()
            local pending = SchlingelInc.GuildRecruitment._pendingWhoRelay
            if not pending or not pending.message then return end
            local num = GetNumWhoResults and GetNumWhoResults() or 0
            local sent = 0
            local maxToSend = 25
            for i = 1, num do
                local whoName, whoGuild = GetWhoInfo(i)
                if whoName and whoName ~= UnitName("player") then
                    -- Optional: verify guild matches target (some clients may return different results)
                    local targetGuild = SchlingelInc.Constants.TARGET_GUILD or "SchlingelInc"
                    if not whoGuild or whoGuild == targetGuild or string.find(string.lower(whoGuild or ""), string.lower(targetGuild), 1, true) then
                        C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, pending.message, "WHISPER", whoName)
                        sent = sent + 1
                    end
                end
                if sent >= maxToSend then break end
            end
            SchlingelInc.GuildRecruitment._pendingWhoRelay = nil
            SchlingelInc:Print(string.format("Relay-Anfragen an %d Spieler gesendet.", sent))
        end, 0, "GuildRecruitWhoHandler")
end

-- Returns formatted zone name
function SchlingelInc.GuildRecruitment:GetPlayerZone()
    if C_Map and C_Map.GetBestMapForUnit then
        local mapID = C_Map.GetBestMapForUnit("player")
        return mapID and C_Map.GetMapInfo(mapID) and C_Map.GetMapInfo(mapID).name or GetZoneText() or "Unknown"
    end
    return GetZoneText() or "Unknown"
end
