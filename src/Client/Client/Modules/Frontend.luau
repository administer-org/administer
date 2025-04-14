--// Administer (2.0.0)

--// pyxfluff (2024-2025)

local Frontend = { Popup = {}, Drawer = {} }

local Libraries = script.Parent.Parent.Libraries
local Modules = script.Parent

local Utilities = require(Modules.Utilities)
local Var = require(Modules.Variables)
local Types = require(Modules.Types)

function Frontend.Render() end

function Frontend.CloneElement(Element: GuiObject, Props: {}, OnClone: ((Clone: GuiObject) -> ())?): ()
	local Clone = Element:Clone()

	for Property, Value in Props do
		Clone[Property] = Value
	end

	Clone.Parent = Element.Parent

	if typeof(OnClone) == "nil" then
		return Clone
	else
		return OnClone(Clone)
	end
end

function Frontend.Log(Text, LogLevel)
	--// TODO
	return { MainFrame = {} }
end

function Frontend.Open(WaitForCompletion): ()
	if not Var.Panel then Var.Panel = Frontend.Render() end
	--local AS = tonumber(Utilities.GetSetting("AnimationSpeed"))
	local AS = 1
	local X = 0.85
	local Y = 0.7

	Var.MainFrame.Size = UDim2.fromScale(X / 1.5, Y / 1.5)
	Var.MainFrame.GroupTransparency = 0.5

	Var.IsPanelAnimating = true
	Var.MainFrame.Visible = true
	if Var.UseAcrylic then
		Libraries.Neon:BindFrame(Var.Panel.MainFrame, {
			Transparency = 0.95,
			BrickColor = BrickColor.new("Institutional white"),
		})
	end

	if not Var.Mobile then
		Var.MainFrame.Position = UDim2.fromScale(0.5, 1.5)
	else
		Var.MainFrame.Position = UDim2.fromScale(1.5, 0.5)
	end

	local PopupTween = Var.Services.TweenService:Create(
		Var.MainFrame,
		TweenInfo.new(AS, Enum.EasingStyle.Cubic),
		{ Position = UDim2.fromScale(0.5, 0.5), GroupTransparency = 0 }
	)

	PopupTween:Play()

	Var.Services.TweenService
		:Create(
			Var.MainFrame,
			TweenInfo.new(AS, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, 0, false, AS * 0.2),
			{
				Size = UDim2.fromScale(X, Y),
			}
		)
		:Play()

	--Var.OpenSound:Play()
	task.delay(AS, function()
		Var.IsPanelAnimating = false
		Var.IsOpen = true
	end)

	if WaitForCompletion then
		task.wait(AS)
	end
end

