--!strict

--// Administer
--// pyxfluff 2024 - 2025

export type IconPack = {
	Meta: {
		Name: string,
		Author: string,
		Type: "full-set" | "partial" | "tweaks",
		AllowThemeDependencies: boolean
	},

	Logos: { [string]: string },
	
	[string]: string
}

type AppID = string

export type Response = { boolean | string }

export type CurrentRanks = {
	Count: number,
	Names: { string },
	GroupAdminIDs: { number },
	AdminIDs: { number }
}

export type AdminRank = {
	Name: string,
	Protected: boolean,
	Members: {
		{
			ID: number,
			MemberType: "User" | "Group",
			GroupRank: number?
		}
	},

	Apps: {
		SuperAdmin: boolean?,

		[AppID]: {
			Added: number,
			PageIDs: { string },
			CommandIDs: { string }
		},
	},

	CreationReason: string,
	ActingUser: number,

	RankID: number?,
	IsEdit: boolean?
}

export type AdminCheck = {
	IsAdmin: boolean,
	RankID: number,

	--// nice to have stuff
	Reason: string?,
	RankName: string?
}

export type ActionObject = {
	Text: string,
	Icon: string | Icon,
	OnClick: () -> ()
}

export type AdmBranch = {
	ImageID: string,
	Name: string,
	IsActive: boolean
}

type Version = string
type Branch = "LIVE" | "BETA" | "CANARY" | "INTERNAL" | "GIT"
type AdministerDistributors = { "git" | "roblox" | "pesde" | "aos" }
type BranchList = { "LIVE" | "BETA" | "CANARY" | "INTERNAL" | "GIT" }

export type PythonVersionInfo = {
	provided_information: {
		branch: BranchList,
		version: string,
		outdated: boolean,

		can_update_to: {
			branch: Branch,
			name: string
		},

		featureset: {
			apps: {
				can_download: boolean,
				can_install_new: boolean,
				can_access_marketplace: boolean
			},

			administer: {
				can_auto_update: boolean,
				can_report_version: boolean
			},

			misc: {
				supports_ranks: { string }
			}
		}
	},

	versions: {
		[Version]: {
			latest: boolean,
			available_to: BranchList,
			distributed_via: AdministerDistributors,
			released: number,
			hash: string,

			logs: { string }
		}
	}
}

export type HomeWidgetInfo = {
	_version: string,
	Widget1: string,
	Widget2: string,
	TextWidgets: { string }
}

export type SettingResponse = boolean | string | number | EnumItem | { Value: EnumItem, String: string }

export type TableWildcard = { { any } | boolean | string }

export type Modules = "AdminRunner" | "Apps" | "Debugging" | "Frontend" | "HTTPRunner" | "Settings" | "Utilities"
export type ClientModules = "Admins" | "Apps" | "Frontend" | "Types" | "UISpawn" | "Utilities" | "Variables" | "Widgets"

export type Notification = {
	NotificationVisiblity: Player | "EVERYBODY",

	Body: string,
	Header: {
		Text: string,
		Icon: string
	},

	Duration: number?,

	Buttons: {
		{
			Text: string,
			Icon: string,
			OnClick: () -> ()
		}
	}?,

	ShelfVisiblity: "FOR_TARGET" | "ALL_ADMINS" | "DO_NOT_DISPLAY",
	NotificationPriority: "CRITICAL" | "NORMAL" | "LOW"
}

export type AppFunction = {
	FinishTime: string,
	RunContext: "AOSDownload" | "LocalAppsFolder",
	RanksWithAccess: number,

	Modules: { { {} | any }? }?
}

export type ExecutionAPI = {}
export type State = {}
export type RunContext = "CommandBar" | "TextChat" | "Administer" | "ThirdParty"
export type CommandOption = {
	Name: string,
	Description: string,

	Type: boolean | string | number,
	Required: boolean,
	DefaultValue: boolean | string | number
}

export type RichConfig = {
	AppMeta: {
		Name: string,
		Icon: string,
		Version: string,
		CardBgID: string?,
		Copyright: string?,
		DisplayName: string?,
		Description: string
	},

	Dependencies: {
		Administer: string,
		SettingsAPI: string?,
		AppPlatform: string,

		AdministerModules: {
			{
				Type: "SERVER" | "CLIENT",
				Name: Modules | ClientModules
			}?
		}
	},

	TextCommands: {
		{
			Name: string,
			Description: string,
			Icon: string,

			PermissionLevel: "0" | "1" | "2" | "3" | "4" | "5",
			Executed: () -> (Player, RunContext, { CommandOption })
		}
	}?,

	State: {},
	RunLocally: boolean?,

	ClientFrame: Frame | CanvasGroup,
	Bootstrap: (ExecutionAPI, State, AppFunction) -> () | nil
}

export type InvocationAPI = {
	RichConfig: () -> RichConfig,
	Construct: (RichConfig, {}) -> AppFunction
}

--// Settings
export type SettingValue = {
	Value: any?,
	Default: any?,
	Min: number?,
	Max: number?,
	Step: number?,
	EnforceEnumValue: boolean?,
	[number]: any
}

export type Setting = {
	DisplayName: string?,
	Description: string,

	SettingType: "Enum" | "Integer" | "Boolean" | "String" | string, --// born to Boolean forced to <string>
	SettingDisplayType: "InputBox" | "NumberRange" | "Dropdown" | "Toggle" | string,

	Value: SettingValue
}


export type SettingsGroup = {
	_SettingsMeta: {
		Name: string,
		Description: string?
	},

	[string]: {
		_CategoryOpts: {
			DisplayName: string,
			Color: string,
			Description: string
		},

		[string]: Setting
	}
}

export type MainSettings = {
	Changed: ({ Setting: string }) -> (() -> (Setting)),
	with: ({ Setting: string }) -> ((...any) -> (Settings: { Setting }, ...any) -> (...any)),
	Get: ({ Setting: string }) -> ({ Setting }),
	GetCategory: (Category: string) -> ({ Setting }),
	Set: (Setting: string) -> ()
}

export type SettingsAPI = {
	New: (SettingsGroup) -> (MainSettings),
	GetRaw: (SettingPath: string) -> (Setting),
	SetRaw: (SettingPath: string, NewValue: any) -> (any)
}

export type Configuration = {
	Name: string,
	
	VersData: {
		Service: {
			Name: string,
			Icon: string
		},
		
		Major: number,
		Minor: number,
		Tweak: number,
		
		Extra: string,
		String: string,
		GitRevision: string,
		NoExtraData: string,
		
		APIRevision: string,
		ID: string
	},
	
	Admins: {
		Groups: {
			[number]: {
				RankNumber: number,
				AdminRankID: number
			}
		},
		Players: {
			[number]: {
				AdminRankID: number
			}
		}
	},
	
	Contributors: {
		{
			UserID: number,
			Name: string,
			Job: string
		}
	},
	
	Settings: SettingsGroup
}

return {}
