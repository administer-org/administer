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
			Description = "This is an application which is improperly configured."
		},

		Dependencies = {
			Administer = "2.0.0",
			SettingsAPI = "1.0",
			AppPlatform = "2.0",

			AdministerModules = {},

			IsAdministerVersionRelevant = true
		},

		TextCommands = {},
		State = {}
	}
end

function App.InvocationAPI.Construct(Config: Types.RichConfig, Misc): Types.Response
	if Misc._ReturnConfig then
		return Config
	end

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
			"misc. data must not be nil, please refer to the documentation for information how to properly return a Construct object"
		}
	end

	-- Utils.Logging.Print("Proceeding with bootstrap")
	local Modules = {}

	for _, Request in Config.Dependencies.AdministerModules do
		if not Request then break end

		if Request.Type == "SERVER" then
			Modules[Request.Name] = require(script.Parent:FindFirstChild(Request.Name)) :: {}
		end
	end

	if Config.ClientFrame ~= nil then
		local UIClone = Config.ClientFrame:Clone()

		UIClone.Parent = Var.Panel.Path.Main
	end

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
	AppMeta: { InstallDate: number, InstallSource: string, AppID: number },
	Debug
): Types.Response
	Utils.Logging.Print(
		`[-] Loading app from source {string.lower(typeof(Path))}_{(typeof(Path) == "Instance" and Path:GetFullName() or Path)}`
	)

	local function DWarn(Msg)
		if Debug then
			warn(`[{Path}] [{(tick() - Ticks[Path]) * 1000}ms]: {Msg}`)
		end
	end

	Ticks[Path] = tick()
	local Extras = {
		RunContext = typeof(Path) == "Instance" and "LocalAppsFolder" or "AOSDownload", 
		TechID = Path
	}

	DWarn("Requiring app")

	local TargetApp, RealApp = {}, require(Path)

	DWarn("Loading app")

	RealApp = RealApp(App.InvocationAPI, Extras) :: { Success: boolean, RichConfig: Types.RichConfig }

	if not RealApp[1] then
		Utils.Logging.Warn("This app cannot be loaded as it has failed a test, this is probably due to an outdated Administer version. The server says: ", App[2])

		return
	end

	--// Construct UI here

	DWarn("Getting data")

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
	local Start = tick()
	local DelaySetting, Apps = Utils.GetSetting("AppLoadDelay"), Var.DataStores.AppDB:GetAsync("AppList") or {}

	for _, AppInstance in script.Parent.Parent.Parent.LocalApps:GetChildren() do
		table.insert(Apps, {
			ID = AppInstance,
			InstallDate = 0,
			InstallSource = "",
			IsPhysicalApp = true
		})
	end

	if Utils.GetSetting("LoadApps") == false then
		Utils.Logging.Print("App Bootstrapping disabled due to configuration, please disable!")

		Var.DidBootstrap = true

		return false
	end

	if DelaySetting == "InStudio" and Var.Services.RunService:IsStudio() or DelaySetting == "All" then
		task.wait(3)
	end

	Utils.Logging.Print("Bootstrapping apps...")

	local Total = 0
	local Completed = 0
	local DoneSignal = Instance.new("BindableEvent")

	for _, AppObj in Apps do
		Total += 1
		--print('obj', AppObj, Completed, Total)

		task.spawn(function()
			pcall(function() --// we don't care if an app bootstrap fails out
				App.LoadLocal(AppObj.ID, {
					InstallDate = AppObj.InstallDate,
					InstallSource = AppObj.InstallSource,
					AppID = AppObj.ID
				}, false)
			end)

			Completed += 1

			if Completed >= Total then
				DoneSignal:Fire()
			end
		end)
	end

	DoneSignal.Event:Wait()

	Utils.Logging.Print(`Finished bootstrapping apps! ({Utils.RoundMS(tick() - Start)}ms)`)
	Var.DidBootstrap = true

	return true
end

function App.Uninstall(AppID: number): Types.Response
	local Apps = Var.DataStores.AppDB:GetAsync("AppList") or {}
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