function Frontend.Close(Instant: boolean, WaitForCompletion): ()
	Var.IsPanelAnimating = true

	xpcall(function(...)
		Libraries.Neon:UnbindFrame(Var.MainFrame)
	end, function(a0)
		--// We can ignore this, it probably happened bc a skid is spamming the keybind.
		Var.InitErrored = true
	end)

	local Duration = 0
	if not Instant then Duration = (tonumber(Utilities.GetSetting("AnimationSpeed")) or 1) end

	local X: number = 0.85
	local Y: number = 0.7

	local OT = Var.Services.TweenService:Create(
		Var.MainFrame,
		TweenInfo.new(Duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{
			Size = UDim2.fromScale(X / 1.5, Y / 1.5),
			GroupTransparency = 0.5,
		}
	)

	OT:Play()

	if not Var.Mobile then
		Var.Services.TweenService
			:Create(
				Var.MainFrame,
				TweenInfo.new(Duration, Enum.EasingStyle.Cubic),
				{ Position = UDim2.fromScale(0.5, 1.5), GroupTransparency = 1 }
			)
			:Play()
	else
		Var.Services.TweenService
			:Create(
				Var.MainFrame,
				TweenInfo.new(Duration, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out, 0, false, Duration * 0.45),
				{ Position = UDim2.fromScale(1.5, 0.5), GroupTransparency = 1 }
			)
			:Play()
	end

	task.delay(Duration, function()
		Var.IsPanelAnimating = false
		Var.MainFrame.Visible = false
		Var.IsOpen = false
	end)

	if WaitForCompletion then
		task.wait(Duration)
	end
end

function Frontend.CheckForUpdates(Products: {}?): ()
	--// TODO: Full product checking, need to redo this regardless
	local Label = Var.MainFrame.Configuration.InfoPage.VersionDetails.Update.Label
	Label.Text = "CHECKING"

	--// fake slowdown lol
	task.wait(0.25)
	Var.Remotes.CheckForUpdates:InvokeServer()
	Label.Text = "COMPLETE"

	task.delay(3, function()
		Label.Text = "CHECK FOR UPDATES"
	end)
end

local Hovers = {}
local CurrentlyActive
local Ready = true
local IsQueued = false
local ShouldAnimate = true

function Frontend.Drawer.Open(): ()
	if not Var.DoHeaderEffects then return end --// Stops clicking the button multiple times which results in broken UI
	if Var.PopupOpen then return end --// stops UI from breaking itself
	
	Frontend.Drawer.HoverEnd()

	local Apps = Var.MainFrame.AppDrawer
	local Container = Instance.new("CanvasGroup")
	local UiC = Instance.new("UICorner")
	local TimeToComplete

	Var.DoHeaderEffects = false
	ShouldAnimate = true
	Ready = true

	local function Clear(MainPageStaysVisible: bool)
		for _, Frame in Container:GetChildren() do
			if Frame.Name == "Header" then continue end

			if Frame:GetAttribute("AdmLinkSinglePage") then 
				Frame.Visible = false

				continue
			end

			for _, Frame in Frame:GetChildren() do
				if not Frame:IsA("CanvasGroup") and not Frame:IsA("Frame") or Frame:GetAttribute("AdmIgnoreVisibility") then continue end

				Frame.Visible = false
			end

			Var.ActivePage.Visible = MainPageStaysVisible
		end
	end

	xpcall(function()
		TimeToComplete = tonumber(Utilities.GetSetting("AnimationSpeed") * 2) or 2
	end, function(e)
		--// This is a temporary fix
		TimeToComplete = 2
	end)

	Container.Size = UDim2.new(1, 0, 1, 0)
	Container.Position = UDim2.new(0, 0, 0, 0)

	Container.ZIndex = 99999
	Container.Parent = Apps.AppDrawerCover
	Container.BackgroundTransparency = 1
	Container.BackgroundColor3 = Color3.fromRGB(11, 12, 17)

	UiC.CornerRadius = UDim.new(0, 18)
	UiC.Parent = Container

	Apps.Visible = true
	Apps.Position = UDim2.new(0, 0, 0.75, 0)

	Apps.AppHolder.Position = UDim2.new(0, 0, 0.45, 0)

	for _, Child in Var.MainFrame:GetChildren() do
		if (Child:IsA("Frame") or Child:IsA("CanvasGroup")) and Child.Name ~= "AppDrawer" then
			Child.Parent = Container 

			if Child.Name == Var.ActivePage.Name then
				CurrentlyActive = Child
			end
		end
	end

	Clear(true)

	Var.Services.TweenService
		:Create(Container, TweenInfo.new(TimeToComplete, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, 0, false), {
			GroupTransparency = 0,
			BackgroundTransparency = 0.25,
			Size = UDim2.new(0.95, 0, 0.95, 0),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
		})
		:Play()

	Var.Services.TweenService
		:Create(Apps, TweenInfo.new(TimeToComplete * 0.3, Enum.EasingStyle.Quart), {
			Position = UDim2.new(0, 0, 0, 0),
		})
		:Play()

	Var.Services.TweenService
		:Create(Apps.AppHolder, TweenInfo.new(TimeToComplete * 0.55, Enum.EasingStyle.Quart), {
			GroupTransparency = 0,
			Position = UDim2.new(0, 0, 0, 0),
		})
		:Play()

	for _, Button in Apps.AppHolder:GetDescendants() do
		if Button.Name ~= "Activator" or Button:FindFirstAncestor("MultiThread") or Button:FindFirstAncestor("SingleThread") then continue end

		local function AppOver(SubIcon, AppVisible)
			--print(IsQueued, Ready, ShouldAnimate)
			--print("expected: {} true true")
			IsQueued = true
			repeat task.wait() until Ready
			Ready = false

			if not ShouldAnimate then return end

			Var.Services.TweenService:Create(Container, TweenInfo.new(.2), { GroupTransparency = 1 }):Play()

			if IsQueued then
				IsQueued = false
				Ready = true
			end

			Clear(false)
			task.wait(.2)

			--// Check again?
			if not ShouldAnimate then return end

			CurrentlyActive.Visible = not AppVisible
			SubIcon.Frame.Visible = AppVisible

			Var.Services.TweenService:Create(Container, TweenInfo.new(.2), { GroupTransparency = 0 }):Play()

			Ready = true
		end

		Button.MouseEnter:Connect(function()
			--// Recursively find the frame bc idk!!
			for _, Object in Var.CombinedButtonConfig do
				for _, SubIcon in Object.SubIcons do
					if SubIcon.Icon ~= Button.Parent.Icon.Image then continue end

					AppOver(SubIcon, true)
				end
			end
		end)

		Button.MouseLeave:Connect(function()
			--// Same dumb logic as above
			for _, Object in Var.CombinedButtonConfig do
				for _, SubIcon in Object.SubIcons do

					if SubIcon.Icon ~= Button.Parent.Icon.Image then continue end
					AppOver(SubIcon, false)
				end
			end
		end)
	end
end

function Frontend.Drawer.Close(): ()
	local Apps = Var.MainFrame.AppDrawer
	local Container = Apps.AppDrawerCover.CanvasGroup
	local TimeToComplete

	ShouldAnimate = false

	xpcall(function()
		TimeToComplete = tonumber(Utilities.GetSetting("AnimationSpeed")) or 1
	end, function(e)
		--// This is a temporary fix
		TimeToComplete = 2
	end)

	Container.Parent.Parent = Var.MainFrame
	Container.Parent.Size = UDim2.new(.75,0,1,0)
	Container.Parent.Position = UDim2.new(.25,0,0,0)

	Var.Services.TweenService
		:Create(Apps, TweenInfo.new(TimeToComplete * 0.75, Enum.EasingStyle.Quart), {
			Position = UDim2.new(0, 0, 1, 0),
		})
		:Play()

	Var.Services.TweenService
		:Create(Apps.AppHolder, TweenInfo.new(TimeToComplete * 0.55, Enum.EasingStyle.Quart), {
			Position = UDim2.new(0, 0, .75, 0),
			GroupTransparency = 1,
		})
		:Play()

	Var.Services.TweenService
		:Create(Container.Parent, TweenInfo.new(TimeToComplete * .6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, 0, false), {
			Position = UDim2.new(0.5,0,0.5,0),
			Size = UDim2.new(1,0,1,0),

			AnchorPoint = Vector2.new(.5,.5),
			BackgroundTransparency = 1
		})
		:Play()

	task.wait(TimeToComplete * .6)

	Var.Services.TweenService
		:Create(Container, TweenInfo.new(TimeToComplete * 0.5, Enum.EasingStyle.Quart), {
			Size = UDim2.new(1,0,1,0),

			BackgroundTransparency = 1,
			GroupTransparency = 0
		})
		:Play()

	task.wait(TimeToComplete * .5)

	for _, Child in Container:GetChildren() do
		if Child:IsA("Frame") or Child:IsA("CanvasGroup") then Child.Parent = Var.MainFrame end
	end

	Container.Parent.Parent      = Apps
	Container.Parent.Size        = UDim2.new(3,0,1,0)
	Container.Parent.Position    = UDim2.new(1,0,0,0)
	Container.Parent.AnchorPoint = Vector2.new(0,0)

	Container:Destroy()

	Var.DoHeaderEffects = true
	Ready = true
end

function Frontend.Drawer.HoverBegin()
	if not Var.DoHeaderEffects then return end

	local MarkBox = Var.MainFrame.Header.Mark.AppLogo
	local QuickTI = TweenInfo.new(.25, Enum.EasingStyle.Quart)

	Var.Services.TweenService:Create(MarkBox.GridIcon, QuickTI, {
		Size = UDim2.new(.75,0,.75,0)
	}):Play()

	Var.Services.TweenService:Create(MarkBox.AppIcon, QuickTI, {
		Size = UDim2.new(.25,0,.25,0),
		ImageTransparency = .75
	}):Play()
end

function Frontend.Drawer.HoverEnd()
	if not Var.DoHeaderEffects then return end

	local MarkBox = Var.MainFrame.Header.Mark.AppLogo
	local QuickTI = TweenInfo.new(.25, Enum.EasingStyle.Quart)

	Var.Services.TweenService:Create(MarkBox.GridIcon, QuickTI, {
		Size = UDim2.new(0,0,0,0)
	}):Play()

	Var.Services.TweenService:Create(MarkBox.AppIcon, QuickTI, {
		Size = UDim2.new(1,0,1,0),
		ImageTransparency = 0
	}):Play()
end

Frontend.Popup.OriginalStates = {}

function Frontend.Popup.Open(): ()
	local BGTweenInfo = TweenInfo.new(1 * .65, Enum.EasingStyle.Cubic)

	Frontend.Popup.OriginalStates = {}

	for _, descendant in Var.MainFrame:GetChildren() do
		if descendant:IsA("Frame") or descendant:IsA("CanvasGroup") then
			if descendant:GetAttribute("AdmDoNotMove") then continue end
			
			local original = {
				Size = descendant.Size,
				Position = descendant.Position,
				Color = descendant.BackgroundColor3,
				AnchorPoint = descendant.AnchorPoint
			}
			Frontend.Popup.OriginalStates[descendant] = original

			Var.Services.TweenService:Create(descendant, BGTweenInfo, {
				Size = UDim2.new(original.Size.X.Scale * 0.75, 0, original.Size.Y.Scale * 0.75, 0),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(.5,.5),
				BackgroundColor3 = original.Color:lerp(Color3.fromRGB(16, 17, 20), 0.6),
			}):Play()
		end
	end
	
	local Popup = Var.MainFrame.MessageBox
	
	local PopupOriginalSize = Popup.Size
	local SizeStr = string.split(tostring(Popup.Size), ",")
	local X = tonumber(string.split(string.gsub(SizeStr[1], "{", ""), " ")[1])
	local Y = tonumber(string.split(string.gsub(SizeStr[3], "{", ""), " ")[2])

	Popup.Size = UDim2.fromScale(X / 1.5, Y / 1.5)
	Popup.Position = UDim2.fromScale(0.5, 1.25)
	Popup.GroupTransparency = 0.5
	Popup.Visible = true

	Utilities.Logging.Print("Calculated, proceeding")

	local PopupTween = Var.Services.TweenService:Create(Popup, TweenInfo.new(1, Enum.EasingStyle.Cubic), {
		Position = UDim2.fromScale(0.5, 0.5),
		GroupTransparency = 0
	})

	PopupTween:Play()
	Utilities.Logging.Print("All done apparently...")

	Var.Services.TweenService:Create(Popup, TweenInfo.new(1 * 0.85, Enum.EasingStyle.Cubic), {
		Size = PopupOriginalSize
	}):Play()
	Var.PopupOpen = true
end

function Frontend.Popup.Close(): ()
	local BGTweenInfo = TweenInfo.new(1 * .65, Enum.EasingStyle.Cubic)

	for descendant, original in Frontend.Popup.OriginalStates do
		if descendant then
			Var.Services.TweenService:Create(descendant, BGTweenInfo, {
				Size = original.Size,
				Position = original.Position,
				BackgroundColor3 = original.Color,
				AnchorPoint = original.AnchorPoint
			}):Play()
		end
	end

	local Box = Var.MainFrame.MessageBox
	local PopupOriginalSize = Box.Size
	local SizeStr = string.split(tostring(Box.Size), ",")
	local X = tonumber(string.split(string.gsub(SizeStr[1], "{", ""), " ")[1])
	local Y = tonumber(string.split(string.gsub(SizeStr[3], "{", ""), " ")[2])

	local PopupTween = Var.Services.TweenService:Create(Box, TweenInfo.new(1 * .85, Enum.EasingStyle.Cubic), {
		Size = UDim2.new(X * 0.35, 0, Y * 0.35, 0),
		GroupTransparency = 1
	})

	PopupTween:Play()
	PopupTween.Completed:Wait()
	
	Box.Size = PopupOriginalSize
	Box.Visible = false
	Var.PopupOpen = false
end

local MessageBox = Var.MainFrame.MessageBox
local ButtonOneOriginalPos = MessageBox.Button1.Position
local PopupButtons = {}

function Frontend.Popup.new(
	App: {
		Name: string,
		Subheader: string,
		Icon: string
	},

	Icons: {
		Primary: string,
		SubIcon: string?
	},

	Header:     string,
	BodyText:   string,

	Options: { 
		{ 
			Text: string, Icon: string, Callback: (Close: () -> (), TextInputChoices: { string? }) -> () 
		}
	},

	TextInputs: { 
		{ 
			HeaderText: string 
		}
	}

): ()
	if Options ~= nil and #Options > 2 then 
		Utilities.Logging.Warn("Popups may not have more than two buttons.")
		return {false, "FAILED"}
	end

	if TextInputs ~= nil and #TextInputs > 2 then 
		Utilities.Logging.Warn("Popups may not have more than two text inputs.")
		return {false, "FAILED"}
	end
	
	if Var.PopupOpen then
		return {false, "Only one popup may be open at a time."}
	end

	for _, Signal in PopupButtons do
		Signal:Disconnect()
	end

	local ClosePopup = Frontend.Popup.Close

	MessageBox.Header.HeaderLabel.Text = `<b>{App.Name}</b>\n{App.Subheader ~= nil and App.Subheader or Header}`
	MessageBox.Header.AppIcon.Image = App.Icon

	MessageBox.PrimaryText.Text = Header
	MessageBox.SubText.Text = BodyText

	MessageBox.AppLogo.LogoImage.Image = Icons.Primary
	MessageBox.SubIcon.Image = Icons.SubIcon

	MessageBox.Button1.Label.Text = Options[1].Text
	MessageBox.Button1.Icon.Image = Options[1].Icon
	PopupButtons[1] = MessageBox.Button1.MouseButton1Click:Connect(function()
		Options[1].Callback(ClosePopup, {
			MessageBox.TextInputs[1].Box.Text, 
			MessageBox.TextInputs[2].Box.Text
		})
	end)

	xpcall(function()
		MessageBox.Button2.Label.Text = Options[2].Text
		MessageBox.Button2.Icon.Image = Options[2].Icon
		PopupButtons[2] = MessageBox.Button2.MouseButton1Click:Connect(function()
			Options[2].Callback(ClosePopup, {
				MessageBox.TextInputs[1].Box.Text, 
				MessageBox.TextInputs[2].Box.Text
			})
		end)

		MessageBox.Button2.Visible = true
		MessageBox.Button1.AnchorPoint = Vector2.zero
		MessageBox.Button1.Position = ButtonOneOriginalPos
	end, function()
		--// Allow for having only one button
		MessageBox.Button2.Visible = false
		MessageBox.Button1.AnchorPoint = Vector2.new(.5, 0)
		MessageBox.Button1.Position = UDim2.fromScale(.5, MessageBox.Button1.Position.Y.Scale) 
	end)
	
	if TextInputs == nil then
		MessageBox.SubText.TextYAlignment = Enum.TextYAlignment.Center
		
		for _, Box in MessageBox.TextInputs:GetChildren() do
			if Box:IsA("Frame") then Box.Visible = false end
		end
	else
		MessageBox.SubText.TextYAlignment = Enum.TextYAlignment.Top
		
		for Num, Input in TextInputs do
			MessageBox.TextInputs[Num].Visible = true
			MessageBox.TextInputs[Num].Label.Text = Input.HeaderText
		end
	end

	Frontend.Popup.Open()
	MessageBox.Visible = true
end

function Frontend.SwapApps(AppConfig: Types.ButtonConfig, Clicked: number, Button)
	local NewFrame

	if Clicked == 0 then
		NewFrame = AppConfig.MainButtonFrame
	else
		NewFrame = AppConfig.SubIcons[Clicked].Frame
	end

	for _, Frame in Var.MainFrame:GetChildren() do
		--// Use their descendants, not the parent
		if Frame.Name == "Header" or Frame.Name == "AppDrawer" then continue end

		if Frame:GetAttribute("AdmLinkSinglePage") then 
			Frame.Visible = false

			continue
		end

		for _, Frame in Frame:GetChildren() do
			if not Frame:IsA("CanvasGroup") and not Frame:IsA("Frame") or Frame:GetAttribute("AdmIgnoreVisibility") then continue end

			Frame.Visible = false
		end
	end

	NewFrame.Visible = true

	Var.ActivePage = NewFrame

	repeat task.wait() until Var.MainFrame:FindFirstChild("Header") --// close animation 

	Var.MainFrame.Header.Mark.HeaderLabel.Text = `<b>Administer{Clicked ~= 0 and ` {AppConfig.AppName}` or ""}</b> · {Clicked == 0 and AppConfig.AppName or AppConfig.SubIcons[Clicked].Name}`
	Var.MainFrame.Header.Mark.AppLogo.AppIcon.Image = AppConfig.Icon
	Var.MainFrame.Header.Mark.Logo.Image = Clicked == 0 and "rbxassetid://116599744136879" or AppConfig.SubIcons[Clicked].Icon
end

function Frontend.InitGestureBar()
	local Connection

	Var.MainFrame.Header.GestureBar.InputBegan:Connect(function(Input)
		if Connection then
			Connection:Disconnect()
		end

		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			local StartPos, StartSize = Input.Position, Var.MainFrame.Size

			Connection = Var.Services.UserInputService.InputChanged:Connect(function(MoveInput)
				if MoveInput.UserInputType == Enum.UserInputType.MouseMovement then
					local Delta = -(MoveInput.Position - StartPos)
					Var.MainFrame.Size = UDim2.new(StartSize.X.Scale, StartSize.X.Offset + -(Delta.X), StartSize.Y.Scale, StartSize.Y.Offset + Delta.Y)
				end
			end)

		elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
			local StartPos, StartPanelPos = Input.Position, Var.MainFrame.Position

			Connection = Var.Services.UserInputService.InputChanged:Connect(function(MoveInput)
				if MoveInput.UserInputType == Enum.UserInputType.MouseMovement then
					local Delta = MoveInput.Position - StartPos
					Var.MainFrame.Position = UDim2.new(StartPanelPos.X.Scale, StartPanelPos.X.Offset + Delta.X, StartPanelPos.Y.Scale, StartPanelPos.Y.Offset + Delta.Y)
				end
			end)
		end

		if Var.Services.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) and 
			Var.Services.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
			Frontend.Close()
		end
	end)

	Var.MainFrame.Header.GestureBar.InputEnded:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.MouseButton2 then
			repeat 
				task.wait()
			until not Var.Services.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) 
				and not Var.Services.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)

			if Connection then
				Connection:Disconnect()
			end
		end
	end)
end

return Frontend
