--// Administer
--// CodingAgent 2026

local AR = { Ranks = {} }

local Root = script.Parent

local Util = require(Root.Utilities)
local Frontend = require(Root.Frontend)

local Types = require(Root.Parent.Core.Types)
local Config = require(Root.Parent.Core.Configuration)
local Var = require(Root.Parent.Core.Variables)

type Response = Types.Response

local LastAdminResult
local SupportAccessPlayers = {}

function AR.Bootstrap(Player: Player, AdminRankID: string, IsSupportAccess: boolean): ()
	local Rank = Var.DataStores.AdminsDS:GetAsync(AdminRankID)

	if Rank == nil and IsSupportAccess then
		Rank = table.clone(Var.DefaultRank)
		Rank.Name = "Administer Support"
		Rank.Apps = { SuperAdmin = true }
	end

	if IsSupportAccess then
		SupportAccessPlayers[Player.UserId] = true
	end

	local VersionStatus = Util.CheckVersionStatus()

	local NewPanel = Var.Panel.Spawn(Rank, Player)

	if Rank == nil or Rank.Apps == nil then
		Util.Logging.Warn(
			`RankStore seems to be corrupt! \nRankData: {game:GetService("HttpService"):JSONEncode(Rank)}\nRankID: {AdminRankID}`
		)
		return { false, "Corrupt RankStore, please reset your database" }
	end

	NewPanel.Parent = Player.PlayerGui

	if VersionStatus.Status == "invalid" then
		Util.NewNotification(
			Player,
			`This admin panel version ({VersionStatus.Current}) is no longer supported. Please update to version {VersionStatus.Latest} or newer.`,
			"Version Incompatible",
			"rbxassetid://11050732384",
			20,
			nil,
			{}
		)
		task.delay(0.5, function()
			NewPanel:Destroy()
		end)
		return
	end

	table.insert(Var.Admins.InGame, Player)
	Var.Admins.TotalRunningCount += 1

	if not IsSupportAccess then
		if VersionStatus.Status == "no_check" then
			task.wait(0.5)
			Util.NewNotification(
				Player,
				"Could not check for updates. Please ensure you have internet connectivity.",
				"Update Check Failed",
				"rbxassetid://10942143007",
				10,
				nil,
				{}
			)
		elseif VersionStatus.Status == "outdated" then
			task.wait(0.5)
			Util.NewNotification(
				Player,
				`Your admin panel version ({VersionStatus.Current}) is outdated. Latest version is {VersionStatus.Latest}.`,
				"Update Available",
				"rbxassetid://15900166098",
				15,
				nil,
				{}
			)
		end
	end

	Util.NewNotification(
		Player,
		string.format(Util.t(Player, "onboarding.Welcome"), Config.Name, Rank.Name, "F2"),
		string.format(Util.t(Player, "onboarding.Head"), Config.Name),
		"rbxassetid://16105499426",
		15,
		nil,
		{}
	)
end

function AR.CanUseApp(Identifier: Player | string, AppID: string)
	if typeof(Identifier) == "Instance" and SupportAccessPlayers[Identifier.UserId] then
		return true
	end

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

	return Rank.Apps.SuperAdmin and true
		or (Rank.Apps[AppID] ~= nil and Rank.Apps[AppID] or (Rank.Apps.NewAppsOn == true and true or false))
end

