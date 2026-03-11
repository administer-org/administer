--// # Administer #
--// CodingAgent 2026

--// https://github.com/administer-org/Administer

--// The following code is free to use, look at, and modify.
--// Please refrain from modifying core functions as it can break everything.
--// All modifications can be done via apps.

--// WARNING: Use of Administer's codebase for AI training is STRICTLY PROHIBITED and you will face consequences if you do it.
--// Do NOT use this script or any in this model to train your AI or else.

local Core = script.Core
local Modules = script.Modules

local AdminRunner = require(Modules.AdminRunner)
local AppsModule = require(Modules.Apps)
local FrontendAPI = require(Modules.Frontend)
local HttpRunner = require(Modules.HTTPRunner)
local Utils = require(Modules.Utilities)
local Debugging = require(Modules.Debugging)
local SettingsAPI = require(Modules.SettingsAPI)
local PanelRelocator = require(Modules.Helpers.PanelRelocator)
local Importer = require(Modules.Importer)

local Configuration = require(Core.Configuration)
local Types = require(Core.Types)
local Var = require(Core.Variables)

Var.InitClock["LoadModules"] = Utils.RoundMS(os.clock() - Var.InitClock["TempInit"])
Utils.Logging.Print(`[✓] Modules OK in {Utils.RoundMS(os.clock() - Var.InitClock["RealInit"])}ms`)

Var.InitClock.TempInit = os.clock()
Var.Init()

Var.InitClock["InitVars"] = Utils.RoundMS(os.clock() - Var.InitClock["TempInit"])
Utils.Logging.Print(`[✓] Init() OK in {Utils.RoundMS(os.clock() - Var.InitClock["TempInit"])}ms`)

do
	local PanelTemplate = script.Parent.Resources:FindFirstChild("AdministerMainPanel")
	local PanelScripts = script.Parent:FindFirstChild("PanelScripts")

	if PanelTemplate and PanelScripts then
		PanelRelocator(PanelTemplate, PanelScripts)
	else
		Utils.Logging.Warn("[PanelRelocator] Could not find Panel or PanelScripts — skipping source patch.")
	end
end

Var.InitClock.TempInit = os.clock()
xpcall(function()
	Var.IsFirstBoot = (Var.IsFirstBoot or Var.DataStores.Settings:GetAsync("HasInit") == nil and true or false)

	Utils.Logging.Print(
		`[✓] DataStoreService connection established in {Utils.RoundMS(os.clock() - Var.InitClock["TempInit"])}ms`
	)

	local Settings = SettingsAPI.new(Configuration.Settings)

	if Var.IsFirstBoot then
		require(script.Modules.Helpers.BootstrapGame)()
		Settings.Save(1)

		Var.DataStores.Settings:SetAsync("HasInit", true)
	else
		Settings.Load(1)

		Var.SettingsAPI = SettingsAPI.GetController("Administer")
	end
end, function(e)
	Utils.Logging.Warn(e)
	Utils.Logging.Warn(
		`[X] Cannot connect to the DataStoreService. Please ensure Studio APIs are enabled and try again.\n\nIf you need help please reach refer to the Getting Started guide.`
	)
end)

Var.InitClock["LoadSettings"] = Utils.RoundMS(os.clock() - Var.InitClock["TempInit"])
Var.InitClock.TempInit = os.clock()

Utils.Logging.Print("[-] Mounting frontend API..")
Var.InitClock.TempInit = os.clock()

local function NewRemote(
	Name: string,
	AuthRequired: boolean,
	PlayerVar: boolean,
	Cbk: (Player, ...any) -> any
): RemoteFunction | RemoteEvent
	if PlayerVar then
		return Utils.NewRemote("RemoteFunction", Name, AuthRequired, function(Player: Player, ...)
			return Cbk(Player, ...)
		end)
	else
		return Utils.NewRemote("RemoteFunction", Name, AuthRequired, function(_, ...)
			return Cbk(...)
		end)
	end
end

