--// pyxfluff 2024 - 2025

local AdmRemotes = game.ReplicatedStorage:WaitForChild("Administer")
local Remotes    = AdmRemotes:WaitForChild("Apps"):WaitForChild("PlayerManagement")

local PausePolling = false
local PollInterval = 20
local IsVerbose    = false
local Connections  = {}
local PlayerCache  = {}

local MainFrame = script.Parent

local ServerDir = script.Parent.ServerDir
local Box = ServerDir.ServerLookup
local PlayerFrame = MainFrame.Player 

local AdministerClient = game.Players.LocalPlayer.PlayerGui:FindFirstChild("AdministerMainPanel", true).Client

local Shimmer   = require(AdministerClient.Libraries.Shime)
local AdmAppAPI = require(AdministerClient.Modules.Apps)
local Utilities = require(AdministerClient.Modules.Utilities)
local Frontend  = require(AdministerClient.Modules.Frontend)

--// PlayerManagement Modules
local ServerFunctions = require(script.ServerActions)
local PlayerFunctions = require(script.PlayerActions)

--// Init dropdown
local Dropdown = script.Parent.ContextMenu
local DropdownConnections = {}

Dropdown.Parent = script:FindFirstAncestorWhichIsA("ScreenGui")

local function HideDropdown()
	game:GetService("TweenService"):Create(Dropdown, TweenInfo.new(.4), { GroupTransparency = 1 }):Play()

	task.delay(.4, function() 
		Dropdown.Visible = false

		for _, Connection: RBXScriptConnection in DropdownConnections do 
			Connection:Disconnect()
		end
	end)
end

local function NewContextMenu(Options: {
	{ Icon: string, Text: string, OnClick: () -> () }
	})
	local Mouse = game.Players.LocalPlayer:GetMouse()
	local FinalSize = 0

	Dropdown.Position = UDim2.fromOffset(Mouse.X, Mouse.Y)
	Dropdown.Visible = true

	game:GetService("TweenService"):Create(Dropdown, TweenInfo.new(.4), { GroupTransparency = 0 }):Play()	
	for _, Child in Dropdown:GetChildren() do
		if Child:IsA("Frame") and Child.Name ~= "Item" then Child:Destroy() end
	end

	for _, Option in Options do
		local Choice = Dropdown.Item:Clone()

		Choice.Name = Option.Text

		Choice.Parent = Dropdown
		Choice.Visible = true

		Choice.Label.Text = Option.Text
		Choice.Icon.Image = Option.Icon

		DropdownConnections[`Click-{math.random(1,50000)}`] = Choice.Click.MouseButton1Click:Connect(function()
			HideDropdown()
			Option.OnClick()
		end)

		DropdownConnections[`Over-{math.random(1,50000)}`] = Choice.Click.MouseEnter:Connect(function()
			game:GetService("TweenService"):Create(Choice, TweenInfo.new(.2), { BackgroundTransparency = 0 }):Play()
		end)

		DropdownConnections[`Leave-{math.random(1,50000)}`] = Choice.Click.MouseLeave:Connect(function()
			game:GetService("TweenService"):Create(Choice, TweenInfo.new(.2), { BackgroundTransparency = 1 }):Play()
		end)

		FinalSize += Choice.Size.Y.Offset + Dropdown.UIListLayout.Padding.Offset
	end

	Dropdown.Size = UDim2.new(.247, 0, 0, FinalSize)
end

local function FormatTime(Seconds, Full)
	local Years = math.floor(Seconds / 31536000)
	Seconds = Seconds % 31536000
	local Months = math.floor(Seconds / 2592000)
	Seconds = Seconds % 2592000
	local Weeks = math.floor(Seconds / 604800)
	Seconds = Seconds % 604800
	local Days = math.floor(Seconds / 86400)
	Seconds = Seconds % 86400
	local Hours = math.floor(Seconds / 3600)
	Seconds = Seconds % 3600
	local Minutes = math.floor(Seconds / 60)
	Seconds = math.floor(Seconds % 60)

	local Final = ""
	local function Format(Value, Name, Short)
		if Value > 0 then
			Final = `{Final}{Value}{Full and ` {Name}{Value == 1 and "" or "s"}, ` or Short}`
		end
	end

	Format(Years, "year", "y")
	Format(Months, "month", "mo")
	Format(Weeks, "week", "w")
	Format(Days, "day", "d")
	Format(Hours, "hour", "h")
	Format(Minutes, "minute", "m")
	if Seconds > 0 or Final == "" then
		Format(Seconds, "second", "s")
	end

	return Final:sub(1, -3)
end


