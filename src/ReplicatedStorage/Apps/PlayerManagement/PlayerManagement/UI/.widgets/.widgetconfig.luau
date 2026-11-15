local ServerStats = script.Parent:WaitForChild("ServerStats")

local renderServerStats = require(ServerStats.Renderer)

return {
	["_generator"] = "AdministerWidgetConfig-1.0",
	["Widgets"] = {
		{
			["Type"] = "SMALL_LABEL",
			["RenderFrequency"] = 1, --// MUST be higher than .5

			["DefaultValue"] = "0", --// This value will be used in the previewer before it is selected
			["Name"] = "Test Widget",
			["Icon"] = "rbxassetid://0",

			["OnRender"] = function(Player)
				-- MUST return a string or number to not throw an error
				print("Rendering...")

				return math.random(1, 10000)
			end,
		},
		{
			["Type"] = "LARGE_BOX",
			["Name"] = "Quick server stats",
			["Icon"] = "rbxassetid://17013216608",
			["OnRender"] = renderServerStats,
			["BaseUIFrame"] = ServerStats,
		},
	},

	["Commands"] = {
		["Player_Management_Ban"] = {
			["ActionName"] = "Ban",
			["Description"] = "Ban a set of users.",
			["FromApp"] = "Configuration",
			["Icon"] = "AppDefaults",
			["Flags"] = {
				{
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
		},
	},
}
