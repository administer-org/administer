-- AjaxTiba, July 2025 (For pyxfloof)

-- Modules
local variables = require(script.Parent.Variables)
local frontEnd = require(script.Parent.Frontend)
local utilities = require(script.Parent.Utilities)

local core = variables
-- Initialize settings
local Settings = variables.Remotes.GetAllSettings:InvokeServer()
-- Load user data
for i,v in pairs(Settings) do
	local controllerName = v._SettingsMeta.Name
	local success = variables.Remotes.LoadSettings:InvokeServer(controllerName, game.Players.LocalPlayer.UserId)
	if success then
		warn("Failed to load data")
	end
end
Settings = variables.Remotes.GetAllSettings:InvokeServer()

local elements = script.Elements
local elementModules = {
	["Dropdown"] = require(script.ElementModules.Dropdown),
	["InputBox"] = require(script.ElementModules.InputBox),
	["KeybindSelector"] = require(script.ElementModules.KeybindSelector),
	["Slider"] = require(script.ElementModules.Slider),
	["Text"] = require(script.ElementModules.InputBox),
	["Toggle"] = require(script.ElementModules.Toggle),
}

-- Main Module
local clientSettings = {}

clientSettings.SettingElements = {
	["Toggle"] = {
		["Element"] = elements.BoolTemplate,
		["Init"] = function(frame, settingInfo)
			local currentValue = settingInfo.Value.Value
			
			local toggle = elementModules.Toggle.createSwitch(frame.Priorities.Select, frame.Priorities.SelectedItem)
			toggle:SetValue(currentValue)
			
			return toggle.ValueChanged, toggle, "value"
		end,
	},
	["InputBox"] = {
		["Element"] = elements.TextTemplate,
		["Init"] = function(frame, settingInfo)
			local currentValue = settingInfo.Value.Value
			
			local input = elementModules.InputBox.setupTextBox(frame.Action)
			input:SetValue(currentValue)
			
			return input.ValueChanged, input, "value"
		end,
	},
	["KeybindSelector"] = {
		["Element"] = elements.KeybindTemplate,
		["Init"] = function(frame, settingInfo)
			local currentValue = settingInfo.Value.Value
			local keybindsList = {}
			
			for i,v in pairs(string.split(currentValue,",")) do
				table.insert(keybindsList, Enum.KeyCode:FromName(v))
			end
			
			local listener = elementModules.KeybindSelector.createKeybindListener(frame.Priorities.Select, frame.Priorities.SelectedItem)
			listener:SetValue(keybindsList)

			return listener.ValueChanged, listener, "commaSeparatedValue"
		end,
	},
	["Dropdown"] = {
		["Element"] = elements.DropdownTemplate,
		["Init"] = function(frame, settingInfo)
			local currentValue = settingInfo.Value.Value
			
			local dropdown = elementModules.Dropdown.createDropdown(frame.Priorities.Select, frame.Priorities.SelectedItem, frame.Dropdown, frame.Dropdown.ScrollingFrame.UIGridLayout.Template, variables.MainFrame.Parent, settingInfo.Value.Items)
			dropdown:SetValue(currentValue)
			
			local arrowDown = utilities.Icon("arrow-down")
			local arrowUp = utilities.Icon("arrow-up")
			
			frame.Priorities.Select.Arrow.Image = arrowDown
			dropdown.Opened:Connect(function()
				frame.Priorities.Select.Arrow.Image = arrowUp
			end)
			dropdown.Closed:Connect(function()
				frame.Priorities.Select.Arrow.Image = arrowDown
			end)
			
			return dropdown.ValueChanged, dropdown, "value"
		end,
	},
	["Slider"] = {
		["Element"] = elements.SliderTemplate,
		["Init"] = function(frame, settingInfo)
			local currentValue = settingInfo.Value.Value
			local min = settingInfo.Value.Min
			local max = settingInfo.Value.Max
			local step = settingInfo.Value.Step
			local label = frame.Priorities.SelectedItem
			local labelValue = math.round(currentValue * 100) / 100
			label.Text = labelValue
			
			local slider = elementModules.Slider.createSlider(frame.Priorities.Select, min, max, step, frame.Priorities.Bar.Fill, frame.Priorities.Bar.Head)
			slider:SetValue(currentValue)
			slider.ValueChanged:Connect(function()
				local labelValue = math.round(slider.value * 100) / 100
				label.Text = labelValue
			end)
			
			return slider.DragEnded, slider, "value"
		end,
	},
}

