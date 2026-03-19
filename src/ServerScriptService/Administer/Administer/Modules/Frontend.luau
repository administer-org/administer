--// Administer
--// CodingAgent 2026

local FrontendAPI = {}
local Root = script:FindFirstAncestor("Loader")

local HTTP = require(Root.Modules.HTTPRunner)
local Utils = require(Root.Modules.Utilities)
local Var = require(Root.Core.Variables)

local Types = require(Root.Core.Types)

local Config = Var.Config

function FrontendAPI.VersionCheck(Plr: Player): Types.Response
	return HTTP.PostRoute(Var.DefaultAppServer, "/pub/versions", {
		current_version = Config.VersData.String,
	}, function(Data: Types.PythonVersionInfo, DebugInfo)
		if Data.provided_information.outdated then
			Utils.NewNotification(
				Plr,
				string.format(Utils.t(Plr, "updater.outofdate.Body")),
				Utils.t(Plr, "updater.outofdate.Header"),
				Utils.Icon("check"),
				15,
				Var.Notification.Ding,
				{}
			)

			for _, Change in Data.versions[Data.provided_information.can_update_to.name].logs do
			end
		end

		return Data
	end, function(StatusCode, Info)
		print(StatusCode, Info)
		Utils.NewNotification(
			Plr,
			string.format(Utils.t(Plr, "updater.Failed.Body"), tostring(StatusCode)),
			Utils.t(Plr, "updater.Failed.Header"),
			Utils.Icon("Plr-warning"),
			99999,
			Var.Notification.Ding,
			{}
		)

		return {
			false,
			Info,
		}
	end, nil, nil)
end

function FrontendAPI.UpdateHomePage(Player, Data)
	if Data == nil then
		return {
			Success = true,
			Message = "Bad data sent by client.",
		}
	end

	local HomeInfo

	if Data["EventType"] == "UPDATE" then
		HomeInfo = Var.DataStores.HomeDS:GetAsync(Player.UserId)

		if not HomeInfo then
			HomeInfo = Var.BaseHomeInfo
		end

		HomeInfo[Data["WidgetID"]] = Data["NewIdentifier"]
	end

	if
		pcall(function()
			Utils.Logging.Print(`Saving homescreen data for {Player.Name}!`)

			Var.DataStores.HomeDS:SetAsync(Player.UserId, HomeInfo)
		end)
	then
		return {
			Success = true,
			Message = "Done!",
		}
	else
		return {
			Success = false,
			Message = "Something happened on Roblox's end, please try again later.",
		}
	end
end

return FrontendAPI
