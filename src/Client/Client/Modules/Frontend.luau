--// Administer

--// pyxfluff 2024-2025

local Frontend = { Popup = {}, Drawer = {} }

local Libraries = script.Parent.Parent.Libraries
local Modules   = script.Parent

local Utilities   = require(Modules.Utilities)
local Ripple      = require(Modules.Parent.Parent.ButtonAnims)
local Var         = require(Modules.Variables)
local Types       = require(Modules.Types)

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

function Frontend.ToggleFullscreen(
	ForceClose: boolean, 
	TargetFrame: Frame | CanvasGroup
): ()
	if not TargetFrame then
		Utilities.Logging.Error("A TargetFrame is required to resize")
	end

	local Speed = Var.AnimationSpeed * .75

	if TargetFrame:GetAttribute("IsFullScreen") == true or ForceClose == true then
		TargetFrame:SetAttribute("IsFullScreen", false)

		Var.Services.TweenService:Create(Var.MainFrame, TweenInfo.new(Speed, Enum.EasingStyle.Quart), { Size = UDim2.fromScale(.843,.708) }):Play()
		Var.Services.TweenService:Create(Var.MainFrame.UICorner, TweenInfo.new(Speed, Enum.EasingStyle.Quart), { CornerRadius = UDim.new(0, 20) }):Play()
		Var.Services.TweenService:Create(Var.MainFrame.Header.Mark, TweenInfo.new(Speed, Enum.EasingStyle.Quart), { Position = UDim2.new(.328, 0, 0, 0) }):Play()
	else
		TargetFrame:SetAttribute("IsFullScreen", true)

		Var.Services.TweenService:Create(Var.MainFrame, TweenInfo.new(Speed, Enum.EasingStyle.Quart), { Size = UDim2.fromScale(1, 1), Position = UDim2.fromScale(.5, .5) }):Play()
		Var.Services.TweenService:Create(Var.MainFrame.UICorner, TweenInfo.new(Speed, Enum.EasingStyle.Quart), { CornerRadius = UDim.new(0,0) }):Play()
		Var.Services.TweenService:Create(
			Var.MainFrame.Header.Mark, 
			TweenInfo.new(Speed, Enum.EasingStyle.Quart), 
			{ 
				Position = UDim2.new(.328, Var.Services.GUIService.TopbarInset.Min.X, 0, 0), 
				Size = UDim2.new(Var.MainFrame.Header.Mark.Size.X.Scale, 0, 0, Var.Services.GUIService.TopbarInset.Height)
			}
		):Play()
	end	
end

function Frontend.Open(
	WaitForCompletion: boolean
): ()
	local AS = Var.AnimationSpeed
	local X = 0.85
	local Y = 0.7
	Var.MainFrame.GroupTransparency = 1

	Var.IsPanelAnimating = true
	Var.MainFrame.Visible = true
	if Var.UseAcrylic then
		require(Libraries.Neon):BindFrame(Var.MainFrame, {
			Transparency = 0.95,
			BrickColor = BrickColor.new("Institutional white")
		})
	end

	local PopupTween

	if not Var.Mobile then
		script.Parent.Parent.Assets.PanelOpen:Play()

		AS *= .55

		Var.MainFrame.Position = UDim2.fromScale(.5, .5)
		Var.MainFrame.Size = UDim2.fromScale(
			Var.MainFrame.Size.X.Scale * .9, 
			Var.MainFrame.Size.Y.Scale * .9
		)

		PopupTween = Var.Services.TweenService:Create(
			Var.MainFrame,
			TweenInfo.new(AS, Enum.EasingStyle.Cubic),
			{ 
				Size = UDim2.fromScale(
					Var.MainFrame.Size.X.Scale * 1.1, 
					Var.MainFrame.Size.Y.Scale * 1.1
				), 
				GroupTransparency = 0 
			}
		)
	else
		Var.MainFrame.Position = UDim2.fromScale(1.5, 0.5)

		Var.Services.TweenService
			:Create(
				Var.MainFrame,
				TweenInfo.new(AS, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, 0, false, AS * 0.2),
				{
					Size = UDim2.fromScale(X, Y)
				}
			)
			:Play()

		PopupTween = Var.Services.TweenService:Create(
			Var.MainFrame,
			TweenInfo.new(AS, Enum.EasingStyle.Cubic),
			{ Position = UDim2.fromScale(0.5, 0.5), GroupTransparency = 0 }
		)
	end

	PopupTween:Play()
	task.delay(AS, function()
		Var.IsPanelAnimating = false
		Var.IsOpen = true
	end)

	if WaitForCompletion then
		task.wait(AS)
	end
end

