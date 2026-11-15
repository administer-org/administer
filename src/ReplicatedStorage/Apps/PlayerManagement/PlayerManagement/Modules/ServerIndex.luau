--// pyxfluff 2024 - 2025
--// Administer

--// Resource by @kylerzong. Modified it to be efficient and modular
--// Fun fact: this is the same resource PS used! Although that one was broken

local MemoryStoreService = game:GetService("MemoryStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

local Server = {
	ServerIndexMap = MemoryStoreService:GetSortedMap("ServerIndex"),
}

local StartIndex = tick()
local GameIndex = RunService:IsStudio() and `Studio-{math.random(1, 25)}` or game.JobId

function Server.GetAllServers()
	local ServerItems = {}
	local StartFrom = nil
	while true do
		local Items = Server.ServerIndexMap:GetRangeAsync(Enum.SortDirection.Ascending, 100, StartFrom)

		for _, Item in Items do
			table.insert(ServerItems, { Item.key, HttpService:JSONDecode(Item.value) })
		end

		if #Items < 100 then
			break
		end

		StartFrom = Items[#Items].key
		task.wait(1)
	end
	return ServerItems
end

function Server.Flush(map)
	local StartFrom = nil
	while true do
		local Items = map:GetRangeAsync(Enum.SortDirection.Ascending, 100, StartFrom)

		for _, Item in Items do
			map:RemoveAsync(Item.key)
		end

		if #Items < 100 then
			break
		end

		StartFrom = Items[#Items].key
		task.wait(3)
	end
end

function Server.UploadToIndex(ExtraData)
	local Data = {
		["P"] = {},
		["ST"] = StartIndex,
		["CST"] = os.time(),
		["PV"] = game.PlaceVersion,
		["PSID"] = game.PrivateServerId,
		["PSO"] = game.PrivateServerOwnerId,
		["IS"] = game:GetService("RunService"):IsStudio(),
	}

	for k, v in ExtraData do
		Data[k] = v
	end

	repeat
		for i, Player in game.Players:GetPlayers() do
			if Player.UserId == nil then
				warn("Server is being a bit slow, waiting and retrying...")

				Data["P"] = nil

				task.wait(3)
				break
			end

			if table.find(Data["P"], Player.UserId) ~= nil then
				continue
			end
			table.insert(Data["P"], Player.UserId)
		end
	until #Data["P"] == #game.Players:GetPlayers()

	Server.ServerIndexMap:SetAsync(GameIndex, HttpService:JSONEncode(Data), 60)
end

game:BindToClose(function()
	Server.ServerIndexMap:RemoveAsync(GameIndex)
end)

return Server
