--// Administer 
--// pyxfluff 2024 - 2025

local Variables = {}

local Typing = require(script.Parent.Types)
local Root   = script.Parent.Parent.Parent

local Config = require(script.Parent.Configuration)

--// The items below this may be edited if you wish and it will not compromise Administer's security or functionality.
Variables.Config                     = require(script.Parent.Configuration) --// Config file location
Variables.RemotesPath                = game.ReplicatedStorage --// Where remotes are stored
Variables.EnableFreeAdmin            = false --// Makes every user a superamdin. Not recommended for anything other than debugging.

--Variables.DefaultAppServer           = "http://192.168.0.40:8020" --// Dev instance, ignore this
Variables.DefaultAppServer           = "https://aos-us-1.admsoftware.org" --// Must be an AOS app server instance.
Variables.ProxyURL                   = "https://proxy.pyxfluff.dev" --// Roblox proxy URL following format {{ domain }}/SUBDOMAIN/path
Variables.Locales                    = script.Parent.Locales --// Locales location
Variables.AppPollingLimit            = 50 --// How many times Administer will poll apps for being loaded before declaring the thread frozen.
Variables.WaitForBootstrap           = false --// Whether or not we will wait for apps to load before sending out panels.
Variables.IsFirstBoot                = false --// Setting this to true will fully reset your game's Administer store so be careful!! Use the Utilities app to do it properly

Variables.Services = setmetatable({}, {
    __index = function(self, Service)
        self[Service] = game:GetService(Service)
        return self[Service]
    end
})

--// The scheme is `app\widget-title`, anything will work here
--// as long as it exists.
Variables.BaseHomeInfo = {
	_version = 1,
	Widget1 = "administer\\welcome",
	Widget2 = "administer\\unselected",
	
	TextWidgets = {
		"administer\\version-label",
		"administer\\server-uptime"
	}
}

Variables.DataStores = {
	AdminsDS   = Variables.Services.DataStoreService:GetDataStore("Administer_Admins"),
	HomeDS     = Variables.Services.DataStoreService:GetDataStore("Administer_HomeStore"),
	AppDB      = Variables.Services.DataStoreService:GetDataStore("Administer_AppData"),
	Settings   = Variables.Services.DataStoreService:GetDataStore("Administer_Settings")
}

Variables.Notification = {
    Ding  = "",
    Error = ""
}

--// WARNING: EVERYTHING BELOW THIS LINE IS AUTOMATED AND SHOULD NOT BE EDITED.
--// DOING SO WILL BREAK YOUR GAME OR ADMINISTER.
--// IF YOU WANT TO HARDCODE ADMINS, SEE ./Configuration
Variables.DidBootstrap               = false
Variables.LogJoins                   = true
Variables.PanelFound                 = Root.Resources:FindFirstChild("AdministerMainPanel")
Variables.Branch                     = nil
Variables.DisableBootstrapProtection = true
Variables.IsRecentV1xMigration       = false

--// Note to self: when adding these, remember to type in the Types file!!
Variables.ModuleSensitivity = {
    AdminRunner  = 3,
    Apps         = 3,
    Utilities    = 2, --// This one is so general purpose it's just safest to mark it as mild
    HTTPRunner   = 2,
    Settings     = 1,
    Frontend     = 1,
    Debugging    = 1
}

Variables.Admins = {
	InGame = {},

	OutOfGame = {},

	TotalRunningCount = 0
}

Variables.InitClock = {
	RealInit = os.clock(),
	TempInit = os.clock()
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
	AdmRankVersion = 3
}

Variables.DefaultRankData = {
	Count = 0,
	Names = {},
	GroupAdminIDs = {},
	AdminIDs = {}
}

Variables.CurrentBranch = {}
Variables.Branches = {
	Internal = {
		ImageID = "rbxassetid://18841275783",
		Name = "Administer Internal",
		BranchName = "canary",
		IsActive = false
	},

	QualityAssurance = {
		ImageID = "rbxassetid://76508533583525",
		Name = "Administer QA Release",
		BranchName = "qualassur",
		IsActive = false
	},

	Fresh = {
		ImageID = "rbxassetid://18224047110",
		Name = "Administer (git)",
		BranchName = "git",
		IsActive = false
	},

	Beta = {
		ImageID = "rbxassetid://18770010888",
		Name = "Administer Public Beta",
		BranchName = "pub_beta",
		IsActive = true
	},

	Stable = {
		ImageID = "rbxassetid://18224047110",
		Name = "Administer",
		BranchName = "stable",
		IsActive = false
	}
}

Variables.Panel = {
	Path = Root.Resources:FindFirstChild("AdministerMainPanel") ~= nil and Root.Resources:FindFirstChild("AdministerMainPanel") or game.StarterGui:FindFirstChild("AdministerMainPanel") 
}

Variables.CachedLocales = {}

Variables.AppServers = Variables.DataStores.AppDB:GetAsync("AppServerList") or {}

Variables.Panel.Spawn = function(Rank, Player)
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
	NewPanel:SetAttribute("NeedsSetup", Tutorials["FirstTimeSetup"] ~= true)
	
	return NewPanel
end

Variables.Init = function()
	local RF = Instance.new("Folder", Variables.RemotesPath)
	RF.Name = "Administer"
	Variables.RemotesPath = RF
	
	local AppRemotes = Instance.new("Folder", Variables.RemotesPath)
	AppRemotes.Name = "Apps"

	for Branch, Object in Variables.Branches :: { Typing.AdmBranch } do
		Object["BranchName"] = Branch

		if Object["IsActive"] then Variables.CurrentBranch = Object end
	end

	Variables.InitTimestamp = {
		Time = os.time(),
		Tick = tick()
	}
	
	for _, Server in Variables.AppServers do
		if Server.IsPrimary then
			Variables.PrimaryAppServer = Server.ServerURL
		end
	end
end

return Variables