function Frontend.Close(
	Instant: boolean? | CanvasGroup? | Frame?, 
	WaitForCompletion, 
	Frame: CanvasGroup? | Frame?
): ()
	if typeof(Instant) ~= "boolean" then
		Frame = Instant	
		Instant = false
	end

	if not Frame then
		Frame = Var.MainFrame
	end

	Var.IsPanelAnimating = true

	xpcall(function(...)
		require(Libraries.Neon):UnbindFrame(Var.MainFrame)
	end, function(a0)
		--// We can ignore this, it probably happened bc a skid is spamming the keybind.
		Var.InitErrored = true
	end)

	local Duration = 0
	if not Instant then Duration = Var.AnimationSpeed end

	if not Var.Mobile then
		Duration *= .55

		Var.Services.TweenService:Create(
			Var.MainFrame,
			TweenInfo.new(Duration, Enum.EasingStyle.Cubic),
			{ 
				Size = UDim2.fromScale(
					Var.MainFrame.Size.X.Scale * .9,
					Var.MainFrame.Size.Y.Scale * .9
				), 
				GroupTransparency = 1 
			}
		):Play()
	else
		Var.Services.TweenService:Create(
			Frame,
			TweenInfo.new(Duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{
				Size = UDim2.fromScale(
					Var.MainFrame.Size.X.Scale / 1.5, 
					Var.MainFrame.Size.Y.Scale / 1.5
				),
				Position = UDim2.fromScale(1.5, 0.5),
				GroupTransparency = 1
			}
		):Play()
	end

	task.delay(Duration, function()
		Frame.Visible = false

		if Frame == Var.MainFrame then
			Var.IsPanelAnimating = false
			Var.MainFrame.Visible = false
			Var.IsOpen = false
		end
	end)

	task.defer(function()
		Frontend.ToggleFullscreen(true, Var.MainFrame)
	end)

	if WaitForCompletion then
		task.wait(Duration)
	end
end

local DrawerConnections = {}
local ShouldAnimate = true
local IsQueued = false
local CurrentlyActive
local Ready = true
local Card

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

	TimeToComplete = Var.AnimationSpeed * 2

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

	local function AppOver(AppConfig, ButtonConfig, AppVisible)
		local ShouldBind

		xpcall(function()
			Card = Apps.AppDrawerCover.Card
			ShouldBind = true
		end, function()
			--// It is already open, no need for concern
			Card = Var.MainFrame.Parent.Card
			ShouldBind = AppVisible
		end)

		if AppVisible then
			Card.AppPrimary.Image = AppConfig.Icon
			Card.AppMenu.Image = ButtonConfig.Icon

			Card.Title.Text = AppConfig.AppName
			Card.SubTitle.Text = ButtonConfig.Name
			Card.Desc.Text = AppConfig.Description

			Card.Parent = Var.MainFrame.Parent

			game:GetService("TweenService"):Create(Card, TweenInfo.new(Var.AnimationSpeed * .15), { GroupTransparency = 0 }):Play()

			if ShouldBind then
				DrawerConnections[`CardMovement`] = game:GetService("RunService").RenderStepped:Connect(function(dt)
					if Card.Visible == false then return end

					local Mouse = game:GetService("UserInputService"):GetMouseLocation()
					local Pos = Vector2.new(Mouse.X, Mouse.Y - game:GetService("GuiService"):GetGuiInset().Y)

					game:GetService("TweenService"):Create(Card, TweenInfo.new(Var.AnimationSpeed * .25), { 
						Position = UDim2.fromOffset(Pos.X, Pos.Y)
					}):Play()
				end)
			end
		else
			game:GetService("TweenService"):Create(Card, TweenInfo.new(Var.AnimationSpeed * .15), { GroupTransparency = 1 }):Play()

			DrawerConnections["CardMovement"]:Disconnect()
		end
	end

	for _, Child in Var.MainFrame:GetChildren() do
		if 
			(Child:IsA("Frame") or Child:IsA("CanvasGroup")) 
			and Child.Name == Var.ActivePage.Name 
			or Child.Name == "Header"
			or Child:FindFirstChild(Var.ActivePage.Name)
		then
			Child.Parent = Container 

			if Child.Name == Var.ActivePage.Name then
				CurrentlyActive = Child
			end
		end
	end

	Var.Services.TweenService
		:Create(Container, TweenInfo.new(TimeToComplete, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, 0, false), {
			GroupTransparency = 0,
			BackgroundTransparency = 0.25,
			Size = UDim2.new(0.95, 0, 0.95, 0),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5)
		})
		:Play()

	Var.Services.TweenService
		:Create(Apps, TweenInfo.new(TimeToComplete * 0.3, Enum.EasingStyle.Quart), {
			Position = UDim2.new(0, 0, 0, 0)
		})
		:Play()

	Var.Services.TweenService
		:Create(Apps.AppHolder, TweenInfo.new(TimeToComplete * 0.55, Enum.EasingStyle.Quart), {
			GroupTransparency = 0,
			Position = UDim2.new(0, 0, 0, 0)
		})
		:Play()

	for _, Button in Apps.AppHolder:GetDescendants() do
		if Button.Name ~= "Activator" or Button:FindFirstAncestor("MultiThread") or Button:FindFirstAncestor("SingleThread") then continue end

		DrawerConnections[`Over-{math.random(1,10000)}`] = Button.MouseEnter:Connect(function()

			--// Recursively find the frame bc idk!!
			for _, Object in Var.CombinedButtonConfig do
				for _, SubIcon in Object.SubIcons do
					if SubIcon.Icon ~= Button.Parent.Icon.Image then continue end

					task.defer(function() 
						AppOver(Object, SubIcon, true)
					end)
				end
			end
		end)

		DrawerConnections[`Over-{math.random(1,10000)}`] = Button.MouseLeave:Connect(function()
			--// Same dumb logic as above
			for _, Object in Var.CombinedButtonConfig do
				for _, SubIcon in Object.SubIcons do
					if SubIcon.Icon ~= Button.Parent.Icon.Image then continue end

					task.defer(function() 
						AppOver(Object, SubIcon, false)
					end)
				end
			end
		end)
	end
end

function Frontend.Drawer.Close(): ()
	local Apps = Var.MainFrame.AppDrawer
	local Container = Apps.AppDrawerCover.CanvasGroup
	local TimeToComplete = Var.AnimationSpeed

	ShouldAnimate = false

	Container.Parent.Parent = Var.MainFrame
	Container.Parent.Size = UDim2.new(.75,0,1,0)
	Container.Parent.Position = UDim2.new(.25,0,0,0)

	Var.Services.TweenService
		:Create(Apps, TweenInfo.new(TimeToComplete * 0.75, Enum.EasingStyle.Quart), {
			Position = UDim2.new(0, 0, 1, 0)
		})
		:Play()

	Var.Services.TweenService
		:Create(Apps.AppHolder, TweenInfo.new(TimeToComplete * 0.55, Enum.EasingStyle.Quart), {
			Position = UDim2.new(0, 0, .75, 0),
			GroupTransparency = 1
		})
		:Play()

	Var.Services.TweenService
		:Create(Container.Parent, TweenInfo.new(TimeToComplete * 0, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, 0, false), {
			Position = UDim2.new(0.5,0,0.5,0),
			Size = UDim2.new(1,0,1,0),

			AnchorPoint = Vector2.new(.5, .5),
			BackgroundTransparency = 1
		})
		:Play()

	pcall(function()
		Var.Services.TweenService:Create(Card, TweenInfo.new(TimeToComplete * .15), { GroupTransparency = 1 })
			:Play()

		DrawerConnections["CardMovement"]:Disconnect()
	end)

	--task.wait(TimeToComplete * .6)

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

	for _, Connection in DrawerConnections do
		Connection:Disconnect()
	end

	Var.DoHeaderEffects = true
	Ready = true
end

function Frontend.Drawer.HoverBegin()
	if not Var.DoHeaderEffects then return end

	local MarkBox = Var.MainFrame.Header.Mark.AppLogo
	local QuickTI = TweenInfo.new(Var.AnimationSpeed * .25, Enum.EasingStyle.Quart)

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
	local QuickTI = TweenInfo.new(Var.AnimationSpeed * .25, Enum.EasingStyle.Quart)

	Var.Services.TweenService:Create(MarkBox.GridIcon, QuickTI, {
		Size = UDim2.new(0,0,0,0)
	}):Play()

	Var.Services.TweenService:Create(MarkBox.AppIcon, QuickTI, {
		Size = UDim2.new(1,0,1,0),
		ImageTransparency = 0
	}):Play()
end

