-- dogo8me2 2025

local SettingsAPI = {}

local Types = require(script.Parent.Parent.Core.Types)
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

local function saveDataStore(key: string, serverKey: string, data: {}): boolean
	local clientData = {}
	local serverData = {}
	
	for categoryName, config in data do
		clientData[categoryName] = {}
		serverData[categoryName] = {}
		
		for settingName, data in config do
			
			if data["SaveOnServer"] then
				serverData[categoryName][settingName] = data
			end
			if data["SaveOnClient"] or data["SaveOnClient"] == nil then
				clientData[categoryName][settingName] = data
			end
		end
	end
	
	local success, err = pcall(function()
		SettingsDataStore:SetAsync(key, HttpService:JSONEncode(clientData))
		SettingsDataStore:SetAsync(serverKey, HttpService:JSONEncode(serverData))
	end)
	return success
end

local function loadDataStore(key: string, serverKey: string, template: {}?): {}
	local success, clientData, serverData = pcall(function()
		if key and serverKey then
			return SettingsDataStore:GetAsync(key), SettingsDataStore:GetAsync(serverKey)
		elseif key then
			return SettingsDataStore:GetAsync(key), "{}"
		elseif serverKey then
			return "{}", SettingsDataStore:GetAsync(serverKey)
		else
			warn("A key must be provided")
			return nil, nil
		end
	end)

	if success and clientData and serverData then
		local successDecode, decodedClientData, decodedServerData = pcall(function()
			return HttpService:JSONDecode(clientData), HttpService:JSONDecode(serverData)
		end)
		
		if successDecode then
			local data = {}
			
			for categoryName, config in decodedClientData do
				data[categoryName] = {}

				for settingName, loadedData in config do
					data[categoryName][settingName] = loadedData
				end
			end
			
			for categoryName, config in decodedServerData do
				if data[categoryName] == nil then
					data[categoryName] = {}
				end
				for settingName, loadedData in config do
					data[categoryName][settingName] = loadedData
				end
			end
			
			if template then
				local function mergeTemplate(dataTable, templateTable)
					local result = {}
					for key, value in templateTable do
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

			local _, Value = xpcall(function()
				return retrievedSetting["Value"]["Value"]
			end, function(e)
				--// the setting does not exist
				warn(`[Administer] Setting {names} was not found!`)
				return false	
			end)

			return Value
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
		--// pyxfluff: Workaround for weird issue with caching
		pcall(function()
			if settingsGroup._SettingsMeta.Name ~= "Administer" then return end
			
			for GroupName, Group in settingsGroup do
				Group._CategoryOpts = require(script.Parent.Parent.Core.Configuration).Settings[GroupName]._CategoryOpts
			end
		end)
		
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
				saveDataStore(dataStoreKey .. "#" .. UserId, dataStoreKey .. "#1", settingsGroup)
			end)
			return success
		else
			local localPlayer = Players.LocalPlayer
			local remoteFolder = ReplicatedStorage:FindFirstChild("Administer")
			local saveRemote: RemoteFunction = remoteFolder:FindFirstChild("SaveSettings")
			
			return saveRemote:InvokeServer(settingsGroup["_SettingsMeta"].Name, UserId)
		end
	end

	function APIController.Load(UserId: number?, customTemplate: SettingsGroup?): boolean
		if isServer then
			local success, err = pcall(function()
				settingsGroup = loadDataStore(dataStoreKey .. "#" .. UserId, dataStoreKey .. "#1", customTemplate or rawSettings)
			end)
			
			if success then
				local remoteFolder = ReplicatedStorage:FindFirstChild("Administer")
				pcall(function() --// if this fails the server is not loaded yet
					local loaded:RemoteEvent = remoteFolder:WaitForChild("SettingsLoaded", 0.5)
					
					loaded:FireAllClients()
				end)
			end
			return success
		else
			local localPlayer = Players.LocalPlayer
			local remoteFolder = ReplicatedStorage:FindFirstChild("Administer")
			local loadRemote: RemoteFunction = remoteFolder:FindFirstChild("LoadSettings")
			
			return loadRemote:InvokeServer(settingsGroup["_SettingsMeta"].Name, UserId, customTemplate)
		end
	end

	table.insert(SettingsAPI.SettingsList, APIController)
	
	return APIController
end

return SettingsAPI
