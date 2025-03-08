local SettingsAPI = {}

local Types = require(script.Parent.Parent.Core.Types)

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

function SettingsAPI.new(setting: SettingsGroup): MainSettings
	local APIController = {}
	local Setting = {}
	local changedEvents = {}
	
	function APIController:Changed()
		local disconnectChangedConnection = {}
		changedEvents[#changedEvents + 1] = function()
			
		end
		function disconnectChangedConnection:Disconnect()
			
		end 
		return disconnectChangedConnection
	end
	
	function APIController:with(name: string, callback)
		local retrievedSetting: Setting = nil -- TODO: get setting from string
		
		return function(...)
			callback(setting, ...)
		end
	end
	
	function APIController:Get(name: string): Setting
		local retrievedSetting: Setting = nil -- TODO: get setting from string
		return retrievedSetting
	end
	
	function APIController:GetCategory(name: string): {Setting}
		local retrievedCategory: SettingsGroup = nil
		
	end
	
	function APIController:Set(value: any?): boolean
		if not value then value = "" end
		
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
