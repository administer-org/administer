--// Administer
--// pyxfluff 2024 - 2025

--// Initialization
local App = {
	ServerAPI = {},
	InvocationAPI = {},

	RunningApps = {},
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

	if min and max then
		return version >= min and version <= max
	end

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
		State = {},
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
			`this app does not support your application platform! expected {Config.Dependencies.AppPlatform}, got {AdmConfig.VersData.APIRevision}`,
		}
	elseif not IsVersionSupported(AdmConfig.VersData.String, Config.Dependencies.Administer) then
		return {
			false,
			`this app does not support your administer version. please upgrade to the latest version of Administer.`,
		}
	elseif Misc == nil then
		return {
			false,
			"misc. data must not be nil, please refer to the documentation for information how to properly return a Construct object",
		}
	end

	Utils.Logging.Print("Proceeding with bootstrap")
	local Modules = {}

	for _, Request in Config.Dependencies.AdministerModules do
		if not Request then
			break
		end

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

		Modules = Modules :: any,
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
		TechID = Path,
	}
	local TargetApp, RealApp =
		{}, require(Path)(App.InvocationAPI, Extras) :: { Success: boolean, RichConfig: Types.RichConfig }

	if not RealApp[1] then
		Utils.Logging.Warn(
			"This app cannot be loaded as it has failed a test, this is probably due to an outdated Administer version. The server says: ",
			App[2]
		)

		return
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

	if Utils.GetSetting("LoadApps") == false then
		Utils.Logging.Print(`App Bootstrapping disabled due to configuration, please disable!`)

		--// switch this to true just in case
		Var.DidBootstrap = true
		return false
	end

	if DelaySetting == "InStudio" and Var.Services.RunService:IsStudio() or DelaySetting == "All" then
		task.wait(3)
	end

	for i, App in script.Parent.Parent.Parent.LocalApps:GetChildren() do
		table.insert(Apps, {
			ID = App,
			InstallDate = 0,
			InstallSource = "",
			IsPhysicalApp = true,
		})
	end

	for _, AppObj in Apps do
		Utils.Logging.Print(`Importing app:`, AppObj)
		task.defer(function()
			App.LoadLocal(AppObj.ID, {
				InstallDate = AppObj.InstallDate,
				InstallSource = AppObj.InstallSource,
				AppID = AppObj.ID,
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

	-- Recovery pass: reload any DataStore apps that didn't make it into RunningApps
	task.defer(function()
		App.RecoverApps()
	end)

	Var.DidBootstrap = true

	return true
end

-- Scans AppList for entries not present in RunningApps and retries LoadLocal.
-- Removes permanently-failed entries and rewrites a compact AppList to DataStore.
function App.RecoverApps()
	local RawList = Var.DataStores.AppDB:GetAsync("AppList") or {}

	-- Compact holes
	local AppList = {}
	for _, v in RawList do
		if v then
			table.insert(AppList, v)
		end
	end

	if #AppList == 0 then
		return
	end

	local Changed = false
	local ToRemove = {}

	for idx, AppObj in ipairs(AppList) do
		if AppObj.IsPhysicalApp then
			continue
		end

		local ID = AppObj.ID
		local IsRunning = false
		for _, RunningApp in App.RunningApps do
			if tostring(RunningApp.AppID) == tostring(ID) then
				IsRunning = true
				break
			end
		end

		if not IsRunning then
			Utils.Logging.Warn(`[RecoverApps] App {ID} is in DataStore but not running — retrying LoadLocal`)
			local ok, result = pcall(function()
				return App.LoadLocal(ID, {
					InstallDate = AppObj.InstallDate,
					InstallSource = AppObj.InstallSource,
					AppID = ID,
				})
			end)

			if ok and result and result[1] then
				Utils.Logging.Print(`[RecoverApps] App {ID} recovered successfully`)
			else
				Utils.Logging.Warn(`[RecoverApps] App {ID} failed to load again — removing stale DataStore entry`)
				table.insert(ToRemove, idx)
				Changed = true
			end
		end
	end

	-- Remove stale entries in reverse so indices stay valid
	for i = #ToRemove, 1, -1 do
		table.remove(AppList, ToRemove[i])
	end

	-- Always rewrite if we compacted holes or removed stale entries
	if Changed or #AppList ~= #RawList then
		Utils.Logging.Print(`[RecoverApps] Writing compacted AppList ({#AppList} entries)`)
		Var.DataStores.AppDB:SetAsync("AppList", AppList)
	end
end

function App.Uninstall(AppID: number): Types.Response
	local Apps = Var.DataStores.AppDB:GetAsync("AppList") or {}
	local DidUninstall = false

	Utils.Logging.Warn(`Removing app {AppID}`)

	for i = #Apps, 1, -1 do
		local App = Apps[i]
		if App and App.ID == AppID then
			Utils.Logging.Print("Successfully uninstalled", App)
			table.remove(Apps, i)
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
			return { false, Utils.t(nil, "generic.error.Generic") }
		end
	end
end

function App.GetAll(Source: string): Types.TableWildcard
	if Source == nil or Source == "Bootstrapped" then
		return { true, App.RunningApps }
	elseif Source == "DataStore_Raw" then
		return { true, Var.DataStores.AppDB:GetAsync("AppList") }
	elseif Source == "Combined" then
		local AppList = Var.DataStores.AppDB:GetAsync("AppList") or {}
		local Final = {}

		for i, Object in AppList do
			Object["ObjSource"] = "DataStore"
			table.insert(Final, Object)
		end

		for i, Object in App.RunningApps do
			-- copy to avoid mutating the live RunningApps entry
			local Copy = {}
			for k, v in Object do
				Copy[k] = v
			end
			Copy["ObjSource"] = "AppPlatform"
			table.insert(Final, Copy)
		end

		return { true, Final }
	end

	return { false, "Source must be of value nil | Bootstrapped | DataStore_Raw | Combined" }
end

function App.Install(AppID: number, InstallContext: string, AppName: string): Types.Response
	Utils.Logging.Print(`[-] Attempting to install app {AppID} from {InstallContext}`)

	-- Only block if the app is already live in this server session
	for _, RunningApp in App.RunningApps do
		if tostring(RunningApp.AppID) == tostring(AppID) then
			Utils.Logging.Warn(`[x] App {AppID} is already running, blocking duplicate install`)
			return { false, Utils.t(nil, "apps.DupeDetected") }
		end
	end

	-- Try to load the app
	local LoadResult
	local ok, err = pcall(function()
		LoadResult = App.LoadLocal(AppID, {
			InstallDate = os.time(),
			InstallSource = InstallContext,
			AppID = AppID,
		})
	end)

	if not ok or not LoadResult or not LoadResult[1] then
		Utils.Logging.Warn(`[x] App load failed: {tostring(err or (LoadResult and LoadResult[2]))}\n`)
		return { false, `Failure: {tostring(err or (LoadResult and LoadResult[2]))}` }
	end

	Utils.Logging.Print(`[✓] App bootstrap OK, saving to DataStore`)

	-- Upsert: replace existing entry for this ID (compacting holes) or append
	local RawList = Var.DataStores.AppDB:GetAsync("AppList") or {}
	local AppList = {}
	local Found = false
	for _, v in RawList do
		if v then
			if tostring(v.ID) == tostring(AppID) then
				-- Replace stale entry with fresh one
				table.insert(AppList, {
					ID = AppID,
					InstallDate = os.time(),
					InstallSource = InstallContext or "Manual ID install",
					Name = AppName ~= nil and AppName or "Unknown",
				})
				Found = true
			else
				table.insert(AppList, v)
			end
		end
	end

	if not Found then
		table.insert(AppList, {
			ID = AppID,
			InstallDate = os.time(),
			InstallSource = InstallContext or "Manual ID install",
			Name = AppName ~= nil and AppName or "Unknown",
		})
	end

	Var.DataStores.AppDB:SetAsync("AppList", AppList)
	Utils.Logging.Print(`[✓] App {AppID} saved to DataStore ({#AppList} total entries)`)
	return { true, Utils.t(nil, "apps.Downloaded") }
end

--// Marketplace functions
function App.ServerAPI.GetList(SpecificServer: string, Area: string): {}
	-- Normalize: gateway expects 'FEATURED' | 'THEMES' | 'APPS' (uppercase)
	local AreaParam = string.upper(Area or "APPS")
	if AreaParam == "APP" then
		AreaParam = "APPS"
	end

	if Utils.GetSetting("DisableAOS") == true then
		Utils.Logging.Print("App server call ignored due to configuration.")
		return {}
	end

	-- Build server URL list: explicit server or fetch from info endpoint
	local ServerURLs = {}
	if SpecificServer ~= nil then
		Utils.Logging.Print(`GetList: using SpecificServer -> {SpecificServer}`)
		ServerURLs = { SpecificServer }
	else
		Utils.Logging.Print(`GetList: fetching AOS node list from {Var.AppServerInfoURL}/appservers`)
		local ok, Fetched = pcall(function()
			return HTTP.GetRoute(Var.AppServerInfoURL, "/appservers", function(Data, _)
				return Data
			end, function(_)
				return nil
			end)
		end)

		if not ok then
			Utils.Logging.Warn("GetList: failed to call AppServerInfo endpoint")
		else
			Utils.Logging.Print(
				"GetList: raw response from info endpoint:",
				type(Fetched) == "table" and (Var.Services.HttpService:JSONEncode(Fetched) or "<json-fail>")
					or tostring(Fetched)
			)
			if type(Fetched) == "table" then
				for _, URL in Fetched do
					table.insert(ServerURLs, URL)
				end
			end
		end
	end

	if #ServerURLs == 0 then
		Utils.Logging.Warn("GetList: no AOS nodes available from info endpoint or specific server provided.")
		return {}
	end

	-- Try each node; return first successful directory response
	for _, ServerURL in ServerURLs do
		Utils.Logging.Print(`GetList: probing node {ServerURL} for area {AreaParam}`)
		local FullList = {}

		local InstanceName = HTTP.GetRoute(ServerURL, "/pub/.administer", function(D, _)
			Utils.Logging.Print(`GetList: {ServerURL} returned instance name {D.instance_name}`)
			return D.instance_name
		end, function(err)
			Utils.Logging.Warn(`GetList: {ServerURL} /pub/.administer failed -> {tostring(err)}`)
			return "Unknown"
		end)

		local Result = HTTP.GetRoute(
			ServerURL,
			`/api/directory?asset_type={AreaParam}`,
			function(Apps, ResponseData): {}
				Utils.Logging.Print(
					`GetList: {ServerURL} directory replied with {tostring(#(type(Apps) == "table" and Apps or {}))} items`
				)
				for _, v in Apps do
					v["Server"] = ServerURL
					v["ServerName"] = InstanceName
					table.insert(FullList, v)
				end

				return { [ServerURL] = FullList }
			end,
			function(sc): {}
				Utils.Logging.Warn(`GetList: {ServerURL} /api/directory returned error code {tostring(sc)}`)
				return { [ServerURL] = { false, sc } }
			end
		)

		-- Return on first node that gives a valid (non-error) response
		if Result and Result[ServerURL] and Result[ServerURL][1] ~= false then
			Utils.Logging.Print(`GetList: successful node {ServerURL}, returning list`)
			return Result
		end

		Utils.Logging.Warn(`GetList: node {ServerURL} failed, trying next...`)
	end

	Utils.Logging.Warn("GetList: all AOS nodes failed to respond.")
	return {}
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
			Creator = ActingUser or 1,
		})

		Var.DataStores.AppDB:SetAsync("AppServerList", Var.AppServers)

		return { true, "Done!" }
	end, function(SC)
		Utils.Logging.Warn(`Failed to connect to AOS, is it running and accessible? (statuscode {SC})`)

		return { false, `AOS is not healthy or accessible. Got code {SC} on /pub/.administer` }
	end)
