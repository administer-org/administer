--// pyxfluff 2025

local Var = require(script.Parent.Parent.Parent.Core.Variables)

local AdminRunner = require(script.Parent.Parent.AdminRunner)
local Utilities = require(script.Parent.Parent.Utilities)
local Apps = require(script.Parent.Parent.Apps)

local Migrator = {}

local AppAssociations = {
	[104329212775273] = 85970011489913,
	[89624237695477]  = 129301980999605,
	[116009468305526] = 72552642257326
}

function Migrator.CheckForV1()
	local SuperAdmin = Var.DataStores.AdminsDS:GetAsync("_Rank1")

	if SuperAdmin == nil then return false end

	return true
end

function Migrator.Migrate()
	Utilities.Logging.Print("[-] Migrating apps...")

	local OldApps = Apps.GetAll("DataStore_Raw")[2]

	for _, App in OldApps do
		if AppAssociations[App.ID] ~= nil then
			--// Replace it
			Utilities.Logging.Print(`[-] Administer found a new version of {App.Name}, installing!`)

			print(Apps.Install(AppAssociations[App.ID], `Administer Migrator, source: AOS Canary`, App.Name))

			Apps.Uninstall(App.ID)

			Utilities.Logging.Print("[ok] Done!")
		else
			Utilities.Logging.Print(`{App.Name} does not have a new replacement app!`)
		end
	end
	
	Apps.ServerAPI.UninstallServer("https://administer.notpyx.me", true)
	Apps.ServerAPI.New(Var.DefaultAppServer, 1)
	
	Apps.ServerAPI.RegisterPrimary(Var.DefaultAppServer)

	local AdminKeys: DataStorePages = Var.DataStores.AdminsDS:ListKeysAsync()
	--local AdminKeys = {
	--	IsFinished = true
	--}

	--function AdminKeys:GetCurrentPage() return {} end

	while true do
		for _, Key in AdminKeys:GetCurrentPage() do
			if string.find(Key.KeyName, "_Rank") == nil then
				Utilities.Logging.Print(`Excluding {Key.KeyName}`)
				continue
			else
				Utilities.Logging.Print(`Hit {Key.KeyName}`)
			end
			
			local Name = Key.KeyName
			
			if Name == "" then
				Name = `AutoMigrate-{math.random(1,1000)}`
				print(`Overwriting blank rank name! '' -> '{Name}'`)
				
				local Info = Var.DataStores.AdminsDS:GetAsync("CurrentRanks") or Var.DefaultRankData

				table.remove(Info.Names, table.find(Info.Names, ""))
				table.insert(Info.Names, Name)

				Var.DataStores.AdminsDS:SetAsync("CurrentRanks", Info)
			end

			local Data = Var.DataStores.AdminsDS:GetAsync(Key.KeyName)

			if Data.RankName == "Admin" then
				AdminRunner.Ranks.New({
					AdmRankVersion = 3,

					Name = "Administrator",
					Protected = Data.Protected,
					Members = Data.Members,

					Apps = {
						SuperAdmin = true
					},

					CreationReason = `Migrated by Administer 2.0.0 automatically ({Data.CreationReason}).`,
					ActingUser = 1,

					Color = "23ff74"
				})

				--// remove old Admin
				local Info = Var.DataStores.AdminsDS:GetAsync("CurrentRanks") or Var.DefaultRankData

				table.remove(Info.Names, table.find(Info.Names, "Admin"))

				Var.DataStores.AdminsDS:SetAsync("CurrentRanks", Info)
				continue
			end
			
			local PossibleConflict = Var.DataStores.AdminsDS:GetAsync(Data.RankName) ~= nil

			AdminRunner.Ranks.New({
				AdmRankVersion = 3,
				RankID = -1,

				Name = `{Data.RankName}{PossibleConflict and math.random(1, 100) or ""}`,
				Protected = Data.Protected,
				Members = Data.Members,

				Apps = {
					SuperAdmin = true
				},

				CreationReason = `Migrated by Administer 2.0.0 automatically ({Data.CreationReason}).`,
				ActingUser = 1,

				Color = "23ff74"
			})
		end

		if AdminKeys.IsFinished then break end

		AdminKeys:AdvanceToNextPageAsync()
	end
	
	--// Delete Rank1 so CheckForV1() will be false
	Var.DataStores.AdminsDS:RemoveAsync("_Rank1")
	
	Utilities.Logging.Print("[ok] Administer has migrated!")
end

return Migrator
