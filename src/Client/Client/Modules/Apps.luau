--// pyxfluff 2025

--// This is mostly for the Marketplace but has some other app-related functions.

local Modules   = script.Parent

local Types     = require(Modules.Types)
local Var       = require(Modules.Variables)
local Frontend  = require(Modules.Frontend)
local Utilities = require(Modules.Utilities)

local Apps = {}
local Connections = {}

function Apps.AddAppDrawerButton(ButtonConfig: Types.ButtonConfig)
	table.insert(Var.CombinedButtonConfig, ButtonConfig)

	local AppsHolder = Var.MainFrame.AppDrawer.AppHolder.Apps

	if #ButtonConfig.SubIcons == 0 then
		--// Just make the one
		local Button = AppsHolder.SingleThread:Clone()

		Button.Parent = AppsHolder
		Button.Icon.Image = ButtonConfig.Icon
		Button.Title.Text = ButtonConfig.AppName

		Button.Visible = true

		Button.Activator.MouseButton1Click:Connect(function()
			Frontend.Drawer.Close()
			Frontend.SwapApps(ButtonConfig, 0, Button)
			ButtonConfig.MainButtonClick()
		end)

		ButtonConfig.MainButtonFrame:SetAttribute("AdmLinkSinglePage", true)

		return Button
	else
		local Button = AppsHolder.MultiThread:Clone()
		local Height = 0

		Button.Name = ButtonConfig.AppName
		Button.Parent = AppsHolder
		Button.Icon.Image = ButtonConfig.Icon
		Button.Title.Text = ButtonConfig.AppName

		Button.Visible = true

		Button.Activator.MouseButton1Click:Connect(function()
			if ButtonConfig.MainButtonFrame == nil then return end

			Frontend.Drawer.Close()
			Frontend.SwapApps(ButtonConfig, 0, Button)
			ButtonConfig.MainButtonClick()
		end)

		for Index, Icon in ButtonConfig.SubIcons do
			local Clone = Button.SubCollection.Object:Clone()

			Clone.Icon.Image = Icon.Icon
			Clone.Title.Text = Icon.Name

			Clone.Activator.MouseButton1Click:Connect(function()
				Frontend.Drawer.Close()
				Frontend.SwapApps(ButtonConfig, Index, Clone)
				Icon.Click()
			end)

			Clone.Parent = Button.SubCollection
			Clone.Visible = true
			Clone.Name = Icon.Name

			Height += .23
		end

		Button.SubHierarchyLine.Size = UDim2.new(.025, 0, Height, 0)

		return Button
	end
end

function Apps.GetVersionLabel(RequestedAPIVersion: number): string
	return `<font color="rgb(139,139,139)">Your version </font>{RequestedAPIVersion == Var.AppAPIVersion and `<font color="rgb(56,218,111)">is supported! ({Var.VersionString})</font>` or `<font color="rgb(255,72,72)">may not be supported ({Var.VersionString})</font>`}`
end

