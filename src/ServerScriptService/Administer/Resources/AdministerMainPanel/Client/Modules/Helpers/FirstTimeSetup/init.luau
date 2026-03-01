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
	local Metadata = {
		["HD_ADMIN"] = {
			PrettyName = "HD Admin",
			Icon = "",
		},

		["EXE_5"] = {
			PrettyName = "Exe 5",
			Icon = "",
		},

		["EXE_6"] = {
			PrettyName = "Exe 6",
			Icon = "",
		},

		["ADONIS"] = {
			PrettyName = "Adonis",
			Icon = "",
		},

		["BASIC_ADMIN_ESSENTIALS"] = {
			PrettyName = "Basic Admin Essentials",
			Icon = "",
		},

		["KOHLS_ADMIN"] = {
			PrettyName = "Kohl's Admin",
			Icon = "",
		},

		["KOHLS_ADMIN_2"] = {
			PrettyName = "Kohl's Admin 2",
			Icon = "",
		},
	}

	Frames.Page1.Body.Text = string.gsub(Frames.Page1.Body.Text, "pyxfluff", game.Players.LocalPlayer.Name)

	Frames.Page1.NextPage.MouseButton1Click:Connect(function()
		SwapPages(Frames.Page1, Frames.Loading, "", true)

		local ImportableSystems = Var.Remotes.GetImports:InvokeServer()

		print(ImportableSystems)

		for TechSystemName, System in ImportableSystems do
			if TechSystemName == "_AdmSystemsNotFound" then
				continue
			end

			local NewDisplay = Frames.Page2.Select.System:Clone()

			NewDisplay.Name = TechSystemName
			NewDisplay.SystemName.Text = Metadata[TechSystemName].PrettyName
			NewDisplay.SystemIcon.Image = Metadata[TechSystemName].Icon
			NewDisplay.DetectedStatus.Text =
				`Ready to import {System.Admins} admins, {System.Commands} commands, and {System.Ranks} ranks`
			NewDisplay.StatusIcon.Image = Utilities.Icon("check-plain")

			NewDisplay.Parent = Frames.Page2.Select
			NewDisplay.Visible = true
		end

		for _, TechSystemName in ImportableSystems._AdmSystemsNotFound do
			local NewDisplay = Frames.Page2.Select.System:Clone()

			NewDisplay.Name = TechSystemName
			NewDisplay.SystemName.Text = Metadata[TechSystemName].PrettyName
			NewDisplay.SystemIcon.Image = Metadata[TechSystemName].Icon
			NewDisplay.DetectedStatus.Text = "Not found"
			NewDisplay.StatusIcon.Image = Utilities.Icon("tear")

			NewDisplay.Parent = Frames.Page2.Select
			NewDisplay.Visible = true
		end

		Frontend.Toast({
			Icon = Utilities.Icon("warning-triangle"),
			Text = "This feature is not ready for use yet",
			Subtext = "Please do not report any errors.",
			Timeout = 3,
		})

		SwapPages(Frames.Loading, Frames.Page2, Utilities.Icon("route"), false)
	end)

	Frames.Page2.NextPage.MouseButton1Click:Connect(function()
		SwapPages(Frames.Page2, Frames.Loading, "", true)

		for _, Connection in ConnectionsTable do
			Connection:Disconnect()
		end

		--// The gateway handles node selection automatically — no instance list needed.
		--// Show a status card and let the user optionally enter a custom AOS URL.
		local GatewayCard = Frames.Page3.Select.URL:Clone()
		GatewayCard.Name = "GatewayCard"
		GatewayCard.SystemName.Text = "Gateway (Automatic)"
		GatewayCard.DetectedStatus.Text = "Connected · Automatic failover · No configuration required"
		GatewayCard.Parent = Frames.Page3.Select
		GatewayCard.Visible = true

		Frames.Page3.CustomServer.Click.MouseButton1Click:Connect(function()
			Frontend.Popup.new(
				{
					Icon = Utilities.Icon("administer"),
					Name = "Administer",
					Subheader = "Custom AOS Server",
				},
				{
					Primary = Utilities.Icon("network"),
					SubIcon = Utilities.Icon("chain"),
				},

				"Custom AOS URL (Optional)",
				"Enter your own AOS instance URL. Leave blank to use the gateway, which automatically routes to the best available node.",

				{
					{
						Text = "Use gateway",
						Icon = Utilities.Icon("no-entry"),
						Callback = function(Close)
							Close()
						end,
					},
					{
						Text = "Save",
						Icon = Utilities.Icon("floppy-disk"),
						Callback = function(Close, TextInputs)
							local ServerURL = TextInputs[1]
							Close()

							if not ServerURL or ServerURL == "" then
								return
							end

							local Result = Var.Remotes.SetPrimaryAppServer:InvokeServer(ServerURL)

							Frontend.Popup.new(
								{
									Icon = Utilities.Icon("administer"),
									Name = "Administer",
									Subheader = "Custom AOS Server",
								},
								{
									Primary = Utilities.Icon("network"),
									SubIcon = Utilities.Icon(Result[1] and "check-plain" or "x"),
								},
								Result[1] and "Saved!" or "Something went wrong",
								Result[1]
										and "Your custom AOS URL has been saved. You can clear it later from the Marketplace settings."
									or "Failed to save the custom server URL. Check your game's output for details.",
								{
									{
										Text = "OK",
										Icon = Utilities.Icon("check-plain"),
										Callback = function(C)
											C()
										end,
									},
								}
							)
						end,
					},
				},
				{ {
					HeaderText = "Server URL (https://my-aos.example.com)",
				} }
			)
		end)

		SwapPages(Frames.Loading, Frames.Page3, Utilities.Icon("network"), false)
	end)

	Frames.Page3.NextPage.MouseButton1Click:Connect(function()
		--// No registration required — the gateway connects automatically.
		SwapPages(Frames.Page3, Frames.Loading, "", true)

		--// load settings todo todo todo

		SwapPages(Frames.Loading, Frames.Page4, Utilities.Icon("gear"), false)
	end)

	Frames.Page4.NextPage.MouseButton1Click:Connect(function()
		SwapPages(Frames.Page4, Frames.Page5, Utilities.Icon("student"), false)
	end)

	Frames.Page5.TourConfirm.MouseButton1Click:Connect(function()
		local tour = require(script.Tour)
		tour.BeginTour()

		SwapPages(Frames.Page5, Frames.Page6, Utilities.Icon("rbxassetid://check-plain"), false)
	end)

	Frames.Page5.Exit.MouseButton1Click:Connect(function()
		SwapPages(Frames.Page5, Frames.Page6, Utilities.Icon("check-plain"), false)
	end)

	Frames.Page6.Exit.MouseButton1Click:Connect(function()
		print(Var.Remotes.TutorialSeen:InvokeServer("FirstTimeSetup", true))

		Var.DoHeaderEffects = true
		Frontend.SwapAppBasic(Var.MainFrame.Home, {
			Icon = Utilities.Icon("home"),
			Name = "Home",
		})
	end)
end
