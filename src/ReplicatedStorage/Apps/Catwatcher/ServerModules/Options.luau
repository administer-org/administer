--// pyxfluff 2025
return {
	_SettingsMeta = {
		Name = "CatwatcherAPI",
	},

	General = {
		_CategoryOpts = {
			DisplayName = "General",
			Color = "#2b32e2",
			Description = "General settings.",
			Icon = "gear",
		},

		JoinCheck = {
			DisplayName = "Check for cheaters on join",
			Description = "If enabled, new players who join the game will be checked at runtime. Your current limit is 100 players every 5 minutes.",
			SettingType = "Boolean",
			SettingDisplayType = "Toggle",
			RequiresRestart = false,

			SaveOnServer = true,
			SaveOnClient = false,

			Value = {
				Value = false,
				Default = false,
			},
		},

		BaseURL = {
			Description = "Change the API URL if you have a custom one.",
			SettingType = "String",
			SettingDisplayType = "InputBox",
			RequiresRestart = false,

			SaveOnServer = true,
			SaveOnClient = false,

			Value = {
				Value = "https://aos-us-2.admsoftware.org",
				Default = "https://aos-us-2.admsoftware.org",
			},
		},

		APIKey = {
			Description = "If you are using an official server, an API key might be required. This is not required for our provided server.",
			SettingType = "String",
			SettingDisplayType = "InputBox",
			RequiresRestart = false,

			SaveOnServer = true,
			SaveOnClient = false,

			Value = {
				Value = "",
				Default = "",
			},
		},

		JoinAction = {
			DisplayName = "Join check action",
			Description = "Pick what action will be taken when a cheater enters the game",
			SettingType = "Enum",
			SettingDisplayType = "Dropdown",
			RequiresRestart = false,

			SaveOnServer = true,
			SaveOnClient = false,

			Value = {
				Value = "None",
				Default = "None",
				Items = {
					"Ban",
					"Kick",
					"CustomEvent",
					"Ignore",
				},
			},
		},
	},
}
