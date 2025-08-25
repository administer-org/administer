--// Administer
--// pyxfluff 2022-2025

local SharedLibs = script.Libraries
local Assets = script.Assets
local Modules = script.Modules

local Var       = require(Modules.Variables)

local Admins    = require(Modules.Admins)
local Apps      = require(Modules.Apps)
local Frontend  = require(Modules.Frontend)
local Utilities = require(Modules.Utilities)
local Widgets   = require(Modules.Widgets)

local t = Utilities.Translate

Frontend.Close(true)

local function CacheSettings()
	local settingData = Utilities.GetSettings({"AnimationSpeed", "ShortNumberDecimals", "Verbosity"})
	
	Var.AnimationSpeed = tonumber(settingData["AnimationSpeed"])
	Var.ShortNumberDecimals = tonumber(settingData["ShortNumberDecimals"])
	Var.Verbosity = settingData["Verbosity"]

	return true
end

local success, errormsg = pcall(function()
	if script.Parent:GetAttribute("StartID") == nil then error() end

	Var.Remotes.Ping:InvokeServer()

	--// Cache some settings
	CacheSettings()

	Var.Remotes.SettingsLoaded.OnClientEvent:Connect(CacheSettings)
end)

if not success then
	print(errormsg)
	Utilities.NewNotification("Administer", "", Utilities.Translate("error.NoPing"), "Startup failed", 999)

	error(`Could not connect to the server, is Administer improperly installed?`)
end

local function DoUpdate()
	Var.FinishedUpdate = false

	Var.Version = Var.Remotes:WaitForChild("GetVersions"):InvokeServer({"administer"})["administer"]
	Var.Remotes.CheckForUpdates:InvokeServer({ "org.admsoftware.Core" })

	Var.FinishedUpdate = true
end

local Thread = task.defer(DoUpdate)
task.delay(5, function()
	if not Var.FinishedUpdate then
		Var.DisableOnlineServices = true

		Utilities.NewNotification(
			"Administer", 
			Utilities.Icon "triangle-warning", 
			Utilities.Translate("updater.Failed.Body"), 
			Utilities.Translate("updater.Failed.Header"), 
			999
		)
	end
end)

task.defer(Utilities.Heartbeat)

task.defer(function()
	pcall(function()
		require(Modules.ClientSettings)
	end)
end)

Var.Remotes.SettingsLoaded.OnClientEvent:Wait()

local essentialSettings = Utilities.GetSettings({"KeybindRegisterTime", "HomepageGreeting", "AssistiveClose", "EnableClickEffects", "ChatCommand"})

local KeybindRegisterTimeframe = essentialSettings["KeybindRegisterTime"]

if KeybindRegisterTimeframe == "optimistic" then
	Frontend.RegisterPanelKeybind()
end

Widgets.Initialize()

task.defer(function()
	Apps.AddAppDrawerButton({
		AppName = t("Apps.MainFrame.Home.Title"),
		Description = t("Apps.MainFrame.Template.Desc"),
		Icon = Utilities.Icon "home",
		ButtonID = "AdmHomepage",

		MainButtonClick = function() end,
		MainButtonFrame = Var.MainFrame.Home,

		SubIcons = {}
	})

	Apps.AddAppDrawerButton({
		AppName = t("Apps.MainFrame.Config.Title"),
		Description = t("Apps.MainFrame.Config.Desc"),
		Icon = Utilities.Icon "media",
		ButtonID = "AdmConfiguration",

		SubIcons = {
			{
				Name = t("Configuration.MenuBar.New.AInfoPage.HeaderLabel"),
				Icon = Utilities.Icon "info",
				Click = function() end,
				Frame = Var.MainFrame.Configuration.InfoPage,
				ButtonID = "Information"
			},
			{
				Name = Utilities.ToSentenceCase( t("Apps.MainFrame.Config.Title") ),
				Icon = Utilities.Icon "gear",
				Click = function() end,
				Frame = Var.MainFrame.Configuration.Settings,
				ButtonID = "Settings"
			},
			{
				Name = Utilities.ToSentenceCase( t("Header.AppDrawer.HeaderLabel") ),
				Icon = Utilities.Icon "grid",
				Click = Apps.LoadAppList,
				Frame = Var.MainFrame.Configuration.Marketplace,
				ButtonID = "Marketplace"
			},
			{
				Name = t("Configuration.Admins.Container.Ranks.Header.TLabel"),
				Icon = Utilities.Icon "user-clip",
				Click = function() end,
				Frame = Var.MainFrame.Configuration.Admins,
				ButtonID = "AdminConfig"
			}
		}
	})
end)

for _, Button in Var.MainFrame:GetDescendants() do
	if Button:IsA("TextButton") then
		print(`ok to {Button.Name}`)
		Frontend.AddButtonAnimation(Button)
	end
end