end

function App.ServerAPI.RegisterPrimary(URL: string, OverwriteExisting: boolean?): Types.Response
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
		Utils.Logging.Warn(
			`Failed to register this AOS instance as your primary, is it online and accepting primary registrations?`,
			...
		)

		return { false, Utils.t(nil, "generic.error.CheckLogs") }
	end)
end

function App.ServerAPI.GetServerStatuses(): Types.Response
	local Resps = {}

	for _, Server in Var.AppServers do
		xpcall(function()
			table.insert(
				Resps,
				HTTP.GetRoute(Server.ServerURL, "/pub/.administer", function(Data, Meta)
					return {
						URL = Server.ServerURL,
						Name = Data.instance_name,
						IsDev = Data.is_dev,
						Uptime = Data.uptime,
						Banner = Data.banner,
						AOSVers = Data.api_version,
						PingTime = Meta.ProcessedMS,
						InstalledBy = Server.Creator,
						ServerInstall = Server.Time,
						RawResp = Data,
					}
				end, function(Code, Data)
					return {
						URL = Server.ServerURL,
						Code = Code,
						Failed = true,
						PingTime = Data.ProcessedMS,
						InstalledBy = Server.Creator,
						ServerInstall = Server.Time,
					}
				end, {
					DontLookForAlts = true,
					Timeout = 15,
				})
			)
		end, function()
			return {
				URL = Server.ServerURL,
				Code = "Invalid server URL!",
				Failed = true,
				PingTime = 0,
				InstalledBy = Server.Creator,
				ServerInstall = Server.Time,
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
	end, function(...)
		return { false, ... }
	end)
end

function App.ServerAPI.InstallFromServer(ServerURL: string, AppID: string): Types.Response
	return HTTP.GetRoute(ServerURL, `/api/asset/{AppID}`, function(Content)
		local RealID = Content.InstallID
		if RealID == 0 then
			return { false, "This server gave us bad data, please report the error to the server owner." }
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

function App.ServerAPI.Vote(ServerURL: string, AppID: string, Vote: number): Types.Response
	return game:GetService("HttpService"):RequestAsync({
		Url = `{ServerURL}/api/asset/{AppID}/vote`,
		Method = "PUT",

		Body = game:GetService("HttpService"):JSONEncode({
			vote = Vote,
			is_favorite = Vote == 2,
		}),

		Headers = {
			["Content-Type"] = "application/json",
		},
	})
end

function App.ServerAPI.GetAOSInstances(DoStatusChecks: boolean): any
	local function DoStatusCheck(URL)
		local Start = tick()

		return HTTP.GetRoute(URL, "/pub/.administer", function(Data, Debugging)
			return {
				IsUp = true,
				Ping = Debugging.ProcessedMS,
				Version = Data.api_version,
				IsDev = Data.is_dev,
			}
		end, function(_, Data)
			return {
				IsUp = false,
				Ping = Data.ProcessedMS,
			}
		end)
	end

	Utils.Logging.Print(
		`GetAOSInstances: querying gateway at {Var.DefaultAppServer} (DoStatusChecks={tostring(DoStatusChecks)})`
	)

	return HTTP.GetRoute(Var.DefaultAppServer, `/`, function(Content)
		Utils.Logging.Print(
			"GetAOSInstances: gateway raw response:",
			type(Content) == "table" and (Var.Services.HttpService:JSONEncode(Content) or "<json-fail>")
				or tostring(Content)
		)
		if DoStatusChecks and type(Content.instances) == "table" then
			for _, URL in Content.instances do
				local Result = DoStatusCheck(URL.url)

				for Key, Value in Result do
					URL[Key] = Value
				end
			end
		end

		return Content.instances
	end, function(...)
		Utils.Logging.Warn("GetAOSInstances: Failed to get gateway reply:", ...)
	end)
end

function App.ServerAPI.Search(ServerURL, Query): {}
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
