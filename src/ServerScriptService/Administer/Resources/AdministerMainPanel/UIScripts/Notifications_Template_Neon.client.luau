local ButtonAnims = game.Players.LocalPlayer.PlayerGui:FindFirstChild("AdministerMainPanel")
	and game.Players.LocalPlayer.PlayerGui.AdministerMainPanel:FindFirstChild("ButtonAnims")
if not ButtonAnims then
	return
end

local neonModule = ButtonAnims:WaitForChild("neon", 5)
if not neonModule then
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