function Apps.Show(ServerURL, ID, Reason): string
	Utilities.Logging.Print("Downloading full info for that app...")

	local TI = TweenInfo.new((tonumber(Utilities.GetSetting("AnimationSpeed")) or 1) * 2, Enum.EasingStyle.Quart)
	local Success, Data = pcall(function()
		return Var.Remotes.GetAppInfo:InvokeServer(ServerURL, ID)
	end)

	if not Success then
		Utilities.Logging.Warn(`Failed to fetch app {ID} from {ServerURL} - is the server active and responsive?`)
		Utilities.Logging.Print(Data)
		return "The server didn't return an OK status code."
	elseif Data["Error"] ~= nil then
		Utilities.Logging.Warn(`App server lookup returned external error:`, Data["Error"])
		return "Something went wrong."
	elseif Data[2] == 404 then
		Utilities.Logging.Warn(Data[2])
		return "App not found."
	end

	local AppInfoFrame = Var.MainFrame.Configuration.Marketplace.MainMarketplace.InstallBox

	Data = Data[2]

	AppInfoFrame.AppIcon.Image = `rbxassetid://{Data["IconID"]}`
	AppInfoFrame.AppIconBG.Image = `rbxassetid://{Data["BlurredIcon"]}`

	AppInfoFrame.Metadata.Text = 
		`{string.gsub(Utilities.Translate("Configuration.Marketplace.Install.MetaCreated.Label"), "{{ }}", Utilities.FormatRelativeTime(Data["Metadata"]["CreatedAt"]))}` .. 
		`\n\n{string.gsub(Utilities.Translate("Configuration.Marketplace.Install.MetaUpdated.Label"), "{{ }}",  Utilities.FormatRelativeTime(Data["Metadata"]["UpdatedAt"]))}` ..
		`\n\n{string.format(Utilities.Translate("appplatform.Supported"), Data["Metadata"]["AppAPIPreferredVersion"])}`
	--if Reason == nil then Configuration.Marketplace.Install.MetaServer.Label
	--	AppInfoFrame.MetaServer.Label.Text =
	--		`Shown because <b>You're subscribed to {string.split(ServerURL, "/")[3]}</b>`
	--else
	--	AppInfoFrame.MetaServer.Label.Text = `Shown because <b>{Reason}</b>`
	--end
	AppInfoFrame.Details.Downloads.Value.Text = Data["Downloads"]
	AppInfoFrame.ImportantInfo.Others.ItemType.Image = Data["AppType"] == "Theme" and Utilities.Icon "pencil-paintbrush" or Utilities.Icon "plugin"

	AppInfoFrame.Details.Creator.Icon.Image = Var.Services.Players:GetUserThumbnailAsync(
		Data["Developer"]["ID"],
		Enum.ThumbnailType.HeadShot,
		Enum.ThumbnailSize.Size180x180
	)
	AppInfoFrame.Details.Creator.Value.Text = `@{Data["Developer"]["Name"]}`
	for _, Tag in AppInfoFrame.Details:GetChildren() do
		if Tag:GetAttribute("IsTag") then Tag:Destroy() end
	end

	for _, TagData in Data["Tags"] do
		local Tag = AppInfoFrame.Details.TagTemplate:Clone()

		Tag.Value.Text = TagData
		Tag.Name = TagData
		Tag.Visible = true
		Tag.Parent = AppInfoFrame.Details

		Tag:SetAttribute("IsTag", true)
	end

	AppInfoFrame.Head.Text = Data["Name"]
	AppInfoFrame.Subheader.Text = Data["Title"]
	AppInfoFrame.Description.Text = Data["LongDescription"]

	AppInfoFrame.Details.Votes.Dislikes.Value.Text = Utilities.ShortNumber(Data["Votes"]["Dislikes"])
	AppInfoFrame.Details.Votes.Likes.Value.Text = Utilities.ShortNumber(Data["Votes"]["Likes"])
	AppInfoFrame.Details.Favorites.Value.Text = Utilities.ShortNumber(Data["Votes"]["Favorites"])

	local Percent = tonumber(Data["Votes"]["Likes"]) / (tonumber(Data["Votes"]["Dislikes"])
		+ tonumber(Data["Votes"]["Likes"]))

	Connections["DownloadClick"] = AppInfoFrame.Details.Downloads.Install.MouseButton1Click:Connect(function()
		AppInfoFrame.Details.Downloads.Value.Text = Utilities.Translate("generic.Loading") .. "..."
		AppInfoFrame.Details.Downloads.Icon.Image = Utilities.Icon "hourglass-wait"

		local Res = Var.Remotes.InstallApp:InvokeServer(ServerURL, ID, Data["Name"])

		AppInfoFrame.Details.Downloads.Value.Text = Res[2]
		AppInfoFrame.Details.Downloads.Icon.Image = Utilities.Icon "download"

		task.delay(5, function()
			AppInfoFrame.Details.Downloads.Value.Text = Utilities.ShortNumber(Data["Downloads"])
		end)
	end)

	Var.MainFrame.Configuration.Marketplace.MainMarketplace[Var.Marketplace.ActivePage].Visible = false
	AppInfoFrame.Visible = true

	Var.Services.TweenService:Create(AppInfoFrame.Details.Votes.VotePercentage, TI, { Size = UDim2.fromScale(Percent, 1) })
		:Play()
	
	if not AppInfoFrame.Details.Votes.Likes:FindFirstChild("TextButton") then
		for i = 1, 2 do
			local Button = Instance.new("TextButton")
			
			Button.BackgroundTransparency = 1
			Button.Size = UDim2.fromScale(1,1)
			Button.Text = ""
			
			Button.Parent = (i == 1 and AppInfoFrame.Details.Votes.Likes or AppInfoFrame.Details.Votes.Dislikes)
		end
	end
	
	Connections["LikeButton"] = AppInfoFrame.Details.Votes.Likes.TextButton.MouseButton1Click:Connect(function()
		print(Var.Remotes.Vote:InvokeServer(ServerURL, ID, 1))
		
		for _, Event in Connections do
			Event:Disconnect()
		end
		
		return Apps.Show(ServerURL, ID, Reason)
	end)
	
	Connections["DislikeButton"] = AppInfoFrame.Details.Votes.Dislikes.TextButton.MouseButton1Click:Connect(function()
		Var.Remotes.Vote:InvokeServer(ServerURL, ID, 0)
		
		for _, Event in Connections do
			Event:Disconnect()
		end
		
		return Apps.Show(ServerURL, ID, Reason)
	end)

	return "Get"