function Frontend.Toast(Config: {
	Text: string,
	Subtext: string,
	Icon: string,
	Timeout: number,

	OnClick: () -> ()?
	})
	local Toast = Var.MainFrame.administer.Toast
	local Close = nil

	Toast.Size = UDim2.fromScale(0.4, 0.74)
	Toast.Position = UDim2.fromScale(.5, 1.1)
	Toast.Timer.Size = UDim2.fromScale(1, 1)

	Toast.HeaderLabel.Text = Config.Text
	Toast.MainText.Text = Config.Subtext
	Toast.Icon.Image = Config.Icon

	Toast.Visible = true

	Var.Services.TweenService:Create(Toast, TweenInfo.new(Var.AnimationSpeed * .6, Enum.EasingStyle.Quart), {
		Position = UDim2.fromScale(.5, .879),
		Size = UDim2.fromScale(0.443, 0.094)
	}):Play()

	local Timer = Var.Services.TweenService:Create(Toast.Timer, TweenInfo.new(Config.Timeout), {
		Size = UDim2.fromScale(0,1)
	})

	Timer:Play()
	script.Parent.Parent.Assets.ToastSound:Play()

	local ClickEvent = Toast.Click.MouseButton1Click:Connect(function()
		Close()

		xpcall(Config.OnClick(), Utilities.Logging.Print)
	end)

	Close = function()
		local C = Var.Services.TweenService:Create(Toast, TweenInfo.new(Var.AnimationSpeed * .6, Enum.EasingStyle.Quart), {
			Position = UDim2.fromScale(.5, 1.1),
			Size = UDim2.fromScale(0.4, .74)
		})

		C:Play()
		ClickEvent:Disconnect()


		C.Completed:Wait()
		Toast.Visible = false
	end

	Timer.Completed:Connect(Close)

	return Close
end

function Frontend.Popup.Open(): ()
	local BGTweenInfo = TweenInfo.new(Var.AnimationSpeed * .65, Enum.EasingStyle.Cubic)

	Frontend.Popup.OriginalStates = {}

	local descendant = Var.ActivePage
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

	local Popup = Var.MainFrame.administer.MessageBox

	local PopupOriginalSize = Popup.Size
	local SizeStr = string.split(tostring(Popup.Size), ",")
	local X = tonumber(string.split(string.gsub(SizeStr[1], "{", ""), " ")[1])
	local Y = tonumber(string.split(string.gsub(SizeStr[3], "{", ""), " ")[2])

	Popup.Size = UDim2.fromScale(X / 1.5, Y / 1.5)
	Popup.Position = UDim2.fromScale(0.5, 1.25)
	Popup.GroupTransparency = 0.5
	Popup.Visible = true

	local PopupTween = Var.Services.TweenService:Create(Popup, TweenInfo.new(Var.AnimationSpeed, Enum.EasingStyle.Cubic), {
		Position = UDim2.fromScale(0.5, 0.5),
		GroupTransparency = 0
	})

	PopupTween:Play()
	Utilities.Logging.Print("Popup animation complete")

	Var.Services.TweenService:Create(Popup, TweenInfo.new(Var.AnimationSpeed * 0.85, Enum.EasingStyle.Cubic), {
		Size = PopupOriginalSize
	}):Play()

	Var.PopupOpen = true
end

function Frontend.Popup.Close(): ()
	local BGTweenInfo = TweenInfo.new(Var.AnimationSpeed * .65, Enum.EasingStyle.Cubic)

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

	local Box = Var.MainFrame.administer.MessageBox
	local PopupOriginalSize = Box.Size
	local SizeStr = string.split(tostring(Box.Size), ",")
	local X = tonumber(string.split(string.gsub(SizeStr[1], "{", ""), " ")[1])
	local Y = tonumber(string.split(string.gsub(SizeStr[3], "{", ""), " ")[2])

	local PopupTween = Var.Services.TweenService:Create(Box, TweenInfo.new(Var.AnimationSpeed * .85, Enum.EasingStyle.Cubic), {
		Size = UDim2.new(X * 0.35, 0, Y * 0.35, 0),
		GroupTransparency = 1
	})

	PopupTween:Play()
	PopupTween.Completed:Wait()

	Box.Size = PopupOriginalSize
	Box.Visible = false
	Var.PopupOpen = false
end

local MessageBox = Var.MainFrame.administer.MessageBox
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
			Text: string,
			Icon: string,
			Callback: (Close: () -> (), TextInputChoices: { string? }) -> () 
		}
	},

	TextInputs: {
		{
			HeaderText: string
		}
	}

): ()
	if Options ~= nil and #Options > 2 then 
		Utilities.Logging.Warn("Popups may not have more than two buttons")

		return {false, "Popups may not have more than two buttons"}
	end

	if TextInputs ~= nil and #TextInputs > 2 then 
		Utilities.Logging.Warn("Popups may not have more than two text inputs.")

		return {false, "Popups may not have more than two text inputs."}
	end

	if Var.PopupOpen then
		Utilities.Logging.Warn("A popup is already open and must be closed before a new one is opened.")

		return {false, "Only one popup may be open at a time."}
	end

	--// Cleanup
	for _, Signal in PopupButtons do
		Signal:Disconnect()
	end

	for Num = 1, 2 do
		local Input = MessageBox.TextInputs[Num].Box

		Input.Text = ""
		Input.ClearTextOnFocus = false
	end

	local ClosePopup = Frontend.Popup.Close

	MessageBox.Header.HeaderLabel.Text = `<b>{App.Name}</b>\n{App.Subheader ~= nil and App.Subheader or Header}`
	MessageBox.Header.AppIcon.Image = App.Icon

	MessageBox.PrimaryText.Text = Header
	MessageBox.SubText.Text = BodyText

	MessageBox.AppLogo.LogoImage.Image = Icons.Primary or App.Icon
	MessageBox.SubIcon.Image = Icons.SubIcon and Icons.SubIcon or ""

	MessageBox.AppLogo.LogoImage.Position = not Icons.SubIcon and UDim2.fromScale(0.5, 0.5) or UDim2.fromScale(0.047, 0.149)
	MessageBox.AppLogo.LogoImage.AnchorPoint = not Icons.SubIcon and Vector2.new(0.5, 0.5) or Vector2.new(0,0)

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

function Frontend.SwapAppBasic(
	NewFrame: Frame | CanvasGroup, 
	NewConfig: { Name: string, Icon: string }
)
	if NewFrame.Name == Var.ActivePage.Name then
		return
	end

	local OGFramePos, OGFrameAP, NewFramePos, NewFrameAP = Var.ActivePage.Position, Var.ActivePage.AnchorPoint, NewFrame.Position, NewFrame.AnchorPoint
	local TInfo = TweenInfo.new(Var.AnimationSpeed * .75, Enum.EasingStyle.Quart)

	NewFrame.Visible = true

	NewFrame.Position = UDim2.new(1,0,.5,0)
	NewFrame.AnchorPoint = Vector2.new(.5,0)

	local x = Var.Services.TweenService:Create(NewFrame, TInfo, { Position = NewFramePos, AnchorPoint = NewFrameAP })
	Var.Services.TweenService:Create(Var.ActivePage, TInfo, { Position = UDim2.new(-1, 0, .5, 0), AnchorPoint = Vector2.new(.5,0) }):Play()

	x:Play()
	x.Completed:Wait()

	Var.ActivePage.Position = OGFramePos
	Var.ActivePage.AnchorPoint = OGFrameAP
	Var.ActivePage.Visible = false

	Var.ActivePage = NewFrame

	repeat task.wait() until Var.MainFrame:FindFirstChild("Header")

	pcall(function()
		--Var.MainFrame.Header.Mark.HeaderLabel.Text = `<b>Administer</b> · {NewConfig.Name}`
		Var.MainFrame.Header.Mark.HeaderTitle.Text = "<b>Administer</b>"
		Var.MainFrame.Header.Mark.HeaderSubapp.Text = NewConfig.Name
		Var.MainFrame.Header.Mark.AppLogo.AppIcon.Image = NewConfig.Icon
		Var.MainFrame.Header.Mark.Logo.Image = Utilities.Icon "administer"

		Var.Services.TweenService:Create(NewFrame, TInfo, { Position = NewFramePos, AnchorPoint = NewFrameAP}):Play()
	end)