NewRemote("Ping", false, false, function()
	return "PONG"
end)

NewRemote("GetTranslationModule", true, true, function(Player, Locale)
	return require(script.Core.Locales[Locale]) :: any
end)

NewRemote("SendClientLocale", true, true, function(Player, LocaleCode): Types.Response
	Var.CachedLocales[Player.UserId] = LocaleCode

	return { true, "OK" }
end)

NewRemote("DirectTranslate", false, false, Utils.t)
NewRemote("GetLocaleNames", false, false, function()
	local Result = {}

	for _, Locale in script.Core.Locales:GetChildren() do
		Result[Locale.Name] = require(Locale)._locale_display_localized
	end

	return Result
end)

NewRemote("LoadSettings", true, false, function(controllerName, userId, customSettings: Types.SettingsGroup?)
	if not SettingsAPI then
		return false
	end
	local settingController = SettingsAPI.GetController(controllerName)
	if not settingController then
		return false
	end
	return settingController.Load(userId, customSettings)
end)

NewRemote("SaveSettings", true, false, function(controllerName, userId)
	if not SettingsAPI then
		return false
	end
	local settingController = SettingsAPI.GetController(controllerName)
	if not settingController then
		Utils.Logging.Warn("Controller not found")
		return false
	end
	return settingController.Save(userId)
end)

NewRemote("ModifySetting", true, false, function(controllerName, name, value)
	if not SettingsAPI then
		return false
	end
	local settingController = SettingsAPI.GetController(controllerName)
	if not settingController then
		return false
	end

	return settingController.Set(name, value)
end)

NewRemote("GetSettings", true, false, function(controllerName: string, settingsArray: { string })
	if not SettingsAPI then
		return {}
	end
	local controller = SettingsAPI.GetController(controllerName)
	local currentValue = {}

	for _, settingName in settingsArray do
		local value = controller.Get(settingName)
		currentValue[settingName] = value
	end

	return currentValue
end)

NewRemote("GetSetting", true, false, function(controllerName: string, settingName: string)
	if not SettingsAPI then
		return nil
	end
	local controller = SettingsAPI.GetController(controllerName)
	local currentValue = controller.Get(settingName)

	return currentValue
end)

NewRemote("GetRemote", true, false, function(controllerName: string, settingName: string)
	if not SettingsAPI then
		return nil
	end
	local controller = SettingsAPI.GetController(controllerName)
	local remote = controller.GetRemote(settingName)

	return remote
end)

NewRemote("GetAllSettings", true, false, function()
	if not SettingsAPI then
		return {}
	end
	local controllers = SettingsAPI.SettingsList
	local allData = {}
	for i, v in controllers do
		allData[i] = v.GetData()
	end
	return allData
end)

Utils.NewRemote("RemoteEvent", "SettingsLoaded", true, function() end)

Var.RemotesPath.Name = "Administer"

Var.InitClock["LoadRemotes"] = Utils.RoundMS(os.clock() - Var.InitClock["TempInit"])

task.defer(function()
	do
		local ok, result = pcall(function()
			local raw = Var.Services.HttpService:GetAsync("https://api.admsoftware.org/info", true)
			local decoded = Var.Services.HttpService:JSONDecode(raw)
			Var.StaffData = decoded.administer.staff
		end)
		if not ok or not Var.StaffData then
			Utils.Logging.Warn("[StaffFetch] Could not fetch staff from API, using config fallback:", tostring(result))
			Var.StaffData = Configuration.Contributors
		else
			Utils.Logging.Print(`[StaffFetch] Loaded {#Var.StaffData} staff members from API`)
		end
	end

	AppsModule.Initialize()

	AdminRunner.Scan(false)

	local function OnPlayerAdded(Player: Player)
		AdminRunner.PlayerAdded(Player)

		if not Var.DataStoreAvailable then
			task.defer(function()
				local MaxWait = 15
				local Elapsed = 0
				repeat
					task.wait(0.5)
					Elapsed += 0.5
				until Player.PlayerGui:FindFirstChild("AdministerMainPanel") ~= nil or Elapsed >= MaxWait

				if Player.PlayerGui:FindFirstChild("AdministerMainPanel") == nil then
					return
				end

				Utils.NewNotification(
					Player,
					"DataStoreService is unavailable. All data will not persist this session. To fix this, publish your game or enable Studio Access to API Services under Game Settings → Security.",
					"DataStore Unavailable",
					Utils.Icon("triangle-warning"),
					30,
					Var.Notification.Ding,
					{}
				)
			end)
		end
	end

	Var.Services.Players.PlayerAdded:Connect(OnPlayerAdded)
	Var.Services.Players.PlayerRemoving:Connect(function(Player: Player)
		AdminRunner.Removing(Player)
	end)

	Var.InitClock["BootstrapApps"] = Utils.RoundMS(os.clock() - Var.InitClock["TempInit"])
	Utils.Logging.Print(`[✓] OK in {Utils.RoundMS(os.clock() - Var.InitClock["TempInit"])}ms`)
end)

