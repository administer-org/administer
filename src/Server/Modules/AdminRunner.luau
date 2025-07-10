--// Administer
--// pyxfluff 2024 - 2025

local AR = { Ranks = {} }

--// Dependencies
local Root = script.Parent
local Config = require(Root.Parent.Core.Configuration)
local Types = require(Root.Parent.Core.Types)
local Util = require(Root.Utilities)
local Var = require(Root.Parent.Core.Variables)

type Response = Types.Response

--// Locals
local LastAdminResult

function AR.Bootstrap(Player: Player, AdminRankID: string): ()
	local Rank = Var.DataStores.AdminsDS:GetAsync(AdminRankID)
	local NewPanel = Var.Panel.Spawn(Rank, Player)

	table.insert(Var.Admins.InGame, Player)
	Var.Admins.TotalRunningCount += 1

	if Rank.Apps == nil then
		Util.Logging.Warn(`RankStore seems to be corrupt! \nRankData: {game:GetService("HttpService"):JSONEncode(Rank)}\nRankID: {AdminRankID}`)
		return {false, "Corrupt RankStore, please reset your database"}
	end

	NewPanel.Parent = Player.PlayerGui
	
	--// TODO

	Util.NewNotification(
		Player :: Player,
		--string.format(Util.t(Player, "onboarding.Welcome"), Config.Name, Rank.Name, Util.GetSetting("Keybind")),
		string.format(Util.t(Player, "onboarding.Welcome"), Config.Name, Rank.Name, "F2"), --// Will replace when we have settings again
		string.format(Util.t(Player, "onboarding.Head"), Config.Name),
		"rbxassetid://16105499426",
		15,
		nil,
		{}
	)
end

function AR.CanUseApp(Identifier: Player | string, AppID: string)
	local Rank

	if typeof(Identifier) == "Instance" then
		local Result = Util.IsAdmin(Identifier)

		if not Result.IsAdmin then 
			return false
		end

		Rank = Var.DataStores.AdminsDS:GetAsync(Result.RankID)
	else
		Rank = Var.DataStores.AdminsDS:GetAsync(Identifier)
	end

	return Rank.Apps.SuperAdmin and true or (Rank.Apps[AppID] ~= nil and Rank.Apps[AppID] or (Rank.Apps.NewAppsOn == true and true or false))
end

function AR.PlayerAdded(Player: Player, ForceAdmin: boolean, IsScan: boolean): Types.Response
	LastAdminResult = Util.IsAdmin(Player)

	Util.Logging.Print("New join:", LastAdminResult)

	if Var.WaitForBootstrap then
		repeat
			task.wait()
		until Var.DidBootstrap
	end

	if IsScan and table.find(Var.Admins.InGame, Player) and not Var.DisableBootstrapProtection then
		return {
			false,
			"This person is already an admin and by default cannot be bootstrapped twice. Change this in the configuration module."
		}
	end

	task.spawn(function()
		if LastAdminResult.IsAdmin then
			AR.Bootstrap(Player, LastAdminResult.RankName)
		elseif
			(Var.Services.RunService:IsStudio() and Util.GetSetting("SandboxMode") == true)
			or Var.EnableFreeAdmin
			or ForceAdmin
		then
			AR.Bootstrap(Player, "Administrator")
		end
	end)

	return { true, "Done" }
end

function AR.Removing(Player: Player): ()
	if table.find(Var.Admins.InGame, Player) ~= nil then
		table.remove(Var.Admins.InGame, table.find(Var.Admins.InGame, Player))
		table.insert(Var.Admins.OutOfGame, Player.UserId)
	end
end

function AR.Scan(ForceAdmin: boolean): ()
	for _, Player: Player in Var.Services.Players:GetPlayers() do
		AR.PlayerAdded(Player, ForceAdmin, true)
	end
end

