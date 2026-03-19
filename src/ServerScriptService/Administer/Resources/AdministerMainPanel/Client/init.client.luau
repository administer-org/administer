--// Administer
--// CodingAgent 2022-2026

local SharedLibs = script.Libraries
local Assets = script.Assets
local Modules = script.Modules

local Var = require(Modules.Variables)

task.spawn(function()
	for _, effect in ipairs(game.Lighting:GetChildren()) do
		if effect:IsA("BlurEffect") then
			effect.Size = 0
		end
	end
end)

game.Lighting.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("BlurEffect") then
		descendant.Size = 0
	end
end)

local Admins = require(Modules.Admins)
local Apps = require(Modules.Apps)
local Frontend = require(Modules.Frontend)
local Utilities = require(Modules.Utilities)
local Widgets = require(Modules.Widgets)

local t = Utilities.Translate

Frontend.Close(true)

pcall(function()
	require(script.Parent.Relocator)()
end)

local function CacheSettings()
	local settingData = Utilities.GetSettings({ "AnimationSpeed", "ShortNumberDecimals", "Verbosity" })

	Var.AnimationSpeed = tonumber(settingData["AnimationSpeed"])
	Var.ShortNumberDecimals = tonumber(settingData["ShortNumberDecimals"])
	Var.Verbosity = settingData["Verbosity"]

	return true
end

local success, errormsg = pcall(function()
	if script.Parent:GetAttribute("StartID") == nil then
		local elapsed = 0
		repeat
			task.wait(0.1)
			elapsed += 0.1
		until script.Parent:GetAttribute("StartID") ~= nil or elapsed >= 10

		if script.Parent:GetAttribute("StartID") == nil then
			error("StartID attribute was never set — panel may not have been bootstrapped correctly")
		end
	end

	Var.Remotes:WaitForChild("Ping", 15):InvokeServer()

	CacheSettings()

	Var.Remotes:WaitForChild("SettingsLoaded", 15).OnClientEvent:Connect(CacheSettings)
end)

if not success then
	print(errormsg)
	local _ok, notifBody = pcall(Utilities.Translate, "error.NoPing")
	if not _ok then
		notifBody = "Could not connect to Administer."
	end
	Utilities.NewNotification("Administer", "", notifBody, "Startup failed", 999)

	error(`Could not connect to the server, is Administer improperly installed?`)
end

local function DoUpdate()
	Var.FinishedUpdate = false

	Var.Version = Var.Remotes:WaitForChild("GetVersions"):InvokeServer({ "administer" })["administer"]
	Var.Remotes.CheckForUpdates:InvokeServer({ "org.admsoftware.Core" })

	Var.FinishedUpdate = true
end

