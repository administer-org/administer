--// Administer
--// pyxfluff 2022-2025

local SharedLibs = script.Libraries
local Assets = script.Assets
local Modules = script.Modules

local Var = require(Modules.Variables)

local Admins    = require(Modules.Admins)
local Apps      = require(Modules.Apps)
local Frontend  = require(Modules.Frontend)
local Utilities = require(Modules.Utilities)
local Widgets   = require(Modules.Widgets)

local t = Utilities.Translate

Frontend.Close(true)

Var.Version = Var.Remotes:WaitForChild("GetVersions"):InvokeServer({"administer"})["administer"]
Var.Remotes.CheckForUpdates:InvokeServer({ "org.admsoftware.Core" })

task.spawn(Utilities.Heartbeat)

if not pcall(function()
		if script.Parent:GetAttribute("StartID") == nil then error() end
		
		Var.Remotes.Ping:InvokeServer()
	end) then
	Utilities.NewNotification("Administer", "rbxassetid://", "Administer has been incorrectly installed and may not continue loading.", "Startup failed", 999)
	error(`Could not connect to the server, is Administer improperly installed?`)
end


local Debounce = false
Var.Services.UserInputService.InputBegan:Connect(function(KeyCode, IsGameProc)
	if IsGameProc then return end

	if KeyCode.KeyCode == Enum.KeyCode.F2 then
		if Var.Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
			if not Var.IsOpen then
				if Debounce then return end
				Debounce = true
				
				Frontend.Open(true)

				Debounce = false	
			end
			
			Frontend.ToggleFullscreen()
			
			return
		end

		if Debounce then return end
		Debounce = true

		if Var.IsOpen then
			Frontend.Close(false, true)
		else
			Frontend.Open(true)
		end

		Debounce = false
	end
end)

Widgets.Initialize()
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
			Name = Utilities.ToSentenceCase(t("Configuration.Apps.Content.Template.Settings.HeaderLabel")),
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
			Name = t("Configuration.Admins.Container.Admins.Header.TLabel"),
			Icon = Utilities.Icon "user-clip",
			Click = function() end,
			Frame = Var.MainFrame.Configuration.Admins,
			ButtonID = "AdminConfig"
		}
	}
})

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
Frontend.InitGestureBar()

Var.MainFrame.Home.Welcome.Text = `<stroke color="rgb(0,0,0)" transparency = "0.85" thickness="0.4">{string.format(
	t("Welcome.Initial.HeaderLabel") :: string,
	Var.Services.Players.LocalPlayer.DisplayName,
	Utilities.GetSetting("HomepageGreeting")
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

--// Marketplace
xpcall(Apps.Init, function(e)
	Utilities.Logging.Print("[x] Failed to initialize the marketplace, this is likely due to insufficient permissions!")
	Utilities.Logging.Print(e)
end)


xpcall(function()
	Admins.RunCreatorApp()
	Admins.Load()

	Var.MainFrame.Configuration.Admins.Header.NewRank.Activator.MouseButton1Click:Connect(function()
		Var.MainFrame.Configuration.Admins.NewAdmin.Visible = true
	end)

	Var.MainFrame.Configuration.Admins.NewAdmin.Page5.NextPage.MouseButton1Click:Connect(function()
		Var.MainFrame.Configuration.Admins.NewAdmin.Visible = false

		Admins.Load()
	end)
end, function(e)
	error(e)
end)

if Var.Services.UserInputService.TouchEnabled and not Var.Services.UserInputService.KeyboardEnabled then
	Utilities.Logging.Print("Making adjustments to UI (Mobile)")
	Var.Mobile = true

	task.defer(function()
		Utilities.NewNotification(
			"Administer",
			"rbxassetid://12500517462",
			"Mobile mode activated. Swipe inwards from the right edge of your screen to open Administer.",
			"Mobile Beta",
			25
		)
	end)

	Var.MainFrame.Parent
		:WaitForChild("MobileOpen", 10).Hit.TouchSwipe
		:Connect(function(SwipeDirection: Enum.SwipeDirection)
			if SwipeDirection == Enum.SwipeDirection.Left then
				Frontend.Open(true)

				Debounce = true
			end
		end)
else
	Var.Mobile = false

	Var.MainFrame.Parent.MobileOpen:Destroy()
end

local IsDonating = false
local Passes = {}

xpcall(function(...)
	local Info = Var.MainFrame.Configuration.InfoPage

	Info.VersionDetails.Version.Text = Var.Version.NoExtraData .. " " .. Var.Version.Extra

	local function NewVersCard(Data)
		local Card = Info.UpdateCenter.ScrollingFrame.Card:Clone()

		Card.Parent = Info.UpdateCenter.ScrollingFrame
		Card.Name = Data.Service.Name

		Card.Data.Text = `{Data.IsUpToDate and "Up to date" or "Out of date"}; {Data.String} installed {Utilities.FormatRelativeTime(Data.InstallDate)}`
		Card.ServiceName.Text = Data.Service.Name
		Card.Logo.Image = Data.Service.Icon
		Card.ServiceRDNN.Text = Data.ID

		Card.Visible = true
	end
	
	repeat
		task.wait(.1)
		Var.Version = Var.Remotes:WaitForChild("GetVersions"):InvokeServer({"administer"})["administer"]
	until Var.Version.IsUpToDate ~= nil
	
	NewVersCard(Var.Version)
	
	local Contributors = Var.Remotes.GetContributors:InvokeServer()
	
	for _, Contrib in Contributors do
		local Card = Info.Credits.Users.Template:Clone()
		
		Card.Username.Text = Contrib.Name
		Card.Task.Text = Contrib.Job
		Card.ImageLabel.Image = game.Players:GetUserThumbnailAsync(Contrib.UserID, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180)
		
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
end, function(a0)
	Utilities.Logging.Warn("Failed to fetch info page assets, assuming this is a permissions issue!", a0)
end)

script.Assets.LocalScript.Enabled = Utilities.GetSetting("EnableClickEffects")

if Utilities.GetSetting("ChatCommand") == true then
	Var.Services.Players.LocalPlayer.Chatted:Connect(function(m)
		if m == "/adm" then Frontend.Open() end
	end)

	xpcall(function()
		local Command = Instance.new("TextChatCommand")

		Command.PrimaryAlias = "/adm"
		Command.SecondaryAlias = "/administer"
		Command.Triggered:Connect(Frontend.Open)
		Command.Parent = game.TextChatService.TextChatCommands
	end, function()
		Utilities.Logging.Print("TCS is disabled (or something else failed), ignoring custom command for TCS")
	end)
end
