local target = script.Parent
if not target:IsA("GuiObject") then
	-- Relocator hasn't moved this script yet; bail silently
	return
end
game:GetService("TweenService")
	:Create(target, TweenInfo.new(0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), { Rotation = 360 })
	:Play()
