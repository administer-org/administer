--// Administer
--// CodingAgent 2024-2026

local Widgets = {
	Active = {},
}

local Modules = script.Parent

local Utilities = require(Modules.Utilities)
local Frontend = require(Modules.Frontend)
local Var = require(Modules.Variables)

function Widgets.GetAvailableWidgets(): { Small: { {} }, Large: { {} } }
	local Widgets: { Small: { {} }, Large: { {} } } = { Small = {}, Large = {} }

	for _, Widget in Var.MainFrame:GetChildren() do
		local WidgetFolder: Folder? = Widget:FindFirstChild(".widgets")
		if not WidgetFolder or not WidgetFolder:IsA("Folder") then
			continue
		end

		xpcall(function()
			local Module: Instance? = WidgetFolder:FindFirstChild(".widgetconfig")
			local Config

			if Module and Module:IsA("ModuleScript") then
				Config = require(Module) :: any
			end

			if not Config then
				Utilities.Logging.Error(
					`{Widget.Name}: Invalid Administer Widget folder (missing .widgetconfig, please read the docs!)`
				)
			end

			local SplitGenerator = string.split(Config._generator, "-")
			if SplitGenerator[1] ~= "AdministerWidgetConfig" then
				Utilities.Logging.Error(
					`{Widget.Name}: Not a valid Administer widget configuration file (bad .widgetconfig, please read the docs!)`
				)
			end

			for Key, FinalWidget in Config["Widgets"] do
				if FinalWidget["Type"] == "SMALL_LABEL" then
					table.insert(Widgets["Small"], FinalWidget)
				elseif FinalWidget["Type"] == "LARGE_BOX" then
					table.insert(Widgets["Large"], FinalWidget)
				else
					Utilities.Logging.Error(`{Widget.Name}: Bad widget type (not in predefined list)`)
				end
				FinalWidget["Identifier"] = `{Widget.Name}\\{Key}`
				FinalWidget["AppName"] = Widget.Name
			end
		end, function(z)
			Utilities.Logging.Warn(z)
			Utilities.Logging.Error(`{Widget.Name}: This does not appear to be a valid Administer widget (failure)`)
		end)
	end

	return Widgets
end

