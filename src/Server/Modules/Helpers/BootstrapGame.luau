--// Administer
--// pyxfluff 2024 - 2025

--// This file exists to stop circular imports
local Root = script:FindFirstAncestor("Loader")

--// Modules
local Admins = require(Root.Modules.AdminRunner)
local Apps   = require(Root.Modules.Apps)
local Utils  = require(Root.Modules.Utilities)
local Var    = require(Root.Core.Variables)

return function(): ()
	Utils.Logging.Print("[-] Performing first-time setup...")
	
	local Owner = Utils.GetGameOwner()

	Var.IsFirstBoot = true
	Admins.Ranks.New({
		AdmRankVersion = 3,
		
		Name = "Administrator",
		Protected = true,
		Members = {
			{
				ID = Owner.ID,
				MemberType = Owner.MemberType,
				GroupRank = 255
			}
		},

		Apps = {
			SuperAdmin = true
		},

		CreationReason = "Added by System for first-time setup",
		ActingUser = 1,
		
		Color = "23ff74"
	})

	Apps.ServerAPI.New(Var.DefaultAppServer, -1)
	
	--// TODO: Remove this and let the setup assistant do it so the user can choose
	Apps.ServerAPI.RegisterPrimary(Var.DefaultAppServer)
	
	Apps.ServerAPI.InstallFromServer(
		Var.DefaultAppServer, --// Assuming this is (hopefully) AOS
		"org.admsoftware.player-management.Main"
	)
	
	--// Fixes first-time boot crash
	Var.PrimaryAppServer = Var.DefaultAppServer

	Utils.Logging.Print("[✓] Welcome to Administer!")
	Utils.Logging.SWarn("[!] Is Administer making too many print messages? To silence prints, go to Settings and set General.Verbosity to `error`!")
end
