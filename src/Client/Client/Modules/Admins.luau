--// pyxfluff 2025

local Modules = script.Parent
local Libs = script.Parent.Parent.Libraries

local Utilities = require(Modules.Utilities)
local Var = require(Modules.Variables)

local Admins = {}
local Connections: { RBXScriptConnection } = {}

local RanksFrame = Var.MainFrame.Configuration.Admins.Container.Ranks.Content

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
		local List = Var.Remotes.GetRanks:InvokeServer()

		if typeof(List) == "string" then
			Utilities.Logging.Warn(`Failed: {List}`)

			return "Something went wrong"
		else
			for i, v in List do
				local Template = RanksFrame.Template:Clone()

				Template.Name = v["Name"]
				Template.RankName.Text = v["Name"]
				Template.Info.Text =
					`{v.RankID} • {v.Apps.SuperAdmin and "Full Access" or #v.Apps .. " apps"}{v.Protected and " • Protected" or ""} • {v.CreationReason} • Created {Utilities.FormatRelativeTime(v.Modified)}`

				if #v["Apps"] > 6 then
					for j = 1, 5 do
						if type(v.Apps[j]) == "boolean" then continue end
						local Card = Template.Pages.Frame:Clone()

						Card.Visible = true
						Card.AppName.Text = v.Apps[j]["DisplayName"]
						Card.ImageLabel.Image = v.Apps[j]["Icon"]
						Card.Parent = Template.Pages
					end

					local Card = Template.Pages.Frame:Clone()
					Card.Visible = true
					Card.AppName.Text = `{#v.Apps - 5} others...`
					Card.Parent = Template.Pages
				else
					for k, App in v["Apps"] do
						if type(App) == "boolean" then continue end
						local Card = Template.Pages.Frame:Clone()

						Card.Visible = true
						Card.AppName.Text = App.DisplayName
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

						Template.ProfilePictures[i].Image = GroupInfo.EmblemUrl
						Template.ProfilePictures[i].Visible = true

						Template.ProfilePictures[i].UICorner.CornerRadius = UDim.new(0, 4)

						table.insert(UserNames, GroupInfo.Name)
					end
				end

				Template.MembersText.Text = (
					#UserNames == 3 and `<b>{UserNames[1]}</b>, <b>{UserNames[2]}</b>, <b>{UserNames[3]}</b>, and <b>{#v.Members - 3}</b> are members`
						or #UserNames == 2 and `<b>{UserNames[1]}</b> and <b>{UserNames[2]}</b> are members`
						or `<b>{UserNames[1]}</b> is a member`
				)
			end
		end

		Shimmer1:Pause()
		Shimmer1:GetFrame():Destroy()
	end)
end

