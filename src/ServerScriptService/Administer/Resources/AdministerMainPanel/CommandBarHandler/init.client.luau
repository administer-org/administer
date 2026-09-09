--// darkpixlz 2024
--// Administer

local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local CommandBar = script.Parent.CommandBar
local Assets = script.Assets

local Actions = {
	["Moderation+_Ban"] = {
		["ActionName"] = "Ban",
		["Description"] = "Ban a set of users.",
		["FromApp"] = "Player Management",
		["Icon"] = "AppDefaults",
		["Flags"] = {
			["Users"] = {
				["Type"] = "json",
				["Description"] = "A set of users to ban ([1,2,3...])",
				["Required"] = true,
			},
			["Reason"] = {
				["Type"] = "string",
				["Description"] = "The reason for the ban.",
				["Required"] = false,
			},
			["Duration"] = {
				["Type"] = "string",
				["Description"] = "The duration of the ban (1m, 2d, 3w, 4m, 5y...)",
				["Required"] = true,
			},
			["IsGlobal"] = {
				["Type"] = "bool",
				["Description"] = "Uses the Roblox IsGlobal ban API. Defaults to true.",
				["Required"] = false,
			},
			["CanAppeal"] = {
				["Type"] = "bool",
				["Description"] = "Allows this player to appeal their ban in a different game under this place. Must be configured. Defaults to false.",
				["Required"] = false,
			},
		},
	},
	["Administer-Version"] = {
		["ActionName"] = "Check Administer Version",
		["Description"] = "Check Administer's runtime version.",
		["FromApp"] = "AdministerLogo",
		["Icon"] = "AppDefaults",
		["Flags"] = {},
	},
}

local CurrentSearchResults = {}
local IsMouseOverMenu = false

local function FindExactCommand(CommandName)
	local LowerName = string.lower(CommandName)
	if string.sub(LowerName, 1, 1) == "/" then
		LowerName = string.sub(LowerName, 2)
	end

	for _, Item in Actions do
		if string.lower(Item["ActionName"]) == LowerName then
			return Item
		end
	end
	return nil
end

local function IndexSearch(Query)
	local Final = {}
	local LowerQuery = string.lower(Query)

	if string.sub(LowerQuery, 1, 1) == "/" then
		LowerQuery = string.sub(LowerQuery, 2)
	end

	for _, Item in Actions do
		local RealName = string.lower(Item["ActionName"])
		local Find = string.find(RealName, LowerQuery)

		if Find then
			table.insert(Final, Item)
		end
	end

	return Final
end

local IsOpen = false
local SearchEvent = nil

CommandBar.CommandList.MouseEnter:Connect(function()
	IsMouseOverMenu = true
end)
CommandBar.CommandList.MouseLeave:Connect(function()
	IsMouseOverMenu = false
end)

local ResultsBox = CommandBar.CommandList

ResultsBox.Position = UDim2.new(0.5, 0, 0, 0)
ResultsBox.Size = UDim2.new(0, 650, 0, 0)

local function UpdateSelectorPosition()
	local Padding = 6

	CommandBar.Selector.Position = UDim2.new(
		CommandBar.Input.Position.X.Scale,
		CommandBar.Input.Position.X.Offset + CommandBar.Input.TextBounds.X + Padding,
		CommandBar.Selector.Position.Y.Scale,
		CommandBar.Selector.Position.Y.Offset
	)
end

CommandBar.Input:GetPropertyChangedSignal("TextBounds"):Connect(UpdateSelectorPosition)
CommandBar.Input:GetPropertyChangedSignal("Position"):Connect(UpdateSelectorPosition)

