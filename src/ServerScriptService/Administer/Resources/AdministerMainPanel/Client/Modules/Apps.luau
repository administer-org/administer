--// Administer
--// CodingAgent 2024-2026

--// This is mostly for the Marketplace but has some other app-related functions.

local Modules = script.Parent

local Types = require(Modules.Types)
local Var = require(Modules.Variables)
local Frontend = require(Modules.Frontend)
local Utilities = require(Modules.Utilities)

local Shime = require(Modules.Parent.Libraries.Shime)

local Apps = {}
local Connections = {}
local ActiveContextMenu = nil

local function getConf()
	if not Var.MainFrame then
		return nil
	end
	local direct = Var.MainFrame:FindFirstChild("Configuration")
	if direct and direct:FindFirstChild("Marketplace") then
		return direct
	end
	local recursive = Var.MainFrame:FindFirstChild("Configuration", true)
	if recursive and recursive:FindFirstChild("Marketplace") then
		return recursive
	end
	return nil
end

local function RemoveDrawerButton(appName: string?)
	if not appName then
		return
	end

	local appsHolder = nil
	pcall(function()
		appsHolder = Var.MainFrame.AppDrawer.AppHolder.Apps
	end)

	Utilities.Logging.Warn(`[RemoveDrawerButton] Removing {appName}, appsHolder={tostring(appsHolder)}`)

	for idx, config in Var.CombinedButtonConfig do
		if config.AppName == appName and not config.IsBuiltIn then
			Utilities.Logging.Warn(
				`[RemoveDrawerButton] Found in CombinedButtonConfig, ButtonRef={tostring(config.ButtonRef)}`
			)
			if config.ButtonRef and config.ButtonRef.Parent then
				Utilities.Logging.Warn(`[RemoveDrawerButton] Destroying ButtonRef for {appName}`)
				config.ButtonRef:Destroy()
			end

			table.remove(Var.CombinedButtonConfig, idx)
			break
		end
	end

	if not appsHolder then
		Utilities.Logging.Warn(`[RemoveDrawerButton] appsHolder is nil, skipping drawer cleanup`)
		return
	end

	Utilities.Logging.Warn(`[RemoveDrawerButton] Searching AppsHolder children for {appName}`)
	for _, child in appsHolder:GetChildren() do
		Utilities.Logging.Warn(`[RemoveDrawerButton] Checking child: {child.Name}`)
		local nameMatch = (child.Name == appName)
		local titleLabel = child:FindFirstChild("Title")
		local titleMatch = titleLabel and titleLabel:IsA("TextLabel") and titleLabel.Text == appName
		if nameMatch or titleMatch then
			Utilities.Logging.Warn(`[RemoveDrawerButton] Found match! Destroying {child.Name}`)
			child:Destroy()
			break
		end
	end
end

local lifecycleRemote = Var.Remotes:FindFirstChild("AppLifecycle") or Var.Remotes:WaitForChild("AppLifecycle", 5)
if lifecycleRemote and lifecycleRemote:IsA("RemoteEvent") then
	lifecycleRemote.OnClientEvent:Connect(function(action, payload)
		if action == "uninstalled" then
			RemoveDrawerButton(payload and payload.AppName)
		end
	end)
else
	Utilities.Logging.Warn("[AppLifecycle] AppLifecycle remote missing; drawer cleanup disabled")
end

local function ShowContextMenu(onDelete: () -> ())
	if ActiveContextMenu then
		ActiveContextMenu:Destroy()
		ActiveContextMenu = nil
	end
	local existingBackdrop = Var.MainFrame.Parent:FindFirstChild("AppContextMenuBackdrop")
	if existingBackdrop then
		existingBackdrop:Destroy()
	end

	local mousePos = Var.Services.UserInputService:GetMouseLocation()
	local inset = game:GetService("GuiService"):GetGuiInset()

	local Menu = Instance.new("Frame")
	Menu.Name = "AppContextMenu"
	Menu.Size = UDim2.fromOffset(160, 36)
	Menu.Position = UDim2.fromOffset(mousePos.X, mousePos.Y - inset.Y)
	Menu.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	Menu.BorderSizePixel = 0
	Menu.ZIndex = 50
	Menu.Parent = Var.MainFrame.Parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 6)
	Corner.Parent = Menu

	local DeleteBtn = Instance.new("TextButton")
	DeleteBtn.Name = "DeleteOption"
	DeleteBtn.Size = UDim2.fromScale(1, 1)
	DeleteBtn.BackgroundTransparency = 1
	DeleteBtn.Font = Enum.Font.GothamMedium
	DeleteBtn.TextSize = 13
	DeleteBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
	DeleteBtn.TextXAlignment = Enum.TextXAlignment.Left
	DeleteBtn.ZIndex = 51
	DeleteBtn.Parent = Menu

	local IconLabel = Instance.new("ImageLabel")
	IconLabel.Name = "Icon"
	IconLabel.Size = UDim2.fromOffset(16, 16)
	IconLabel.Position = UDim2.fromOffset(10, 10)
	IconLabel.BackgroundTransparency = 1
	IconLabel.Image = Utilities.Icon("trash")
	IconLabel.ImageColor3 = Color3.fromRGB(255, 80, 80)
	IconLabel.ZIndex = 52
	IconLabel.Parent = Menu

	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0, 34)
	Padding.Parent = DeleteBtn

	DeleteBtn.Text = "Delete App"

	task.defer(function()
		if not Menu.Parent then
			return
		end
		local screen = Menu.Parent.AbsoluteSize
		local mx = math.min(mousePos.X, screen.X - 168)
		local my = math.min(mousePos.Y - inset.Y, screen.Y - 44)
		Menu.Position = UDim2.fromOffset(mx, my)
	end)

	ActiveContextMenu = Menu

	local Backdrop = Instance.new("TextButton")
	Backdrop.Name = "AppContextMenuBackdrop"
	Backdrop.Size = UDim2.fromScale(1, 1)
	Backdrop.Position = UDim2.fromOffset(0, 0)
	Backdrop.BackgroundTransparency = 1
	Backdrop.Text = ""
	Backdrop.ZIndex = Menu.ZIndex - 1
	Backdrop.Parent = Menu.Parent

	local function closeMenu()
		if ActiveContextMenu == Menu then
			Backdrop:Destroy()
			Menu:Destroy()
			ActiveContextMenu = nil
		end
	end

	Backdrop.MouseButton1Click:Connect(closeMenu)
	Backdrop.MouseButton2Click:Connect(closeMenu)

	DeleteBtn.MouseButton1Click:Connect(function()
		Backdrop:Destroy()
		Menu:Destroy()
		ActiveContextMenu = nil
		onDelete()
	end)
end

