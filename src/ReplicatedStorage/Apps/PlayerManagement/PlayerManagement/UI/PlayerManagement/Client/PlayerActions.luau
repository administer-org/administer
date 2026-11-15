--// pyxfluff 2025

local Player = {}

local AdministerClient = game.Players.LocalPlayer.PlayerGui:FindFirstChild("AdministerMainPanel", true).Client

local Shimmer = require(AdministerClient.Libraries.Shime)
local AdmAppAPI = require(AdministerClient.Modules.Apps)
local Utilities = require(AdministerClient.Modules.Utilities)
local Frontend = require(AdministerClient.Modules.Frontend)

local AdmRemotes = game.ReplicatedStorage:WaitForChild("Administer")
local Remotes = AdmRemotes:WaitForChild("Apps"):WaitForChild("PlayerManagement")

function Player.NotAvailableBox(PlayerBasic, IsOffline: boolean)
	Frontend.Popup.new(
		{
			Name = "Player Management",
			Icon = Utilities.Icon("users"),
		},
		{
			Primary = PlayerBasic.Photo,
			SubIcon = Utilities.Icon("x"),
		},

		`Feature unavailable`,
		IsOffline and "This feature does not allow targets to be offline or in restricted servers."
			or "You cannot make moderation actions against yourself. If you are simply testing then please load an alt account.",

		{
			{
				Text = "OK",
				Icon = Utilities.Icon("check-plain"),
				Callback = function(Close)
					Close()
				end,
			},
		}
	)
end

function Player.Kick(IsOnline, PlayerBasic, PlayerID, LoadPlayer, ServerJobID)
	if not IsOnline then
		Player.NotAvailableBox(PlayerBasic, true)
	end

	Frontend.Popup.new(
		{
			Name = "Player Management",
			Icon = Utilities.Icon("users"),
		},
		{
			Primary = PlayerBasic.Photo,
			SubIcon = Utilities.Icon("user-exit"),
		},

		`Kick @{PlayerBasic.Username}`,
		"Kicking removes somebody from the current server while retaining the ability to join instantly.",
		{
			{
				Text = "Yes",
				Icon = Utilities.Icon("check-plain"),
				Callback = function(Close, Text)
					print(Remotes.ServerComm:InvokeServer("KickPlayer", {
						["PrivateNote"] = Text[2],
						["KickMsg"] = Text[1],
						["TargetID"] = PlayerID,
					}))

					Close()
					LoadPlayer(PlayerID, ServerJobID)
				end,
			},
			{
				Text = "No",
				Icon = Utilities.Icon("x"),
				Callback = function(Close)
					Close()
				end,
			},
		},
		{
			{
				HeaderText = "Kick message",
			},
			{
				HeaderText = "Audit log reason",
			},
		}
	)
end