UIS.InputBegan:Connect(function(Input, Processed)
	local ExpandedView = ResultsBox:FindFirstChild("ExpandedView")
	local Anims = {}

	if Input.KeyCode == Enum.KeyCode.Tab and IsOpen then
		if #CurrentSearchResults > 0 then
			local FirstResult = CurrentSearchResults[1]
			local Prefix = string.sub(CommandBar.Input.Text, 1, 1) == "/" and "/" or ""

			CommandBar.Input.Text = Prefix .. FirstResult["ActionName"] .. " "
			CommandBar.Input.CursorPosition = string.len(CommandBar.Input.Text) + 1
		end
		return
	end

	if Processed then
		return
	end

	if Input.KeyCode == Enum.KeyCode.Semicolon then
		local CommandCursor = CommandBar.InitIcon

		if IsOpen then
			IsOpen = false

			if SearchEvent then
				SearchEvent:Disconnect()
				SearchEvent = nil
			end

			CommandBar.Input:ReleaseFocus()
			CommandBar.Input.Text = ""
			CurrentSearchResults = {}

			if ExpandedView then
				ExpandedView.Visible = false
				if ExpandedView:FindFirstChild("Inputs") then
					for _, child in ExpandedView.Inputs:GetChildren() do
						if child:IsA("Frame") then
							child:Destroy()
						end
					end
				end
			end

			Anims = {
				TS:Create(CommandBar, TweenInfo.new(0.3, Enum.EasingStyle.Cubic), { BackgroundTransparency = 1 }),
				TS:Create(CommandBar.InitIcon, TweenInfo.new(0.3, Enum.EasingStyle.Cubic), { ImageTransparency = 1 }),
				TS:Create(CommandBar.Input, TweenInfo.new(0.3, Enum.EasingStyle.Cubic), { TextTransparency = 1 }),
				TS:Create(ResultsBox, TweenInfo.new(0.3, Enum.EasingStyle.Cubic), { BackgroundTransparency = 1 }),
			}

			for i, Anim in Anims do
				Anim:Play()
			end

			task.wait(0.3)
			if not IsOpen then
				CommandBar.Visible = false
				CommandBar.CommandList.Visible = false
			end
		else
			IsOpen = true
			CommandBar.Visible = true
			CommandBar.Input:CaptureFocus()

			if ExpandedView then
				ExpandedView.Visible = false
			end

			Assets.Open:Play()

			Anims = {
				TS:Create(
					CommandBar,
					TweenInfo.new(0.4, Enum.EasingStyle.Cubic),
					{ BackgroundTransparency = 0.25, Position = UDim2.new(0.5, 0, 0.85, 0) }
				),
				TS:Create(CommandBar.InitIcon, TweenInfo.new(0.4, Enum.EasingStyle.Cubic), { ImageTransparency = 0 }),
				TS:Create(CommandBar.Input, TweenInfo.new(0.4, Enum.EasingStyle.Cubic), { TextTransparency = 0 }),
			}
			for i, Anim in Anims do
				Anim:Play()
			end

			task.wait(0.02)
			CommandBar.Input.Text = ""

			SearchEvent = CommandBar.Input:GetPropertyChangedSignal("Text"):Connect(function()
				Assets.Type:Play()
				local CurrentText = CommandBar.Input.Text
				local LowerText = string.lower(CurrentText)

				for i, v in ResultsBox.OptionList:GetChildren() do
					if v:IsA("Frame") and v.Name ~= "OptionTemplate" then
						v:Destroy()
					end
				end

				if ExpandedView and ExpandedView:FindFirstChild("Inputs") then
					for _, child in ExpandedView.Inputs:GetChildren() do
						if child:IsA("Frame") then
							child:Destroy()
						end
					end
				end

				if CurrentText == "" then
					CurrentSearchResults = {}
					if ExpandedView then
						ExpandedView.Visible = false
					end
					Anims = {
						TS:Create(
							CommandBar,
							TweenInfo.new(0.3, Enum.EasingStyle.Cubic),
							{ BackgroundTransparency = 0.25 }
						),
						TS:Create(ResultsBox, TweenInfo.new(0.3, Enum.EasingStyle.Cubic), {
							BackgroundTransparency = 1,
							Size = UDim2.new(0, 650, 0, 0),
							Position = UDim2.new(0.5, 0, 0, 0),
						}),
					}
					for i, Anim in Anims do
						Anim:Play()
					end
					return
				end

				local SpaceMatch = string.find(CurrentText, " ")
				local ShowExpanded = false
				local ExactMatchedAction = nil

				if SpaceMatch then
					local PossibleCommand = string.sub(CurrentText, 1, SpaceMatch - 1)
					ExactMatchedAction = FindExactCommand(PossibleCommand)

					if ExactMatchedAction then
						ShowExpanded = true
					end
				end

				if ExpandedView then
					ExpandedView.Visible = ShowExpanded
				end

				CurrentSearchResults = IndexSearch(CurrentText)

				if #CurrentSearchResults > 0 or ShowExpanded then
					CommandBar.CommandList.Visible = true
					Anims = {
						TS:Create(
							CommandBar,
							TweenInfo.new(0.4, Enum.EasingStyle.Cubic),
							{ BackgroundTransparency = 1 }
						),
						TS:Create(ResultsBox, TweenInfo.new(0.4, Enum.EasingStyle.Cubic), {
							BackgroundTransparency = 0,
							Size = UDim2.new(0, 650, 0, 300),
							Position = UDim2.new(0.5, 0, -4.35, 0),
						}),
					}
					for i, Anim in Anims do
						Anim:Play()
					end
				else
					Anims = {
						TS:Create(
							CommandBar,
							TweenInfo.new(0.3, Enum.EasingStyle.Cubic),
							{ BackgroundTransparency = 0.25 }
						),
						TS:Create(ResultsBox, TweenInfo.new(0.3, Enum.EasingStyle.Cubic), {
							BackgroundTransparency = 1,
							Size = UDim2.new(0, 650, 0, 0),
							Position = UDim2.new(0.5, 0, 0, 0),
						}),
					}
					for i, Anim in Anims do
						Anim:Play()
					end
				end

				if ShowExpanded and ExactMatchedAction then
					if
						ExpandedView
						and script:FindFirstChild("ArgumentTemplate")
						and ExpandedView:FindFirstChild("Inputs")
					then
						local SortedFlags = {}
						for flagName, flagData in ExactMatchedAction["Flags"] do
							table.insert(SortedFlags, { Name = flagName, Data = flagData })
						end

						table.sort(SortedFlags, function(a, b)
							if a.Data.Required ~= b.Data.Required then
								return a.Data.Required == true
							end
							return string.lower(a.Name) < string.lower(b.Name)
						end)

						for _, flagInfo in SortedFlags do
							local flagName = flagInfo.Name
							local flagData = flagInfo.Data

							if string.find(LowerText, string.lower(flagName) .. "%s*:") then
								continue
							end

							local ArgObj = script.ArgumentTemplate:Clone()
							ArgObj.Name = "RenderedArgument_" .. flagName

							if ArgObj:FindFirstChild("ArgsButton") then
								local labelText = flagName
								if flagData["Required"] then
									labelText = labelText .. " *"
									ArgObj.ArgsButton.RichText = true
									labelText = "<b>" .. labelText .. "</b>"
								end
								ArgObj.ArgsButton.Text = labelText

								ArgObj.ArgsButton.InputBegan:Connect(function(InputObj)
									if
										InputObj.UserInputType == Enum.UserInputType.MouseButton1
										or InputObj.UserInputType == Enum.UserInputType.Touch
									then
										local CurrentInput = CommandBar.Input.Text

										if string.sub(CurrentInput, -1) ~= " " then
											CurrentInput = CurrentInput .. " "
										end

										CommandBar.Input.Text = CurrentInput .. flagName .. ":"

										task.defer(function()
											CommandBar.Input:CaptureFocus()
											CommandBar.Input.CursorPosition = string.len(CommandBar.Input.Text) + 1
										end)
									end
								end)
							end

							if ArgObj:FindFirstChild("Selector") and ArgObj.Selector:FindFirstChild("Type") then
								ArgObj.Selector.Type.Text = string.upper(flagData["Type"])
							end

							ArgObj.Visible = true
							ArgObj.Parent = ExpandedView.Inputs
						end
					end
					return
				end

				local CreatedObjects = {}

				for i, Result in CurrentSearchResults do
					local SearchObj = script.OptionTemplate:Clone()
					SearchObj.Name = "SearchResult"
					SearchObj.CommandName.Text = Result["ActionName"]
					SearchObj.CommandDesc.Text = Result["Description"]
					SearchObj.CommandApp.Text = Result["FromApp"]

					local TargetApp = script.Parent.Main.AppDrawer.AppHolder.Apps:FindFirstChild(Result["FromApp"])
					if TargetApp and TargetApp:FindFirstChild("Icon") then
						SearchObj.AppIcon.Image = TargetApp.Icon.Image
					else
						SearchObj.AppIcon.Image = ""
					end

					SearchObj.InputBegan:Connect(function(InputObj)
						if
							InputObj.UserInputType == Enum.UserInputType.MouseButton1
							or InputObj.UserInputType == Enum.UserInputType.Touch
						then
							local Prefix = string.sub(CommandBar.Input.Text, 1, 1) == "/" and "/" or ""
							CommandBar.Input.Text = Prefix .. Result["ActionName"] .. " "

							task.defer(function()
								CommandBar.Input:CaptureFocus()
								CommandBar.Input.CursorPosition = string.len(CommandBar.Input.Text) + 1
							end)
						end
					end)

					SearchObj.Visible = true
					SearchObj.Parent = ResultsBox.OptionList

					table.insert(CreatedObjects, SearchObj)
				end
			end)
		end
	end
end)