function Apps.AddAppDrawerButton(ButtonConfig: Types.ButtonConfig)
	local AppsHolder = Var.MainFrame.AppDrawer.AppHolder.Apps

	if ButtonConfig.ButtonID == nil then
		return { false, "You must have a button link ID." }
	end

	if ButtonConfig.SubIcons ~= nil then
		for Index, Icon in ButtonConfig.SubIcons do
			if Icon.ButtonID == nil then
				return { false, `Subicon {Icon.Name} must have a ButtonID!` }
			end
		end
	end

	table.insert(Var.CombinedButtonConfig, ButtonConfig)

	if #ButtonConfig.SubIcons == 0 then
		local Button = AppsHolder.SingleThread:Clone()

		Button.Parent = AppsHolder
		Button.Name = ButtonConfig.AppName
		Button.Icon.Image = ButtonConfig.Icon
		Button.Title.Text = ButtonConfig.AppName

		Button:SetAttribute("ThreadType", "single")
		Button:SetAttribute("ButtonID", ButtonConfig.ButtonID)
		Button:SetAttribute("IsBuiltIn", ButtonConfig.IsBuiltIn == true)

		task.defer(function()
			Button.Visible = Var.Remotes.CanUseApp:InvokeServer(ButtonConfig.ButtonID)
		end)

		local suppressNextTap = false
		Button.Activator.MouseButton1Click:Connect(function()
			if suppressNextTap then
				suppressNextTap = false
				return
			end
			task.defer(Frontend.Drawer.Close)

			Frontend.SwapApps(ButtonConfig, 0, Button)

			xpcall(ButtonConfig.MainButtonClick, Utilities.Logging.Warn)
		end)

		if not ButtonConfig.IsBuiltIn then
			local function _openDeletePopup()
				ShowContextMenu(function()
					Frontend.Popup.new(
						{
							Name = Utilities.Translate("Configuration.Marketplace.Header.Head"),
							Icon = Utilities.Icon("administer"),
						},
						{ Primary = ButtonConfig.Icon, SubIcon = Utilities.Icon("warning-filled") },
						Utilities.Translate("Configuration.Apps.MessageBox.Header"):format(ButtonConfig.AppName),
						Utilities.Translate("Configuration.Apps.MessageBox.Content"),
						{
							{
								Text = Utilities.Translate("generic.Yes"),
								Icon = Utilities.Icon("trash"),
								Callback = function(_Close)
									_Close()
									if Button and Button.Parent then
										Button:Destroy()
									end
									for idx, config in Var.CombinedButtonConfig do
										if config.AppName == ButtonConfig.AppName and not config.IsBuiltIn then
											table.remove(Var.CombinedButtonConfig, idx)
											break
										end
									end
									task.spawn(function()
										local invokeOk, Response = pcall(
											Var.Remotes.ManageApp.InvokeServer,
											Var.Remotes.ManageApp,
											ButtonConfig.AppName
										)
										if invokeOk and Response[1] == false then
											Frontend.Toast({
												Icon = Utilities.Icon("x"),
												Text = Utilities.Translate("generic.error.Generic"),
												Subtext = Response[2],
												Timeout = 10,
											})
										end
									end)
								end,
							},
							{
								Text = Utilities.Translate("generic.Cancel"),
								Icon = Utilities.Icon("x"),
								Callback = function(_Close)
									_Close()
								end,
							},
						}
					)
				end)
			end

			Button.Activator.MouseButton2Click:Connect(_openDeletePopup)

			if Var.Services.UserInputService.TouchEnabled then
				local holdThread = nil
				Button.Activator.InputBegan:Connect(function(Input)
					if Input.UserInputType ~= Enum.UserInputType.Touch then
						return
					end
					holdThread = task.delay(0.45, function()
						holdThread = nil
						suppressNextTap = true
						_openDeletePopup()
					end)
				end)
				Button.Activator.InputEnded:Connect(function(Input)
					if Input.UserInputType ~= Enum.UserInputType.Touch then
						return
					end
					if holdThread then
						task.cancel(holdThread)
						holdThread = nil
					end
				end)
			end
		end

		ButtonConfig.MainButtonFrame:SetAttribute("AdmLinkSinglePage", true)

		ButtonConfig.ButtonRef = Button
		Utilities.Logging.Debug(
			`[DBG] AddAppDrawerButton single: {ButtonConfig.AppName} ({ButtonConfig.ButtonID}) ref={tostring(Button)}`
		)
		return Button
	else
		local Button = AppsHolder.MultiThread:Clone()
		local Height = 0

		Button.Name = ButtonConfig.AppName
		Button.Parent = AppsHolder
		Button.Icon.Image = ButtonConfig.Icon
		Button.Title.Text = ButtonConfig.AppName

		Button:SetAttribute("ThreadType", "multi")
		Button:SetAttribute("ButtonID", ButtonConfig.ButtonID)
		Button:SetAttribute("IsBuiltIn", ButtonConfig.IsBuiltIn == true)

		task.defer(function()
			Button.Visible = Var.Remotes.CanUseApp:InvokeServer(ButtonConfig.ButtonID)
		end)

		local suppressNextTap = false
		Button.Activator.MouseButton1Click:Connect(function()
			if suppressNextTap then
				suppressNextTap = false
				return
			end
			if ButtonConfig.MainButtonFrame == nil then
				return
			end

			task.defer(Frontend.Drawer.Close)

			Frontend.SwapApps(ButtonConfig, 0, Button)

			xpcall(ButtonConfig.MainButtonClick, Utilities.Logging.Warn)
		end)

		if not ButtonConfig.IsBuiltIn then
			local function _openDeletePopup()
				ShowContextMenu(function()
					Frontend.Popup.new(
						{
							Name = Utilities.Translate("Configuration.Marketplace.Header.Head"),
							Icon = Utilities.Icon("administer"),
						},
						{ Primary = ButtonConfig.Icon, SubIcon = Utilities.Icon("warning-filled") },
						Utilities.Translate("Configuration.Apps.MessageBox.Header"):format(ButtonConfig.AppName),
						Utilities.Translate("Configuration.Apps.MessageBox.Content"),
						{
							{
								Text = Utilities.Translate("generic.Yes"),
								Icon = Utilities.Icon("trash"),
								Callback = function(_Close)
									_Close()
									if Button and Button.Parent then
										Button:Destroy()
									end
									for idx, config in Var.CombinedButtonConfig do
										if config.AppName == ButtonConfig.AppName and not config.IsBuiltIn then
											table.remove(Var.CombinedButtonConfig, idx)
											break
										end
									end
									task.spawn(function()
										local invokeOk, Response = pcall(
											Var.Remotes.ManageApp.InvokeServer,
											Var.Remotes.ManageApp,
											ButtonConfig.AppName
										)
										if invokeOk and Response[1] == false then
											Frontend.Toast({
												Icon = Utilities.Icon("x"),
												Text = Utilities.Translate("generic.error.Generic"),
												Subtext = Response[2],
												Timeout = 10,
											})
										end
									end)
								end,
							},
							{
								Text = Utilities.Translate("generic.Cancel"),
								Icon = Utilities.Icon("x"),
								Callback = function(_Close)
									_Close()
								end,
							},
						}
					)
				end)
			end

			Button.Activator.MouseButton2Click:Connect(_openDeletePopup)

			if Var.Services.UserInputService.TouchEnabled then
				local holdThread = nil
				Button.Activator.InputBegan:Connect(function(Input)
					if Input.UserInputType ~= Enum.UserInputType.Touch then
						return
					end
					holdThread = task.delay(0.45, function()
						holdThread = nil
						suppressNextTap = true
						_openDeletePopup()
					end)
				end)
				Button.Activator.InputEnded:Connect(function(Input)
					if Input.UserInputType ~= Enum.UserInputType.Touch then
						return
					end
					if holdThread then
						task.cancel(holdThread)
						holdThread = nil
					end
				end)
			end
		end

		for Index, Icon in ButtonConfig.SubIcons do
			local Clone = Button.SubCollection.Object:Clone()

			Clone.Icon.Image = Icon.Icon
			Clone.Title.Text = Icon.Name

			Clone:SetAttribute("ButtonID", `{ButtonConfig.ButtonID}\\{Icon.ButtonID}`)

			Clone.Activator.MouseButton1Click:Connect(function()
				task.defer(Frontend.Drawer.Close)
				Frontend.SwapApps(ButtonConfig, Index, Clone)

				if Icon.Click ~= nil then
					xpcall(Icon.Click, Utilities.Logging.Warn)
				end
			end)

			Clone.Parent = Button.SubCollection

			task.defer(function()
				Clone.Visible = Var.Remotes.CanUseApp:InvokeServer(ButtonConfig.ButtonID)
			end)

			Clone.Name = Icon.Frame.Name

			Height += 0.23
		end

		Button.SubHierarchyLine.Size = UDim2.new(0.025, 0, Height, 0)

		ButtonConfig.ButtonRef = Button
		Utilities.Logging.Debug(
			`[DBG] AddAppDrawerButton multi: {ButtonConfig.AppName} ({ButtonConfig.ButtonID}) ref={tostring(Button)}`
		)
		return Button
	end
