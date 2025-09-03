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
					Icon = Utilities.Icon "administer",
					Name = "Access Control",
					Subheader = "Error"
				}, {
					Primary = Utilities.Icon "user",
					SubIcon = Utilities.Icon "triangle-warning"
				},
				Utilities.Translate("admin.rankcreator.corrupt.Detail"),
				string.format(Utilities.Translate("admin.rankcreator.corrupt.Body"), e)
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
				local CreatorName = v.CreatorID == 1 and Utilities.Translate("admin.ranktype.System") or Var.Services.Players:GetNameFromUserIdAsync(v.CreatorID)
				Template.Name = v.Name
				Template.RankName.Text = v.Name
				Template.Info.Text = string.format(Utilities.Translate("Configuration.Admins.Container.Ranks.Content.Template.Info"),
					v.RankID,
					v.Apps.SuperAdmin and Utilities.Translate("Configuration.Admins.Ranks.HasSuperAdmin") or string.format(Utilities.Translate("Configuration.Admins.Ranks.HasApps"), #v.Apps),
					CreatorName,
					Utilities.FormatRelativeTime(v.Modified)
				)

				if v.Apps.SuperAdmin then
					local Card = Template.Pages.Frame:Clone()
					local Tip = Instance.new("TextButton")

					Card.Visible = true
					Card.AppName.Text = Utilities.Translate("admin.ranks.superadmin.Detail")
					Card.ImageLabel.Image = Utilities.Icon "user-shield"
					Card.Parent = Template.Pages

					Tip.Size = UDim2.new(1,0,1,0)
					Tip.BackgroundTransparency = 1
					Tip.BorderSizePixel = 0
					Tip.Parent = Card
					Tip.Text = ""

					table.insert(Connections, Tip.MouseButton1Click:Connect(function()
						Frontend.Popup.new(
							{
								Icon = Utilities.Icon "administer",
								Name = "Administer",
								Subheader = "Information"
							},
							{
								Primary = Utilities.Icon "user-shield"
							},
							Utilities.Translate("admin.ranks.superadmin.Detail"),
							Utilities.Translate("admin.ranks.superadmin.Body"),
							{
								{
									Text = Utilities.Translate("generic.Done"),
									Icon = Utilities.Icon "check-plain",
									Callback = function(c) c() end
								}
							}
						)
					end))
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
					Card.AppName.Text = string.format(Utilities.Translate("admin.ranks.Others"), AppCount - 5)
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
					Template.ColorBG.BackgroundColor3 = Color3.fromHex(v.Color)
				end, function()
					--// Invalid hex code
					Template.ColorBG.BackgroundColor3 = Color3.new(0.239, 0.643, 1)
				end)

				Template.Parent = RanksFrame
				Template.Visible = true

				local UserNames = {}
				local MoveTI = TweenInfo.new(Var.AnimationSpeed * .3)

				for i = 1, 3 do
					local User = v.Members[i]

					if User == nil then break end
					if User.MemberType == "User" then
						pcall(function()
							Template.ProfilePictures[i].Visible = true
							Template.ProfilePictures[i].Image = Var.Services.Players:GetUserThumbnailAsync(
								User.ID,
								Enum.ThumbnailType.HeadShot,
								Enum.ThumbnailSize.Size100x100
							)

							table.insert(UserNames, Var.Services.Players:GetNameFromUserIdAsync(User.ID))
						end)
					else
						local Success, GroupInfo = pcall(function()
							return game:GetService("GroupService"):GetGroupInfoAsync(User.ID)
						end)

						if Success then
							Template.ProfilePictures[i].Image = GroupInfo.EmblemUrl
							Template.ProfilePictures[i].Visible = true

							Template.ProfilePictures[i].UICorner.CornerRadius = UDim.new(0, 4)

							table.insert(UserNames, GroupInfo.Name)
						end

					end
				end

				if UserNames[1] == nil then
					Template.MembersText.Text = string.format(Utilities.Translate("admin.ranks.members.one"), Utilities.Translate("generic.User"))

					continue
				end

				Template.MembersText.Text = (
					#UserNames == 3 and string.format(
						"<b>%s</b>, <b>%s</b>, <b>%s</b>, and <b>%d %s</b>",
						UserNames[1],
						UserNames[2],
						UserNames[3],
						#v.Members - 3,
						Utilities.Translate(#v.Members - 3 == 1 and "admin.ranks.members.one" or "admin.ranks.members.more"):format(#v.Members - 3)
					)
						or #UserNames == 2 and string.format(
							"<b>%s</b> and <b>%s</b> %s",
							UserNames[1],
							UserNames[2],
							Utilities.Translate("admin.ranks.members.two")
						)
						or string.format(
							"<b>%s</b> %s",
							UserNames[1],
							Utilities.Translate("admin.ranks.members.one")
						)
				)

				table.insert(Connections, Template.EditTrigger.MouseEnter:Connect(function()
					if Var.RankCreatorOpen then return end

					Var.Services.TweenService:Create(Template.RankName, MoveTI, {
						Position = UDim2.fromScale(0.1, 0.036),
						Size = UDim2.fromScale(0.858, 0.126)
					}):Play()

					Var.Services.TweenService:Create(Template.Configure, MoveTI, {
						ImageTransparency = 0
					}):Play()
				end))

				table.insert(Connections, Template.EditTrigger.MouseLeave:Connect(function()
					Var.Services.TweenService:Create(Template.RankName, MoveTI, {
						Position = UDim2.fromScale(0.025, 0.036),
						Size = UDim2.fromScale(0.955, 0.126)
					}):Play()

					Var.Services.TweenService:Create(Template.Configure, MoveTI, {
						ImageTransparency = 1
					}):Play()
				end))

				if v.Protected then
					Template.Configure.Image = Utilities.Icon "lock"

					table.insert(Connections, Template.EditTrigger.MouseButton1Click:Connect(function()
						if Var.RankCreatorOpen then return end

						Frontend.Toast({
							Icon = Utilities.Icon "triangle-warning",
							Text = Utilities.Translate("admin.ranks.protected.Detail"),
							Subtext = Utilities.Translate("admin.ranks.protected.Body"),
							Timeout = 5
						})
					end))
				else
					local Env = require(script.Parent.UI.AdminHelperEnv)

					table.insert(Connections, Template.EditTrigger.MouseButton1Click:Connect(function()
						if Var.RankCreatorOpen then return end

						Env.EditMode = true
						Env.EditModeMembers = v.Members
						Env.EditModeApps = v.Apps
						Env.EditModeName = v.Name
						Env.EditModeColor = v.Color

						Admins.OpenCreator()
					end))
				end
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
	local TTC = Var.AnimationSpeed * .4

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
	Dots.AProgress.Text = string.format(
		Utilities.Translate("Configuration.Admins.NewAdmin.BottomData.StepLabel"),
		Page,
		"5"
	)

	ET.Completed:Wait() --// stop the animation from being too quick
