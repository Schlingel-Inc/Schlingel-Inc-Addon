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
        local isInGuild = C_GuildInfo.MemberExistsByName(tradePartner)
        --local isInGuild = SchlingelInc:IsGuildAllowed(GetGuildInfo("NPC"))
        if not isInGuild then
            SchlingelInc:Print("Handeln mit Spielern außerhalb der Gilde ist verboten!")
            CancelTrade() -- Schließt das Handelsfenster sofort
        end
    end
end

-- Regel: Gruppen mit Spielern außerhalb der Gilde verbieten
function SchlingelInc.Rules:ProhibitGroupingWithNonGuildMembers()
    -- Request fresh guild roster data
    C_GuildInfo.GuildRoster()

    -- Build list of all guild members
    local guildMembers = {}
    local numTotalGuildMembers = GetNumGuildMembers()
    for i = 1, numTotalGuildMembers do
        local name = GetGuildRosterInfo(i)
        if name then
            table.insert(guildMembers, SchlingelInc:RemoveRealmFromName(name))
        end
    end

    -- Check all group members
    local numGroupMembers = GetNumGroupMembers()
    for i = 1, numGroupMembers do
        local unit = "party" .. i
        if not UnitExists(unit) then
            unit = "raid" .. i
        end

        -- Skip disconnected players - they'll be checked again when they reconnect
        if UnitExists(unit) and not UnitIsConnected(unit) then
            -- Player is offline/disconnected, don't kick them
        else
            local memberName = UnitName(unit)
            -- Skip if name is not yet available (loading state)
            if memberName and memberName ~= UNKNOWNOBJECT and memberName ~= "" then
                local shortMemberName = SchlingelInc:RemoveRealmFromName(memberName)
                local isInGuild = tContains(guildMembers, shortMemberName)

                if not isInGuild then
                    LeaveParty()
                    SchlingelInc.Popup:Show({
                        title = "Gruppe verlassen!",
                        message = "Du kannst nur mit Gildenmitgliedern in einer Gruppe sein.",
                        displayTime = 3
                    })
                    return
                end
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

	-- Instantly decline party invites from non-guild members
	SchlingelInc.EventManager:RegisterHandler("PARTY_INVITE_REQUEST",
		function(event, sender)
			local isInGuild = SchlingelInc.GuildCache:IsGuildMember(sender)
			if not isInGuild then
				StaticPopup_Hide("PARTY_INVITE")
				DeclineGroup()
			end
		end, 0, "PartyInviteCheck")

	-- Check group members on roster updates
	SchlingelInc.EventManager:RegisterHandler("GROUP_ROSTER_UPDATE",
		function()
			SchlingelInc.Rules:ProhibitGroupingWithNonGuildMembers()
		end, 0, "GroupRosterCheck")

	SchlingelInc.EventManager:RegisterHandler("RAID_ROSTER_UPDATE",
		function()
			SchlingelInc.Rules:ProhibitGroupingWithNonGuildMembers()
		end, 0, "RaidRosterCheck")
end
