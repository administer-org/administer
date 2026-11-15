-- Keep interactive UI inside the device safe area, with a stationary header in
-- the part of Roblox's top bar that is not occupied by its own controls.
local Var = require(script.Parent.Variables)

local MobileLayout = {}
local EDGE_PADDING = 8
local HEADER_HEIGHT = 44
local MOBILE_SCALE = 1.5
local initialized = false

function MobileLayout.StyleMenu()
	local Drawer = Var.MainFrame.AppDrawer
	local Apps = Drawer.AppHolder.Apps
	local PlayerData = Drawer.PlayerData

	Drawer.Size = UDim2.fromScale(1, 1)
	Drawer.AppDrawerCover.Visible = false
	PlayerData.AnchorPoint = Vector2.zero
	PlayerData.Position = UDim2.fromOffset(12, 4)
	PlayerData.Size = UDim2.new(1, -24, 0, 44)
	PlayerData.PlayerImage.Position = UDim2.fromOffset(8, 7)
	PlayerData.PlayerImage.Size = UDim2.fromOffset(30, 30)
	PlayerData.DisplayName.Position = UDim2.fromOffset(48, 2)
	PlayerData.DisplayName.Size = UDim2.new(1, -56, 0, 23)
	PlayerData.DisplayName.TextXAlignment = Enum.TextXAlignment.Left
	PlayerData.DisplayName.TextScaled = false
	PlayerData.DisplayName.TextSize = 17
	PlayerData.Rank.Position = UDim2.fromOffset(48, 24)
	PlayerData.Rank.Size = UDim2.new(1, -56, 0, 17)
	PlayerData.Rank.TextXAlignment = Enum.TextXAlignment.Left
	PlayerData.Rank.TextScaled = false
	PlayerData.Rank.TextSize = 11

	Apps.AnchorPoint = Vector2.zero
	Apps.Position = UDim2.fromOffset(12, 52)
	Apps.Size = UDim2.new(1, -24, 1, -56)
	Apps.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Apps.CanvasSize = UDim2.fromOffset(0, 0)
	Apps.CanvasPosition = Vector2.zero
	Apps.ScrollingEnabled = true
	Apps.Active = true
	Apps.ScrollingDirection = Enum.ScrollingDirection.Y
	Apps.ScrollBarThickness = 5
	Apps.UIListLayout.Padding = UDim.new(0, 6)

	local function StyleRow(Row, Indent)
		Row.AnchorPoint = Vector2.zero
		Row.Size = UDim2.new(1, -Indent, 0, 34)
		Row.BackgroundTransparency = 0.35
		Row.BackgroundColor3 = Color3.fromRGB(23, 26, 34)
		local Icon = Row:FindFirstChild("Icon")
		if Icon then
			Icon.AnchorPoint = Vector2.new(0, 0.5)
			Icon.Position = UDim2.fromOffset(12, 17)
			Icon.Size = UDim2.fromOffset(17, 17)
		end
		local Title = Row:FindFirstChild("Title")
		if Title then
			Title.AnchorPoint = Vector2.zero
			Title.Position = UDim2.fromOffset(40, 0)
			Title.Size = UDim2.new(1, -48, 0, 34)
			Title.TextXAlignment = Enum.TextXAlignment.Left
			Title.TextScaled = false
			Title.TextSize = 14
		end
		local Activator = Row:FindFirstChild("Activator")
		if Activator then
			Activator.Size = UDim2.fromScale(1, 1)
		end
	end

	for _, Row in Apps:GetChildren() do
		if not Row:IsA("Frame") or Row.Name == "SingleThread" or Row.Name == "MultiThread" then
			continue
		end
		local SubCollection = Row:FindFirstChild("SubCollection")
		local SubCount = 0
		if SubCollection then
			for _, SubRow in SubCollection:GetChildren() do
				if SubRow:IsA("Frame") and SubRow.Visible and SubRow.Name ~= "Object" then
					SubCount += 1
					StyleRow(SubRow, 0)
				end
			end
			SubCollection.Position = UDim2.fromOffset(24, 38)
			SubCollection.Size = UDim2.new(1, -24, 0, SubCount * 40)
			SubCollection.UIListLayout.Padding = UDim.new(0, 6)
		end
		StyleRow(Row, 0)
		Row.Size = UDim2.new(1, -10, 0, 38 + SubCount * 40)
		local Activator = Row:FindFirstChild("Activator")
		if Activator and SubCount > 0 then
			Activator.Size = UDim2.new(1, 0, 0, 34)
		end
		for _, Name in { "HierarchyLine", "SubHierarchyLine" } do
			local Line = Row:FindFirstChild(Name)
			if Line then
				Line.Visible = false
			end
		end
	end
