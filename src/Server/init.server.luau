--// # Administer #
--// pyxfluff 2024 - 2025

--// https://github.com/administer-org/Administer

--// The following code is free to use, look at, and modify. 
--// Please refrain from modifying core functions as it can break everything.
--// All modifications can be done via apps.

--// WARNING: Use of Administer's codebase for AI training is STRICTLY PROHIBITED and you will face consequences if you do it.
--// Do NOT use this script or any in this model to train your AI or else.

local Core           = script.Core
local Modules        = script.Modules

local AdminRunner    = require(Modules.AdminRunner)
local AppsModule     = require(Modules.Apps)
local FrontendAPI    = require(Modules.Frontend)
local HttpRunner     = require(Modules.HTTPRunner)
local Utils          = require(Modules.Utilities)
local Debugging      = require(Modules.Debugging)
local SettingsAPI    = require(Modules.SettingsAPI)
local Migrator       = require(Modules.Helpers.AdmV1Migrator)
local Importer       = require(Modules.Importer)

local Configuration  = require(Core.Configuration)
local Types          = require(Core.Types)
local Var            = require(Core.Variables)

Var.InitClock["LoadModules"] = Utils.RoundMS(os.clock() - Var.InitClock["TempInit"])
Utils.Logging.Print(`[✓] Modules OK in {Utils.RoundMS(os.clock() - Var.InitClock["RealInit"])}ms`)

Var.InitClock.TempInit = os.clock()
Var.Init()

Var.InitClock["InitVars"] = Utils.RoundMS(os.clock() - Var.InitClock["TempInit"])
Utils.Logging.Print(`[✓] Init() OK in {Utils.RoundMS(os.clock() - Var.InitClock["TempInit"])}ms`)

Var.InitClock.TempInit = os.clock()
xpcall(function()
	Var.IsFirstBoot = (Var.IsFirstBoot or Var.DataStores.Settings:GetAsync("HasInit") == nil and true or false)

	Utils.Logging.Print(`[✓] DataStoreService connection established in {Utils.RoundMS(os.clock() - Var.InitClock["TempInit"])}ms`)

	local Settings = SettingsAPI.new(Configuration.Settings)

	if Migrator.CheckForV1() then
		Utils.Logging.Print("[-] Administer has detected a live Administer 1.x install! Attempting to migrate..")
		Migrator.Migrate()

		Var.IsFirstBoot = false
	else
		Utils.Logging.Print("V1 Installation not found!")
	end

	if Var.IsFirstBoot then
		require(script.Modules.Helpers.BootstrapGame)()
		Settings.Save(1)

		--// This system is better than the old one because it allows the user
		--// to uninstall AOS without causing the system to overwrite stuff
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

task.defer(function()
	AppsModule.Initialize()

	AdminRunner.Scan(false)
	Var.Services.Players.PlayerAdded:Connect(AdminRunner.PlayerAdded)

	Var.InitClock["BootstrapApps"] = Utils.RoundMS(os.clock() - Var.InitClock["TempInit"])
	Utils.Logging.Print(`[✓] OK in {Utils.RoundMS(os.clock() - Var.InitClock["TempInit"])}ms`)
end)

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

--// Translation routes
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

--// Homepage
NewRemote("UpdateHomePage", true, true, FrontendAPI.UpdateHomePage)

--// Utilities
NewRemote("GetVersions", true, true, function(Player, Services)
	local Final = {}

	for _, Service in Services do
		--// BIG TODO here
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
				`https://proxy.pyxfluff.dev/games/v1/games/1778091660/game-passes?sortOrder=Asc&limit=50`,
				true
			)
		end)
	until Success or Attempts > 5

	return Var.Services.HttpService:JSONDecode(_Content)["data"]
		or {
			{
				price = "Failed to load.",
				id = 0
			},
			{
				price = "Your proxy may be offline.",
				id = 0
			}
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
	return Configuration.Contributors
end)

--// Apps
NewRemote("GetAppList", true, false, function(QueryType)
	return AppsModule.ServerAPI.GetList(nil, QueryType)
end)

NewRemote("GetAppInfo", true, false, AppsModule.ServerAPI.GetApp)
NewRemote("GetInstalledApps", true, false, AppsModule.GetAll)
NewRemote("GetApplicableThemes", true, false, AppsModule.GetApplicableThemes)
NewRemote("InstallApp", true, true, AppsModule.ServerAPI.InstallFromServer)
NewRemote("Vote", true, false, AppsModule.ServerAPI.Vote)
NewRemote("GetVote", true, false, AppsModule.ServerAPI.GetVote)
NewRemote("ManageApp", true, false, AppsModule.Uninstall)
NewRemote("ManageTheme", true, true, AppsModule.ModifyThemePreference)
NewRemote("GetAppServers", true, false, AppsModule.ServerAPI.GetServerStatuses)
NewRemote("RemoveAppServer", true, false, AppsModule.ServerAPI.UninstallServer)
NewRemote("GetAppCounts", true, false, AppsModule.GetTotals)
NewRemote("AOSRichSearch", true, false, AppsModule.ServerAPI.Search)
NewRemote("GetAOSInstances", true, false, AppsModule.ServerAPI.GetAOSInstances)
NewRemote("RegisterPrimaryAOS", true, false, AppsModule.ServerAPI.RegisterPrimary)
NewRemote("InstallServer", true, false, AppsModule.ServerAPI.New)
NewRemote("GetPrimaryServer", true, false, AppsModule.ServerAPI.GetPrimaryServer)