function App.GetApplicableThemes(): {any}
	--// TODO: Do we want to use App.GetAll instead?
	local Themes = Var.DataStores.AppDB:GetAsync("ThemeList")
	local Final = {}

	for ThemeID, Data in Themes do
		table.insert(Final, {
			ID = ThemeID,
			AdministerID = ThemeID,
			InstallSoruce = Data.InstallSource,
			InstallDate = Data.InstallDate,
			Source = require(tonumber(Data.ID))
		})
	end

	return Final
end

function App.ModifyThemePreference(
	Player: Player, 
	Message: { Type: "SetAsPreferred" | "ApplyScheme" | "Delete" },
	SchemeType: "Dark"? | "Light"?,
	ThemeName: string?
): ()
	if not Player then
		return {false, "Player must not be nil"}
	end
	
	if Message == "SetAsPreferred" then
		local ExistingPreferences = Var.DataStores.Settings:GetAsync(Player.UserId.."_ThemeSaves") or Var.DefaultThemePreferences
		
		ExistingPreferences[SchemeType] = ThemeName
		
		Var.DataStores.Settings:SetAsync(Player.UserId.."_ThemeSaves", ExistingPreferences)
		
		return {true, "Setting saved successfully"}
	elseif Message == "ApplyScheme" then
		local ExistingPreferences = Var.DataStores.Settings:GetAsync(Player.UserId.."_ThemeSaves") or Var.DefaultThemePreferences

		ExistingPreferences.CurrentMode = SchemeType

		Var.DataStores.Settings:SetAsync(Player.UserId.."_ThemeSaves", ExistingPreferences)

		return {true, "Setting saved successfully"}
	elseif Message == "Delete" then
		local Themes = Var.DataStores.AppDB:GetAsync("ThemeList")
		
		if Themes[ThemeName] then
			Utils.Logging.Warn(`[Theme] Uninstalling theme {ThemeName} (initiated by {Player.Name}/{Player.UserId}`)
			
			Themes[ThemeName] = nil
			
			Var.DataStores.AppDB:SetAsync("ThemeList", Themes)
			
			return {true, "Uninstalled!"}
		else
			return {false, "Theme not installed"}
		end
	else
		return {false, "Unknown control request"}
	end
end


function App.Install(
	AppID: number, 
	InstallContext: string, 
	AppName: string
): Types.Response
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

		return { false, `Failure: {e}` }
	end)

	if res[1] == false then return res end

	Utils.Logging.Print(`[✓] App bootstrap OK, installing!`)

	local AppList = Var.DataStores.AppDB:GetAsync("AppList") or {}
	for i, App in AppList do
		if App.ID == AppID then
			Utils.Logging.Warn("[x] Not re-installing duplicate app")
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

	if Utils.GetSetting("DisableAOS") == true then
		Utils.Logging.Print("App server call ignored due to configuration.")
		return {}
	end


	for i, Server in (SpecificServer ~= nil and {{ ServerURL = SpecificServer }} or Var.DataStores.AppDB:GetAsync("AppServerList")) do
		local FullList = {}

		local InstanceName = HTTP.GetRoute(Server.ServerURL, "/pub/.administer", function(D, _)
			return D.instance_name
		end, function(x)
			return "Unknown"
		end)

		return HTTP.GetRoute(Server.ServerURL, `/api/directory?asset_type={string.upper(Area)}`, function(Apps, ResponseData): {}
			for i, v in Apps do
				v["Server"] = Server.ServerURL
				v["ServerName"] = InstanceName

				table.insert(FullList, v)
			end

			return { [Server.ServerURL] = FullList }
		end, function(sc): {}
			return { [Server.ServerURL] = { false, sc } }
		end)
	end

	return Combined
end

function App.ServerAPI.New(URL: string, ActingUser: number?): Types.Response
	Utils.Logging.Print(`Installing AOS instance @ {URL}...`)

	return HTTP.GetRoute(URL, "/pub/.administer", function(Data, Info)
		if Data.server ~= "AdministerAppServer" then
			Utils.Logging.Warn("This does not seem to be a valid or up-to-date AOS instance.")
			return { false, "This is not a valid AOS instance." }
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
		Utils.Logging.Warn(`Failed to connect to AOS, is it running and accessible? (statuscode {SC})`)

		return { false, `AOS is not healthy or accessible. Got code {SC} on /pub/.administer` }
	end)
