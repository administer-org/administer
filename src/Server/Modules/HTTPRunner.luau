--// Administer
--// pyxfluff 2024 - 2025

local Root = script:FindFirstAncestor("Loader")
local Config = require(Root.Core.Configuration)
local Var = require(Root.Core.Variables)
local Types = require(Root.Core.Types)

local Http = {}

--// Stops a circular import with the Utils module
local function RoundMS(num)
	return tostring(num * 1000):sub(1, 7)
end

-- For more information on this API, please refer to the documentation: https://docs.administer.notpyx.me
function Http.GetRoute(AppServer, Route, OnOK, OnError): Types.Response
	local ST = tick()

	local Response = Var.Services.HttpService:RequestAsync({
		Url = `{AppServer}{Route}`,
		Method = "GET",
		Headers = {
			["X-Adm-Version"] = Config.VersData.NoExtraData,
			["X-Adm-Branch"] = string.upper(Var.CurrentBranch.BranchName) --// this is mostly just used for /versions but idc
		}
	})

	if Response.StatusCode == 200 then
		return OnOK(Var.Services.HttpService:JSONDecode(Response.Body), {
			ProcessedMS = RoundMS(tick() - ST),
			RespMessage = Response.StatusMessage,
			Code = 200
		})
	else
		--// Proposed
		--if AppServer == "https://administer.notpyx.me" then
		--	return Http.GetRoute("https://administer-bk2.notpyx.me", Route, OnOK, OnError)
		--end
		local ErrorResp
		
		local R = xpcall(function()
			ErrorResp = OnError(Response.StatusCode, {
				ProcessedMS = RoundMS(tick() - ST),
				RespMessage = Response.StatusMessage,
				Code = Response.StatusCode
			})
		end, function(e)
			warn(`Failed to send out OnError! {e}`)
		end)
		
		return ErrorResp
	end
end

-- For more information on this API, please refer to the documentation: https://docs.administer.notpyx.me
function Http.PostRoute(
	AppServer: string,
	Route: string,
	Body: {},
	OnOK: (any, { ProcTime: number, RespMessage: string, Code: number }) -> any,
	OnError: (any, any) -> any,
	MiscConfig: nil | { Headers: {} },
	DoAnyways: nil | (any) -> any
)
	local ST = tick()
	local FinalHeaders = {}

	if MiscConfig ~= nil then
		for Key, Header in MiscConfig.Headers do
			FinalHeaders[Key] = Header
		end
	else
		FinalHeaders = { ["X-Administer-Version"] = Config.VersData.String }
	end

	local Response = Var.Services.HttpService:RequestAsync({
		Url = `{AppServer}{Route}`,
		Method = "POST",
		Headers = FinalHeaders,
		Body = Var.Services.HttpService:JSONEncode(Body)
	})

	if DoAnyways ~= nil then DoAnyways(Response) end

	if string.sub(tostring(Response.StatusCode), 0, 1) == "2" then
		return OnOK(Var.Services.HttpService:JSONDecode(Response.Body), {
			ProcessedMS = RoundMS(ST - tick()),
			RespMessage = Response.StatusMessage,
			Code = 200
		})
	else
		return OnError(Response.StatusCode :: number, Response)
	end
end

return Http
