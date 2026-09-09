--// Administer
--// CodingAgent 2026

local Variables = {}

local Typing = require(script.Parent.Types)
local Root = script.Parent.Parent.Parent

--// The items below this may be edited if you wish and it will not compromise Administer's security or functionality.
Variables.Config = require(script.Parent.Configuration) --// Config file location
Variables.AdministerRoot = Root --// Root folder of Administer (works from any location: ServerScriptService, Workspace, etc.)
Variables.RemotesPath = game.ReplicatedStorage --// Where remotes are stored
Variables.EnableFreeAdmin = false --// Makes every user a superadmin. Not recommended for anything other than debugging.
Variables.LocalAppsFolder = nil --// Optional folder containing local apps; leave empty to skip local app loading.

--Variables.DefaultAppServer           = "http://192.168.0.40:8020" --// Dev instance, ignore this
Variables.DefaultAppServer = "https://gateway.admsoftware.org" --// Gateway auto-selects the best AOS instance.
Variables.AppServerInfoURL = "https://api.admsoftware.org/appservers" --// Base URL; /appservers returns the list of available AOS node URLs
Variables.VersionCheckURL = "https://api.admsoftware.org/info" --// Version check API URL
Variables.ProxyURL = "https://proxy.admsoftware.org" --// Roblox proxy URL following format /RobloxSubdomain/<path>, so https://games.roblox.com//docs would resolve to https://proxy.CodingAgent.dev/games//docs.
Variables.Locales = script.Parent.Locales --// Locales location
Variables.AppPollingLimit = 50 --// How many times Administer will poll apps for being loaded before declaring the thread frozen.
Variables.WaitForBootstrap = false --// Whether or not we will wait for apps to load before sending out panels.
Variables.IsFirstBoot = false --// Setting this to true will fully reset your game's Administer store so be careful!! Use the Utilities app to do it properly

Variables.Services = setmetatable({}, {
	__index = function(self, Service)
		self[Service] = game:GetService(Service)
		return self[Service]
	end,
})

Variables.BaseHomeInfo = {
	_version = 1,
	Widget1 = "administer\\welcome",
	Widget2 = "administer\\unselected",

	TextWidgets = {
		"administer\\version-label",
		"administer\\server-uptime",
	},
}

local function makeStubDataStore(name: string)
	return {
		GetAsync = function(self, key)
			return nil
		end,
		SetAsync = function(self, key, value) end,
		UpdateAsync = function(self, key, fn) end,
		RemoveAsync = function(self, key) end,
		_isStub = true,
		_name = name,
	}
end

local _dsOk = false
local _dsErr = nil

local budget = 0
pcall(function()
	budget = Variables.Services.DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.GetAsync)
end)

if budget > 0 then
	local ok, err = pcall(function()
		Variables.Services.DataStoreService:GetDataStore("__adm_probe"):GetAsync("__probe")
	end)
	_dsOk = ok
	_dsErr = err
else
	_dsOk = false
	_dsErr = "DataStore request budget is 0 — API Services likely disabled"
end

if not _dsOk then
	warn(
		"[Administer] DataStoreService is unavailable — running in stub mode.\n"
			.. "  All data (admins, settings, app servers) will NOT persist this session.\n"
			.. "  To fix: publish your place to Roblox, or enable Studio Access to API Services\n"
			.. "  under Game Settings → Security → Enable Studio Access to API Services.\n"
			.. "  Reason: "
			.. tostring(_dsErr)
	)
end

local function getDS(storeName: string)
	if not _dsOk then
		return makeStubDataStore(storeName)
	end
	local ok, result = pcall(function()
		return Variables.Services.DataStoreService:GetDataStore(storeName)
	end)
	if ok then
		return result
	else
		warn("[Administer] Failed to get DataStore '" .. storeName .. "': " .. tostring(result))
		return makeStubDataStore(storeName)
	end
end

Variables.DataStores = {
	AdminsDS = getDS("Administer_Admins"),
	HomeDS = getDS("Administer_HomeStore"),
	AppDB = getDS("Administer_AppData"),
	Settings = getDS("Administer_Settings"),
}

Variables.DataStoreAvailable = _dsOk

Variables.Notification = {
	Ding = "",
	Error = "",
}