end

function Frontend.SwapApps(AppConfig: Types.ButtonConfig, Clicked: number)
	local NewFrame

	Ready = true

	if typeof(AppConfig) == "Instance" then
		NewFrame = AppConfig
	elseif Clicked == 0 then
		NewFrame = AppConfig.MainButtonFrame
	else
		NewFrame = AppConfig.SubIcons[Clicked].Frame
	end

	if NewFrame.Name == Var.ActivePage.Name then --// Stop them from breaking it
		return
	end

	local OGFramePos, OGFrameAP, NewFramePos, NewFrameAP = Var.ActivePage.Position, Var.ActivePage.AnchorPoint, NewFrame.Position, NewFrame.AnchorPoint
	local TInfo = TweenInfo.new(Var.AnimationSpeed * .75, Enum.EasingStyle.Quart)

	NewFrame.Visible = true

	NewFrame.Position = UDim2.new(1,0,.5,0)
	NewFrame.AnchorPoint = Vector2.new(.5,0)

	local x = Var.Services.TweenService:Create(NewFrame, TInfo, { Position = NewFramePos, AnchorPoint = NewFrameAP })
	Var.Services.TweenService:Create(Var.ActivePage, TInfo, { Position = UDim2.new(-1, 0, .5, 0), AnchorPoint = Vector2.new(.5,0) }):Play()

	x:Play()
	x.Completed:Wait()

	Var.ActivePage.Position = OGFramePos
	Var.ActivePage.AnchorPoint = OGFrameAP
	Var.ActivePage.Visible = false

	Var.ActivePage = NewFrame

	repeat task.wait() until Var.MainFrame:FindFirstChild("Header") --// close animation 

	xpcall(function()
		Var.MainFrame.Header.Mark.HeaderTitle.Text = Clicked ~= 0 and AppConfig.AppName or "Administer"
		Var.MainFrame.Header.Mark.HeaderSubapp.Text = Clicked == 0 and AppConfig.AppName or AppConfig.SubIcons[Clicked].Name
		Var.MainFrame.Header.Mark.AppLogo.AppIcon.Image = AppConfig.Icon
		Var.MainFrame.Header.Mark.Logo.Image = Clicked == 0 and Utilities.Icon "administer" or AppConfig.SubIcons[Clicked].Icon

		Var.Services.TweenService:Create(NewFrame, TInfo, { Position = NewFramePos, AnchorPoint = NewFrameAP}):Play()
	end, function()
		--// just dont change it lmao
	end)
end

function Frontend.InitGestureBar()
	Utilities.Logging.Warn("attempt to use deprecated method (Frontend.InitGestureBar)")
	return { false, "This method is deprecated" }
end

local MinX, MinY = -350, -300
local MaxX, MaxY = workspace.Camera.ViewportSize.X, workspace.Camera.ViewportSize.Y
local OverlayConnections: { [string]: RBXScriptConnection } = {}

