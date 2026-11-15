return function(Remote)
	return {
		Name = "Kill",
		Description = "Kills the character.",
		RequireLocalPlayer = false,
		Trigger = function(Player: Player)
			local character = Player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if not humanoid or humanoid.Health <= 0 then
				return false
			end
			humanoid.Health = 0
			return true
		end,
	}
end
