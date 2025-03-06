--// Administer
--// pyxfluff 2024 - 2025

--// This file exists to stop circular imports

local Root = script:FindFirstAncestor("Loader")
local Admins = require(Root.Modules.AdminRunner)
local Apps = require(Root.Modules.Apps)
local Utils = require(Root.Modules.Utilities)
local Var = require(Root.Core.Variables)

return function(): ()
	Utils.Logging.Print("[-] Performing first-time setup...")
	local Owner = Utils.GetGameOwner()

	Var.IsFirstBoot = true
	Admins.Ranks.New({
		Name = "Administrator",
		Protected = true,
		Members = {
			{
				ID = Owner.ID,
				MemberType = (Owner.MemberType) :: "Group" | "User",
				GroupRank = 255,
			},
		},

		AllowedApps = {
			SuperAdmin = true,
		},

		CreationReason = "Added by System for first-time setup.",
		ActingUser = 1,
	})

	Apps.ServerAPI.New(Var.DefaultAppServer, -1)
	Apps.ServerAPI.InstallFromServer(
		Var.DefaultAppServer, --// Assuming this is (hopefully) AOS
		1
	)

	Utils.Logging.Print("[✓] Welcome to Administer!")
	Utils.Logging.Print([[[!] Is Administer making too many print messages?
Turn off the `misc.Verbose` setting to silence prints!
]])
end
