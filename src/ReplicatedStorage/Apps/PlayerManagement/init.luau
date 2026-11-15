--// pyxfluff 2024 - 2025

local Types = require(game.ServerScriptService.Administer.Loader.Core.Types)

return function(InvokeAPI: Types.InvocationAPI, a)
	local RichConfig = InvokeAPI.RichConfig()

	RichConfig.AppMeta.Name = "Player Management"
	RichConfig.AppMeta.Description = "Manage your game's players from anywhere"
	RichConfig.AppMeta.ID = "org.admsoftware.player-management.Main"
	RichConfig.AppMeta.Icon = require(game.ServerScriptService.Administer.Loader.Core.Icons).users
	RichConfig.AppMeta.Copyright = "2024 - 2025 pyxfluff"
	RichConfig.AppMeta.Version = "1.0.0"

	RichConfig.Dependencies.AppPlatform = "min:1.0.0;max:2.0.0"
	RichConfig.Dependencies.Administer = "min:1.0.0;max:2.0.0"
	RichConfig.Dependencies.SettingsAPI = "1.0"
	RichConfig.Dependencies.AdministerModules = {
		{
			Type = "SERVER",
			Name = "AdminRunner",
		},
		{
			Type = "SERVER",
			Name = "SettingsAPI",
		},
		{
			Type = "SERVER",
			Name = "Utilities",
		},
	} :: any

	local PlayerManagement = script.PlayerManagement
	local Config = PlayerManagement.Config
	local Widgets = PlayerManagement.UI[".widgets"]

	RichConfig.ClientFrame = PlayerManagement.UI.PlayerManagement
	RichConfig.Commands = require(Config[".commandConfig"])
	RichConfig.Widgets = require(Widgets[".widgetconfig"])
	RichConfig.Bootstrap = require(PlayerManagement.Main)

	return InvokeAPI.Construct(RichConfig, a)
end