end

function App.ServerAPI.RegisterPrimary(
	URL: string, 
	OverwriteExisting: boolean?
): Types.Response
	if OverwriteExisting then
		App.ServerAPI.UninstallServer(Var.DefaultAppServer, true)
		App.ServerAPI.New(URL, 1)
	end

	return HTTP.PostRoute(URL, "/api/register-home-node", {}, function(Data, Info)
		Utils.Logging.Print("Registered!", Data)

		for _, Server in Var.AppServers do
			if Server.ServerURL == URL then
				Server.IsPrimary = true
			elseif Server.IsPrimary then
				Server.IsPrimary = false
			end
		end

		Var.DataStores.AppDB:SetAsync("AppServerList", Var.AppServers)

		Var.PrimaryAppServer = URL

		return { true, "Done!" }
	end, function(...)
		Utils.Logging.Warn(`Failed to register this AOS instance as your primary, is it online and accepting primary registrations?`, ...)

		return { false, Utils.t(nil, "generic.error.CheckLogs") }
	end)
end

function App.ServerAPI.GetServerStatuses(): Types.Response
	local Resps = {}

	for _, Server in Var.AppServers do
		xpcall(function()
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
					ServerInstall = Server.Time,
					RawResp = Data
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
			end, {
				DontLookForAlts = true,
				Timeout = 15
			}))
		end, function()
			return {
				URL           = Server.ServerURL,
				Code          = "Invalid server URL!",
				Failed        = true,
				PingTime      = 0,  
				InstalledBy   = Server.Creator,
				ServerInstall = Server.Time
			}	
		end)
	end

	return { true, Resps }
end

function App.ServerAPI.UninstallServer(ServerURL, IsStatic, Force): Types.Response
	local Done = false
	Utils.Logging.SWarn(`Uninstalling app server {ServerURL}`)

	local i = 0
	for _, _ in Var.AppServers do
		i += 1
	end

	if i == 1 then
		return { false, "You must always have at least one server installed" }
	end

	for i, Server in Var.AppServers do
		if Server.ServerURL == ServerURL then
			table.remove(Var.AppServers, i)
			Done = true
		end
	end

	if IsStatic then
		pcall(function()
			table.remove(Var.AppServers, table.find(Var.AppServers, ServerURL))
		end)
	end

	if Done then
		Var.DataStores.AppDB:SetAsync("AppServerList", Var.AppServers)

		return { true, "Done!" }
	else
		return { false, "This app server does not appear to be installed." }
	end
end

function App.ServerAPI.GetApp(AppServer: string, AppID: string): Types.Response
	return HTTP.GetRoute(AppServer, `/api/asset/{AppID}`, function(Data)
		if Data.Metadata.AssetType == "app" then
			Data.Unprocessed = true

			xpcall(function()
				local RichConfig = require(Data.InstallID)(App.InvocationAPI, { _ReturnConfig = true })

				Data.CannotDownload = false
				Data.Unprocessed = false
				Data.RichConfig = RichConfig
			end, function(e)
				warn("------------", e)
				Utils.Logging.Warn(e)

				Data.CannotDownload = true
			end)

			return { true, Data }
		else
			return { true, Data }
		end
	end, function(...)
		return { false, ... }
	end)
end

