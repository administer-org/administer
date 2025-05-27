--// pyxfluff 2025

local Modules = script.Parent
local Libs = script.Parent.Parent.Libraries

local Utilities = require(Modules.Utilities)
local Frontend = require(Modules.Frontend)
local Var = require(Modules.Variables)

local Admins = {}
local Connections: { RBXScriptConnection } = {}

local RanksFrame = Var.MainFrame.Configuration.Admins.Container.Ranks.Content
local Frames = Var.MainFrame.Configuration.Admins.NewAdmin

local TweenService = Var.Services.TweenService

function Admins.Load(): ()
	for _, Item in RanksFrame:GetChildren() do
		if Item:IsA("Frame") and Item.Name ~= "Template" then Item:Destroy() end
	end

	for _, Connection in Connections do
		Connection:Disconnect()
	end

	Connections = {}

	local Shimmer1 = require(Libs.Shime).new(Var.MainFrame.Configuration.Admins.Container.Ranks)

	Shimmer1:Play()

	task.defer(function()
		local List
		
		xpcall(function()
			List = Var.Remotes.GetRanks:InvokeServer()
		end, function(e)
			Frontend.Popup.new(
				{
					Icon = `rbxassetid://{Var.Icons["logos"]["administer-blue"]}`,
					Name = "Access Control",
					Subheader = "Error"
				}, {
					Primary = Utilities.Icon "user",
					SubIcon = Utilities.Icon "triangle-warning"
				},
				"Improper Rank Configuration Detected",
				`Administer has detected an error in the rank configuration. This is most likely due to an incomplete setup process and will result in Administer not loading out of Studio. Please re-initialize Administer.\n{e}`,
				{
					{
						Text = "Ok",
						Icon = Utilities.Icon "check-plain",
						Callback = function(c)
							c()
						end
					}
				}
			)
			
			List = {}
		end)

		if typeof(List) == "string" then
			Utilities.Logging.Warn(`Failed: {List}`)

			return "Something went wrong"
		else
			for i, v in List do
				local Template = RanksFrame.Template:Clone()

				Template.Name = v.Name
				Template.RankName.Text = v.Name
				Template.Info.Text =
					`{v.RankID} • {v.Apps.SuperAdmin and "Full Access" or #v.Apps .. " apps"}{v.Protected and " • Protected" or ""} • {v.CreationReason} • Created {Utilities.FormatRelativeTime(v.Modified)}`
				
				if v.Apps.SuperAdmin then
					local Card = Template.Pages.Frame:Clone()

					Card.Visible = true
					Card.AppName.Text = "Super Administrator"
					Card.ImageLabel.Image = Utilities.Icon "user-shield"
					Card.Parent = Template.Pages
				end
				
				local UsableAppInfo = {}
				local AppCount = 0
				
				for App, IsVisible in v.Apps do
					if App == "CachedData" or App == "AdmHomepage" or App == "SuperAdmin" then continue end
					
					if IsVisible then
						AppCount += 1
						table.insert(UsableAppInfo, v.Apps.CachedData[App])
					end
				end

				if AppCount > 6 then
					for j = 1, 5 do
						if type(v.Apps[j]) == "boolean" then continue end
						
						local Card = Template.Pages.Frame:Clone()

						Card.Visible = true
						Card.AppName.Text = UsableAppInfo[j].Name
						Card.ImageLabel.Image = UsableAppInfo[j].Icon
						Card.Parent = Template.Pages
					end

					local Card = Template.Pages.Frame:Clone()
					Card.Visible = true
					Card.AppName.Text = `{AppCount - 5} others...`
					Card.Parent = Template.Pages
				else
					for k, App in UsableAppInfo do
						if type(App) == "boolean" then continue end
						
						local Card = Template.Pages.Frame:Clone()

						Card.Visible = true
						Card.AppName.Text = App.Name
						Card.ImageLabel.Image = App.Icon
						Card.Parent = Template.Pages
					end
				end

				xpcall(function()
					Template.ColorBG.BackgroundColor3 = Color3.fromHex(`#{v.Color}`)
				end, function()
					--// Invalid hex code
					Template.ColorBG.BackgroundColor3 = Color3.new(0.239, 0.643, 1)
				end)

				Template.Parent = RanksFrame
				Template.Visible = true

				local UserNames = {}

				for i = 1, 3 do
					local User = v.Members[i]

					if User == nil then break end
					if User.MemberType == "User" then
						Template.ProfilePictures[i].Visible = true
						Template.ProfilePictures[i].Image = Var.Services.Players:GetUserThumbnailAsync(
							User.ID,
							Enum.ThumbnailType.HeadShot,
							Enum.ThumbnailSize.Size100x100
						)

						table.insert(UserNames, Var.Services.Players:GetNameFromUserIdAsync(User.ID))
					else
						local _, GroupInfo = pcall(function()
							return game:GetService("GroupService"):GetGroupInfoAsync(User.ID)
						end)

						xpcall(function()
							Template.ProfilePictures[i].Image = GroupInfo.EmblemUrl
							Template.ProfilePictures[i].Visible = true

							Template.ProfilePictures[i].UICorner.CornerRadius = UDim.new(0, 4)
						end, function()
							--// do nothing? idk if i do i - 1 itll cause a loop so FIXME..?
						end)

						table.insert(UserNames, GroupInfo.Name)
					end
				end

				Template.MembersText.Text = (
					#UserNames == 3 and `<b>{UserNames[1]}</b>, <b>{UserNames[2]}</b>, <b>{UserNames[3]}</b>, and <b>{#v.Members - 3} {#v.Members - 3 == 1 and "other is a member" or "are members"}</b>`
						or #UserNames == 2 and `<b>{UserNames[1]}</b> and <b>{UserNames[2]}</b> are members`
						or `<b>{UserNames[1]}</b> is a member`
				)
			end
		end

		Shimmer1:Pause()
		Shimmer1:GetFrame():Destroy()
	end)
