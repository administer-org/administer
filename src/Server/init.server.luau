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

local Configuration  = require(Core.Configuration)
local Types          = require(Core.Types)
local Var            = require(Core.Variables)

Utils.Logging.Print(`[✓] Modules OK in {os.clock() - Var.InitClock["RealInit"]}s`)

Var.InitClock.TempInit = os.clock()
Var.Init()

Utils.Logging.Print(`[✓] Init() OK in {os.clock() - Var.InitClock["TempInit"]}s`)

Var.InitClock.TempInit = os.clock()
xpcall(function()
	Var.IsFirstBoot = (Var.IsFirstBoot or Var.DataStores.Settings:GetAsync("HasInit") == nil and true or false)
	
	Utils.Logging.Print(`[✓] DataStoreService connection established in {os.clock() - Var.InitClock["TempInit"]}s`)
	
	local Settings
	if Var.IsFirstBoot then
		require(script.Modules.Helpers.BootstrapGame)()
		Settings = SettingsAPI.new(Configuration.Settings) --// Initialize for the first time
		Settings:Save()

		--// This system is better than the old one because it allows the user
		--// to uninstall AOS without causing the system to overwrite stuff
		Var.DataStores.Settings:SetAsync("HasInit", true)
	end

	--// Now load settings
	if not Settings then
		Settings = SettingsAPI.new(Configuration.Settings)
		--Settings:Load()
	end
	
end, function(e)
	Utils.Logging.Warn(e)
	Utils.Logging.Warn(
		`[X] Cannot connect to the DataStoreService. Please ensure Studio APIs are enabled and try again.\n\nIf you need help please reach refer to the Getting Started guide.`
	)
end)

Var.InitClock.TempInit = os.clock()
AppsModule.Initialize()

Utils.Logging.Print(`[✓] OK in {os.clock() - Var.InitClock["TempInit"]}s`)

AdminRunner.Scan(false)
Var.Services.Players.PlayerAdded:Connect(AdminRunner.PlayerAdded)

Utils.Logging.Print("[-] Mounting frontend API..")
Var.InitClock.TempInit = os.clock()

local function NewRemote(
	Name: string, 
	AuthRequired: boolean, 
	PlayerVar: boolean, 
	Cbk: (Player, ...any) -> any
): any
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

NewRemote("DirectTranslate", false, true, function(Player, Key)
	return Utils.t(Player, Key)
end)

--// Homepage
NewRemote("UpdateHomePage", true, true, FrontendAPI.UpdateHomePage)

--// Utilities
NewRemote("CheckForUpdates", true, true, function(Player)
	return FrontendAPI.VersionCheck(Player)
end)
NewRemote("GetGameArt", false, false, Utils.GetGameIcon)

NewRemote("GetProminentColorFromUserID", false, true, function(Player)
	return Utils.GetProminentColor(Player.UserId)
end)

NewRemote("GetIconPack", false, false, function()
	return require(script.Core.Icons) :: any
end)

--// Apps
NewRemote("GetAppList", true, false, function(QueryType)
	return AppsModule.ServerAPI.GetList(nil, QueryType)
end)

NewRemote("GetAppInfo", true, false, AppsModule.ServerAPI.GetApp)
NewRemote("GetInstalledApps", true, false, AppsModule.GetAll)
NewRemote("InstallApp", true, false, AppsModule.ServerAPI.InstallFromServer)
NewRemote("Vote", true, false, AppsModule.ServerAPI.Vote)

--// Admin routes

Utils.Logging.Print(`[✓] OK in {os.clock() - Var.InitClock["TempInit"]}s`)
Utils.Logging.Print(`[-] Running startup jobs!`)

HttpRunner.PostRoute(Var.DefaultAppServer, "/api/report-version", {
	version = Configuration.VersData.NoExtraData,
	branch = Var.CurrentBranch["BranchName"],
}, function(...)
	return { ... }
end, function(...)
	Utils.Logging.Warn(...)
	return { ... }
end)