local function NewRemote(
	Name: string,
	AuthRequired: boolean,
	PlayerVar: boolean,
	Cbk: (Player, ...any) -> any
): RemoteFunction | RemoteEvent
	if PlayerVar then
		return Utils.NewRemote("RemoteFunction", Name, AuthRequired, function(Player: Player, ...)
			return Cbk(Player, ...)
		end)
	else
		return Utils.NewRemote("RemoteFunction", Name, AuthRequired, function(_, ...)
			return Cbk(...)
		end)
	end
end

NewRemote("UpdateHomePage", true, true, FrontendAPI.UpdateHomePage)

NewRemote("GetVersions", true, true, function(Player, Services)
	local Final = {}

	for _, Service in Services do
		if Service == "administer" then
			Final["administer"] = Configuration.VersData
		end
	end

	return Final
end)

NewRemote("GetPasses", false, false, function()
	local Attempts, _Content = 0, ""

	repeat
		local Success, Error = pcall(function()
			Attempts += 1
			_Content = Var.Services.HttpService:GetAsync(
				`https://proxy.CodingAgent.dev/games/v1/games/2208062007/game-passes?sortOrder=Asc&limit=50`,
				true
			)
		end)
	until Success or Attempts > 5

	local ok, decoded = pcall(function()
		return Var.Services.HttpService:JSONDecode(_Content)
	end)

	return (ok and decoded and decoded["data"])
		or {
			{
				price = "Failed to load.",
				id = 0,
			},
			{
				price = "Your proxy may be offline.",
				id = 0,
			},
		}
end)

NewRemote("CheckForUpdates", true, false, Utils.UpdateCallback)
NewRemote("GetSystemClock", false, false, os.time)
NewRemote("GetGameArt", false, false, Utils.GetGameIcon)
NewRemote("GetGameMedia", true, false, Utils.GetGameMedia)
NewRemote("GetServerRegion", true, false, Utils.GetServerRegion)
NewRemote("FilterString", true, true, Utils.GetFilteredString)
NewRemote("HasSeenTutorial", true, true, Utils.HasSeenTutorial)
NewRemote("TutorialSeen", true, true, Utils.TutorialSeen)
NewRemote("GetImports", true, true, Importer.ListFoundSystems)
NewRemote("PerformImport", true, true, Importer.Import)

NewRemote("GetProminentColorFromUserID", false, true, function(Player)
	return Utils.GetProminentColor(Player.UserId)
end)

NewRemote("GetIconPack", false, false, function()
	return require(script.Core.Icons)
end)

NewRemote("GetContributors", false, false, function()
	return Var.StaffData
end)

NewRemote("GetAppList", true, false, function(QueryType)
	return AppsModule.ServerAPI.GetList(nil, QueryType)
end)

