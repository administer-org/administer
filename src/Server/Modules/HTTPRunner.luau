--// Administer
--// pyxfluff 2024 - 2025

local Root = script:FindFirstAncestor("Loader")
local Config = require(Root.Core.Configuration)
local Var = require(Root.Core.Variables)
local Types = require(Root.Core.Types)

local Http = {}
local KnownOfflineInstances = {}
local ActiveFailoverDomain = ""

--// Stops a circular import with the Utils module
local function RoundMS(num)
	return tostring(num * 1000):sub(1, 7)
end

--// same with Apps..
local function FindAOSInstances()
	local function DoStatusCheck(URL)
		local Start = tick()

		if table.find(KnownOfflineInstances, URL) ~= nil then 
			return {
				IsUp = false,
				Ping = 5000
			} 
		end --// nice try

		return Http.GetRoute(URL, "/pub/.administer", function(Data, Debugging)
			return {
				IsUp = true,
				Ping = Debugging.ProcessedMS,
				Version = Data.api_version,
				IsDev = Data.is_dev
			}
		end, function(_, Data)
			return {
				IsUp = false,
				Ping = Data.ProcessedMS
			}
		end, {
			DontLookForAlts = true,
			Timeout = 3
		})
	end

	return Http.GetRoute("https://gateway.admsoftware.org", `/`, function(Content)
		for _, URL in Content.instances do
			local Result = DoStatusCheck(URL.url)

			for Key, Value in Result do
				URL[Key] = Value
			end
		end

		return Content.instances
	end, function(...)
		print(...)
	end)
end

-- For more information on this API, please refer to the documentation: https://docs.admsoftware.org
function Http.GetRoute(
	AppServer, 
	Route, 
	OnOK, 
	OnError, 
	Options: {Timeout: number, DontLookForAlts: boolean}
): Types.Response
	if AppServer == nil or AppServer == "" then
		AppServer = Var.PrimaryAppServer ~= "" and Var.PrimaryAppServer ~= nil and Var.PrimaryAppServer or Var.DefaultAppServer 
	end
	
	local ST = tick()
	local Response
	local IsAOS = string.match(AppServer, "^https://aos%-.+%.admsoftware%.org$") ~= nil
	
	Options = Options or {}
	
	local Timeout = Options.Timeout or 5
	
	if AppServer == "" then error() end

	xpcall(function()
		local function DoRequest()
			Response = Var.Services.HttpService:RequestAsync({
				Url = `{AppServer}{Route}`,
				Method = "GET",
				Headers = {
					["X-Adm-Version"] = Config.VersData.NoExtraData,
					["X-Adm-Branch"] = string.upper(Var.CurrentBranch.BranchName) --// this is mostly just used for /versions but idc
				}
			})
		end

		local Thread = task.spawn(DoRequest)

		repeat task.wait() until Response or tick() - ST >= Timeout

		if tick() - ST >= Timeout and not Response then
			task.cancel(Thread)	

			Response = {
				StatusCode = 500,
				StatusMessage = `Administer - The request timed out`
			}
		end

	end, function(e)
		Response = {
			StatusCode = 500,
			StatusMessage = `Administer - Failed HTTP request: {e}`
		}
	end)

	if string.sub(tostring(Response.StatusCode), 1, 1) == "2" then
		local JSON
		xpcall(function()
			JSON = Var.Services.HttpService:JSONDecode(Response.Body)
		end, function()
			JSON = Response.Body
		end)

		return OnOK(JSON, {
			ProcessedMS = RoundMS(tick() - ST),
			RespMessage = Response.StatusMessage,
			Code = 200
		})
	else
		if (IsAOS and not Options.DontLookForAlts) or ActiveFailoverDomain == AppServer and string.sub(tostring(Response.StatusCode), 1, 1) ~= "4" then
			print("[Administer] You Primary AOS instance is currently offline, selecting another")
			print(Response)

			table.insert(KnownOfflineInstances, AppServer)

			local AvailableServers = FindAOSInstances()
			local LowestPing = 999999
			print(AvailableServers)
			
			--// find lowest ping and set it as primary for now
			for _, Server in AvailableServers do
				if tonumber(Server.Ping) < LowestPing then
					LowestPing = tonumber(Server.Ping)
					ActiveFailoverDomain = Server.url
				end 
			end
			
			--// retry!!
			return Http.GetRoute(ActiveFailoverDomain, Route, OnOK, OnError, Options)
		end

		local ErrorResp

		local R = xpcall(function()
			ErrorResp = OnError(Response.StatusCode, {
				ProcessedMS = RoundMS(tick() - ST),
				RespMessage = Response.StatusMessage,
				Code = Response.StatusCode
			})
		end, function(e)
			warn(`[Administer] Failed to send out OnError! {e}`)
		end)

		return ErrorResp
	end
end

-- For more information on this API, please refer to the documentation: https://docs.admsoftware.org
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

function Http.GUID()
	return Var.Services.HttpService:GenerateGUID(false)
end

return Http
