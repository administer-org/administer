--// Administer (2.0.0)

--// pyxfluff (2024-2025)

local Variables = {}

Variables.AdministerRoot = script.Parent.Parent.Parent
Variables.Remotes = game.ReplicatedStorage:WaitForChild("Administer", 10)

Variables.MainFrame = Variables.AdministerRoot:WaitForChild("Main", 10)
Variables.Mobile = false
Variables.InitErrored = false
Variables.IsOpen = false
Variables.IsPanelAnimating = false
Variables.EnableEditableImages = false --// roblox sucks
Variables.ActivePage = Variables.MainFrame.Home
Variables.DoHeaderEffects = true
Variables.HeartbeatDuration = 1
Variables.PingTicksLog = 60

Variables.CombinedButtonConfig = {}
Variables.Ping = {}

Variables.Panel = nil
Variables.OpenSound = script.Parent --// TODO

Variables.Services = {
	AssetService        = game:GetService("AssetService"),
	MarketplaceService  = game:GetService("MarketplaceService"),
	Players             = game:GetService("Players"),
	ReplicatedStorage   = game:GetService("ReplicatedStorage"),
	TweenService        = game:GetService("TweenService"),
	UserInputService    = game:GetService("UserInputService"),
	LocalizationService = game:GetService("LocalizationService"),
	HttpService         = game:GetService("HttpService"),
	GUIService          = game:GetService("GuiService")
}

Variables.Marketplace = {
	ActivePage = "AAFeatured",
	ActivePageType = "FEATURED"
}

Variables.LocaleModule = { ["_"] = "_init" }

function Variables.init() end

return Variables
