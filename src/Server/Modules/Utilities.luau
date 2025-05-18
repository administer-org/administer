--// Administer
--// pyxfluff 2024 - 2025

--// Initialization
local Utils = {
	Time = {},
}

--// Dependencies
--// Do not add anything here you don't need, it will cause circular imports.
local Root     = script:FindFirstAncestor("Loader")
local Config   = require(Root.Core.Configuration)
local Var      = require(Root.Core.Variables)
local Locales  = Root.Core.Locales
local Types    = require(Root.Core.Types)
local HTTP     = require(Root.Modules.HTTPRunner)

local Settings = Config.Settings

--Retrieves a setting from the Administer settings index. Setting must be valid Setting syntax (read docs)
Utils.GetSetting = function(setting: Types.Setting, settings: Types.SettingsGroup, userId: number?): Types.SettingResponse
	return ""
end

Utils.Logging = {
	--Prints out a basic message.
	Print = function(...)
		if not Utils.GetSetting("Verbose") then return end
		print(`[{Config.Name}] [log]`, ...)
	end,

	--Creates a warning, with a traceback.
	Warn = function(...)
		warn(`[{Config.Name}] [warn]`, debug.traceback(...))
	end,

	--Warns without a debugging traceback both for the console and for admins.
	SWarn = function(...)
		warn(`[{Config.Name}] [warn]`, ...)
	end,

	--Throws an error.
	Error = function(...)
		error(debug.traceback(...))
	end,

	Debug = function(...)
		--// TODO
		print(debug.traceback(...))
	end,
}

--Checks if a provided player is an Administer admin.
Utils.IsAdmin = function(Player: Player): Types.AdminCheck
	if (Utils.GetSetting("SandboxMode") and game:GetService("RunService"):IsStudio()) or Var.EnableFreeAdmin then
		return {
			IsAdmin  = true,
			Reason   = Utils.t(Player, "admincheck.SUDO"),
			RankID   = 1,
			RankName = Utils.t(Player, "admin.RankDefault")
		}
	end

	local RanksIndex = game:GetService("DataStoreService"):GetDataStore("Administer_Admins"):GetAsync("CurrentRanks")

	if table.find({}, Player.UserId) ~= nil then
		return {
			IsAdmin = true,
			Reason = Utils.t(Player, "admincheck.OVERRIDE"),
			RankID = 1,
			RankName = Utils.t(Player, "admin.RankDefault")
		}
	else
		for GroupID, Data in require(Root.Core.Configuration).Admins.Groups do
			xpcall(function()
				if Player:GetRankInGroup(GroupID) == Data.RankNumber then
					return {
						IsAdmin = true,
						Reason = Utils.t(Player, "admincheck.OVERRIDE"),
						RankID = Data.AdminRankID,
						RankName = "Admin"
					}
				end
			end, function(e)
				if string.find(e, "of table") ~= nil then
					--// can disregard
				else
					error(e)
				end
			end)
		end
	end

	local _, Result = xpcall(function(): Types.AdminCheck
		if RanksIndex.AdminIDs[tostring(Player.UserId)] ~= nil then
			return {
				IsAdmin = true,
				Reason = Utils.t(Player, "admincheck.RANKINDEX"),
				RankID = RanksIndex.AdminIDs[tostring(Player.UserId)].AdminRankID,
				RankName = RanksIndex.AdminIDs[tostring(Player.UserId)].AdminRankName
			}
		else
			return {
				IsAdmin = false,
				RankID = 0
			}
		end
	end, function()
		--// Safe to ignore an error
		return {
			IsAdmin = false,
			RankID = 0
		}
	end)

	if Result.IsAdmin then return Result end

	--if RanksData["IsAdmin"] then
	--	return true, "Data based on settings configured by an admin.", RanksData["RankId"], RanksData["RankName"]
	--end

	local _, Result = xpcall(function()
		for ID, Group in RanksIndex.GroupAdminIDs do
			ID = string.split(ID, "_")[1]
			if not Player:IsInGroup(ID) then continue end

			if Group["RequireRank"] then
				if Player:GetRankInGroup(ID) ~= tonumber(Group["RankNumber"]) then continue end

				return {
					IsAdmin = true,
					Reason = Utils.t(Player, "admincheck.GROUP"),
					RankID = Group.AdminRankID,
					RankName = Group.AdminRankName
				}
			else
				return {
					IsAdmin = true,
					Reason = Utils.t(Player, "admincheck.GROUP"),
					RankID = Group.AdminRankID,
					RankName = Group.AdminRankName
				}
			end
		end
	end, function(e)
		if string.find(e, "of table") ~= nil then
			--// can disregard
		else
			error(e)
		end

		return {
			IsAdmin = false
		}
	end)

	if Result.IsAdmin then
		return Result
	end

	return {
		IsAdmin = false,
		Reason = Utils.t(Player, "admincheck.nil"),
		RankID = 0,
		RankName = Utils.t(Player, "admin.NoRank")
	}