function Frontend.SpawnOverlay(
	Frame: Frame | CanvasGroup
)
	local Speed = Var.AnimationSpeed
	local ButtonsOpen = false
	local MovementConnection: RBXScriptConnection

	--// Spawn new overlay
	local OverlayClone = Var.AdministerRoot.AdmOverlays.Template:Clone()

	OverlayClone.Parent = Var.AdministerRoot.AdmOverlays
	OverlayClone.Name = `{Frame.Name}_Overlay`

	Frame:GetPropertyChangedSignal("Size"):Connect(function()
		OverlayClone.Size = Frame.Size
	end)

	Frame:GetPropertyChangedSignal("Position"):Connect(function()
		OverlayClone.Position = Frame.Position
	end)

	Frame:GetPropertyChangedSignal("AnchorPoint"):Connect(function()
		OverlayClone.AnchorPoint = Frame.AnchorPoint
	end)

	Frame:GetPropertyChangedSignal("BackgroundTransparency"):Connect(function()
		OverlayClone.Grabber.BackgroundTransparency = Frame.BackgroundTransparency
	end)

	--// ?
	Frame:GetPropertyChangedSignal("GroupTransparency"):Connect(function()
		OverlayClone.Grabber.BackgroundTransparency = Frame.GroupTransparency
		OverlayClone.Visible = OverlayClone.Grabber.BackgroundTransparency ~= 1
	end)

	if Frame:FindFirstChild("UISizeConstraint") then
		local SizeConstraint = Frame:FindFirstChild("UISizeConstraint"):Clone()

		SizeConstraint.Parent = OverlayClone
	end

	OverlayClone.AnchorPoint = Frame.AnchorPoint
	OverlayClone.Position = Frame.Position
	OverlayClone.Size = Frame.Size

	Var.Services.TweenService:Create(OverlayClone.Grabber, TweenInfo.new(Var.AnimationSpeed * .3), {
		BackgroundTransparency = (Frame.GroupTransparency ~= nil and Frame.GroupTransparency or Frame.BackgroundTransparency)
	}):Play()

	task.delay(Var.AnimationSpeed * .3, function()
		OverlayClone.Visible = false
	end)

	OverlayClone.Visible = true

	--// Gripper
	local function HideButtons()
		local Controls = OverlayClone.Grabber.Controls

		ButtonsOpen = false

		Var.Services.TweenService:Create(OverlayClone.Grabber, TweenInfo.new(Speed * .5, Enum.EasingStyle.Quart), {
			Position = UDim2.fromScale(.5, 1.02),
			Size = UDim2.fromOffset(150, 6)
		}):Play()

		Var.Services.TweenService:Create(Controls, TweenInfo.new(Speed * .5, Enum.EasingStyle.Quart), {
			GroupTransparency = 1,
			Size = UDim2.fromScale(.704, 2.5),
			Position = UDim2.fromScale(0, 0)
		}):Play()
	end

	local function ShowButtons()
		local Controls = OverlayClone.Grabber.Controls

		if ButtonsOpen then return end
		if OverlayClone.Visible == false then 
			return 
		end

		ButtonsOpen = true

		Var.Services.TweenService:Create(OverlayClone.Grabber, TweenInfo.new(Speed * .5, Enum.EasingStyle.Quart), {
			Position = UDim2.fromScale(.55, 1.02),
			Size = UDim2.fromOffset(105, 6)
		}):Play()

		Controls.Visible = true
		Controls.GroupTransparency = 1
		Controls.Size = UDim2.fromScale(.704, 2.5)
		Controls.Position = UDim2.fromScale(0, 0)

		Var.Services.TweenService:Create(Controls, TweenInfo.new(Speed * .5, Enum.EasingStyle.Quart), {
			GroupTransparency = 0,
			Size = UDim2.fromScale(.704, 3.5),
			Position = UDim2.fromScale(-.85, .5)
		}):Play()
	end

	local LeftOver = OverlayClone.GrabberLeft.MouseEnter:Connect(ShowButtons)
	local LeftLeave = OverlayClone.GrabberLeft.MouseLeave:Connect(function()
		task.delay(3, HideButtons)
	end)

	local Grabber = OverlayClone.Grabber.RealGrabber
	local GrabMove, InputEnded: RBXScriptSignal

	Grabber.MouseEnter:Connect(function()
		if ButtonsOpen then return end

		Var.Services.TweenService:Create(OverlayClone.Grabber, TweenInfo.new(Speed * .5, Enum.EasingStyle.Quart), {
			Size = UDim2.fromOffset(165, 15),
			BackgroundColor3 = Color3.fromRGB(185, 185, 185)
		}):Play()
	end)

	Grabber.MouseLeave:Connect(function()
		Var.Services.TweenService:Create(OverlayClone.Grabber, TweenInfo.new(Speed * .5, Enum.EasingStyle.Quart), {
			Size = UDim2.fromOffset(150, 6),
			BackgroundColor3 = Color3.new(1,1,1)
		}):Play()
	end)

	Grabber.InputBegan:Connect(function(Input)
		if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		local StartPos, StartPanelPos = Input.Position, Var.MainFrame.Position

		GrabMove = Var.Services.UserInputService.InputChanged:Connect(function(MoveInput)
			if MoveInput.UserInputType == Enum.UserInputType.MouseMovement then
				local Delta = MoveInput.Position - StartPos

				Var.Services.TweenService:Create(Frame, TweenInfo.new(Var.AnimationSpeed * .2, Enum.EasingStyle.Quart), {
					Position = UDim2.new(StartPanelPos.X.Scale, StartPanelPos.X.Offset + Delta.X, StartPanelPos.Y.Scale, StartPanelPos.Y.Offset + Delta.Y)
				}):Play()
			end
		end)
	end)

	Grabber.InputEnded:Connect(function()
		repeat 
			task.wait() 
		until not Var.Services.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)

		if GrabMove then GrabMove:Disconnect() end

		Var.Services.TweenService:Create(OverlayClone.Grabber, TweenInfo.new(Speed * .5, Enum.EasingStyle.Quart), {
			Size = UDim2.fromOffset(150, 6),
			BackgroundColor3 = Color3.new(1,1,1)
		}):Play()
	end)

	--// Corner grabber
	local function GripAnimation(
		Type: "Release" | "Grip" | "Hover",
		Axis: "X" | "Y" | "XY"
	)
		if Type == "Release" then
			Var.Services.TweenService:Create(
				OverlayClone.CornerGripper.Grabber,
				TweenInfo.new(Speed * .5, Enum.EasingStyle.Quart), {
					Size = UDim2.fromOffset(50, 50)
				}
			):Play()

			if MovementConnection then
				repeat 
					task.wait() 
				until not Var.Services.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)

				MovementConnection:Disconnect()
			end
		elseif Type == "Grip" then
			Var.Services.TweenService:Create(
				OverlayClone.CornerGripper.Grabber,
				TweenInfo.new(Speed * .5, Enum.EasingStyle.Quart), 
				{
					Size = UDim2.fromOffset(
						Axis == "X" and 75 or Axis == "XY" and 60 or 45, 
						Axis == "Y" and 75 or Axis == "XY" and 60 or 45
					)
				}
			):Play()
		elseif Type == "Hover" then
			Var.Services.TweenService:Create(
				OverlayClone.CornerGripper.Grabber,
				TweenInfo.new(Speed * .5, Enum.EasingStyle.Quart), {
					Size = UDim2.fromOffset(
						Axis == "X" and 70 or Axis == "XY" and 60 or 45, 
						Axis == "Y" and 70 or Axis == "XY" and 60 or 45
					)
				}
			):Play()
		end
	end

	local RecentClick = false
	local function DoResize(Input, Axis)
		if MovementConnection then MovementConnection:Disconnect() end
		if InputEnded then InputEnded:Disconnect() end

		local StartPos = Var.Services.UserInputService:GetMouseLocation()
		local StartSize = Frame.Size

		if RecentClick then
			Frontend.Open(true)

			return
		else
			RecentClick = true
			task.delay(.2, function()
				RecentClick = false
			end)
		end

		MovementConnection = Var.Services.UserInputService.InputChanged:Connect(function(MoveInput)
			local Size

			if MoveInput.UserInputType == Enum.UserInputType.MouseMovement then
				local MousePos = Var.Services.UserInputService:GetMouseLocation()
				local Delta = MousePos - StartPos

				local NewX = StartSize.X.Offset + Delta.X * 1.5
				local NewY = StartSize.Y.Offset + Delta.Y * 1.5

				if Axis == "X" then
					Size = UDim2.new(StartSize.X.Scale, NewX, StartSize.Y.Scale, StartSize.Y.Offset)
				elseif Axis == "Y" then
					Size = UDim2.new(StartSize.X.Scale, StartSize.X.Offset, StartSize.Y.Scale, NewY)
				elseif Axis == "XY" then
					Size = UDim2.new(StartSize.X.Scale, NewX, StartSize.Y.Scale, NewY)
				end

				Var.Services.TweenService:Create(Frame, TweenInfo.new(Var.AnimationSpeed * .2, Enum.EasingStyle.Quart), {
					Size = Size
				}):Play()
			end
		end)

		InputEnded = Var.Services.UserInputService.InputEnded:Connect(function(EndInput)
			warn(EndInput)
			if EndInput.UserInputType == Enum.UserInputType.MouseButton1 then
				if MovementConnection then 
					MovementConnection:Disconnect()

					repeat 
						task.wait() 
					until not Var.Services.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
				end
				if InputEnded then InputEnded:Disconnect() end
				GripAnimation("Release", Axis)
			end
		end)
	end

	local function ToggleGripperVisibility(ForceState)
		local Opacity = Utilities.GetSetting("GripperIdleOpacity")
		local Idle = 
			Opacity == "visible" and 0 or
			Opacity == "faint" and 0.5 or
			1

		Var.Services.TweenService:Create(
			OverlayClone.CornerGripper.Grabber,
			TweenInfo.new(
				Speed * 0.3,
				Enum.EasingStyle.Quart,
				Enum.EasingDirection.In,
				0,
				false,
				ForceState == false and 2 or 0
			),
			{ ImageTransparency = ForceState and 0 or Idle }
		):Play()
	end

	ToggleGripperVisibility()

	OverlayClone.CornerGripper.Trigger.MouseEnter:Connect(function()
		ToggleGripperVisibility(true)
		GripAnimation("Hover", "XY")
	end)

	OverlayClone.CornerGripper.Trigger.MouseLeave:Connect(function()
		ToggleGripperVisibility(false)
		GripAnimation("Release", "XY")
	end)

	OverlayClone.CornerGripper.Trigger.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			GripAnimation("Grip", "XY")
			DoResize(Input, "XY")
		end
	end)

	OverlayClone.CornerGripper.TriggerHoriz.MouseEnter:Connect(function()
		ToggleGripperVisibility(true)
		GripAnimation("Hover", "X")
	end)

	OverlayClone.CornerGripper.TriggerHoriz.MouseLeave:Connect(function()
		ToggleGripperVisibility(false)
		GripAnimation("Release", "X")
	end)

	OverlayClone.CornerGripper.TriggerHoriz.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			GripAnimation("Grip", "X")
			DoResize(Input, "X")
		end
	end)

	OverlayClone.CornerGripper.TriggerVert.MouseEnter:Connect(function()
		ToggleGripperVisibility(true)
		GripAnimation("Hover", "Y")
	end)

	OverlayClone.CornerGripper.TriggerVert.MouseLeave:Connect(function()
		ToggleGripperVisibility(false)
		GripAnimation("Release", "Y")
	end)

	OverlayClone.CornerGripper.TriggerVert.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			GripAnimation("Grip", "Y")
			DoResize(Input, "Y")
		end
	end)

	--// Connections
	OverlayConnections[Frame.Name] = {}

	for _, Conn in ({
		Close = OverlayClone.Grabber.Controls.Close.MouseButton1Click:Connect(function()
			Frontend.Close(Frame)
		end),

		Expand = OverlayClone.Grabber.Controls.Expand.MouseButton1Click:Connect(function()
			Frontend.ToggleFullscreen(false, Frame)
		end),

		ExpandFixGripper = Frame:GetAttributeChangedSignal("IsFullScreen"):Connect(function()
			local IsFullScreen = Frame:GetAttribute("IsFullScreen")
			Var.Services.TweenService:Create(OverlayClone.CornerGripper.Grabber, TweenInfo.new(Var.AnimationSpeed * .3), {
				ImageTransparency = IsFullScreen and 1 or 0
			}):Play()

			OverlayClone.CornerGripper.TriggerVert.Visible = not IsFullScreen
			OverlayClone.CornerGripper.TriggerHoriz.Visible = not IsFullScreen
			OverlayClone.CornerGripper.Trigger.Visible = not IsFullScreen

			if IsFullScreen then
				local Trigger = Instance.new("TextButton")

				Trigger.Parent = Frame
				--Trigger.BackgroundTransparency = 1
				Trigger.Text = ""

				Trigger.Size = UDim2.fromOffset(150, 15)

				Trigger.AnchorPoint = Vector2.new(0.5, 1)
				Trigger.Position = UDim2.new(0.5, 0, 1, -10)
			end
		end),

		Shrink = OverlayClone.Grabber.Controls.Minimize.MouseButton1Click:Connect(function()
			print("shrink TODO")
		end)}) 
	do
		table.insert(OverlayConnections[Frame.Name], Conn)
	end