end

function Apps.Show(ServerURL, ID, Reason): string
	Utilities.Logging.Print("Downloading full info for that app...")

	local TI = TweenInfo.new(Var.AnimationSpeed * 2, Enum.EasingStyle.Quart)
	local Success, Data = pcall(function()
		return Var.Remotes.GetAppInfo:InvokeServer(ServerURL, ID)
	end)

	if not Success then
		Utilities.Logging.Warn(`Failed to fetch app {ID} from {ServerURL} - is the server active and responsive?`)
		Utilities.Logging.Print(Data)

		return Utilities.Translate("apps.aos.Down")
	elseif Data.Error ~= nil then
		Utilities.Logging.Warn(`AOS lookup returned external error:`, Data.Error)

		return Utilities.Translate("generic.error.Generic")
	elseif Data[2] == 404 then
		Utilities.Logging.Warn(Data[2])

		return Utilities.Translate("generic.NotFound")
	elseif Data[2] == 500 then
		Utilities.Logging.Warn(Data[2])

		return Utilities.Translate("apps.aos.InternalError")
	end

	local AppInfoFrame

	local mainFrame = Var.MainFrame
	local config = mainFrame and mainFrame.FindFirstChild and mainFrame:FindFirstChild("Configuration")
	local marketplace = config and config:FindFirstChild("Marketplace")
	local mainMarketplace = marketplace and marketplace:FindFirstChild("MainMarketplace")
	local installBox = mainMarketplace and mainMarketplace:FindFirstChild("InstallBox")
	local mainContent = installBox and installBox:FindFirstChild("MainContent")

	if not mainContent then
		local missing = {}
		if not mainFrame then
			table.insert(missing, "MainFrame")
		end
		if not config then
			table.insert(missing, "Configuration")
		end
		if not marketplace then
			table.insert(missing, "Marketplace")
		end
		if not mainMarketplace then
			table.insert(missing, "MainMarketplace")
		end
		if not installBox then
			table.insert(missing, "InstallBox")
		end
		if not installBox or not mainContent then
			table.insert(missing, "MainContent")
		end

		Utilities.Logging.Debug(
			"Apps.Show: InstallBox UI not found or malformed; missing=",
			table.concat(missing, ", ")
		)

		Frontend.Popup.new(
			{
				Name = Utilities.ToSentenceCase(Utilities.Translate("Configuration.Marketplace.Header.Head")),
				Icon = Utilities.Icon("grid"),
			},
			{
				Primary = Utilities.Icon("download"),
				SubIcon = Utilities.Icon("x"),
			},
			Data.Name or Utilities.Translate("generic.unknown"),
			Data.LongDescription or Utilities.Translate("generic.error.Generic"),
			{
				{
					Icon = Utilities.Icon("check-plain"),
					Text = Utilities.Translate("apps.install") or "Install",
					Callback = function(Close)
						local Res = Var.Remotes.InstallApp:InvokeServer(ServerURL, ID, Data.Name)
						if not Res[1] then
							Frontend.Popup.new(
								{
									Name = Utilities.ToSentenceCase(
										Utilities.Translate("Configuration.Marketplace.Header.Head")
									),
									Icon = Utilities.Icon("grid"),
								},
								{
									Primary = Utilities.Icon("warning-filled"),
									SubIcon = Utilities.Icon("x"),
								},
								Utilities.Translate("apps.load.Fail"),
								Res[2] or Utilities.Translate("generic.error.Generic"),
								{
									{
										Icon = Utilities.Icon("check-plain"),
										Text = "OK",
										Callback = function(C)
											C()
										end,
									},
								}
							)
						else
							Frontend.Toast({
								Icon = Utilities.Icon("check-plain"),
								Text = Utilities.Translate("generic.Success"),
								Subtext = Utilities.Translate("apps.installed.Body"),
								Timeout = 5,
							})
							task.defer(Apps.LoadLibrary)
						end
						Close()
					end,
				},
				{
					Icon = Utilities.Icon("x"),
					Text = Utilities.Translate("generic.Close") or "Close",
					Callback = function(Close)
						Close()
					end,
				},
			}
		)
		return true
	end

	AppInfoFrame = mainContent

	local function NewInfoBox(Icon, Title, Value)
		local NewMetaBox = AppInfoFrame.MainContent.MetadataBox.Template:Clone()

		NewMetaBox.Parent = AppInfoFrame.MainContent.MetadataBox
		NewMetaBox.Visible = true
		NewMetaBox.Name = Title

		NewMetaBox.Body.Text = Value and Value or Utilities.Translate("generic.error.Generic")
		NewMetaBox.Icon.Image = Utilities.Icon(Icon)
		NewMetaBox.Title.Text = Title
	end

	for _, Tag in AppInfoFrame.TopHeader.Details:GetChildren() do
		if Tag:GetAttribute("IsTag") then
			Tag:Destroy()
		end
	end

	for _, Box in AppInfoFrame.MainContent.MetadataBox:GetChildren() do
		if Box:IsA("Frame") and Box.Name ~= "Template" then
			Box:Destroy()
		end
	end

	for _, Box in AppInfoFrame.MainContent.PrivacyBoxSensitive:GetChildren() do
		if Box:IsA("TextLabel") and Box.Name ~= "Item" then
			Box:Destroy()
		end
	end

	for _, Box in AppInfoFrame.MainContent.PrivacyBoxInsensitive:GetChildren() do
		if Box:IsA("TextLabel") and Box.Name ~= "Item" then
			Box:Destroy()
		end
	end

	Data = Data[2]

	if Data.CannotDownload then
		Frontend.Toast({
			Text = "Invalid app",
			Subtext = "Cannot fetch MainModule, please inform the developer.",
			Timeout = 5,
			Icon = Utilities.Icon("x"),
		})

		return
	end

	NewInfoBox(
		"calendar",
		string.format(Utilities.Translate("Configuration.Marketplace.Install.Created"), ""),
		Utilities.FormatRelativeTime(Data.Metadata.CreatedAt)
	)

	NewInfoBox(
		"hourglass-wait",
		string.format(Utilities.Translate("Configuration.Marketplace.Install.Updated"), ""),
		Utilities.FormatRelativeTime(Data.Metadata.UpdatedAt)
	)

	NewInfoBox("administer", "Administer Version", Data.RichConfig.Dependencies.AppPlatform)

	NewInfoBox("house-key", "Server URL", ServerURL)

	NewInfoBox(
		"comment-code",
		"Asset Type",
		"App"
	)

	NewInfoBox("info", "Trusted", "This server is <b>trusted.</b>")

	NewInfoBox("question-circle", "AOSGenerator", Data.Metadata.AOSGenerator)

	NewInfoBox("question-circle", "App ID", Data.Metadata.AdministerID)

	if Data.IconID then
		AppInfoFrame.MainContent.MediaScroller.Template.Visible = true
		AppInfoFrame.MainContent.MediaScroller.Template.Image = `rbxassetid://{Data.IconID}`
	else
		AppInfoFrame.MainContent.MediaScroller.Template.Visible = false

		for _, Image in Data.Media do
			local NewImage = AppInfoFrame.MainContent.MediaScroller.Template:Clone()

			NewImage.Visible = true
			NewImage.Parent = AppInfoFrame.MainContent.MediaScroller
			NewImage.Name = Image

			NewImage.Image = `rbxassetid://{Image}`
		end
	end

	AppInfoFrame.TopHeader.MediaBackdrop.Image = `rbxassetid://{Data.BlurredIcon}`
	AppInfoFrame.TopHeader.Details.Downloads.Value.Text = Utilities.ShortNumber(Data.Downloads)

	local Modules = { Sensitive = {}, Insensitive = {} }
	for _, Dependency in Data.RichConfig.Dependencies.AdministerModules do
		if table.find({ "AdminRunner", "Apps" }, Dependency.Name) ~= nil then
			table.insert(Modules.Sensitive, Dependency.Name)
		else
			table.insert(Modules.Insensitive, Dependency.Name)
		end
	end

	if Modules.Sensitive == {} then
		Modules.Sensitive = {
			string.format(
				Utilities.Translate("apps.sensitivity.DoesNotUse"),
				Utilities.Translate("apps.sensitivity.Sensitive")
			),
		}
	end

	if Modules.Insensitive == {} then
		Modules.Insensitive = {
			string.format(
				Utilities.Translate("apps.sensitivity.DoesNotUse"),
				Utilities.Translate("apps.sensitivity.Insensitive")
			),
		}
	end

	for _, SensitiveModule in Modules.Sensitive do
		local NewSensitivity = AppInfoFrame.MainContent.PrivacyBoxSensitive.Item:Clone()

		NewSensitivity.Name = SensitiveModule
		NewSensitivity.Visible = true
		NewSensitivity.Parent = AppInfoFrame.MainContent.PrivacyBoxSensitive

		NewSensitivity.Text = SensitiveModule
	end

	for _, SensitiveModule in Modules.Insensitive do
		local NewSensitivity = AppInfoFrame.MainContent.PrivacyBoxInsensitive.Item:Clone()

		NewSensitivity.Name = SensitiveModule
		NewSensitivity.Visible = true
		NewSensitivity.Parent = AppInfoFrame.MainContent.PrivacyBoxInsensitive

		NewSensitivity.Text = SensitiveModule
	end

	AppInfoFrame.TopHeader.Details.Creator.Icon.Image = Var.Services.Players:GetUserThumbnailAsync(
		Data.Developer.ID,
		Enum.ThumbnailType.HeadShot,
		Enum.ThumbnailSize.Size180x180
	)

	AppInfoFrame.TopHeader.Details.Creator.Value.Text = `@{Data.Developer.Name}`

	for _, TagData in Data.Tags do
		local Tag = AppInfoFrame.TopHeader.Details.TagTemplate:Clone()

		Tag.Value.Text = TagData
		Tag.Name = TagData
		Tag.Visible = true
		Tag.Parent = AppInfoFrame.TopHeader.Details

		Tag:SetAttribute("IsTag", true)
	end

	AppInfoFrame.TopHeader.AppIcon.AppName.Text = Data.Name
	AppInfoFrame.TopHeader.AppIcon.Subheader.Text = Data.Title
	AppInfoFrame.MainContent.Description.Text = Data.LongDescription

	AppInfoFrame.TopHeader.Details.Votes.Dislikes.Value.Text = Utilities.ShortNumber(Data["Votes"]["Dislikes"])
	AppInfoFrame.TopHeader.Details.Votes.Likes.Value.Text = Utilities.ShortNumber(Data["Votes"]["Likes"])
	AppInfoFrame.TopHeader.Details.Favorites.Value.Text = Utilities.ShortNumber(Data["Votes"]["Favorites"])

	local Percent = tonumber(Data["Votes"]["Likes"])
		/ (tonumber(Data["Votes"]["Dislikes"]) + tonumber(Data["Votes"]["Likes"]))

	Connections.DownloadClick = AppInfoFrame.TopHeader.Details.Downloads.MouseButton1Click:Connect(function()
		if Data.CannotDownload then
			Frontend.Toast({
				Icon = Utilities.Icon("triangle-warning"),
				Text = "Downloads disabled",
				Subtext = "This app may not be downloaded at this time",
				Timeout = 10,
			})

			return
		end

		local Shimmer = Shime.new(AppInfoFrame.TopHeader.Details.Downloads)

		Shimmer:Play()

		AppInfoFrame.TopHeader.Details.Downloads.Value.Text = Utilities.Translate("generic.Loading") .. "..."
		AppInfoFrame.TopHeader.Details.Downloads.Icon.Image = Utilities.Icon("hourglass-wait")

		local Res = Var.Remotes.InstallApp:InvokeServer(ServerURL, ID, Data.Name)

		AppInfoFrame.TopHeader.Details.Downloads.Icon.Image = Utilities.Icon("download")

		if not Res[1] then
			Frontend.Popup.new(
				{
					Name = Utilities.ToSentenceCase(Utilities.Translate("Configuration.Marketplace.Header.Head")),
					Icon = Utilities.Icon("grid"),
				},
				{
					Primary = Utilities.Icon("warning-filled"),
					SubIcon = Utilities.Icon("x"),
				},
				Utilities.Translate("apps.load.Fail"),
				Res[2],
				{
					{
						Icon = Utilities.Icon("check-plain"),
						Text = "OK",
						Callback = function(Close)
							Close()
						end,
					},
				}
			)
		else
			Frontend.Toast({
				Icon = Utilities.Icon("check-plain"),
				Text = Utilities.Translate("generic.Success"),
				Subtext = Utilities.Translate("apps.installed.Body"),
				Timeout = 5,
			})

			task.defer(Apps.LoadLibrary)
		end

		task.delay(2, function()
			AppInfoFrame.TopHeader.Details.Downloads.Value.Text = Utilities.ShortNumber(Data.Downloads)
		end)

		Shimmer:Pause()
		Shimmer:GetFrame():Destroy()
	end)

	local _conf = getConf()
	if _conf then
		_conf.Marketplace.MainMarketplace[Var.Marketplace.ActivePage].Visible = false
	end
	AppInfoFrame.Parent.Visible = true

	Var.Services.TweenService
		:Create(AppInfoFrame.TopHeader.Details.Votes.VotePercentage, TI, { Size = UDim2.fromScale(Percent, 1) })
		:Play()

	if not AppInfoFrame.TopHeader.Details.Votes.Likes:FindFirstChild("TextButton") then
		for i = 1, 2 do
			local Button = Instance.new("TextButton")

			Button.BackgroundTransparency = 1
			Button.Size = UDim2.fromScale(1, 1)
			Button.Text = ""

			Button.Parent = (
				i == 1 and AppInfoFrame.TopHeader.Details.Votes.Likes or AppInfoFrame.TopHeader.Details.Votes.Dislikes
			)
		end
	end

	local IsVoting = false
	local function DoVote(VoteType)
		if IsVoting then
			Frontend.Toast({
				Icon = Utilities.Icon("triangle-warning"),
				Text = "Too many requests",
				Subtext = "Please slow down.",
				Timeout = 3,
			})

			return
		end

		IsVoting = true

		local Response = Var.Remotes.Vote:InvokeServer(ServerURL, ID, VoteType)

		if Response.StatusCode == 400 then
			Frontend.Toast({
				Icon = Utilities.Icon("triangle-warning"),
				Text = Var.Services.HttpService:JSONDecode(Response.Body).message,
				Subtext = Var.Services.HttpService:JSONDecode(Response.Body).user_facing_message,
				Timeout = 10,
			})
		end

		for _, Event in Connections do
			Event:Disconnect()
		end

		IsVoting = false

		return Apps.Show(ServerURL, ID, Reason)
	end

	Connections.LikeButton = AppInfoFrame.TopHeader.Details.Votes.Likes.TextButton.MouseButton1Click:Connect(function()
		DoVote(1)
	end)

	Connections.DislikeButton = AppInfoFrame.TopHeader.Details.Votes.Dislikes.TextButton.MouseButton1Click:Connect(
		function()
			DoVote(0)
		end
	)

	return true