function App.InstallTheme(
	Player: Player,
	Source: "AOS" | "Local",
	Data: table | number,
	ServerURL: string?,
	AdministerID: string
): Types.Response
	if Source == "AOS" then
		if Data.RequirePayment then
			if not Var.Services.MarketplaceService:UserOwnsGamePassAsync(Player.UserId, Data.GamePassID) then
				local Result = "Waiting"

				Var.Services.MarketplaceService:PromptGamePassPurchase(Player, Data.GamePassID)
				Var.Services.MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(Plr, GamePassID, WasPurchased)
					if Plr ~= Player or GamePassID ~= Data.GamePassID then return end

					Result = WasPurchased and "Purchased" or "NotPurchased"
				end)

				while Result == "Waiting" do
					task.wait(.1)
				end

				if Result == "NotPurchased" then
					return {false, "Purchased cancelled by user"}
				else
					--// we now own it, wow!!!
				end
			else
				--print("owned!!")
			end

			HTTP.PostRoute(ServerURL, `/api/asset/{Data.Metadata.AdministerID}/install`, {}, function(): Types.Response
				--// installed OK
			end, function(SC): Types.Response
				if SC == 400 then
					--// AOS detected a duplicate, probably safe
					return
				end

				Utils.Logging.Warn(`Failed to tell AOS about the installation: {SC}`)
			end, {
				Debug = false
			})

			return App.InstallTheme(Player, "Local", Data.InstallID, ServerURL, AdministerID)
		end
	else
		--local ThemeList = Var.DataStores.AppDB:GetAsync("ThemeList") or {}
		local ThemeList = {}

		if ThemeList[tostring(AdministerID)] ~= nil then
			return {false, "You can't install a theme more than once!"}
		end
		
		print(AdministerID)

		ThemeList[AdministerID] = {
			ID = Data,
			InstallDate = os.time(),
			InstallSource = ServerURL
		}

		Var.DataStores.AppDB:SetAsync("ThemeList", ThemeList)

		return {true, "Theme successfully installed!"}
	end
end

function App.ServerAPI.InstallFromServer(
	Player: Player,
	ServerURL: string,
	AppID: string
): Types.Response
	if typeof(Player) == "string" then
		--// backwards compat
		ServerURL = Player
		AppID = ServerURL
	end

	return HTTP.GetRoute(ServerURL, `/api/asset/{AppID}`, function(Content)
		local RealID = Content.InstallID

		if RealID == 0 then
			return { false, "This server gave us bad data, please report the error to the server owner." }
		end

		if Content.Metadata.AssetType == "theme" then
			return App.InstallTheme(Player, "AOS", Content, ServerURL, AppID)
		end

		--// Basic checks
		--if not IsVersionSupported(Var.Config.VersData.String, Content.Metadata.AppAPIPreferredVersion) then
		--	return {false, "Administer is too old to support this app. Please update your Administer installation."}
		--end

		local Result: Types.Response = App.Install(RealID, ServerURL, Content["Name"])

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

function App.ServerAPI.Vote(
	ServerURL: string, 
	AppID: string, 
	Vote: number
): Types.Response
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

function App.ServerAPI.GetVote(
	ServerURL: string,
	AppID: string
)
	return HTTP.GetRoute(ServerURL, `/api/asset/{AppID}/vote`, function(Data, _)
		return Data["data"]
	end, function(...)
		Utils.Logging.Warn(...)

		return {
			liked = false,
			dislined = false,
			favorited = false
		}
	end, {
		Debug = false
	})
end


function App.ServerAPI.GetAOSInstances(
	DoStatusChecks: boolean
): (any)
	local function DoStatusCheck(URL)
		local Start = tick()

		return HTTP.GetRoute(URL, "/pub/.administer", function(Data, Debugging)
			return {
				IsUp = true,
				Ping = Debugging.ProcessedMS,
				Version = Data.api_version,
				IsDev = Data.is_dev
			}
		end, function(_, Data)
			return {
				IsUp = false,
				Ping = Data.ProcessedMS
			}
		end)
	end

	return HTTP.GetRoute("https://gateway.admsoftware.org", `/`, function(Content)
		if DoStatusChecks then
			for _, URL in Content.instances do
				local Result = DoStatusCheck(URL.url)

				for Key, Value in Result do
					URL[Key] = Value
				end
			end
		end

		return Content.instances
	end, function(...)
		Utils.Logging.Warn("Failed to get gateway reply:", ...)
	end)
end

function App.ServerAPI.Search(
	ServerURL,
	Query
): {}
	return HTTP.GetRoute(ServerURL, `/api/search/{Query}`, function(Data, ...)
		return Data
	end, function(...)
		return ...
	end)
end

function App.ServerAPI.GetPrimaryServer()
	for _, Server in Var.AppServers do
		if Server.IsPrimary then
			return Server.ServerURL
		end
	end

	return Var.AppServers[1].ServerURL
end

function App.GetTotals()
	local RunningApps = 0

	for _, App in App.RunningApps do
		RunningApps += 1
	end


	return { Servers = #Var.AppServers, Apps = RunningApps }
end

return App
