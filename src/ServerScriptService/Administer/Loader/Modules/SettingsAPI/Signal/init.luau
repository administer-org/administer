local Signal = {}
Signal.__index = Signal

local Connection = require(script.Connection)

local HttpService = game:GetService("HttpService")

function Signal.new()
	local connectionSignal = {}
	connectionSignal.Connections = {}
	function connectionSignal:Connect(setting: string, callback)
		local connection = Connection.new(callback)
		self.Connections[connection] = setting
		return connection
	end
	return connectionSignal
end

function Signal:Fire(setting: string)
	for connection, connectionSetting in self.Connections do
		if connectionSetting == setting then
			connection:_Fire()
		end
	end
end

return Signal