--// pyxfluff 2025

local Root = script.Parent.Parent

--// Modules
local Var = require(Root.Variables)
local Frontend = require(Root.Frontend)
local Utilities = require(Root.Utilities)

local Page
local Frames = Var.MainFrame.Welcome.SetupFull

local TweenService = Var.Services.TweenService

local function SwapPages(Page1, Page2, NewIcon, Spin)
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

	ET.Completed:Wait() --// stop the animation from being too quick
end

return function()
	local ConnectionsTable = {}
	local DidRegister = false
	local Metadata = {
		["HD_ADMIN"] = {
			PrettyName = "HD Admin",
			Icon = ""
		},

		["EXE_5"] = {
			PrettyName = "Exe 5",
			Icon = ""
		},

		["EXE_6"] = {
			PrettyName = "Exe 6",
			Icon = ""
		},

		["ADONIS"] = {
			PrettyName = "Adonis",
			Icon = ""
		},

		["BASIC_ADMIN_ESSENTIALS"] = {
			PrettyName = "Basic Admin Essentials",
			Icon = ""
		},

		["KOHLS_ADMIN"] = {
			PrettyName = "Kohl's Admin",
			Icon = ""
		},

		["KOHLS_ADMIN_2"] = {
			PrettyName = "Kohl's Admin 2",
			Icon = ""
		}
	}

	Frames.Page1.NextPage.MouseButton1Click:Connect(function()
		SwapPages(Frames.Page1, Frames.Loading, "rbxassetid://11102397100", true)

		local ImportableSystems = Var.Remotes.GetImports:InvokeServer()

		print(ImportableSystems)

		for TechSystemName, System in ImportableSystems do
			if TechSystemName == "_AdmSystemsNotFound" then continue end

			local NewDisplay = Frames.Page2.Select.System:Clone()

			NewDisplay.Name = TechSystemName
			NewDisplay.SystemName.Text = Metadata[TechSystemName].PrettyName
			NewDisplay.SystemIcon.Image = Metadata[TechSystemName].Icon
			NewDisplay.DetectedStatus.Text = `Ready to import {System.Admins} admins, {System.Commands} commands, and {System.Ranks} ranks`
			NewDisplay.StatusIcon.Image = Utilities.Icon "check-plain"

			NewDisplay.Parent = Frames.Page2.Select
			NewDisplay.Visible = true
		end

		for _, TechSystemName in ImportableSystems._AdmSystemsNotFound do
			local NewDisplay = Frames.Page2.Select.System:Clone()

			NewDisplay.Name = TechSystemName
			NewDisplay.SystemName.Text = Metadata[TechSystemName].PrettyName
			NewDisplay.SystemIcon.Image = Metadata[TechSystemName].Icon
			NewDisplay.DetectedStatus.Text = "Not found"
			NewDisplay.StatusIcon.Image = Utilities.Icon "tear"

			NewDisplay.Parent = Frames.Page2.Select
			NewDisplay.Visible = true
		end

		SwapPages(Frames.Loading, Frames.Page2, Utilities.Icon "route", false)
	end)

	Frames.Page2.NextPage.MouseButton1Click:Connect(function()
		SwapPages(Frames.Page2, Frames.Loading, "rbxassetid://11102397100", true)

		for _, Connection in ConnectionsTable do
			Connection:Disconnect()
		end

		local AOSInstances = Var.Remotes.GetAOSInstances:InvokeServer(true)

		for _, Instance in AOSInstances do
			local UI = Frames.Page3.Select.URL:Clone()

			UI.Name = Instance.url
			UI.Parent = Frames.Page3.Select

			UI.SystemName.Text = `{Instance.name} ({Instance.region_code})`
			UI.DetectedStatus.Text = `{not Instance.IsUp and "Offline · " or ""}{Instance.Ping}ms · Verified Server · AOS {Instance.Version}{Instance.IsDev and " · Development Mode" or ""}`

			UI.Selector.MouseButton1Click:Connect(function()
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

					"Complete Registration",
					"Are you sure you would like to register this instance as your AOS Primary Node? You may not edit this right now, but you may be able to in a future Administer version.",

					{
						{
							Text = "Yes",
							Icon = Utilities.Icon "check-plain",
							Callback = function(Close)
								DidRegister = true

								local Result = Var.Remotes.RegisterPrimaryAOS:InvokeServer(Instance.url)

								print(Result)

								Close()

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
										"This AOS instance is now your primary! Please proceed with setup." or 
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
							end
						},
						{
							Text = "Cancel",
							Icon = Utilities.Icon "no-entry",
							Callback = function(Close)
								Close()
							end
						}
					}
				)
			end)

			UI.Visible = true
		end

		Frames.Page3.CustomServer.Click.MouseButton1Click:Connect(function()
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

				"Custom URL",
				"Please enter your custom AOS server here with https:// and no trailing slash. It must be online and linked to your Mongo instance in order to be saved as primary.",

				{
					{
						Text = "Use official server",
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
										"This AOS instance is now your primary! Please proceed with setup." or 
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

		SwapPages(Frames.Loading, Frames.Page3, "rbxassetid://15082548595", false)
	end)

	Frames.Page3.NextPage.MouseButton1Click:Connect(function()
		if not DidRegister then
			Frontend.Popup.new(
				{
					Icon = Utilities.Icon "administer",
					Name = "Administer",
					Subheader = "Registration Incomplete"
				},
				{
					Primary = Utilities.Icon "network",
					SubIcon = Utilities.Icon "x"
				},
				"Please select an instance",
				"You must select a primary AOS instance before finishing setup. You may do so by clicking on its name.",
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

			return
		end

		SwapPages(Frames.Page3, Frames.Loading, "rbxassetid://11102397100", true)

		--// load settings todo todo todo

		SwapPages(Frames.Loading, Frames.Page4, "rbxassetid://14865439768", false)
	end)

	Frames.Page4.NextPage.MouseButton1Click:Connect(function()	
		SwapPages(Frames.Page4, Frames.Page5, "rbxassetid://11102397100", true)
	end)
	
	Frames.Page5.TourConfirm.MouseButton1Click:Connect(function()
		local tour = require(script.Tour)
		tour.BeginTour()
		
		SwapPages(Frames.Page5, Frames.Page6, "rbxassetid://18151072839", false)
	end)

	Frames.Page5.Exit.MouseButton1Click:Connect(function()
		SwapPages(Frames.Page5, Frames.Page6, "rbxassetid://18151072839", false)
	end)

	Frames.Page6.Exit.MouseButton1Click:Connect(function()
		Utilities.Logging.Print("This is where TutorialSeen would be fired, but for the sake of development it's not being called")
		--print(Var.Remotes.TutorialSeen:InvokeServer("FirstTimeSetup"))

		Var.DoHeaderEffects = true
		Frontend.SwapAppBasic(Var.MainFrame.Home, {
			Icon = Utilities.Icon "home",
			Name = "Home"
		})
	end)
end
