local SettingsAPI = {}

local Types = require(script.Parent.Parent.Core.Types)
local Signal = require(script.Signal)

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local SettingsDataStore = DataStoreService:GetDataStore("Administer_SettingPresets")

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

local function loadDataStore(key: string): {}
	local success, data = pcall(function()
		return HttpService:JSONDecode(SettingsDataStore:GetAsync(key))
	end)
	if success then return data else return {} end
end

local function settingFromString(settingName: string, settingsGroup: SettingsGroup, categoryName: string?, returnAsString: boolean?)
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
		if setting and i ~= "_CategoryOpts" then return i end
	end
end

function SettingsAPI.new(setting, dataStoreKey: string)
	local APIController = {}
	local Setting = {}
	local changedSignal = Signal.new()
	local settingsGroup
	if #Setting == 0 then settingsGroup = loadDataStore("Presets") else settingsGroup = setting end

	function APIController.Changed(names: {settingName: string}, callback) -- fires when either setting changes
		for i, name in names do
			changedSignal:Connect(name, function()
				callback(setting)
			end)
			return changedSignal
		end
	end

	function APIController.with(names: {string}, callback)
		return function(...)
			for i, name in names do
				local retrievedSetting: Setting = settingFromString(name, settingsGroup)
				callback(retrievedSetting, ...)
			end
		end
	end


	function APIController.Get(names: any): any
		if typeof(names) == "table" then
		local returnTable = {}
		for i, name in names do
			local retrievedSetting: Setting = settingFromString(name, settingsGroup)
			returnTable[name] = retrievedSetting["Value"]["Value"]
		end
		return returnTable
		else
			local retrievedSetting: Setting = settingFromString(names, settingsGroup)
			return retrievedSetting["Value"]["Value"]
		end
	end

	function APIController.GetCategory(name: string): {Setting}
		local retrievedCategory: SettingsGroup = settingsGroup[name]
		return retrievedCategory
	end

	function APIController.Set(name: string, value: any?): boolean
		if not value then value = "" end
		local success = pcall(function()
			local setting: Setting = settingFromString(name, settingsGroup)
			setting.Value.Value = value
			local category = categoryFromString(name, settingsGroup)
			local newSettingsGroup = settingsGroup
			newSettingsGroup[category][name] = setting
			settingsGroup = newSettingsGroup
		end)
		if success then changedSignal:Fire(name) end
		return success
	end
	
	function APIController.Save(): boolean
		local success, err = pcall(function()
			saveDataStore(dataStoreKey, settingsGroup)
		end)
		return success
	end
	
	function APIController.Load(customSettings: SettingsGroup?): boolean
		if customSettings then settingsGroup = customSettings end
		local success, err = pcall(function()
			settingsGroup = loadDataStore(dataStoreKey)
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
