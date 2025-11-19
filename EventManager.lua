-- EventManager.lua
-- Zentraler Event-Manager für das SchlingelInc Addon
-- Verwaltet alle WoW-Events an einem Ort für bessere Performance und Wartbarkeit

SchlingelInc.EventManager = {
	frame = nil,
	handlers = {},  -- { eventName = { {callback, priority, enabled}, ... } }
	registeredEvents = {}
}

--- Registriert einen Event-Handler
-- @param event string Der Name des WoW-Events (z.B. "PLAYER_DEAD")
-- @param callback function Die Funktion, die aufgerufen werden soll
-- @param priority number Optional: Priorität (höher = früher ausgeführt), Standard: 0
-- @param identifier string Optional: Eindeutiger Identifier für den Handler
-- @return string Der Identifier des registrierten Handlers
function SchlingelInc.EventManager:RegisterHandler(event, callback, priority, identifier)
	priority = priority or 0
	identifier = identifier or tostring(callback)

	-- Initialisiere Handler-Liste für dieses Event
	if not self.handlers[event] then
		self.handlers[event] = {}
	end

	-- Prüfe ob dieser Handler bereits existiert
	for _, handler in ipairs(self.handlers[event]) do
		if handler.identifier == identifier then
			-- Handler bereits registriert, überspringen
			return identifier
		end
	end

	-- Füge Handler hinzu
	table.insert(self.handlers[event], {
		callback = callback,
		priority = priority,
		enabled = true,
		identifier = identifier
	})

	-- Sortiere Handler nach Priorität (höchste zuerst)
	table.sort(self.handlers[event], function(a, b)
		return a.priority > b.priority
	end)

	-- Registriere Event beim Frame, falls noch nicht geschehen
	if not self.registeredEvents[event] then
		self.frame:RegisterEvent(event)
		self.registeredEvents[event] = true
	end

	return identifier
end

--- Entfernt einen Event-Handler
-- @param event string Der Event-Name
-- @param identifier string Der Identifier des zu entfernenden Handlers
function SchlingelInc.EventManager:UnregisterHandler(event, identifier)
	if not self.handlers[event] then return end

	for i = #self.handlers[event], 1, -1 do
		if self.handlers[event][i].identifier == identifier then
			table.remove(self.handlers[event], i)
		end
	end

	-- Wenn keine Handler mehr für dieses Event existieren, unregister vom Frame
	if #self.handlers[event] == 0 then
		self.frame:UnregisterEvent(event)
		self.registeredEvents[event] = nil
		self.handlers[event] = nil
	end
end

--- Aktiviert oder deaktiviert einen Handler
-- @param event string Der Event-Name
-- @param identifier string Der Identifier des Handlers
-- @param enabled boolean true = aktiviert, false = deaktiviert
function SchlingelInc.EventManager:SetHandlerEnabled(event, identifier, enabled)
	if not self.handlers[event] then return end

	for _, handler in ipairs(self.handlers[event]) do
		if handler.identifier == identifier then
			handler.enabled = enabled
			return
		end
	end
end

--- Hauptevent-Handler - verteilt Events an registrierte Callbacks
local function OnEvent(self, event, ...)
	local handlers = SchlingelInc.EventManager.handlers[event]
	if not handlers then return end

	-- Rufe alle aktivierten Handler für dieses Event auf
	for _, handler in ipairs(handlers) do
		if handler.enabled then
			-- Führe Handler mit Fehlerbehandlung aus
			pcall(handler.callback, event, ...)
		end
	end
end

--- Initialisiert den EventManager
function SchlingelInc.EventManager:Initialize()
	if self.frame then
		-- Bereits initialisiert
		return
	end

	-- Erstelle den zentralen Event-Frame
	self.frame = CreateFrame("Frame", "SchlingelIncEventManagerFrame")
	self.frame:SetScript("OnEvent", OnEvent)
end

--- Gibt Debug-Informationen über registrierte Events aus
function SchlingelInc.EventManager:DebugInfo()
	print("=== SchlingelInc EventManager Debug ===")
	print("Registrierte Events: " .. SchlingelInc:CountTable(self.registeredEvents))

	for event, handlers in pairs(self.handlers) do
		print("Event: " .. event .. " (" .. #handlers .. " Handler)")
		for i, handler in ipairs(handlers) do
			local status = handler.enabled and "aktiv" or "inaktiv"
			print(string.format("  [%d] Priority: %d, Status: %s, ID: %s",
				i, handler.priority, status, handler.identifier))
		end
	end
	print("=======================================")
end
