-- AjaxTiba

-- Services
local runService = game:GetService("RunService")
local guiService = game:GetService("GuiService")

local module = {}

module.__index = module
local LastGoodWidth

function module.setupTextBox(textBox: TextBox)
	local self = {}

	self.textBox = textBox
	self.value = ""

	self.ValueChangedBindable = Instance.new("BindableEvent")
	self.ValueChanged = self.ValueChangedBindable.Event

	if runService:IsClient() then
		self.textBox.FocusLost:Connect(function(enterPressed)
			if not enterPressed then
				return
			end
			self:SetValue(self.textBox.Text)
		end)

		self.textBox:GetPropertyChangedSignal("Text"):Connect(function()

		end)
	end

	self = setmetatable(self, module)

	return self
end

function module:SetValue(value)
	if value ~= self.value then
		self.value = value

		self.textBox.Text = value

		self.ValueChangedBindable:Fire(self.value)
	end
end

return module
