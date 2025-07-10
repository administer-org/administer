-- AjaxTiba

-- Services
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local guiService = game:GetService("GuiService")

local module = {}

-- Metamethods
module.__index = module

-- Slider setup function
function module.createKeybindListener(bounds : GuiButton, indicationText : TextLabel)
	-- Fill and slider are optional but 1 must be included
	local self = {}
	
	self.boundingArea = bounds
	self.indicationText = indicationText
	
	self.value = Enum.KeyCode
	self.nameValue = ""
	
	self.listening = false
	
	-- BindableEvents
	self.listeningBindable = Instance.new("BindableEvent")
	self.listeningStarted = self.listeningBindable.Event
	self.ValueChangedBindable = Instance.new("BindableEvent")
	self.ValueChanged = self.ValueChangedBindable.Event
	
	-- PC / Mobile support
	self.boundingArea.MouseButton1Click:Connect(function()
		local pressedKeys = {}
		self.listening = true
		self.boundingArea.Interactable = false
		self.listeningBindable:Fire()
		indicationText.Text = "..."
		local connection0
		local connection1
		connection0 = userInputService.InputBegan:Connect(function(input)
			table.insert(pressedKeys, input.KeyCode)
		end)
		
		connection1 = userInputService.InputEnded:Connect(function(input)
			if input.KeyCode == pressedKeys[1] then
				self:SetValue(pressedKeys)
				self.listening = false
				self.boundingArea.Interactable = true
				
				connection0:Disconnect()
				connection1:Disconnect()
			end
		end)
	end)
	
	self = setmetatable(self, module)
	
	return self
end

-- Set the sliders value
function module:SetValue(value : {Enum.KeyCode})
	if value ~= self.value then
		self.value = value
		local commaSeparated = {}
		for i, v in pairs(value) do
			table.insert(commaSeparated, v.Name)
		end
		commaSeparated = table.concat(commaSeparated,",")
		self.commaSeparatedValue = commaSeparated
		
		self.indicationText.Text = commaSeparated
		
		self.ValueChangedBindable:Fire(self.value.Name)
	end
end

return module
