--// Administer (2.0.0)

--// pyxfluff (2024-2025)

local Variables = {}

Variables.AdministerRoot = script.Parent.Parent.Parent
Variables.Remotes = game.ReplicatedStorage:WaitForChild("Administer", 10)

Variables.MainFrame = Variables.AdministerRoot:WaitForChild("Main", 10)
Variables.Mobile = false
Variables.InitErrored = false
Variables.IsOpen = true
Variables.IsPanelAnimating = false
Variables.EnableEditableImages = true
Variables.ActivePage = Variables.MainFrame.Home
Variables.DoHeaderEffects = true

Variables.CombinedButtonConfig = {}

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
}

Variables.Marketplace = {
	ActivePage = "Featured",
	ActivePageType = "FEATURED"
}

Variables.Icons = { ["_"] = false }

Variables.LocaleModule = { ["_"] = "_init" }

function Variables.init() end

return Variables
