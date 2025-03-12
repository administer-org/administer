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

	local Success, Data = pcall(function()
		return Var.Remotes.GetAppInfo:InvokeServer(ServerURL, ID)
	end)

	if not Success then
		Utilities.Logging.Warn(`Failed to fetch app {ID} from {ServerURL} - is the server active and responsive?`)
		Utilities.Logging.Print(Data)
		return "The server didn't return an OK status code."
	elseif Data["Error"] ~= nil then
		Utilities.Logging.Warn(`App server lookup returned external error:`, Data["Error"])
		return "Something went wrong, check logs."
	elseif Data[1] == 404 then
		Utilities.Logging.Warn()
		return "This app is missing."
	end

	local AppInfoFrame = Var.MainFrame.Configuration.Marketplace.MainMarketplace.InstallBox

	AppInfoFrame.Head.Text = Data["Title"]
	AppInfoFrame.Metadata.Text = 
		`Created {Utilities.FormatRelativeTime(Data["Metadata"]["CreatedAt"])}\n\nUpdated {Utilities.FormatRelativeTime(Data["Metadata"]["UpdatedAt"])}\n\nUses AppPlatform {Data["Metadata"]["AppAPIPreferredVersion"]}, which is supported by your Administer version.`
	if Reason == nil then
		AppInfoFrame.MetaServer.Label.Text =
			`Shown because <b>You're subscribed to {string.split(ServerURL, "/")[3]}</b>`
	else
		AppInfoFrame.MetaServer.Label.Text = `Shown because <b>{Reason}</b>`
	end
	AppInfoFrame.MetaInstalls.Label.Text = `<b>{Utilities.ShortNumber(Data["AppDownloadCount"])}</b> installs`
	AppInfoFrame.ImportantInfo.Creator.ItemType.Image = Data["AppType"] == "Theme" and Utilities.Icon "pencil-paintbrush" or Utilities.Icon "plugin"

	AppInfoFrame.UserInfo.PFP.Image = Var.Services.Players:GetUserThumbnailAsync(
		Var.Services.Players:GetUserIdFromNameAsync(Data["AppDeveloper"]),
		Enum.ThumbnailType.HeadShot,
		Enum.ThumbnailSize.Size180x180
	)
	AppInfoFrame.UserInfo.Creator.Text = `@{Data["AppDeveloper"]}`
	for _, Tag in AppInfoFrame.Tags:GetChildren() do
		if Tag.Name ~= "Tag" and Tag:IsA("Frame") then Tag:Destroy() end
	end

	for _, TagData in Data["AppTags"] do
		local Tag = AppInfoFrame.Tags.Tag:Clone()

		Tag.TagText.Text = TagData
		Tag.Name = TagData
		Tag.Visible = true
		Tag.TagText.TextTransparency = 0
		Tag.Parent = AppInfoFrame.Tags
	end

	AppInfoFrame.Head.HeaderLabel.Text = `Install {Data["AppName"]}`
	AppInfoFrame.Description.Text = Data["AppLongDescription"]
	AppInfoFrame.Dislikes.Text = Utilities.ShortNumber(Data["AppDislikes"])
	AppInfoFrame.Likes.Text = Utilities.ShortNumber(Data["AppLikes"])

	local Percent = tonumber(Data["AppLikes"]) :: number
		/ (tonumber(Data["AppDislikes"]) :: number + tonumber(Data["AppLikes"]) :: number)
	AppInfoFrame.RatingBar.Positive.Size = UDim2.new(Percent, 0, 1, 0)
	AppInfoFrame.RatingBar.Positive.Percentage.Text = math.round(Percent * 100) .. "%"

	AppInfoFrame.Install.MouseButton1Click:Connect(function()
		AppInfoFrame.Install.HeaderLabel.Text = "Installing..."
		AppInfoFrame.Install.ImageLabel.Image = "rbxassetid://84027648824846"

		AppInfoFrame.Install.HeaderLabel.Text = Var.Remotes.InstallApp:InvokeServer(ServerURL, ID)[2]
		AppInfoFrame.Install.ImageLabel.Image = "rbxassetid://14651353224"
	end)

	AppInfoFrame.Head.Close.MouseButton1Click:Connect(function()
		Frontend.Popup.Close(AppInfoFrame, AppInfoFrame.Parent.MainMarketplace)
	end)

	Frontend.Popup.Open(
		Var.MainFrame.Configuration.Marketplace.Install,
		Var.MainFrame.Configuration.Marketplace.MainMarketplace,
		UDim2.fromScale(0.868, 1)
	)

	return "More"
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
	local Result = Var.Remotes.SearchAppsByMarketplaceServer:InvokeServer("https://administer.notpyx.me", Query)
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
	Market.MPFrozen.Visible = false

	if InProgress then
		Utilities.Logging.Warn("You're clicking too fast or your app servers are unresponsive! Please slow down.")
		Market.MPFrozen.Visible = true

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
		NewCard.Server.Text = `App by @{CardData.developer.Name} from {CardData.Server}`

		NewCard.Stats.Downloads.Label.Text = Utilities.ShortNumber(CardData.downloads)
		NewCard.Stats.Rating.Label.Text = CardData.rating

		NewCard.Stats.DownloadButton.Activator.MouseButton1Click:Connect(function()
			Apps.Show(CardData.Server, CardData.id, CardData.Server)
		end)
	end

	local AppList = List or Var.Remotes.GetAppList:InvokeServer(Var.Marketplace.ActivePageType)

	if Var.Marketplace.ActivePage == "Featured" then
		local Featured = {}
		local Index = 1

		for _, Item in Market.MainMarketplace.Featured.TopGrid:GetChildren() do
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
			Card(App, Market.MainMarketplace.Featured.TopGrid)
		end
	end



	if AppList[1] == false then
		Utilities.Logging.Warn("You're clicking too fast or your app servers are unresponsive! Please slow down.")
		Var.MainFrame.Configuration.Marketplace.MPFrozen.Visible = true
		Var.MainFrame.Configuration.Marketplace.MPFrozen.Subheading1.Text = Utilities.Translate("Configuration.Marketplace.MPFrozen.Subheading1")

		return
	end

	for Index, App in AppList do
		print(App)
		if App["processed_in"] ~= nil then
			Utilities.Logging.Print(`Loaded {#AppList - 1} apps from the database in {App["processed_in"]}s`)
			continue
		end

		local Frame = Market.MainMarketplace.Content.Template:Clone()
		Frame.Parent = Var.MainFrame.Configuration.Marketplace.MainMarketplace.Content

		Frame.AppName.Text = App["Name"]
		Frame.ShortDesc.Text = App["ShortDescription"]
		Frame.InstallCount.Text = App["DownloadCount"]
		Frame.Rating.Text = string.sub(string.gsub(App["AppRating"], "0.", ""), 1, 2) .. "%"
		Frame.Name = Index

		table.insert(
			Connections,
			Frame.Install.MouseButton1Click:Connect(function()
				Frame.InstallIcon.Image = "rbxassetid://84027648824846"
				Frame.InstallLabel.Text = "Loading..."
				
				Frame.InstallLabel.Text = Apps.Show(App["AppServer"], App["AppID"], "")
				Frame.InstallIcon.Image = "rbxassetid://16467780710"
			end)
		)

		Frame.Visible = true
	end

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

