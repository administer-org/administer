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
		--// Just make the one
		local Button = AppsHolder.SingleThread:Clone()

		Button.Parent = AppsHolder
		Button.Name = ButtonConfig.AppName
		Button.Icon.Image = ButtonConfig.Icon
		Button.Title.Text = ButtonConfig.AppName

		Button:SetAttribute("ThreadType", "single")
		Button:SetAttribute("ButtonID", ButtonConfig.ButtonID)

		Button.Visible = Var.Remotes.CanUseApp:InvokeServer(ButtonConfig.ButtonID)

		Button.Activator.MouseButton1Click:Connect(function()
			task.defer(Frontend.Drawer.Close)

			Frontend.SwapApps(ButtonConfig, 0, Button)

			xpcall(ButtonConfig.MainButtonClick, Utilities.Logging.Warn)
		end)

		ButtonConfig.MainButtonFrame:SetAttribute("AdmLinkSinglePage", true) --// TODO: do we need this anymore?

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

		Button.Visible = Var.Remotes.CanUseApp:InvokeServer(ButtonConfig.ButtonID)

		Button.Activator.MouseButton1Click:Connect(function()
			if ButtonConfig.MainButtonFrame == nil then return end

			task.defer(Frontend.Drawer.Close)

			Frontend.SwapApps(ButtonConfig, 0, Button)

			xpcall(ButtonConfig.MainButtonClick, Utilities.Logging.Warn)
		end)

		for Index, Icon in ButtonConfig.SubIcons do
			local Clone = Button.SubCollection.Object:Clone()

			Clone.Icon.Image = Icon.Icon
			Clone.Title.Text = Icon.Name

			Clone:SetAttribute("ButtonID", `{ButtonConfig.ButtonID}\\{Icon.ButtonID}`)

			Clone.Activator.MouseButton1Click:Connect(function()
				task.defer(Frontend.Drawer.Close)
				Frontend.SwapApps(ButtonConfig, Index, Clone)

				xpcall(Icon.Click, Utilities.Logging.Warn)
			end)

			Clone.Parent = Button.SubCollection
			Clone.Visible = Var.Remotes.CanUseApp:InvokeServer(Clone:GetAttribute("ButtonID"))
			Clone.Name = Icon.Frame.Name

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
	elseif Data[2] == 500 then
		Utilities.Logging.Warn(Data[2])
		
		return "Internal Error"
	end

	local AppInfoFrame = Var.MainFrame.Configuration.Marketplace.MainMarketplace.InstallBox

	Data = Data[2]

	AppInfoFrame.AppIcon.Image = `rbxassetid://{Data["IconID"]}`
	AppInfoFrame.AppIconBG.Image = `rbxassetid://{Data["BlurredIcon"]}`
	
	AppInfoFrame.Metadata.Text = 
		`{string.gsub(Utilities.Translate("Configuration.Marketplace.Install.MetaCreated.Label"), "{{ }}", Utilities.FormatRelativeTime(Data["Metadata"]["CreatedAt"]))}` .. 
		`\n\n{string.gsub(Utilities.Translate("Configuration.Marketplace.Install.MetaUpdated.Label"), "{{ }}",  Utilities.FormatRelativeTime(Data["Metadata"]["UpdatedAt"]))}` ..
		`\n\n{string.format(Utilities.Translate("appplatform.Supported"), Data.RichConfig.Dependencies.AppPlatform)}`
	--if Reason == nil then Configuration.Marketplace.Install.MetaServer.Label
	--	AppInfoFrame.MetaServer.Label.Text =
	--		`Shown because <b>You're subscribed to {string.split(ServerURL, "/")[3]}</b>`
	--else
	--	AppInfoFrame.MetaServer.Label.Text = `Shown because <b>{Reason}</b>`
	--end
	AppInfoFrame.Details.Downloads.Value.Text = Data["Downloads"]
	AppInfoFrame.ImportantInfo.Others.ItemType.Image = Data["AppType"] == "Theme" and Utilities.Icon "pencil-paintbrush" or Utilities.Icon "plugin"
	
	local Modules = { Sensitive = {}, Insensitive = {} }
	for _, Dependency in Data.RichConfig.Dependencies.AdministerModules do
		if table.find({"AdminRunner", "Apps"}, Dependency.Name) ~= nil then
			table.insert(Modules.Sensitive, Dependency.Name)
		else
			table.insert(Modules.Insensitive, Dependency.Name)
		end 
	end
	
	local CombinedSensitive, CombinedInsensitive = "", ""
	for i, Module in Modules.Sensitive do
		CombinedSensitive = CombinedSensitive .. i ~= #Modules.Sensitive and `{Module}, ` or `and {Module}`
	end
	
	for i, Module in Modules.Insensitive do
		CombinedInsensitive = CombinedInsensitive .. i ~= #Modules.Insensitive and `{Module}, ` or `and {Module}`
	end
	
	AppInfoFrame.PrivacyUsage.Text = 
		(CombinedSensitive ~= "" and `Uses sensitive Administer modules {CombinedSensitive}` or "Does not use sensitive Administer modules") .. "\n" .. 
		(CombinedInsensitive ~= "" and `Uses insensitive Administer modules {CombinedInsensitive}` or "Does not use insensitive Administer modules") .. "\n" .. 
		`Published by <b>{string.find(ServerURL, "admsoftware.org") ~= nil and "a trusted Administer AOS instance" or "a 3rd party AOS instance"}</b>`

	AppInfoFrame.Details.Creator.Icon.Image = Var.Services.Players:GetUserThumbnailAsync(
		Data["Developer"]["ID"],
		Enum.ThumbnailType.HeadShot,
		Enum.ThumbnailSize.Size180x180
	)
	AppInfoFrame.Details.Creator.Value.Text = `@{Data["Developer"]["Name"]}`
	for _, Tag in AppInfoFrame.Details:GetChildren() do
		if Tag:GetAttribute("IsTag") then Tag:Destroy() end
	end

	for _, TagData in Data.Tags do
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

		AppInfoFrame.Details.Downloads.Icon.Image = Utilities.Icon "download"

		if not Res[1] then
			Frontend.Popup.new(
				{
					Name = Utilities.ToSentenceCase( Utilities.Translate("Configuration.Marketplace.Header.Head") ),
					Icon = Utilities.Icon "grid"
				}, {
					Primary = Utilities.Icon "warning-filled",
					SubIcon = Utilities.Icon "x"
				}, 
				Utilities.Translate("apps.InstallFail"),
				Res[2],
				{
					{
						Icon = Utilities.Icon "check-plain",
						Text = "OK",
						Callback = function(Close)
							Close()
						end
					}
				}
			)
		else
			Frontend.Toast({
				Icon = Utilities.Icon "check-plain",
				Text = "Success!",
				Subtext = "The app has loaded, but you may need to rejoin for the frontend to load.",
				Timeout = 5
			})
		end

		task.delay(2, function()
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

	local function DoVote(VoteType)
		local Response = Var.Remotes.Vote:InvokeServer(ServerURL, ID, 1)

		if Response.StatusCode == 400 then
			Frontend.Popup.new(
				{
					Name = Utilities.ToSentenceCase( Utilities.Translate("Configuration.Marketplace.Header.Head") ),
					Icon = Utilities.Icon "grid"
				}, {
					Primary = Utilities.Icon "warning-filled",
					SubIcon = Utilities.Icon "x"
				}, 
				Var.Services.HttpService:JSONDecode(Response.Body).message,
				Var.Services.HttpService:JSONDecode(Response.Body).user_facing_message,
				{
					{
						Icon = Utilities.Icon "check-plain",
						Text = "OK",
						Callback = function(Close)
							Close()
						end
					}
				}
			)
		end

		for _, Event in Connections do
			Event:Disconnect()
		end

		return Apps.Show(ServerURL, ID, Reason)
	end

	Connections["LikeButton"] = AppInfoFrame.Details.Votes.Likes.TextButton.MouseButton1Click:Connect(function()
		DoVote(1)
	end)

	Connections["DislikeButton"] = AppInfoFrame.Details.Votes.Dislikes.TextButton.MouseButton1Click:Connect(function()
		DoVote(0)
	end)

	return true
end

function Apps.Clear(): ()
	for _, Connection in Connections do
		(Connection :: RBXScriptConnection):Disconnect()
	end

	for _, Item in Var.MainFrame.Configuration.Marketplace.MainMarketplace.Content:GetChildren() do
		if Item:IsA("Frame") and Item.Name ~= "Template" then Item:Destroy() end
	end
end

function Apps.Search(Query: string, ServerURL: string?): {}
	local Result = Var.Remotes.AOSRichSearch:InvokeServer(
		ServerURL or Var.Remotes.GetPrimaryServer:InvokeServer(), 
		Query
	)

	local Final: { { Type: string, Value: any } } = {}

	if Result.index == "no_results" then
		return {
			Success = false,
			Data = {
				{
					Type = "text",
					Value = "Sorry, but we couldn't find any results for that."
				}
			},
			AOSProcessedInfo = Result.meta._aos_search_api
		}
	elseif Result.meta.ratio_info.is_ratio == true then
		table.insert(Final, {
			Type = "text",
			Value = `We think you meant {Result.meta.ratio_info.keyword} ({
			string.sub(string.gsub(Result.meta.ratio_info.confidence, "0.", ""), 1, 2) .. "%"
			} confidence), results for it may be included.`
		})
	end

	for Index, SearchResult in Result.index do
		table.insert(Final, {
			Type = "card",
			Value = SearchResult
		})
	end

	return {
		Success = true,
		Data = Final,
		AOSProcessedInfo = Result.meta._aos_search_api
	}
end

local InProgress = false

function Apps.LoadAppList(List: {}?): ()
	local Market = Var.MainFrame.Configuration.Marketplace

	if List == {} then return end

	Utilities.Logging.Print("Refreshing app list...")

	if InProgress then
		Frontend.Toast({
			Icon = Utilities.Icon "triangle-warning",
			Text = "Error loading apps",
			Subtext = "Rate limit exceeded, please slow down",
			Timeout = 10
		})
		
		Utilities.Logging.Warn("You're clicking too fast or your app servers are unresponsive! Please slow down.")

		Var.MainFrame.Configuration.Marketplace.MainMarketplace[Var.Marketplace.ActivePage].Visible = false
		Var.Marketplace.ActivePage = "MPFrozen"

		Var.MainFrame.Configuration.Marketplace.MainMarketplace.MPFrozen.Visible = true
		Var.MainFrame.Configuration.Marketplace.MainMarketplace.MPFrozen.Subheading1.Text = string.gsub(Utilities.Translate("Configuration.Marketplace.MPFrozen.Subheading1"),"{{ }}", "debounce triggered, app server is unresponsive")

		return
	end

	InProgress = true

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
			NewCard.Server.Text = `{string.sub(CardData.short_desc, 1, 50)}{string.len(CardData.short_desc) >= 50 and "..." or ""}\n\n{Utilities.ToSentenceCase(CardData.object_type)} by @{CardData.developer.Name} from {CardData.ServerName}`

			NewCard.Stats.Downloads.Label.Text = Utilities.ShortNumber(CardData.downloads)
			NewCard.Stats.Rating.Label.Text = CardData.rating

			Connections[`Download-{math.random(1,2^25)}`] = NewCard.Stats.DownloadButton.Activator.MouseButton1Click:Connect(function()
				local ShowResult = Apps.Show(CardData.Server, CardData.id, CardData.Server)
				
				if ShowResult ~= true then
					Frontend.Toast({
						Icon = Utilities.Icon "triangle-warning",
						Text = "Failed to load app",
						Subtext = ShowResult,
						Timeout = 10
					})
				end
			end)

			Connections[`Show-{math.random(1,2^25)}`] = NewCard.Stats.DownloadButton.Activator.MouseButton2Click:Connect(function()
				Frontend.Popup.new(
					{
						Icon = Utilities.Icon "grid",
						Name = "Marketplace",
						Subheader = "AOS Instance"
					},
					{
						Primary = Utilities.Icon "administer",
						SubIcon = Utilities.Icon "question-circle"
					},
					"App Info",
					`AOS Data URL: {CardData.Server}\nAOSId2: {CardData.id}\nWeighted Score: {CardData.weighted_score}\nObject Type: {CardData.object_type}\nDeveloper: {game:GetService("HttpService"):JSONEncode(CardData.developer)}`,
					{
						{
							Text = "OK",
							Icon = "check-plain",
							Callback = function(c)
								c()
							end
						}
					}
				)
			end)
		end, function(e)
			if e == "Unable to assign property Name. string expected, got nil" then
				Utilities.Logging.Print(`Server spent {CardData}s processing apps!`)
			else
				Utilities.Logging.Error(e)
			end
		end)
	end

	local AppList = List or Var.Remotes.GetAppList:InvokeServer(Var.Marketplace.ActivePageType)

	if Var.Marketplace.ActivePage == "AAFeatured" then
		local Featured = {}
		local Index = 1

		for _, Item in Market.MainMarketplace.AAFeatured.TopGrid:GetChildren() do
			if Item:IsA("CanvasGroup") and Item.Name ~= "Template" then Item:Destroy() end
		end

		repeat
			for SUrl, Server in AppList do
				--// This does not work, do not uncomment it, I do not know why.
				--if pcall(function() Server[Index]["processed_in"] = Server[Index]["processed_in"] end) then continue end

				if Server[Index] == nil then 
					--// try again next time 
					--Index -= 2 actually i think this will cause an infinite loop so ill jsut fix it if there are issues
				else
					table.insert(Featured, Server[Index])
				end
			end

			Index += 1
		until #Featured == 4 or Index == 30

		for _, App in Featured do
			Card(App, Market.MainMarketplace.AAFeatured.TopGrid)
		end

		--// make the 1st result the featured card, will prob have an algo soon
		local TopCard = Market.MainMarketplace.AAFeatured.MainHot
		local Selected = Featured[1]

		TopCard.ObjName.Text = Selected.name
		TopCard.Server.Text = `{Utilities.ToSentenceCase(Selected.object_type)} by @{Selected.developer.Name} from {Selected.ServerName}`
		TopCard.Stats.Installs.Label.Text = Utilities.ShortNumber(Selected.downloads)
		TopCard.Stats.Rating.Label.Text = Selected.rating
		TopCard.ImageLabel.Image = `rbxassetid://{Selected.image_id}`

		TopCard.Stats.DownloadButton.MouseButton1Click:Connect(function()
			Apps.Show(Selected.Server, Selected.id, Selected.Server)
		end)

		TopCard.Stats.DownloadButton.MouseButton2Click:Connect(function()
			Frontend.Popup.new(
				{
					Icon = Utilities.Icon "grid",
					Name = "Marketplace",
					Subheader = "AOS Instance"
				},
				{
					Primary = Utilities.Icon "grid",
					SubIcon = Utilities.Icon "question-circle"
				},
				"Why is this here?",
				`You're seeing this featured because it's server, {Selected.ServerName} ({Selected.Server}), has reported its weighted score to be {Selected.weighted_score}, which is the highest among your installed servers.\nIf this is being done maliciously, remove the server.`,
				{
					{
						Text = "OK",
						Icon = "check",
						Callback = function(c)
							c()
						end
					}
				}
			)
		end)
	else
		local Featured = {}
		local Index = 1

		for _, Item in Market.MainMarketplace.CardGrid:GetChildren() do
			if Item:IsA("CanvasGroup") and Item.Name ~= "Template" then Item:Destroy() end
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

		Var.MainFrame.Configuration.Marketplace.MainMarketplace[Var.Marketplace.ActivePage].Visible = false
		Var.Marketplace.ActivePage = "MPFrozen"

		Var.MainFrame.Configuration.Marketplace.MainMarketplace.MPFrozen.Visible = true
		Var.MainFrame.Configuration.Marketplace.MainMarketplace.MPFrozen.Subheading1.Text = string.gsub(Utilities.Translate("Configuration.Marketplace.MPFrozen.Subheading1"),"{{ }}", "500")

		return
	end

	InProgress = false
