--// CodingAgent 2024

local TS = game:GetService("TweenService")

TS:Create(
	script.Parent,
	TweenInfo.new(0.75, Enum.EasingStyle.Quart),
	{ GroupTransparency = 0, Size = UDim2.new(1, 0, 1, 0) }
):Play()

local Blur = nil

script.Parent.Exit.MouseButton1Click:Connect(function()
	TS:Create(
		script.Parent,
		TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{ GroupTransparency = 1, Size = UDim2.new(1.5, 0, 1.5, 0) }
	):Play()

	task.wait(0.75)

	script.Parent:Destroy()
end)
