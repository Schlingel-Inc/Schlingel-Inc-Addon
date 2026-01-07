-- EventManager.lua
-- Central event manager for the SchlingelInc addon
-- Manages all WoW events in one place for better performance and maintainability

SchlingelInc.EventManager = {
	frame = nil,
	handlers = {},  -- { eventName = { {callback, priority, enabled}, ... } }
	registeredEvents = {}
}

--- Registers an event handler
-- @param event string The name of the WoW event (e.g. "PLAYER_DEAD")
-- @param callback function The function to be called
-- @param priority number Optional: Priority (higher = executed earlier), default: 0
-- @param identifier string Optional: Unique identifier for the handler
-- @return string The identifier of the registered handler
function SchlingelInc.EventManager:RegisterHandler(event, callback, priority, identifier)
	priority = priority or 0
	identifier = identifier or tostring(callback)

	-- Initialize handler list for this event
	if not self.handlers[event] then
		self.handlers[event] = {}
	end

	-- Check if this handler already exists
	for _, handler in ipairs(self.handlers[event]) do
		if handler.identifier == identifier then
			-- Handler already registered, skip
			return identifier
		end
	end

	-- Add handler
	table.insert(self.handlers[event], {
		callback = callback,
		priority = priority,
		enabled = true,
		identifier = identifier
	})

	-- Sort handlers by priority (highest first)
	table.sort(self.handlers[event], function(a, b)
		return a.priority > b.priority
	end)

	-- Register event with frame if not already done
	if not self.registeredEvents[event] then
		self.frame:RegisterEvent(event)
		self.registeredEvents[event] = true
	end

	return identifier
end

--- Removes an event handler
-- @param event string The event name
-- @param identifier string The identifier of the handler to remove
function SchlingelInc.EventManager:UnregisterHandler(event, identifier)
	if not self.handlers[event] then return end

	for i = #self.handlers[event], 1, -1 do
		if self.handlers[event][i].identifier == identifier then
			table.remove(self.handlers[event], i)
		end
	end

	-- If no more handlers exist for this event, unregister from frame
	if #self.handlers[event] == 0 then
		self.frame:UnregisterEvent(event)
		self.registeredEvents[event] = nil
		self.handlers[event] = nil
	end
end

--- Enables or disables a handler
-- @param event string The event name
-- @param identifier string The handler identifier
-- @param enabled boolean true = enabled, false = disabled
function SchlingelInc.EventManager:SetHandlerEnabled(event, identifier, enabled)
	if not self.handlers[event] then return end

	for _, handler in ipairs(self.handlers[event]) do
		if handler.identifier == identifier then
			handler.enabled = enabled
			return
		end
	end
end

--- Main event handler - distributes events to registered callbacks
local function OnEvent(self, event, ...)
	local handlers = SchlingelInc.EventManager.handlers[event]
	if not handlers then return end

	-- Call all enabled handlers for this event
	for _, handler in ipairs(handlers) do
		if handler.enabled then
			-- Execute handler with error handling
			pcall(handler.callback, event, ...)
		end
	end
end

--- Initializes the EventManager
function SchlingelInc.EventManager:Initialize()
	if self.frame then
		-- Already initialized
		return
	end

	-- Create the central event frame
	self.frame = CreateFrame("Frame", "SchlingelIncEventManagerFrame")
	self.frame:SetScript("OnEvent", OnEvent)
end

--- Outputs debug information about registered events
function SchlingelInc.EventManager:DebugInfo()
	print("=== SchlingelInc EventManager Debug ===")
	print("Registered events: " .. SchlingelInc:CountTable(self.registeredEvents))

	for event, handlers in pairs(self.handlers) do
		print("Event: " .. event .. " (" .. #handlers .. " handlers)")
		for i, handler in ipairs(handlers) do
			local status = handler.enabled and "active" or "inactive"
			print(string.format("  [%d] Priority: %d, Status: %s, ID: %s",
				i, handler.priority, status, handler.identifier))
		end
	end
	print("=======================================")
end
