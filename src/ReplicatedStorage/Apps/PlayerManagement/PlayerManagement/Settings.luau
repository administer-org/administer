return {
	_SettingsMeta = {
		Name = "Player Management",
	},

	Logging = {
		_CategoryOpts = {
			DisplayName = "Logging",
			Color = "#60B9DD",
			Description = "Change where Player Management logs to and what is logged.",
		},

		DiscordURL = {
			DisplayName = "Discord Webhook URL",
			Description = "The Discord webhook to send a request to on a successful action. You should use a proxy!",
			SettingType = "String",
			SettingDisplayType = "InputBox",
			RequiresRestart = true,
			SaveOnServer = true,
			SaveOnClient = false,

			Value = {
				Value = "",
				Default = "",
			},
		},
	},

	General = {
		_CategoryOpts = {
			DisplayName = "General",
			Color = "#5176d0",
			Description = "Change general settings for Player Management.",
		},

		QuickSelect = {
			Description = "The keybind to enter QuickSelect mode.",
			SettingType = "KeyCode",
			SettingDisplayType = "KeybindSelector",
			RequiresRestart = true,
			SaveOnServer = false,
			SaveOnClient = true,

			Value = {
				Value = "LeftShift,Z",
				Default = "LeftShift,Z",
			},
		},
	},
}
