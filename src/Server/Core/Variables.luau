--// Administer 
--// (pyxfluff + FloofyPlasma) 2024 - 2025
-- stylua: ignore start
local Variables = {}

--// The items below this until the warning may be edited if you wish and it will not compromise Administer's security or functionality.
--// If you change too many functionality-related variables and Administer does not boot you will NOT be elligible for support.
Variables.Config                     = require(script.Parent.Configuration)
Variables.DidBootstrap               = false
Variables.WaitForBootstrap           = false
Variables.LogJoins                   = true
Variables.PanelFound                 = script.Parent.Parent.Resources:FindFirstChild("AdministerMainPanel")
Variables.Branch                     = nil
Variables.RemotesPath                = game.ReplicatedStorage
Variables.EnableFreeAdmin            = false
Variables.DisableBootstrapProtection = true
Variables.IsFirstBoot                = false

Variables.DefaultAppServer           = "https://administer.notpyx.me"
Variables.ProxyURL                   = "https://rblx.notpyx.me"

Variables.DefaultLocale              = "en-us"
Variables.Locales                    = script.Parent.Locales

Variables.Services = {
	ContentProvider      = game:GetService("ContentProvider"),
	MarketplaceService   = game:GetService("MarketplaceService"),
	ReplicatedStorage    = game:GetService("ReplicatedStorage"),
	DataStoreService     = game:GetService("DataStoreService"),
	HttpService          = game:GetService("HttpService"),
	TextService          = game:GetService("TextService"),
	TweenService         = game:GetService("TweenService"),
	GroupService         = game:GetService("GroupService"),
	MessagingService     = game:GetService("MessagingService"),
	Players              = game:GetService("Players"),
	RunService           = game:GetService("RunService")
}

Variables.BaseHomeInfo = {
	["_version"] = 1,
	["Widget1"] = "administer\\welcome",
	["Widget2"] = "administer\\unselected",
	["TextWidgets"] = {
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

--// WARNING: EVERYTHING BELOW THIS LINE IS AUTOMATED AND SHOULD NOT BE EDITED.
--// IF YOU WANT TO HARDCODE ADMINS, SEE Configuration.luau
-- stylua: ignore end

Variables.Admins = {
	InGame = {},

	OutOfGame = {},

	TotalRunningCount = 0,
}

Variables.ThemeColors = {
	DefaultDark = {},
}

Variables.InitClock = {
	RealInit = os.clock(),
	TempInit = os.clock(),
}

Variables.DefaultRank = {
	["RankID"] = 0,
	["RankName"] = require(Variables.Locales[Variables.DefaultLocale])["admin.RankDefault"],
	["Protected"] = false,

	["Members"] = {},
	["Apps"] = {},

	["Modified"] = os.time(),
	["Modifications"] = {},

	["CreatorID"] = 0,
	["AdmRankVersion"] = 2,
}

Variables.DefaultRankData = {
	Count = 1,
	Names = {},
	GroupAdminIDs = {},
	AdminIDs = {},
}

Variables.CurrentBranch = { Name = "" }
Variables.Branches = {
	["Interal"] = {
		["ImageID"] = "rbxassetid://18841275783",
		["UpdateLog"] = 18336751142,
		["Name"] = "Administer Internal",
		["IsActive"] = false,
	},

	["QA"] = {
		["ImageID"] = "rbxassetid://76508533583525",
		["UpdateLog"] = 18336751142,
		["Name"] = "Administer QA",
		["IsActive"] = false,
	},

	["Canary"] = {
		["ImageID"] = "rbxassetid://18841275783",
		["UpdateLog"] = 18841988915,
		["Name"] = "Administer Canary",
		["IsActive"] = false,
	},

	["Beta"] = {
		["ImageID"] = "rbxassetid://18770010888",
		["UpdateLog"] = 18336751142,
		["Name"] = "Administer Beta",
		["IsActive"] = false,
	},

	["Live"] = {
		["ImageID"] = "rbxassetid://18224047110",
		["UpdateLog"] = 18336751142,
		["Name"] = "Administer",
		["IsActive"] = true,
	},
}

Variables.CurrentBranch = nil

Variables.Panel = {
	Path = script.Parent.Parent.Resources.AdministerMainPanel,
}

Variables.CachedLocales = {
	[133017837] = "es-es",
}

Variables.AppServers = Variables.DataStores.AppDB:GetAsync("AppServerList") or {}

Variables.Panel.Spawn = function(Rank, Player)
	local NewPanel = Variables.Panel.Path:Clone()

	NewPanel:SetAttribute("_AdminRank", Rank.RankName)
	NewPanel:SetAttribute(
		"_HomeWidgets",
		Variables.Services.HttpService:JSONEncode(
			Variables.DataStores.HomeDS:GetAsync(Player.UserId) or Variables.BaseHomeInfo
		)
	)
	NewPanel:SetAttribute(
		"_InstalledApps",
		Variables.Services.HttpService:JSONEncode(require(script.Parent.Parent.Modules.AppAPI).AllApps)
	)
	NewPanel:SetAttribute("_CurrentBranch", Variables.Services.HttpService:JSONEncode(Variables.CurrentBranch))

	return NewPanel
end

Variables.Init = function()
	local RF = Instance.new("Folder", Variables.RemotesPath)
	RF.Name = "Administer"
	Variables.RemotesPath = RF

	for Branch, Object in Variables.Branches do
		Object["BranchName"] = Branch

		if Object["IsActive"] then Variables.CurrentBranch = Object end
	end

	Variables.InitTimestamp = {
		Time = os.time(),
		Tick = tick(),
	}
end

return Variables
