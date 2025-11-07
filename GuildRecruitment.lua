-- Initialisiert den Namespace für das Gildenrekrutierungsmodul
SchlingelInc.GuildRecruitment = SchlingelInc.GuildRecruitment or {}
SchlingelInc.GuildRecruitment.inviteRequests = SchlingelInc.GuildRecruitment.inviteRequests or {}

local guildOfficers =
{
    -- Gildenleitung/Mods
    -- Kurti
    "Kurtibrown",
    "Schmurt",
    "Schmurti",
    -- Dörte
    "Dörtchen",
    "Siegdörty",
    -- Fihlo
    "Syluri",
    "Syltank",
    -- Hauke
    "Totanka",
    -- Hauke Bankaccount
    "Schlingbank",
    "Schlinglbank",
    -- Dev-Schlingel
    "Luminette",
    "Cricksumage",
    "Devschlingel",
    "Pudidev",
    -- alte Offiziere
    "Fenriic",
    "Totärztin",
    -- neue Offiziere
    "Coldchase",
    "Coltchase",
    "Raixxen",
    "Peirithoos",
    -- Ab hier kommen PfundsSchlingel
    "Akimah",
    "Automatix",
    "Bartzmorak",
    "Cowihendrixs",
    "Eowendra",
    "Ganadorian",
    "Hufgeruch",
    "Kalterwalter",
    "Kipptum",
    "Knubbsi",
    "Kritze",
    "Lucifia",
    "Lünda",
    "Meltfacê",
    "Naikjin",
    "Pfarrer",
    "Pfeilgiftfro",
    "Treeguard",
    "Tuskdoc",
    "Tötemir",
    "Vindicætor",
    "Wujujade",
    "Ûshnotz"
}

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
    local message = string.format("INVITE_REQUEST:%s:%d:%d:%s:%s", playerName, playerLevel, playerExp, zone, playerGold)

    -- --Debug Aufruf zum testen. debugTarget mit dem gewünschten Character initialisieren, der die Nachricht erhalten soll
    -- local debugTarget = "Pudidev"
    -- C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, message, "WHISPER", debugTarget)

    -- Sendet die Anfrage an alle Officer.
    for _, name in ipairs(guildOfficers) do
        C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, message, "WHISPER", name)
    end
end

local function HandleAddonMessage(message)
    if message:find("^INVITE_REQUEST:") then
        local name, level, xp, zone, money = message:match("^INVITE_REQUEST:([^:]+):(%d+):(%d+):([^:]+):(.+)$")
        if name and level and xp and zone and money then
            local requestData = {
                name = name,
                level = level,
                xp = tonumber(xp),
                zone = zone,
                money = money,
            }
            local message = string.format("Neue Gildenanfrage von %s (Level %s) mit %s in der Tasche aus %s erhalten.",
                name, level, money, zone)
            SchlingelInc:Print(message)
            SchlingelInc.GuildInvites:ShowInviteMessage(message, requestData)
        end
    elseif message:find("^INVITE_SENT:") and CanGuildInvite() then
        SchlingelInc.GuildInvites:HideInviteMessage()
    elseif message:find("^INVITE_DECLINED:") then
        local name = message:match("^INVITE_DECLINED:(.+)$")
        SchlingelInc:Print("Ein Officer hat die Anfrage von " .. name .. " abgelehnt.")
        SchlingelInc.GuildInvites:HideInviteMessage()
    end
end

function SchlingelInc.GuildRecruitment:HandleAcceptRequest(playerName)
    if not playerName then return end

    if CanGuildInvite() then
        SchlingelInc:Print("Versuche, " .. playerName .. " in die Gilde einzuladen...")
        C_GuildInfo.Invite(playerName)
        for _, name in ipairs(guildOfficers) do
            C_ChatInfo.SendAddonMessage(SchlingelInc.prefix, "INVITE_SENT:" .. playerName, "WHISPER", name)
        end
    else
        SchlingelInc:Print("Du hast keine Berechtigung, Spieler in die Gilde einzuladen.")
    end
end

function SchlingelInc.GuildRecruitment:HandleDeclineRequest(playerName)
    if not playerName then return end
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
