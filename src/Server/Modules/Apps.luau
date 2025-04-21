--// Administer
--// pyxfluff 2024 - 2025

--// Initialization
local App = {
	ServerAPI = {},
	InvocationAPI = {},

	RunningApps = {}
}

local Ticks = {}

--// Dependencies
local Root = script:FindFirstAncestor("Loader")
local AdmConfig = require(Root.Core.Configuration)
local HTTP = require(Root.Modules.HTTPRunner)
local Types = require(Root.Core.Types)
local Utils = require(Root.Modules.Utilities)
local Var = require(Root.Core.Variables)

local function IsVersionSupported(version: string, range: string): boolean
	local min, max = range:match("min:([%d%.]+);max:([%d%.]+)")

	if min and max then return version >= min and version <= max end

	return version == range
end

function App.InvocationAPI.RichConfig(): Types.RichConfig
	return {
		AppMeta = {
			Name = "Default App",
			Icon = "",
			Version = "0",
			Description = "This is an application which is improperly configured.",
		},

		Dependencies = {
			Administer = "2.0.0",
			SettingsAPI = "1.0",
			AppPlatform = "2.0",

			AdministerModules = {},

			IsAdministerVersionRelevant = true,
		},

		TextCommands = {},
		State = {}
	}
end

function App.InvocationAPI.Construct(Config: Types.RichConfig, Misc): Types.Response
	--// Config checks
	if not Config.Bootstrap then
		return { false, "bootstrap function must not be nil" }
	elseif not IsVersionSupported(AdmConfig.VersData.APIRevision, Config.Dependencies.AppPlatform) then
		return {
			false,
			`this app does not support your application platform! expected {Config.Dependencies.AppPlatform}, got {AdmConfig.VersData.APIRevision}`
		}
	elseif not IsVersionSupported(AdmConfig.VersData.String, Config.Dependencies.Administer) then
		return {
			false,
			`this app does not support your administer version. please upgrade to the latest version of Administer.`
		}
	elseif Misc == nil then
		return {
			false,
			"misc. data must not be nil, please refer to the documentation for imformation how to properly return a Construct object"
		}
	end

	Utils.Logging.Print("Proceeding with bootstrap")
	local Modules = {}

	for _, Request in Config.Dependencies.AdministerModules do
		if not Request then break end

		if Request.Type == "SERVER" then
			Modules[Request.Name] = require(script.Parent:FindFirstChild(Request.Name)) :: {}
		end
	end
	
	local UIClone = Config.ClientFrame:Clone()
	
	UIClone.Parent = Var.Panel.Path.Main

	Config.Bootstrap({}, Config.State, {
		FinishTime = string.sub(tostring(tick() - Ticks[Misc.TechID]), 1, 5),
		RunContext = Misc.RunContext,
		RanksWithAccess = 0, --// TODO

		Modules = Modules :: any
	})

	return { true, Config }
end

--// Core App functions
function App.LoadLocal(
	Path: number | Instance,
	AppMeta: { InstallDate: number, InstallSource: string, AppID: number }
): Types.Response
	Utils.Logging.Print(
		`[-] Loading app from source {string.lower(typeof(Path))}_{(typeof(Path) == "Instance" and Path:GetFullName() or Path)}`
	)

	Ticks[Path] = tick()
	local Extras = {
		RunContext = typeof(Path) == "Instance" and "LocalAppsFolder" or "AOSDownload", 
		TechID = Path
	}
	local TargetApp, RealApp = {}, require(Path)(App.InvocationAPI, Extras) :: { Success: boolean, RichConfig: Types.RichConfig }

	if not RealApp[1] then
		Utils.Logging.Warn("This app cannot be loaded as it has failed a test, this is probably due to an outdated Administer version. The server says: ", App[2])
	end

	--// Construct UI here

	xpcall(function()
		TargetApp.AppID = (typeof(Path) == "number") and Path or AppMeta.AppID
		TargetApp.BuildTime = string.sub(tostring(tick() - Ticks[Path]), 1, 5)
		TargetApp.Description = RealApp[2].AppMeta.Description
		TargetApp.InstallSource = AppMeta.InstallSource
		TargetApp.InstalledSince = AppMeta.InstallDate
		TargetApp.Copyright = RealApp[2].AppMeta.Copyright
		TargetApp.Version = RealApp[2].AppMeta.Version
		TargetApp.Icon = RealApp[2].AppMeta.Icon
		TargetApp.Name = RealApp[2].AppMeta.Name

		Utils.Logging.Print(`[✓] App bootstrap OK in {Utils.RoundMS(tick() - Ticks[Path])}ms`)
		
		App.RunningApps[RealApp[2].AppMeta.Name] = TargetApp
	end, function(e)
		Utils.Logging.Warn(`[X] Failed bootstrapping app: {e}`) --// We cannot Logging.Error() here because the thread will suppress it for some reason
	end)

	return { true, TargetApp }
end