end

function Apps.Clear(): ()
	for _, Connection in Connections do
		(Connection :: RBXScriptConnection):Disconnect()
	end

	local _conf = getConf()
	for _, Item in (_conf and _conf.Marketplace.MainMarketplace.Content or {}):GetChildren() do
		if Item:IsA("Frame") and Item.Name ~= "Template" then
			Item:Destroy()
		end
	end
end

function Apps.Search(Query: string, ServerURL: string?): {}
	local Result =
		Var.Remotes.AOSRichSearch:InvokeServer(ServerURL or Var.Remotes.GetPrimaryServer:InvokeServer(), Query)

	local Final: { { Type: string, Value: any } } = {}

	if Result.index == "no_results" then
		return {
			Success = false,
			Data = {
				{
					Type = "text",
					Value = Utilities.Translate("apps.search.NoResults"),
				},
			},
			AOSProcessedInfo = Result.meta._aos_search_api,
		}
	elseif Result.meta.ratio_info.is_ratio == true then
		table.insert(Final, {
			Type = "text",
			Value = string.format(
				Utilities.Translate("apps.search.FoundMatch"),
				Result.meta.ratio_info.keyword,
				string.sub(string.gsub(Result.meta.ratio_info.confidence, "0.", ""), 1, 2) .. "%"
			),
		})
	end

	for Index, SearchResult in Result.index do
		table.insert(Final, {
			Type = "card",
			Value = SearchResult,
		})
	end

	return {
		Success = true,
		Data = Final,
		AOSProcessedInfo = Result.meta._aos_search_api,
	}