--// Admin routes
NewRemote("GetRanks", true, false, AdminRunner.Ranks.GetAll)
NewRemote("NewRank", true, false, AdminRunner.Ranks.New)
NewRemote("CanUseApp", true, true, AdminRunner.CanUseApp)
NewRemote("GetRank", true, false, function(Rankname)
	return Var.DataStores.AdminsDS:GetAsync(Rankname)
end)

--// Settings
NewRemote("LoadSettings", true, false, function(controllerName, userId, customSettings: Types.SettingsGroup?)
	local settingController = SettingsAPI.GetController(controllerName)
	if not settingController then
		return false
	end
	return settingController.Load(userId, customSettings)
end)

NewRemote("SaveSettings", true, false, function(controllerName, userId)
	local settingController = SettingsAPI.GetController(controllerName)
	if not settingController then
		Utils.Logging.Warn("Controller not found")
		return false
	end
	return settingController.Save(userId)
end)

NewRemote("ModifySetting", true, false, function(controllerName, name, value)
	local settingController = SettingsAPI.GetController(controllerName)
	if not settingController then
		return false
	end

	return settingController.Set(name, value)
end)

NewRemote("GetSettings", true, false, function(controllerName : string, settingsArray : {string})
	local controller = SettingsAPI.GetController(controllerName)
	local currentValue = {}
	
	for _,settingName in settingsArray do
		local value = controller.Get(settingName)
		currentValue[settingName] = value
	end

	return currentValue
end)

NewRemote("GetSetting", true, false, function(controllerName : string, settingName : string)
	local controller = SettingsAPI.GetController(controllerName)
	local currentValue = controller.Get(settingName)

	return currentValue
end)

NewRemote("GetRemote", true, false, function(controllerName : string, settingName : string)
	local controller = SettingsAPI.GetController(controllerName)
	local remote = controller.GetRemote(settingName)

	return remote
end)

NewRemote("GetAllSettings", true, false, function()
	local controllers = SettingsAPI.SettingsList
	local allData = {}
	for i, v in controllers do
		allData[i] = v.GetData()
	end
	return allData
end)

Utils.NewRemote("RemoteEvent", "SettingsLoaded", true, function() end)

Var.InitClock["LoadRemotes"] = Utils.RoundMS(os.clock() - Var.InitClock["TempInit"])
Utils.Logging.Print(`[✓] OK in {Utils.RoundMS(os.clock() - Var.InitClock["TempInit"])}s`)
Utils.Logging.Print(
	`\n-- Administer {Configuration.VersData.String} {Configuration.VersData.GitRevision} loaded! --`,
	"\n		> Ready in ",
	Utils.RoundMS(os.clock() - Var.InitClock.RealInit).."ms",
	"\n		> Apps thread: ",
	Var.DidBootstrap and "FinishedBootstrap" or "Loading",
	"\n		> Using AOS: ",
	Var.PrimaryAppServer,
	"\n		> Startup information:",
	Var.InitClock,
	"\n		> Environment:",
	Var.Services.RunService:IsStudio() and Var or Var.Services.HttpService:JSONEncode(Var),
	Var.EnableFreeAdmin and "\n		> [!] Free admin is enabled, you should probably disable it for a production game." or "",
	Var.IsFirstBoot and "\n		> [!] First boot mode is enabled!" or "",
	not script:IsDescendantOf(game.ServerScriptService) and "\n		> [!] Administer is not a member of ServerScriptService! You need to move it there before you install Apps." or "" 
)

Utils.Logging.Print(`[-] Running startup jobs!`)

xpcall(
	function()
		if not Utils.GetSetting("LiveUpdate") then return end

		Var.Services.MessagingService:SubscribeAsync("Administer", AdminRunner.Socket)
	end,

	function()
		Utils.Logging.Warn("[thread Admins] MessagingService seems to be busy (did not bind on message Administer), some cross-server features disabled!")
	end
)

HttpRunner.GetRoute(Var.PrimaryAppServer, "/api/ping", function(...) end, function(...)
	Utils.Logging.Warn(...)
end)

HttpRunner.PostRoute(Var.PrimaryAppServer, "/api/report-version", {
	version = Configuration.VersData.NoExtraData,
	branch = Var.CurrentBranch["BranchName"]
}, function(...)
	return { ... }
end, function(...)
	Utils.Logging.SWarn(...)

	return { ... }
end)

--// Initial version stuff
Configuration.VersData.InstallDate = Utils.CheckVersion()
Configuration.VersData.IsUpToDate = not Utils.UpdateCallback({ "org.admsoftware.Core" })["org.admsoftware.Core"].your_version.is_outdated

Utils.Logging.Print(`[✓] Startup complete!`)
