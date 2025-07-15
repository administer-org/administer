-- AjaxTiba, July 2025 (For pyxfloof)

local Root = script.Parent.Parent.Parent

--// Modules
local Var = require(Root.Variables)
local Frontend = require(Root.Frontend)
local Utilities = require(Root.Utilities)

local TweenService = Var.Services.TweenService
local Frames = Var.MainFrame.Welcome.SetupFull

local tour = {}
tour.Buttons = {}

--[[ Functions ]]--

function tour.GetButtons(frame: GuiObject)
	tour.Buttons = {}

	for _,v in pairs(frame:GetDescendants()) do
		if v:IsA("GuiButton") then
			table.insert(tour.Buttons, v)
		end
	end
end

function tour.ToggleButtons(buttons, enabled)
	local effected = {}
	for _, button: GuiButton in pairs(buttons) do
		if button.Interactable ~= enabled then
			table.insert(effected, button)
		end
		button.Interactable = enabled
	end

	return effected
end

function tour.highlight(button: GuiButton, labelText)
	local active = true

	local Circle = Instance.new("Frame", button)
	local UICorner = Instance.new("UICorner", Circle)

	Circle.BackgroundColor3 = Color3.new(1,1,1)
	Circle.Size = UDim2.new(0,0,0,0)
	Circle.Position = UDim2.fromScale(.5,.5)
	Circle.AnchorPoint = Vector2.new(.5,.5)

	UICorner.CornerRadius = UDim.new(2,0)

	local CircleRipple = TweenService:Create(
		Circle, 
		TweenInfo.new(
			1, 
			Enum.EasingStyle.Quad, 
			Enum.EasingDirection.In
		), 
		{ 
			Size = UDim2.fromScale(1.5,1.5), 
			BackgroundTransparency = 1
		}
	)

	local darken = script.Circle:Clone()
	darken.Parent = Var.MainFrame.Parent
	darken.Size = UDim2.new(0, 6000, 0, 6000)
	local inset = game:GetService("GuiService"):GetGuiInset()

	local label = Instance.new("TextLabel", Var.MainFrame.Parent)
	label.Text = labelText
	label.RichText = true
	label.BackgroundTransparency = 0.5
	label.BackgroundColor3 = Color3.new(0, 0, 0)
	label.ZIndex = 6
	label.Size = UDim2.new(0,0,0,0)
	label.AnchorPoint = Vector2.new(0, 0.5)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = 16
	label.AutomaticSize = Enum.AutomaticSize.XY
	local corner = Instance.new("UICorner", label)
	corner.CornerRadius = UDim.new(0, 8)

	local buttonAbsolutePosition = UDim2.new(0, 0, 0, 0)
	darken.Position = buttonAbsolutePosition
	darken:TweenSize(UDim2.new(0, button.AbsoluteSize.X * 2, 0, button.AbsoluteSize.Y * 2), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .6)

	local updateLoop = game:GetService("RunService").RenderStepped:Connect(function()
		buttonAbsolutePosition = UDim2.new(0, button.AbsolutePosition.X + button.AbsoluteSize.X / 2  + inset.X, 0, button.AbsolutePosition.Y + button.AbsoluteSize.Y / 2 + inset.Y)
		darken.Position = buttonAbsolutePosition
		if buttonAbsolutePosition.X.Offset + darken.AbsoluteSize.X > game.Workspace.CurrentCamera.ViewportSize.X - label.AbsoluteSize.X then
			label.Position = buttonAbsolutePosition - UDim2.new(0, darken.AbsoluteSize.X / 2, 0, 0)
			label.AnchorPoint = Vector2.new(1,0.5)
		else
			label.Position = buttonAbsolutePosition + UDim2.new(0, darken.AbsoluteSize.X / 2, 0, 0)
			label.AnchorPoint = Vector2.new(0,0.5)
		end
	end)

	button.MouseButton1Click:Once(function()
		-- Cleanup
		label:Destroy()
		Circle:Destroy()
		active = false
		darken:Destroy()
		updateLoop:Disconnect()
	end)

	repeat
		CircleRipple:Play()
		CircleRipple.Completed:Wait()

		Circle.Size = UDim2.fromScale(0,0)
		Circle.BackgroundTransparency = 0

		task.wait(.25)
	until not active