function Apps.LoadPage(Configuration, AppsMenu)
	Configuration.MenuBar.New.CApps.Click.MouseButton1Click:Connect(function()
		for i, AppItem: Instance in { workspace } do --// TODO
			if not AppItem:IsA("CanvasGroup") or AppItem.Name == "Template" then continue end
			AppItem:Destroy()
		end

		local AppsList = Var.Remotes.GetAllApps:InvokeServer("Bootstrapped")

		for k, App in AppsList do
			local NewTemplate = AppsMenu.Content.Template:Clone()

			NewTemplate.AppName.Text = k
			NewTemplate.Name = k
			NewTemplate.Logo.Image = App["AppButtonConfig"]["Icon"]
			NewTemplate.AppShortDesc.Text = App["PrivateAppDesc"] ~= nil and App["PrivateAppDesc"]
				or "This app is installed locally in your Apps folder and metadata has not been loaded."
			NewTemplate.InstallDate.Text = `Installed {App["InstalledSince"] ~= nil and Utilities.FormatRelativeTime(
				App["InstalledSince"]
			) or "locally"}`

			if not Var.EnableEditableImages then
				NewTemplate.BackgroundImage.Image = App["AppButtonConfig"]["Icon"]
			else
				NewTemplate.BackgroundImage.ImageContent = Content.fromObject(
					require(script.Parent.Parent.Libraries.QuickBlur):Blur(
						game:GetService("Var.Services.AssetService"):CreateEditableImageAsync(
							App["AppButtonConfig"]["BGOverride"] ~= nil and App["AppButtonConfig"]["BGOverride"]
								or App["AppButtonConfig"]["Icon"]
						),
						10,
						6
					)
				)
			end

			NewTemplate.Parent = AppsMenu.Content
			NewTemplate.Visible = true

			--// buttons!!!
			NewTemplate.Disable.MouseButton1Click:Connect(function(Close)
				Frontend.Popup.new(
					`Disable "{k}"`,
					`You can re-enable it from the "Disabled Apps" menu. The app may be able to continue running for this session but it will not be started in any new servers.`,
					{
						{
							["Text"] = "Yes",
							["Icon"] = "",
							["Callback"] = function(_Close)
								Var.Remotes.ManageApp:InvokeServer({
									["App"] = App["AppID"],
									["Action"] = "disable",
									["Source"] = "Apps UI",
								})

								_Close(false)
								Apps.LoadPage(Configuration, AppsMenu)
							end,
						},
						{
							["Text"] = "Cancel",
							["Icon"] = "",
							["Callback"] = function(_Close)
								_Close(false)
							end,
						},
					},
					App["AppButtonConfig"]["Icon"],
					App
				)
			end)

			NewTemplate.Delete.MouseButton1Click:Connect(function()
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
								Apps.LoadPage(Configuration, AppsMenu)
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
					App["AppButtonConfig"]["Icon"],
					App
				)
			end)

			--// animation todo
			NewTemplate.Settings.MouseButton1Click:Connect(function()
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
		AppsMenu.Options.Exit.MouseButton1Click:Connect(function()
			AppsMenu.Options.Visible = false
		end)
	end)
end

return Apps
