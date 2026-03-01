--// pyxfluff 2025

local Types = require(game.ServerScriptService.Administer.Loader.Core.Types)

local Http = game:GetService("HttpService")

return function(InvokeAPI: Types.InvocationAPI, a)
	local RichConfig = InvokeAPI.RichConfig()

	RichConfig.AppMeta.Name = "Theme tester"
	RichConfig.AppMeta.Description = "Adds sidebar buttons for managing themes"
	RichConfig.AppMeta.Icon = require(game.ServerScriptService.Administer.Loader.Core.Icons)["notepad-edit"]
	RichConfig.AppMeta.Copyright = "2025 Administer Software"
	RichConfig.AppMeta.Version = "1.0.0"

	RichConfig.Dependencies.AppPlatform = "min:2.0.0;max:3.0.0"
	RichConfig.Dependencies.Administer = "min:2.0.0;max:3.0.0"
	RichConfig.Dependencies.AdministerModules = {} :: any

	RichConfig.ClientFrame = script.Content.PublicBetaAssistant
	RichConfig.Bootstrap = function(_, _, RuntimeAPI)
		--RuntimeAPI.Modules.Utilities.Logging.Print("theme assistant is ready")
	end

	return InvokeAPI.Construct(RichConfig, a)
end
