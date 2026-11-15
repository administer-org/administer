--// pyxfluff 2025

local Types = require(game.ServerScriptService.Administer.Loader.Core.Types)

return function(InvokeAPI: Types.InvocationAPI, a)
	local RichConfig = InvokeAPI.RichConfig()

	RichConfig.AppMeta.Name = "Catwatcher API"
	RichConfig.AppMeta.Description = "Implement the Catwatcher exploiter database into your game to detect cheaters."
	RichConfig.AppMeta.Icon = require(game.ServerScriptService.Administer.Loader.Core.Icons)["triangle-warning"]
	RichConfig.AppMeta.Copyright = "2025 Administer Software"
	RichConfig.AppMeta.Version = "1.0.0"

	RichConfig.Dependencies.AppPlatform = "min:2.0.0;max:3.0.0"
	RichConfig.Dependencies.Administer = "min:2.1.1;max:3.0.0"
	RichConfig.Dependencies.SettingsAPI = "2.0"
	RichConfig.Dependencies.AdministerModules = {
		{
			Type = "SERVER",
			Name = "Utilities",
		},
		{
			Type = "SERVER",
			Name = "HTTPRunner",
		},
		{
			Type = "SERVER",
			Name = "SettingsAPI",
		},
	}

	RichConfig.ClientFrame = script.Content.CatwatcherUI
	RichConfig.Bootstrap = require(script.ServerModules.Main)

	return InvokeAPI.Construct(RichConfig, a)
end