end

function Frontend.RegisterPanelKeybind()
	local currentKeys, Debounce = {}, false

	local targetSettings = {
		"PanelKeybind",
		"PanelFullscreenKeybind",
		"AppDrawerKeybind"
	}
	local keybinds = Utilities.GetSettings(targetSettings)

	local openKeybind = keybinds["PanelKeybind"]
	local openChanged = Utilities.GetSettingChanged("PanelKeybind")

	local ExpandKeybind = keybinds["PanelFullscreenKeybind"]
	local expandChanged = Utilities.GetSettingChanged("PanelFullscreenKeybind")

	local DrawerKeybind = keybinds["AppDrawerKeybind"]
	local DrawerChanged = Utilities.GetSettingChanged("AppDrawerKeybind")

	local loadedSettings: RemoteEvent = Var.Remotes:FindFirstChild("SettingsLoaded")

	loadedSettings.OnClientEvent:Connect(function()
		keybinds = Utilities.GetSettings(targetSettings)

		openKeybind = keybinds["PanelKeybind"]
		ExpandKeybind = keybinds["PanelFullscreenKeybind"]
		DrawerKeybind = keybinds["AppDrawerKeybind"]
	end)

	openChanged.OnClientEvent:Connect(function(newValue)
		openKeybind = newValue
	end)

	expandChanged.OnClientEvent:Connect(function(newValue)
		ExpandKeybind = newValue
	end)

	DrawerChanged.OnClientEvent:Connect(function(newValue)
		DrawerKeybind = newValue
	end)

	Var.Services.UserInputService.InputBegan:Connect(function(KeyCode, IsGameProc)
		if IsGameProc then return end

		if KeyCode.KeyCode == Enum.KeyCode.Unknown then return end

		table.insert(currentKeys, KeyCode.KeyCode)
	end)

	Var.Services.UserInputService.InputEnded:Connect(function(KeyCode, IsGameProc)
		if IsGameProc then return end

		if KeyCode.KeyCode == currentKeys[1] then
			local commaSeparated = {}

			for i, v in currentKeys do
				table.insert(commaSeparated, v.Name)
			end


			commaSeparated = table.concat(commaSeparated, ",")
			currentKeys = {}

			if commaSeparated == ExpandKeybind then 
				if Debounce then return end
				Debounce = true

				if not Var.IsOpen then
					Frontend.Open(true)
				end

				Frontend.ToggleFullscreen(false, Var.MainFrame)

				Debounce = false
			elseif commaSeparated == openKeybind then
				if Debounce then return end
				Debounce = true

				if Var.IsOpen then
					Frontend.Close(false, true)
				else
					Frontend.Open(true)
				end

				Debounce = false
			elseif commaSeparated == DrawerKeybind then
				Frontend.Drawer.Open()
			end
		end
	end)
end