Variables.DidBootstrap = false
Variables.StaffData = {}
Variables.LogJoins = true
Variables.PanelFound = Root.Resources:FindFirstChild("AdministerMainPanel")
Variables.Branch = nil
Variables.DisableBootstrapProtection = true
Variables.IsRecentV1xMigration = false

Variables.ModuleSensitivity = {
	AdminRunner = 3,
	Apps = 3,
	Utilities = 2,
	HTTPRunner = 2,
	Settings = 1,
	Frontend = 1,
	Debugging = 1,
}

Variables.Admins = {
	InGame = {},

	OutOfGame = {},

	TotalRunningCount = 0,
}

Variables.InitClock = {
	RealInit = os.clock(),
	TempInit = os.clock(),
}

Variables.DefaultRank = {
	RankID = 0,
	Name = "Administrator",
	Protected = false,

	Members = {},
	Apps = {},

	Modified = os.time(),
	Modifications = {},

	CreatorID = 0,
	AdmRankVersion = 3,
}

Variables.DefaultRankData = {
	Count = 0,
	Names = {},
	GroupAdminIDs = {},
	AdminIDs = {},
}

Variables.CurrentBranch = {}
Variables.Branches = {
	Stable = {
		ImageID = "rbxassetid://18224047110",
		Name = "Administer",
		BranchName = "stable",
		IsActive = true,
	},
}

Variables.Panel = {
	Path = Root.Resources:FindFirstChild("AdministerMainPanel") ~= nil and Root.Resources:FindFirstChild(
		"AdministerMainPanel"
	) or game.StarterGui:FindFirstChild("AdministerMainPanel"),
}

Variables.CachedLocales = {}

Variables.AppServers = Variables.DataStores.AppDB:GetAsync("AppServerList") or {}

Variables.Panel.Spawn = function(Rank, Player)
	local stale = Player.PlayerGui:FindFirstChild("AdministerMainPanel")
	if stale then
		stale:Destroy()
	end

	local NewPanel = Variables.Panel.Path:Clone()
	local Tutorials = Variables.DataStores.AdminsDS:GetAsync("__Global_Tutorials") or {}

	xpcall(function()
		NewPanel:SetAttribute("_AdminRank", Rank.Name)
	end, function()
		NewPanel:SetAttribute("_AdminRank", "Administrator")
	end)

	NewPanel:SetAttribute(
		"_HomeWidgets",
		Variables.Services.HttpService:JSONEncode(
			Variables.DataStores.HomeDS:GetAsync(Player.UserId) or Variables.BaseHomeInfo
		)
	)

	NewPanel:SetAttribute(
		"_InstalledApps",
		Variables.Services.HttpService:JSONEncode((require(script.Parent.Parent.Modules.Apps).RunningApps) :: any)
	)

	NewPanel:SetAttribute("_CurrentBranch", Variables.Services.HttpService:JSONEncode(Variables.CurrentBranch))
	NewPanel:SetAttribute("StartID", Variables.Services.HttpService:GenerateGUID(false))
	local needsSetup = _dsOk and (Tutorials["FirstTimeSetup"] ~= true) or false
	NewPanel:SetAttribute("NeedsSetup", needsSetup)

	return NewPanel
end

Variables.Init = function()
	local RF = Instance.new("Folder", Variables.RemotesPath)
	RF.Name = "__AdmPending"
	Variables.RemotesPath = RF

	local AppRemotes = Instance.new("Folder", Variables.RemotesPath)
	AppRemotes.Name = "Apps"

	for Branch, Object in Variables.Branches :: { Typing.AdmBranch } do
		Object["BranchName"] = Branch

		if Object["IsActive"] then
			Variables.CurrentBranch = Object
		end
	end

	Variables.InitTimestamp = {
		Time = os.time(),
		Tick = tick(),
	}

	for _, Server in Variables.AppServers do
		if Server.IsPrimary then
			Variables.PrimaryAppServer = Server.ServerURL
		end
	end

	local ok, customServer = pcall(function()
		return Variables.DataStores.AppDB:GetAsync("CustomAOSServer")
	end)
	if ok and customServer and customServer ~= "" then
		Variables.PrimaryAppServer = customServer
	else
		Variables.PrimaryAppServer = nil
	end
end

return Variables
