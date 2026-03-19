--// Administer
--// CodingAgent (2024-2026)

local Variables = {}

Variables.AdministerRoot = script.Parent.Parent.Parent
Variables.Remotes = game.ReplicatedStorage:WaitForChild("Administer", 15)

Variables.MainFrame = Variables.AdministerRoot:WaitForChild("Main", 10)
Variables.Mobile = false
Variables.InitErrored = false
Variables.IsOpen = false
Variables.IsPanelAnimating = false
Variables.EnableEditableImages = false
Variables.ActivePage = Variables.MainFrame.Home
Variables.DoHeaderEffects = true
Variables.HeartbeatDuration = 10
Variables.PingTicksLog = 60
Variables.AnimationSpeed = 1

Variables.CombinedButtonConfig = {}
Variables.Ping = {}

Variables.Panel = nil
Variables.OpenSound = script.Parent

Variables.Services = {
	Players = game:GetService("Players"),
	GUIService = game:GetService("GuiService"),
	HttpService = game:GetService("HttpService"),
	TweenService = game:GetService("TweenService"),
	AssetService = game:GetService("AssetService"),
	UserInputService = game:GetService("UserInputService"),
	ReplicatedStorage = game:GetService("ReplicatedStorage"),
	MarketplaceService = game:GetService("MarketplaceService"),
	LocalizationService = game:GetService("LocalizationService"),
}

Variables.Marketplace = {
	ActivePage = "AAFeatured",
	ActivePageType = "FEATURED",
}

Variables.LocaleModule = { ["_"] = "_init" }

function Variables.init() end

return Variables