local Thread = task.defer(DoUpdate)
task.delay(5, function()
	if not Var.FinishedUpdate then
		Var.DisableOnlineServices = true

		Utilities.NewNotification(
			"Administer",
			Utilities.Icon("triangle-warning"),
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

Var.Remotes:WaitForChild("SettingsLoaded", 15).OnClientEvent:Wait()

local essentialSettings = Utilities.GetSettings({
	"KeybindRegisterTime",
	"HomepageGreeting",
	"AssistiveClose",
	"EnableClickEffects",
	"ChatCommand",
	"ForceMobile",
	"ForceAcrylic",
})
local KeybindRegisterTimeframe = essentialSettings.KeybindRegisterTime

Var.Mobile = essentialSettings.ForceMobile == true
Var.UseAcrylic = essentialSettings.ForceAcrylic == true

if KeybindRegisterTimeframe == "optimistic" then
	Frontend.RegisterPanelKeybind()
end

if Var.UseAcrylic then
	local NewEffect = Instance.new("DepthOfFieldEffect")
	NewEffect.FarIntensity = 0
	NewEffect.FocusDistance = 51.6
	NewEffect.InFocusRadius = 50
	NewEffect.NearIntensity = 1

	NewEffect.Parent = game.Lighting
	NewEffect.Name = "AdministerAcrylic"
end

Widgets.Initialize()

task.defer(function()
	Apps.AddAppDrawerButton({
		AppName = t("Apps.MainFrame.Home.Title"),
		Description = t("Apps.MainFrame.Template.Desc"),
		Icon = Utilities.Icon("home"),
		ButtonID = "AdmHomepage",
		IsBuiltIn = true,

		MainButtonClick = function() end,
		MainButtonFrame = Var.MainFrame.Home,

		SubIcons = {},
	})

	Var.MainFrame.Header.Mark.AppLogo.AppIcon.Image = Utilities.Icon("home")
	Var.MainFrame.Header.Mark.HeaderLabel.Text = `<b>Administer</b> · {t("Apps.MainFrame.Home.Title")}`

	Apps.AddAppDrawerButton({
		AppName = t("Apps.MainFrame.Config.Title"),
		Description = t("Apps.MainFrame.Config.Desc"),
		Icon = Utilities.Icon("media"),
		ButtonID = "AdmConfiguration",
		IsBuiltIn = true,

		SubIcons = {
			{
				Name = t("Configuration.MenuBar.New.AInfoPage.HeaderLabel"),
				Icon = Utilities.Icon("info"),
				Click = function() end,
				Frame = Var.MainFrame.Configuration.InfoPage,
				ButtonID = "Information",
			},
			{
				Name = Utilities.ToSentenceCase(t("Apps.MainFrame.Config.Title")),
				Icon = Utilities.Icon("gear"),
				Click = function() end,
				Frame = Var.MainFrame.Configuration.Settings,
				ButtonID = "Settings",
			},
			{
				Name = Utilities.ToSentenceCase(t("Header.AppDrawer.HeaderLabel")),
				Icon = Utilities.Icon("grid"),
				Click = Apps.LoadAppList,
				Frame = Var.MainFrame.Configuration.Marketplace,
				ButtonID = "Marketplace",
			},
			{
				Name = t("Configuration.Admins.Container.Ranks.Header.TLabel"),
				Icon = Utilities.Icon("user-clip"),
				Click = function() end,
				Frame = Var.MainFrame.Configuration.Admins,
				ButtonID = "AdminConfig",
			},
		},
	})

	Frontend.PrepTheme()

end)

local function waitForHome(retries, interval)
	retries = retries or 10
	interval = interval or 0.2
	for i = 1, retries do
		local h = Var.MainFrame:FindFirstChild("Home")
		if h and h:IsA("Frame") then
			return h
		end
		task.wait(interval)
	end
	return Var.MainFrame:FindFirstChild("Home")
end

local Home = waitForHome(10, 0.2)
if Home and Home:IsA("Frame") then
	if Home:FindFirstChild("Widget1") and Home.Widget1:FindFirstChild("Edit") then
		Home.Widget1.Edit.MouseButton1Click:Connect(function()
			Widgets.Edit(Home.Widget1)
		end)
	end

	if Home:FindFirstChild("Widget2") and Home.Widget2:FindFirstChild("Edit") then
		Home.Widget2.Edit.MouseButton1Click:Connect(function()
			Widgets.Edit(Home.Widget2)
		end)
	end

	if Var.MainFrame:FindFirstChild("Header") and Var.MainFrame.Header:FindFirstChild("Mark") then
		local Mark = Var.MainFrame.Header.Mark
		if Mark.AppLogo then
			Mark.AppLogo.MouseButton1Click:Connect(Frontend.Drawer.Open)
			Mark.AppLogo.MouseEnter:Connect(Frontend.Drawer.HoverBegin)
			Mark.AppLogo.MouseLeave:Connect(Frontend.Drawer.HoverEnd)
		end
	end

	Frontend.SpawnOverlay(Var.MainFrame)

	Home.Welcome.Text = `<stroke color="rgb(0,0,0)" transparency = "0.85" thickness="0.4">{string.format(
		t("Welcome.Initial.HeaderLabel") :: string,
		Var.Services.Players.LocalPlayer.DisplayName,
		essentialSettings["HomepageGreeting"]
	)}</stroke>`

	Home.PlayerImage.Image = Var.Services.Players:GetUserThumbnailAsync(
		Var.Services.Players.LocalPlayer.UserId,
		Enum.ThumbnailType.HeadShot,
		Enum.ThumbnailSize.Size352x352
	)

	if Var.MainFrame:FindFirstChild("AppDrawer") and Var.MainFrame.AppDrawer:FindFirstChild("PlayerData") then
		local PD = Var.MainFrame.AppDrawer.PlayerData
		PD.DisplayName.Text = Var.Services.Players.LocalPlayer.DisplayName
		PD.Rank.Text =
			`{Var.MainFrame.Parent:GetAttribute("_AdminRank")} · {#Var.MainFrame.AppDrawer.AppHolder.Apps:GetChildren() - 4} apps`
		if PD:FindFirstChild("PlayerImage") then
			PD.PlayerImage.Image = Var.Services.Players:GetUserThumbnailAsync(
				Var.Services.Players.LocalPlayer.UserId,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size352x352
			)
		end
	end

	task.defer(function()
		local ok, PromColor = pcall(function()
			return Var.Remotes.GetProminentColorFromUserID:InvokeServer(Var.Services.Players.LocalPlayer.UserId)
		end)

		if ok and PromColor and Home:FindFirstChild("Gradient2") and Home.Gradient2:FindFirstChild("ImageLabel") then
			Home.Gradient2.ImageLabel.ImageColor3 = Color3.fromRGB(PromColor[1], PromColor[2], PromColor[3])
		end
	end)
else
	Utilities.Logging.Warn("MainFrame.Home not found after wait; skipping homepage bindings")
end

if script.Parent:GetAttribute("NeedsSetup") then
	Utilities.Logging.Print("Setup is not complete, entering lockdown mode!")

	Var.DoHeaderEffects = false

	Frontend.SwapAppBasic(Var.MainFrame.Welcome, {
		Name = "Setup",
		Icon = Utilities.Icon("sparkles"),
	})

	require(script.Modules.Helpers.FirstTimeSetup)()

	Frontend.Open()
end

task.defer(function()
	xpcall(Apps.Init, function(e)
		Utilities.Logging.Print(
			"[x] [thread Apps] Failed to initialize the marketplace, this is likely due to insufficient permissions!",
			e
		)
	end)
end)

xpcall(function()
	task.defer(function()
		pcall(Admins.Load)
	end)

	Var.MainFrame.Configuration.Admins.Header.NewRank.Server.Text = t("Configuration.Admins.NewAdmin.Start")

	Admins.RunCreatorApp()

	Var.MainFrame.Configuration.Admins.Header.NewRank.MouseButton1Click:Connect(function()
		Admins.OpenCreator()
	end)

	Var.MainFrame.Configuration.Admins.Header.NewRank.MouseButton2Click:Connect(function()
		Frontend.Popup.new(
			{
				Icon = Utilities.Icon("administer"),
				Name = "Administer",
				Subheader = "RankCreator Debug Info",
			},
			{},
			"Admin Debug Table",
			game:GetService("HttpService"):JSONEncode(Admins.GetEditState()),
			{
				{
					Text = "OK",
					Icon = Utilities.Icon("check-plain"),
					Callback = function(e)
						e()
					end,
				},
			}
		)
	end)
end, function(e)
	Utilities.Logging.Warn(`[x] [thread Admins] {e}`)
end)

if Var.Services.UserInputService.TouchEnabled and not Var.Services.UserInputService.KeyboardEnabled or Var.Mobile then
	Utilities.Logging.Print("Mobile mode has been enabled!")
	Var.Mobile = true

	task.defer(function()
		Utilities.NewNotification(
			"Administer",
			Utilities.Icon("iphone-notch"),
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

	Var.MainFrame.Configuration.Marketplace.MainMarketplace.InstallBox.MainContent.MainContent.MetadataBox.UIGridLayout.CellSize =
		UDim2.fromOffset(150, 115)
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
	repeat
		task.wait()
	until Var.MainFrame:FindFirstChild("Header")

	local Info = Var.MainFrame.Configuration.InfoPage

	Info.VersionDetails.Version.Text = Var.Version.NoExtraData .. " " .. Var.Version.Extra

	local function NewVersCard(Data)
		if Data.IsFail then
			local Card = Info.UpdateCenter.ScrollingFrame.Card:Clone()

			Card.Parent = Info.UpdateCenter.ScrollingFrame
			Card.Name = "Administer"

			Card.Data.Text = Utilities.Translate("updater.failedcomm")
			Card.ServiceName.Text = "Administer"
			Card.Logo.Image = Utilities.Icon("administer")
			Card.ServiceRDNN.Text = "org.admsoftware.Core"

			Card.Visible = true

			return
		end

		local Card = Info.UpdateCenter.ScrollingFrame.Card:Clone()

		Card.Parent = Info.UpdateCenter.ScrollingFrame
		Card.Name = Data.Service.Name

		Card.Data.Text = `{Data.IsUpToDate and Utilities.Translate("generic.UpToDate") or Utilities.Translate(
			"generic.OutOfDate"
		)}; {Data.String} installed {Utilities.FormatRelativeTime(Data.InstallDate)}`
		Card.ServiceName.Text = Data.Service.Name
		Card.Logo.Image = Data.Service.Icon
		Card.ServiceRDNN.Text = Data.ID

		Card.Visible = true
	end

	local ok, versionRes = pcall(function()
		return Var.Remotes:WaitForChild("GetVersions"):InvokeServer({ "administer" })
	end)

	if ok and versionRes and versionRes["administer"] then
		Var.Version = versionRes["administer"]
	elseif Var.DisableOnlineServices then
		Var.Version = {
			IsUpToDate = true,
			IsFail = true,
		}
	else
		Var.Version = {
			IsUpToDate = true,
			IsFail = false,
			NoExtraData = "?",
			Extra = "",
		}
	end

	NewVersCard(Var.Version)

	local okContrib, Contributors = pcall(function()
		return Var.Remotes.GetContributors:InvokeServer()
	end)

	if not okContrib or not Contributors then
		Utilities.Logging.Warn("[InfoPage] Failed to fetch contributors", Contributors)
		Contributors = {}
	end

	for _, Contrib in pairs(Contributors) do
		local Card = Info.Credits.Users.Template:Clone()

		Card.Username.Text = Contrib.Name
		Card.Task.Text = Contrib.Job
		pcall(function()
			Card.ImageLabel.Image = game.Players:GetUserThumbnailAsync(
				Contrib.UserID,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size180x180
			)
		end)

		Card.Parent = Info.Credits.Users
		Card.Visible = true
	end

	Var.MainFrame.Configuration.InfoPage.Donate.ScrollingFrame.Version.Text =
		Utilities.Translate("Configuration.InfoPage.Donate.Message")

	for _, Pass in Var.Remotes.GetPasses:InvokeServer() do
		local Cloned = Var.MainFrame.Configuration.InfoPage.Donate.Buttons.Temp:Clone()

		Cloned.Label.Text = Pass["price"]
		Cloned.Visible = true
		Cloned.Parent = Var.MainFrame.Configuration.InfoPage.Donate.Buttons
		Cloned.MouseButton1Click:Connect(function()
			IsDonating = true
			Var.Services.MarketplaceService:PromptGamePassPurchase(Var.Services.Players.LocalPlayer, Pass["id"])
		end)

		if
			Var.Services.MarketplaceService:UserOwnsGamePassAsync(Var.Services.Players.LocalPlayer.UserId, Pass["id"])
		then
			Var.MainFrame.Configuration.InfoPage.Donate.ScrollingFrame.Version.Text =
				string.format(Utilities.Translate("donations.Done"), game.Players.LocalPlayer.DisplayName)
		end

		table.insert(Passes, Pass["id"])
	end

	Var.Services.MarketplaceService.PromptGamePassPurchaseFinished:Connect(Utilities.ProcessDono)

	Info.VersionDetails.AdmSoftware.Button.MouseButton1Click:Connect(function()
		Frontend.Popup.new(
			{
				Icon = Utilities.Icon("administer"),
				Name = "Administer",
			},
			{
				Primary = Utilities.Icon("administer"),
				SubIcon = Utilities.Icon("hammer"),
			},
			Utilities.Translate("Configuration.InfoPage.License.About"),
			string.format(Utilities.Translate("Configuration.InfoPage.License"), "2022 - 2026"),
			{
				{
					Text = Utilities.Translate("generic.OK"),
					Icon = Utilities.Icon("check-plain"),
					Callback = function(c)
						c()
					end,
				},
			}
		)
	end)
end, function(a0)
	Utilities.Logging.Debug("Failed to fetch info page assets, assuming this is a permissions issue!", a0)
end)

if essentialSettings.ChatCommand then
	local Command = Instance.new("TextChatCommand")

	Command.PrimaryAlias = "/adm"
	Command.SecondaryAlias = "/administer"
	Command.Triggered:Connect(Frontend.Open)
	Command.Parent = game.TextChatService.TextChatCommands
end

if essentialSettings.EnableClickEffects then
	for _, Button in Var.MainFrame:GetDescendants() do
		if Button:IsA("TextButton") or Button:IsA("ImageButton") then
			Frontend.AddButtonAnimation(Button)
		end
	end

	Var.MainFrame.DescendantAdded:Connect(function(Instance)
		if Instance:IsA("TextButton") or Instance:IsA("ImageButton") then
			Frontend.AddButtonAnimation(Instance)
		end
	end)
end

pcall(function()
	Var.MainFrame.Configuration.Marketplace.ASidebar.Head.Text =
		Utilities.Translate("Configuration.Marketplace.Header.Head")
	Var.MainFrame.Configuration.Marketplace.ASidebar.Buttons.AAFeatured.Title.Text =
		Utilities.Translate("apps.sidebar.Featured")
	Var.MainFrame.Configuration.Marketplace.ASidebar.Buttons.Apps.Title.Text =
		Utilities.Translate("Configuration.Marketplace.Header.Plugins")
	Var.MainFrame.Configuration.Marketplace.ASidebar.Buttons.XLibrary.Resources.Content.Title.Text =
		Utilities.Translate("apps.sidebar.Library")
	Var.MainFrame.Configuration.Marketplace.ASidebar.Searchbar.Title.Text =
		Utilities.Translate("Configuration.Marketplace.Searchbar.Searchbar.Label")
	Var.MainFrame.Configuration.Marketplace.MainMarketplace.AAFeatured.Head.Text =
		Utilities.Translate("apps.featured.TopInstalled")
	Var.MainFrame.Configuration.Marketplace.MainMarketplace.AAFeatured.MainHot.HotLabel.Title.Text =
		Utilities.Translate("apps.Hot")
	Var.MainFrame.Configuration.Marketplace.MainMarketplace.XLibrary.Head.Text =
		Utilities.Translate("apps.library.Header")
	Var.MainFrame.Configuration.Marketplace.MainMarketplace.XLibrary.SubHeader.Text =
		Utilities.Translate("apps.library.Subheader")
	Var.MainFrame.Configuration.Marketplace.MainMarketplace.XLibrary.InstallAOSInstance.LogoWordmark.Text =
		Utilities.Translate("apps.InstallServer")

	Var.MainFrame.Configuration.Admins.Header.Head.Text =
		Utilities.Translate("Configuration.Admins.Container.Ranks.Header.TLabel")
	Var.MainFrame.Configuration.Admins.Header.Subheader.Text =
		Utilities.Translate("Configuration.Admins.Container.Ranks.Subheader")

	Var.MainFrame.Configuration.InfoPage.VersionDetails.AdmSoftware.Text =
		Utilities.Translate("Configuration.InfoPage.License.Prompt")
	Var.MainFrame.Configuration.InfoPage.UpdateCenter.TextLogo.Text =
		Utilities.Translate("Configuration.InfoPage.VersionDetails.Header")
	Var.MainFrame.Configuration.InfoPage.UpdateCenter.CreditHeader.Text =
		Utilities.Translate("Configuration.InfoPage.VersionDetails.Updated")
	Var.MainFrame.Configuration.InfoPage.UpdateCenter.Temp.Label.Text =
		Utilities.Translate("Configuration.InfoPage.VersionDetails.Update")
	Var.MainFrame.Configuration.InfoPage.Donate.TextLogo.Text =
		Utilities.Translate("Configuration.InfoPage.Donate.title")
	Var.MainFrame.Configuration.InfoPage.Credits.TextLogo.Text =
		Utilities.Translate("Configuration.InfoPage.Credits.title")
end)

if KeybindRegisterTimeframe == "safe" then
	Frontend.RegisterPanelKeybind()
end
