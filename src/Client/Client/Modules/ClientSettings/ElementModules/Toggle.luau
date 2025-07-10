-- AjaxTiba

-- Services
local tweenService = game:GetService("TweenService")

local module = {}

-- Metamethods
module.__index = module

-- Slider setup function
function module.createSwitch(bounds : GuiButton, indicator : TextLabel)
	-- Fill and slider are optional but 1 must be included
	local self = {}
	
	self.boundingArea = bounds
	self.indicatingText = indicator
	self.value = false
	
	bounds.MouseButton1Click:Connect(function()
		self:SetValue(not self.value)
	end)
	
	-- BindableEvents
	self.valueChangedBindable = Instance.new("BindableEvent")
	self.ValueChanged = self.valueChangedBindable.Event
	
	self = setmetatable(self, module)
	
	return self
end

-- Set the sliders value
function module:SetValue(value)
	if value ~= self.value then
		self.value = value
		if value == true then
			self.indicatingText.Text = "Enabled"
		else
			self.indicatingText.Text = "Disabled"
		end
		
		local properties = {}
		
		self.valueChangedBindable:Fire(self.value)
	end
end

return module