local main = variables.MainFrame
local settingsFrame = main:WaitForChild("Configuration").Settings

local selectedCategory = "Interface"
local selectedData = "Administer"
local layoutOrder = 0

function clientSettings.LoadCategories(categories)
	local highestOrder = 0
	for index, settingData in pairs(categories) do
		if index == "_SettingsMeta" then
			local header = elements.Header:Clone()
			header.Text = settingData.Name
			header.Parent = settingsFrame.CategoriesPage
			header.LayoutOrder = layoutOrder
			
			continue
		end
		
		local categoryOptions = settingData._CategoryOpts
		local categoryFrame = elements.CategoryTemplate:Clone()
		
		categoryFrame.Title.Text = categoryOptions.DisplayName
		categoryFrame.Parent = settingsFrame.CategoriesPage
		categoryFrame.LayoutOrder = layoutOrder + 1
		
		categoryFrame.Activator.MouseButton1Click:Connect(function()
			clientSettings.ClearSettings()
			clientSettings.LoadSettings(settingData)
			selectedCategory = categories["_SettingsMeta"].Name
			selectedCategory = index
		end)
	end
	layoutOrder += 2
end

function clientSettings.LoadSettings(settingData)
	local categoryOptions = settingData._CategoryOpts
	
	settingsFrame.DetailsCard.AppName.Text = categoryOptions.DisplayName
	settingsFrame.DetailsCard.AppShortDesc.Text = categoryOptions.Description
	settingsFrame.DetailsCard.ColorBG.ColorFrame.BackgroundColor3 = Color3.fromHex(categoryOptions.Color)
	
	for i, v in pairs(settingData) do
		if i == "_CategoryOpts" then
			continue
		end
		
		local displayType = v["SettingDisplayType"]
		if clientSettings.SettingElements[displayType] then
			local frame = clientSettings.SettingElements[displayType].Element:Clone()
			frame.Parent = settingsFrame.Settings
			
			frame.SettingName.Text = v.DisplayName or i
			frame.Description.Text = v.Description
			frame.SettingID.Text = i
			
			local signal : RBXScriptSignal, object, valueName = clientSettings.SettingElements[displayType].Init(frame, v)
			if not signal then
				continue
			end
			signal:Connect(function()
				local value = object[valueName]
				
				v.Value.Value = value
				local success = variables.Remotes.ModifySetting:InvokeServer(selectedData, i, value)
				
				if success then
					success = variables.Remotes.SaveSettings:InvokeServer(selectedData, game.Players.LocalPlayer.UserId)
					if not success then
						frontEnd.Toast({
							Icon = utilities.Icon("x"),
							Text = "Error",
							Subtext = "Something went wrong saving changes",
							Timeout = 3
						})
						return
					end
					frontEnd.Toast({
						Icon = utilities.Icon("check"),
						Text = "Success",
						Subtext = "Changes applied!",
						Timeout = 3
					})
				else
					frontEnd.Toast({
						Icon = utilities.Icon("x"),
						Text = "Error",
						Subtext = "Something went wrong applying changes",
						Timeout = 3
					})
				end
			end)
		end
	end
end

function clientSettings.ClearSettings()
	for _, frame in pairs(settingsFrame.Settings:GetChildren()) do
		if frame:IsA("Frame") then
			frame:Destroy()
		end
	end
end

for i, v in pairs(Settings) do
	clientSettings.LoadCategories(v)
	if v[selectedCategory] then
		clientSettings.LoadSettings(v[selectedCategory])
	end
end

return clientSettings
