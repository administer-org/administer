--// Administer - ClearAllRanks.server.lua
--// Utility script to clear all admin ranks from the DataStore
--// To disable: set ENABLED to false or delete this script

local ENABLED = true

if not ENABLED then return end

local Root = script.Parent.Administer.Loader.Modules -- adjust path if needed

local Var = require(Root.Parent.Core.Variables)

local function ClearAllRanks()
	print("[-] Clearing all admin ranks...")
	local Start = os.clock()

	xpcall(function()
		local Info = Var.DataStores.AdminsDS:GetAsync("CurrentRanks")

		if not Info or not Info.Names then
			warn("[!] No ranks found, nothing to clear.")
			return
		end

		-- Remove each individual rank entry
		for _, Name in Info.Names do
			Var.DataStores.AdminsDS:RemoveAsync(Name)
			print(`[~] Removed rank: {Name}`)
		end

		-- Reset CurrentRanks
		Var.DataStores.AdminsDS:SetAsync("CurrentRanks", {
			Count = 0,
			Names = {},
			GroupAdminIDs = {},
			AdminIDs = {}
		})

		print(`[✓] All ranks cleared in {os.clock() - Start}s!`)
	end, function(E)
		warn(`[X] Failed to clear ranks! {E}`)
	end)
end

ClearAllRanks()