end

-- Spawns a new admin notification. Yields, use with task.spawn to avoid.
Utils.NewNotification = function(Admin: Player, Body, Title, Icon, Duration, NotificationSound, Options)
	local Panel
	if (xpcall(function()
			Panel = Admin.PlayerGui:FindFirstChild("AdministerMainPanel")

			if Panel == nil then error(nil) end
			return true
		end, function()
			Utils.Logging.SWarn(
				"This player does not have the assets required to render a notification, ignoring request."
			)
			return false
		end)) == false
	then
		return { false }
	end

	local OpenTime = 1.25

	local Placeholder = Instance.new("Frame")

	Placeholder.Parent = Panel.Notifications
	Placeholder.BackgroundTransparency = 1
	Placeholder.Size = UDim2.new(1.036, 0, 0.142, 0)

	local Notification = Panel.Notifications.Template:Clone()

	Notification.Visible = true
	Notification = Notification.NotificationContent
	Notification.Parent.Position = UDim2.new(0, 0, 1.3, 0)
	Notification.Parent.Parent = Panel.NotificationsTweening
	Notification.Body.Text = Body
	Notification.Header.Title.Text = `<b>Administer</b> • {Title}`
	Notification.Header.ImageL.Image = Icon

	for i, Object: Types.ActionObject in Options do
		local NewButton = Notification.Buttons.DismissButton:Clone()
		NewButton.Parent = Notification.Buttons

		NewButton.Name = Object["Text"]
		NewButton.Title.Text = Object["Text"]
		NewButton.ImageL.Image = Object["Icon"]
		NewButton.MouseButton1Click:Connect(function()
			Object["OnClick"]()
		end)
	end

	local NewSound = Instance.new("Sound")
	NewSound.Parent = Notification
	NewSound.SoundId = "rbxassetid://9770089602"
	NewSound:Play()

	local Tweens = {
		Var.Services.TweenService:Create(
			Notification.Parent,
			TweenInfo.new(OpenTime, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{
				Position = UDim2.new(-0.018, 0, 0.858, 0)
			}
		),
		Var.Services.TweenService:Create(
			Notification,
			TweenInfo.new(OpenTime, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{
				GroupTransparency = 0
			}
		)
	}

	for i, v in Tweens do
		v:Play()
	end

	Tweens[1].Completed:Wait()
	Placeholder:Destroy()
	Notification.Parent.Parent = Panel.Notifications

	local function Close()
		local NotifTween2 =
			Var.Services.TweenService:Create(Notification, TweenInfo.new(OpenTime * 0.7, Enum.EasingStyle.Quad), {
				Position = UDim2.new(1, 0, 0, 0),
				GroupTransparency = 1
			})

		NotifTween2:Play()
		NotifTween2.Completed:Wait()
		pcall(function()
			Notification.Parent:Destroy()
		end)
	end

	Notification.Buttons.DismissButton.MouseButton1Click:Connect(Close)
	task.delay(Duration, Close)

	return { true }
end

function Utils.NewRemote(
	RemoteType: "RemoteEvent" | "RemoteFunction",
	RemoteName: string,
	AuthRequired: boolean,
	Callback: (...any) -> (...any),
	AppName: string | nil
): ()
	if not table.find({ "RemoteFunction", "RemoteEvent" }, RemoteType) then return false, "Invalid remote type!" end

	local Rem = Instance.new(RemoteType)
	Rem.Name = RemoteName
	Rem.Parent = Var.RemotesPath

	if RemoteType == "RemoteEvent" then
		(Rem :: RemoteEvent).OnServerEvent:Connect(function(Player: Player, ...)
			if AuthRequired and not table.find(Var.Admins.InGame, Player) then return false end

			Callback(Player, ...)

			return true
		end)

		return
	elseif RemoteType == "RemoteFunction" then
		(Rem :: RemoteFunction).OnServerInvoke = function(Player: Player, ...)
			if AuthRequired and not Utils.IsAdmin(Player)["IsAdmin"] then return false end

			if RemoteName ~= "Ping" then Utils.Logging.Print(`<-- [{Player.UserId}] {RemoteName}`) end

			local t, cbk = tick(), Callback(Player, ...)

			if RemoteName ~= "Ping" then Utils.Logging.Print(`--> {Utils.t(nil, "generic.Done")} ({string.sub(tostring((tick() - t) * 1000), 1, 6)}ms)`) end

			return cbk
		end
	end

	if AppName ~= nil then
		local AppsFolder = Var.RemotesPath:FindFirstChild("Apps")

		local AppFolder = AppsFolder:FindFirstChild(AppName) or Instance.new("Folder", AppsFolder)
		AppFolder.Name = AppName

		Rem.Parent = AppFolder
	end
end

function Utils.Time.RelativeFormat(Unix)
	local CurrentTime = os.time()
	local TimeDifference = CurrentTime - Unix

	if TimeDifference < 60 then
		return "Just Now"
	elseif TimeDifference < 3600 then
		local Minutes = math.floor(TimeDifference / 60)
		return `{Minutes} {Minutes == 1 and "minute" or "minutes"} ago`
	elseif TimeDifference < 86400 then
		local Hours = math.floor(TimeDifference / 3600)
		return `{Hours} {Hours == 1 and "hour" or "hours"} ago`
	elseif TimeDifference < 604800 then
		local Days = math.floor(TimeDifference / 86400)
		return `{Days} {Days == 1 and "day" or "days"} ago`
	elseif TimeDifference < 31536000 then
		local Weeks = math.floor(TimeDifference / 604800)
		return `{Weeks} {Weeks == 1 and "week" or "weeks"} ago`
	else
		local Years = math.floor(TimeDifference / 31536000)
		return `{Years} {Years == 1 and "years" or "years"} ago`
	end
end

function Utils.Time.FormatSeconds(Seconds: number)
	local Minutes = math.floor(Seconds / 60)
	Seconds = Seconds % 60

	if Utils.GetSetting("DisplayHours") then
		local Hours = math.floor(Minutes / 60)
		Minutes = Minutes % 60
		return string.format("%02i:%02i:%02i", Hours, Minutes, Seconds)
	else
		return string.format("%02i:%02i.%02i", Minutes, math.floor(Seconds), math.floor((Seconds % 1) * 100))
	end
end

function Utils.GetGameOwner(): { ID: number, MemberType: string }
	local _, Result, Type = pcall(function()
		local GameInfo = Var.Services.MarketplaceService:GetProductInfo(game.PlaceId, Enum.InfoType.Asset)

		if GameInfo.Creator.CreatorType == "User" then
			return GameInfo.Creator.Id, "User"
		else
			return Var.Services.GroupService:GetGroupInfoAsync(GameInfo.Creator.CreatorTargetId).Owner.Id, "Group"
		end
	end)

	return {
		ID = Result,
		MemberType = Type
	}
end

function Utils.GetShortNumer(Number)
	local Decimals = 2

	return (
		math.floor(
			((Number < 1 and Number) or math.floor(Number) / 10 ^ (math.log10(Number) - math.log10(Number) % 3))
				* 10 ^ (Decimals or 3)
		) / 10 ^ (Decimals or 3) .. (({ "k", "M", "B", "T", "Qa", "Qn", "Sx", "Sp", "Oc", "N" })[math.floor(math.log10(Number) / 3)] or "")
	)
end

function Utils.RoundMS(num)
	return tostring(num * 1000):sub(1, 7)
end

function Utils.GetGameMedia()
	local Default = "rbxassetid://75024044611103"

	local MediaData = Var.Services.HttpService:JSONDecode(
		Var.Services.HttpService:GetAsync(`{Var.ProxyURL}/games/v2/games/{game.GameId}/media`)
	)["data"]
	if MediaData == {} then return Default end

	local Tries = 0
	local Selected = false
	while not Selected do
		local Next = MediaData[Tries]

		if Next == nil or Next.videoHash ~= nil then
			if Tries >= 50 then return Default end

			if Tries ~= #MediaData then
				Tries += 1
				continue 
			else
				return Default --// exhausted all of our images, none good
			end
		else
			return "rbxassetid://" .. MediaData[Tries]["imageId"]
		end
	end

	return Default
end

function Utils.GetGameIcon()
	return `rbxassetid://{Var.Services.HttpService:JSONDecode(
		Var.Services.HttpService:GetAsync(`{Var.ProxyURL}/games/v1/games/{game.GameId}/icon`)
	)["imageId"] or Utils.Icon("book")}`
end

function Utils.GetServerRegion()
	local IP = Var.Services.HttpService:GetAsync("https://api.ipify.org/")
	local IPInfo = Var.Services.HttpService:JSONDecode(
		Var.Services.HttpService:GetAsync(`http://www.ip-api.com/json/{IP}?fields=status,message,countryCode,regionName,city`)
	)

	return `{IPInfo["countryCode"]}\\{IPInfo["regionName"]}`
end

function Utils.GetProminentColor(UserID)
	local s, Content = pcall(function()
		local Tries = 0
		local Raw

		repeat
			Tries += 1
			local success, data = pcall(function()
				return Var.Services.HttpService:GetAsync(
					`{Var.ProxyURL}/thumbnails/v1/users/avatar-headshot?userIds={UserID}&size=420x420&format=Png&isCircular=false`
				)
			end)
			Raw = data
		until success or Tries == 2

		if Tries == 2 then return { 33, 53, 122 } end

		local Decoded = Var.Services.HttpService:JSONDecode(Raw)
		local UserURL = Decoded["data"][1]["imageUrl"]

		return Var.Services.HttpService:JSONDecode(
			Var.Services.HttpService:GetAsync(`{Var.DefaultAppServer}/api/misc/get_prominent_color?image_url={UserURL}`)
		)
	end)

	Utils.Logging.Print("Got color", Content)

	return s and Content or { 33, 53, 122 }
end

function Utils.GetFilteredString(Player: Player, String: string): Types.Response
	local Success, Text = pcall(function()
		return Var.Services.TextService:FilterStringAsync(String, Player.UserId)
	end)

	if Success then
		local Success2, Text2 = pcall(function()
			return Text:GetNonChatStringForBroadcastAsync()
		end)
		if Success2 then
			return { true, Text2 }
		else
			return { false, `Failed to filter: {Text2}` }
		end
	else
		return { false, `Failed to filter: {Text}` }
	end
end

function Utils.t(Player: Player | nil, Key: string): string
	if Player == nil then
		return (require(Locales[Settings.Interface.Language.Value.Default]) :: any)[Key]
	else
		local LocaleResult
		xpcall(function()
			LocaleResult = (
				Var.CachedLocales[Player.UserId] or Var.DataStores.Settings:GetAsync(Player.UserId .. "Locale")
			) or "en"
		end, function(x) --// idk why we need should this?
			warn(debug.traceback(x))
			LocaleResult = "en"
		end)

		--Utils.Logging.Print(`Locale: {LocaleResult}`)

		return (require(Locales:FindFirstChild(LocaleResult)) :: any)[Key] or Key
	end
end

function Utils.Icon(IconID: string): string
	return require(script.Parent.Parent.Core.Icons)[IconID]
end

function Utils.UpdateCallback(Services: { string })
	local Data = {}

	for _, Service in Services do
		if Service == "org.admsoftware.Core" then
			Data["Administer"] = HTTP.GetRoute(Var.DefaultAppServer, "/pub/versions", function(VersionInfo, Misc)
				Data["org.admsoftware.Core"] = VersionInfo
			end, function(...)
				warn(...)
				Data["org.admsoftware.Core"] = VersionInfo
			end)
		else
			--// ...
		end	
	end
	
	return Data
end

function Utils.CountryToFlag(CountryCode)
	local Flag = ""

	for i = 1, string.len(CountryCode) do
		Flag = Flag .. utf8.char((CountryCode:sub(i, i):byte() % 32) + 0x1F1E5)
	end

	return Flag
end

function Utils.CheckVersion()
	local Vers = Config.VersData.String
	local SavedInstalls = Var.DataStores.AppDB:GetAsync("InstallDates") or {
		["org.admsoftware.Core"] = {}
	}
	
	if SavedInstalls["org.admsoftware.Core"][Vers] == nil then
		SavedInstalls["org.admsoftware.Core"][Vers] = os.time()
	end
	
	Var.DataStores.AppDB:SetAsync("InstallDates", SavedInstalls)
	
	return SavedInstalls["org.admsoftware.Core"][Vers]
end

return Utils