NewRemote("GetAppInfo", true, false, AppsModule.ServerAPI.GetApp)
NewRemote("GetInstalledApps", true, false, AppsModule.GetAll)
NewRemote("InstallApp", true, true, function(Player: Player, ServerURL: string, AppID: string)
	local Result = AppsModule.ServerAPI.InstallFromServer(ServerURL, AppID)

	if not Result[1] then
		return Result
	end

	local newAppName, newIcon, newFrameName = nil, nil, nil

	local LivePanel = Player.PlayerGui:FindFirstChild("AdministerMainPanel")
	local livePanelMain = LivePanel and LivePanel:FindFirstChild("Main")

	for appName, RunningApp in AppsModule.RunningApps do
		if RunningApp.ClientFrameName then
			local frameExists = livePanelMain and livePanelMain:FindFirstChild(RunningApp.ClientFrameName)
			if not frameExists then
				local TemplateFrame = Var.Panel.Path.Main:FindFirstChild(RunningApp.ClientFrameName)
				if TemplateFrame and livePanelMain then
					TemplateFrame:Clone().Parent = livePanelMain
				end
				newFrameName = RunningApp.ClientFrameName
				newAppName = RunningApp.Name
				newIcon = RunningApp.Icon
				break
			end
		end
	end

	return { true, Result[2], newAppName, newIcon, newFrameName }
end)
NewRemote("Vote", true, false, AppsModule.ServerAPI.Vote)
NewRemote("ManageApp", true, false, AppsModule.Uninstall)
NewRemote("GetAppServers", true, false, AppsModule.ServerAPI.GetServerStatuses)
NewRemote("RemoveAppServer", true, false, AppsModule.ServerAPI.UninstallServer)
NewRemote("GetAppCounts", true, false, AppsModule.GetTotals)
NewRemote("AOSRichSearch", true, false, AppsModule.ServerAPI.Search)
NewRemote("GetAOSInstances", true, false, AppsModule.ServerAPI.GetAOSInstances)
if not Var.RemotesPath:FindFirstChild("AppLifecycle") then
	Utils.NewRemote("RemoteEvent", "AppLifecycle", false, function() end)
end
NewRemote("RegisterPrimaryAOS", true, false, AppsModule.ServerAPI.RegisterPrimary)
NewRemote("InstallServer", true, false, AppsModule.ServerAPI.New)
NewRemote("GetPrimaryServer", true, false, AppsModule.ServerAPI.GetPrimaryServer)

NewRemote("SetPrimaryAppServer", true, false, function(ServerURL: string)

	local IsGateway = string.find(ServerURL, "gateway") or string.find(ServerURL, "gate")

	Utils.Logging.Print(`[GatewayDetect] SetPrimaryAppServer called with {ServerURL}`)
	Utils.Logging.Print(`[GatewayDetect] IsGateway detection -> {tostring(IsGateway ~= nil)}`)
	Utils.Logging.Print(`[GatewayDetect] AppServers count -> {#Var.AppServers}`)

	if IsGateway then
		local BestServer = nil
		local LowestPing = math.huge

		for _, Server in Var.AppServers do
			local ServerPing = tonumber(Server.Ping) or 5000
			Utils.Logging.Print(
				`[GatewayDetect] Candidate: {Server.ServerURL} is_up={tostring(Server.IsUp)} ping={tostring(ServerPing)}`
			)
			if Server.IsUp and ServerPing < LowestPing then
				LowestPing = ServerPing
				BestServer = Server
			end
		end

		if BestServer then
			Utils.Logging.Print(
				`[GatewayDetect] BestServer chosen -> {BestServer.ServerURL} ping={tostring(LowestPing)}`
			)
			for _, Server in Var.AppServers do
				Server.IsPrimary = (Server.ServerURL == BestServer.ServerURL)
			end
			Var.PrimaryAppServer = BestServer.ServerURL
		else
			Utils.Logging.Warn("[GatewayDetect] No available AOS instances found while selecting gateway fallback")
		end
	else
		Utils.Logging.Print(`[GatewayDetect] Setting explicit primary -> {ServerURL}`)
		for _, Server in Var.AppServers do
			if Server.ServerURL == ServerURL then
				Server.IsPrimary = true
			elseif Server.IsPrimary then
				Server.IsPrimary = false
			end
		end
		Var.PrimaryAppServer = ServerURL
	end

	Var.DataStores.AppDB:SetAsync("AppServerList", Var.AppServers)

	return { true, "Primary server updated" }
end)

