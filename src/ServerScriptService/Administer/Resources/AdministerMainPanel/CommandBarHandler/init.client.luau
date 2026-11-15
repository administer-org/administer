--// darkpixlz 2024
--// Administer

local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CommandBar = script.Parent.CommandBar
local Assets = script.Assets
local Frontend = require(script.Parent.Client.Modules.Frontend)

local Actions = {
	["Moderation+_Ban"] = {
		["ActionName"] = "Ban",
		["Description"] = "Ban a set of users (template; not executable).",
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
				["Description"] = "Ban duration (30m, 2d, 1w, or permanent).",
				["Required"] = true,
			},
			["IsGlobal"] = {
				["Type"] = "bool",
				["Description"] = "Uses the Roblox IsGlobal ban API. Defaults to true.",
				["Required"] = false,
			},
			["CanAppeal"] = {
				["Type"] = "bool",
				["Description"] = "Whether users can appeal the ban.",
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

local function RefreshAppCommands()
	for key, action in Actions do
		if action.Executable then
			Actions[key] = nil
		end
	end
	local remote = game.ReplicatedStorage:WaitForChild("Administer", 5):WaitForChild("GetAppCommands", 5)
	if not remote then
		return
	end
	local ok, commands = pcall(function()
		return remote:InvokeServer()
	end)
	if not ok or type(commands) ~= "table" then
		return
	end
	for _, command in commands do
		if type(command) == "table" and type(command.ActionName) == "string" then
			command.Executable = true
			Actions[command.FromApp .. "_" .. command.ActionName] = command
		end
	end
end

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
		local Find = string.find(RealName, LowerQuery, 1, true)

		if Find then
			table.insert(Final, Item)
		end
	end

	return Final
end

local function GetUsersField(input: string, action)
	if not action or not action.Flags or not action.Flags.Users then
		return nil
	end

	local _, colonEnd = string.find(string.lower(input), "%f[%w]users%s*:%s*")
	if not colonEnd then
		return nil
	end

	local valueStart = colonEnd + 1
	local firstValue = string.find(input, "%S", valueStart) or (#input + 1)
	local inner, valueEnd
	if string.sub(input, firstValue, firstValue) == "[" then
		local closingBracket = string.find(input, "]", firstValue + 1, true)
		valueEnd = closingBracket or #input
		inner = string.sub(input, firstValue + 1, closingBracket and closingBracket - 1 or #input)
	else
		local rawValue = string.match(string.sub(input, firstValue), "^%S*") or ""
		valueEnd = firstValue + #rawValue - 1
		inner = rawValue
	end

	local cursor = CommandBar.Input.CursorPosition
	if cursor > 0 and cursor > valueEnd + 1 then
		return nil
	end

	local ids, selected = {}, {}
	for token in string.gmatch(inner, "[^,]+") do
		local trimmed = string.match(token, "^%s*(.-)%s*$")
		local id = tonumber(trimmed)
		if id and id > 0 and id % 1 == 0 and not selected[id] then
			selected[id] = true
			table.insert(ids, id)
		end
	end

	local lastToken = string.match(inner, "([^,]*)$") or ""
	lastToken = string.match(lastToken, "^%s*(.-)%s*$")
	local query = tonumber(lastToken) and "" or string.lower(lastToken)
	return { ValueStart = valueStart, ValueEnd = valueEnd, IDs = ids, Selected = selected, Query = query }
end

local function RenderPlayerOptions(input: string, field)
	local matches = {}
	for _, player in Players:GetPlayers() do
		local query = field.Query
		if
			query == ""
			or string.find(string.lower(player.Name), query, 1, true)
			or string.find(string.lower(player.DisplayName), query, 1, true)
			or string.find(tostring(player.UserId), query, 1, true)
		then
			table.insert(matches, player)
		end
	end
	table.sort(matches, function(a, b)
		return string.lower(a.Name) < string.lower(b.Name)
	end)

	for _, player in matches do
		local option = script.OptionTemplate:Clone()
		option.Name = "PlayerOption_" .. player.UserId
		option.CommandName.Text = player.Name
		option.CommandDesc.Text = player.DisplayName ~= player.Name
			and `{player.DisplayName} · User ID {player.UserId}` or `User ID {player.UserId}`
		option.CommandApp.Text = field.Selected[player.UserId] and "Selected · click to remove" or "Player"
		option.AppIcon.Image = `rbxthumb://type=AvatarHeadShot&id={player.UserId}&w=150&h=150`
		option.InputBegan:Connect(function(inputObject)
			if
				inputObject.UserInputType ~= Enum.UserInputType.MouseButton1
				and inputObject.UserInputType ~= Enum.UserInputType.Touch
			then
				return
			end
			local ids = table.clone(field.IDs)
			if field.Selected[player.UserId] then
				local index = table.find(ids, player.UserId)
				if index then
					table.remove(ids, index)
				end
			else
				table.insert(ids, player.UserId)
			end
			local replacement = "[" .. table.concat(ids, ",") .. "]"
			local before = string.sub(input, 1, field.ValueStart - 1)
			CommandBar.Input.Text = before .. replacement .. string.sub(input, field.ValueEnd + 1)
			task.defer(function()
				CommandBar.Input:CaptureFocus()
				CommandBar.Input.CursorPosition = #before + #replacement + 1
			end)
		end)
		option.Visible = true
		option.Parent = CommandBar.CommandList.OptionList
	end
end

local IsOpen = false
local SearchEvent = nil

CommandBar.Input.FocusLost:Connect(function(enterPressed)
	if not enterPressed or not IsOpen then
		return
	end
	local input = CommandBar.Input.Text
	if string.match(input, "^%s*$") then
		return
	end
	local commandName, arguments = string.match(input, "^%s*/?(%S+)%s*(.-)%s*$")
	local action = commandName and FindExactCommand(commandName)
	local remote = game.ReplicatedStorage:WaitForChild("Administer", 5):WaitForChild("ExecuteAppCommand", 5)
	local ok, response = false, nil
	if action and action.Executable and remote then
		ok, response = pcall(function()
			return remote:InvokeServer(action.FromApp, action.ActionName, arguments)
		end)
	end
	local success = ok and type(response) == "table" and response[1] == true
	local message = ok and type(response) == "table" and response[2]
		or (action and not action.Executable and "This is a template, not an installed app command." or "Command is unavailable.")
	Frontend.Toast({
		Text = success and "Command completed" or "Command failed",
		Subtext = tostring(message),
		Icon = success and "rbxassetid://15477669816" or "rbxassetid://11050732384",
		Timeout = 6,
	})
	IsOpen = false
	if SearchEvent then
		SearchEvent:Disconnect()
		SearchEvent = nil
	end
	CommandBar.Input.Text = ""
	CommandBar.CommandList.Visible = false
	CommandBar.Visible = false
end)

local ResultsBox = CommandBar.CommandList

ResultsBox.Position = UDim2.new(0.5, 0, 0, 0)
ResultsBox.Size = UDim2.new(0, 650, 0, 0)

--------------------------------------------------------------------
-- DYNAMIC SELECTOR POSITION LOGIC
--------------------------------------------------------------------
local function UpdateSelectorPosition()
	local Padding = 6 -- Pixels of space between the end of the text and the Selector

	-- Calculates the end of the text relative to the Input's starting point
	CommandBar.Selector.Position = UDim2.new(
		CommandBar.Input.Position.X.Scale,
		CommandBar.Input.Position.X.Offset + CommandBar.Input.TextBounds.X + Padding,
		CommandBar.Selector.Position.Y.Scale,
		CommandBar.Selector.Position.Y.Offset
	)
end

-- Fire whenever text changes, sizes adjust, or fonts scale up
CommandBar.Input:GetPropertyChangedSignal("TextBounds"):Connect(UpdateSelectorPosition)
CommandBar.Input:GetPropertyChangedSignal("Position"):Connect(UpdateSelectorPosition)
--------------------------------------------------------------------

UIS.InputBegan:Connect(function(Input, Processed)
	local ExpandedView = ResultsBox:FindFirstChild("ExpandedView")
	local Anims = {}

	--------------------------------------------------------------------
	-- TAB AUTOCOMPLETE LOGIC
	--------------------------------------------------------------------
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
		if IsOpen then
			--------------------------------------------------------------------
			-- CLOSE SEQUENCE
			--------------------------------------------------------------------
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
			--------------------------------------------------------------------
			-- OPEN SEQUENCE
			--------------------------------------------------------------------
			RefreshAppCommands()
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

				-- Clean up old visual autocomplete option layout elements
				for i, v in ResultsBox.OptionList:GetChildren() do
					if v:IsA("Frame") and v.Name ~= "OptionTemplate" then
						v:Destroy()
					end
				end

				-- Clean up old active argument items from the correct container (.Inputs)
				if ExpandedView and ExpandedView:FindFirstChild("Inputs") then
					for _, child in ExpandedView.Inputs:GetChildren() do
						if child:IsA("Frame") then
							child:Destroy()
						end
					end
				end

				-- Shrink back down if input text is empty
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

				-- Argument Detection Logic
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
				local UsersField = ShowExpanded and GetUsersField(CurrentText, ExactMatchedAction)
				if UsersField then
					CurrentSearchResults = {}
				end

				-- Handle sizing dynamically depending on whether matches are found
				if #CurrentSearchResults > 0 or ShowExpanded or UsersField then
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
					-- Shrink seamlessly back down if no matching results are found
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

				--------------------------------------------------------------------
				-- RENDER ARGUMENT PARAMETER FLAGS
				--------------------------------------------------------------------
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

						-- Order parameters: Required parameters first, then sorting alphabetically
						table.sort(SortedFlags, function(a, b)
							if a.Data.Required ~= b.Data.Required then
								return a.Data.Required == true
							end
							return string.lower(a.Name) < string.lower(b.Name)
						end)

						for _, flagInfo in SortedFlags do
							local flagName = flagInfo.Name
							local flagData = flagInfo.Data

							-- Skip rendering this option if it has already been typed out (e.g., "Users:")
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

								-- FIX: Switched from .Activated (MouseUp) to .InputBegan (MouseDown) to intercept focus drop
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
					if UsersField then
						RenderPlayerOptions(CurrentText, UsersField)
					end
					return
				end

				--------------------------------------------------------------------
				-- RENDER COMMAND AUTOCOMPLETE SELECTIONS
				--------------------------------------------------------------------
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