function Admins.RunCreatorApp()
	--// TODO
	local TweenService = game:GetService("TweenService")

	local Page = 1
	local CanGoBack = true
	local Env = require(script.Parent.UI.AdminHelperEnv)
	local Frames = Var.MainFrame.Configuration.Admins.NewAdmin

	local function SwapPages(Page1, Page2, NewIcon, Spin, PageNumber)
		if type(Spin) == "number" then PageNumber = Spin end

		Page = PageNumber
		local TTC = 0.4

		for _, descendant in Page1:GetDescendants() do
			if descendant:IsA("ImageLabel") then
				TweenService:Create(descendant, TweenInfo.new(TTC, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					ImageTransparency = 1,
					BackgroundTransparency = 1,
				}):Play()
			elseif descendant:IsA("GuiObject") then
				TweenService:Create(descendant, TweenInfo.new(TTC, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Transparency = 1,
				}):Play()
			elseif descendant:IsA("TextLabel") then
				TweenService:Create(descendant, TweenInfo.new(TTC, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					TextTransparency = 1,
					BackgroundTransparency = 1,
				}):Play()
			elseif descendant:IsA("Frame") then
				TweenService:Create(descendant, TweenInfo.new(TTC, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					BackgroundTransparency = 1,
				}):Play()
			end
		end
		local Tweem = TweenService:Create(
			Page1,
			TweenInfo.new(TTC * 1.3, Enum.EasingStyle.Cubic),
			{ Position = UDim2.new(-0.5, 0, 0, 0) }
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
		for _, descendant in Page2:GetDescendants() do
			if descendant:IsA("ImageLabel") then
				descendant.ImageTransparency = 1
				descendant.BackgroundTransparency = 1
			elseif descendant:IsA("GuiObject") then
				descendant.Transparency = 1
			elseif descendant:IsA("TextLabel") then
				descendant.TextTransparency = 1
				descendant.BackgroundTransparency = 1
			elseif descendant:IsA("Frame") then
				descendant.BackgroundTransparency = 1
			end
		end

		Page2.Position = UDim2.new(0.3, 0, 0, 0)
		Frames.SideDecor.ImageLabel.Position = UDim2.new(0.8, 0, 0.5, 0)
		Frames.SideDecor.AdmSpinner.Position = UDim2.new(0.8, 0, 0.5, 0)

		Frames.SideDecor.AdmSpinner.Visible = Spin
		Frames.SideDecor.ImageLabel.Image = NewIcon
		Frames.SideDecor.ImageLabel.Visible = not Spin

		Page2.Visible = true
		Page1.Visible = false

		for _, descendant in Page2:GetDescendants() do
			if descendant:IsA("ImageLabel") then
				TweenService:Create(descendant, TweenInfo.new(TTC, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					ImageTransparency = 0,
				}):Play()
			elseif descendant:IsA("TextLabel") then
				TweenService:Create(descendant, TweenInfo.new(TTC, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					TextTransparency = 0,
				}):Play()
			elseif descendant:IsA("TextBox") then
				TweenService:Create(descendant, TweenInfo.new(TTC, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					TextTransparency = 0,
					BackgroundTransparency = 0,
				}):Play()
			elseif descendant:IsA("TextButton") then
				TweenService:Create(descendant, TweenInfo.new(TTC, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					TextTransparency = 0,
				}):Play()
				if descendant.Name == "NextPage" then
					TweenService
						:Create(descendant, TweenInfo.new(TTC, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
							BackgroundTransparency = 0,
						})
						:Play()
				end
			elseif descendant:IsA("Frame") and not descendant:GetAttribute("hide") then
				TweenService:Create(descendant, TweenInfo.new(TTC, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					BackgroundTransparency = 0,
				}):Play()
			end
		end

		local ET = TweenService:Create(
			Page2,
			TweenInfo.new(TTC * 1.2, Enum.EasingStyle.Cubic),
			{ Position = UDim2.new(0, 0, 0, 0) }
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
		end

		Dots[`Dot{PageNumber}`].UIStroke.Thickness = 2
		Dots.AProgress.Text = `Step {Page}/5`

		ET.Completed:Wait() --// stop the animation from being too quick
	end

	--// buttons
	local ConnectionsTable
	local FinalData = {}

	Frames.BottomData.Controls.ALast.MouseButton1Click:Connect(function()
		if not CanGoBack then return end

		Page -= 1
		SwapPages(Frames[`Page{Page + 1}`], Frames[`Page{Page}`], "rbxassetid://14147040290", false, Page)
	end)

	Frames.Page1.NextPage.MouseButton1Click:Connect(function()
		-- Verify the filtering service is online
		SwapPages(Frames.Page1, Frames.Loading, "rbxassetid://11102397100", true, 1)

		Env = require(script.Parent.UI.AdminHelperEnv) --// Re-fetch config just incase it changed

		if Env.EditModeIsProtected then
			Frames.Page5.Header.Text = "Access Denied"
			Frames.Page5.Body.Text =
				"Sorry, but this rank is protected and may not be edited. Please contact whoever installed Administer."

			SwapPages(Frames.Loading, Frames.Page5, "rbxassetid://14147040290", false, 5)
			return
		end

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
		SwapPages(Frames.Page2, Frames.Loading, "rbxassetid://11102397100", true, 2)

		local ExistingRank = Var.Remotes.GetRank:InvokeServer(Frames.Page2.TextInput.Text)

		if ExistingRank ~= nil and not Env.EditMode then
			Frames.Page5.Header.Text = "Oops! That's not meant to happen."
			Frames.Page5.Body.Text = `A rank already has the name {Frames.Page2.TextInput.Text}. Please re-open the creator and choose another. If you are looking to edit this rank instead, click the gear icon.`

			SwapPages(Frames.Loading, Frames.Page5, "rbxassetid://14147040290", false, 5)
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
			ConnectionsTable["Evemt" .. math.random(1, 500)] = Clone.TextInput:GetPropertyChangedSignal("Text"):Connect(function()
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
						),
					}
				end)

				if Success then
					Clone._Name.Text = `{Info[1]}`
					Clone.Image.Image = Info[2]
				else
					print(Info)
					Clone._Name.Text = `Not found`
					Clone.Image.Image = "rbxassetid://15105863258"
				end
			end

			ConnectionsTable["Evemt" .. math.random(1, 500)] = Clone.TextInput:GetPropertyChangedSignal("Text"):Connect(function()
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

		for i, v in ConnectionsTable do
			v:Disconnect()
		end

		for i, Child in Frames.Page4.Apps.Apps:GetChildren() do
			if Child.Name ~= "Template" and Child:IsA("Frame") then Child:Destroy() end
		end

		local function NewAppCard(AppName, Icon, TechName, DescText)
			local Template = Frames.Page4.Apps.Apps.Template:Clone()

			Template.Parent = Frames.Page4.Apps.Apps
			Template.AppName.Text = AppName
			Template.Icon.Image = Icon
			Template.AppDesc.Text = DescText
			Template.Name = AppName
			Template.StatusImage.Image = "rbxassetid://15106359967"
			Template.Status.Text = "Enabled"
			Template.Visible = true

			Template:SetAttribute("Showing", true)
			Template:SetAttribute("TechName", TechName)

			ConnectionsTable[AppName] = Template.Toggle.MouseButton1Click:Connect(function()
				if Template:GetAttribute("Showing") then
					Template.StatusImage.Image = "rbxassetid://15082598696"
					Template.Status.Text = "Disabled"
					Template:SetAttribute("Showing", false)
				else
					Template.StatusImage.Image = "rbxassetid://15106359967"
					Template.Status.Text = "Enabled"
					Template:SetAttribute("Showing", true)
				end
			end)
		end

		for i, v: Instance in Var.MainFrame.AppDrawer.AppHolder.Apps:GetChildren() do
			if not table.find({ "MultiThread", "SingleThread", "ZZ_AdministerData", "UIListLayout" }, v.Name) then
				if v:GetAttribute("ThreadType") == "multi" then
					for _, App in v.SubCollection:GetChildren() do
						if App.Name == "Object" or App.Name == "UIListLayout" then continue end

						NewAppCard(`{v.Title.Text} - {App.Title.Text}`, App.Icon.Image, App.Name, "This is a subapp and it does not have a description.")
					end
				else
					NewAppCard(v.Title.Text, v.Icon.Image, v.Name, v.Desc.Text)
				end
			end
		end

		for i, App in Env.EditModeApps :: { { DisplayName: string, Icon: string, Name: string } } do
			if Frames.Page4.Apps.Apps:FindFirstChild(App.DisplayName) then continue end

			NewAppCard(
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
					["MemberType"] = "Group",
					["ID"] = v.TextInput.Text or 0,
					["GroupRank"] = v.GroupRankInput.Text or 0,
				})
			else
				table.insert(Members, {
					["MemberType"] = "User",
					["ID"] = v.TextInput.Text or 0,
				})
			end
		end

		for i, v in Frames.Page4.Apps.Apps:GetChildren() do
			if not v:IsA("Frame") then continue end
			if v.Name == "Template" then continue end
			if not v:GetAttribute("Showing") then continue end

			table.insert(AllowedPages, {
				["Name"] = v:GetAttribute("TechName"),
				["DisplayName"] = v.AppName.Text or "Failed to fetch",
				["Icon"] = v.Icon.Image or "rbxassetid://0",
			})
		end

		FinalData = {
			Name = Var.Remotes.FilterString:InvokeServer(Frames.Page2.TextInput.Text)[2],
			Protected = false, -- may be configurable soon
			Members = Members,

			AllowedApps = AllowedPages,

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
			print(Result)
			SwapPages(Frames.Loading, Frames.Page5, "rbxassetid://13531414092", false, 5)
			Frames.Page5.Header.Text = require(script.Parent.UI.AdminHelperEnv).Strings.FinHeaderError
			Frames.Page5.Body.Text =
				string.format(require(script.Parent.UI.AdminHelperEnv).Strings.FinHeaderError, Result[2])
		end
	end)

	Frames.Page5.NextPage.MouseButton1Click:Connect(function()
		SwapPages(Frames.Page5, Frames.Page1, "rbxassetid://18151072839", false, 1)
		Frames.BottomData.RankTitle.Text = "Creating a rank"
		CanGoBack = true
	end)

	Frames.BottomData.Controls.Exit.MouseButton1Click:Connect(function()
		if Env.EditMode == true then
			Env.EditMode = false
			Env.EditModeMembers = {}
			Env.EditModeApps = {}
			Env.EditModeName = ""
			Env.EditModeIsProtected = false
			Env.EditModeRank = 0
		end

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
	end)
end

return Admins