NewRemote("CompleteFirstTimeSetup", true, false, function(Mode: string)
	local GatewayURL = Var.DefaultAppServer
	local TargetURL = (Mode == "automatic") and GatewayURL or Mode

	if TargetURL ~= GatewayURL then
		local AddResult = AppsModule.ServerAPI.New(TargetURL, 1)
		if not AddResult[1] then
			return { false, "Could not reach the custom AOS. Make sure the URL is correct and the server is online." }
		end

		AppsModule.ServerAPI.UninstallServer(GatewayURL, false)

		AppsModule.ServerAPI.RegisterPrimary(TargetURL, false)

		Utils.Logging.Print(`[Setup] Custom AOS registered and set as primary: {TargetURL}`)
	else
		Utils.Logging.Print("[Setup] Automatic setup confirmed - gateway.admsoftware.org is already primary.")
	end

	return { true, "Setup complete!" }
end)

NewRemote("GetRanks", true, false, AdminRunner.Ranks.GetAll)
NewRemote("NewRank", true, false, AdminRunner.Ranks.New)
NewRemote("CanUseApp", true, true, AdminRunner.CanUseApp)
NewRemote("GetRank", true, false, function(Rankname)
	return Var.DataStores.AdminsDS:GetAsync(Rankname)
end)

Var.InitClock["LoadRemotes"] = Utils.RoundMS(os.clock() - Var.InitClock["TempInit"])
Utils.Logging.Print(`[✓] OK in {Utils.RoundMS(os.clock() - Var.InitClock["TempInit"])}s`)
Utils.Logging.Print(
	`\n
	"\n		> Ready in ",
	Utils.RoundMS(os.clock() - Var.InitClock.RealInit) .. "ms",
	"\n		> Apps thread: ",
	Var.DidBootstrap and "done" or "proc",
	"\n		> Using AOS: ",
	Var.PrimaryAppServer,
	"\n		> Startup information:",
	Var.InitClock,
	"\n		> Environment:",
	Var,
	Var.EnableFreeAdmin and "\n		> [!] Free admin is enabled, you should probably disable it for a production game."
		or "",
	Var.IsFirstBoot and "\n		> [!] First boot mode is enabled!" or ""
)
Utils.Logging.Print(`[-] Running startup jobs!`)

xpcall(function()
	if not Utils.GetSetting("LiveUpdate") then
		return
	end

	Var.Services.MessagingService:SubscribeAsync("Administer", AdminRunner.Socket)
end, function()
	Utils.Logging.Warn(
		"[thread Admins] MessagingService seems to be busy (did not bind on message Administer), some cross-server features disabled!"
	)
end)

if Var.PrimaryAppServer ~= nil and Var.PrimaryAppServer ~= "" then
	HttpRunner.GetRoute(Var.PrimaryAppServer, "/api/ping", function(...) end, function(...)
		Utils.Logging.Warn(...)
	end)

	HttpRunner.PostRoute(Var.PrimaryAppServer, "/api/report-version", {
		version = Configuration.VersData.NoExtraData,
		branch = Var.CurrentBranch["BranchName"],
	}, function(...)
		return { ... }
	end, function(...)
		Utils.Logging.SWarn(...)
		return { ... }
	end)
end

Configuration.VersData.InstallDate = Utils.CheckVersion()
do
	local _updateData = Utils.UpdateCallback({ "org.admsoftware.Core" })
	local _coreData = _updateData["org.admsoftware.Core"]
	Configuration.VersData.IsUpToDate = not (
		_coreData
		and not _coreData.IsError
		and _coreData.your_version
		and _coreData.your_version.is_outdated
	)
end

Utils.Logging.Print(`[✓] Startup complete!`)