local function CachePlayer(
	Id,
	Verbose,
	ReturnPlaceholderOnFail
): any
	Verbose = IsVerbose

	if typeof(Id) ~= "table" then
		Id = { tonumber(Id) }
	else
		for I = 1, #Id do
			Id[I] = tonumber(Id[I])
		end
	end

	local Result = {}
	local ToFetch = {}

	for I = 1, #Id do
		local Cached = PlayerCache[Id[I]]
		if Cached then
			if Verbose then print("Found", Id[I], "from local cache!") end
			Result[Id[I]] = Cached
		else
			ToFetch[#ToFetch + 1] = Id[I]
		end
	end

	local Current = 1
	local Final = {
		{ }
	}

	for I = 1, #ToFetch do
		local UID = ToFetch[I]
		if #Final[Current] >= 100 then
			Current += 1
			Final[Current] = {}
		end

		Final[Current][#Final[Current] + 1] = UID
	end

	for I = 1, #Final do
		local Batch = Final[I]

		while true do
			local Success, Response = pcall(function()
				return game:GetService("UserService"):GetUserInfosByUserIdsAsync(Batch)
			end)

			if not Success then
				if Verbose then print("UserService request failed:", Response) end

				local Lower = string.lower(Response)
				for J = 1, #Batch do
					local UID = Batch[J]

					if string.find(Lower, "invalid userid") then
						Result[UID] = {
							Id = UID,
							DisplayName = `Banned user {UID}`,
							Username = "This user appears to have been banned.",
							HasVerifiedBadge = false,
							Photo = game.Players:GetUserThumbnailAsync(UID, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
						}
					elseif ReturnPlaceholderOnFail then
						Result[UID] = {
							Id = UID,
							DisplayName = `Loading failed ({UID})`,
							Username = "Roblox ratelimit reached",
							HasVerifiedBadge = false,
							Photo = "rbxassetid://84027648824846"
						}
					end
				end

				if not ReturnPlaceholderOnFail then
					task.wait(2)
					continue
				end

				break
			end

			for J = 1, #Response do
				local Info = Response[J]
				local UID = Info.Id

				Info.Photo = game.Players:GetUserThumbnailAsync(UID, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)

				PlayerCache[UID] = Info
				Result[UID] = Info
			end

			break
		end
	end

	if Verbose then
		local Total = 0
		for _, entry in PlayerCache do --// idk why # isnt working right
			Total += 1
		end
		print(`Completed! The cache is now {Total} items big.`)
	end

	return #Id == 1 and Result[Id[1]] or Result
end

--// Take a sample and attempt to cache as many people as possible
task.defer(function()
	local List = Remotes.ServerComm:InvokeServer("RequestServers")

	for i, s in List do
		for _i, p in s[2]["P"] do
			CachePlayer(p, false, false)
		end
	end
end)

local function LoadPlayer(
	PlayerID, 
	ServerJobID, 
	Delay
): nil
	for i, conn in Connections do conn:Disconnect() end
	Connections = {}

	PausePolling = true

	for i, c in PlayerFrame.Logs.ActionList:GetChildren() do
		if c:IsA("Frame") and c.Name ~= "Log" then
			c:Destroy() 
		end
	end

	PlayerFrame.ImageLabel.ImageColor3 = Color3.fromRGB(25, 25, 34)
	PlayerFrame.PlayerImage.Image = "rbxassetid://15105863258"
	PlayerFrame.PlayerDN.Text = "Loading player info..."
	PlayerFrame.PlayerUN.Text = ""

	local Shimmers = {}
	Connections = {}

	for i, Frame in {PlayerFrame.PlayerImage, PlayerFrame.Logs, PlayerFrame.PlayerUN, PlayerFrame.PlayerDN, PlayerFrame.Stats} do
		Shimmers[Frame.Name] = Shimmer.new(Frame)

		Shimmers[Frame.Name]:Play()
	end

	task.defer(function()
		Frontend.SwapApps(PlayerFrame)
	end)

	if Delay then
		task.wait(2)
	end

	local PlayerBasic = CachePlayer(PlayerID, false, false)
	local PlayerFull = Remotes.ServerComm:InvokeServer("RequestPlayerJSON", PlayerID)

	task.defer(function()
		local PromColor = game.ReplicatedStorage.Administer.GetProminentColorFromUserID:InvokeServer(PlayerID)
		PlayerFrame.ImageLabel.ImageColor3 = Color3.fromRGB(PromColor[1], PromColor[2], PromColor[3])
	end)

	PlayerFrame.PlayerDN.Text = PlayerBasic.DisplayName
	PlayerFrame.PlayerUN.Text = `@{PlayerBasic.Username}`
	PlayerFrame.PlayerImage.Image = PlayerBasic.Photo

	pcall(function()
		if PlayerFull.Main.IsActive then
			PlayerFrame.PlayStatus.Orb.BackgroundColor3 = Color3.fromRGB(20, 255, 114)
			PlayerFrame.PlayStatus.Text = `Playing for {FormatTime(AdmRemotes.GetSystemClock:InvokeServer() - PlayerFull["Main"]["LastSeen"])}`
		else
			PlayerFrame.PlayStatus.Orb.BackgroundColor3 = Color3.fromRGB(30, 32, 36)
			PlayerFrame.PlayStatus.Text = `Offline`
		end
	end)

	local Stats = PlayerFrame.Stats.ActionList

	print(PlayerFull)

	if PlayerFull.Main.Inactive then
		Frontend.Toast({
			Text = "That user has never played this game.",
			Subtext = "Some information may be unavailable.",
			Icon = Utilities.Icon "x",
			Timeout = 5
		})

		Stats.FirstSeen.Desc.Text = "Never"
		Stats.LastSeen.Desc.Text = "Never"
		Stats.PlayTime.Desc.Text = "0s"
		Stats.Plays.Desc.Text = "0"
		Stats.RobuxSpent.Desc.Text = "0"
		Stats.JoinedRoblox.Desc.Text = "0 days ago"

		Stats.IsAdmin.Desc.Text = PlayerFull.Admin.RankName
		Stats.UserID.Desc.Text = PlayerID

		Stats.ServerID.Desc.Text = "Offline"

		Stats.Region.Desc.Text = "Unknown"

		Stats.Warnings.Desc.Text = `<font color="{PlayerFull.Main.ModRecords._Warnings >= 2 and "rgb(187, 189, 49)" or "rgb(176, 176, 176)"}">{PlayerFull.Main.ModRecords._Warnings} Warnings</font>`
		Stats.Warnings.Icon.ImageColor3 = (PlayerFull.Main.ModRecords._Warnings >= 2 and Color3.fromRGB(187,189,49) or Color3.new(1,1,1))
	else
		Stats.FirstSeen.Desc.Text = Utilities.FormatRelativeTime(PlayerFull.Main.FirstSeen)
		Stats.LastSeen.Desc.Text = PlayerFull.Main.IsActive and "<font color=\"rgb(0,255,0)\">now</font>" or Utilities.FormatRelativeTime(PlayerFull.Main.LastSeen)
		Stats.PlayTime.Desc.Text = FormatTime(PlayerFull.Main.PlayTime)
		Stats.Plays.Desc.Text = PlayerFull.Main.Joins

		xpcall(function()
			Stats.Region.Desc.Text = PlayerFull.Main.RegionSerialized
		end, function()
			Stats.Region.Desc.Text = "Unknown"
		end)

		Stats.RobuxSpent.Desc.Text = PlayerFull.Main.RobuxSpent ~= nil and PlayerFull.Main.RobuxSpent or "0"
		Stats.JoinedRoblox.Desc.Text = PlayerFull.Main.RobuxSpent ~= nil and FormatTime(PlayerFull.Main.JoinedRoblox * 86400) or "?"

		Stats.IsAdmin.Desc.Text = PlayerFull.Admin.RankName
		Stats.UserID.Desc.Text = PlayerID

		if ServerJobID ~= nil then
			Stats.ServerID.Desc.Text = ServerJobID
		else
			Stats.ServerID.Desc.Text = "Offline"
		end


		Stats.Warnings.Desc.Text = `<font color="{PlayerFull.Main.ModRecords._Warnings >= 2 and "rgb(187, 189, 49)" or "rgb(176, 176, 176)"}">{PlayerFull.Main.ModRecords._Warnings} Warnings</font>`
		Stats.Warnings.Icon.ImageColor3 = (PlayerFull.Main.ModRecords._Warnings >= 2 and Color3.fromRGB(187,189,49) or Color3.new(1,1,1))

		local ContextRobux = Instance.new("TextButton", Stats.RobuxSpent)

		ContextRobux.Text = ""
		ContextRobux.BackgroundTransparency = 1
		ContextRobux.BorderSizePixel = 0
		ContextRobux.Size = UDim2.fromScale(1,1)

		ContextRobux.MouseButton2Click:Connect(function()
			Frontend.Popup.new(
				{
					Name = "Player Management",
					Subheader = "Robux Spent Information",
					Icon = Utilities.Icon "users"
				},
				{
					Primary = Utilities.Icon "finance-upwards",
					SubIcon = Utilities.Icon "question-circle"
				},
				"Why is this inaccurate?",
				"Administer only started collecting spent Robux after Player Management 2.1, so anything before then is not accounted for.",
				{
					{
						Text = "Got it!",
						Icon = Utilities.Icon "check-plain",
						Callback = function(C)
							C()
						end
					}
				}
			)
		end)
	end

	local IsOnline = (PlayerFull.Main.Inactive == nil and true or false) and PlayerFull.Main.IsActive 

	for _, Data in PlayerFull.Main.ModRecords.Actions do
		local Action = PlayerFrame.Logs.ActionList.Log:Clone()
		local ModData = CachePlayer(Data.Moderator, false, false)

		Action.Parent = PlayerFrame.Logs.ActionList
		Action.Visible = true
		Action.Name = game:GetService("HttpService"):GenerateGUID(false)

		Action.ActionLabel.Text = `<b>@{ModData.Username}</b> {Data._Type == "BAN" and `created a ban for {FormatTime(Data.Duration, true)}` or
			Data._Type == "WARN"       and   "created an active warning" or
			Data._Type == "NOTE"       and   "sent a note privately" or
			Data._Type == "LOGS_CLEAR" and   "cleared their logs" or
			Data._Type == "KICK"       and   "kicked them out of the game server" or
			Data._Type == "TELEPORT"   and   "moved them to another game" or
			Data._Type == "UNBAN"      and   "unbanned them early" or
			"... did something that confused your client"
		}`
		Action.Note.Text = 
			Data._Type == "BAN"        and   `{Data.Reason} ({Data.PrivNote}).` or
			Data._Type == "WARN"       and    Data.Warning or
			Data._Type == "NOTE"       and    Data.Message or
			Data._Type == "LOGS_CLEAR" and   `All logs and statistics may have been reset.` or
			Data._Type == "KICK"       and   `{Data.Reason} ({Data.PrivNote}).` or
			Data._Type == "TELEPORT"   and   `Sent to {Data.PlaceID}. {Data.Reason}` or
			Data._Type == "UNBAN"      and    Data.PrivNote or
			`Failed (_Type ({Data._Type} is unknown, unfinished feature)`
		Action.Icon.Image = 
			Data._Type == "BAN"        and   "rbxassetid://11284736452" or
			Data._Type == "WARN"       and   "rbxassetid://17402667535" or
			Data._Type == "NOTE"       and   "0" or
			Data._Type == "LOGS_CLEAR" and   "0" or
			Data._Type == "KICK"       and   "rbxassetid://138303173193406" or
			Data._Type == "TELEPORT"   and   "rbxassetid://84037313964620" or
			"http://www.roblox.com/asset/?id=15105963940"
		Action.Player.Image = ModData.Photo
	end

	for _, Log in PlayerFull.Main.AuditableActions do
		local Action = PlayerFrame.Logs.ActionList.Log:Clone()

		Action.Parent = PlayerFrame.Logs.ActionList
		Action.Visible = true
		Action.Name = game:GetService("HttpService"):GenerateGUID(false)

		Action.ActionLabel.Text = `Auditable action from app {Log.App.Name}`
		Action.Note.Text = Log.Action

		Action.Icon.Image = `rbxassetid://{Log.Icon}`
		Action.Player.Image = `rbxassetid://{Log.App.Icon}`
	end

	for _, Obj in {"PlayerImage", "PlayerUN", "PlayerDN", "Stats", "Logs"} do
		Shimmers[Obj]:Pause()
		Shimmers[Obj]:GetFrame():Destroy()
	end

	local function NotAvailableBox(IsOffline: boolean)
		Frontend.Popup.new(
			{
				Name = "Player Management",
				Icon = Utilities.Icon "users",
			},
			{
				Primary = PlayerBasic.Photo,
				SubIcon = Utilities.Icon "x"
			},

			`Feature unavailable`,
			IsOffline and "This feature does not allow targets to be offline or in restricted servers."
				or "You cannot make moderation actions against yourself. If you are simply testing then please load an alt account.",

			{
				{
					Text = "OK",
					Icon = Utilities.Icon "check-plain",
					Callback = function(Close)
						Close()
					end
				}
			}
		)
	end

	if PlayerBasic.Id == game.Players.LocalPlayer.UserId then
		for _, Button in PlayerFrame.QuickActions.ActionList:GetChildren() do
			if not Button:IsA("Frame") or Button.Name == "Fun" then continue end

			table.insert(Connections, Button.Click.MouseButton1Click:Connect(function()
				NotAvailableBox(false)

				return
			end))
		end

		return
	end

	Connections["KickButton"] = PlayerFrame.QuickActions.ActionList.Kick.Click.MouseButton1Click:Connect(function()
		PlayerFunctions.Kick(IsOnline, PlayerBasic, PlayerID, LoadPlayer)
	end)

	if ServerJobID == 0 or ServerJobID == nil then
		PlayerFrame.QuickActions.ActionList.TeleporterNudge.Desc.Text = "Unavailable"

	else
		PlayerFrame.QuickActions.ActionList.TeleporterNudge.Desc.Text = "Join server..."
	end

	Connections["JoinServer"] = PlayerFrame.QuickActions.ActionList.TeleporterNudge.Click.MouseButton1Click:Connect(function()
		PlayerFunctions.Join(IsOnline, PlayerBasic, PlayerID, LoadPlayer)
	end)

	if PlayerFull.Main.ModRecords.ActiveBan then
		if PlayerFull.Main.ModRecords.CurrentBanDuration == -1 then
			Stats.BanStatus.Desc.Text = `Permanently Suspended`
		else
			Stats.BanStatus.Desc.Text = `Suspended for {PlayerFull["Main"]["ModRecords"]["CurrentBanDuration"] / 60 / 24} days`
		end
		PlayerFrame.QuickActions.ActionList.Ban.Desc.Text = "Unban"

		Connections["UnbanButton"] = PlayerFrame.QuickActions.ActionList.Ban.Click.MouseButton1Click:Connect(function()
			PlayerFunctions.Unban(IsOnline, PlayerBasic, PlayerID, LoadPlayer, ServerJobID)
		end)
	else
		Stats.BanStatus.Desc.Text = `Not suspended`
		PlayerFrame.QuickActions.ActionList.Ban.Desc.Text = "Issue ban.."

		Connections["BanButton"] = PlayerFrame.QuickActions.ActionList.Ban.Click.MouseButton1Click:Connect(function()
			PlayerFunctions.PromptBan(PlayerFrame, Connections, PlayerBasic, PlayerID)
		end)

		Connections["BanClearWarns"] = PlayerFrame.Prompts.BanBox.BanClear.MouseButton1Click:Connect(function()
			PlayerFunctions.Ban(IsOnline, PlayerBasic, PlayerID, LoadPlayer, ServerJobID, PlayerFrame, true, FormatTime)
		end)

		Connections["BanKeepWarns"] = PlayerFrame.Prompts.BanBox.BanKeep.MouseButton1Click:Connect(function()
			PlayerFunctions.Ban(IsOnline, PlayerBasic, PlayerID, LoadPlayer, ServerJobID, PlayerFrame, false, FormatTime)
		end)
	end

	Connections["Warn"] = PlayerFrame.QuickActions.ActionList.Warn.Click.MouseButton1Click:Connect(function() 
		PlayerFunctions.Warn(IsOnline, PlayerBasic, PlayerID, LoadPlayer)
	end)

	Connections["NoteButton"] = PlayerFrame.QuickActions.ActionList.SendNote.Click.MouseButton1Click:Connect(function()
		PlayerFunctions.SendNote(IsOnline, PlayerBasic, PlayerID, LoadPlayer)
	end)

	--// DO NOT PUT ANYTHING DOWN HERE
end

local function InitServers(PopulateFakeServers)
	local Servers = Remotes.ServerComm:InvokeServer("RequestServers")
	local CanClick = true

	if PopulateFakeServers ~= nil then
		Servers = {}

		for i = 1, PopulateFakeServers do
			local FakeData = {
				CST = os.time(),
				ST = os.time() - math.random(60, 140000),
				AP = 0,
				P = {}
			}

			for i = 1, math.random(4, 50) do
				FakeData.AP += 1
				table.insert(FakeData.P, math.random(1, 2^30) * 2)
			end

			table.insert(Servers, {
				game:GetService("HttpService"):GenerateGUID(false),
				FakeData
			})
		end
	end

	for i, Server in Servers do
		local Template = ServerDir.Content.Template:Clone()

		Template.Name = Server[1]

		Template.RankName.Text = `Server {i}`
		Template.Info.Text = `{FormatTime(Server[2]["CST"] - Server[2]["ST"], true)} uptime · {#Server[2]["P"]} CCU · {Server[2]["AP"]} visits`

		Template.Parent = ServerDir.Content
		Template.Visible = true

		for _, Child in Template.ProfilePictures:GetChildren() do
			if Child:IsA("ImageLabel") then Child.Visible = false end
		end

		for i, Player in Server[2]["P"] do
			local PlayerData = CachePlayer(Player, false, true)

			pcall(function()
				if Template.ProfilePictures[i] == nil or PlayerData == {} then return end

				local CorrespondingIcon = Template.ProfilePictures[i]

				CorrespondingIcon.Image = PlayerData["Photo"]
				CorrespondingIcon.Visible = true
			end)
		end

		local function ServerView()
			if not CanClick then return end

			local Admins = 0
			local ShimmerAnim = Shimmer.new(Template)
			ShimmerAnim:Play()

			CanClick = false
			PausePolling = true

			Box.Position = UDim2.new(.35,0,0,0)
			Box.GroupTransparency = 1

			Box.GameDataHolder.GameData.Text = `Job ID: <b>{Server[1]}</b> • {FormatTime(Server[2]["CST"] - Server[2]["ST"])} uptime • version {Server[2]["PV"]}`

			task.defer(function()
				--// do slower processes here
				local Region = AdmRemotes.GetServerRegion:InvokeServer()

				Box.GameDataHolder.GameName.Text = `<b>{game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name}</b> • Server #{i}`
				Box.GameDataHolder.Thumb.Image = AdmRemotes.GetGameMedia:InvokeServer()
				Box.ServerStats.Region.Desc.Text = Region
				Box.ServerStats.Region.Icon.Text = Utilities.CountryToFlag(string.split(Region, "\\")[1])
			end)

			print(Server)

			Box.ServerStats.CurrentUsers.Desc.Text = #Server[2]["P"]
			Box.ServerStats.Visits.Desc.Text = Server[2]["AP"]
			Box.ServerStats.LockedTo.Desc.Text = Server[2]["L"] == "1" and "Admins" or Server[2]["L"] == "2" and "Nobody" or "Everybody"

			if Server[2]["PSID"] then
				--// just something we want to do while people may have PM2.0 servers live..
				Box.ServerStats.IsPrivateServer.Desc.Text = Server[2]["PSID"] == "" and "Public Server" or Server[2]["PSID"]
				Box.ServerStats.PrivateServerOwner.Desc.Text = Server[2]["PSO"] == 0 and "None" or Server[2]["PSO"]
			end

			Connections["ServerExit"] = Box.GameDataHolder.Close.MouseButton1Click:Connect(function()
				game:GetService("TweenService"):Create(Box, TweenInfo.new(.65, Enum.EasingStyle.Quart), {
					Position = UDim2.new(.35, 0, 0, 0),
					--Size = UDim2.new(.475, 0, .775, 0),
					GroupTransparency = 1
				}):Play()

				CanClick = true
				PausePolling = false

				for _, Connection in Connections do
					Connection:Disconnect()
				end

				task.delay(.65, function()
					Box.Visible = false
				end)
			end)

			for i, ch in Box.Members:GetChildren() do
				if ch.Name ~= "Template" and ch:IsA("Frame") then 
					ch:Destroy() 
				end
			end

			for _, ID in Server[2]["P"] do
				task.defer(function()
					local Template = Box.Members.Template:Clone()
					local PlayerInfo = CachePlayer(ID, false, true)
					local ServerPlayerInfo = Remotes.ServerComm:InvokeServer("RequestPlayerJSON", ID)

					Template.PlayerData.Text = `Current session: {FormatTime(AdmRemotes.GetSystemClock:InvokeServer() - ServerPlayerInfo["Main"]["LastSeen"])}\n{ServerPlayerInfo["Main"]["Joins"]} visits`
					Template.Icon.Image = PlayerInfo["Photo"]
					Template.PlrName.Text = `@{PlayerInfo.Username}`
					Template.PlrDisplayName.Text = PlayerInfo.DisplayName

					Template.AdminShield.Visible = ServerPlayerInfo.Admin.IsAdmin

					Template.Visible = true
					Template.Parent = Box.Members
					Template.Name = PlayerInfo["Id"]

					Connections[`Clickbox-{ID}-{math.random(1,5000)}`] = Template.Clickbox.MouseButton1Click:Connect(function()
						CanClick = true

						game:GetService("TweenService"):Create(Box, TweenInfo.new(.65, Enum.EasingStyle.Quart), {
							Position = UDim2.new(.35, 0, 0, 0),
							GroupTransparency = 1
						}):Play()

						LoadPlayer(ID, Server[1])
					end)

					Connections[`Clickbox-{ID}-{math.random(1,5000)}`] = Template.Clickbox.MouseButton2Click:Connect(function()
						local PlayerID = PlayerInfo.Id

						local PlayerBasic = CachePlayer(PlayerInfo.Id, false, false)

						NewContextMenu({
							{
								Icon = Utilities.Icon "x",
								Text = "Kick",
								OnClick = function()
									PlayerFunctions.Kick(true, PlayerBasic, PlayerID, LoadPlayer)
								end
							},
							{
								Icon = Utilities.Icon "network",
								Text = "Join",
								OnClick = function()
									ServerFunctions.Join(Server)
								end
							},
							{
								Icon = Utilities.Icon "no-entry",
								Text = "Ban",
								OnClick = function()
									--// we need to pull up their profile or it won't work
									LoadPlayer(PlayerID, Server[1])

									PlayerFunctions.PromptBan(PlayerFrame, Connections, PlayerBasic)
								end
							},
							{
								Icon = Utilities.Icon "triangle-warning",
								Text = "Warn",
								OnClick = function()
									PlayerFunctions.Warn(true, PlayerBasic, PlayerID, LoadPlayer)
								end
							},
							{
								Icon = Utilities.Icon "megaphone",
								Text = "Send PM",
								OnClick = function()
									PlayerFunctions.SendNote(true, PlayerBasic, PlayerID, LoadPlayer, Server[1])
								end
							},
							{
								Icon = Utilities.Icon "eye",
								Text = "View profile...",
								OnClick = function()
									LoadPlayer(PlayerID, Server[1])
								end
							},
							{
								Icon = Utilities.Icon "x",
								Text = "Cancel",
								OnClick = function()

								end
							}
						})
					end)

					if ServerPlayerInfo.Admin.IsAdmin then
						Admins += 1
					end
				end)
			end

			Box.ServerStats.CurrentAdmins.Desc.Text = Admins
			Box.GameDataHolder.Controls.Join.MouseButton1Click:Connect(function()
				ServerFunctions.Join(Server)
			end)

			Box.GameDataHolder.Controls.ShutDown.MouseButton1Click:Connect(function()
				ServerFunctions.Shutdown(Server)
			end)

			Box.GameDataHolder.Controls.Lock.MouseButton1Click:Connect(function()
				ServerFunctions.Lock(Server)
			end)

			Box.Visible = true
			game:GetService("TweenService"):Create(Box, TweenInfo.new(.65, Enum.EasingStyle.Quart), {
				Position = UDim2.new(.316, 0, 0, 0),
				--Size = UDim2.new(.675, 0, .974, 0),
				GroupTransparency = 0
			}):Play()

			ShimmerAnim:Pause()
			ShimmerAnim:GetFrame():Destroy()
		end

		Connections[Server[1]] = Template.Activate.MouseButton1Click:Connect(ServerView)

		Template.Activate.MouseButton2Click:Connect(function()
			NewContextMenu({
				{
					Icon = Utilities.Icon "no-entry",
					Text = "Shutdown",
					OnClick = function()
						ServerFunctions.Shutdown(Server)
					end
				},
				{
					Icon = Utilities.Icon "network",
					Text = "Join",
					OnClick = function()
						ServerFunctions.Join(Server)
					end
				},
				{
					Icon = Utilities.Icon "lock-closed",
					Text = "Lock",
					OnClick = function()
						ServerFunctions.Lock(Server)
					end
				},
				{
					Icon = Utilities.Icon "eye",
					Text = "View players",
					OnClick = function()
						ServerView()
					end
				},
				{
					Icon = Utilities.Icon "x",
					Text = "Cancel",
					OnClick = function()
					end
				}
			})
		end)
	end
end

AdmAppAPI.AddAppDrawerButton({
	AppName = "Player Management",
	Description = "Manage every player in your game from one place.",
	Icon = Utilities.Icon "users",
	ButtonID = "PlayerManagement",

	SubIcons = {
		{
			Name = "Directory",
			Icon = Utilities.Icon "network",
			Frame = ServerDir,
			Click = function()
				for i, conn in Connections do conn:Disconnect() end --// idk why it wasnt happen before but ? 

				PausePolling = false

				--// force an update
				for i, ch in ServerDir.Content:GetChildren() do
					if ch.Name ~= "Template" and ch:IsA("Frame") then ch:Destroy() end
				end

				task.defer(InitServers)
			end,
			ButtonID = "PlrDirectory"
		},
		{
			Name = "Bulk Moderate",
			Icon = Utilities.Icon "no-entry",
			Frame = script.Parent.Ban,
			ButtonID = "BulkModerate"
		},
		{
			Name = "Search",
			Icon = Utilities.Icon "user-search",
			Frame = script.Parent.PlayerLookup,
			ButtonID = "PlayerSearch"
		}
	}
})

task.defer(InitServers)

--// Bulk moderation functionality
local BulkFrame = script.Parent.Ban
local BulkSearchInput = BulkFrame.Searchbar.TextBox
local BulkSearchLabel = BulkFrame.Searchbar.Label
local BulkPlayerList = BulkFrame.PlayerList
local BulkPlayerTemplate = BulkPlayerList.Template
local BulkSearchConnections = {}
local BulkSearchGeneration = 0
local BulkSearchPlaceholder = "Type a User ID or name..."

local function ClearBulkResults()
	for _, Connection in BulkSearchConnections do
		Connection:Disconnect()
	end
	table.clear(BulkSearchConnections)

	for _, Child in BulkPlayerList:GetChildren() do
		if Child:IsA("Frame") and Child ~= BulkPlayerTemplate then
			Child:Destroy()
		end
	end
end

local function SetBulkSearchText(Text: string?)
	BulkSearchLabel.Text = if Text == nil or Text == "" then BulkSearchPlaceholder else Text
end

local function ShowBulkMessage(Message: string)
	local Card = BulkPlayerTemplate:Clone()
	Card.Name = "Message"
	Card.PlayerDN.Text = Message
	Card.PlayerUN.Text = ""
	Card.PlayerImage.Image = Utilities.Icon "question-circle"
	Card.Visible = true
	Card.Parent = BulkPlayerList
end

local function OpenBulkActions(PlayerBasic)
	local PlayerID = PlayerBasic.Id
	if PlayerID == game.Players.LocalPlayer.UserId then
		PlayerFunctions.NotAvailableBox(PlayerBasic, false)
		return
	end

	NewContextMenu({
		{
			Icon = Utilities.Icon "no-entry",
			Text = "Ban",
			OnClick = function()
				LoadPlayer(PlayerID)
				PlayerFunctions.PromptBan(PlayerFrame, Connections, PlayerBasic, PlayerID)
			end
		},
		{
			Icon = Utilities.Icon "triangle-warning",
			Text = "Warn",
			OnClick = function()
				PlayerFunctions.Warn(false, PlayerBasic, PlayerID, LoadPlayer)
			end
		},
		{
			Icon = Utilities.Icon "eye",
			Text = "View profile...",
			OnClick = function()
				LoadPlayer(PlayerID)
			end
		},
		{
			Icon = Utilities.Icon "x",
			Text = "Cancel",
			OnClick = function() end
		}
	})
end

local function RenderBulkPlayer(PlayerBasic)
	if type(PlayerBasic) ~= "table" or type(PlayerBasic.Id) ~= "number" then
		return
	end

	local Card = BulkPlayerTemplate:Clone()
	Card.Name = tostring(PlayerBasic.Id)
	Card.PlayerDN.Text = PlayerBasic.DisplayName or `User {PlayerBasic.Id}`
	Card.PlayerUN.Text = `{PlayerBasic.Id} · @{PlayerBasic.Username or "Unknown"}`
	Card.PlayerImage.Image = PlayerBasic.Photo or ""
	Card.Visible = true
	Card.Parent = BulkPlayerList

	local Activator = Instance.new("TextButton")
	Activator.Name = "Activator"
	Activator.BackgroundTransparency = 1
	Activator.BorderSizePixel = 0
	Activator.Text = ""
	Activator.Size = UDim2.fromScale(1, 1)
	Activator.ZIndex = math.max(Card.ZIndex, Card.PlayerDN.ZIndex, Card.PlayerUN.ZIndex) + 1
	Activator.Parent = Card

	table.insert(BulkSearchConnections, Activator.MouseButton1Click:Connect(function()
		OpenBulkActions(PlayerBasic)
	end))
	table.insert(BulkSearchConnections, Activator.MouseButton2Click:Connect(function()
		OpenBulkActions(PlayerBasic)
	end))
end

local function SearchBulkPlayers()
	BulkSearchGeneration += 1
	local SearchGeneration = BulkSearchGeneration
	local Query = string.match(BulkSearchInput.Text, "^%s*(.-)%s*$") or ""
	if Query == "" then
		ClearBulkResults()
		SetBulkSearchText()
		return
	end

	ClearBulkResults()
	SetBulkSearchText("Searching...")

	task.spawn(function()
		local IDs
		local NumericID = tonumber(Query)
		if NumericID then
			IDs = { NumericID }
		else
			local Success, Result = pcall(function()
				return Remotes.ServerComm:InvokeServer("SearchFromRoblox", {
					Query = Query
				})
			end)
			IDs = Success and type(Result) == "table" and Result or {}
		end

		if SearchGeneration ~= BulkSearchGeneration then
			return
		end

		local Players = #IDs > 0 and CachePlayer(IDs, false, true) or {}
		if SearchGeneration ~= BulkSearchGeneration then
			return
		end

		local Results = {}
		if #IDs == 1 and type(Players) == "table" and Players.Id ~= nil then
			table.insert(Results, Players)
		elseif type(Players) == "table" then
			for _, ID in IDs do
				if type(Players[ID]) == "table" then
					table.insert(Results, Players[ID])
				end
			end
		end

		SetBulkSearchText(Query)
		if #Results == 0 then
			ShowBulkMessage("No Roblox users were found.")
			return
		end

		for _, PlayerBasic in Results do
			RenderBulkPlayer(PlayerBasic)
		end
	end)
end

BulkSearchInput:GetPropertyChangedSignal("Text"):Connect(function()
	SetBulkSearchText(BulkSearchInput.Text)
end)

BulkSearchInput.FocusLost:Connect(function(WasEnterPressed)
	if WasEnterPressed then
		SearchBulkPlayers()
	end
end)

SetBulkSearchText()

local SearchEvents = {}
local SearchFrame = script.Parent.PlayerLookup
local PlayerSearchInput = SearchFrame.FromWhere.Searchbar.Input

-- A decorative search-bar layer can win touch hit-testing over its TextBox.
-- Explicitly focus the input when any part of the search bar is tapped so the
-- mobile keyboard always opens.
if game:GetService("UserInputService").TouchEnabled then
	PlayerSearchInput.Active = true
	PlayerSearchInput.TextEditable = true

	local function FocusPlayerSearch(Input)
		if Input.UserInputType == Enum.UserInputType.Touch then
			task.defer(function()
				PlayerSearchInput:CaptureFocus()
			end)
		end
	end

	SearchFrame.FromWhere.Searchbar.InputBegan:Connect(FocusPlayerSearch)
	for _, Child in SearchFrame.FromWhere.Searchbar:GetDescendants() do
		if Child:IsA("GuiObject") and Child ~= PlayerSearchInput then
			Child.InputBegan:Connect(FocusPlayerSearch)
		end
	end
end

local function IsExtendedTable(Table)
	for _, Child in Table do
		if type(Child) == "table" then
			return true
		else
			return false
		end
	end
end

--// Player Search functionality
local function UserSearchItem(
	UserID:      number,
	SearchQuery: string,
	SkipChecks:  boolean,
	ServerID:    string?
): ()
	if UserID == "InfoTip" then
		local Card = SearchFrame.Results.Template:Clone()

		Card.Name = "TipFrame"
		Card.Visible = true

		Card.User.Text = "Information"
		Card.Info.Text = SearchQuery
		Card.ProfilePicture.Image = Utilities.Icon "question-circle"

		Card.Parent = SearchFrame.Results

		return
	end

	if type(UserID) ~= "table" or #UserID == 0 then
		UserSearchItem("InfoTip", "No Roblox users were found for this search.", false)
		return
	end

	SearchQuery = string.lower(SearchQuery or "")

	if #UserID >= 100 then
		Frontend.Toast({
			Text = `Loading {#UserID} Players...`,
			Subtext = "This will take a while! For a quicker result please narrow your search query down or use a user ID for direct searches.",
			Icon = Utilities.Icon "triangle-warning",
			Timeout = 10
		})
	end

	local User = CachePlayer(UserID, false, false)
	if not User or (type(User) == "table" and next(User) == nil) then
		UserSearchItem("InfoTip", "No Roblox users were found for this search.", false)
		return
	end
	local Sanitized = {}

	if SkipChecks ~= true or SearchQuery == "" then
		local function Check(User)
			xpcall(function()
				if string.find(string.lower(User.DisplayName), SearchQuery) then
					User.IndexedFrom = "DisplayName"
				end
			end, function()
				Frontend.Toast({
					Text = `Could not complete search`,
					Subtext = "No results found. Please try another query.",
					Icon = Utilities.Icon "triangle-warning",
					Timeout = 5
				})
				User.IndexedFrom = "NoResults"
			end)

			if User.IndexedFrom == "NoResults" then return false end

			if string.find(string.lower(User.Username), SearchQuery) then
				User.IndexedFrom = "Username"
			end

			if tonumber(SearchQuery) ~= nil and string.find(tostring(UserID), SearchQuery) then
				User.IndexedFrom = "UserID"
			end

			if User.IndexedFrom == nil then
				return false
			else
				return true
			end
		end

		if IsExtendedTable(User) then
			for i, Player in User do
				if Check(Player) then
					Sanitized[i] = Player
				end
			end
		else
			Check(User)
		end
	end
	if IsExtendedTable(User) and next(Sanitized) == nil then
		UserSearchItem("InfoTip", "No Roblox users matched this search.", false)
		return
	end

	local function Card(User)
		if type(User) ~= "table" or type(User.Id) ~= "number" then
			return
		end
		local Card = SearchFrame.Results.Template:Clone()

		Card.Name = tostring(User.Id)
		Card.Visible = true

		Card.User.Text = User.DisplayName
		Card.Info.Text = `@{User.Username} · {User.Id} · Found from {User.IndexedFrom}`
		Card.ProfilePicture.Image = User.Photo

		SearchEvents[User.Id] = Card.Activate.MouseButton1Click:Connect(function()
			LoadPlayer(User.Id, ServerID, false)
		end)

		SearchEvents[`{User.Id}-Context`] = Card.Activate.MouseButton2Click:Connect(function()
			local PlayerID = User.Id

			local PlayerBasic = CachePlayer(User.Id, false, false)

			if ServerID then
				NewContextMenu({
					{
						Icon = Utilities.Icon "x",
						Text = "Kick",
						OnClick = function()
							PlayerFunctions.Kick(true, PlayerBasic, PlayerID, LoadPlayer)
						end
					},
					{
						Icon = Utilities.Icon "network",
						Text = "Join",
						OnClick = function()
							ServerFunctions.Join({ServerID})
						end
					},
					{
						Icon = Utilities.Icon "no-entry",
						Text = "Ban",
						OnClick = function()
							LoadPlayer(PlayerID, ServerID)
							PlayerFunctions.PromptBan(PlayerFrame, Connections, PlayerBasic)
						end
					},
					{
						Icon = Utilities.Icon "triangle-warning",
						Text = "Warn",
						OnClick = function()
							PlayerFunctions.Warn(true, PlayerBasic, PlayerID, LoadPlayer)
						end
					},
					{
						Icon = Utilities.Icon "megaphone",
						Text = "Send PM",
						OnClick = function()
							PlayerFunctions.SendNote(true, PlayerBasic, PlayerID, LoadPlayer, ServerID)
						end
					},
					{
						Icon = Utilities.Icon "eye",
						Text = "View profile...",
						OnClick = function()
							LoadPlayer(PlayerID, ServerID)
						end
					},
					{
						Icon = Utilities.Icon "x",
						Text = "Cancel",
						OnClick = function()
						end
					}
				})
			else
				NewContextMenu({
					{
						Icon = Utilities.Icon "x",
						Text = "User is offline",
						OnClick = function() end
					},
					{
						Icon = Utilities.Icon "no-entry",
						Text = "Ban",
						OnClick = function()
							LoadPlayer(PlayerID, ServerID)
							PlayerFunctions.PromptBan(PlayerFrame, Connections, PlayerBasic)
						end
					},
					{
						Icon = Utilities.Icon "triangle-warning",
						Text = "Warn",
						OnClick = function()
							PlayerFunctions.Warn(true, PlayerBasic, PlayerID, LoadPlayer)
						end
					},
					{
						Icon = Utilities.Icon "eye",
						Text = "View profile...",
						OnClick = function()
							LoadPlayer(PlayerID, ServerID)
						end
					},
					{
						Icon = Utilities.Icon "x",
						Text = "Cancel",
						OnClick = function()
						end
					}
				})
			end
		end)

		Card.Parent = SearchFrame.Results
	end

	if IsExtendedTable(User) then
		for _, User in Sanitized do
			Card(User)
		end
	else
		Card(User)
	end
end

PlayerSearchInput.FocusLost:Connect(function(WasEnter)
	if not WasEnter then return end

	local IndexLocation = (
		SearchFrame.FromWhere.Buttons.AllUsers.BackgroundTransparency == 0 and "Roblox" or
			SearchFrame.FromWhere.Buttons.GameDB.BackgroundTransparency == 0 and "Game" or
			SearchFrame.FromWhere.Buttons.Servers.BackgroundTransparency == 0 and "Servers"
	)

	for _, Child in SearchFrame.Results:GetChildren() do
		if not Child:IsA("Frame") or Child.Name == "Template" then continue end

		Child:Destroy()
	end

	for _, Connection in SearchEvents do
		Connection:Disconnect()
	end

	print(`Indexing search from {IndexLocation}`)

	if IndexLocation == "Servers" then
		local List = Remotes.ServerComm:InvokeServer("RequestServers")

		for _, Server in List do
			UserSearchItem(Server[2].P, SearchFrame.FromWhere.Searchbar.Input.Text, false, Server[1])
		end
	elseif IndexLocation == "Game" then
		UserSearchItem("InfoTip", `This tool is designed for smaller games. If you are having trouble loading page content please use Roblox search.`, false)
		local List = Remotes.ServerComm:InvokeServer("GetAllPlayers", {
			Type = "Deep"
		})		

		if List.__message ~= nil then
			UserSearchItem("InfoTip", List.__message, false)	
		end

		UserSearchItem(List, SearchFrame.FromWhere.Searchbar.Input.Text, false)
	elseif IndexLocation == "Roblox" then
		local List 

		if tonumber(SearchFrame.FromWhere.Searchbar.Input.Text) ~= nil then
			UserSearchItem({ tonumber(SearchFrame.FromWhere.Searchbar.Input.Text) }, "", true)

			return
		end

		xpcall(function()
			List = Remotes.ServerComm:InvokeServer("SearchFromRoblox", {
				Query = SearchFrame.FromWhere.Searchbar.Input.Text
			})
		end, function(e)
			UserSearchItem("InfoTip", `No results found ({e}).`, false)

			List = {}
		end)

		UserSearchItem(List, SearchFrame.FromWhere.Searchbar.Input.Text, false)
	end
end)

for _, Button: TextButton in SearchFrame.FromWhere.Buttons:GetChildren() do
	if not Button:IsA("TextButton") then continue end

	Button.MouseButton1Click:Connect(function()
		for _, Button2: TextButton in SearchFrame.FromWhere.Buttons:GetChildren() do
			if not Button2:IsA("TextButton") then continue end
			if Button2 == Button then continue end

			game:GetService("TweenService"):Create(Button2, TweenInfo.new(.3), { BackgroundTransparency = 1 }):Play()
		end

		game:GetService("TweenService"):Create(Button, TweenInfo.new(.3), { BackgroundTransparency = 0 }):Play()
	end)
end

local QSKeybind = AdmRemotes.GetSetting:InvokeServer("Player Management", "QuickSelect")

local CurrentKeys = {}
local Mouse = game.Players.LocalPlayer:GetMouse()
local QSConnection, Highlight

local QSBox = script.Parent.QuickSelect

QSBox.Parent = script.Parent.Parent.Parent

game:GetService("UserInputService").InputBegan:Connect(function(KeyCode, IsGameProc)
	if IsGameProc then return end

	table.insert(CurrentKeys, KeyCode.KeyCode)
end)

game:GetService("UserInputService").InputEnded:Connect(function(KeyCode, IsGameProc)
	if IsGameProc then return end

	if KeyCode.KeyCode == CurrentKeys[1] then
		local commaSeparated = {}

		for i, v in CurrentKeys do
			table.insert(commaSeparated, v.Name)
		end

		commaSeparated = table.concat(commaSeparated, ",")
		CurrentKeys = {}

		if commaSeparated == QSKeybind then 
			QSConnection = game:GetService("RunService").RenderStepped:Connect(function()
				local Target = Mouse.Target
				local Player = game.Players:GetPlayerFromCharacter(Target.Parent)

				if not Player then
					if Highlight then
						Highlight:Destroy()
					end

					return 
				end

				if Highlight then --// chances are there wont be Player for at least one frame.. but best to check anyways
					Highlight:Destroy()
				end

				Highlight = Instance.new("Highlight")

				Highlight.OutlineColor = Color3.new(1,1,1)
				Highlight.FillColor = Color3.new(1,1,1)
				Highlight.FillTransparency = .5

				Highlight.Parent = Target.Parent

				print(game.Players.LocalPlayer:GetMouse().Target)
				
				QSConnection:Disconnect() --// todo
			end)
		end
	end
end)

while task.wait(PollInterval) do
	if PausePolling then continue end

	for i, ch in ServerDir.Content:GetChildren() do
		if ch.Name ~= "Template" and ch:IsA("Frame") then ch:Destroy() end
	end

	for i, conn in Connections do conn:Disconnect() end
	Connections = {}

	InitServers()
end
