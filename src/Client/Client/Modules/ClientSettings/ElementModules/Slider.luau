-- AjaxTiba

-- Services
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local guiService = game:GetService("GuiService")

local module = {}

-- Metamethods
module.__index = module

-- Slider setup function
function module.createSlider(bounds : GuiButton, min, max, step, fill : Frame, head : Frame)
	-- Fill and slider are optional but 1 must be included
	local self = {}
	
	self.boundingArea = bounds
	self.fill = fill
	self.head = head
	
	self.minimumValue = min
	self.maximumValue = max
	self.roundingValue = step
	self.value = 0
	
	self.dragging = false
	
	-- BindableEvents
	self.dragStartBindable = Instance.new("BindableEvent")
	self.DragBegin = self.dragStartBindable.Event
	self.dragEndBindable = Instance.new("BindableEvent")
	self.DragEnded = self.dragEndBindable.Event
	self.ValueChangedBindable = Instance.new("BindableEvent")
	self.ValueChanged = self.ValueChangedBindable.Event
	
	-- PC / Mobile support
	self.boundingArea.MouseButton1Down:Connect(function()
		self.dragging = true
		self.dragStartBindable:Fire()
		
		repeat
			local mousePos = userInputService:GetMouseLocation().X
			local barPos = self.boundingArea.AbsolutePosition.X
			local xPos = mousePos - barPos
			local range = (self.maximumValue - self.minimumValue)
			local barSize = self.boundingArea.AbsoluteSize.X
			local rawValue = math.clamp(xPos / barSize, 0, 1) * range + self.minimumValue
			
			local roundValue = math.round(rawValue / self.roundingValue) * self.roundingValue
			
			self:SetValue(roundValue)
			
			runService.RenderStepped:Wait()
		until not self.dragging
	end)
	
	userInputService.InputEnded:Connect(function(inputObject, processed)
		if self.dragging then
			if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then
				self.dragging = false
				
				self.dragEndBindable:Fire()
			end
		end
	end)
	
	self = setmetatable(self, module)
	
	return self
end

-- Set the sliders value
function module:SetValue(value)
	if value ~= self.value then
		self.value = value
		
		local range = (self.maximumValue - self.minimumValue)
		local x = (self.value - self.maximumValue) / range + 1
		
		if self.fill then
			self.fill.Size = UDim2.new(
				x,0,
				1,0
			)
		end
		
		if self.head then
			self.head.Position = UDim2.new(
				x,0,
				0.5,0
			)
		end
		
		self.ValueChangedBindable:Fire(self.value)
	end
end

return module
