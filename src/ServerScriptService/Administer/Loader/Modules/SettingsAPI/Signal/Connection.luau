local Connection = {}
Connection.__index = Connection

function Connection.new(callback)
	local newConnection = {}
	newConnection.callback = function(...)
		callback(...)
	end
	return newConnection
end

function Connection:_Fire()
	if self.callback then
		task.spawn(self.callback)
	end
end

function Connection:Disconnect()
	self.callback = nil
end

return Connection
