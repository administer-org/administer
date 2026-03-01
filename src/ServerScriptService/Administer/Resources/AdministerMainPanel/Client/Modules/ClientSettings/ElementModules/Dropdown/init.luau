-- AjaxTiba

-- Services
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local guiService = game:GetService("GuiService")

--// Modules
local Frontend = require(script.Parent.Parent.Parent.Frontend)
local Utilities = require(script.Parent.Parent.Parent.Utilities)

local module = {}

-- Metamethods
module.__index = module

-- Slider setup function
function module.createDropdown(
	bounds: GuiButton,
	indicationText: TextLabel,
	list: GuiObject,
	template: GuiObject,
	parent: Instance,
	items: {},
	SettingName
)
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
		local LanguageNames

		dropdownMenu.Visible = true
		dropdownMenu.Parent = parent
		dropdownMenu.Size = UDim2.new(0, bounds.AbsoluteSize.X, 0, bounds.AbsoluteSize.Y * 3)
		dropdownMenu.Position =
			UDim2.new(0, bounds.AbsolutePosition.X, 0, bounds.AbsolutePosition.Y + bounds.AbsoluteSize.Y + inset.Y)

		self.openMenu = dropdownMenu
		self.MenuOpened:Fire()

		if SettingName and string.find(SettingName, "Language") ~= nil then
			LanguageNames = game.ReplicatedStorage.Administer.GetLocaleNames:InvokeServer()
		end

		for i, v in items do
			local item = template:Clone()
			item.Parent = dropdownMenu:FindFirstChildWhichIsA("ScrollingFrame")
			item.Visible = true

			local button = item:FindFirstChildWhichIsA("GuiButton")
			local label = item:FindFirstChildWhichIsA("TextLabel")

			if LanguageNames then
				label.Text = `{LanguageNames[v]} [{v}]`
			else
				label.Text = v
			end

			button.MouseButton1Click:Connect(function()
				self:SetValue(v)

				if LanguageNames then
					Frontend.Popup.new(
						{
							Icon = Utilities.Icon("administer"),
							Name = "Administer",
						},
						{
							Primary = Utilities.Icon("translate"),
							SubIcon = Utilities.Icon("administer"),
						},
						game.ReplicatedStorage.Administer.DirectTranslate:InvokeServer(
							v,
							"setting.Locale.Swapped.Title"
						),
						game.ReplicatedStorage.Administer.DirectTranslate:InvokeServer(v, "setting.Locale.Swapped.Body"),
						{
							{
								Text = game.ReplicatedStorage.Administer.DirectTranslate:InvokeServer(v, "generic.OK"),
								Icon = Utilities.Icon("check-plain"),
								Callback = function(a)
									a()
								end,
							},
						}
					)
				end

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