function App.Initialize(): boolean
	local DelaySetting, Apps = Utils.GetSetting("AppLoadDelay"), Var.DataStores.AppDB:GetAsync("AppList") or {}
	local AppsCount, i, TotalAttempts, Start = #Apps, 0, 0, tick()

	Utils.Logging.Print("Bootstrapping apps...")

	--if Utils.GetSetting("DisableApps") then
	--	Utils.Logging.Print(`App Bootstrapping disabled due to configuration, please disable!`)
	--	return false
	--end

	if DelaySetting == "InStudio" and Var.Services.RunService:IsStudio() or DelaySetting == "All" then
		task.wait(3)
	end

	for i, App in script.Parent.Parent.Parent.LocalApps:GetChildren() do
		table.insert(Apps, {
			ID = App,
			InstallDate = 0,
			InstallSource = ""
		})
	end

	for _, AppObj in Apps do
		task.defer(function()
			App.LoadLocal(AppObj.ID, {
				InstallDate = AppObj.InstallDate,
				InstallSource = AppObj.InstallSource,
				AppID = AppObj.ID
			})
			i += 1
		end)
	end

	repeat
		task.wait(0.05)
		TotalAttempts += 1
	until i >= AppsCount or TotalAttempts == Var.AppPollingLimit

	if TotalAttempts == Var.AppPollingLimit then
		Utils.Logging.Warn(
			`[thread APPS] Failed to initialize some apps after the polling limit! Try looking for faulty apps or increasing the limit if you have a heavy app. {i / AppsCount}% of {AppsCount} cloud apps loaded in {TotalAttempts} tries/{tick() - Start}s.`
		)
	end
	
	Utils.Logging.Print(`Finished bootstrapping apps! ({Utils.RoundMS(tick() - Start)}ms)`)

	Var.DidBootstrap = true

	return true
end

function App.Uninstall(AppID: number): Types.Response
	local Apps = Var.DataStores.AppDB:GetAsync("AppList")
	local DidUninstall = false
	
	Utils.Logging.Warn(`Removing app {AppID}`)

	for i, App in Apps do
		if App.ID == AppID then
			Utils.Logging.Print("Successfully uninstalled", App)
			Apps[i] = nil
			DidUninstall = true
		end
	end

	Var.DataStores.AppDB:SetAsync("AppList", Apps)
	
	if DidUninstall then
		return { true, Utils.t(nil, "generic.Done") }
	else
		if AppID == nil then
			return { false, Utils.t(nil, "Configuration.Apps.Content.Template.Local.HeaderLabel") }
		else
			return { false, Utils.t(nil, "generic.error.Generic")}
		end
	end
end

function App.GetAll(Source: string): Types.TableWildcard
	if Source == nil or Source == "Bootstrapped" then
		return { true, App.RunningApps }
	elseif Source == "DataStore_Raw" then
		return {true, Var.DataStores.AppDB:GetAsync("AppList")}
	elseif Source == "Combined" then
		local AppList = Var.DataStores.AppDB:GetAsync("AppList") or {}
		local Final = {}

		for i, Object in AppList do
			Object["ObjSource"] = "DataStore"
			table.insert(Final, Object)
		end

		for i, Object in App.RunningApps do
			Object["ObjSource"] = "AppPlatform"
			table.insert(Final, Object)
		end

		return {true, Final}
	end

	return { false, "Source must be of value nil | Bootstrapped | DataStore_Raw | Combined" }
end

function App.Install(AppID: number, InstallContext: string, AppName: string): Types.Response
	--// NEW: Now we run the app in this server to test it. Putting here so I don't forget for the 2.0 logs.
	Utils.Logging.Print(`[-] Attempting to load app`)
	local _, res = xpcall(function(): Types.Response
		App.LoadLocal(AppID, {
			InstallDate = os.time(),
			InstallSource = InstallContext,
			AppID = AppID
		})

		return { true, "OK" }
	end, function(e): Types.Response
		Utils.Logging.Warn(`[x] This does not seem to be an Administer app or the initial build failed.\n\n{e}`)
		return { false, "This app isn't valid, check the log." }
	end)

	if res[1] == false then return res end
	Utils.Logging.Print(`[✓] App bootstrap OK, installing!`)

	local AppList = Var.DataStores.AppDB:GetAsync("AppList") or {}
	for i, App in AppList do
		if App.ID == AppID then
			Utils.Logging.Warn("[x] Not continuing because this app is a duplicate!")
			return { false, Utils.t(nil, "apps.DupeDetected") }
		end
	end

	table.insert(AppList, {
		ID = AppID,
		InstallDate = os.time(),
		InstallSource = InstallContext or "Manual ID install",
		Name = AppName ~= nil and AppName or "Unknown" --// surely wont cause any issues
	})

	Var.DataStores.AppDB:SetAsync("AppList", AppList)
	return { true, Utils.t(nil, "apps.Downloaded") }
end