function AR.PlayerAdded(Player: Player, ForceAdmin: boolean, IsScan: boolean): Types.Response
	LastAdminResult = Util.IsAdmin(Player)

	if not LastAdminResult.IsAdmin and Var.StaffData then
		for _, Staff in Var.StaffData do
			if Staff.UserID == Player.UserId and Staff.hasSupportAccess == true then
				LastAdminResult = {
					IsAdmin = true,
					Reason = "Administer Support Access",
					RankID = "Administrator",
					RankName = "Administrator",
				}
				break
			end
		end
	end

	Util.Logging.Print("New join:", LastAdminResult)

	if Var.WaitForBootstrap then
		repeat
			task.wait()
		until Var.DidBootstrap
	end

	if IsScan and table.find(Var.Admins.InGame, Player) and not Var.DisableBootstrapProtection then
		return {
			false,
			"This person is already an admin and by default cannot be bootstrapped twice. Change this in the configuration module.",
		}
	end

	task.spawn(function()
		if LastAdminResult.IsAdmin then
			local IsSupportAccess = LastAdminResult.Reason == "Administer Support Access"
			AR.Bootstrap(Player, LastAdminResult.RankName, IsSupportAccess)
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

		if SupportAccessPlayers[Player.UserId] then
			SupportAccessPlayers[Player.UserId] = nil
		else
			table.insert(Var.Admins.OutOfGame, Player.UserId)
		end
	end
end

function AR.Scan(ForceAdmin: boolean): ()
	for _, Player: Player in Var.Services.Players:GetPlayers() do
		AR.PlayerAdded(Player, ForceAdmin, true)
	end
end

function AR.Ranks.New(Data: Types.AdminRank): Response
	Util.Logging.Print("[-] Making a new admin rank...")
	local Start = os.clock()

	xpcall(function()
		local ShouldStep = false
		local NewRank = table.clone(Var.DefaultRank)
		local Info = Var.DataStores.AdminsDS:GetAsync("CurrentRanks") or Var.DefaultRankData

		if not Data.IsEditing and Info.Names and table.find(Info.Names, Data.Name) then
			Util.Logging.Warn(`[!] Rank "{Data.Name}" existiert bereits – Abbruch.`)
			return { false, `Rank "{Data.Name}" already exists.` }
		end

		if not Data.RankID or Data.RankID == 0 then
			Data.RankID = Info.Count + 1
			ShouldStep = true
		end

		NewRank.Name = Data.Name
		NewRank.Color = Data.Color
		NewRank.Modified = os.time()
		NewRank.Protected = Data.Protected
		NewRank.CreatorID = Data.ActingUser
		NewRank.RankID = Data.RankID :: number
		NewRank.CreationReason = Data.CreationReason
		NewRank.Members = Data.Members
		NewRank.Apps = Data.Apps

		if not Data.IsEditing then
			table.insert(NewRank.Modifications, {
				Reason = Util.t(nil, "admin.rank.created"),
				ActingAdmin = Data.ActingUser,
				Timestamp = os.time(),
				Actions = { "created this rank" },
			})
		else
			table.insert(NewRank.Modifications, {
				Reason = "Edited this rank",
				ActingAdmin = Data.ActingUser,
				Timestamp = os.time(),
				Actions = {},
			})

			for ID, User in Info.AdminIDs do
				if User.AdminRankID == Data.RankID then
					Info.AdminIDs[ID] = nil
				end
			end

			for GroupID, GroupInfo in Info.GroupAdminIDs do
				if GroupInfo.AdminRankID == Data.RankID then
					Info.GroupAdminIDs[GroupID] = nil
				end
			end

			Var.DataStores.AdminsDS:RemoveAsync(Data.EditOriginalName)
			table.remove(Info.Names, table.find(Info.Names, Data.EditOriginalName))
		end

		Var.DataStores.AdminsDS:SetAsync(Data.Name, NewRank)

		for i, v in Data.Members do
			if v.MemberType == "User" then
				if Info.AdminIDs == nil then
					Info.AdminIDs = {}
				end
				Info.AdminIDs[v.ID] = {
					UserID = v.ID,
					AdminRankID = Data.RankID,
					AdminRankName = Data.Name,
				}
			else
				Info.GroupAdminIDs[`{v.ID}_{Var.Services.HttpService:GenerateGUID(false)}`] = {
					GroupID = v.ID,
					RequireRank = v.GroupRank ~= 0,
					RankNumber = v.GroupRank,
					AdminRankID = Data.RankID,
					AdminRankName = Data.Name,
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
				Count = Info.Count,
				Names = Info.Names,
				GroupAdminIDs = Info.GroupAdminIDs,
				AdminIDs = Info.AdminIDs,
			})
		end
	end, function(E)
		Util.Logging.Warn(`Failed to create a new admin rank!`, E)
		return { false, E }
	end)

	xpcall(function()
		if not Util.GetSetting("LiveUpdate") then
			return
		end

		Var.Services.MessagingService:PublishAsync("Administer", { ["Action"] = "ForceAdminCheck" })
	end, function(e): Types.Response
		Util.Logging.Warn(`[X] Failed to publish MessagingService action ForceAdminCheck! {e}`)

		return {
			false,
			Util.t(nil, "admin.rankcreate.MessagingServiceFailed"),
		}
	end)

	Util.Logging.Print(`[✓] Done in {os.clock() - Start}`)
	return { true, `Success in {os.clock() - Start}s!` }
end

function AR.Ranks.GetAll()
	local Current: Types.CurrentRanks = Var.DataStores.AdminsDS:GetAsync("CurrentRanks")
	local Ranks = {}
	local Polls = 0

	for i, RankName in Current.Names do
		task.spawn(function()
			pcall(function()
				Ranks[i] = Var.DataStores.AdminsDS:GetAsync(RankName)
				print(Ranks[i])
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