end

local InProgress = false

function Apps.LoadAppList(List: {}?): ()
	local Market = getConf() and getConf().Marketplace
	if not Market then
		Utilities.Logging.Warn("Apps.LoadAppList: could not resolve Marketplace, aborting")
		return
	end

	if List == {} then
		return
	end

	Utilities.Logging.Print("Refreshing app list...")

	if InProgress then
		Frontend.Toast({
			Icon = Utilities.Icon("triangle-warning"),
			Text = Utilities.Translate("apps.load.Fail"),
			Subtext = Utilities.Translate("apps.load.Ratelimit"),
			Timeout = 10,
		})

		Utilities.Logging.Warn("You're clicking too fast or your app servers are unresponsive! Please slow down.")

		Market.MainMarketplace[Var.Marketplace.ActivePage].Visible = false
		Var.Marketplace.ActivePage = "MPFrozen"

		Market.MainMarketplace.MPFrozen.Visible = true
		Market.MainMarketplace.MPFrozen.Subheading1.Text = string.gsub(
			Utilities.Translate("Configuration.Marketplace.MPFrozen.Subheading1"),
			"{{ }}",
			"debounce triggered, AOS is unresponsive. try again in 5-10 seconds"
		)

		return
	end

	InProgress = true

	task.delay(5, function()
		InProgress = false
	end)

	for Name, Connection in Connections do
		Connection:Disconnect()
		Connections[Name] = nil
	end

	local function Card(CardData, ListLoc)
		xpcall(function()
			local NewCard: Instance = ListLoc.Template:Clone()
			NewCard.Parent = ListLoc
			NewCard.Name = CardData.name
			NewCard.Visible = true

			NewCard.ObjName.Text = CardData.name
			NewCard.Server.Text = string.format(
				Utilities.Translate("Configuration.Apps.Description"),
				`{string.sub(CardData.short_desc, 1, 50)}{string.len(CardData.short_desc) >= 50 and "..." or ""}`,
				Utilities.ToSentenceCase(CardData.object_type),
				CardData.developer.Name,
				CardData.ServerName
			)

			NewCard.Stats.Downloads.Label.Text = Utilities.ShortNumber(CardData.downloads)

			NewCard.Stats.Rating.Label.Text = tostring(CardData.rating) == "1" and "100%"
				or string.sub(string.gsub(tostring(CardData.rating), "0.", ""), 1, 2) .. "%"

			NewCard.Stats.Rating.ImageLabel.Image = Utilities.Icon("like")
			NewCard.Stats.DownloadButton.Server.Text = Utilities.Translate("generic.Install")

			Connections[`Download-{math.random(1, 2 ^ 25)}`] = NewCard.Stats.DownloadButton.MouseButton1Click:Connect(
				function()
					local Shimmer = Shime.new(NewCard.Stats.DownloadButton)
					Shimmer:Play()

					xpcall(function()
						local ShowResult = Apps.Show(CardData.Server, CardData.id, CardData.Server)

						if ShowResult ~= true then
							Frontend.Toast({
								Icon = Utilities.Icon("triangle-warning"),
								Text = Utilities.Translate("apps.load.Fail"),
								Subtext = ShowResult,
								Timeout = 10,
							})
						end
					end, function(e)
						Utilities.Logging.Warn(e)
						Frontend.Toast({
							Icon = Utilities.Icon("triangle-warning"),
							Text = Utilities.Translate("generic.error.Generic"),
							Subtext = e,
							Timeout = 15,
						})
					end)

					Shimmer:Pause()
					Shimmer:GetFrame():Destroy()
				end
			)

			Connections[`Show-{math.random(1, 2 ^ 25)}`] = NewCard.Stats.DownloadButton.MouseButton2Click:Connect(
				function()
					Frontend.Popup.new(
						{
							Icon = Utilities.Icon("grid"),
							Header = Utilities.Translate("Configuration.Marketplace.Header.Head"),
							Subheader = "AOS Instance",
						},
						{
							Primary = Utilities.Icon("administer"),
							SubIcon = Utilities.Icon("question-circle"),
						},
						"App Info",
						`AOS Data URL: {CardData.Server}\nAOSId2: {CardData.id}\nWeighted Score: {CardData.weighted_score}\nObject Type: {CardData.object_type}\nDeveloper: {game
							:GetService("HttpService")
							:JSONEncode(CardData.developer)}`,
						{
							{
								Text = "OK",
								Icon = "check-plain",
								Callback = function(c)
									c()
								end,
							},
						}
					)
				end
			)
		end, function(e)
			if e == "Unable to assign property Name. string expected, got nil" then
				Utilities.Logging.Print(`Server spent {CardData}s processing apps!`)
			else
				Utilities.Logging.Error(e)
			end
		end)
	end

	local AppList = List or Var.Remotes.GetAppList:InvokeServer(Var.Marketplace.ActivePageType)

	if AppList == nil or type(AppList) ~= "table" then
		Frontend.Toast({
			Icon = Utilities.Icon("warning-circle"),
			Text = "Failed to load apps",
			Subtext = "Please try again",
			Timeout = 5,
		})
		return
	end

	if Var.Marketplace.ActivePage == "AAFeatured" then
		local Featured = {}
		local Index = 1

		for _, Item in Market.MainMarketplace.AAFeatured.TopGrid:GetChildren() do
			if Item:IsA("CanvasGroup") and Item.Name ~= "Template" then
				Item:Destroy()
			end
		end

		repeat
			for SUrl, Server in AppList do

				if Server[Index] == nil then
				else
					table.insert(Featured, Server[Index])
				end
			end

			Index += 1
		until #Featured == 4 or Index == 30

		for _, App in Featured do
			Card(App, Market.MainMarketplace.AAFeatured.TopGrid)
		end

		local TopCard = Market.MainMarketplace.AAFeatured.MainHot
		local Selected = Featured[1]

		if Selected == nil or type(Selected) ~= "table" then
			return
		end

		TopCard.ObjName.Text = Selected.name
		TopCard.Stats.Installs.Label.Text = Utilities.ShortNumber(Selected.downloads)
		TopCard.ImageLabel.Image = `rbxassetid://{Selected.image_id}`

		TopCard.Stats.Rating.Label.Text = tostring(Selected.rating) == "1" and "100%"
			or string.sub(string.gsub(tostring(Selected.rating), "0.", ""), 1, 2) .. "%"
		TopCard.Server.Text = string.format(
			Utilities.Translate("Configuration.Apps.Description"):gsub("%%s\n\n", ""),
			Utilities.ToSentenceCase(Selected.object_type),
			Selected.developer.Name,
			Selected.ServerName
		)

		TopCard.Stats.DownloadButton.MouseButton1Click:Connect(function()
			Apps.Show(Selected.Server, Selected.id, Selected.Server)
		end)

		TopCard.Stats.DownloadButton.MouseButton2Click:Connect(function()
			Frontend.Popup.new(
				{
					Icon = Utilities.Icon("grid"),
					Name = Utilities.Translate("Configuration.Marketplace.Header.Head"),
					Subheader = "AOS",
				},
				{
					Primary = Utilities.Icon("grid"),
					SubIcon = Utilities.Icon("question-circle"),
				},
				Utilities.Translate("apps.score.Detail"),
				string.gsub(
					string.format(Utilities.Translate("apps.score.Body"), Selected.ServerName, Selected.weighted_score),
					"{}",
					Selected.Server
				),
				{
					{
						Text = Utilities.Translate("generic.OK"),
						Icon = "check",
						Callback = function(c)
							c()
						end,
					},
				}
			)
		end)
	else
		local Featured = {}
		local Index = 1

		for _, Item in Market.MainMarketplace.CardGrid:GetChildren() do
			if Item:IsA("CanvasGroup") and Item.Name ~= "Template" then
				Item:Destroy()
			end
		end

		for SUrl, Server in AppList do
			for _, App in Server do
				table.insert(Featured, App)
			end
		end

		for _, App in Featured do
			Card(App, Market.MainMarketplace[Var.Marketplace.ActivePage])
		end
	end

	if AppList[1] == false then
		Utilities.Logging.Warn("Failed to fetch!", AppList)

		Market.MainMarketplace[Var.Marketplace.ActivePage].Visible = false
		Var.Marketplace.ActivePage = "MPFrozen"

		Market.MainMarketplace.MPFrozen.Visible = true
		Market.MainMarketplace.MPFrozen.Subheading1.Text = string.format(
			Utilities.Translate("Configuration.Marketplace.MPFrozen.Subheading1"),
			"ETIMEOUT",
			"/api/directory"
		)

		return
	end

	InProgress = false
