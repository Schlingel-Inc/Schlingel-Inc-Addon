-- Initialisiert den Namespace für das Gildenrekrutierungsmodul
SchlingelInc.GuildRecruitment = SchlingelInc.GuildRecruitment or {}
SchlingelInc.GuildRecruitment.inviteRequests = SchlingelInc.GuildRecruitment.inviteRequests or {}

-- Gibt eine Liste aller Officers zurück, die Einladungsrechte haben
-- Basierend auf den in Constants.OFFICER_RANKS definierten Rängen
-- Funktioniert nur für Spieler, die bereits in der Gilde sind!
local function GetAuthorizedOfficers()
	-- Prüfe ob Spieler in einer Gilde ist
	if not IsInGuild() then
		SchlingelInc.Debug:Print("Spieler ist nicht in der Gilde - kann keine Officers abrufen")
		return {}
	end

	local officers = {}

	-- Durchlaufe alle autorisierten Ränge
	for _, rankName in ipairs(SchlingelInc.Constants.OFFICER_RANKS) do
		local membersWithRank = SchlingelInc.GuildCache:GetMembersByRank(rankName)

		-- Füge alle Online-Mitglieder dieses Rangs zur Officer-Liste hinzu
		for _, member in ipairs(membersWithRank) do
			if member.isOnline then
				table.insert(officers, member.name)
			end
		end
	end

	SchlingelInc.Debug:Print(string.format(
		"Gefundene online Officers mit Einladungsrechten: %d", #officers
	))

	return officers
end

function SchlingelInc.GuildRecruitment:SendGuildRequest()
    local playerName = UnitName("player")
    local playerLevel = UnitLevel("player")
    local playerExp = UnitXP("player")

    if playerLevel > 1 then
        SchlingelInc:Print("Du darfst nur mit Level 1 eine Gildenanfrage senden.")
        return
    end

    local zone = SchlingelInc.GuildRecruitment:GetPlayerZone()
    local playerGold = GetMoneyString(GetMoney(), true)

    -- Sanitize inputs by replacing delimiters with safe characters
    -- This prevents zone names with colons from breaking the message parsing
    local safeZone = zone:gsub(":", "-"):gsub("|", "-")
    local safePlayerGold = playerGold:gsub(":", "-"):gsub("|", "-")

    local message = string.format("INVITE_REQUEST:%s:%d:%d:%s:%s", playerName, playerLevel, playerExp, safeZone, safePlayerGold)

    -- Level 1 Spieler sind IMMER außerhalb der Gilde
    -- Nutze die Fallback-Officer-Liste aus Constants
    local guildOfficers = SchlingelInc.Constants.FALLBACK_OFFICERS

    if #guildOfficers == 0 then
        SchlingelInc:Print(SchlingelInc.Constants.COLORS.ERROR ..
            "Keine Officers konfiguriert. Bitte kontaktiere einen Officer direkt.|r")
        return
    end

    -- Sendet die Anfrage an alle Officers per Whisper
    local sentCount = 0
    for _, name in ipairs(guildOfficers) do
        C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, message, "WHISPER", name)
        sentCount = sentCount + 1
    end

    SchlingelInc:Print(SchlingelInc.Constants.COLORS.SUCCESS ..
        string.format("Gildenanfrage an %d Officers gesendet.", sentCount) .. "|r")
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
                SchlingelInc.Debug:Print("Ungültige Level-Angabe in Guild Request: " .. tostring(level))
                return
            end

            if not xpNum or xpNum < 0 then
                SchlingelInc.Debug:Print("Ungültige XP-Angabe in Guild Request: " .. tostring(xp))
                return
            end

            -- Ensure strings are not empty
            if name == "" or zone == "" or money == "" then
                SchlingelInc.Debug:Print("Leere Felder in Guild Request empfangen")
                return
            end

            local requestData = {
                name = name,
                level = level,
                xp = xpNum,
                zone = zone,
                money = money,
            }
            local displayMessage = string.format("Neue Gildenanfrage von %s (Level %s) mit %s in der Tasche aus %s erhalten.",
                name, level, money, zone)
            SchlingelInc:Print(displayMessage)
            SchlingelInc.GuildInvites:ShowInviteMessage(displayMessage, requestData)
        end
    elseif message:find("^INVITE_SENT:") and CanGuildInvite() then
        SchlingelInc.GuildInvites:HideInviteMessage()
    elseif message:find("^INVITE_DECLINED:") then
        local name = message:match("^INVITE_DECLINED:(.+)$")
        if name and name ~= "" then
            SchlingelInc:Print("Ein Officer hat die Anfrage von " .. name .. " abgelehnt.")
            SchlingelInc.GuildInvites:HideInviteMessage()
        end
    end
end

function SchlingelInc.GuildRecruitment:HandleAcceptRequest(playerName)
    if not playerName then return end

    if CanGuildInvite() then
        SchlingelInc:Print("Versuche, " .. playerName .. " in die Gilde einzuladen...")
        C_GuildInfo.Invite(playerName)

        -- Benachrichtige alle online Officers über die gesendete Einladung
        local guildOfficers = GetAuthorizedOfficers()
        for _, name in ipairs(guildOfficers) do
            C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "INVITE_SENT:" .. playerName, "WHISPER", name)
        end
    else
        SchlingelInc:Print("Du hast keine Berechtigung, Spieler in die Gilde einzuladen.")
    end
end

function SchlingelInc.GuildRecruitment:HandleDeclineRequest(playerName)
    if not playerName then return end

    -- Benachrichtige alle online Officers über die abgelehnte Anfrage
    local guildOfficers = GetAuthorizedOfficers()
    for _, name in ipairs(guildOfficers) do
        C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "INVITE_DECLINED:" .. playerName, "WHISPER", name)
    end

    SchlingelInc:Print("Anfrage von " .. playerName .. " wurde abgelehnt.")
end

-- Initialisiert das GuildRecruitment Modul
function SchlingelInc.GuildRecruitment:Initialize()
	SchlingelInc.EventManager:RegisterHandler("CHAT_MSG_ADDON",
		function(_, prefix, message)
			if prefix == SchlingelInc.prefix then
				if message:find("INVITE_REQUEST") or message:find("INVITE_SENT") then
					HandleAddonMessage(message)
				end
			end
		end, 0, "GuildInviteHandler")
end

-- Gibt formatierten Zonennamen zurück
function SchlingelInc.GuildRecruitment:GetPlayerZone()
    if C_Map and C_Map.GetBestMapForUnit then
        local mapID = C_Map.GetBestMapForUnit("player")
        return mapID and C_Map.GetMapInfo(mapID) and C_Map.GetMapInfo(mapID).name or GetZoneText() or "Unbekannt"
    end
    return GetZoneText() or "Unbekannt"
end