function Frontend.AddButtonAnimation(Button: TextButton | ImageButton)
	local Tween = TweenInfo.new(Var.AnimationSpeed * .3, Enum.EasingStyle.Quart)
	local BGChanged

	local UICorner = Button:FindFirstChildWhichIsA("UICorner") or Instance.new("UICorner")
	local OriginalCorner = UICorner.CornerRadius
	local OriginalColor = Button.BackgroundColor3

	Button.AutoButtonColor = false

	--Button.HoverHapticEffect = script.Parent.Parent.Assets.HoverHaptic

	UICorner.Parent = Button

	local function Lighten(color, amount)
		local h, s, v = color:ToHSV()

		v = math.clamp(v + amount, 0, 1)

		return Color3.fromHSV(h, s, v)
	end

	Button.MouseEnter:Connect(function()
		local NewBorder = Instance.new("UIStroke")

		NewBorder.Color = Button.BackgroundColor3
		NewBorder.Transparency = Button.BackgroundTransparency
		NewBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		NewBorder.Thickness = 0

		NewBorder.Name = "ButtonAnimBorder"
		NewBorder.Parent = Button

		BGChanged = Button:GetPropertyChangedSignal("BackgroundColor3"):Connect(function()
			NewBorder.Color = Button.BackgroundColor3
		end)

		Var.Services.TweenService:Create(UICorner, Tween, {
			CornerRadius = OriginalCorner + UDim.new(0, 4)
		}):Play()

		Var.Services.TweenService:Create(Button.ButtonAnimBorder, Tween, {
			Thickness = 3
		}):Play()

		Var.Services.TweenService:Create(Button, Tween, {
			BackgroundColor3 = Lighten(Button.BackgroundColor3, 0.2)
		}):Play()

		script.Parent.Parent.Assets.SelectSound:Play()
	end)

	Button.MouseLeave:Connect(function()
		if Button:FindFirstChild("ButtonAnimBorder") then
			task.defer(function()
				BGChanged:Disconnect()

				local BorderGone = Var.Services.TweenService:Create(Button.ButtonAnimBorder, Tween, {
					Thickness = 0
				})

				BorderGone:Play()
				BorderGone.Completed:Wait()

				Button.ButtonAnimBorder:Destroy()
			end)
		end

		Var.Services.TweenService:Create(Button, Tween, {
			BackgroundColor3 = OriginalColor
		}):Play()

		Var.Services.TweenService:Create(UICorner, Tween, {
			CornerRadius = OriginalCorner
		}):Play()
	end)

	Button.MouseButton1Click:Connect(function()
		script.Parent.Parent.Assets.ClickSound:Play()
		script.Parent.Parent.Assets.ClickHaptic:Play()

		Ripple(Button, game.Players.LocalPlayer:GetMouse(), Var.AnimationSpeed * .4, Color3.fromRGB(255,255,255))
	end)

	Button.MouseButton2Click:Connect(function()
		script.Parent.Parent.Assets.ClickSound:Play()

		Ripple(Button, game.Players.LocalPlayer:GetMouse(), Var.AnimationSpeed * .4, Color3.fromRGB(255,255,255))
	end)
end


function Frontend.PrepTheme()
	local Dark = require(script.Parent.Parent.Assets.Themes.DefaultDark)

	local ForceSimilarity = Utilities.GetSetting("ThemeForceSimilarity") == true
	local Debug = Utilities.GetSetting("ThemeDebug") == true
	local Threshold = Utilities.GetSetting("ThemeSimilarityThreshold") or 12


	--// Helpers
	local function ColorDistance(a, b)
		if not a or not b then return math.huge end
		local DistanceRed = (a.R - b.R) * 255
		local DistanceGreen = (a.G - b.G) * 255
		local DistanceBlue = (a.B - b.B) * 255

		return math.sqrt(DistanceRed*DistanceRed + DistanceGreen*DistanceGreen + DistanceBlue * DistanceBlue)
	end

	local function FindClosestInGroup(Color, Group, GroupName)
		local BestName, BestColor, BestDistance = nil, nil, math.huge

		for ColorName, Data in pairs(Group or {}) do
			local cand = (type(Data) == "table" and Data.Color) or (typeof(Data) == "Color3" and Data)
			if not cand then continue end

			local success, _ = xpcall(function()
				local d = ColorDistance(Color, cand)

				if d < BestDistance then
					BestName = (GroupName and (GroupName .. "." .. tostring(ColorName))) or tostring(ColorName)
					BestColor = cand
					BestDistance = d
				end
			end, Utilities.Logging.Warn)
		end

		return BestName, BestColor, BestDistance
	end

	local function FindClosestAcrossPriority(Color, Groups)
		if not Color then return nil, nil, math.huge end
		local Name, BestColor, Distance = nil, nil, math.huge

		for _, g in Groups do
			local n, c, d = FindClosestInGroup(Color, g.tbl, g.Name)

			if c and d < Distance then
				Name, BestColor, Distance = n, c, d
			end
		end

		return Name, BestColor, Distance
	end

	local function DebugLabel(Descendant, ColorName)
		if Debug then 
			local NewTL = Instance.new("TextLabel")

			NewTL.Size = UDim2.fromScale(1,1) 
			NewTL.Parent = Descendant 
			NewTL.BackgroundTransparency = .25 
			NewTL.Text = ColorName 
		end
	end

	local IconIndex = {}
	for Name, Icon in Var.Icons do
		if Name == "administer" then continue end

		IconIndex[Icon] = Icon
	end

	local function Process(Descendant: GuiObject)
		if Descendant:GetAttribute("_AdmStyleText") or Descendant:GetAttribute("_AdmStyleBackground") then return end

		--// Text
		if Descendant:IsA("TextLabel") or Descendant:IsA("TextButton") or Descendant:IsA("TextBox") then
			local Found = false

			for ColorName, Data in Dark.Colors.Text do
				local cand = (type(Data) == "table" and Data.Color) or (typeof(Data) == "Color3" and Data)

				if cand and Descendant.TextColor3 == cand then
					Found = ColorName

					break
				end
			end

			if not Found and ForceSimilarity then
				local ColorName, Color, Distance = FindClosestInGroup(Descendant.TextColor3, Dark.Colors.Text, "Text")

				if Color and Distance <= (Threshold * 2) then --// dumb hack
					Descendant.TextColor3 = Color
					Found = ColorName
				else
					--print(`{Descendant:GetFullName()} not styled; {Distance} too far from {Threshold * 2}`)
				end
			end

			DebugLabel(Descendant, Found or "NoMatch")

			if Found then 
				Descendant:SetAttribute("_AdmStyleText", Found)
			end
		end

		--// Images / Icons
		if Descendant:IsA("ImageLabel") or Descendant:IsA("ImageButton") then
			--// force icons individually 
			if IconIndex[Descendant.Image:match("%d+$")] then
				Descendant.ImageColor3 = Dark.Colors.Text.Primary.Color

				Descendant:SetAttribute("_AdmStyleText", "Primary")
				Descendant:SetAttribute("_AdmIsIcon", true)

				return
			else
				Descendant:SetAttribute("_AdmIsIcon", false)
			end

			if ForceSimilarity then
				local Name, DataType, Distance = FindClosestAcrossPriority(Descendant.ImageColor3, {
					{ Name = "Text", tbl = Dark.Colors.Text },
					{ Name = "Colors", tbl = Dark.Colors.Colors },
					{ Name = "Buttons", tbl = Dark.Colors.Buttons },
				})

				if DataType and Distance <= Threshold then
					Descendant.ImageColor3 = DataType
					Descendant:SetAttribute("_AdmStyleText", string.gsub(Name, "Text.", ""))
				end
			end
		end

		--// Button backgrounds
		if Descendant:IsA("TextButton") or Descendant:IsA("ImageButton") then
			if Descendant.BackgroundTransparency ~= 1 then
				local Found = false

				for ColorName, Data in Dark.Colors.Buttons do
					local DataType = (type(Data) == "table" and Data.Color) or (typeof(Data) == "Color3" and Data)
					if DataType and Descendant.BackgroundColor3 == DataType then

						Found = ColorName
						break
					end
				end

				if not Found and ForceSimilarity then
					local Name, DataType, Distance = FindClosestInGroup(Descendant.BackgroundColor3, Dark.Colors.Buttons, "Buttons")
					if DataType and Distance <= Threshold then
						Descendant.BackgroundColor3 = DataType

						Found = Name
					end
				end

				DebugLabel(Descendant, Found or "NoMatch")

				if Found then 
					Descendant:SetAttribute("_AdmStyleBackground", Found) 
				end
			end
		end

		--// Generic GuiObjects (Background)
		if Descendant:IsA("GuiObject") then
			if Descendant.BackgroundTransparency ~= 1 then
				local Found = false

				for ColorName, Data in Dark.Colors.Background do
					local DataType = (type(Data) == "table" and Data.Color) or (typeof(Data) == "Color3" and Data)

					if DataType and Descendant.BackgroundColor3 == DataType then
						Found = ColorName

						break
					end
				end

				if not Found and ForceSimilarity then
					local Name, Type, Distance = FindClosestInGroup(Descendant.BackgroundColor3, Dark.Colors.Background, "Background")
					if Type and Distance <= Threshold then
						Descendant.BackgroundColor3 = Type

						Found = Name
					end
				end

				DebugLabel(Descendant, Found or "NoMatch")

				if Found then 
					Descendant:SetAttribute("_AdmStyleBackground", Found) 
				end
			end
		end
	end

	--// Main loop
	for _, Descendant in Var.MainFrame.Parent:GetDescendants() do
		Process(Descendant)
	end

	Process(Var.MainFrame)

	if Var.ThemeAddedEvent then
		Var.ThemeAddedEvent:Disconnect()
	end

	Var.ThemeAddedEvent = Var.MainFrame.Parent.DescendantAdded:Connect(function(Child)
		if not Child:IsA("GuiObject") then return end

		Process(Child)
	end)
