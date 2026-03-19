--// Administer
--// CodingAgent 2026

--// Initialization
local App = {
	ServerAPI = {},
	InvocationAPI = {},

	RunningApps = {},
}

local Ticks = {}

local Root = script:FindFirstAncestor("Loader")
local AdmConfig = require(Root.Core.Configuration)
local HTTP = require(Root.Modules.HTTPRunner)
local Types = require(Root.Core.Types)
local Utils = require(Root.Modules.Utilities)
local Var = require(Root.Core.Variables)

local AppLifecycleEvent = Utils.NewRemote("RemoteEvent", "AppLifecycle", false, function() end)

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

	if not Config.Bootstrap then
		return { false, "bootstrap function must not be nil" }
	elseif
		not Misc.AosVersionValidated
		and not IsVersionSupported(AdmConfig.VersData.APIRevision, Config.Dependencies.AppPlatform)
	then
		return {
			false,
			`this app does not support your application platform! expected {Config.Dependencies.AppPlatform}, got {AdmConfig.VersData.APIRevision}`,
		}
	elseif
		not Misc.AosVersionValidated
		and not IsVersionSupported(AdmConfig.VersData.String, Config.Dependencies.Administer)
	then
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

	task.spawn(function()
		Config.Bootstrap({}, Config.State, {
			FinishTime = string.sub(tostring(tick() - Ticks[Misc.TechID]), 1, 5),
			RunContext = Misc.RunContext,
			RanksWithAccess = 0,

			Modules = Modules :: any,
		})
	end)

	return { true, Config }
end

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
		AosVersionValidated = AppMeta.AosVersionValidated == true,
	}
	local TargetApp, RealApp =
		{}, require(Path)(App.InvocationAPI, Extras) :: { Success: boolean, RichConfig: Types.RichConfig }

	if not RealApp[1] then
		Utils.Logging.Warn(
			"This app cannot be loaded as it has failed a test, this is probably due to an outdated Administer version. The server says: ",
			RealApp[2]
		)

		return { false, tostring(RealApp[2]) }
	end

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
		TargetApp.ClientFrameName = RealApp[2].ClientFrame ~= nil and RealApp[2].ClientFrame.Name or nil

		Utils.Logging.Print(`[✓] App bootstrap OK in {Utils.RoundMS(tick() - Ticks[Path])}ms`)

		App.RunningApps[RealApp[2].AppMeta.Name] = TargetApp
	end, function(e)
		Utils.Logging.Warn(`[X] Failed bootstrapping app: {e}`)
	end)

	return { true, TargetApp }
end