end

function Apps.InitSerarchbar()
	local MP = Var.MainFrame.Configuration.Marketplace
	MP.Sidebar.Searchbar.Input:GetPropertyChangedSignal("Text"):Connect(function()
		MP.Sidebar.Searchbar.Title.Text = MP.Sidebar.Searchbar.Input.Text 	
	end)

	MP.Sidebar.Searchbar.Input.FocusLost:Connect(
		function(EnterPressed: boolean, ...)
			if not EnterPressed then return end

			MP.MainMarketplace.MPFrozen.Visible = false

			local Cards = {}
			local ServerURL = Var.Remotes.GetPrimaryServer:InvokeServer()
			local SearchResult = Apps.Search(
				MP.Sidebar.Searchbar.Input.Text
			)

			for _, Data in SearchResult.Data do
				if Data.Type == "text" then
					Frontend.Toast({
						Icon = "search",
						Text = "Information",
						Subtext = Data.Value,
						Timeout = 5
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
						Server = ServerURL
					})
				end
			end

			if #Cards == 0 then return end

			MP.MainMarketplace[Var.Marketplace.ActivePage].Visible = false
			Var.Marketplace.ActivePage = "CardGrid"
			MP.MainMarketplace.CardGrid.Visible = true
			
			Cards = {
				[ServerURL] = Cards
			}

			Apps.LoadAppList(Cards)
		end
	)
