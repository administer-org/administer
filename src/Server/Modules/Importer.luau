--// pyxfluff 2024 - 2025

local Importer = {}

local Utils = require(script.Parent.Utilities)

Importer.Systems = {
	"EXE_5",
	"EXE_6",
	"HD_ADMIN",
	"ADONIS",
	"BASIC_ADMIN_ESSENTIALS",
	"KOHLS_ADMIN",
	"KOHLS_ADMIN_2"
}

function Importer.GetData(SystemName)
	if SystemName == "EXE_5" then
		--// Find ELEMENTS
		local Exe5Elements = require(game.ServerScriptService:FindFirstAncestor("ELEMENTS"))
		local ExeFoundSanitizedAdmins = {}

		if Exe5Elements == nil then 
			return {false, "Exe 5 is not installed."}
		end

		local ExeGroup = Exe5Elements.FETCH_GROUP()
		local ExeGroupRanks = Exe5Elements.FETCH_RANKS()
		local ExePlayers = Exe5Elements.FETCH_PLAYERS()

		for UserID, Data in ExePlayers do
			table.insert(ExeFoundSanitizedAdmins, {
				MemberType = "User",
				ID = UserID
			})
		end

		for _, Rank in ExeGroupRanks do
			table.insert(ExeFoundSanitizedAdmins, {
				MemberType = "Group",
				RankName = "Administrator",

				ID = ExeGroup,
				GroupRank = Rank
			})
		end

		return { true, {
			Commands = {},
			Ranks = {
				"Administrator"	
			},
			Admins = ExeFoundSanitizedAdmins,
			Logs = {}
		}}

	elseif SystemName == "HD_ADMIN" then
		local HDRoot = game:FindFirstAncestor("HD Admin")
		local HDSanitizedAdmins = {}
		local HDRankNames = {}

		if HDRoot == nil then 
			return { false, "HD Admin is not installed." }
		end

		local HDSettings = require(HDRoot.Settings)

		for GroupID, RankData in HDSettings.Groups do
			for GroupRank, RankName in RankData do
				table.insert(HDSanitizedAdmins, {
					MemberType = "Group",
					RankName = RankName,

					ID = GroupID,
					GroupRank = GroupRank
				})	
			end
		end 

		--// i hate this so much HD admins parsing is so buns
		--// Realistically idk how it works so I'm just guessing..
		for _, Rank in HDSettings.Ranks do
			for _, Child in Rank do
				if typeof(Child) ~= "table" then continue end

				table.insert(HDRankNames)
				table.insert(HDSanitizedAdmins, {
					MemberType = "User",
					RankName = Rank[1],

					ID = Child[1]
				})	
			end
		end

		return { true, {
			Commands = {},
			Ranks = {
				"Administrator"	
			},
			Admins = HDSanitizedAdmins,
			Logs = {}
		}}
	else
		return {
			false,
			`{SystemName} is not installed`
		}
	end
end

function Importer.ListFoundSystems()
	--// find stuff
	local Final = {}

	for _, System in Importer.Systems do
		xpcall(function()
			local Data = Importer.GetData(System)

			print(Data)
			
			if Data[1] then
				Data = Data[2]

				Final[System] = {
					Commands = #Data.Commands,
					Ranks = #Data.Ranks,
					Admins = #Data.Admins
				}
			end	
		end, function(e)
			Utils.Logging.Print(`System not found: {e}`)
			Final[System] = {
				Error = true,
				Data = e,

				Commands = -1,
				Ranks = -1,
				Admins = -1
			}
		end)
	end


	return {
		EXE_5 = {
			Commands = 3,
			Ranks = 1,
			Admins = 4
		},

		HD_ADMIN = {
			Commands = 0,
			Ranks = 1,
			Admins = 7
		},

		_AdmSystemsNotFound = {
			"EXE_6", "ADONIS", "BASIC_ADMIN_ESSENTIALS", "KOHLS_ADMIN_2", "KOHLS_ADMIN"
		}
	}
end

function Importer.Import(System)
	if not table.find() then
		return { false, "This system is not supported for importing." } 
	end
end

return Importer
