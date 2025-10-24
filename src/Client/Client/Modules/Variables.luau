--// Administer

--// pyxfluff (2024-2025)

local Variables = {}

Variables.AdministerRoot = script.Parent.Parent.Parent
Variables.Remotes = game.ReplicatedStorage:WaitForChild("Administer", 10)

Variables.MainFrame = Variables.AdministerRoot:WaitForChild("Main", 10) --// frontend location
Variables.Mobile = false 												--// enable to force mobile mode
Variables.InitErrored = false
Variables.IsOpen = false
Variables.IsPanelAnimating = false
Variables.EnableEditableImages = false --// roblox sucks
Variables.ActivePage = Variables.MainFrame.Home
Variables.DoHeaderEffects = true
Variables.HeartbeatDuration = 10
Variables.PingTicksLog = 60
Variables.AnimationSpeed = 1

Variables.AppliedThemeSource = {} 
Variables.ThemeData = {}

Variables.CombinedButtonConfig = {}
Variables.Ping = {}

Variables.Panel = nil
Variables.OpenSound = script.Parent --// TODO

Variables.Services = {
	Players             = game:GetService("Players"),
	GUIService          = game:GetService("GuiService"),
	HttpService         = game:GetService("HttpService"),
	TweenService        = game:GetService("TweenService"),
	AssetService        = game:GetService("AssetService"),
	UserInputService    = game:GetService("UserInputService"),
	ReplicatedStorage   = game:GetService("ReplicatedStorage"),
	MarketplaceService  = game:GetService("MarketplaceService"),
	LocalizationService = game:GetService("LocalizationService")
}

Variables.Marketplace = {
	ActivePage = "AAFeatured",
	ActivePageType = "FEATURED"
}

Variables.LocaleModule = { ["_"] = "_init" }

function Variables.init() end

return Variables