end

function Apps.LoadLibrary()
	local AppsMenu = Var.MainFrame.Configuration.Marketplace.MainMarketplace.XLibrary
	for i, AppItem: Instance in AppsMenu.Content:GetChildren() do
		if not AppItem:IsA("CanvasGroup") or AppItem.Name == "Template" or AppItem.Name == "ServerTemplate" then continue end
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

		NewTemplate.Buttons.LongText.Title.Text = `Initialized in {App.BuildTime * 1000}ms`

		NewTemplate.Parent = AppsMenu.Content
		NewTemplate.Visible = true

		NewTemplate.Buttons.Delete.MouseButton1Click:Connect(function()
			Frontend.Popup.new(
				{
					Name = Utilities.Translate("Configuration.Marketplace.Header.Head"),
					Icon = `rbxassetid://{Var.Icons.logos["administer-blue"]}`
				},
				{
					Primary = `rbxassetid://{App["Icon"]}`,
					SubIcon = Utilities.Icon "warning-filled"
				},
				Utilities.Translate("Configuration.Apps.MessageBox.Header"):gsub("{{ app }}", k),
				Utilities.Translate("Configuration.Apps.MessageBox.Content"),
				{
					{
						Text = Utilities.Translate("generic.Yes"),
						Icon = Utilities.Icon "trash",
						Callback = function(_Close)
							local Response = Var.Remotes.ManageApp:InvokeServer(App.AppID)

							_Close()

							if Response[1] == false then
								Frontend.Popup.new(
									{
										Name = "Administer",
										Icon = `rbxassetid://{Var.Icons.logos["administer-blue"]}`
									},
									{
										Primary = `rbxassetid://{App["Icon"]}`,
										SubIcon = Utilities.Icon "x"
									},

									Utilities.Translate("generic.error.Generic"),
									Response[2],

									{{
										Text = Utilities.Translate("generic.OK"),
										Icon = Utilities.Icon "check-plain",
										Callback = function(Cls)
											Cls()
										end
									}}
								)
							else
								_Close()
								Apps.LoadLibrary()
							end	
						end
					},
					{
						Text = Utilities.Translate("generic.Cancel"),
						Icon = Utilities.Icon "x",
						Callback = function(_Close)
							_Close()
						end
					}
				}
			)
		end)
	end

	local AppServers = Var.Remotes.GetAppServers:InvokeServer()

	for _, Server in AppServers[2] do
		local NewTemplate = AppsMenu.Content.ServerTemplate:Clone()

		xpcall(function()
			NewTemplate.ServerName.Text = Server.Name
			NewTemplate.Name = Server.Name
			NewTemplate.Metadata.Text = `{Server.Banner.text}\n\nAOS v{Server.AOSVers}\n\n{Server.IsDev and "Development mode \n\n"}{Server.URL}`
			NewTemplate.InstallDate.Text = `Installed {Server.ServerInstall ~= 0 and Utilities.FormatRelativeTime(
				Server.ServerInstall
			) or "locally"}`

			NewTemplate.BackgroundImage.BackgroundColor3 = Color3.fromHex(Server.Banner.color)
			NewTemplate.Buttons.LongText.Title.Text = `{Server.PingTime}ms · Running since {Utilities.FormatRelativeTime(os.time() - Server.Uptime)}`

		end, function()
			--// must be an error
			NewTemplate.ServerName.Text = Server.URL
			NewTemplate.Name = Server.URL
			NewTemplate.Metadata.Text = `This server seems to be experiencing an outage.`
			NewTemplate.InstallDate.Text = `Installed {Server.ServerInstall ~= 0 and Utilities.FormatRelativeTime(
				Server.ServerInstall
			) or "locally"}`

			NewTemplate.Buttons.LongText.Icon.BackgroundColor3 = Color3.fromRGB(255, 108, 110)
			NewTemplate.Buttons.LongText.Title.Text = `{Server.PingTime}ms · HTTP {Server.Code}`	
		end)

		NewTemplate.Parent = AppsMenu.Content
		NewTemplate.Visible = true

		NewTemplate.Buttons.Delete.MouseButton1Click:Connect(function()
			Frontend.Popup.new(
				{
					Name = Utilities.Translate("Configuration.Marketplace.Header.Head"),
					Icon = `rbxassetid://{Var.Icons.logos["administer-blue"]}`
				},
				{
					Primary = `rbxassetid://{Var.Icons.logos["administer-blue"]}`,
					SubIcon = Utilities.Icon "warning-filled"
				},
				Utilities.Translate("Configuration.Apps.MessageBox.Header"):gsub("{{ app }}", Server.URL),
				"Uninstalling app servers may have unintended side effects. Please make sure you have at least one server installed.",
				{
					{
						Text = Utilities.Translate("generic.Yes"),
						Icon = Utilities.Icon "trash",
						Callback = function(_Close)
							local Response = Var.Remotes.RemoveAppServer:InvokeServer(Server.URL)

							_Close()

							if Response[1] == false then
								Frontend.Popup.new(
									{
										Name = "Administer",
										Icon = `rbxassetid://{Var.Icons.logos["administer-blue"]}`
									},
									{
										Primary = `rbxassetid://{Var.Icons.logos["administer-blue"]}`,
										SubIcon = Utilities.Icon "x"
									},

									Utilities.Translate("generic.error.Generic"),
									Response[2],

									{{
										Text = Utilities.Translate("generic.OK"),
										Icon = Utilities.Icon "check-plain",
										Callback = function(Cls)
											Cls()
										end
									}}
								)
							else
								Apps.LoadLibrary()
							end	
						end
					},
					{
						Text = Utilities.Translate("generic.Cancel"),
						Icon = Utilities.Icon "x",
						Callback = function(_Close)
							_Close()
						end
					}
				}
			)
		end)
	end
