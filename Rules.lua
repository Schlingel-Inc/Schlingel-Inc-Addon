-- Globale Tabelle für Regeln
SchlingelInc.Rules = {}

-- Regel: Briefkasten-Nutzung verbieten
function SchlingelInc.Rules.ProhibitMailboxUsage()
    SchlingelInc:Print("Die Nutzung des Briefkastens ist verboten!")
    CloseMail() -- Schließt den Briefkasten
end

-- Regel: Auktionshaus-Nutzung verbieten
function SchlingelInc.Rules.ProhibitAuctionhouseUsage()
    SchlingelInc:Print("Die Nutzung des Auktionshauses ist verboten!")
    CloseAuctionHouse() -- Schließt das Auktionshaus
end

-- Regel: Handeln mit Spielern außerhalb der Gilde verbieten
function SchlingelInc.Rules:ProhibitTradeWithNonGuildMembers(player)
    local tradePartner, _ = UnitName("NPC") -- Name des Handelspartners
    if tradePartner then
        local isInGuild = SchlingelInc:IsGuildAllowed(GetGuildInfo("NPC"))
        if not isInGuild then
            SchlingelInc:Print("Handeln mit Spielern außerhalb der Gilde ist verboten!")
            CancelTrade() -- Schließt das Handelsfenster sofort
        end
    end
end

-- Regel: Gruppen mit Spielern außerhalb der Gilde verbieten
function SchlingelInc.Rules:ProhibitGroupingWithNonGuildMembers()
    -- Nutze gecachte Guild Members statt direktem API-Call
    local numGroupMembers = GetNumGroupMembers()
    for i = 1, numGroupMembers do
        local memberName = UnitName("party" .. i) or UnitName("raid" .. i)
        local connected = UnitIsConnected("party" .. i) or UnitIsConnected("raid" .. i)
        if memberName and connected then
            -- Verwende GuildCache für schnellen Lookup
            if not SchlingelInc.GuildCache:IsGuildMember(memberName) then
                SchlingelInc:Print("Gruppen mit Spielern außerhalb der Gilde sind verboten!")
                LeaveParty() -- Verlasse die Gruppe
                return
            end
        end
    end
end

-- Initialisierung der Regeln
function SchlingelInc.Rules:Initialize()
	SchlingelInc.EventManager:RegisterHandler("MAIL_SHOW",
		function()
			SchlingelInc.Rules:ProhibitMailboxUsage()
		end, 0, "RuleMailbox")

	SchlingelInc.EventManager:RegisterHandler("AUCTION_HOUSE_SHOW",
		function()
			SchlingelInc.Rules:ProhibitAuctionhouseUsage()
		end, 0, "RuleAuctionHouse")

	SchlingelInc.EventManager:RegisterHandler("TRADE_SHOW",
		function()
			SchlingelInc.Rules:ProhibitTradeWithNonGuildMembers()
		end, 0, "RuleTrade")

	-- GROUP_ROSTER_UPDATE und RAID_ROSTER_UPDATE sind derzeit deaktiviert
	-- Kann bei Bedarf wieder aktiviert werden
end
