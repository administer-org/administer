-- AjaxTiba

-- Services
local tweenService = game:GetService("TweenService")

local module = {}

module.__index = module

function module.createSwitch(bounds: GuiButton, indicator: TextLabel)
	local self = {}

	self.boundingArea = bounds
	self.indicatingText = indicator
	self.value = false

	bounds.MouseButton1Click:Connect(function()
		self:SetValue(not self.value)
	end)

	self.valueChangedBindable = Instance.new("BindableEvent")
	self.ValueChanged = self.valueChangedBindable.Event

	self = setmetatable(self, module)

	return self
end

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
