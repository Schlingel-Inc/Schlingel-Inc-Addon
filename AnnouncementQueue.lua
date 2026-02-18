-- AnnouncementQueue.lua
-- Serializes death, level-up, and cap announcement popups so they don't override each other.
-- Callers push a function into the queue; the queue calls it when the slot is free.
-- Each popup's OnFinished animation callback must call AnnouncementQueue:Finished().

SchlingelInc.AnnouncementQueue = {
	_queue = {},
	_playing = false,
}

function SchlingelInc.AnnouncementQueue:Push(showFn)
	table.insert(self._queue, showFn)
	if not self._playing then
		self:_Next()
	end
end

function SchlingelInc.AnnouncementQueue:_Next()
	if #self._queue == 0 then
		self._playing = false
		return
	end
	self._playing = true
	local fn = table.remove(self._queue, 1)
	fn()
end

function SchlingelInc.AnnouncementQueue:Finished()
	self._playing = false
	self:_Next()
end