end

function Apps.InitSerarchbar()
	local MP = getConf() and getConf().Marketplace
	if not MP then
		Utilities.Logging.Warn("Apps.InitSerarchbar: could not resolve Marketplace, aborting")
		return
	end

	MP.ASidebar.Searchbar.Input:GetPropertyChangedSignal("Text"):Connect(function()
		MP.ASidebar.Searchbar.Title.Text = MP.ASidebar.Searchbar.Input.Text
	end)

	MP.ASidebar.Searchbar.Input.FocusLost:Connect(function(EnterPressed: boolean, ...)
		if not EnterPressed then
			return
		end

		local Shimmer = Shime.new(MP.ASidebar.Searchbar)
		Shimmer:Play()

		MP.MainMarketplace.MPFrozen.Visible = false

		local Cards = {}
		local ServerURL = Var.Remotes.GetPrimaryServer:InvokeServer()
		local SearchResult = Apps.Search(MP.ASidebar.Searchbar.Input.Text)

		for _, Data in SearchResult.Data do
			if Data.Type == "text" then
				Frontend.Toast({
					Icon = "search",
					Text = Utilities.Translate("Configuration.MenuBar.New.AInfoPage.HeaderLabel"),
					Subtext = Data.Value,
					Timeout = 5,
				})
			else
				local data = Data.Value
				local rating = data.Votes.Likes / (data.Votes.Likes + data.Votes.Dislikes)

				table.insert(Cards, {
					name = data.Name,
					short_desc = data.ShortDescription,
					downloads = data.Downloads,
					rating = rating,
					weighted_score = (data.Downloads * 0.6 + (rating * 0.9)) + data.Votes.Favorites,
					developer = data.Developer,
					last_update = data.Metadata.UpdatedAt,
					id = data.Metadata.AdministerID,
					object_type = data.Metadata.AssetType,
					image_id = data.IconID,
					Server = ServerURL,
				})
			end
		end

		Shimmer:Pause()
		Shimmer:GetFrame():Destroy()

		if #Cards == 0 then
			return
		end

		MP.MainMarketplace[Var.Marketplace.ActivePage].Visible = false
		Var.Marketplace.ActivePage = "CardGrid"
		MP.MainMarketplace.CardGrid.Visible = true

		Cards = {
			[ServerURL] = Cards,
		}

		Apps.LoadAppList(Cards)
	end)