end

local Page = 1

local function SwapPages(Page1, Page2, NewIcon, Spin, PageNumber)
	if type(Spin) == "number" then PageNumber = Spin end

	Page = PageNumber
	local TTC = 0.4

	local Tweem = TweenService:Create(
		Page1,
		TweenInfo.new(TTC * 1.3, Enum.EasingStyle.Cubic),
		{ Position = UDim2.new(-0.5, 0, 0, 0), GroupTransparency = 1 }
	)

	Tweem:Play()
	TweenService:Create(
		Frames.SideDecor.ImageLabel,
		TweenInfo.new(TTC, Enum.EasingStyle.Cubic),
		{ Position = UDim2.new(0, 0, 0.5, 0), ImageTransparency = 1 }
	):Play()
	TweenService:Create(
		Frames.SideDecor.AdmSpinner,
		TweenInfo.new(TTC, Enum.EasingStyle.Cubic),
		{ Position = UDim2.new(0, 0, 0.5, 0), GroupTransparency = 1 }
	):Play()

	Tweem.Completed:Wait()

	Page2.Position = UDim2.new(0.3, 0, 0, 0)
	Page2.GroupTransparency = 1

	Frames.SideDecor.ImageLabel.Position = UDim2.new(0.8, 0, 0.5, 0)
	Frames.SideDecor.AdmSpinner.Position = UDim2.new(0.8, 0, 0.5, 0)

	Frames.SideDecor.AdmSpinner.Visible = Spin
	Frames.SideDecor.ImageLabel.Image = NewIcon
	Frames.SideDecor.ImageLabel.Visible = not Spin

	Page2.Visible = true
	Page1.Visible = false

	local ET = TweenService:Create(
		Page2,
		TweenInfo.new(TTC * 1.2, Enum.EasingStyle.Cubic),
		{ Position = UDim2.new(0, 0, 0, 0), GroupTransparency = 0 }
	)
	TweenService:Create(
		Frames.SideDecor.ImageLabel,
		TweenInfo.new(TTC, Enum.EasingStyle.Cubic),
		{ Position = UDim2.new(0.5, 0, 0.5, 0), ImageTransparency = 0 }
	):Play()
	TweenService:Create(
		Frames.SideDecor.AdmSpinner,
		TweenInfo.new(TTC, Enum.EasingStyle.Cubic),
		{ Position = UDim2.new(0.5, 0, 0.5, 0), GroupTransparency = 0 }
	):Play()

	ET:Play()

	local Dots = Frames.BottomData.Controls.Dots

	for i, Dot in Dots:GetChildren() do
		if not Dot:IsA("Frame") then continue end
		Dot.UIStroke.Thickness = 0
		Dot.UIStroke.Color = Color3.fromRGB(37, 72, 194)

		Dot.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
	end

	Dots[`Dot{PageNumber}`].UIStroke.Thickness = 2
	Dots[`Dot{PageNumber}`].BackgroundColor3 = Color3.fromRGB(37, 72, 194)
	Dots.AProgress.Text = `Step {Page}/5`

	ET.Completed:Wait() --// stop the animation from being too quick
