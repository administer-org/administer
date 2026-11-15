--// pyxfluff 2024 - 2025

local Types = require(game.ServerScriptService.Administer.Loader.Core.Types)

return function(InvokeAPI: Types.InvocationAPI, a)
	local RichConfig = InvokeAPI.RichConfig()

	RichConfig.AppMeta.Name = "Announcements"
	RichConfig.AppMeta.ID = "org.admsoftware.Announcements"
	RichConfig.AppMeta.Description = "Announce things globally!"
	RichConfig.AppMeta.Icon = require(game.ServerScriptService.Administer.Loader.Core.Icons).megaphone
	RichConfig.AppMeta.Copyright = "2024 Dull3rkiller"
	RichConfig.AppMeta.Version = "1.0.0"

	RichConfig.Dependencies.AppPlatform = "min:1.0.0;max:2.0.0"
	RichConfig.Dependencies.Administer = "min:1.0.0;max:2.0.0"
	RichConfig.Dependencies.SettingsAPI = "1.0"
	RichConfig.Dependencies.AdministerModules = {
		{
			Type = "SERVER",
			Name = "Utilities",
		},
	} :: any

	RichConfig.ClientFrame = script.Announcements.UI.Announcements
	RichConfig.Bootstrap = function(_, _, RuntimeAPI)
		RuntimeAPI.Modules.Utilities.Logging.Print("Announcements running!")

		local AccouncementsGui = script.Announcements.UI:WaitForChild("AnnouncementsGui")
		AccouncementsGui.Parent = game:GetService("StarterGui")
	end

	return InvokeAPI.Construct(RichConfig, a)
end