end

local IsLibraryLoading = false

function Apps.LoadLibrary()
	if IsLibraryLoading then
		return
	end

	IsLibraryLoading = true

	local ok, err = pcall(function()
		local _conf = getConf()
		if not _conf then
			error("getConf() returned nil — Configuration not found")
		end
		local AppsMenu = _conf.Marketplace.MainMarketplace.XLibrary
		for i, AppItem: Instance in AppsMenu.Content:GetChildren() do
			if not AppItem:IsA("CanvasGroup") or AppItem.Name == "Template" or AppItem.Name == "ServerTemplate" then
				continue
			end
			AppItem:Destroy()
		end

		Apps.Init(true)

		local AppsList = Var.Remotes.GetInstalledApps:InvokeServer("Bootstrapped")

		for k, App in AppsList[2] do
			local NewTemplate = AppsMenu.Content.Template:Clone()

			NewTemplate.AppName.Text = k
			NewTemplate.Name = k
			NewTemplate.Logo.Image = App["Icon"]
			NewTemplate.AppShortDesc.Text = App["Description"]
			NewTemplate.InstallDate.Text = string.format(
				Utilities.Translate("Configuration.Apps.Content.Template.InstallDate"),
				App["InstalledSince"] ~= 0 and Utilities.FormatRelativeTime(App["InstalledSince"])
					or Utilities.Translate("generic.Locally")
			)

			if not Var.EnableEditableImages then
				NewTemplate.BackgroundImage.Image = `rbxassetid://{App["Icon"]}`
			else
				NewTemplate.BackgroundImage.ImageContent = Content.fromObject(
					require(script.Parent.Parent.Libraries.QuickBlur):Blur(
						Var.Services.AssetService:CreateEditableImageAsync(`rbxassetid://{App["Icon"]}`),
						10,
						6
					)
				)
			end

			NewTemplate.Buttons.LongText.Title.Text = `{math.round(App.BuildTime * 1000)}ms`

			NewTemplate.Parent = AppsMenu.Content
			NewTemplate.Visible = true

			NewTemplate.Buttons.Delete.MouseButton1Click:Connect(function()
				Frontend.Popup.new(
					{
						Name = Utilities.Translate("Configuration.Marketplace.Header.Head"),
						Icon = Utilities.Icon("administer"),
					},
					{
						Primary = `rbxassetid://{App["Icon"]}`,
						SubIcon = Utilities.Icon("warning-filled"),
					},
					Utilities.Translate("Configuration.Apps.MessageBox.Header"):format(k),
					Utilities.Translate("Configuration.Apps.MessageBox.Content"),
					{
						{
							Text = Utilities.Translate("generic.Yes"),
							Icon = Utilities.Icon("trash"),
							Callback = function(_Close)
								_Close()
								local Response = Var.Remotes.ManageApp:InvokeServer(App.AppID)
								if Response[1] == false then
									Frontend.Popup.new(
										{
											Name = "Administer",
											Icon = Utilities.Icon("administer"),
										},
										{
											Primary = `rbxassetid://{App["Icon"]}`,
											SubIcon = Utilities.Icon("x"),
										},

										Utilities.Translate("generic.error.Generic"),
										Response[2],

										{
											{
												Text = Utilities.Translate("generic.OK"),
												Icon = Utilities.Icon("check-plain"),
												Callback = function(Cls)
													Cls()
												end,
											},
										}
									)
								else
									Utilities.Logging.Warn(
										`[DBG] LoadLibrary delete: k={k} AppID={tostring(App.AppID)} CombinedButtonConfig#={#Var.CombinedButtonConfig}`
									)
									local found = false
									for idx, config in Var.CombinedButtonConfig do
										Utilities.Logging.Warn(
											`[DBG] config[{idx}] name={config.AppName} isBuiltIn={tostring(
												config.IsBuiltIn
											)} hasRef={tostring(config.ButtonRef ~= nil)}`
										)
										if config.AppName == k and not config.IsBuiltIn then
											Utilities.Logging.Warn(`[DBG] matched config[{idx}] -> destroying`)
											RemoveDrawerButton(k)
											table.remove(Var.CombinedButtonConfig, idx)
											found = true
											break
										end
									end
									if not found then
										Utilities.Logging.Warn(
											"[DBG] no match in CombinedButtonConfig; AppsHolder children:"
										)
										local AppsHolder = Var.MainFrame.AppDrawer.AppHolder.Apps
										for i, child in AppsHolder:GetChildren() do
											Utilities.Logging.Warn(
												`[DBG]   [{i}] name={child.Name} ButtonID={tostring(
													child:GetAttribute("ButtonID")
												)}`
											)
										end
									end
									NewTemplate:Destroy()
									Apps.LoadLibrary()
								end
							end,
						},
						{
							Text = Utilities.Translate("generic.Cancel"),
							Icon = Utilities.Icon("x"),
							Callback = function(_Close)
								_Close()
							end,
						},
					}
				)
			end)
		end

		local AppServers = Var.Remotes.GetAppServers:InvokeServer()

		local NextButton = AppsMenu.Content.ServerTemplate:Clone()
		xpcall(function()
			NextButton.ServerName.Text = "Next"
			NextButton.Name = "GatewayNextButton"
			NextButton.Metadata.Text = "Automatic failover through gateway"
			NextButton.BackgroundImage.BackgroundColor3 = Color3.fromHex("4CAF50")
			NextButton.Buttons.LongText.Title.Text = "⚡ Use Gateway (Auto-Failover)"
			NextButton.Buttons.LongText.Icon.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
		end, function()
			NextButton.ServerName.Text = "Next"
			NextButton.Name = "GatewayNextButton"
			NextButton.Buttons.LongText.Title.Text = "⚡ Use Gateway"
		end)

		NextButton.Parent = AppsMenu.Content
		NextButton.Visible = true

		local GatewayActionBtn = NextButton.Buttons.Delete
		GatewayActionBtn.MouseButton1Click:Connect(function()
			Var.Remotes.SetPrimaryAppServer:InvokeServer("https://gate.admsoftware.workers.dev")
			Frontend.Toast({
				Icon = Utilities.Icon("check-circle"),
				Text = "Connected via Gateway",
				Subtext = "Using automatic failover",
				Timeout = 5,
			})
		end)
	end)

	if not ok then
		Utilities.Logging.Warn("LoadLibrary encountered an error:", tostring(err))
	end

	IsLibraryLoading = false
