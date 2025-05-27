--// Administer
--// pyxfluff 2024 - 2025

local L = script.Parent.Locales:GetChildren()
local Locales = {}

for _, Locale in L do
	table.insert(Locales, L.Name)
end

Locales["Default"] = "en" --// Default locale here
Locales["Value"] = "en"

return {
	Name = "Administer",

	VersData = {
		Service = { 
			Name = "Administer",
			Icon = `rbxassetid://{require(script.Parent.Icons).logos["administer-blue"]}`
		},
		
		Major = 2,
		Minor = 0,
		Tweak = 0,
		
		Extra = "RC1 (target:PRLSE\\pubbeta) 54340f3",
		String = "2.0.0-rc1",
		
		NoExtraData = "2.0.0",
		APIRevision = "2.0.0",
		
		ID = "org.admsoftware.Core"
	},

	Admins = {
		--// Hardcoded admins go here.
		--// If you have no idea what a dictionary is then please just
		--// use GUI-based rank configuration, you are going to make a syntax error.
		
		Groups = {
			--// Change the ID in the table key here. Copy this entry to make more.
			[0] = { --// Group ID
				RankNumber = 255, --// Group rank ID
				AdminRankID = 1   --// Administer rank ID, leave 1 for administrator rights
			},
		},
		
		Players = {
			[0] = { --// User ID
				AdminRankID = 1
			},
		}
	},
	
	Contributors = {
		{
			UserID = 133017837,
			Name   = "pyxfluff",
			Job    = "project lead, AOS, frontend/backend"
		},
		{
			UserID = 3610087630,
			Name   = "dogo8me2",
			Job    = "core assistance, apps"
		},
		{
			UserID = 630064214,
			Name   = "DullerKill7r",
			Job    = "app development"
		},
		{
			UserID = 3952806136,
			Name   = "RoltairTheProtogen",
			Job    = "community management, product testing"
		},
		{
			UserID = 1,
			Name   = "iiPythonx",
			Job    = "hosting, database administration"
		},
		{
			UserID = 3239844753,
			Name   = "CDot_NightHawk",
			Job    = "hosting infrastructure"
		},
		{
			UserID = 1,
			Name   = "FlatIcon",
			Job    = "default icon pack"
		},
		{
			UserID = 365438147,
			Name   = "pixe_ated",
			Job    = "QuickBlur"
		},
		{
			UserID = 345072461,
			Name   = "WinnersTakesAll",
			Job    = "Shime"
		},
		{
			UserID = 1516442,
			Name   = "Fractality",
			Job    = "neon"
		}
	},

	--// Don't change these unless you have to, they will probably be overwritten
	--// or ignored by the system. They are just default values.
	Settings = {
		["_SettingsMeta"] = {
			["Name"] = "Administer"
		},

		["Admins"] = {
			["_CategoryOpts"] = {
				["DisplayName"] = "Admins",
				["Color"] = "#fff",
				["Description"] = "Change how ranks and admins operate."
			},

			["RefreshTime"] = {
				["DisplayName"] = "Admin check time",
				["Description"] = "How often to check if admins are still admins, and take away the panel if they are not.",
				["SettingType"] = "NumberRange",
				["SettingDisplayType"] = "Slider",
				["RequiresRestart"] = false,

				["Value"] = {
					["Value"] = 120,
					["Default"] = 120,
					["Min"] = 15,
					["Max"] = 1000,
					["Step"] = 1
				}
			},

			["AllowProtectedEdits"] = {
				["DisplayName"] = "Edit Protected Ranks",
				["Description"] = "Allows editing protected ranks (superadmin). Also allows the creation of them. Not recommended as you could potentially break your installation.",
				["SettingType"] = "Boolean",
				["SettingDisplayType"] = "Toggle",
				["RequiresRestart"] = false,

				["Value"] = {
					["Value"] = false,
					["Default"] = false
				}
			}
		},

		["Interface"] = {
			["_CategoryOpts"] = {
				["DisplayName"] = "Interface",
				["Color"] = "#000",
				["Description"] = "Customize the user interface."
			},

			["Language"] = {
				["Description"] = "This option will override your default Roblox preference.",
				["SettingType"] = "Enum",
				["InputDisplayType"] = "Dropdown",

				["Value"] = Locales
			},

			["AnimationSpeed"] = {
				["DisplayName"] = "Animation Speed",
				["Description"] = "Controls the speed of client-side animations. Higher is slower. Set to 0 to disable animations.",
				["SettingType"] = "float",
				["SettingDisplayType"] = "Slider",
				["RequiresRestart"] = false,

				["Value"] = {
					["Value"] = 1,
					["Default"] = 1,
					["Min"] = 0,
					["Max"] = 5,
					["Step"] = 0.1
				}
			},
			
			["AllowThemeScriptHooks"] = {
				["DisplayName"] = "Allow themes to run Lua",
				["Description"] = "If enabled, all themes will be allowed to run external Luau code. This is useful for more advanced themes or other modifications.",
				["SettingType"] = "boolean",
				
				["Value"] = {
					["Value"] = true,
					["Default"] = true
				}
			},

			["DisableUnofficialAppWarning"] = {
				["DisplayName"] = "Disable unofficial app warning",
				["Description"] = "Hides the warning which says if an app/theme is external. Useful for new people, otherwise just UI clutter.",
				["SettingType"] = "Boolean",
				["SettingDisplayType"] = "Toggle",
				["RequiresRestart"] = false,

				["Value"] = {
					["Value"] = false,
					["Default"] = false
				}
			},

			["EnableEditableImages"] = {
				["DisplayName"] = "Enable EditableImages",
				["Description"] = "Enables EditableImage features such as app card backgrounds, reflections, and other blurring effects. Requires the game permission and ID verification due to Roblox limitations.",
				["SettingType"] = "Boolean",
				["SettingDisplayType"] = "Toggle",
				["RequiresRestart"] = false,

				["Value"] = {
					["Value"] = true,
					["Default"] = true
				}
			},

			["HomepageGreeting"] = {
				["DisplayName"] = "Homepage Greeting",
				["Description"] = 'This is the text that displays after the "Hello, username!" text on the homepage.',
				["SettingType"] = "String",
				["SettingDisplayType"] = "InputBox",
				["RequiresRestart"] = false,

				["Value"] = {
					["Value"] = "Welcome to Administer!",
					["Default"] = "Welcome to Administer!"
				}
			},

			["PanelKeybind"] = {
				["DisplayName"] = "Panel Keybind",
				["Description"] = "The key used to open the panel on keyboard-enabled devices.",
				["SettingType"] = "KeyCode",
				["SettingDisplayType"] = "KeybindSelector",
				["RequiresRestart"] = false,

				["Value"] = {
					["Value"] = "F2",
					["Default"] = "F2"
				}
			},

			["EnableClickEffects"] = {
				["DisplayName"] = "Enable button effects",
				["Description"] = "Increases memory usage slightly, also makes noise.",
				["SettingType"] = "Boolean",
				["SettingDisplayType"] = "Toggle",
				["RequiresRestart"] = true,

				["Value"] = {
					["Value"] = true,
					["Default"] = true
				}
			}
		},

		["Apps"] = {
			["_CategoryOpts"] = {
				["DisplayName"] = "Apps",
				["Color"] = "#fff",
				["Description"] = "Manage app settings."
			},

			["LoadDelay"] = {
				["Description"] = "Enables a 3s delay before loading any admins. Use this to solve apps not initializing.",
				["SettingType"] = "Enum",
				["SettingDisplayType"] = "Dropdown",
				["RequiresRestart"] = false,

				["Value"] = {
					"None",
					"InStudio",
					"All",
					["Value"] = "None",
					["Default"] = "None",
				}
			},

			["FetchAppServers"] = {
				["Description"] = "Disallows Administer from contacting any external app servers.",
				["SettingType"] = "Boolean",
				["SettingDisplayType"] = "Toggle",
				["RequiresRestart"] = false,

				["Value"] = {
					["Value"] = false,
					["Default"] = false
				}
			},

			["LoadApps"] = {
				["Description"] = "Controls the ability for the server to load apps.",
				["SettingType"] = "Boolean",
				["SettingDisplayType"] = "Toggle",
				["RequiresRestart"] = true,

				["Value"] = {
					["Value"] = true,
					["Default"] = true
				}
			}
		},

		["Accessibility"] = {
			["_CategoryOpts"] = {
				["DisplayName"] = "Accessibility",
				["Color"] = "#888",
				["Description"] = "Adjust accessibility settings."
			},

			["ChatCommand"] = {
				["Description"] = "Enables an /adm command to open Administer.",
				["SettingType"] = "Boolean",
				["SettingDisplayType"] = "Toggle",
				["RequiresRestart"] = false,

				["Value"] = {
					["Value"] = true,
					["Default"] = true
				}
			},

			["MobileOpenGesture"] = {
				["Description"] = "Controls how big the mobile open gesture is from the right side.",
				["SettingType"] = "Enum",
				["SettingDisplayType"] = "Dropdown",
				["RequiresRestart"] = false,

				["Value"] = {
					"disabled",
					"small",
					"regular",
					"medium",
					"large",
					"extralarge",
					
					["Value"] = "regular",
					["Default"] = "regular"
				}
			}
		}
	},

	BetaOptIns = {},

	Webhooks = {}
}