end

function Frontend.LoadTheme(ThemeTable)
	Utilities.Logging.Print(`Loading theme`, ThemeTable)

	Var.UseAcrylic = ThemeTable.EnableAcrylic
	if ThemeTable.EnableAcrylic then
		require(Libraries.Neon):BindFrame(Var.MainFrame, {
			Transparency = 0.95,
			BrickColor = BrickColor.new("Institutional white")
		})

		if not game.Lighting:FindFirstChild("AdministerAcrylic") then
			local NewEffect = Instance.new("DepthOfFieldEffect")
			NewEffect.FarIntensity = 0
			NewEffect.FocusDistance = 51.6
			NewEffect.InFocusRadius = 50
			NewEffect.NearIntensity = 1

			NewEffect.Parent = game.Lighting
			NewEffect.Name = "AdministerAcrylic"
		end
	else
		require(Libraries.Neon):UnbindFrame(Var.MainFrame)
	end

	local function Style(Descendant: GuiObject)
		if Descendant:IsA("GuiObject") then
			if Descendant:GetAttribute("_AdmStyleText") then
				for Name, Color in ThemeTable.Colors.Text do
					if Name == Descendant:GetAttribute("_AdmStyleText") then
						if Descendant:IsA("TextBox") or Descendant:IsA("TextLabel") then
							Descendant.TextColor3 = Color.Color

							Descendant.FontFace = ThemeTable.General.Fonts[Name]

							if Descendant.TextTransparency ~= 1 then
								Descendant.TextTransparency = Color.Transparency
							end
						elseif Descendant:IsA("ImageLabel") or Descendant:IsA("ImageButton") then	
							if Descendant:GetAttribute("_AdmIsIcon") or ThemeTable.ForceStyleImages == true then
								Descendant.ImageColor3 = Color.Color

								if Descendant.ImageTransparency ~= 1 then
									Descendant.ImageTransparency = Color.Transparency
								end
							else
								--print(Descendant:GetFullName(), ThemeTable.ForceStyleImages)
							end
						end
					end
				end
			end

			if Descendant:GetAttribute("_AdmStyleBackground") then
				for Name, Color in ThemeTable.Colors.Background do
					if Name == Descendant:GetAttribute("_AdmStyleBackground") then
						Descendant.BackgroundColor3 = Color.Color

						if Descendant.BackgroundTransparency ~= 1 then
							Descendant.BackgroundTransparency = Color.Transparency
						end
					end
				end

				for Name, Color in ThemeTable.Colors.Colors do
					if Name == Descendant:GetAttribute("_AdmStyleBackground") then
						Descendant.BackgroundColor3 = Color.Color

						if Descendant.BackgroundTransparency ~= 1 then
							Descendant.BackgroundTransparency = Color.Transparency
						end
					end
				end

				for Name, Color in ThemeTable.Colors.Buttons do
					if Name == Descendant:GetAttribute("_AdmStyleBackground") then
						Descendant.BackgroundColor3 = Color.Color

						if Descendant.BackgroundTransparency ~= 1 then
							Descendant.BackgroundTransparency = Color.Transparency
						end
					end
				end
			end
		elseif Descendant:IsA("UICorner") then
			for _, Overrides in ThemeTable.General.RoundingOverrides do
				if Overrides[1] == Descendant.CornerRadius then
					Descendant.CornerRadius = Overrides[2]
				end
			end
		end

		if ThemeTable.General.AdditionalProperties[Descendant.ClassName] then
			for Property, Value in ThemeTable.General.AdditionalProperties[Descendant.ClassName] do
				xpcall(function()
					Descendant[Property] = Value
				end, function()
					Utilities.Logging.Warn(`[ThemeValidation] prop {Descendant.ClassName}/{Property} is locked or hidden`)
				end)
			end
		end
	end

	Style(Var.MainFrame)

	for _, Descendant in Var.MainFrame.Parent:GetDescendants() do
		Style(Descendant)
	end

	if Var.ThemeUpdateEvent then
		Var.ThemeUpdateEvent:Disconnect()
	end

	Var.ThemeUpdateEvent = (Var.MainFrame.Parent :: CanvasGroup).DescendantAdded:Connect(function(Child)
		Style(Child)
	end)
	
	ThemeTable.OnStyle()
end

return Frontend
