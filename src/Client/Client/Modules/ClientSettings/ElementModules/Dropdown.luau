-- AjaxTiba

-- Services
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local guiService = game:GetService("GuiService")

local module = {}

-- Metamethods
module.__index = module

-- Slider setup function
function module.createDropdown(bounds : GuiButton, indicationText : TextLabel, list : GuiObject, template : GuiObject, parent : Instance, items : {})
	-- Fill and slider are optional but 1 must be included
	local self = {}
	
	self.boundingArea = bounds
	self.indicatorText = indicationText
	
	self.value = items[1]
	
	self.openMenu = nil
	
	-- BindableEvents
	self.MenuOpened = Instance.new("BindableEvent")
	self.Opened = self.MenuOpened.Event
	self.MenuClosed = Instance.new("BindableEvent")
	self.Closed = self.MenuClosed.Event
	self.ValueChangedBindable = Instance.new("BindableEvent")
	self.ValueChanged = self.ValueChangedBindable.Event
	
	-- PC / Mobile support
	self.boundingArea.MouseButton1Down:Connect(function()
		if self.openMenu then
			self.openMenu:Destroy()
			self.openMenu = nil
			self.MenuClosed:Fire()
			return
		end
		local inset = game:GetService("GuiService"):GetGuiInset()
		
		local dropdownMenu = list:Clone()
		dropdownMenu.Visible = true
		dropdownMenu.Parent = parent
		dropdownMenu.Size = UDim2.new(0, bounds.AbsoluteSize.X, 0, bounds.AbsoluteSize.Y * 3)
		dropdownMenu.Position = UDim2.new(0, bounds.AbsolutePosition.X, 0, bounds.AbsolutePosition.Y + bounds.AbsoluteSize.Y + inset.Y)
		
		self.openMenu = dropdownMenu
		self.MenuOpened:Fire()
		
		for i, v in ipairs(items) do
			local item = template:Clone()
			item.Parent = dropdownMenu:FindFirstChildWhichIsA("ScrollingFrame")
			item.Visible = true
			local button = item:FindFirstChildWhichIsA("GuiButton")
			local label = item:FindFirstChildWhichIsA("TextLabel")
			
			label.Text = v
			button.MouseButton1Click:Connect(function()
				self:SetValue(v)
				self.openMenu = false
				dropdownMenu:Destroy()
				self.MenuClosed:Fire()
			end)
		end
	end)
	
	self = setmetatable(self, module)
	
	return self
end

-- Set the sliders value
function module:SetValue(value)
	self.indicatorText.Text = value
	
	if value ~= self.value then
		self.value = value
		
		self.ValueChangedBindable:Fire(self.value)
	end
end

return module