end

function Apps.Clear(): ()
	for _, Connection in Connections do
		(Connection :: RBXScriptConnection):Disconnect()
	end

	for _, Item in Var.MainFrame.Configuration.Marketplace.MainMarketplace.Content:GetChildren() do
		if Item:IsA("Frame") and Item.Name ~= "Template" then Item:Destroy() end
	end
end

function Apps.Search(Query: string): {}
	local Result = Var.Remotes.SearchAppsByMarketplaceServer:InvokeServer(Var.Marketplace.Servers, Query)
	local Final: { { Type: string, Value: any } } = {}

	if Result.SearchIndex == "NoResultsFound" then
		return {
			Success = false,
			Data = {
				{
					Type = "text",
					Value = "Sorry, but we couldn't find any results for that.",
				},
			},
		}
	elseif Result.RatioInfo.IsRatio == true then
		table.insert(Final, {
			Type = "text",
			Value = `We think you meant {Result.RatioInfo.RatioKeyword} ({string.sub(
				string.gsub(Result.RatioInfo.RatioConfidence, "0.", ""),
				1,
				2
			) .. "%"} confidence), results for it may be included.`,
		})
	end

	for Index, SearchResult in Result.SearchIndex do
		local Frame = Var.MainFrame.Configuration.Marketplace.MainMarketplace.Content.Template:Clone()
		Frame.Parent = Var.MainFrame.Configuration.Marketplace.MainMarketplace.Content

		Frame.AppName.Text = SearchResult["AppName"]
		Frame.ShortDesc.Text = SearchResult["AppShortDescription"]
		Frame.InstallCount.Text = SearchResult["AppDownloadCount"]
		Frame.Rating.Text = "--%"
		Frame.Name = Index

		table.insert(Final, {
			Type = "card",
			Value = {
				Name = SearchResult["Name"],
				ShortDesc = SearchResult["ShortDescription"],
				InstallCount = SearchResult["DownloadCount"],
				Rating = SearchResult["Rating"]["Ratio"],
				ShownBecause = `You searched for it ({SearchResult["IndexedBecause"]} in query).`,
				SourceServer = "https://administer.notpyx.me",
				AdministerID = SearchResult["Metadata"]["AdministerID"],
				Index = Index,
			},
		})

		Frame.Visible = true
	end

	return {
		Success = true,
		Data = Final,
	}
end

local InProgress = false

