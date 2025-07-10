-- AjaxTiba

-- Services
local runService = game:GetService("RunService")
local guiService = game:GetService("GuiService")

local module = {}

-- Metamethods
module.__index = module

-- Slider setup function
function module.setupTextBox(textBox : TextBox)
	-- Fill and slider are optional but 1 must be included
	local self = {}
	
	self.textBox = textBox
	self.value = ""
	
	-- BindableEvents
	self.ValueChangedBindable = Instance.new("BindableEvent")
	self.ValueChanged = self.ValueChangedBindable.Event
	
	-- PC / Mobile support
	if runService:IsClient() then
		self.textBox.FocusLost:Connect(function(enterPressed)
			if not enterPressed then
				return
			end
			self:SetValue(self.textBox.Text)
		end)
	end
	
	self = setmetatable(self, module)
	
	return self
end

-- Set the sliders value
function module:SetValue(value)
	if value ~= self.value then
		self.value = value
		
		self.textBox.Text = value
		
		self.ValueChangedBindable:Fire(self.value)
	end
end

return module
