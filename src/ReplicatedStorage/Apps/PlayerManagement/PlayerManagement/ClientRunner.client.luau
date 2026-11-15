--// pyxfluff 2024

print("[Administer] [Log] ClientInit job starting up")

local t = tick()

game.ReplicatedStorage.Administer.Apps.PlayerManagement.FunCommandClient.OnClientEvent:Connect(function(...)
	print(...)
end)

print("✓ Listening to requests")
