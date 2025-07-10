-- dogo8me2 2025

local SettingsAPI = {}

local Types = require(script.Parent.Parent.Core.Types)
local Utilities = require(script.Parent.Utilities)
local Signal = require(script.Signal)

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
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

local function loadDataStore(key: string, template: {}?): {}
	local success, rawData = pcall(function()
		return SettingsDataStore:GetAsync(key)
	end)

	if success and rawData then
		local successDecode, data = pcall(function()
			return HttpService:JSONDecode(rawData)
		end)

		if successDecode and typeof(data) == "table" then
			if template then
				local function mergeTemplate(dataTable, templateTable)
					local result = {}
					for key, value in pairs(templateTable) do
						if typeof(value) == "table" then
							result[key] = mergeTemplate(dataTable and dataTable[key] or {}, value)
						else
							result[key] = dataTable and dataTable[key] ~= nil and dataTable[key] or value
						end
					end
					return result
				end

				return mergeTemplate(data, template)
			else
				return data
			end
		end
	end

	-- Return template if provided, otherwise empty
	if template then
		return template
	end
	return {}
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

SettingsAPI.SettingsList = {}

function SettingsAPI.GetController(name: string)
	for i,v in pairs(SettingsAPI.SettingsList) do
		local data = v.GetData()["_SettingsMeta"]
		if data.Name == name then
			return v
		end
	end

	return nil
end

function SettingsAPI.new(rawSettings)
	local remotes = {}
	
	local function cloneTable(list)
		local newTable = {}
		for i, v in list do
			if typeof(v) == "table" then
				newTable[i] = cloneTable(v)
			else
				newTable[i] = v
			end
		end

		return newTable
	end
	local settingsGroup = cloneTable(rawSettings)

	local isServer = RunService:IsServer()
	local APIController = {}
	local dataStoreKey = settingsGroup["_SettingsMeta"].Name
	local changedSignal = Signal.new()

	function APIController.Changed(names: {settingName: string}, callback) -- fires when either setting changes
		for i, name in names do
			changedSignal:Connect(name, function()
				callback(settingsGroup)
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
	
	function APIController.GetRemote(names: any)
		if typeof(names) == "table" then
			local returnTable = {}
			for i, name in names do
				local retrievedRemote = remotes[name]
				if retrievedRemote == nil then
					retrievedRemote = Instance.new("RemoteEvent")
					remotes[name] = retrievedRemote
				end
				returnTable[name] = retrievedRemote
			end
			return returnTable
		else
			local retrievedRemote = remotes[names]
			if retrievedRemote == nil then
				retrievedRemote = Instance.new("RemoteEvent")
				retrievedRemote.Parent = game.ReplicatedStorage:WaitForChild("Administer")
				remotes[names] = retrievedRemote
				return retrievedRemote
			end
			return retrievedRemote
		end
	end

	function APIController.GetData(): any
		return settingsGroup
	end

	function APIController.GetCategory(name: string)
		local retrievedCategory: SettingsGroup = settingsGroup[name]
		return retrievedCategory
	end

	function APIController.Set(name: string, value: any?): boolean
		if not value then value = "" end
		
		local success = pcall(function()
			local setting: Setting = settingFromString(name, settingsGroup)
			setting.Value.Value = value
		end)
		
		pcall(function()
			if success then changedSignal:Fire(name) end
		end)
		
		if remotes[name] then
			local remote: RemoteEvent = remotes[name]
			remote:FireAllClients(value)
		end

		return success
	end

	function APIController.Save(UserId: number?): boolean
		if isServer then
			local success, err = pcall(function()
				saveDataStore(dataStoreKey .. "#" .. UserId, settingsGroup)
			end)
			return success
		else
			local localPlayer = Players.LocalPlayer
			local remoteFolder = ReplicatedStorage:FindFirstChild("Administer")
			local saveRemote: RemoteFunction = remoteFolder:FindFirstChild("SaveSettings")
			return saveRemote:InvokeServer(settingsGroup["_SettingsMeta"].Name, UserId)
		end
	end

	function APIController.Load(UserId: number?, customSettings: SettingsGroup?): boolean
		if isServer then
			if customSettings then settingsGroup = customSettings end
			local success, err = pcall(function()
				settingsGroup = loadDataStore(dataStoreKey .. "#" .. UserId, rawSettings)
			end)
			if success then
				local remoteFolder = ReplicatedStorage:FindFirstChild("Administer")
				local loaded:RemoteEvent = remoteFolder:WaitForChild("SettingsLoaded")
				loaded:FireAllClients()
			end
			return success
		else
			local localPlayer = Players.LocalPlayer
			local remoteFolder = ReplicatedStorage:FindFirstChild("Administer")
			local loadRemote: RemoteFunction = remoteFolder:FindFirstChild("LoadSettings")
			return loadRemote:InvokeServer(settingsGroup["_SettingsMeta"].Name, UserId, customSettings)
		end
	end

	table.insert(SettingsAPI.SettingsList, APIController)
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
