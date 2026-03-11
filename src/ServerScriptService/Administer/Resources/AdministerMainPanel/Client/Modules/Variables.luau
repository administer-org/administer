--// Administer
--// CodingAgent (2024-2026)

local Variables = {}

local Configuration = script.Parent.Parent.ClientConfig

local function getObjectFromPath(pathString)
	if not pathString or type(pathString) ~= "string" then
		return nil
	end

	local parts = string.split(pathString, ".")
	local current

	if parts[1] == "game" then
		current = game
		table.remove(parts, 1)
	elseif parts[1] == "script" then
		current = script
		table.remove(parts, 1)
	else
		return nil
	end

	for _, name in ipairs(parts) do
		if current:IsA("DataModel") or current:IsA("Instance") then
			if name == "Parent" then
				current = current.Parent
			else
				current = current:FindFirstChild(name)
			end
			if not current then
				warn(`Path broken at: {name}`)
				return nil
			end
		else
			return nil
		end
	end

	return current
end

Variables.AdministerRoot = getObjectFromPath(Configuration:GetAttribute("AdministerRoot"))
	or script.Parent.Parent.Parent
Variables.Remotes = (game:GetService("ReplicatedStorage")):WaitForChild("Administer")
	or (getObjectFromPath(Configuration:GetAttribute("RemotesPath")))

Variables.MainFrame = Variables.AdministerRoot:WaitForChild("Main", 10)
Variables.Mobile = Configuration:GetAttribute("ForceMobile")
Variables.InitErrored = false
Variables.IsOpen = false
Variables.IsPanelAnimating = false
Variables.EnableEditableImages = false
Variables.ActivePage = Variables.MainFrame.Home
Variables.DoHeaderEffects = Configuration:GetAttribute("DoHeaderEffects")
Variables.HeartbeatDuration = Configuration:GetAttribute("HeartbeatDuration")
Variables.PingTicksLog = Configuration:GetAttribute("PingTicksLog")
Variables.AnimationSpeed = Configuration:GetAttribute("AnimationSpeed")

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
