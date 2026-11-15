--// pyxfluff 2025

return function(_, _, RuntimeData)
	local Settings = RuntimeData.Modules.SettingsAPI.new(require(script.Parent.Options))

	Settings.Load(1)

	local SettingsController = RuntimeData.Modules.SettingsAPI.GetController("CatwatcherAPI")
	local CustomEvent = Instance.new("BindableEvent", game.ServerStorage)

	CustomEvent.Name = "AdmCatWatcherTrigger"

	local function Scan(Player: Player)
		if not SettingsController.Get("JoinCheck") then
			return
		end

		RuntimeData.Modules.HTTPRunner.PostRoute(SettingsController.Get("BaseURL"), "/cwatcher/find-by-id", {
			user_id = Player.UserId,
		}, function(Response)
			assert(Response.code == 200, Response.data.message)

			if not Response.data.clean then
				local Action = SettingsController.Get("JoinAction")
				local PlayerStore = game:GetService("DataStoreService"):GetDataStore("AdministerPM_PlayerStore")
				local PlayerInfo = PlayerStore:GetAsync(Player.UserId)

				if not PlayerInfo then
					local Tries = 0

					repeat
						task.wait(0.5)
						PlayerInfo = PlayerStore:GetAsync(Player.UserId)
						Tries += 1
					until PlayerInfo ~= nil or Tries == 5
				end

				if Action == "Ban" then
					PlayerInfo.ModRecords.Actions[`Ban-{math.random(1, 50000)}`] = {
						DidClearWarnings = false,
						Duration = -1,
						Expires = "-1",
						Moderator = 1,
						PrivNote = `Found in servers: {game:GetService("HttpService")
							:JSONEncode(Response.data.current_servers)}`,
						Reason = "This user was found in exploiting servers.",
						Timestamp = os.time(),
						_Type = "BAN",
						Source = `Administer AdministerCatwatcherAPI/1.0`,
					}
					PlayerInfo.ModRecords._Bans += 1
					PlayerInfo.ModRecords.CurrentBanDuration = -1
					PlayerInfo.ModRecords.ActiveBan = true

					PlayerInfo.IsActive = false

					PlayerStore:SetAsync(Player.UserId, PlayerInfo)

					game.Players:BanAsync({
						UserIds = { Player.UserId },
						ApplyToUniverse = true,
						Duration = -1,
						DisplayReason = "Your account was found in exploit-related servers, and this game has opted to ban suspected cheaters. This action was taken automatically, please contact game staff with questions.\n\nPowered by Administer",
						PrivateReason = `Found in servers: {game:GetService("HttpService")
							:JSONEncode(Response.data.current_servers)}`,
						ExcludeAltAccounts = false,
					})
				elseif Action == "Kick" then
					PlayerInfo.ModRecords.Actions[`Kick-{math.random(1, 1500000)}`] = {
						DidClearWarnings = false,
						Moderator = 1,
						PrivNote = `Found in servers: {game:GetService("HttpService")
							:JSONEncode(Response.data.current_servers)}`,
						Reason = "This user was found in exploiting servers.",
						Timestamp = os.time(),
						_Type = "KICK",
					}

					PlayerInfo.IsActive = false

					PlayerStore:SetAsync(Player.UserId, PlayerInfo)

					Player:Kick(
						"Your account was found in exploit-related servers, and this game has opted to kick suspected cheaters. This action was taken automatically, please contact game staff with questions.\n\nPowered by Administer"
					)
				elseif Action == "CustomEvent" then
					CustomEvent:Fire(Player)
				end
			end
		end, function(...)
			warn(...)
		end)
	end

	RuntimeData.Modules.Utilities.NewRemote(
		"RemoteFunction",
		"DoLookup",
		true,
		function(Player: Player, Identifier: string | number)
			print(xpcall(function()
				if typeof(Identifier) == "string" then
					Identifier = game.Players:GetUserIdFromNameAsync(Identifier)
				end
			end, function()
				return {
					code = -1,
					data = {},
				}
			end))

			return RuntimeData.Modules.HTTPRunner.PostRoute(SettingsController.Get("BaseURL"), "/cwatcher/find-by-id", {
				user_id = Identifier,
			}, function(Response)
				Response.UserID = tonumber(Identifier)

				return Response
			end, function(_, Reply)
				--// idk
				if Reply.code then
					return Reply
				else
					return {
						code = 500,
						data = {
							is_ok = false,
							message = "internal http error",
						},
					}
				end
			end)
		end,
		"Catwatcher"
	)

	game.Players.PlayerAdded:Connect(Scan)

	--// post-init scan
	for _, Player in game.Players:GetPlayers() do
		task.defer(Scan, Player)
	end
end
