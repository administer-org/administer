local SettingsAPI = {}
SettingsAPI.__index = SettingsAPI

local Types = require(script.Parent.Parent.Core.Types)
local Signal = require(script.Signal)

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local SettingsDataStore = DataStoreService:GetDataStore("Administer_Setting_Preferences")

type Setting = Types.Setting
type SettingsGroup = Types.SettingsGroup
type SettingsApi = Types.SettingsAPI
type MainSettings = Types.MainSettings

local function saveDataStore(key: string, data: {}): boolean
	local success, err = pcall(function()
		SettingsDataStore:SetAsync(key, HttpService:JSONEncode(data))
	end)
	return success
end

local function loadDataStore(key: string): any
	local success, data = pcall(function()
		return HttpService:JSONDecode(SettingsDataStore:GetAsync(key))
	end)
	if success then return data else return nil end
end

local function settingFromString(settingName: string, categoryName: string?, settingsGroup: SettingsGroup)
	if categoryName then
		return settingsGroup[categoryName][settingName]
	else
		for i, category in settingsGroup do
			local setting: Setting = category[settingName]
			if setting then return setting end
		end
	end
end

local function categoryFromString(settingName: string, settingsGroup: SettingsGroup)
	for i, category in settingsGroup do
		local setting: Setting = category[settingName]
		if setting then return i end
	end
end

function SettingsAPI.new(setting: SettingsGroup): MainSettings
	local APIController = {}
	local Setting = {}
	local settingsGroup = setting

	function APIController:Changed(name: string)
		local changedSignal = Signal.new()
		function onChanged() -- TODO: fire this when set is called
			changedSignal:Fire()
		end
		return changedSignal
	end

	function APIController:with(name: string, callback)
		local retrievedSetting: Setting = settingFromString(name, nil, settingsGroup)

		return function(...)
			callback(settingsGroup, ...)
		end
	end

	function APIController:Get(name: string): Setting
		local retrievedSetting: Setting = settingFromString(name, nil, settingsGroup)
		return retrievedSetting
	end

	function APIController:GetCategory(name: string): {Setting}
		local retrievedCategory: SettingsGroup = settingsGroup[name]
		return retrievedCategory
	end

	function APIController:Set(name: string, value: any?): boolean
		if not value then value = "" end
		local success = pcall(function()
			local setting: Setting = settingFromString(name, nil, settingsGroup)
			setting.Value.Value = value
			local category = categoryFromString(name, settingsGroup)
			local newSettingsGroup = settingsGroup
			newSettingsGroup[category][name] = setting
			settingsGroup = newSettingsGroup
		end)
		return success
	end

	return APIController
end



return SettingsAPI

---- SettingsAPI V2
---- Part of Administer
---- metatablecat 2024

--local SettingsAPI = {}

--export type EnumPair = {
--	Key: string,
--	Value: number,
--}

--type Connection = { Disconnect: (Connection) -> () }

--type Setting = {
--	Name: string,
--	DisplayName: string,
--	Description: string,
--	SortOrder: number,
--	EditorType: string, -- not type enforcing this so i dont have to keep changing this
--	Save: (Setting) -> (),
--	Group: SettingsGroup,
--} & ({
--	Type: "boolean",
--	DefaultValue: boolean,
--	Value: boolean,
--} | {
--	Type: "string",
--	DefaultValue: string,
--	Value: string,

--	Constraints: {
--		TrimInput: boolean,
--		LuaPattern: string,
--	},
--} | {
--	Type: "enum",
--	DefaultValue: EnumPair,
--	Value: EnumPair,

--	Constraints: {
--		Values: { EnumPair },
--	},
--} | {
--	Type: "int" | "float",
--	DefaultValue: number,
--	Value: number,
--	Constraints: {
--		Min: number,
--		Max: number,
--		Step: number,
--		DecimalPoints: number, -- 0-14, always 0 for ints
--	},
--})
