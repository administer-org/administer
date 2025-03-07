--// Administer
--// pyxfluff 2024 - 2025

local FrontendAPI = {}
local Root = script:FindFirstAncestor("Loader")

local HTTP = require(Root.Modules.HTTPRunner)
local Utils = require(Root.Modules.Utilities)
local Var = require(Root.Core.Variables)

local Types = require(Root.Core.Types)

local Config = Var.Config

function FrontendAPI.NewUpdateLogText(P: Player, Text)
	--// TODO
	--[[
	local Template = P.ScrollingFrame.TextLabel:Clone()

	Template.Visible = true
	Template.Text = Text
	Template.Name = Text
	Template.Parent = P.ScrollingFrame
    ]]
end

function FrontendAPI.VersionCheck(Plr: Player): Types.Response
	--// We need a better system for this
	-- for i, Label in ScrollingFrame:GetChildren() do
	-- 	if Label:IsA("TextLabel") and Label.Name ~= "TextLabel" then Label:Destroy() end
	-- end
	return HTTP.PostRoute(Var.DefaultAppServer, "/pub/versions", {
		current_version = Config.VersData.String,
	}, function(Data: Types.PythonVersionInfo, DebugInfo)
		--// TODO
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
				FrontendAPI.NewUpdateLogText(Plr, Change)
			end
		end

		return
	end, function(StatusCode)
		Utils.NewNotification(
			Plr,
			string.format(Utils.t(Plr, "updater.Failed.Body"), tostring(StatusCode)),
			Utils.t(Plr, "updater.Failed.Header"),
			Utils.Icon("Plr-warning"),
			99999,
			Var.Notification.Ding,
			{}
		)
		return
	end, nil, nil)
end

function FrontendAPI.UpdateHomePage(Player, Data)
	--// do some checks
	if Data == nil then return {
		UserFacingMessage = "Bad data sent by client.",
		Result = "fail",
	} end

	local HomeInfo

	if Data["EventType"] == "UPDATE" then
		--// check current data?
		HomeInfo = Var.DataStores.HomeDS:GetAsync(Player.UserId)

		if not HomeInfo then
			--// This shouldn't happen in practice but best to check?
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
			Result = "success",
			UserFacingMessage = "Done!",
		}
	else
		return {
			Result = "fail",
			UserFacingMessage = "Something happened on Roblox's end, please try again later.",
		}
	end
end

return FrontendAPI
