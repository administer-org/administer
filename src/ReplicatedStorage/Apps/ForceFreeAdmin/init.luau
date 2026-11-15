--// pyxfluff 2025

local Types = require(game.ServerScriptService.Administer.Loader.Core.Types)

return function(InvokeAPI: Types.InvocationAPI, _)
	local RichConfig = InvokeAPI.RichConfig()

	RichConfig.AppMeta.Name = "ForceFreeAdmin"
	RichConfig.AppMeta.Description = "A utility which forces Vars.FreeAdmin to be true."
	RichConfig.AppMeta.Icon = require(game.ServerScriptService.Administer.Loader.Core.Icons)["user-shield"]
	RichConfig.AppMeta.Copyright = "2025 pyxfluff"
	RichConfig.AppMeta.Version = "1.0.0"

	RichConfig.Dependencies.AppPlatform = "min:1.0.0;max:99.0.0"
	RichConfig.Dependencies.Administer = "min:1.0.0;max:99.0.0"
	RichConfig.Dependencies.SettingsAPI = "min:1.0.0;max:99.0.0"
	RichConfig.Dependencies.AdministerModules = {
		{
			Type = "SERVER",
			Name = "SettingsAPI",
		},
	} --// vars will be requested at runtime

	RichConfig.Bootstrap = function(_, _, Config)
		local Settings = Config.Modules.SettingsAPI.new({
			["_SettingsMeta"] = {
				["Name"] = "ForceFreeAdmin",
			},

			["General"] = {
				["_CategoryOpts"] = {
					["DisplayName"] = "General",
					["Color"] = "#4aeb6a",
					["Description"] = "General settings.",
				},

				["Enabled"] = {
					["Description"] = "Enable ForceFreeAdmin.",
					["SettingType"] = "Boolean",
					["SettingDisplayType"] = "Toggle",
					["RequiresRestart"] = true,

					["Value"] = {
						["Value"] = false,
						["Default"] = false,
					},
				},
			},
		})

		Settings:Load()

		Settings.with({ "Enabled" }, function(IsEnabled)
			local Vars = require(game.ServerScriptService.Administer.Loader.Core.Variables)

			print(IsEnabled)

			if IsEnabled.Value.Value then
				Vars.EnableFreeAdmin = true
			end
		end)()
	end

	return InvokeAPI.Construct(RichConfig, _)
end