end

function Admins.ClearEditState(Env)
	if Env.EditMode == true then
		Env.EditMode = false
		Env.EditModeMembers = {}
		Env.EditModeApps = {}
		Env.EditModeName = ""
		Env.EditModeIsProtected = false
		Env.EditModeRank = 0
	end

	--// stuff to clear regardless
	Env.Apps = {}
end

function Admins.OpenCreator()
	
end

function Admins.CloseCreator()
	task.delay(1, function()
		if Page == 2 then
			SwapPages(Frames.Page2, Frames.Page1, "rbxassetid://18151072839", false, 1)
		elseif Page == 3 then
			SwapPages(Frames.Page3, Frames.Page1, "rbxassetid://18151072839", false, 1)
		elseif Page == 4 then
			SwapPages(Frames.Page4, Frames.Page1, "rbxassetid://18151072839", false, 1)
		elseif Page == 5 then
			SwapPages(Frames.Page5, Frames.Page1, "rbxassetid://18151072839", false, 1)
		end
	end)
end

function Admins.RunCreatorApp()
	local CanGoBack = true
	local Env = require(script.Parent.UI.AdminHelperEnv)

	--// buttons
	local ConnectionsTable
	local FinalData = {}

	Frames.BottomData.Controls.ALast.MouseButton1Click:Connect(function()
		if not CanGoBack then return end
		
		print(Page, Page <= 1)
		
		if Page <= 1 then return end

		Page -= 1
		SwapPages(Frames[`Page{Page + 1}`], Frames[`Page{Page}`], "rbxassetid://14147040290", false, Page)
	end)

	Frames.Page1.NextPage.MouseButton1Click:Connect(function()
		SwapPages(Frames.Page1, Frames.Loading, "rbxassetid://11102397100", true, 1)

		Env = require(script.Parent.UI.AdminHelperEnv) --// Re-fetch config just incase it changed

		if Env.EditModeIsProtected then
			Frames.Page5.Header.Text = "Access Denied"
			Frames.Page5.Body.Text =
				"Sorry, but this rank is protected and may not be edited. Please contact whoever installed Administer."

			SwapPages(Frames.Loading, Frames.Page5, "rbxassetid://14147040290", false, 5)
			return
		end

		--// Verify the filtering service is online
		local Success, FilterResult = pcall(function()
			return Var.Remotes.FilterString:InvokeServer("test string")
		end)

		if Success and FilterResult[1] then
			SwapPages(Frames.Loading, Frames.Page2, "rbxassetid://15084609272", false, 2)

			ConnectionsTable = {
				Frames.Page2.TextInput:GetPropertyChangedSignal("Text"):Connect(function()
					Frames.Page2.PreviewText.Text =
						`Preview: {Var.Remotes.FilterString:InvokeServer(
							Frames.Page2.TextInput.Text
						)[2]}`
				end),

				Frames.Page2.ColorInput:GetPropertyChangedSignal("Text"):Connect(function()
					Frames.Page2.ColorPreview.Text = `Rank Color (<font color="#{Frames.Page2.ColorInput.Text}">The quick brown fox jumps over the lazy dog</font>)`
				end)
			}
		else
			Frames.Page5.Header.Text = "Oops! That's not meant to happen."
			if FilterResult[2] then
				Frames.Page5.Body.Text = "Failed to connect to Roblox's filtering service. This likely isn't an issue with your game, try again later.\n\n"
					.. FilterResult[2]
					or "The server did not send an error."
			else
				Frames.Page5.Body.Text = "Failed to call the remote to filter. Did you install Administer wrong?\n\n"
					.. FilterResult
					or "The server did not send an error."
			end

			SwapPages(Frames.Loading, Frames.Page5, "rbxassetid://14147040290", false, 5)
		end
	end)

	Frames.Page2.NextPage.MouseButton1Click:Connect(function()
		if string.len(Frames.Page2.TextInput.Text) == 0 or string.len(Frames.Page2.TextInput.Text) > 50 then
			Frontend.Popup.new(
				{
					Icon = `rbxassetid://{Var.Icons["logos"]["administer-blue"]}`,
					Name = "Administer",
					Subheader = "Rank Creator"
				}, {
					Primary = Utilities.Icon "warning-filled",
					SubIcon = Utilities.Icon "x"
				},
				"Invalid input",
				"Rank name must be more than one character and less than 50.",
				{
					{
						Text = "Ok",
						Icon = Utilities.Icon "check-plain",
						Callback = function(c)
							c()
						end
					}
				}
			)

			return
		end

		SwapPages(Frames.Page2, Frames.Loading, "rbxassetid://11102397100", true, 2)

		local ExistingRank = Var.Remotes.GetRank:InvokeServer(Frames.Page2.TextInput.Text)
		if ExistingRank ~= nil and not Env.EditMode then
			Frontend.Popup.new(
				{
					Icon = `rbxassetid://{Var.Icons["logos"]["administer-blue"]}`,
					Name = "Administer",
					Subheader = "Rank Creator"
				}, {
					Primary = Utilities.Icon "warning-filled",
					SubIcon = Utilities.Icon "x"
				},
				"Invalid input",
				`You cannot make name for this rank {Frames.Page2.TextInput.Text} because it is already being used for a different rank.`,
				{
					{
						Text = "Ok",
						Icon = Utilities.Icon "check-plain",
						Callback = function(c)
							c()

							SwapPages(Frames.Loading, Frames.Page2, "rbxassetid://15084609272", false, 5)
						end
					}
				}
			)

			return
		end

		for _, Connection in ConnectionsTable do
			Connection:Disconnect()
		end

		for i, v in Frames.Page3.Members.Members:GetChildren() do
			if not v:GetAttribute("IsTemplate") and v:IsA("Frame") then v:Destroy() end
		end

		local Checking = false
		local Thread
		local function NewGroupCard(PresetID: number?, PresetRank: number?)
			local Clone = Frames.Page3.Members.Members.GroupTemplate:Clone()

			Clone.Parent = Frames.Page3.Members.Members
			Clone.Visible = true
			Clone:SetAttribute("IsTemplate", false)
			Clone:SetAttribute("TemplateType", "Group")

			local CheckTask = function()
				Checking = true
				local Success, Info = pcall(function()
					return game:GetService("GroupService"):GetGroupInfoAsync(tonumber(Clone.TextInput.Text))
				end)

				if Success then
					Clone._Name.Text = `{Info["Name"]}`
					Clone.Image.Image = Info["EmblemUrl"]
				else
					Clone._Name.Text = `Group not found!`
					Clone.Image.Image = "rbxassetid://15105863258"
				end

				Checking = false
			end

			local Thread
			ConnectionsTable["Event" .. math.random(1, 500)] = Clone.TextInput:GetPropertyChangedSignal("Text"):Connect(function()
				if Checking then
					task.cancel(Thread) --// too quick, stop the old one...

					Thread = task.spawn(CheckTask)
				else
					Thread = task.spawn(CheckTask)
				end
			end)
			
			ConnectionsTable["Close" .. math.random(1, 500)] = Clone.Delete.MouseButton1Click:Connect(function()
				Clone:Destroy()
			end)

			Clone.TextInput.Text = PresetID or ""
			Clone.GroupRankInput.Text = PresetRank or ""
		end

		local function NewUserCard(PresetID: number?)
			local Clone = Frames.Page3.Members.Members.PlayerTemplate:Clone()

			Clone.Parent = Frames.Page3.Members.Members
			Clone.Visible = true
			
			Clone:SetAttribute("IsTemplate", false)
			Clone:SetAttribute("TemplateType", "User")

			local function CheckTask()
				local Success, Info = pcall(function()
					return {
						game.Players:GetNameFromUserIdAsync(tonumber(Clone.TextInput.Text)),
						game.Players:GetUserThumbnailAsync(
							tonumber(Clone.TextInput.Text),
							Enum.ThumbnailType.HeadShot,
							Enum.ThumbnailSize.Size100x100
						)
					}
				end)

				if Success then
					Clone._Name.Text = `{Info[1]}`
					Clone.Image.Image = Info[2]
				else
					Clone._Name.Text = `Not found`
					Clone.Image.Image = "rbxassetid://15105863258"
				end
			end

			ConnectionsTable["Event" .. math.random(1, 500)] = Clone.TextInput:GetPropertyChangedSignal("Text"):Connect(function()
				if Checking then
					task.cancel(Thread)

					Thread = task.spawn(CheckTask)
				else
					Thread = task.spawn(CheckTask)
				end
			end)

			ConnectionsTable["Close" .. math.random(1, 500)] = Clone.Delete.MouseButton1Click:Connect(function()
				Clone:Destroy()
			end)

			Clone.TextInput.Text = PresetID or ""
		end

		ConnectionsTable = {
			Frames.Page3.AddPane.AddGroup.Click.MouseButton1Click:Connect(function()
				NewGroupCard()
			end),

			Frames.Page3.AddPane.AddUser.Click.MouseButton1Click:Connect(function()
				NewUserCard()
			end)
		}

		for i, User in Env.EditModeMembers :: { { MemberType: string, ID: number, GroupRank: number? } } do
			if User.MemberType == "User" then
				NewUserCard(User.ID)
			else
				NewGroupCard(User.ID, User.GroupRank)
			end
		end

		SwapPages(Frames.Loading, Frames.Page3, "rbxassetid://15082548595", false, 3)
	end)

	Frames.Page3.NextPage.MouseButton1Click:Connect(function()
		SwapPages(Frames.Page3, Frames.Loading, "rbxassetid://11102397100", true, 3)

		local MemberCount = 0
		for i, v in Frames.Page3.Members.Members:GetChildren() do
			if not v:IsA("Frame") then continue end
			if v:GetAttribute("IsTemplate") then continue end

			MemberCount += 1
		end

		if MemberCount == 0 then
			Frontend.Popup.new(
				{
					Icon = `rbxassetid://{Var.Icons["logos"]["administer-blue"]}`,
					Name = "Administer",
					Subheader = "Rank Creator"
				}, {
					Primary = Utilities.Icon "warning-filled",
					SubIcon = Utilities.Icon "x"
				},
				"Invalid input",
				"You must have at least one member in this rank.",
				{
					{
						Text = "Ok",
						Icon = Utilities.Icon "check-plain",
						Callback = function(c)
							SwapPages(Frames.Loading, Frames.Page3, "rbxassetid://15082548595", false, 3)

							c()
						end
					}
				}
			)

			return
		end

		local ShouldGoBack = false
		local Toggled = false
		
		for i, v in Frames.Page3.Members.Members:GetChildren() do	
			if not v:IsA("Frame") then continue end
			if v:GetAttribute("IsTemplate") then continue end

			pcall(function()
				if ShouldGoBack then return true end
				
				Toggled = false
				
				if v.TextInput.Text == "" then
					Frontend.Popup.new(
						{
							Icon = `rbxassetid://{Var.Icons["logos"]["administer-blue"]}`,
							Name = "Administer",
							Subheader = "Rank Creator"
						}, {
							Primary = Utilities.Icon "warning-filled",
							SubIcon = Utilities.Icon "x"
						},
						"Invalid input",
						"One or more of your members do not have a UserID assigned. All users must have an ID.",
						{
							{
								Text = "Ok",
								Icon = Utilities.Icon "check-plain",
								Callback = function(c)
									c()

									Toggled = true
									ShouldGoBack = true

									SwapPages(Frames.Loading, Frames.Page3, "rbxassetid://15082548595", false, 3)
								end
							}
						}
					)
				else
					Toggled = true
				end
			end)

			repeat task.wait() until Toggled
			Toggled = false
			
		end

		if ShouldGoBack then return end
		
		ShouldGoBack = false

		for i, v in ConnectionsTable do
			v:Disconnect()
		end

		for i, Child in Frames.Page4.Apps.Apps:GetChildren() do
			if Child.Name ~= "Template" and Child:IsA("Frame") then Child:Destroy() end
		end

		print(Var.CombinedButtonConfig)

		for _, AppObj in Var.CombinedButtonConfig do
			if Var.RankCreatorApps == nil then
				Var.RankCreatorApps = {
					CachedData = {}
				}
			end

			Var.RankCreatorApps[AppObj.ButtonID] = true
			Var.RankCreatorApps.CachedData[AppObj.ButtonID] = {
				Name = AppObj.AppName,
				Icon = AppObj.Icon
			}

			for _, SubIcon in AppObj.SubIcons do
				Var.RankCreatorApps[`{AppObj.ButtonID}\\{SubIcon.ButtonID}`] = true 
				Var.RankCreatorApps.CachedData[`{AppObj.ButtonID}\\{SubIcon.ButtonID}`] = {
					Name = SubIcon.Name,
					Icon = SubIcon.Icon
				}
			end
		end

		for i, v: Instance in Var.MainFrame.AppDrawer.AppHolder.Apps:GetChildren() do
			if not table.find({ "MultiThread", "SingleThread", "ZZ_AdministerData", "UIListLayout", "Home" }, v.Name) then
				if v:GetAttribute("ThreadType") == "multi" then
					local NewApp = v:Clone()

					NewApp.Parent = Frames.Page4.AppDrawer.AppHolder.Apps
					NewApp.Size = UDim2.new(.911, 0, .636, 0)

					for _, App in NewApp.SubCollection:GetChildren() do
						if not App:IsA("Frame") then continue end

						App:FindFirstChildWhichIsA("TextButton").MouseButton1Click:Connect(function()
							for _, AppObj in Var.CombinedButtonConfig do
								--// i hate recursion
								for _, SubIcon in AppObj.SubIcons do
									local ButtonID = `{AppObj.ButtonID}\\{SubIcon.ButtonID}`

									if App:GetAttribute("ButtonID") == ButtonID then
										Var.RankCreatorApps[ButtonID] = not Var.RankCreatorApps[ButtonID]

										TweenService:Create(App.Title, TweenInfo.new(.4), { 
											TextTransparency = Var.RankCreatorApps[ButtonID] and 0 or .6
										}):Play()

										TweenService:Create(App.Icon, TweenInfo.new(.4), { 
											ImageTransparency = Var.RankCreatorApps[ButtonID] and 0 or .6
										}):Play()
									end
								end
							end
						end)
					end
				else
					local NewApp = v:Clone()

					NewApp.Parent = Frames.Page4.AppDrawer.AppHolder.Apps
					NewApp.Size = UDim2.new(.911, 0, .13, 0)

					NewApp.Activator.MouseButton1Click:Connect(function()
						for _, AppObj in Var.CombinedButtonConfig do
							if AppObj.ButtonID == NewApp:GetAttribute("ButtonID") then
								Var.RankCreatorApps[AppObj.ButtonID] = not Var.RankCreatorApps[AppObj.ButtonID]

								TweenService:Create(NewApp.Title, TweenInfo.new(.4), { 
									TextTransparency = Var.RankCreatorApps[NewApp] and 0 or .6
								}):Play()

								TweenService:Create(NewApp.Icon, TweenInfo.new(.4), { 
									ImageTransparency = Var.RankCreatorApps[NewApp] and 0 or .6
								}):Play()
							end
						end
					end)
				end
			end
		end

		for i, App in Env.EditModeApps :: { { DisplayName: string, Icon: string, Name: string } } do
			if Frames.Page4.Apps.Apps:FindFirstChild(App.DisplayName) then continue end

			NewLegacyCard(
				App.DisplayName,
				App.Icon,
				App.Name,
				"You don't have the permissions to access this app, so we don't know anything else about it."
			)
		end

		SwapPages(Frames.Loading, Frames.Page4, "rbxassetid://14865439768", false, 4)
	end)

	Frames.Page4.NextPage.MouseButton1Click:Connect(function()
		CanGoBack = false
		-- Start packaging the data
		SwapPages(Frames.Page4, Frames.Loading, "rbxassetid://11102397100", true, 4)

		local Members, AllowedPages = {}, {}

		for i, v in Frames.Page3.Members.Members:GetChildren() do
			if not v:IsA("Frame") then continue end
			if v:GetAttribute("IsTemplate") then continue end

			if v:GetAttribute("TemplateType") == "Group" then
				table.insert(Members, {
					MemberType = "Group",
					ID = v.TextInput.Text or 0,
					GroupRank = v.GroupRankInput.Text or 0
				})
			else
				table.insert(Members, {
					MemberType = "User",
					ID = v.TextInput.Text or 0
				})
			end
		end

		FinalData = {
			Name = Var.Remotes.FilterString:InvokeServer(Frames.Page2.TextInput.Text)[2],
			Protected = false, -- may be configurable soon
			Members = Members,

			Apps = Var.RankCreatorApps,

			ActingUser = game.Players.LocalPlayer.UserId,
			Color = Frames.Page2.ColorInput.Text,

			IsEditing = Env.EditMode,
			EditingRankID = Env.EditModeRank,

			CreationReason = "Created in the rank editor"
		}

		local Result = Var.Remotes.NewRank:InvokeServer(FinalData)
		if Result[1] then
			SwapPages(Frames.Loading, Frames.Page5, "rbxassetid://13531414092", false, 5)
		else
			SwapPages(Frames.Loading, Frames.Page5, "rbxassetid://13531414092", false, 5)
			Frames.Page5.Header.Text = require(script.Parent.UI.AdminHelperEnv).Strings.FinHeaderError
			Frames.Page5.Body.Text =
				string.format(require(script.Parent.UI.AdminHelperEnv).Strings.FinHeaderError, Result[2])
		end
	end)

	Frames.Page5.NextPage.MouseButton1Click:Connect(function()
		Admins.CloseCreator()
		SwapPages(Frames.Page5, Frames.Page1, "rbxassetid://18151072839", false, 1)

		Frames.BottomData.RankTitle.Text = "Creating a rank"
		CanGoBack = true
	end)

	Frames.BottomData.Controls.Exit.MouseButton1Click:Connect(function()
		Admins.CloseCreator()
	end)
end

return Admins