function AR.Ranks.New(Data: Types.AdminRank): Response
	if Var.DataStores.AdminsDS:GetAsync("HasMigratedToV2") == false then
		return { false, Util.t(nil, "admin.rv2.Migrate") }
	end

	Util.Logging.Print("[-] Making a new admin rank...")
	local Start = os.clock()

	xpcall(function()
		local ShouldStep = false
		local OldRankData = nil
		local NewRank = table.clone(Var.DefaultRank)
		local Info = Var.DataStores.AdminsDS:GetAsync("CurrentRanks") or Var.DefaultRankData

		if not Data.RankID or Data.RankID == 0 then
			Data.RankID = Info.Count + 1
			ShouldStep = true
		end

		if Data.IsEdit then OldRankData = Var.DataStores.AdminsDS:GetAsync(`_Rank{Data.RankID}`) end

		NewRank.Name = Data.Name
		NewRank.Color = Data.Color
		NewRank.Modified = os.time()
		NewRank.Protected = Data.Protected
		NewRank.CreatorID = Data.ActingUser
		NewRank.RankID = Data.RankID :: number
		NewRank.CreationReason = Data.CreationReason

		NewRank.Members = Data.Members
		NewRank.Apps = Data.Apps

		table.insert(NewRank.Modifications, {
			Reason = Util.t(nil, "admin.rank.created"),
			ActingAdmin = Data.ActingUser,
			Actions = { "created this rank" }
		})

		Var.DataStores.AdminsDS:SetAsync(Data.Name, NewRank)

		for i, v in Data.Members do
			if v.MemberType == "User" then
				if Info.AdminIDs == nil then Info.AdminIDs = {} end

				Info.AdminIDs[v.ID] = {
					UserID = v.ID,
					AdminRankID = Data.RankID,
					AdminRankName = Data.Name
				}
			else
				--// Identify groups differently because we may have the same group multiple times
				Info.GroupAdminIDs[`{v.ID}_{Var.Services.HttpService:GenerateGUID(false)}`] = {
					GroupID = v.ID,
					RequireRank = v.GroupRank ~= 0,
					RankNumber = v.GroupRank,
					AdminRankID = Data.RankID,
					AdminRankName = Data.Name
				}
			end
		end

		if ShouldStep then
			Info.Count = Data.RankID + 1
			Info.Names = Info.Names or {}

			table.insert(Info.Names, Data.Name)
		end

		if Data.Overwrite ~= true then	
			Var.DataStores.AdminsDS:SetAsync("CurrentRanks", {
				Count         = Info.Count,
				Names         = Info.Names,
				GroupAdminIDs = Info.GroupAdminIDs,
				AdminIDs      = Info.AdminIDs
			})
		end
	end, function(E)
		Util.Logging.Warn(`Failed to create a new admin rank!`, E)
		return { false, E }
	end)

	xpcall(function()
		Var.Services.MessagingService:PublishAsync("Administer", { ["Action"] = "ForceAdminCheck" })
	end, function(e): Types.Response
		Util.Logging.Warn(`[X] Failed to publish MessagingService action ForceAdminCheck! {e}`)
		
		return {
			false,
			Util.t(nil, "admin.rankcreate.MessagingServiceFailed")
		}
	end)

	Util.Logging.Print(`[✓] Done in {os.clock() - Start}`)
	return { true, `Success in {os.clock() - Start}s!` }
end

function AR.Ranks.GetAll()
	local Current: Types.CurrentRanks = Var.DataStores.AdminsDS:GetAsync("CurrentRanks")
	local Ranks = {}
	local Polls = 0

	--// Load in parallel
	for i, RankName in Current.Names do
		task.spawn(function()
			pcall(function()
				Ranks[i] = Var.DataStores.AdminsDS:GetAsync(RankName)
			end)
		end)
	end

	repeat
		Polls += 1
		
		task.wait(0.1)
		
		Util.Logging.Print("Rank check progress:", #Ranks / #Current.Names, Ranks, Current, Polls)
	until #Ranks == #Current.Names or Polls == 10

	if Polls == 10 then
		Util.Logging.Warn(`Only managed to load {#Ranks / #Current.Names}% of ranks, possibly corrupt rank exists!`)
	end

	return Ranks
end

function AR.Socket(Msg)
	local Data = Msg["Data"]

	if Data["Action"] == "ForceAdminCheck" then
		for i, Player in Var.Services.Players:GetPlayers() do
			local AdminResult = Util.IsAdmin(Player)

			if AdminResult["IsAdmin"] and not table.find(Var.Admins.InGame, Player) then
				AR.PlayerAdded(Player)
			elseif not AdminResult["IsAdmin"] and table.find(Var.Admins.InGame, Player) then
				AR.Removing(Player)
				
				Player.PlayerGui:FindFirstChild("AdministerMainPanel"):Destroy()
			end
		end
	end
end

return AR
