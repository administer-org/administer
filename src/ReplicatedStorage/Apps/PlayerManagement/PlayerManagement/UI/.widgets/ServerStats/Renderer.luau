-- Runtime renderer for the ServerStats widget.
local CachedStats = nil
local IsFetching = false
local WaitingUIs = {}

local function formatNumber(value): string
	if type(value) ~= "number" then
		return tostring(value)
	end

	local formatted = tostring(math.floor(value))
	while true do
		local replaced, substitutions = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
		formatted = replaced
		if substitutions == 0 then
			return formatted
		end
	end
end

local function setLoading(UI: Instance, isLoading: boolean)
	local Loading = UI:FindFirstChild("Loading", true)
	if Loading and Loading:IsA("GuiObject") then
		Loading.Visible = isLoading
	end
end

local function setStat(UI: Instance, name: string, value)
	for _, Item in UI:GetDescendants() do
		if Item.Name ~= name then
			continue
		end

		local Label = Item:FindFirstChild("Desc", true) or Item:FindFirstChild("Value", true)
		if Label and (Label:IsA("TextLabel") or Label:IsA("TextButton") or Label:IsA("TextBox")) then
			Label.Text = formatNumber(value)
		elseif Item:IsA("TextLabel") or Item:IsA("TextButton") or Item:IsA("TextBox") then
			Item.Text = formatNumber(value)
		end
	end
end

local function renderStats(UI: Instance, Stats)
	for Name, Value in Stats do
		setStat(UI, Name, Value)
	end
	setLoading(UI, false)
end

local function runWithTimeout(timeout: number, callback)
	local Finished = false
	local Success = false
	local Result = nil

	task.spawn(function()
		Success, Result = pcall(callback)
		Finished = true
	end)

	local Deadline = os.clock() + timeout
	while not Finished and os.clock() < Deadline do
		task.wait()
	end

	if not Finished or not Success then
		return nil
	end
	return Result
end

local function invoke(Remote: Instance?, timeout: number, ...)
	if not Remote or not Remote:IsA("RemoteFunction") then
		return nil
	end

	local Arguments = table.pack(...)
	return runWithTimeout(timeout, function()
		return Remote:InvokeServer(table.unpack(Arguments, 1, Arguments.n))
	end)
end

local function getPlaceInfo()
	return runWithTimeout(8, function()
		return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
	end)
end

local function versionText(isOutdated: boolean): string
	return `Server Version: {tostring(game.PlaceVersion)} ({isOutdated and "Outdated" or "Up-to-date"})`
end

local function watchGameVersion(UI: Instance)
	if UI:GetAttribute("PlayerManagementVersionWatcher") then
		return
	end
	UI:SetAttribute("PlayerManagementVersionWatcher", true)

	task.spawn(function()
		local PlaceInfo = getPlaceInfo()
		local Ver = type(PlaceInfo) == "table" and PlaceInfo.Updated or nil

		while UI.Parent do
			local NewPlaceInfo = getPlaceInfo()
			local NewVer = type(NewPlaceInfo) == "table" and NewPlaceInfo.Updated or nil
			setStat(UI, "GameVersion", versionText(Ver ~= nil and NewVer ~= nil and NewVer ~= Ver))
			task.wait(2)
		end

		UI:SetAttribute("PlayerManagementVersionWatcher", nil)
	end)
end