function Apps.LoadList(List: {} | nil): ()
	local Market = Var.MainFrame.Configuration.Marketplace

	Utilities.Logging.Print("Refreshing app list...")
	
	if InProgress then
		Utilities.Logging.Warn("You're clicking too fast or your app servers are unresponsive! Please slow down.")
		
		Var.MainFrame.Configuration.Marketplace.MainMarketplace[Var.Marketplace.ActivePage].Visible = false
		Var.Marketplace.ActivePage = "MPFrozen"

		Var.MainFrame.Configuration.Marketplace.MainMarketplace.MPFrozen.Visible = true
		Var.MainFrame.Configuration.Marketplace.MainMarketplace.MPFrozen.Subheading1.Text = string.gsub(Utilities.Translate("Configuration.Marketplace.MPFrozen.Subheading1"),"{{ }}", "debounce triggered, app server is unresponsive")

		return
	end

	InProgress = true

	for _, Connection in Connections do
		(Connection :: RBXScriptConnection):Disconnect()
	end

	local function Card(CardData, ListLoc)
		local NewCard: Instance = ListLoc.Template:Clone()
		NewCard.Parent = ListLoc
		NewCard.Name = CardData.name
		NewCard.Visible = true

		NewCard.ObjName.Text = CardData.name
		NewCard.Server.Text = `{string.sub(CardData.short_desc, 1, 50)}{string.len(CardData.short_desc) >= 50 and "..." or ""}\n\n{Utilities.ToSentenceCase(CardData.object_type)} by @{CardData.developer.Name} from {CardData.Server}`

		NewCard.Stats.Downloads.Label.Text = Utilities.ShortNumber(CardData.downloads)
		NewCard.Stats.Rating.Label.Text = CardData.rating

		Connections[`Download-{math.random(1,4923498)}`] = NewCard.Stats.DownloadButton.Activator.MouseButton1Click:Connect(function()
			Apps.Show(CardData.Server, CardData.id, CardData.Server)
		end)
	end

	local AppList = List or Var.Remotes.GetAppList:InvokeServer(Var.Marketplace.ActivePageType)

	if Var.Marketplace.ActivePage == "AAFeatured" then
		local Featured = {}
		local Index = 1

		for _, Item in Market.MainMarketplace.AAFeatured.TopGrid:GetChildren() do
			if Item:IsA("Frame") and Item.Name ~= "Template" then Item:Destroy() end
		end

		repeat
			for SUrl, Server in AppList do
				--// This does not work, do not uncomment it, I do not know why.
				--if pcall(function() Server[Index]["processed_in"] = Server[Index]["processed_in"] end) then continue end

				table.insert(Featured, Server[Index])
			end

			Index += 1
		until #Featured == 4 or Index == 30

		print(Featured)

		for _, App in Featured do
			Card(App, Market.MainMarketplace.AAFeatured.TopGrid)
		end
	end



	if AppList[1] == false then
		Utilities.Logging.Warn("Failed to fetch!", AppList)
		
		Var.MainFrame.Configuration.Marketplace.MainMarketplace[Var.Marketplace.ActivePage].Visible = false
		Var.Marketplace.ActivePage = "MPFrozen"
		
		Var.MainFrame.Configuration.Marketplace.MainMarketplace.MPFrozen.Visible = true
		Var.MainFrame.Configuration.Marketplace.MainMarketplace.MPFrozen.Subheading1.Text = string.gsub(Utilities.Translate("Configuration.Marketplace.MPFrozen.Subheading1"),"{{ }}", "500")

		return
	end

	--for Index, App in AppList do
	--	print(App)
	--	if App["processed_in"] ~= nil then
	--		Utilities.Logging.Print(`Loaded {#AppList - 1} apps from the database in {App["processed_in"]}s`)
	--		continue
	--	end

	--	local Frame = Market.MainMarketplace.Content.Template:Clone()
	--	Frame.Parent = Var.MainFrame.Configuration.Marketplace.MainMarketplace.Content

	--	Frame.AppName.Text = App["Name"]
	--	Frame.ShortDesc.Text = App["ShortDescription"]
	--	Frame.InstallCount.Text = App["DownloadCount"]
	--	Frame.Rating.Text = string.sub(string.gsub(App["AppRating"], "0.", ""), 1, 2) .. "%"
	--	Frame.Name = Index

	--	table.insert(
	--		Connections,
	--		Frame.Install.MouseButton1Click:Connect(function()
	--			Frame.InstallIcon.Image = "rbxassetid://84027648824846"
	--			Frame.InstallLabel.Text = "Loading..."

	--			Frame.InstallLabel.Text = Apps.Show(App["AppServer"], App["AppID"], "")
	--			Frame.InstallIcon.Image = "rbxassetid://16467780710"
	--		end)
	--	)

	--	Frame.Visible = true
	--end

	InProgress = false
end

function Apps.InitSerarchbar() --// TODO
	Var.MainFrame.Configuration.MenuBar.New.FMarketplace.Input.FocusLost:Connect(
		function(EnterPressed: boolean, InputThatCausedFocusLoss: InputObject)
			if not EnterPressed then return end

			Var.MainFrame.Configuration.Marketplace.PartialSearch.Visible = false
			Var.MainFrame.Configuration.Marketplace.MPFrozen.Visible = false

			Apps.Search( --// TODO
				Var.MainFrame.Configuration.MenuBar.New.FMarketplace.Input.Text
			)
		end
	)
end