function Widgets.Edit(ContainingUI): ()
	if ContainingUI:GetAttribute("IsEditing") then
		Frontend.Toast({
			Icon = Utilities.Icon("triangle-warning"),
			Text = Utilities.Translate("generic.error.Generic"),
			Subtext = Utilities.Translate("widgets.concurrent.Body"),
			Timeout = 5,
		})

		return
	else
		ContainingUI:SetAttribute("IsEditing", true)
	end

	ContainingUI.Content.Visible = false

	local Editing = ContainingUI.Editing
	local AnimSpeed = Var.AnimationSpeed * 1.2
	local Selected = ""
	local SelectedTable = {}
	local Tweens: { Tween } = {}
	local HoverConnections = {}
	local NavConnections = {}
	local ShouldHover = true

	local function DisconnectConnections(ConnectionList)
		for _, Connection in ipairs(ConnectionList) do
			if Connection then
				Connection:Disconnect()
			end
		end
		table.clear(ConnectionList)
	end

	local function ClearPreview()
		for _, Element in Editing.Preview:GetChildren() do
			if not table.find({ "DefaultCorner_", "Select" }, Element.Name) then
				Element:Destroy()
			end
		end
	end

	local function FinishEdit()
		ShouldHover = false
		DisconnectConnections(HoverConnections)
		DisconnectConnections(NavConnections)
		Editing.Visible = false
		ContainingUI.Content.Visible = true
		ContainingUI:SetAttribute("IsEditing", false)
	end

	Editing.Visible = true
	Editing.Preview.Select.Visible = true

	local NewPreviewContent: CanvasGroup = ContainingUI.Content:Clone()

	for _, Item in NewPreviewContent:GetChildren() do
		if
			Item:IsA("LocalScript") or Item:IsA("Script")
			Item:IsA("LocalScript") or Item:IsA("Script")
		then
			Item:Destroy()
		end
	end

	NewPreviewContent.Parent = Editing:FindFirstChild("Preview")

	Tweens = {
		Var.Services.TweenService:Create(Editing.Preview, TweenInfo.new(AnimSpeed, Enum.EasingStyle.Quart), {
			Size = UDim2.new(0.459, 0, 0.551, 0),
			Position = UDim2.new(0.271, 0, 0.057, 0),
			BackgroundTransparency = 0.4,
		}),
		Var.Services.TweenService:Create(
			NewPreviewContent,
			TweenInfo.new(AnimSpeed * 0.35),
			{ Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0) }
		),
		Var.Services.TweenService:Create(Editing.Background, TweenInfo.new(AnimSpeed), { ImageTransparency = 0 }),
		Var.Services.TweenService:Create(Editing.AppName, TweenInfo.new(AnimSpeed), { TextTransparency = 0 }),
		Var.Services.TweenService:Create(Editing.WidgetName, TweenInfo.new(AnimSpeed), { TextTransparency = 0 }),
		Var.Services.TweenService:Create(Editing.Last.ImageLabel, TweenInfo.new(AnimSpeed), { ImageTransparency = 0 }),
		Var.Services.TweenService:Create(Editing.Next.ImageLabel, TweenInfo.new(AnimSpeed), { ImageTransparency = 0 }),
		Var.Services.TweenService:Create(
			Editing.Preview.DefaultCorner_,
			TweenInfo.new(AnimSpeed),
			{ CornerRadius = UDim.new(0, 18) }
		),
	}

	xpcall(function()
		Editing.AppName.Text = ContainingUI:GetAttribute("AppName")
		Editing.WidgetName.Text = ContainingUI:GetAttribute("InitialWidgetName")
	end, function()
		Editing.AppName.Text = Utilities.Translate("widgets.uninstalled.Header")
		Editing.WidgetName.Text = Utilities.Translate("widgets.Corrupted")
	end)

	task.spawn(function()
		Tweens[1]:Play()
		Tweens[2]:Play()
		Tweens[3]:Play()
		Tweens[8]:Play()

		task.wait(AnimSpeed * 0.8)

		for _, Tween in Tweens do
			Tween:Play()
		end
	end)

	table.insert(
		HoverConnections,
		Editing.Preview.Select.MouseEnter:Connect(function()
			if not ShouldHover then
				return
			end
			Var.Services.TweenService
				:Create(
					Editing.Preview,
					TweenInfo.new(AnimSpeed * 0.6, Enum.EasingStyle.Quart),
					{ Size = UDim2.new(0.472, 0, 0.614, 0), Position = UDim2.new(0.264, 0, 0.017, 0) }
				)
				:Play()
		end)
	)

	table.insert(
		HoverConnections,
		Editing.Preview.Select.MouseLeave:Connect(function()
			if not ShouldHover then
				return
			end
			Var.Services.TweenService
				:Create(
					Editing.Preview,
					TweenInfo.new(AnimSpeed * 0.6, Enum.EasingStyle.Quart),
					{ Size = UDim2.new(0.459, 0, 0.551, 0), Position = UDim2.new(0.271, 0, 0.057, 0) }
				)
				:Play()
		end)
	)

	table.insert(
		HoverConnections,
		Editing.Preview.Select.MouseButton1Click:Connect(function()
			DisconnectConnections(HoverConnections)
			Editing.Preview.Select.Visible = false

			AnimSpeed = ((tonumber(Utilities.GetSetting("AnimationSpeed")) :: number) or 1) * 0.4

			Tweens = {
				Var.Services.TweenService:Create(
					Editing.Preview,
					TweenInfo.new(
						((tonumber(Utilities.GetSetting("AnimationSpeed")) :: number) or 1) * 1.2,
						Enum.EasingStyle.Quart
					),
					{ Position = UDim2.new(0.264, 0, 0.189, 0) }
				),
				Var.Services.TweenService:Create(Editing.AppName, TweenInfo.new(AnimSpeed), { TextTransparency = 1 }),
				Var.Services.TweenService:Create(
					Editing.WidgetName,
					TweenInfo.new(AnimSpeed),
					{ TextTransparency = 1 }
				),
				Var.Services.TweenService:Create(
					Editing.Last.ImageLabel,
					TweenInfo.new(AnimSpeed),
					{ ImageTransparency = 1 }
				),
				Var.Services.TweenService:Create(
					Editing.Next.ImageLabel,
					TweenInfo.new(AnimSpeed),
					{ ImageTransparency = 1 }
				),
			}

			for _, Tween in Tweens do
				Tween:Play()
			end

			Tweens[1].Completed:Wait()
			AnimSpeed = ((tonumber(Utilities.GetSetting("AnimationSpeed")) :: number) or 1) * 1.2

			Var.Services.TweenService
				:Create(Editing.Preview, TweenInfo.new(AnimSpeed, Enum.EasingStyle.Quart), {
					Position = UDim2.new(0.043, 0, 0, 0),
					Size = UDim2.new(0.957, 0, 1, 0),
					BackgroundTransparency = 1,
				})
				:Play()
			Var.Services.TweenService
				:Create(Editing.Background, TweenInfo.new(AnimSpeed), { ImageTransparency = 1 })
				:Play()
			Var.Services.TweenService
				:Create(Editing.Preview.DefaultCorner_, TweenInfo.new(AnimSpeed), { CornerRadius = UDim.new(0, 0) })
				:Play()

			if Selected == "" then
				Utilities.Logging.Print("Exiting because nothing was selected!")
				ClearPreview()
				FinishEdit()
				return
			end

			local Success, ErrorMessage = pcall(function()
				Var.Remotes.UpdateHomePage:InvokeServer({
					EventType = "UPDATE",
					EventID = `ChangeWidget-{ContainingUI.Name}`,
					WidgetID = ContainingUI.Name,
					NewIdentifier = Selected,
				})
			end)

			if not Success then
				Utilities.Logging.Warn(ErrorMessage)
				ClearPreview()
				FinishEdit()
				return
			end

			task.wait(AnimSpeed)

			ContainingUI.Content.Visible = true
			ContainingUI.SideData.Banner.Text = SelectedTable["Name"]
			ContainingUI.SideData.BannerIcon.Image = SelectedTable["Icon"]
			ContainingUI.Content:ClearAllChildren()

			for _, Element in Editing.Preview:GetChildren() do
				if not table.find({ "DefaultCorner_", "Select" }, Element.Name) then
					Element.Parent = ContainingUI.Content
				end
			end

			FinishEdit()
		end)
	)

	local AvailableWidgets = Widgets.GetAvailableWidgets()["Large"]
	local Count = 0

	local function FindCurrentWidgetIndex()
		local CurrentIdentifier = ""
		local Success, AppName = pcall(function()
			return ContainingUI:GetAttribute("AppName")
		end)
		local SuccessName, InitialWidgetName = pcall(function()
			return ContainingUI:GetAttribute("InitialWidgetName")
		end)

		if Success and SuccessName and AppName and InitialWidgetName then
			CurrentIdentifier = `{AppName}\\{InitialWidgetName}`
		end

		if CurrentIdentifier ~= "" then
			for Index, Widget in ipairs(AvailableWidgets) do
				if Widget["Identifier"] == CurrentIdentifier then
					return Index
				end
			end
		end

		return 0
	end

	local function SelectWidget(Index, Animate, Direction)
		if not AvailableWidgets[Index] then
			return false
		end

		local Widget = AvailableWidgets[Index]
		if Widget.CanDiscover == false then
			return false
		end

		local EnterDirection = Direction or 1
		local SlideOutPosition = EnterDirection > 0 and UDim2.new(-1, 0, 0.057, 0) or UDim2.new(1, 0, 0.057, 0)
		local SlideOutLabelPosition = EnterDirection > 0 and UDim2.new(-1, 0, 0.81, 0) or UDim2.new(1, 0, 0.81, 0)
		local SlideOutNamePosition = EnterDirection > 0 and UDim2.new(-1, 0, 0.647, 0) or UDim2.new(1, 0, 0.647, 0)
		local EnterPosition = EnterDirection > 0 and UDim2.new(1, 0, 0.075, 0) or UDim2.new(-0.7, 0, 0.075, 0)
		local EnterLabelPosition = EnterDirection > 0 and UDim2.new(1, 0, 0.81, 0) or UDim2.new(-0.7, 0, 0.81, 0)
		local EnterNamePosition = EnterDirection > 0 and UDim2.new(1, 0, 0.647, 0) or UDim2.new(-0.7, 0, 0.647, 0)

		if Animate then
			AnimSpeed = Var.AnimationSpeed * 3
			Tweens = {
				Var.Services.TweenService:Create(
					Editing.Preview,
					TweenInfo.new(AnimSpeed, Enum.EasingStyle.Quart),
					{ Position = SlideOutPosition, GroupTransparency = 1 }
				),
				Var.Services.TweenService:Create(
					Editing.AppName,
					TweenInfo.new(AnimSpeed, Enum.EasingStyle.Quart),
					{ Position = SlideOutLabelPosition, TextTransparency = 1 }
				),
				Var.Services.TweenService:Create(
					Editing.WidgetName,
					TweenInfo.new(AnimSpeed, Enum.EasingStyle.Quart),
					{ Position = SlideOutNamePosition, TextTransparency = 1 }
				),
			}
			for _, t in Tweens do
				t:Play()
			end

			task.wait(AnimSpeed / 3)
		end

		local NewWidgetTemplate = Widget["BaseUIFrame"]:Clone()
		NewWidgetTemplate.Visible = true

		ClearPreview()

		NewWidgetTemplate.Parent = Editing.Preview
		Selected = Widget["Identifier"]
		Count = Index

		Editing.Preview.Position = EnterPosition
		Editing.AppName.Position = EnterLabelPosition
		Editing.WidgetName.Position = EnterNamePosition
		Editing.WidgetName.Text = Widget["Name"]
		Editing.AppName.Text = Widget["AppName"]
		AnimSpeed = Var.AnimationSpeed * 2.45
		SelectedTable = Widget

		if Animate then
			Tweens = {
				Var.Services.TweenService:Create(
					Editing.Preview,
					TweenInfo.new(AnimSpeed, Enum.EasingStyle.Quart),
					{ Position = UDim2.new(0.271, 0, 0.057, 0), GroupTransparency = 0 }
				),
				Var.Services.TweenService:Create(
					Editing.AppName,
					TweenInfo.new(AnimSpeed, Enum.EasingStyle.Quart),
					{ Position = UDim2.new(0.04, 0, 0.81, 0), TextTransparency = 0 }
				),
				Var.Services.TweenService:Create(
					Editing.WidgetName,
					TweenInfo.new(AnimSpeed, Enum.EasingStyle.Quart),
					{ Position = UDim2.new(0.04, 0, 0.647, 0), TextTransparency = 0 }
				),
			}
			for _, t in Tweens do
				t:Play()
			end

			Tweens[1].Completed:Wait()
		else
			Editing.Preview.Position = UDim2.new(0.271, 0, 0.057, 0)
			Editing.Preview.GroupTransparency = 0
			Editing.AppName.Position = UDim2.new(0.04, 0, 0.81, 0)
			Editing.WidgetName.Position = UDim2.new(0.04, 0, 0.647, 0)
			Editing.AppName.TextTransparency = 0
			Editing.WidgetName.TextTransparency = 0
		end

		ShouldHover = true
		return true
	end

	local function MoveWidget(Step)
		if #AvailableWidgets == 0 then
			return false
		end

		local StartIndex = Count > 0 and Count or FindCurrentWidgetIndex()
		if StartIndex <= 0 then
			StartIndex = 1
		end

		local CandidateIndex = StartIndex
		for _ = 1, #AvailableWidgets do
			CandidateIndex += Step
			if CandidateIndex > #AvailableWidgets then
				CandidateIndex = 1
			elseif CandidateIndex < 1 then
				CandidateIndex = #AvailableWidgets
			end

			if SelectWidget(CandidateIndex, true, Step) then
				return true
			end
		end

		return false
	end

	local CurrentIndex = FindCurrentWidgetIndex()
	if CurrentIndex > 0 then
		SelectWidget(CurrentIndex, false, 1)
	else
		for Index = 1, #AvailableWidgets do
			if SelectWidget(Index, false, 1) then
				break
			end
		end
	end

	table.insert(
		NavConnections,
		Editing.Next.MouseButton1Click:Connect(function()
			ShouldHover = false
			MoveWidget(1)
		end)
	)

	table.insert(
		NavConnections,
		Editing.Last.MouseButton1Click:Connect(function()
			ShouldHover = false
			MoveWidget(-1)
		end)
	)
end

function Widgets.ActivateWidget(WidgetNumber, WidgetConfig) end

function Widgets.Initialize()
	local WidgetData = game:GetService("HttpService"):JSONDecode(Var.MainFrame.Parent:GetAttribute("_HomeWidgets"))
	local Available = Widgets.GetAvailableWidgets()["Large"]

	for _, UI in Var.MainFrame.Home:GetChildren() do
		if not table.find({ "Widget1", "Widget2" }, UI.Name) then
			continue
		end

		for _, Widget in Available do
			if Widget["Identifier"] == WidgetData[UI.Name] then
				xpcall(function()
					UI.SideData.Banner.Text = Widget["Name"]
					UI.SideData.BannerIcon.Image = Widget["Icon"]
				end, function() end)

				Widget["BaseUIFrame"].Parent = UI.Content
				Widget["BaseUIFrame"].Visible = true
				Widget["OnRender"](Var.Services.Players.LocalPlayer, Widget["BaseUIFrame"])

				UI:SetAttribute("AppName", string.split(Widget["Identifier"], "\\")[1])
				UI:SetAttribute("InitialWidgetName", string.split(Widget["Identifier"], "\\")[2])

				table.insert(Widgets.Active, Widget)
			end
		end
	end
end

return Widgets