end

function tour.Step(button: GuiButton, text: string)
	if not button:IsA("GuiButton") then
		button = button:FindFirstChildWhichIsA("GuiButton")
	end
	-- Grab all visible buttons
	tour.GetButtons(Var.MainFrame)

	local effectedButtons = tour.ToggleButtons(tour.Buttons, false)
	tour.ToggleButtons({button}, true)
	tour.highlight(button, text) -- Yields function until button is clicked

	tour.ToggleButtons(effectedButtons, true)
end

--[[ Start Tour ]]--
function tour.BeginTour()
	Var.IsInTutorial = true
	Var.DoHeaderEffects = true
	Var.TutorialStage = "OpenAppDrawer"

	local Header = Var.MainFrame.Header.Mark
	local apps = Var.MainFrame.AppDrawer.AppHolder.Apps

	--[[ STEPS ]]--

	tour.Step(Header.AppLogo, [[Lets get started by opening the App Drawer.
		<b>Click the App Icon to continue.</b>]])

	tour.Step(apps:WaitForChild("Home"), [[First things first, let's take a look at the homepage.
		<b>Click the Home Button to continue.</b>]])

	tour.Step(Var.MainFrame:WaitForChild("Home").Widget1.Edit, [[Here you can edit a widget to change what it shows.
		<b>Click the Edit Button to continue.</b>]])

	-- Editing a Widget
	tour.Step(Var.MainFrame:WaitForChild("Home").Widget1.Editing.Next, [[You can change the displayed widget by clicking the next button.
	<b>Click the Next Button to continue.</b>]])
	
	task.wait(2)
	
	tour.Step(Var.MainFrame:WaitForChild("Home").Widget1.Editing.Last, [[You can also go back to the previous widget.
	<b>Click the Back Button to continue.</b>]])
	
	task.wait(2)
	
	tour.Step(Var.MainFrame:WaitForChild("Home").Widget1.Editing.Preview, [[Click the widget to select it.
	<b>Click the widget to continue.</b>]])
	
	task.wait(1)

	Frontend.Drawer.Open()

	-- Installing a widget
	tour.Step(apps:WaitForChild("Configuration").SubCollection.Marketplace, [[Open up the Marketplace by clicking Apps.
	<b>Click Apps to continue.</b>]])

	local marketPlace = Var.MainFrame:WaitForChild("Configuration"):WaitForChild("Marketplace").MainMarketplace
	repeat task.wait() until #marketPlace.AAFeatured.TopGrid:GetChildren() > 2

	tour.Step(marketPlace.AAFeatured.MainHot.Stats.DownloadButton, [[Click the Get button to view this app.
	<b>Click Get to continue</b>]]
	)
	tour.Step(marketPlace.InstallBox.Details.Downloads.Install, [[Click the Install button to install this app.
	<b>Click Install to continue</b>]])

	repeat task.wait() until Var.MainFrame.administer.MessageBox.Visible or Var.MainFrame.administer.Toast.Visible
	repeat task.wait() until not Var.MainFrame.administer.MessageBox.Visible and not Var.MainFrame.administer.Toast.Visible

	tour.Step(marketPlace.InstallBox.Details.Votes.Likes:WaitForChild("TextButton"), [[And you can click here to give the app a like.
	<b>Press Like to continue</b>]])
	tour.Step(marketPlace.Parent.Sidebar.Buttons.XLibrary:WaitForChild("TextButton"), [[You can view your installed apps here.
	<b>Press library to continue</b>]])
	repeat task.wait() until #marketPlace.XLibrary.Content:GetChildren() > 3
	task.wait(3)

	-- Admins
	Frontend.Drawer.Open()
	tour.Step(apps:WaitForChild("Configuration").SubCollection.Admins, [[To view and edit your games ranks, you can use the Admins menu.
	<b>Click Admins to continue.</b>]])

	task.wait(3)
	Frontend.Drawer.Open()

	tour.Step(apps:WaitForChild("Configuration").SubCollection.Settings, [[To change any settings you can click Options.
	<b>Click Options to continue.</b>]])

	task.wait(3)

	Frontend.SwapAppBasic(Var.MainFrame.Welcome, {
		Name = "Setup",
		Icon = Utilities.Icon "sparkles"
	})
end

return tour