function Player.Join(IsOnline, PlayerBasic, PlayerID, LoadPlayer, ServerJobID)
	if
		(ServerJobID == 0 or ServerJobID == nil or string.find(ServerJobID:lower(), "studio") ~= nil) or not IsOnline
	then
		Player.NotAvailableBox(PlayerBasic, true)

		return
	end

	Frontend.Popup.new(
		{
			Name = "Player Management",
			Icon = Utilities.Icon("users"),
		},
		{
			Primary = PlayerBasic.Photo,
			SubIcon = Utilities.Icon("route"),
		},

		`Join @{PlayerBasic.Username}`,
		`Are you sure you would like to teleport to {PlayerBasic.DisplayName}? You will instantly join their server.`,
		{
			{
				Text = "Yes",
				Icon = Utilities.Icon("check-plain"),
				Callback = function(Close, Text)
					xpcall(function()
						game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, ServerJobID)
					end, function(e)
						Utilities.Logging.Warn(e)
					end)

					Close()
					LoadPlayer(PlayerID, ServerJobID)
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

function Player.Ban(IsOnline, PlayerBasic, PlayerID, LoadPlayer, ServerJobID, PlayerFrame, ClearWarns, FormatTime)
	local Shm = Shimmer.new(ClearWarns and PlayerFrame.Prompts.BanBox.BanClear or PlayerFrame.Prompts.BanBox.BanKeep)
	Shm:Play()

	--// serialize the duration
	local Seconds

	if string.lower(PlayerFrame.Prompts.BanBox.LengthInput.Text) ~= "forever" then
		local Sep = string.split(string.lower(PlayerFrame.Prompts.BanBox.LengthInput.Text), " ")

		if not tonumber(Sep[1]) then
			PlayerFrame.Prompts.BanBox.LengthInput.Text =
				'Bad input, try again using "x second(s), minute(s), day(s), ..."'

			Shm:Pause()
			Shm:GetFrame():Destroy()

			return
		end

		Seconds = (
			({
				second = 1,
				seconds = 1,
				minute = 60,
				minutes = 60,
				hour = 3600,
				hours = 3600,
				day = 86400,
				days = 86400,
				week = 604800,
				weeks = 604800,
				month = 18144000,
				months = 18144000,
				year = 31556952,
				years = 31556952,
			})[Sep[2]] or 0
		) * tonumber(Sep[1])

		if Seconds == 0 then
			PlayerFrame.Prompts.BanBox.LengthInput.Text =
				"Bad input, please specify a valid duration (x second(s), minute(s), day(s), ...)"
			Shm:Pause()
			Shm:GetFrame():Destroy()

			return
		end
	else
		Seconds = -1
	end

	print(Remotes.ServerComm:InvokeServer("BanPlayer", {
		["DidClearWarnings"] = ClearWarns,
		["BanDuration"] = Seconds,
		["PrivateNote"] = PlayerFrame.Prompts.BanBox.LogMessage.Text or "No reason provided.",
		["BanReason"] = PlayerFrame.Prompts.BanBox.BanMessage.Text
			or `Ban reason not provided.\n\nBanned by {game.Players.LocalPlayer.Name} for {FormatTime(Seconds)}.\n\nPowered by Administer.`,
		["TargetID"] = PlayerID,
		["BanDurationString"] = FormatTime(Seconds),
	}))

	Shm:Pause()
	Shm:GetFrame():Destroy(); --// i hate semicolons. i hate semicolons. i hate semicolons. i ha

	(ClearWarns and PlayerFrame.Prompts.BanBox.BanClear or PlayerFrame.Prompts.BanBox.BanKeep).Label.Text = "SUCCESS!"

	--// goodbye :saluting_face:
	task.wait(2)
	PlayerFrame.Prompts.BanBox.Visible = false
	(ClearWarns and PlayerFrame.Prompts.BanBox.BanClear or PlayerFrame.Prompts.BanBox.BanKeep).Label.Text = ClearWarns
			and "BAN & CLEAR WARNINGS"
		or "BAN (RETAIN RECORDS)"

	LoadPlayer(PlayerID, ServerJobID)
end

function Player.PromptBan(PlayerFrame, Connections, PlayerBasic, PlayerID)
	PlayerFrame.Prompts.BanBox.Visible = true

	PlayerFrame.Prompts.BanBox.MiscMeta.Text = `@{PlayerBasic["Username"]} • {PlayerID}`
	PlayerFrame.Prompts.BanBox.TopEffect.PlayerImage.Image = PlayerBasic["Photo"]
	PlayerFrame.Prompts.BanBox.Header.Text = `Ban {PlayerBasic["DisplayName"]}`
	PlayerFrame.Prompts.BanBox.HeaderContainer.HeaderLabel.Text = `Ban @{PlayerBasic["Username"]}`

	Connections["BanClose"] = PlayerFrame.Prompts.BanBox.HeaderContainer.Exit.MouseButton1Click:Connect(function()
		PlayerFrame.Prompts.BanBox.Visible = false
	end)
end

function Player.Unban(IsOnline, PlayerBasic, PlayerID, LoadPlayer, ServerJobID)
	Frontend.Popup.new(
		{
			Name = "Player Management",
			Icon = Utilities.Icon("users"),
		},
		{
			Primary = PlayerBasic.Photo,
			SubIcon = Utilities.Icon("warning-triangle"),
		},

		`Unban @{PlayerBasic.Username}`,
		"Are you sure you would like to end this players ban early? They will be able to join the game normally again.",
		{
			{
				Text = "Yes",
				Icon = Utilities.Icon("warning-filled"),
				Callback = function(Close, Text)
					print(Remotes.ServerComm:InvokeServer("UnbanPlayer", {
						TargetID = PlayerID,
						AuditLogMessage = Text[1],
					}))

					Close()
					LoadPlayer(PlayerID, ServerJobID)
				end,
			},
			{
				Text = "No",
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
		}
	)
end

function Player.Warn(IsOnline, PlayerBasic, PlayerID, LoadPlayer, ServerJobID)
	Frontend.Popup.new(
		{
			Name = "Player Management",
			Subheader = "Create warning",
			Icon = Utilities.Icon("users"),
		},
		{
			Primary = PlayerBasic.Photo,
			SubIcon = Utilities.Icon("warning-filled"),
		},

		`Warn @{PlayerBasic.Username}?`,
		"Enter your warning below.",
		{
			{
				Text = "Yes",
				Icon = Utilities.Icon("warning-filled"),
				Callback = function(Close, Text)
					print(Remotes.ServerComm:InvokeServer("WarnPlayer", {
						TargetID = PlayerID,
						Warning = Text[1],
					}))

					Close()
					LoadPlayer(PlayerID, ServerJobID)
				end,
			},
			{
				Text = "No",
				Icon = Utilities.Icon("x"),
				Callback = function(Close)
					Close()
				end,
			},
		},
		{
			{
				HeaderText = "Warning Text",
			},
			{
				HeaderText = "Log Reason",
			},
		}
	)
end

function Player.SendNote(IsOnline, PlayerBasic, PlayerID, LoadPlayer, ServerJobID)
	if not IsOnline then
		Player.NotAvailableBox(PlayerBasic, true)
	end

	Frontend.Popup.new(
		{
			Name = "Player Management",
			Subheader = "Send note",
			Icon = Utilities.Icon("users"),
		},
		{
			Primary = PlayerBasic.Photo,
			SubIcon = Utilities.Icon("megaphone"),
		},

		`Send note to @{PlayerBasic.Username}`,
		"They will be privately notified with a fullscreen message.",
		{
			{
				Text = "Send",
				Icon = Utilities.Icon("check-plain"),
				Callback = function(Close, Text)
					if Text[2] ~= "" and not table.find({ "y", "n", "yes", "no" }, string.lower(Text[2])) then
						Close()

						Frontend.Popup.new(
							{
								Name = "Player Management",
								Subheader = "Send note",
								Icon = Utilities.Icon("users"),
							},
							{
								Primary = Utilities.Icon("megaphone"),
								SubIcon = Utilities.Icon("x"),
							},

							"Unexpected value",
							'"Allow replying" must be y/n.',
							{
								{
									Text = "OK",
									Icon = Utilities.Icon("check-plain"),
									Callback = function(Close)
										Close()
									end,
								},
							}
						)

						return
					end

					print(Remotes.ServerComm:InvokeServer("SendNote", {
						TargetID = PlayerID,
						Message = Text[1],
						UseInput = string.lower(Text[2]) == "y" or string.lower(Text[2]) == "yes",
					}))

					Close()
					LoadPlayer(PlayerID, ServerJobID)
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
				HeaderText = "Message",
			},
			{
				HeaderText = "Allow replying? (y/n)",
			},
		}
	)
end

return Player