end

function MobileLayout.FillScreen()
	local Main = Var.MainFrame
	local Scale = Main:FindFirstChild("MobileUIScale")
	local ScaleValue = Scale and Scale.Scale or MOBILE_SCALE
	Main.Position = UDim2.fromScale(0.5, 0.5)
	Main.Size = UDim2.fromScale(1 / ScaleValue, 1 / ScaleValue)
	Main.UICorner.CornerRadius = UDim.new(0, 0)
	Main:SetAttribute("IsFullScreen", true)
end

function MobileLayout.Initialize()
	if initialized then
		return
	end
	initialized = true

	local Root = Var.AdministerRoot
	local Main = Var.MainFrame
	local Header = Main.Header
	local Mark = Header.Mark
	local GuiService = Var.Services.GUIService

	-- The panel background fills the entire screen. Padding below keeps only
	-- interactive content clear of the notch and Roblox's topbar.
	Root.ScreenInsets = Enum.ScreenInsets.None
	Root.SafeAreaCompatibility = Enum.SafeAreaCompatibility.None
	Root.ClipToDeviceSafeArea = false

	local Scale = Instance.new("UIScale")
	Scale.Name = "MobileUIScale"
	Scale.Scale = MOBILE_SCALE
	Scale.Parent = Main

	local SizeConstraint = Main:FindFirstChildWhichIsA("UISizeConstraint")
	if SizeConstraint then
		SizeConstraint.MinSize = Vector2.zero
	end

	local Padding = Main:FindFirstChildWhichIsA("UIPadding") or Instance.new("UIPadding")
	Padding.Name = "MobileSafePadding"
	Padding.Parent = Main
	Main.AppDrawer.Visible = false

	local function UpdateInsets()
		-- All inset rectangles use the same coordinate space. Convert physical
		-- pixels to pre-scale offsets for children of the enlarged panel.
		local NoneArea = GuiService:GetInsetArea(Enum.ScreenInsets.None)
		local DeviceArea = GuiService:GetInsetArea(Enum.ScreenInsets.DeviceSafeInsets)
		local CoreArea = GuiService:GetInsetArea(Enum.ScreenInsets.CoreUISafeInsets)
		local TopbarArea = GuiService:GetInsetArea(Enum.ScreenInsets.TopbarSafeInsets)
		local Viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Root.AbsoluteSize
		Scale.Scale = Viewport.X < 600 and 1.25 or MOBILE_SCALE
		local UiScale = Scale.Scale
		MobileLayout.FillScreen()

		local LeftSafe = math.max(0, DeviceArea.Min.X - NoneArea.Min.X)
		local TopbarHeight = math.max(HEADER_HEIGHT, CoreArea.Min.Y - NoneArea.Min.Y)
		local TopPadding = TopbarHeight

		Padding.PaddingLeft = UDim.new(0, LeftSafe / UiScale)
		Padding.PaddingRight = UDim.new(0, 0)
		Padding.PaddingBottom = UDim.new(0, 0)
		Padding.PaddingTop = UDim.new(0, TopPadding / UiScale)

		-- Cancel the content padding for the header only. The app and its drawer
		-- stay below the top bar; the header stays alongside the Roblox buttons.
		Header.AnchorPoint = Vector2.zero
		Header.Position = UDim2.fromOffset(-LeftSafe / UiScale, -TopPadding / UiScale)
		Header.Size = UDim2.new(1, LeftSafe / UiScale, 0, TopbarHeight / UiScale)
		Header.ZIndex = Main.AppDrawer.ZIndex + 1

		local Left = math.max(0, TopbarArea.Min.X - NoneArea.Min.X) + EDGE_PADDING
		local Right = math.min(NoneArea.Width, TopbarArea.Max.X - NoneArea.Min.X) - EDGE_PADDING
		local Width = math.max(0, Right - Left)
		local Height = math.min(HEADER_HEIGHT, TopbarHeight)
		local IconSize = Height / (1.5 * UiScale)
		local HeaderHeight = TopbarHeight / UiScale

		Mark.AnchorPoint = Vector2.zero
		Mark.Position = UDim2.fromOffset(Left / UiScale, (TopbarHeight - Height) / (2 * UiScale))
		Mark.Size = UDim2.fromOffset(math.max(0, Width - Height - EDGE_PADDING) / UiScale, Height / UiScale)
		Mark.ClipsDescendants = true

		-- The desktop mark uses negative scale positions. Give its children a
		-- compact local layout instead of adding a viewport inset to that scale.
		Mark.AppLogo.AnchorPoint = Vector2.new(0, 0.5)
		Mark.AppLogo.Position = UDim2.fromScale(0, 0.5)
		Mark.AppLogo.Size = UDim2.fromOffset(IconSize, IconSize)
		Mark.HeaderTitle.AnchorPoint = Vector2.zero
		Mark.HeaderTitle.Position = UDim2.fromOffset(IconSize + EDGE_PADDING / UiScale, 0)
		Mark.HeaderTitle.Size = UDim2.new(1, -IconSize - EDGE_PADDING / UiScale, 0, 24 / UiScale)
		Mark.HeaderTitle.TextScaled = false
		Mark.HeaderTitle.TextWrapped = false
		Mark.HeaderTitle.TextSize = 18 / UiScale
		Mark.HeaderTitle.TextTruncate = Enum.TextTruncate.AtEnd
		Mark.HeaderSubapp.AnchorPoint = Vector2.zero
		Mark.HeaderSubapp.Position = UDim2.fromOffset(IconSize + 24 / UiScale, 24 / UiScale)
		Mark.HeaderSubapp.Size = UDim2.new(1, -IconSize - 24 / UiScale, 0, 20 / UiScale)
		Mark.HeaderSubapp.TextScaled = false
		Mark.HeaderSubapp.TextWrapped = false
		Mark.HeaderSubapp.TextSize = 12 / UiScale
		Mark.HeaderSubapp.TextTruncate = Enum.TextTruncate.AtEnd
		Mark.Logo.AnchorPoint = Vector2.zero
		Mark.Logo.Position = UDim2.fromOffset(IconSize + EDGE_PADDING / UiScale, 28 / UiScale)
		Mark.Logo.Size = UDim2.fromOffset(12 / UiScale, 12 / UiScale)

		Header.AssistiveClose.AnchorPoint = Vector2.new(1, 0.5)
		Header.AssistiveClose.Position = UDim2.fromOffset(Right / UiScale, HeaderHeight / 2)
		Header.AssistiveClose.Size = UDim2.fromOffset(Height / UiScale, Height / UiScale)
		-- When Roblox temporarily occupies the whole top bar, don't draw over it.
		Mark.Visible = Width >= Height * 2 + EDGE_PADDING
		Header.AssistiveClose.Visible = Width >= Height
	end

	local Connections = {}
	local CameraConnection
	local function WatchCamera()
		if CameraConnection then
			CameraConnection:Disconnect()
		end
		local Camera = workspace.CurrentCamera
		if Camera then
			CameraConnection = Camera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateInsets)
		end
		UpdateInsets()
	end

	table.insert(Connections, GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(UpdateInsets))
	table.insert(Connections, Root:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateInsets))
	table.insert(Connections, Root:GetPropertyChangedSignal("AbsolutePosition"):Connect(UpdateInsets))
	table.insert(Connections, workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(WatchCamera))
	Root.Destroying:Connect(function()
		for _, Connection in Connections do
			Connection:Disconnect()
		end
		if CameraConnection then
			CameraConnection:Disconnect()
		end
	end)

	WatchCamera()
end

return MobileLayout
