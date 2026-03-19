--// Administer
--// CodingAgent 2026

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
		AdmRankVersion = 3,

		Name = "Administrator",
		Protected = true,
		Members = {
			{
				ID = Owner.ID,
				MemberType = Owner.MemberType,
				GroupRank = 255,
			},
		},

		Apps = {
			SuperAdmin = true,
		},

		CreationReason = "Added by System for first-time setup",
		ActingUser = 1,

		Color = "23ff74",
	})

	Var.PrimaryAppServer = Var.DefaultAppServer

	task.spawn(function()
		local ok, err = pcall(function()
			Apps.ServerAPI.New(Var.DefaultAppServer, -1)
			Apps.ServerAPI.RegisterPrimary(Var.DefaultAppServer)
			Apps.ServerAPI.InstallFromServer(Var.DefaultAppServer, "org.admsoftware.player-management.Main")
		end)
		if not ok then
			Utils.Logging.SWarn("[BootstrapGame] AOS registration failed (gateway unreachable?): " .. tostring(err))
		end
	end)

	Utils.Logging.Print("[✓] Welcome to Administer!")
	Utils.Logging.SWarn(
		"[!] Is Administer making too many print messages? To silence prints, go to Settings and set General.Verbosity to `error`!"
	)
end
