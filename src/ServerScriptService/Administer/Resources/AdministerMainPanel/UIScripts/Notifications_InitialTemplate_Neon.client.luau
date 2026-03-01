local ButtonAnims = game.Players.LocalPlayer.PlayerGui:FindFirstChild("AdministerMainPanel")
	and game.Players.LocalPlayer.PlayerGui.AdministerMainPanel:FindFirstChild("ButtonAnims")

local neonModule = ButtonAnims and ButtonAnims:WaitForChild("neon", 5)
if not neonModule then
	warn("[Notifications_InitialTemplate_Neon] neon module not found in ButtonAnims, skipping neon effect")
	return
end

local neon = require(neonModule)
neon:BindFrame(script.Parent, {
	Transparency = 0.98,
	BrickColor = BrickColor.new("Institutional white"),
})

script.Parent.Parent.Parent.Destroying:Connect(function()
	neon:UnbindFrame(script.Parent)
end)