--// Homepage, app drawer, header connections
Var.MainFrame.Home.Widget1.Edit.MouseButton1Click:Connect(function()
	Widgets.Edit(Var.MainFrame.Home.Widget1)
end)

Var.MainFrame.Home.Widget2.Edit.MouseButton1Click:Connect(function()
	Widgets.Edit(Var.MainFrame.Home.Widget2)
end)

Var.MainFrame.Header.Mark.AppLogo.MouseButton1Click:Connect(Frontend.Drawer.Open)
Var.MainFrame.Header.Mark.AppLogo.MouseEnter:Connect(Frontend.Drawer.HoverBegin)
Var.MainFrame.Header.Mark.AppLogo.MouseLeave:Connect(Frontend.Drawer.HoverEnd)

Frontend.SpawnOverlay(Var.MainFrame)

Var.MainFrame.Home.Welcome.Text = `<stroke color="rgb(0,0,0)" transparency = "0.85" thickness="0.4">{string.format(
	t("Welcome.Initial.HeaderLabel") :: string,
	Var.Services.Players.LocalPlayer.DisplayName,
	essentialSettings["HomepageGreeting"]
)}</stroke>`

Var.MainFrame.Home.PlayerImage.Image = Var.Services.Players:GetUserThumbnailAsync(
	Var.Services.Players.LocalPlayer.UserId,
	Enum.ThumbnailType.HeadShot,
	Enum.ThumbnailSize.Size352x352
) 

Var.MainFrame.AppDrawer.PlayerData.DisplayName.Text = Var.Services.Players.LocalPlayer.DisplayName
Var.MainFrame.AppDrawer.PlayerData.Rank.Text = `{Var.MainFrame.Parent:GetAttribute("_AdminRank")} · {#Var.MainFrame.AppDrawer.AppHolder.Apps:GetChildren() - 4} apps`
Var.MainFrame.AppDrawer.PlayerData.PlayerImage.Image = Var.Services.Players:GetUserThumbnailAsync(
	Var.Services.Players.LocalPlayer.UserId,
	Enum.ThumbnailType.HeadShot,
	Enum.ThumbnailSize.Size352x352
)

task.defer(function()
	local PromColor = Var.Remotes.GetProminentColorFromUserID:InvokeServer(Var.Services.Players.LocalPlayer.UserId)

	Var.MainFrame.Home.Gradient2.ImageLabel.ImageColor3 = Color3.fromRGB(PromColor[1], PromColor[2], PromColor[3])
end)

if script.Parent:GetAttribute("NeedsSetup") then
	Utilities.Logging.Print("Setup is not complete, entering lockdown mode!")

	Var.DoHeaderEffects = false

	Frontend.SwapAppBasic(Var.MainFrame.Welcome, {
		Name = "Setup",
		Icon = Utilities.Icon "sparkles"
	})

	require(script.Modules.Helpers.FirstTimeSetup)()

	Frontend.Open()
end

--// Marketplace
task.defer(function()
	xpcall(Apps.Init, function(e)
		Utilities.Logging.Print("[x] [thread Apps] Failed to initialize the marketplace, this is likely due to insufficient permissions!", e)
	end)
end)

--// Admins
xpcall(function()
	task.defer(function()
		pcall(Admins.Load)
	end)

	Admins.RunCreatorApp()

	Var.MainFrame.Configuration.Admins.Header.NewRank.Activator.MouseButton1Click:Connect(function()
		Admins.OpenCreator()
	end)
end, function(e)
	Utilities.Logging.Warn(`[x] [thread Admins] {e}`)
end)

if Var.Services.UserInputService.TouchEnabled and not Var.Services.UserInputService.KeyboardEnabled then
	Utilities.Logging.Print("Mobile mode has been enabled!")
	Var.Mobile = true

	task.defer(function()
		Utilities.NewNotification(
			"Administer",
			Utilities.Icon "iphone-notch",
			Utilities.Translate("mobile.body"),
			Utilities.Translate("mobile.detail"),
			25
		)
	end)

	Var.MainFrame.Parent
		:WaitForChild("MobileOpen", 10).Hit.TouchSwipe
		:Connect(function(SwipeDirection: Enum.SwipeDirection)
			if SwipeDirection == Enum.SwipeDirection.Left then
				Frontend.Open(true)
			end
		end)

	Var.MainFrame.Header.AssistiveClose.Visible = true
	Var.MainFrame.Header.AssistiveClose.MouseButton1Click:Connect(Frontend.Close)
else
	Var.Mobile = false

	Var.MainFrame.Parent.MobileOpen:Destroy()

	if essentialSettings["AssistiveClose"] == true then
		Var.MainFrame.Header.AssistiveClose.Visible = true
		Var.MainFrame.Header.AssistiveClose.MouseButton1Click:Connect(Frontend.Close)
	end
end

local IsDonating = false
local Passes = {}