end

function Apps.Init(JustRefreshCounts)
	local Sidebar = Var.MainFrame.Configuration.Marketplace.Sidebar
	local ActiveApps = Var.Remotes.GetInstalledApps:InvokeServer("Combined")
	local Counts = Var.Remotes.GetAppCounts:InvokeServer()

	Sidebar.Buttons.XLibrary.Resources.Content.Apps.Text = `{Counts.Apps} apps, {Counts.Servers} servers`

	if JustRefreshCounts then return end

	for _, Button in Sidebar.Buttons:GetChildren() do
		local Watcher = Instance.new("TextButton")
		Watcher.BackgroundTransparency = 1
		Watcher.Text = ""
		Watcher.Parent = Button

		Watcher.Size = UDim2.new(1,0,1,0)
		Watcher.Position = UDim2.new(0,0,0,0)

		Watcher.MouseButton1Click:Connect(function()
			--// just incase
			Var.MainFrame.Configuration.Marketplace.MainMarketplace.InstallBox.Visible = false
			Var.MainFrame.Configuration.Marketplace.MainMarketplace.MPFrozen.Visible = false

			Var.MainFrame.Configuration.Marketplace.MainMarketplace[Var.Marketplace.ActivePage].Visible = false

			Var.Marketplace.ActivePage = Button.Name
			Var.Marketplace.ActivePageType = Button.Name:upper()

			if Button.Name == "Themes" or Button.Name == "Apps" then
				Var.Marketplace.ActivePage = "CardGrid"
				Var.Marketplace.ActivePageType = Button.Name
				Apps.LoadAppList()
			elseif Button.Name == "AAFeatured" then
				Var.Marketplace.ActivePageType = "FEATURED"
			elseif Button.Name == "XLibrary" then
				Apps.LoadLibrary()
			end

			Var.MainFrame.Configuration.Marketplace.MainMarketplace[Var.Marketplace.ActivePage].Visible = true
		end)
	end

	--// hopefully the icon pack has loaded by now?
	Sidebar.Parent.MainMarketplace.XLibrary.AdministerLogo.Image = Utilities.Icon "administer" 
	Sidebar.Parent.MainMarketplace.XLibrary.GameArt.Image = Var.Remotes.GetGameArt:InvokeServer()

	Var.MainFrame.Configuration.Marketplace.MainMarketplace.XLibrary.SubHeader.TextButton.MouseButton1Click:Connect(function()
		Frontend.SwapAppBasic(
			Var.MainFrame.Configuration.Admins,
			{
				Name = Utilities.Translate("Configuration.Admins.Container.Admins.Header.TLabel"),
				Icon = Utilities.Icon "user-clip"
			}
		)
	end)

	Var.MainFrame.Configuration.Marketplace.MainMarketplace.XLibrary.InstallAOSInstance.MouseButton1Click:Connect(function()
		Frontend.Popup.new(
			{
				Icon = Utilities.Icon "administer",
				Name = "Administer",
				Subheader = "AOS Registration"
			},
			{
				Primary = Utilities.Icon "network",
				SubIcon = Utilities.Icon "chain"
			},

			"Link custom server",
			"Please enter your custom AOS server here with https:// and no trailing slash. It must be online and linked to your Mongo instance in order to be saved as primary.",

			{
				{
					Text = "Cancel",
					Icon = Utilities.Icon "no-entry",
					Callback = function(Close)
						Close()
					end
				},
				{
					Text = "Register",
					Icon = Utilities.Icon "floppy-disk",
					Callback = function(Close, TextInputs)
						Close()

						local ServerURL = TextInputs[1]
						local Result = Var.Remotes.InstallServer:InvokeServer(ServerURL, game.Players.LocalPlayer.UserId)

						print(Result)

						if Result[1] then
							Result = Var.Remotes.RegisterPrimaryAOS:InvokeServer(ServerURL)

							Frontend.Popup.new(
								{
									Icon = Utilities.Icon "administer",
									Name = "Administer",
									Subheader = "AOS Registration"
								},
								{
									Primary = Utilities.Icon "network",
									SubIcon = Utilities.Icon(Result[1] and "check-plain" or "x")
								},
								Result[1] and "Success!" or "Something went wrong",
								Result[1] and 
									"This AOS instance has been saved and registered as primary." or 
									"Sorry, but something went wrong while assigning your primary instance. Please make note of the error in your game's logs and report it to the server maintainer.",
								{
									{
										Text = "OK",
										Icon = Utilities.Icon "check-plain",
										Callback = function(Close)
											Close()
										end
									}
								}
							)
						else
							Frontend.Popup.new(
								{
									Icon = Utilities.Icon "administer",
									Name = "Administer",
									Subheader = "AOS Registration"
								},
								{
									Primary = Utilities.Icon "network",
									SubIcon = Utilities.Icon "question-circle"
								},
								"Invalid server",
								`This is not a valid AOS instance or it is offline. {Result[2]}`,
								{
									{
										Text = "OK",
										Icon = Utilities.Icon "check-plain",
										Callback = function(Close)
											Close()
										end
									}
								}
							)
						end
					end
				}
			},
			{{
				HeaderText = "Server URL (https://aos-us-1.admsoftware.org)"
			}}
		)
	end)

	Apps.InitSerarchbar()
	task.defer(Apps.LoadAppList)
end

return Apps