local function fetchStats()
	local Administer = game:GetService("ReplicatedStorage"):WaitForChild("Administer")
	local Apps = Administer:WaitForChild("Apps", 10)
	local PlayerManagement = Apps and Apps:WaitForChild("PlayerManagement", 10)
	local ServerComm = PlayerManagement and PlayerManagement:WaitForChild("ServerComm", 10)
	if not ServerComm then
		error("Player Management's ServerComm remote is unavailable")
	end

	local Stats = {
		BannedPlayers = 0,
		Favorites = "Unavailable",
		GameVersion = versionText(false),
		Players = 0,
		PrivateServers = 0,
		ServerCount = 0,
		["Staff Members"] = 0,
		Visits = 0,
	}

	local Servers = invoke(ServerComm, 8, "RequestServers")
	if type(Servers) == "table" then
		Stats.ServerCount = #Servers
		for _, Server in Servers do
			local Data = type(Server) == "table" and Server[2] or nil
			if type(Data) ~= "table" then
				continue
			end

			if type(Data.PSID) == "string" and Data.PSID ~= "" then
				Stats.PrivateServers += 1
			end
		end
	end

	local Ranks = invoke(Administer:FindFirstChild("GetRanks"), 8)
	if type(Ranks) == "table" then
		local Members = {}
		for _, Rank in Ranks do
			if type(Rank) == "table" and type(Rank.Members) == "table" then
				for _, Member in Rank.Members do
					if type(Member) == "table" and Member.ID ~= nil then
						Members[`{tostring(Member.MemberType)}:{tostring(Member.ID)}`] = true
					end
				end
			end
		end
		for _ in Members do
			Stats["Staff Members"] += 1
		end
	end

	local ProductInfo = getPlaceInfo()
	if type(ProductInfo) == "table" then
		Stats.Favorites = ProductInfo.FavoritedCount
			or ProductInfo.FavoriteCount
			or ProductInfo.Favorites
			or "Unavailable"
	end

	local PlayerIDs = invoke(ServerComm, 10, "GetAllPlayers", { Type = "Deep" })
	if type(PlayerIDs) ~= "table" then
		return Stats
	end

	local UniquePlayerIDs = {}
	for _, PlayerID in PlayerIDs do
		PlayerID = tonumber(PlayerID)
		if PlayerID then
			UniquePlayerIDs[PlayerID] = true
		end
	end

	local Queue = {}
	for PlayerID in UniquePlayerIDs do
		table.insert(Queue, PlayerID)
	end
	Stats.Players = #Queue

	local NextIndex = 0
	local CompletedWorkers = 0
	local WorkerCount = math.min(8, #Queue)
	local PlayerFetchDeadline = os.clock() + 15
	for _ = 1, WorkerCount do
		task.spawn(function()
			while os.clock() < PlayerFetchDeadline do
				NextIndex += 1
				local PlayerID = Queue[NextIndex]
				if not PlayerID then
					break
				end

				local RemainingTime = math.max(PlayerFetchDeadline - os.clock(), 0.1)
				local PlayerData = invoke(ServerComm, math.min(RemainingTime, 3), "RequestPlayerJSON", PlayerID)
				local Main = type(PlayerData) == "table" and PlayerData.Main or nil
				if type(Main) == "table" then
					if type(Main.Joins) == "number" then
						Stats.Visits += Main.Joins
					end
					if type(Main.ModRecords) == "table" and Main.ModRecords.ActiveBan == true then
						Stats.BannedPlayers += 1
					end
				end
			end
			CompletedWorkers += 1
		end)
	end

	while CompletedWorkers < WorkerCount do
		task.wait()
	end

	return Stats
end

local function loadStats(UI: Instance)
	setLoading(UI, true)
	if CachedStats then
		renderStats(UI, CachedStats)
		return
	end

	table.insert(WaitingUIs, UI)
	if IsFetching then
		return
	end
	IsFetching = true

	task.spawn(function()
		local Success, Result = pcall(fetchStats)
		CachedStats = Success and Result or {
			BannedPlayers = "Unavailable",
			Favorites = "Unavailable",
			GameVersion = versionText(false),
			Players = "Unavailable",
			PrivateServers = "Unavailable",
			ServerCount = "Unavailable",
			["Staff Members"] = "Unavailable",
			Visits = "Unavailable",
		}
		IsFetching = false

		if not Success then
			warn(`[Player Management] Failed to load widget stats: {tostring(Result)}`)
		end

		local UIs = WaitingUIs
		WaitingUIs = {}
		for _, WaitingUI in UIs do
			if WaitingUI.Parent then
				renderStats(WaitingUI, CachedStats)
			end
		end
	end)
end

return function(_Player, UI)
	watchGameVersion(UI)
	loadStats(UI)
end