end

function Admins.ClearEditState(Env)
	if Env.EditMode == true then
		Env.EditMode = false
		Env.EditModeMembers = {}
		Env.EditModeApps = {}
		Env.EditModeName = ""
		Env.EditModeColor = ""
		Env.EditModeIsProtected = false
		Env.EditModeRank = 0
	end

	--// stuff to clear regardless
	Env.Apps = {}
end

function Admins.GetEditState()
	local Clone = table.clone(require(script.Parent.UI.AdminHelperEnv))
	
	Clone.Strings = nil
	
	return Clone
end

function Admins.OpenCreator()
	local NewAdmin = Var.MainFrame.Configuration.Admins.NewAdmin
	local CompleteTime = Var.AnimationSpeed * .6

	NewAdmin.GroupTransparency = 1
	NewAdmin.Size = UDim2.fromScale(0.6, 0.57) 
	NewAdmin.Position = UDim2.fromScale(.5, .65)

	Var.Services.TweenService:Create(NewAdmin, TweenInfo.new(CompleteTime, Enum.EasingStyle.Quart), {
		Size = UDim2.fromScale(.867, .847),
		Position = UDim2.fromScale(.5, .5),
		GroupTransparency = 0
	}):Play()

	NewAdmin.Visible = true
	Var.RankCreatorOpen = true
end

