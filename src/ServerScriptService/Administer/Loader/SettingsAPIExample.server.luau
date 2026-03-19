local SettingsAPI = require(game.ServerScriptService.Administer.Loader.Modules.SettingsAPI)

local Settings = SettingsAPI.new({
	["_SettingsMeta"] = {
		["Name"] = "Administertesttesttest",
	},

	["General"] = {
		["_CategoryOpts"] = {
			["DisplayName"] = "General",
			["Color"] = "#fff",
			["Description"] = "Configure general settings.",
		},

		["AnimationSpeed"] = {
			["DisplayName"] = "Animation Speed",
			["Description"] = "Controls the speed of animations.",

			["SettingType"] = "float",
			["SettingDisplayType"] = "InputBox",

			["Value"] = {
				["Value"] = 1,
				["Default"] = 1,
			},
		},
		["Language"] = {
			["Description"] = "Administer's UI language.",
			["SettingType"] = "Enum",

			["InputDisplayType"] = "Dropdown",
			["Value"] = {
				"English",
				"Spanish",
				"French",
				["Value"] = "English",
				["Default"] = "English",
			},
		},
	},

	["Interface"] = {
		["_CategoryOpts"] = {
			["DisplayName"] = "Interface options",
			["Color"] = "#000",
			["Description"] = "Change the interface.",
		},

		["InterfaceScale"] = {
			["Description"] = "The scale of the interface.",
			["SettingType"] = "float",
			["InputDisplayType"] = "Slider",

			["Value"] = {
				["Value"] = 1,
				["Default"] = 1,
				["Min"] = 0.25,
				["Max"] = 5,
				["Step"] = 1,
			},
		},
	},
})

Settings.Changed({ "AnimationSpeed", "InterfaceScale" }, function(Setting)
	print(`{Setting.Name} has changed and is now {Setting.Value}!`)
end)

local LotsOfValues = Settings.Get({ "Language", "InterfaceScale" })
print(LotsOfValues)

print(Settings.Get("AnimationSpeed"))

local Category = Settings.GetCategory("Interface")

print(Category)