xpcall(function(...)
	repeat task.wait() until Var.MainFrame:FindFirstChild("Header")

	local Info = Var.MainFrame.Configuration.InfoPage

	Info.VersionDetails.Version.Text = Var.Version.NoExtraData .. " " .. Var.Version.Extra

	local function NewVersCard(Data)
		if Data.IsFail then
			local Card = Info.UpdateCenter.ScrollingFrame.Card:Clone()

			Card.Parent = Info.UpdateCenter.ScrollingFrame
			Card.Name = "Administer"

			Card.Data.Text = Utilities.Translate("updater.failedcomm")
			Card.ServiceName.Text = "Administer"
			Card.Logo.Image = Utilities.Icon "administer"
			Card.ServiceRDNN.Text = "org.admsoftware.Core"

			Card.Visible = true

			return
		end

		local Card = Info.UpdateCenter.ScrollingFrame.Card:Clone()

		Card.Parent = Info.UpdateCenter.ScrollingFrame
		Card.Name = Data.Service.Name

		Card.Data.Text = `{Data.IsUpToDate and Utilities.Translate("generic.UpToDate") or Utilities.Translate("generic.OutOfDate")}; {Data.String} installed {Utilities.FormatRelativeTime(Data.InstallDate)}`
		Card.ServiceName.Text = Data.Service.Name
		Card.Logo.Image = Data.Service.Icon
		Card.ServiceRDNN.Text = Data.ID

		Card.Visible = true
	end

	repeat
		Var.Version = Var.Remotes:WaitForChild("GetVersions"):InvokeServer({"administer"})["administer"]

		if Var.DisableOnlineServices then
			Var.Version = {
				IsUpToDate = true,
				IsFail = true
			}
		end

		task.wait(1)
	until Var.Version.IsUpToDate ~= nil

	NewVersCard(Var.Version)

	local Contributors = Var.Remotes.GetContributors:InvokeServer()

	for _, Contrib in Contributors do
		local Card = Info.Credits.Users.Template:Clone()

		Card.Username.Text = Contrib.Name
		Card.Task.Text = Contrib.Job
		pcall(function() --// just incase a user gets banned and i cant remove them
			Card.ImageLabel.Image = game.Players:GetUserThumbnailAsync(Contrib.UserID, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180)
		end)

		Card.Parent = Info.Credits.Users
		Card.Visible = true
	end

	--// We need to do this last because it's a possible failure point so we should load the actual content first
	for _, Pass in Var.Remotes.GetPasses:InvokeServer() do
		local Cloned = Var.MainFrame.Configuration.InfoPage.Donate.Buttons.Temp:Clone()

		Cloned.Label.Text = Pass["price"]
		Cloned.MouseButton1Click:Connect(function()
			IsDonating = true
			Var.Services.MarketplaceService:PromptGamePassPurchase(Var.Services.Players.LocalPlayer, Pass["id"])
		end)
		Cloned.Visible = true
		Cloned.Parent = Var.MainFrame.Configuration.InfoPage.Donate.Buttons

		if Var.Services.MarketplaceService:UserOwnsGamePassAsync(Var.Services.Players.LocalPlayer.UserId, Pass["id"]) then
			Var.MainFrame.Configuration.InfoPage.Donate.ScrollingFrame.Version.Text =
				`Thank you for your support, {Var.Services.Players.LocalPlayer.DisplayName}! Your donation helps ensure future Administer updates for years to come ^^`
		end

		table.insert(Passes, Pass["id"])
	end

	Var.Services.MarketplaceService.PromptGamePassPurchaseFinished:Connect(Utilities.ProcessDono)

	Info.VersionDetails.AdmSoftware.Button.MouseButton1Click:Connect(function()
		Frontend.Popup.new(
			{
				Icon = Utilities.Icon "administer",
				Name = "Administer"
			},
			{
				Primary = Utilities.Icon "administer",
				SubIcon = Utilities.Icon "hammer"
			},
			Utilities.Translate("Configuration.InfoPage.License.About"),
			string.format(Utilities.Translate("Configuration.InfoPage.License"), "2022 - 2025"),
			{
				{
					Text = Utilities.Translate("generic.OK"),
					Icon = Utilities.Icon "check-plain",
					Callback = function(c) c() end
				}
			}
		)
	end)
end, function(a0)
	Utilities.Logging.Warn("Failed to fetch info page assets, assuming this is a permissions issue!", a0)
end)

script.Assets.LocalScript.Enabled = essentialSettings["EnableClickEffects"]

if essentialSettings["ChatCommand"] then
	local Command = Instance.new("TextChatCommand")

	Command.PrimaryAlias = "/adm"
	Command.SecondaryAlias = "/administer"
	Command.Triggered:Connect(Frontend.Open)
	Command.Parent = game.TextChatService.TextChatCommands
end

if KeybindRegisterTimeframe == "safe" then
	Frontend.RegisterPanelKeybind()
end
