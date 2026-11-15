--// pyxfluff 2025

local Server = {}

local AdministerClient = game.Players.LocalPlayer.PlayerGui:FindFirstChild("AdministerMainPanel", true).Client

local Shimmer = require(AdministerClient.Libraries.Shime)
local AdmAppAPI = require(AdministerClient.Modules.Apps)
local Utilities = require(AdministerClient.Modules.Utilities)
local Frontend = require(AdministerClient.Modules.Frontend)

local AdmRemotes = game.ReplicatedStorage:WaitForChild("Administer")
local Remotes = AdmRemotes:WaitForChild("Apps"):WaitForChild("PlayerManagement")

function Server.Join(Server)
	if Server[1] == 0 or string.find(Server[1]:lower(), "studio") ~= nil then
		Frontend.Popup.new(
			{
				Name = "Player Management",
				Icon = Utilities.Icon("users"),
				Subheader = "Teleport Unavailable",
			},
			{
				Primary = Utilities.Icon("route"),
				SubIcon = Utilities.Icon("no-entry"),
			},
			`This feature isn't available`,
			Server[1] == 0 and `This player cannot be teleported to because they are in a reserved server.`
				or "This player cannot be teleported to because they are in Studio.",
			{
				{
					Text = "OK",
					Icon = Utilities.Icon("check-plain"),
					Callback = function(Close, Text)
						Close()
					end,
				},
			}
		)

		return
	end

	Frontend.Popup.new(
		{
			Name = "Player Management",
			Icon = Utilities.Icon("users"),
		},
		{
			Primary = AdmRemotes.GetGameArt:InvokeServer(),
			SubIcon = Utilities.Icon("route"),
		},

		`Join Server`,
		`Are you sure you would like to join {Server[1]}?`,

		{
			{
				Text = "Yes",
				Icon = Utilities.Icon("check-plain"),
				Callback = function(Close, Text)
					xpcall(function()
						game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, Server[1])
					end, function(e)
						Utilities.Logging.Warn(e)
					end)

					Close()
				end,
			},
			{
				Text = "Cancel",
				Icon = Utilities.Icon("x"),
				Callback = function(Close)
					Close()
				end,
			},
		}
	)
end

function Server.Shutdown(Server)
	Frontend.Popup.new(
		{
			Name = "Player Management",
			Icon = Utilities.Icon("users"),
		},
		{
			Primary = AdmRemotes.GetGameArt:InvokeServer(),
			SubIcon = Utilities.Icon("x"),
		},

		`Shutdown server`,
		`Are you sure you would like to shutdown this game instance?`,

		{
			{
				Text = "Yes",
				Icon = Utilities.Icon("check-plain"),
				Callback = function(Close, Text)
					print(Remotes.ServerComm:InvokeServer("ShutdownServer", {
						JobID = Server[1],
						PubReason = Text[1],
						PrivReason = Text[2],
					}))

					Close()
				end,
			},
			{
				Text = "Cancel",
				Icon = Utilities.Icon("x"),
				Callback = function(Close)
					Close()
				end,
			},
		},
		{
			{
				HeaderText = "Reason",
			},
			{
				HeaderText = "Log reason",
			},
		}
	)
end

function Server.Lock(Server)
	Frontend.Popup.new(
		{
			Name = "Player Management",
			Icon = Utilities.Icon("users"),
			Subheader = "Lock server",
		},
		{
			Primary = AdmRemotes.GetGameArt:InvokeServer(),
			SubIcon = Utilities.Icon("house-key"),
		},

		`Change Server Access Level`,
		`To make a server inaccessible, use level <b>2</b>. To make a server accessible to admins, use <b>1</b>. To allow everybody to join, use <b>0</b>.`,

		{
			{
				Text = "Yes",
				Icon = Utilities.Icon("check-plain"),
				Callback = function(Close, Text)
					print(Remotes.ServerComm:InvokeServer("LockServer", {
						JobID = Server[1],
						AccessLevel = Text[1],
						PubReason = Text[2],
						PrivReason = "N/A",
					}))

					Close()
				end,
			},
			{
				Text = "Cancel",
				Icon = Utilities.Icon("x"),
				Callback = function(Close)
					Close()
				end,
			},
		},
		{
			{
				HeaderText = "Security level",
			},
			{
				HeaderText = "Message to display",
			},
		}
	)
end

return Server
