--!strict

--// Administer
--// pyxfluff 2024 - 2025

local Types = require(script.Parent.Types)
local Locales: { Default: string, Value: string, Items: { string } } = {
	--// Change the default locale here
	--// Make sure it is supported by Administer! See ./Locales for the list.
	Default = "en",
	Value = "en",
	Items = {}
}; for _, Locale in script.Parent.Locales:GetChildren() do table.insert(Locales.Items, Locale.Name) end

type SettingsType = Types.Configuration

local Settings: SettingsType = {
	Name = "Administer",

	VersData = {
		Service = { 
			Name = "Administer",
			Icon = `rbxassetid://{require(script.Parent.Icons).logos["administer-blue"]}`
		},

		Major = 2,
		Minor = 0,
		Tweak = 0,

		Extra = "RC2 (trg PRLS.pbta) 9989f20",
		String = "2.0.0-rc2",
		GitRevision = "9989f20",

		NoExtraData = "2.0.0",
		APIRevision = "2.0.0",

		ID = "org.admsoftware.Core"
	},

	Admins = {
		--// Hardcoded admins go here.
		--// If you have no idea what a dictionary is then please just
		--// use GUI-based rank configuration, you are going to make a syntax error.
		--// If you see red lines anywhere here press Ctrl Z until they go away

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
			UserID = 938429178,
			Name   = "AjaxTiba",
			Job    = "core features"
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
			UserID = 556692115,
			Name   = "FabulousTrophies",
			Job    = "product testing"
		},
		{
			UserID = 462102164,
			Name   = "MCJ_RB",
			Job    = "product testing"
		},
		{
			UserID = 1,
			Name   = "FlatIcon",
			Job    = "icons"
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

			["LiveUpdate"] = {
				["DisplayName"] = "Live rank changes",
				["Description"] = "If enabled, when a rank is made or edited, Administer will automatically check for new admins.",
				["SettingType"] = "Boolean",
				["SettingDisplayType"] = "Toggle",
				["RequiresRestart"] = false,

				["Value"] = {
					["Value"] = true,
					["Default"] = true
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
			},

			["LoadDelay"] = {
				["Description"] = "Enables a 3s delay before loading any admins. Use this to solve apps not initializing.",
				["SettingType"] = "Enum",
				["SettingDisplayType"] = "Dropdown",
				["RequiresRestart"] = false,

				["Value"] = {
					["Value"] = "None",
					["Default"] = "None",
					Items = {
						"None",
						"InStudio",
						"All"
					}
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
				["DisplayName"] = "Interface Language (BETA)",
				["Description"] = "This option will override your default Roblox preference. This is a work in progress and will NOT be supported fully by Administer or apps yet.",
				["SettingType"] = "Enum",
				["SettingDisplayType"] = "Dropdown",

				["Value"] = Locales :: Types.SettingValue
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
				["SettingDisplayType"] = "Toggle",

				["Value"] = {
					["Value"] = true,
					["Default"] = true
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
					["Value"] = Enum.KeyCode.F2.Name,
					["Default"] = Enum.KeyCode.F2.Name
				}
			},

			["PanelFullscreenKeybind"] = {
				["DisplayName"] = "Panel Fullscreen Keybind",
				["Description"] = "The key used to expand the panel to be fullscreen on keyboard-enabled devices.",
				["SettingType"] = "KeyCode",
				["SettingDisplayType"] = "KeybindSelector",
				["RequiresRestart"] = false,

				["Value"] = {
					["Value"] = "LeftShift,F2",
					["Default"] = "LeftShift,F2"
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

			["DisableAOS"] = {
				["Description"] = "Prohibits AOS from being reached for the marketplace.",
				["SettingType"] = "Boolean",
				["SettingDisplayType"] = "Toggle",
				["RequiresRestart"] = false,

				["Value"] = {
					["Value"] = false,
					["Default"] = false
				}
			},

			["LoadApps"] = {
				["Description"] = "Enables the ability for Administer to load apps.",
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

			["AssistiveClose"] = {
				["Description"] = "Enables a close button in the top left for desktop. Always enabled on mobile.",
				["SettingType"] = "Boolean",
				["SettingDisplayType"] = "Toggle",
				["RequiresRestart"] = true,

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
					Items = {
						"disabled",
						"small",
						"regular",
						"medium",
						"large"
					},

					["Value"] = "regular",
					["Default"] = "regular"
				}
			}
		},

		["General"] = {
			["_CategoryOpts"] = {
				["DisplayName"] = "General",
				["Color"] = "#888",
				["Description"] = "General Administer settings."
			},

			["Verbosity"] = {
				["Description"] = "The amount of debugging prints Administer makes. To disable remote logging (<-- Remote [1], --> Done (20ms)), set to `warning`.",
				["SettingType"] = "Enum",
				["SettingDisplayType"] = "Dropdown",
				["RequiresRestart"] = false,

				["Value"] = {
					Items = {
						"debug",
						"log",
						"warning",
						"error"
					},

					["Value"] = "log",
					["Default"] = "log"
				}
			},

			["KeybindRegisterTime"] = {
				["Description"] = "Changes how soon Administer will listen for the keybind to open the panel. Optimistic = Early but quick, some things may not be finished, Safe = registers when ready",
				["SettingType"] = "Enum",
				["SettingDisplayType"] = "Dropdown",
				["RequiresRestart"] = false,

				["Value"] = {
					Items = {
						"optimistic",
						"safe",
					},

					["Value"] = "optimistic",
					["Default"] = "optimistic"
				}
			},

			["ShortNumberDecimals"] = {
				["Description"] = 'How many decimals to display after a short number (54.123k)',
				["SettingType"] = "Integer",
				["SettingDisplayType"] = "InputBox",
				["RequiresRestart"] = false,

				["Value"] = {
					["Value"] = 2,
					["Default"] = 2
				}
			}
		}
	},

	BetaOptIns = {},

	Webhooks = {}
}

return Settings
