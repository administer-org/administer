--// pyxfluff 2025

local Var = require(script.Parent.Parent.Parent.Core.Variables)

local AdminRunner = require(script.Parent.Parent.AdminRunner)

local Migrator = {}

function Migrator.CheckForV1()
	local SuperAdmin = Var.DataStores.AdminsDS:GetAsync("_Rank1")
	
	if SuperAdmin == nil then return false end
	if SuperAdmin.FinishedMigration then return false end
	
	return true
end

function Migrator.Migrate()
	local AdminKeys: DataStorePages = Var.DataStores.AdminsDS:ListKeysAsync()
	
	while true do
		for _, Key in AdminKeys:GetCurrentPage() do
			local Data = Var.DataStores.AdminsDS:GetAsync(Key.KeyName)
			print(Data)
			
			AdminRunner.Ranks.New({
				AdmRankVersion = 3,

				Name = Data.RankName,
				Protected = Data.Protected,
				Members = Data.Members,

				Apps = {
					SuperAdmin = true,
				},

				CreationReason = `Migrated by Administer 2.0.0 automatically ({Data.CreationReason}).`,
				ActingUser = 1,

				Color = "23ff74"
			})
		end
		
		if AdminKeys.IsFinished then break end
		
		AdminKeys:AdvanceToNextPageAsync()
	end
end

return Migrator