function Apps.LoadPage()
	local AppsMenu = Var.MainFrame.Configuration.Marketplace.MainMarketplace.XLibrary
	for i, AppItem: Instance in AppsMenu.Content:GetChildren() do --// TODO
		if not AppItem:IsA("CanvasGroup") or AppItem.Name == "Template" then continue end
		AppItem:Destroy()
	end

	local AppsList = Var.Remotes.GetInstalledApps:InvokeServer("Bootstrapped")
	
	print(AppsList)

	for k, App in AppsList[2] do
		local NewTemplate = AppsMenu.Content.Template:Clone()

		NewTemplate.AppName.Text = k
		NewTemplate.Name = k
		NewTemplate.Logo.Image = App["Icon"]
		NewTemplate.AppShortDesc.Text = App["Description"]
		NewTemplate.InstallDate.Text = `Installed {App["InstalledSince"] ~= 0 and Utilities.FormatRelativeTime(
			App["InstalledSince"]
		) or "locally"}`

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

		NewTemplate.Parent = AppsMenu.Content
		NewTemplate.Visible = true

		NewTemplate.Buttons.Delete.MouseButton1Click:Connect(function()
			Frontend.Popup.new(
				`Remove "{k}"?`,
				`This app will not start in any new servers but will continue running.`,
				{
					{
						["Text"] = "Yes",
						["Icon"] = "",
						["Callback"] = function(_Close)
							Var.Remotes.ManageApp:InvokeServer({
								["AppID"] = App["AppID"],
								["Action"] = "remove",
								["Source"] = "Apps UI",
							})

							_Close(false)
							Apps.LoadPage(AppsMenu)
						end,
					},
					{
						["Text"] = "Cancel",
						["Icon"] = "",
						["Callback"] = function(_Close)
							_Close()
						end,
					},
				},
				App["Icon"],
				App
			)
		end)

		--// animation todo
		NewTemplate.Buttons.Settings.MouseButton1Click:Connect(function()
			AppsMenu.Options.Visible = true

			--// Eventually dev apps will behave the same as normal ones. Just not today
			AppsMenu.Options.Frame.HeaderLabel.Text = `Configure "{k}"`
			AppsMenu.Options.DetailsCard.BackgroundImage.Image = App["AppButtonConfig"]["Icon"]
			AppsMenu.Options.DetailsCard.Logo.Image = App["AppButtonConfig"]["Icon"]
			AppsMenu.Options.DetailsCard.AppName.Text = k
			AppsMenu.Options.DetailsCard.AppShortDesc.Text = App["PrivateAppDesc"] ~= nil and App["PrivateAppDesc"]
				or "Metadata cannot be loaded from locally installed applications."
			AppsMenu.Options.DetailsCard.Details.Info_Source.Label.Text =
				`Installed from {App["InstallSource"] ~= nil and string.gsub(
					string.gsub(App["InstallSource"], "https://", ""),
					"http://",
					""
				) or "your local Apps folder"}`
			AppsMenu.Options.DetailsCard.Details.Info_PingTime.Label.Text = `✓ {App["BuildTime"]}s`
			AppsMenu.Options.DetailsCard.Details.Info_Version.Label.Text = App["Version"] ~= nil and App["Version"]
				or "v1"
		end)
	end

	--// out here to not have a memory leak
	--AppsMenu.Options.Exit.MouseButton1Click:Connect(function()
	--	AppsMenu.Options.Visible = false
	--end)
end

function Apps.Init()
	local Sidebar = Var.MainFrame.Configuration.Marketplace.Sidebar
	local ActiveApps = Var.Remotes.GetInstalledApps:InvokeServer("Combined")
	
	Apps.LoadPage()

	for _, Button in Sidebar.Buttons:GetChildren() do
		local Watcher = Instance.new("TextButton")
		Watcher.BackgroundTransparency = 1
		Watcher.Text = ""
		Watcher.Parent = Button
		
		Watcher.Size = UDim2.new(1,0,1,0)
		Watcher.Position = UDim2.new(0,0,0,0)
		
		Watcher.MouseButton1Click:Connect(function()
			Var.MainFrame.Configuration.Marketplace.MainMarketplace.MPFrozen.Visible = false --// just incase
			Var.MainFrame.Configuration.Marketplace.MainMarketplace[Var.Marketplace.ActivePage].Visible = false
			
			Var.Marketplace.ActivePage = Button.Name
			Var.Marketplace.ActivePageType = Button.Name:upper()
			
			if Button.Name == "Themes" or Button.Name == "Apps" then
				Var.Marketplace.ActivePage = "CardGrid"
				Var.Marketplace.ActivePageType = Button.Name
				Apps.LoadList()
			elseif Button.Name == "AAFeatured" then
				Var.Marketplace.ActivePageType = "FEATURED"
			end
			
			Var.MainFrame.Configuration.Marketplace.MainMarketplace[Var.Marketplace.ActivePage].Visible = true
		end)
	end
	
	--// hopefully the icon pack has loaded by now?
	Sidebar.Parent.MainMarketplace.XLibrary.AdministerLogo.Image = `rbxassetid://{Var.Icons.logos["administer-blue"]}` 
	Sidebar.Parent.MainMarketplace.XLibrary.GameArt.Image = Var.Remotes.GetGameArt:InvokeServer()

	--Apps.InitSerarchbar()
end

return Apps