--// Marketplace functions
function App.ServerAPI.GetList(
	SpecificServer: string, 
	Area: string
): {}
	local Combined = {}

	if Utils.GetSetting("DisableAppServerFetch") == true then
		Utils.Logging.Print("App server call ignored due to configuration.")
		return {}
	end

	for i, Server in (SpecificServer ~= nil and {{ ServerURL = SpecificServer }} or Var.DataStores.AppDB:GetAsync("AppServerList")) do
		local FullList = {}

		return HTTP.GetRoute(Server.ServerURL, `/api/directory?asset_type={Area}`, function(Apps, ResponseData): {}
			for i, v in Apps do
				v["Server"] = Server.ServerURL

				table.insert(FullList, v)
			end

			return { [Server.ServerURL] = FullList }
		end, function(sc): {}
			return { [Server.ServerURL] = { false, sc } }
		end)
	end

	return Combined
end

function App.ServerAPI.New(URL: string, ActingUser: number): Types.Response
	Utils.Logging.Print("Installing app server...")
	
	HTTP.GetRoute(URL, "/pub/.administer", function(Data, Info)
		if Data["server"] ~= "AdministerAppServer" then
			Utils.Logging.Warn("This URL doesn't seem to be an Administer app server.")
			return { false, "This is not a valid Administer app server." }
		end

		Utils.Logging.Print("This server is valid!", Data)

		table.insert(Var.AppServers, {
			ServerURL = URL,
			Time = os.time(),
			Creator = ActingUser or 1
		})

		Var.DataStores.AppDB:SetAsync("AppServerList", Var.AppServers)

		return { true, "Done!" }
	end, function(SC)
		Utils.Logging.Warn(`Failed to connect to the app server, is it running? (statuscode {SC})`)

		return { false, Utils.t(nil, "generic.error.CheckLogs") }
	end)

	return { false, Utils.t(nil, "generic.error.Generic") }
end

function App.ServerAPI.GetServerStatuses(): Types.Response
	local Resps = {}
	
	for _, Server in Var.AppServers do
		table.insert(Resps, HTTP.GetRoute(Server.ServerURL, "/pub/.administer", function(Data, Meta)
			return {
				URL           = Server.ServerURL,
				Name          = Data.instance_name,
				IsDev         = Data.is_dev,
				Uptime        = Data.uptime,
				Banner        = Data.banner,
				AOSVers       = Data.api_version,
				PingTime      = Meta.ProcessedMS,
				InstalledBy   = Server.Creator,
				ServerInstall = Server.Time 
			}
		end, function(Code, Data)
			return {
				URL           = Server.ServerURL,
				Code          = Code,
				Failed        = true,
				PingTime      = Data.ProcessedMS,  
				InstalledBy   = Server.Creator,
				ServerInstall = Server.Time
			}
		end))
	end
	
	return { true, Resps }
end

function App.ServerAPI.UninstallServer(ServerURL): Types.Response
	local Done = false
	Utils.Logging.SWarn(`Uninstalling app server {ServerURL}`)
	
	for i, Server in Var.AppServers do
		if Server.ServerURL == ServerURL then
			table.remove(Var.AppServers, i)
			Done = true
		end
	end
	
	if Done then
		Var.DataStores.AppDB:SetAsync("AppServerList", Var.AppServers)

		return { true, "Done!" }
	else
		return { false, "This app server does not appear to be installed." }
	end
end


function App.GetTotals()
	local RunningApps = 0
	
	for _, App in App.RunningApps do
		RunningApps += 1
	end
	
	
	return { Servers = #Var.AppServers, Apps = RunningApps }
end

function App.ServerAPI.GetApp(AppServer: string, AppID: number): Types.Response
	return HTTP.GetRoute(AppServer, `/api/asset/{AppID}`, function(Data)
		return { true, Data }
	end, function(...)
		return { false, ... }
	end)
end

function App.ServerAPI.InstallFromServer(ServerURL: string, AppID: number): Types.Response
	return HTTP.GetRoute(ServerURL, `/api/asset/{AppID}`, function(Content)
		local RealID = Content["InstallID"]
		if RealID == 0 then
			return { false, "This server gave us bad data, please report the error to the server owner." }
		end

		local Result: Types.Response = App.Install(RealID, ServerURL, Content["AppName"])

		if Result[1] then
			return HTTP.PostRoute(ServerURL, `/api/asset/{AppID}/install`, {}, function(): Types.Response
				return { true, `{Utils.t(nil, "generic.Done")}!` }
			end, function(SC): Types.Response
				if SC == 400 then
					--// AOS detected a duplicate, probably safe
					return { true, `{Utils.t(nil, "generic.Done")}!` }	
				end
				
				return { false, Utils.t(nil, "generic.error.TryAgainLater") }
			end)
		else
			Utils.Logging.Warn("App did not install with an OK status code, ignoring request to tell AOS.")
			return Result
		end
	end, function(c)
		return { false, string.format(Utils.t(nil, "apps.pulled.Bad"), c) }
	end)
end

function App.ServerAPI.Vote(ServerURL: string, AppID: string, Vote: number): Types.Response
	return game:GetService("HttpService"):RequestAsync({
		Url = `{ServerURL}/api/asset/{AppID}/vote`,
		Method = "PUT",
		
		Body = game:GetService("HttpService"):JSONEncode({
			vote = Vote,
			is_favorite = Vote == 2
		}),
		
		Headers = {
			["Content-Type"] = "application/json"
		}
	})
end

return App