function Admins.CloseCreator()
	local NewAdmin = Var.MainFrame.Configuration.Admins.NewAdmin
	local CompleteTime = Var.AnimationSpeed * .5

	Var.Services.TweenService:Create(NewAdmin, TweenInfo.new(CompleteTime, Enum.EasingStyle.Quart), {
		Size = UDim2.fromScale(0.6, 0.57) ,
		Position = UDim2.fromScale(.5, .65),
		GroupTransparency = 1
	}):Play()

	task.delay(CompleteTime, function()
		Var.RankCreatorOpen = false
		Var.MainFrame.Configuration.Admins.NewAdmin.Visible = false

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

	--// Translations
	Frames.BottomData.RankTitle.Text = Utilities.Translate("Configuration.Admins.NewAdmin.BottomData.RankTitle")

	Frames.Page1.Header.Text = Utilities.Translate("Configuration.Admins.NewAdmin.Page1.Header")
	Frames.Page1.Body.Text = Utilities.Translate("Configuration.Admins.NewAdmin.Page1.Body")

	Frames.Page2.Header.Text = Utilities.Translate("Configuration.Admins.NewAdmin.Page2.LogoWordmark")
	Frames.Page2.Body.Text = Utilities.Translate("Configuration.Admins.NewAdmin.Page2.FilterHdr")

	Frames.Page3.LogoWordmark.Text = Utilities.Translate("Configuration.Admins.NewAdmin.Page3.LogoWordmark")
	Frames.Page3.PageHdr.Text = Utilities.Translate("Configuration.Admins.NewAdmin.Page3.PageHdr")

	Frames.Page4.LogoWordmark.Text = Utilities.Translate("Configuration.Admins.NewAdmin.Page4.LogoWordmark")
	Frames.Page4.PageHdr.Text = Utilities.Translate("Configuraton.Admins.NewAdmin.Page4.PageHdr")
	
	for _, Label in Frames:GetDescendants() do
		if not Label:IsA("TextLabel") then continue end
		if Label.Text ~= "Continue" then continue end
		
		Label.Text = Utilities.Translate("Configuration.Admins.NewAdmin.Page1.NextPage.LogoWordmark")
	end

	Frames.BottomData.Controls.ALast.MouseButton1Click:Connect(function()
		if not CanGoBack then return end
		if Page <= 1 then return end

		Page -= 1
		SwapPages(Frames[`Page{Page + 1}`], Frames[`Page{Page}`], "rbxassetid://14147040290", false, Page)
	end)

	Frames.Page1.NextPage.MouseButton1Click:Connect(function()
		SwapPages(Frames.Page1, Frames.Loading, "rbxassetid://11102397100", true, 1)

		Env = require(script.Parent.UI.AdminHelperEnv) --// Re-fetch config just incase it changed
		
		print("hi")

		--// Verify the filtering service is online
		local Success, FilterResult = pcall(function()
			return Var.Remotes.FilterString:InvokeServer("test string")
		end)
		
		print(Success, FilterResult)

		if Success and FilterResult[1] then
			SwapPages(Frames.Loading, Frames.Page2, "rbxassetid://15084609272", false, 2)

			ConnectionsTable = {
				Frames.Page2.TextInput.FocusLost:Connect(function(_)
					Frames.Page2.PreviewText.Text =
						`Preview: {Var.Remotes.FilterString:InvokeServer(
							Frames.Page2.TextInput.Text
						)[2]}`
				end),

				Frames.Page2.ColorInput:GetPropertyChangedSignal("Text"):Connect(function()
					xpcall(function()
						TweenService:Create(Frames.Page2.ColorPreview, TweenInfo.new(Var.AnimationSpeed * .3, Enum.EasingStyle.Quart), {
							BackgroundColor3 = Color3.fromHex(Frames.Page2.ColorInput.Text)
						}):Play()
					end, function()
						TweenService:Create(Frames.Page2.ColorPreview, TweenInfo.new(Var.AnimationSpeed * .3, Enum.EasingStyle.Quart), {
							BackgroundColor3 = Color3.fromHex("#fff")
						}):Play()
					end)
				end)
			}

			Frames.Page2.TextInput.Text = Env.EditModeName
			Frames.Page2.ColorInput.Text = Env.EditModeColor
		else
			Frames.Page5.Header.Text = Utilities.Translate("admin.rankcreator.failed.Detail")
			Frames.Page5.Body.Text = string.format(Utilities.Translate("admin.rankcreator.errors.filter.Body"), FilterResult[2])

			SwapPages(Frames.Loading, Frames.Page5, "rbxassetid://14147040290", false, 5)
		end
	end)

	Frames.Page2.NextPage.MouseButton1Click:Connect(function()
		if string.len(Frames.Page2.TextInput.Text) == 0 or string.len(Frames.Page2.TextInput.Text) > 50 then
			Frontend.Toast({
				Icon = Utilities.Icon "x",
				Text = Utilities.Translate("generic.InvalidInput"),
				Subtext = Utilities.Translate("admin.rankcreator.errors.name.Len"),
				Timeout = 5
			})

			return
		end

		SwapPages(Frames.Page2, Frames.Loading, "rbxassetid://11102397100", true, 2)

		local ExistingRank = Var.Remotes.GetRank:InvokeServer(Frames.Page2.TextInput.Text)
		if ExistingRank ~= nil and not Env.EditMode then
			Frontend.Toast({
				Icon = Utilities.Icon "x",
				Text = Utilities.Translate("generic.InvalidInput"),
				Subtext = string.format(Utilities.Translate("admin.rankcreator.errors.name.Unique"), Frames.Page2.TextInput.Text),
				Timeout = 5
			})

			SwapPages(Frames.Loading, Frames.Page2, "rbxassetid://11102397100", false)

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
			
			Clone.Label.Text = Utilities.Translate("Configuration.Admins.EditRank.People.Content.GroupTemplate.Label")

			local CheckTask = function()
				Checking = true
				local Success, Info = pcall(function()
					return game:GetService("GroupService"):GetGroupInfoAsync(tonumber(Clone.TextInput.Text))
				end)

				if Success then
					Clone._Name.Text = `{Info["Name"]}`
					Clone.Image.Image = Info["EmblemUrl"]
				else
					Clone._Name.Text = Utilities.Translate("generic.NotFound")
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
			
			Clone.Label.Text = Utilities.Translate("Configuration.Admins.EditRank.People.Content.PlayerTemplate.Label")

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
					Clone._Name.Text = Info[1]
					Clone.Image.Image = Info[2]
				else
					Clone._Name.Text = Utilities.Translate("generic.NotFound")
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
			Frames.Page3.AddPane.AddGroup.Click.MouseButton1Click:Connect(NewGroupCard),
			Frames.Page3.AddPane.AddUser.Click.MouseButton1Click:Connect(NewUserCard)
		}
		
		Frames.Page3.AddPane.AddGroup.LogoWordmark.Text = Utilities.Translate("Configuration.Admins.EditRank.People.Content.GroupTemplate.Label")
		Frames.Page3.AddPane.AddUser.LogoWordmark.Text = Utilities.Translate("Configuration.Admins.EditRank.People.Content.PlayerTemplate.Label")

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
			Frontend.Toast({
				Icon = Utilities.Icon "x",
				Text = Utilities.Translate("generic.InvalidInput"),
				Subtext = Utilities.Translate("admin.rankcreator.errors.members.NotEnough"),
				Timeout = 5
			})

			SwapPages(Frames.Loading, Frames.Page3, "rbxassetid://15082548595", false, 3)

			return
		elseif MemberCount > Env.MaxPeople then
			Frontend.Toast({
				Icon = Utilities.Icon "x",
				Text = Utilities.Translate("generic.InvalidInput"),
				Subtext = string.format(Utilities.Translate("admin.rankcreator.errors.members.TooMany")),
				Timeout = 5
			})

			SwapPages(Frames.Loading, Frames.Page3, "rbxassetid://15082548595", false, 3)

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
							Icon = Utilities.Icon "administer",
							Name = "Administer",
							Subheader = "Rank Creator"
						}, 
						{
							Primary = Utilities.Icon "warning-filled",
							SubIcon = Utilities.Icon "x"
						},
						Utilities.Translate("generic.InvalidInput"),
						Utilities.Translate("admin.rankcreator.errors.members.NoInput"),
						{
							{
								Text = Utilities.Translate("generic.OK"),
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

		local CanNotEdit = {}

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


		if Env.EditModeApps ~= {} then
			for AppID, CanUse in Env.EditModeApps do
				if AppID == "CachedData" then
					continue
				end

				--// TODO: Maybe we should do something better with CanNotEdit eventually like displaying a label.. but it works like this for now!
				if not Var.RankCreatorApps[AppID] then
					table.insert(CanNotEdit, AppID)
				end

				Var.RankCreatorApps[AppID] = CanUse


				--print(AppID, CanUse)
			end
		end

		for i, v: Instance in Var.MainFrame.AppDrawer.AppHolder.Apps:GetChildren() do
			if Env.HasPopulatedApps then break end --// maybe a better place for this?

			if not table.find({ "MultiThread", "SingleThread", "ZZ_AdministerData", "UIListLayout", "Home" }, v.Name) then
				if v:GetAttribute("ThreadType") == "multi" then
					local NewApp = v:Clone()

					NewApp.Parent = Frames.Page4.AppDrawer.AppHolder.Apps
					NewApp.Size = UDim2.new(.911, 0, .636, 0)

					for _, App in NewApp.SubCollection:GetChildren() do
						if not App:IsA("Frame") then continue end

						--// check just incase its edited
						for _, AppObj in Var.CombinedButtonConfig do
							for _, SubIcon in AppObj.SubIcons do
								local ButtonID = `{AppObj.ButtonID}\\{SubIcon.ButtonID}`

								if App:GetAttribute("ButtonID") == ButtonID and Var.RankCreatorApps[ButtonID] == false then
									TweenService:Create(App.Title, TweenInfo.new(.4), { 
										TextTransparency = Var.RankCreatorApps[ButtonID] and 0 or .6
									}):Play()

									TweenService:Create(App.Icon, TweenInfo.new(.4), { 
										ImageTransparency = Var.RankCreatorApps[ButtonID] and 0 or .6
									}):Play()
								end
							end
						end

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
					local ButtonID = NewApp:GetAttribute("ButtonID")

					NewApp.Parent = Frames.Page4.AppDrawer.AppHolder.Apps
					NewApp.Size = UDim2.new(.911, 0, .13, 0)

					--// same "is this edited?" logic..
					for _, AppObj in Var.CombinedButtonConfig do
						if AppObj.ButtonID == ButtonID and Var.RankCreatorApps[ButtonID] == false then
							TweenService:Create(NewApp.Title, TweenInfo.new(.4), { 
								TextTransparency = Var.RankCreatorApps[AppObj.ButtonID] and 0 or .6
							}):Play()

							TweenService:Create(NewApp.Icon, TweenInfo.new(.4), { 
								ImageTransparency = Var.RankCreatorApps[AppObj.ButtonID] and 0 or .6
							}):Play()
						end
					end

					NewApp.Activator.MouseButton1Click:Connect(function()
						for _, AppObj in Var.CombinedButtonConfig do
							if AppObj.ButtonID == ButtonID then
								Var.RankCreatorApps[AppObj.ButtonID] = not Var.RankCreatorApps[AppObj.ButtonID]

								TweenService:Create(NewApp.Title, TweenInfo.new(.4), { 
									TextTransparency = Var.RankCreatorApps[AppObj.ButtonID] and 0 or .6
								}):Play()

								TweenService:Create(NewApp.Icon, TweenInfo.new(.4), { 
									ImageTransparency = Var.RankCreatorApps[AppObj.ButtonID] and 0 or .6
								}):Play()
							end
						end
					end)
				end
			end
		end

		SwapPages(Frames.Loading, Frames.Page4, "rbxassetid://14865439768", false, 4)
		Env.HasPopulatedApps = true
	end)


	Frames.Page4.NextPage.MouseButton1Click:Connect(function()
		CanGoBack = false

		--// Start packaging the data
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
			Protected = false, --// may be configurable soon
			Members = Members,

			Apps = Var.RankCreatorApps,

			ActingUser = game.Players.LocalPlayer.UserId,
			Color = Frames.Page2.ColorInput.Text,

			IsEditing = Env.EditMode,
			EditOriginalName = Env.EditModeName,

			CreationReason = "Created in the Rank Creator"
		}

		local Result = Var.Remotes.NewRank:InvokeServer(FinalData)
		if Result[1] then
			SwapPages(Frames.Loading, Frames.Page5, "rbxassetid://13531414092", false, 5)
			Frames.Page5.Header.Text = Env.Strings.FinHeaderSucc
			Frames.Page5.Body.Text = Env.Strings.FinBodyNew
		else
			SwapPages(Frames.Loading, Frames.Page5, "rbxassetid://13531414092", false, 5)
			Frames.Page5.Header.Text = Env.Strings.FinHeaderError
			Frames.Page5.Body.Text =
				string.format(Env.Strings.FinBodyNewError, Result[2])
		end
	end)

	Frames.Page5.NextPage.MouseButton1Click:Connect(function()
		Admins.Load()
		Admins.CloseCreator()
		Admins.ClearEditState(Env)

		SwapPages(Frames.Page5, Frames.Page1, "rbxassetid://18151072839", false, 1)

		Frames.BottomData.RankTitle.Text = Utilities.Translate("Configuration.Admins.NewAdmin.BottomData.RankTitle")
		CanGoBack = true
	end)

	Frames.BottomData.Controls.Exit.MouseButton1Click:Connect(function()
		Admins.CloseCreator()
	end)
end

return Admins