function App.Initialize(): boolean
	local DelaySetting, Apps = Utils.GetSetting("AppLoadDelay"), Var.DataStores.AppDB:GetAsync("AppList") or {}
	local i, TotalAttempts, Start = 0, 0, tick()

	Utils.Logging.Print("Bootstrapping apps...")

	if Utils.GetSetting("LoadApps") == false then
		Utils.Logging.Print(`App Bootstrapping disabled due to configuration, please disable!`)

		Var.DidBootstrap = true
		return false
	end

	if DelaySetting == "InStudio" and Var.Services.RunService:IsStudio() or DelaySetting == "All" then
		task.wait(3)
	end

	if Var.LocalAppsFolder then
		for _, App in Var.LocalAppsFolder:GetChildren() do
			table.insert(Apps, {
				ID = App,
				InstallDate = 0,
				InstallSource = "",
				IsPhysicalApp = true,
			})
		end
	end

	local AppsCount = #Apps

	for _, AppObj in Apps do
		Utils.Logging.Print(`Importing app:`, AppObj)
		task.defer(function()
			App.LoadLocal(AppObj.ID, {
				InstallDate = AppObj.InstallDate,
				InstallSource = AppObj.InstallSource,
				AppID = AppObj.ID,
				AosVersionValidated = AppObj.AosVersionValidated,
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

	task.defer(function()
		App.RecoverApps()
	end)

	task.defer(function()
		App.SyncWithAOS()
	end)

	Var.DidBootstrap = true

	return true
end

function App.SyncWithAOS()
	warn(`[AOS-DEBUG][SyncWithAOS] START PlaceId={tostring(game.PlaceId)}`)
	if Utils.GetSetting("DisableAOS") == true then
		warn(`[AOS-DEBUG][SyncWithAOS] SKIP DisableAOS=true`)
		return
	end

	local RawList = Var.DataStores.AppDB:GetAsync("AppList") or {}
	warn(`[AOS-DEBUG][SyncWithAOS] DS AppList has {#RawList} total entries`)
	for idx, v in RawList do
		warn(
			`[AOS-DEBUG][SyncWithAOS]   DS[{idx}] ID={tostring(v and v.ID)} AOSID={tostring(v and v.AOSID)} Src={tostring(
				v and v.InstallSource
			)} Physical={tostring(v and v.IsPhysicalApp)}`
		)
	end

	local byServer = {}
	for _, v in RawList do
		if v and not v.IsPhysicalApp and v.AOSID and v.InstallSource and v.InstallSource ~= "" then
			if not byServer[v.InstallSource] then
				byServer[v.InstallSource] = {}
			end
			table.insert(byServer[v.InstallSource], v)
		end
	end

	for _, serverEntry in Var.AppServers do
		local url = serverEntry.ServerURL
		if url and not byServer[url] then
			byServer[url] = {}
		end
	end

	local serverCount = 0
	for _ in byServer do
		serverCount += 1
	end
	warn(`[AOS-DEBUG][SyncWithAOS] Servers to reconcile: {serverCount}`)

	for serverURL, dsEntries in byServer do
		warn(`[AOS-DEBUG][SyncWithAOS] Reconciling {serverURL} — DS has {#dsEntries} entries`)

		local ok, aosApps = pcall(function()
			return HTTP.GetRoute(serverURL, "/api/asset/list", function(Data)
				warn(
					`[AOS-DEBUG][SyncWithAOS] /api/asset/list hasData={tostring(
						type(Data) == "table" and Data.data ~= nil
					)}`
				)
				if type(Data) == "table" and Data.data then
					return Data.data
				end
				return {}
			end, function(err)
				warn(`[AOS-DEBUG][SyncWithAOS] /api/asset/list FAILED err={tostring(err)}`)
				Utils.Logging.Warn(`[SyncWithAOS] Failed to fetch /api/asset/list from {serverURL}: {tostring(err)}`)
				return nil
			end)
		end)
		warn(
			`[AOS-DEBUG][SyncWithAOS] GetRoute ok={tostring(ok)} count={type(aosApps) == "table" and #aosApps or "n/a"}`
		)

		if not ok or not aosApps then
			warn(`[AOS-DEBUG][SyncWithAOS] SKIP {serverURL} — list fetch failed`)
			Utils.Logging.Warn(`[SyncWithAOS] Skipping {serverURL} — list fetch failed`)
			continue
		end

		local aosSet = {}
		local dsSet = {}

		for _, aosEntry in aosApps do
			if aosEntry.id then
				aosSet[tostring(aosEntry.id)] = true
				warn(`[AOS-DEBUG][SyncWithAOS]   AOS knows: {tostring(aosEntry.id)}`)
			end
		end
		for _, entry in dsEntries do
			dsSet[tostring(entry.AOSID)] = entry
			warn(`[AOS-DEBUG][SyncWithAOS]   DS  wants: {tostring(entry.AOSID)}`)
		end

		for aosID, entry in dsSet do
			if not aosSet[aosID] then
				Utils.Logging.Print(`[SyncWithAOS] Re-registering {aosID} on {serverURL}`)
				task.spawn(function()
					local postURL = `{serverURL}/api/asset/{aosID}/install`
					warn(`[AOS-DEBUG][SyncWithAOS] POST (install) {postURL}`)
					local postOk, postResp = pcall(function()
						return Var.Services.HttpService:RequestAsync({
							Url = postURL,
							Method = "POST",
							Headers = { ["Content-Type"] = "application/json" },
							Body = "{}",
						})
					end)
					if postOk then
						warn(
							`[AOS-DEBUG][SyncWithAOS] install POST StatusCode={tostring(
								type(postResp) == "table" and postResp.StatusCode
							)} Body={tostring(type(postResp) == "table" and postResp.Body)}`
						)
						Utils.Logging.Print(`[SyncWithAOS] Re-registered {aosID}`)
					else
						warn(`[AOS-DEBUG][SyncWithAOS] install POST FAILED err={tostring(postResp)}`)
						Utils.Logging.Warn(`[SyncWithAOS] Failed to re-register {aosID}: {tostring(postResp)}`)
					end
				end)
			end
		end

		for aosID in aosSet do
			if not dsSet[aosID] then
				Utils.Logging.Print(`[SyncWithAOS] Evicting stale AOS entry {aosID} from {serverURL}`)
				task.spawn(function()
					local uninstallURL = `{serverURL}/api/asset/{aosID}/uninstall`
					warn(`[AOS-DEBUG][SyncWithAOS] POST (uninstall) {uninstallURL}`)
					local postOk, postResp = pcall(function()
						return Var.Services.HttpService:RequestAsync({
							Url = uninstallURL,
							Method = "POST",
							Headers = { ["Content-Type"] = "application/json" },
							Body = "{}",
						})
					end)
					if postOk then
						warn(
							`[AOS-DEBUG][SyncWithAOS] uninstall POST StatusCode={tostring(
								type(postResp) == "table" and postResp.StatusCode
							)} Body={tostring(type(postResp) == "table" and postResp.Body)}`
						)
						Utils.Logging.Print(`[SyncWithAOS] Evicted {aosID}`)
					else
						warn(`[AOS-DEBUG][SyncWithAOS] uninstall POST FAILED err={tostring(postResp)}`)
						Utils.Logging.Warn(`[SyncWithAOS] Failed to evict {aosID}: {tostring(postResp)}`)
					end
				end)
			end
		end
	end
	warn(`[AOS-DEBUG][SyncWithAOS] DONE`)
end

function App.RecoverApps()
	local RawList = Var.DataStores.AppDB:GetAsync("AppList") or {}

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

	for i = #ToRemove, 1, -1 do
		table.remove(AppList, ToRemove[i])
	end

	if Changed or #AppList ~= #RawList then
		Utils.Logging.Print(`[RecoverApps] Writing compacted AppList ({#AppList} entries)`)
		Var.DataStores.AppDB:SetAsync("AppList", AppList)
	end
end

function App.Uninstall(AppID: number): Types.Response
	local Apps = Var.DataStores.AppDB:GetAsync("AppList") or {}
	local DidUninstall = false
	local evictedAppName = nil
	local evictedFrameName = nil
	local evictedAOSID = nil
	local evictedServerURL = nil

	if type(AppID) == "string" then
		for appName, RunningApp in App.RunningApps do
			if appName == AppID or tostring(RunningApp.AppID) == AppID then
				AppID = RunningApp.AppID
				evictedAppName = appName
				break
			end
		end
	end

	Utils.Logging.Warn(`Removing app {AppID}`)

	for i = #Apps, 1, -1 do
		local AppEntry = Apps[i]
		if AppEntry and AppEntry.ID == AppID then
			Utils.Logging.Print("Successfully uninstalled", AppEntry)
			if not evictedAppName then
				evictedAppName = AppEntry.Name
			end
			if not evictedAOSID then
				evictedAOSID = AppEntry.AOSID
			end
			if not evictedServerURL then
				evictedServerURL = AppEntry.InstallSource
			end
			table.remove(Apps, i)
			DidUninstall = true
		end
	end

	Var.DataStores.AppDB:SetAsync("AppList", Apps)

	warn(
		`[AOS-DEBUG][Uninstall] DidUninstall={tostring(DidUninstall)} evictedAOSID={tostring(evictedAOSID)} evictedServerURL={tostring(
			evictedServerURL
		)}`
	)
	if DidUninstall and evictedAOSID and evictedServerURL and evictedServerURL ~= "" then
		task.spawn(function()
			local uninstallURL = `{evictedServerURL}/api/asset/{evictedAOSID}/uninstall`
			warn(`[AOS-DEBUG][Uninstall] POST {uninstallURL} Place-Id={tostring(game.PlaceId)}`)
			local ok, resp = pcall(function()
				return Var.Services.HttpService:RequestAsync({
					Url = uninstallURL,
					Method = "POST",
					Headers = {
						["Content-Type"] = "application/json",
						["Place-Id"] = tostring(game.PlaceId),
					},
					Body = "{}",
				})
			end)
			if not ok then
				warn(`[AOS-DEBUG][Uninstall] POST pcall FAILED err={tostring(resp)}`)
				Utils.Logging.Warn(`[Uninstall] POST /uninstall failed for {evictedAOSID}: {tostring(resp)}`)
			else
				warn(`[AOS-DEBUG][Uninstall] POST StatusCode={tostring(resp.StatusCode)} Body={tostring(resp.Body)}`)
				Utils.Logging.Print(`[Uninstall] AOS notified for {evictedAOSID}`)
			end
		end)
	else
		warn(
			`[AOS-DEBUG][Uninstall] Skipping AOS POST — DidUninstall={tostring(DidUninstall)} AOSID={tostring(
				evictedAOSID
			)} Src={tostring(evictedServerURL)}`
		)
	end

	if DidUninstall then
		pcall(function()
			for appName, RunningApp in App.RunningApps do
				if tostring(RunningApp.AppID) == tostring(AppID) then
					evictedFrameName = RunningApp.ClientFrameName
					evictedAppName = evictedAppName or appName
					App.RunningApps[appName] = nil
					break
				end
			end

			if evictedFrameName then
				local panelMain = Var.Panel.Path and Var.Panel.Path:FindFirstChild("Main")
				if panelMain then
					local tmplFrame = panelMain:FindFirstChild(evictedFrameName)
					if tmplFrame then
						tmplFrame:Destroy()
					end
				end

				for _, player in Var.Services.Players:GetPlayers() do
					local panel = player.PlayerGui:FindFirstChild("AdministerMainPanel")
					local main = panel and panel:FindFirstChild("Main")
					local liveFrame = main and main:FindFirstChild(evictedFrameName)
					if liveFrame then
						liveFrame:Destroy()
					end
				end
			end
		end)

		local ok, err = pcall(function()
			local evt = AppLifecycleEvent or Var.RemotesPath:FindFirstChild("AppLifecycle")
			if evt and evt:IsA("RemoteEvent") then
				(evt :: RemoteEvent):FireAllClients("uninstalled", {
					AppID = AppID,
					AppName = evictedAppName,
					ClientFrameName = evictedFrameName,
				})
			end
		end)

		if not ok then
			Utils.Logging.Warn(`[AppLifecycle] Failed to notify clients about uninstall: {tostring(err)}`)
		end
	end

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

function App.Install(
	AppID: number,
	InstallContext: string,
	AppName: string,
	AosVersionValidated: boolean?,
	AOSID: string?
): Types.Response
	warn(
		`[AOS-DEBUG][Install] START AppID={tostring(AppID)} AOSID={tostring(AOSID)} Name={tostring(AppName)} Src={tostring(
			InstallContext
		)} AosValidated={tostring(AosVersionValidated)}`
	)
	Utils.Logging.Print(`[-] Attempting to install app {AppID} from {InstallContext}`)

	for _, RunningApp in App.RunningApps do
		if tostring(RunningApp.AppID) == tostring(AppID) then
			warn(`[AOS-DEBUG][Install] DUPLICATE BLOCKED AppID={tostring(AppID)}`)
			Utils.Logging.Warn(`[x] App {AppID} is already running, blocking duplicate install`)
			return { false, Utils.t(nil, "apps.DupeDetected") }
		end
	end

	local LoadResult
	local ok, err = pcall(function()
		LoadResult = App.LoadLocal(AppID, {
			InstallDate = os.time(),
			InstallSource = InstallContext,
			AppID = AppID,
			AosVersionValidated = AosVersionValidated == true,
		})
	end)
	warn(
		`[AOS-DEBUG][Install] LoadLocal ok={tostring(ok)} result[1]={tostring(LoadResult and LoadResult[1])} err={tostring(
			err
		)}`
	)

	if not ok or not LoadResult or not LoadResult[1] then
		warn(`[AOS-DEBUG][Install] FAILED load err={tostring(err or (LoadResult and LoadResult[2]))}`)
		Utils.Logging.Warn(`[x] App load failed: {tostring(err or (LoadResult and LoadResult[2]))}\n`)
		return { false, `Failure: {tostring(err or (LoadResult and LoadResult[2]))}` }
	end

	Utils.Logging.Print(`[✓] App bootstrap OK, saving to DataStore`)

	local RawList = Var.DataStores.AppDB:GetAsync("AppList") or {}
	warn(`[AOS-DEBUG][Install] DS AppList has {#RawList} entries before upsert`)
	local AppList = {}
	local Found = false
	for _, v in RawList do
		if v then
			if tostring(v.ID) == tostring(AppID) then
				warn(
					`[AOS-DEBUG][Install] UPSERT replacing existing entry ID={tostring(v.ID)} AOSID={tostring(v.AOSID)}`
				)
				table.insert(AppList, {
					ID = AppID,
					AOSID = AOSID or v.AOSID,
					InstallDate = os.time(),
					InstallSource = InstallContext or "Manual ID install",
					Name = AppName ~= nil and AppName or "Unknown",
					AosVersionValidated = AosVersionValidated == true,
				})
				Found = true
			else
				table.insert(AppList, v)
			end
		end
	end

	if not Found then
		warn(`[AOS-DEBUG][Install] APPEND new entry ID={tostring(AppID)} AOSID={tostring(AOSID)}`)
		table.insert(AppList, {
			ID = AppID,
			AOSID = AOSID,
			InstallDate = os.time(),
			InstallSource = InstallContext or "Manual ID install",
			Name = AppName ~= nil and AppName or "Unknown",
			AosVersionValidated = AosVersionValidated == true,
		})
	end

	Var.DataStores.AppDB:SetAsync("AppList", AppList)
	warn(`[AOS-DEBUG][Install] DS saved. Total entries={#AppList}. Final list:`)
	for idx, entry in AppList do
		warn(
			`[AOS-DEBUG][Install]   [{idx}] ID={tostring(entry.ID)} AOSID={tostring(entry.AOSID)} Name={tostring(
				entry.Name
			)} Src={tostring(entry.InstallSource)}`
		)
	end
	Utils.Logging.Print(`[✓] App {AppID} saved to DataStore ({#AppList} total entries)`)
	return { true, Utils.t(nil, "apps.Downloaded") }
end

function App.ServerAPI.GetList(SpecificServer: string, Area: string): {}
	local AreaParam = string.upper(Area or "APPS")
	if AreaParam == "APP" then
		AreaParam = "APPS"
	end

	if Utils.GetSetting("DisableAOS") == true then
		Utils.Logging.Print("App server call ignored due to configuration.")
		return {}
	end

	local ServerURLs = {}
	if SpecificServer ~= nil then
		Utils.Logging.Print(`GetList: using SpecificServer -> {SpecificServer}`)
		ServerURLs = { SpecificServer }
	else
		Utils.Logging.Print(`GetList: fetching AOS node list from {Var.AppServerInfoURL}`)
		local ok, Fetched = pcall(function()
			return HTTP.GetRoute(Var.AppServerInfoURL, "", function(Data, _)
				Utils.Logging.Print(
					`GetList: raw response from info endpoint: {type(Data) == "table" and Var.Services.HttpService:JSONEncode(
						Data
					) or tostring(Data)}`
				)
				return Data
			end, function(sc)
				Utils.Logging.Warn(`GetList: AppServerInfo endpoint failed with code {tostring(sc)}`)
				return nil
			end)
		end)

		if not ok or not Fetched then
			Utils.Logging.Warn("GetList: failed to call AppServerInfo endpoint or got nil response")
		elseif type(Fetched) == "table" then
			for _, URL in Fetched do
				table.insert(ServerURLs, URL)
			end
		end
	end

	if #ServerURLs == 0 then
		Utils.Logging.Warn("GetList: no AOS nodes available from info endpoint or specific server provided.")
		return {}
	end

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
				local AppCount = type(Apps) == "table" and #Apps or 0
				Utils.Logging.Print(`GetList: {ServerURL} directory replied with {tostring(AppCount)} items`)
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

		if Result and Result[ServerURL] and Result[ServerURL][1] ~= false and #(Result[ServerURL] or {}) > 0 then
			Utils.Logging.Print(`GetList: node {ServerURL} succeeded with {#Result[ServerURL]} apps, returning`)
			return Result
		end

		if Result and Result[ServerURL] and (Result[ServerURL][1] ~= false and #(Result[ServerURL] or {}) == 0) then
			Utils.Logging.Print(`GetList: node {ServerURL} had no apps, trying next node...`)
		else
			Utils.Logging.Warn(`GetList: node {ServerURL} failed, trying next...`)
		end
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
	warn(
		`[AOS-DEBUG][InstallFromServer] START ServerURL={tostring(ServerURL)} AppID={tostring(AppID)} PlaceId={tostring(
			game.PlaceId
		)}`
	)
	return HTTP.GetRoute(ServerURL, `/api/asset/{AppID}`, function(Content)
		warn(
			`[AOS-DEBUG][InstallFromServer] GET /api/asset/{AppID} response: {Var.Services.HttpService:JSONEncode(
				Content
			)}`
		)
		local RealID = Content.InstallID
		warn(`[AOS-DEBUG][InstallFromServer] RealID={tostring(RealID)}`)
		if RealID == 0 then
			warn(`[AOS-DEBUG][InstallFromServer] FAIL RealID is 0 (bad server data)`)
			return { false, "This server gave us bad data, please report the error to the server owner." }
		end

		local AosVersionValidated = false
		local AosPrefVersion = Content.Metadata and Content.Metadata.AppAPIPreferredVersion
		warn(
			`[AOS-DEBUG][InstallFromServer] AosPrefVersion={tostring(AosPrefVersion)} CurrentVers={tostring(
				AdmConfig.VersData.String
			)}`
		)
		if AosPrefVersion then
			AosVersionValidated = IsVersionSupported(AdmConfig.VersData.String, AosPrefVersion)
			if not AosVersionValidated then
				warn(
					`[AOS-DEBUG][InstallFromServer] FAIL version mismatch required={AosPrefVersion} have={AdmConfig.VersData.String}`
				)
				return {
					false,
					`This app requires Administer {AosPrefVersion}, but you have {AdmConfig.VersData.String}.`,
				}
			end
			Utils.Logging.Print(
				`[InstallFromServer] AOS version check passed ({AdmConfig.VersData.String} in {AosPrefVersion})`
			)
		end

		warn(
			`[AOS-DEBUG][InstallFromServer] Calling App.Install RealID={tostring(RealID)} AOSID={tostring(AppID)} Name={tostring(
				Content["Name"]
			)}`
		)
		local Result: Types.Response = App.Install(RealID, ServerURL, Content["Name"], AosVersionValidated, AppID)
		warn(`[AOS-DEBUG][InstallFromServer] App.Install returned ok={tostring(Result[1])} msg={tostring(Result[2])}`)

		if Result[1] then
			local postURL = `{ServerURL}/api/asset/{AppID}/install`
			warn(`[AOS-DEBUG][InstallFromServer] POST {postURL} with Place-Id={tostring(game.PlaceId)}`)
			local ok, Response = pcall(function()
				return Var.Services.HttpService:RequestAsync({
					Url = postURL,
					Method = "POST",
					Headers = {
						["Content-Type"] = "application/json",
						["Place-Id"] = tostring(game.PlaceId),
					},
					Body = "{}",
				})
			end)

			if not ok then
				warn(`[AOS-DEBUG][InstallFromServer] POST pcall FAILED err={tostring(Response)}`)
				Utils.Logging.Warn(`[InstallFromServer] POST /install request failed: {tostring(Response)}`)
				return { true, `{Utils.t(nil, "generic.Done")}!` }
			end

			warn(
				`[AOS-DEBUG][InstallFromServer] POST StatusCode={tostring(Response.StatusCode)} Body={tostring(
					Response.Body
				)}`
			)

			if Response.StatusCode == 200 or Response.StatusCode == 400 then
				return { true, `{Utils.t(nil, "generic.Done")}!` }
			end

			warn(`[AOS-DEBUG][InstallFromServer] FAIL unexpected status {Response.StatusCode}`)
			Utils.Logging.Warn(`[InstallFromServer] POST /install returned {Response.StatusCode}`)
			return { false, Utils.t(nil, "generic.error.TryAgainLater") }
		else
			warn(`[AOS-DEBUG][InstallFromServer] App.Install failed, skipping AOS POST`)
			Utils.Logging.Warn("App did not install with an OK status code, ignoring request to tell AOS.")
			return Result
		end
	end, function(c)
		warn(`[AOS-DEBUG][InstallFromServer] GET /api/asset/{AppID} FAILED code={tostring(c)}`)
		return { false, string.format(Utils.t(nil, "apps.pulled.Bad"), c) }
	end)
end

function App.ServerAPI.Vote(ServerURL: string, AppID: string, Vote: number): Types.Response
	if not ServerURL or ServerURL == "" then
		ServerURL = Var.PrimaryAppServer ~= "" and Var.PrimaryAppServer ~= nil and Var.PrimaryAppServer
			or Var.DefaultAppServer
	end

	return game:GetService("HttpService"):RequestAsync({
		Url = `{ServerURL}/api/asset/{AppID}/vote`,
		Method = "PUT",

		Body = game:GetService("HttpService"):JSONEncode({
			vote = Vote,
			is_favorite = false,
		}),

		Headers = {
			["Content-Type"] = "application/json",
			["X-Adm-Version"] = AdmConfig.VersData.NoExtraData,
			["X-Adm-Branch"] = string.upper(Var.CurrentBranch.BranchName),
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

	return Var.AppServers[1] and Var.AppServers[1].ServerURL or nil
end

function App.GetTotals()
	local RunningApps = 0

	for _, App in App.RunningApps do
		RunningApps += 1
	end

	return { Servers = #Var.AppServers, Apps = RunningApps }
end

return App