end

function Apps.Init(JustRefreshCounts)
	local _initConf = getConf()
	if not Var.MainFrame or not _initConf then
		Utilities.Logging.Warn("Apps.Init: MainFrame or Configuration not accessible yet, skipping")
		return
	end

	local Sidebar = _initConf.Marketplace.ASidebar
	local Counts = Var.Remotes.GetAppCounts:InvokeServer()

	Sidebar.Buttons.XLibrary.Resources.Content.Apps.Text =
		string.format(Utilities.Translate("apps.library.Detail"), Counts.Apps, Counts.Servers)

	if JustRefreshCounts then
		return
	end

	local ActiveApps = Var.Remotes.GetInstalledApps:InvokeServer("Combined")

	for _, Button in Sidebar.Buttons:GetChildren() do
		local Watcher = Instance.new("TextButton")
		Watcher.BackgroundTransparency = 1
		Watcher.Text = ""
		Watcher.Parent = Button

		Watcher.Size = UDim2.new(1, 0, 1, 0)
		Watcher.Position = UDim2.new(0, 0, 0, 0)

		Watcher.MouseButton1Click:Connect(function()
			xpcall(function()
				local marketplace = Sidebar.Parent
				local mainMarketplace = marketplace and marketplace:FindFirstChild("MainMarketplace")
				if not mainMarketplace then
					Utilities.Logging.Debug("Apps.Init: Sidebar click - MainMarketplace missing, ignoring")
					return
				end

				if mainMarketplace:FindFirstChild("InstallBox") then
					mainMarketplace.InstallBox.Visible = false
				end
				if mainMarketplace:FindFirstChild("MPFrozen") then
					mainMarketplace.MPFrozen.Visible = false
				end

				if mainMarketplace:FindFirstChild(Var.Marketplace.ActivePage) then
					mainMarketplace[Var.Marketplace.ActivePage].Visible = false
				end

				Var.Marketplace.ActivePage = Button.Name
				Var.Marketplace.ActivePageType = Button.Name:upper()

				if Button.Name == "Themes" or Button.Name == "Apps" then
					Var.Marketplace.ActivePage = "CardGrid"
					Var.Marketplace.ActivePageType = Button.Name

					Apps.LoadAppList()
				elseif Button.Name == "AAFeatured" then
					Var.Marketplace.ActivePageType = "FEATURED"

					Apps.LoadAppList()
				elseif Button.Name == "XLibrary" then
					Apps.LoadLibrary()
				end

				if mainMarketplace:FindFirstChild(Var.Marketplace.ActivePage) then
					mainMarketplace[Var.Marketplace.ActivePage].Visible = true
				end
			end, function(err)
				Utilities.Logging.Warn("Apps.Init: Sidebar click handler failed:", tostring(err))
			end)
		end)
	end

	Sidebar.Parent.MainMarketplace.XLibrary.AdministerLogo.Image = Utilities.Icon("administer")
	Sidebar.Parent.MainMarketplace.XLibrary.GameArt.Image = Var.Remotes.GetGameArt:InvokeServer()

	Sidebar.Parent.MainMarketplace.XLibrary.SubHeader.TextButton.MouseButton1Click:Connect(function()
		local _c = getConf()
		Frontend.SwapAppBasic(_c and _c.Admins, {
			Name = Utilities.Translate("Configuration.Admins.Container.Admins.Header.TLabel"),
			Icon = Utilities.Icon("user-clip"),
		})
	end)

	Sidebar.Parent.MainMarketplace.XLibrary.InstallAOSInstance.MouseButton1Click:Connect(function()
		Frontend.Popup.new(
			{
				Icon = Utilities.Icon("administer"),
				Name = "Administer",
				Subheader = `AOS {Utilities.Translate("generic.Registration")}`,
			},
			{
				Primary = Utilities.Icon("network"),
				SubIcon = Utilities.Icon("chain"),
			},

			Utilities.Translate("apps.aos.install.Detail"),
			Utilities.Translate("apps.aos.install.Body"),

			{
				{
					Text = Utilities.Translate("generic.Exit"),
					Icon = Utilities.Icon("no-entry"),
					Callback = function(Close)
						Close()
					end,
				},
				{
					Text = Utilities.Translate("generic.Done"),
					Icon = Utilities.Icon("floppy-disk"),
					Callback = function(Close, TextInputs)
						Close()

						local ServerURL = TextInputs[1]
						local Result =
							Var.Remotes.InstallServer:InvokeServer(ServerURL, game.Players.LocalPlayer.UserId)

						if Result[1] then
							Result = Var.Remotes.RegisterPrimaryAOS:InvokeServer(ServerURL)

							Frontend.Popup.new(
								{
									Icon = Utilities.Icon("administer"),
									Name = "Administer",
									Subheader = `AOS {Utilities.Translate("generic.Registration")}`,
								},
								{
									Primary = Utilities.Icon("network"),
									SubIcon = Utilities.Icon(Result[1] and "check-plain" or "x"),
								},
								Result[1] and Utilities.Translate("generic.Success")
									or Utilities.Translate("generic.errors.Generic"),
								Result[1] and Utilities.Translate("apps.addserver.OK")
									or Utilities.Translate("apps.addserver.Failed"),
								{
									{
										Text = Utilities.Translate("generic.OK"),
										Icon = Utilities.Icon("check-plain"),
										Callback = function(Close)
											Close()
										end,
									},
								}
							)
						else
							Frontend.Popup.new(
								{
									Icon = Utilities.Icon("administer"),
									Name = "Administer",
									Subheader = "AOS Registration",
								},
								{
									Primary = Utilities.Icon("network"),
									SubIcon = Utilities.Icon("question-circle"),
								},
								"Invalid server",
								Utilities.Translate("apps.server.NotAdminister") .. Result[2],
								{
									{
										Text = "OK",
										Icon = Utilities.Icon("check-plain"),
										Callback = function(Close)
											Close()
										end,
									},
								}
							)
						end
					end,
				},
			},
			{ {
				HeaderText = "Server URL (https://aos-us-1.admsoftware.org)",
			} }
		)
	end)

	Apps.InitSerarchbar()
	task.defer(Apps.LoadAppList)
end

return Apps
