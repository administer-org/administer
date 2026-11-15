local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CommandIndex = require(script.Parent.Parent.Modules.CommandProcessor).GetCommandIndex(nil)

local function parseUsers(arguments: string): ({ number }?, string?)
	local startAt, endAt = string.find(string.lower(arguments), "users%s*:%s*")
	if not startAt then
		return nil, "Users is required (for example, Users:[123456])."
	end
	local value = string.sub(arguments, endAt + 1)
	local json = string.match(value, "^%b[]")
	local users
	if json then
		local ok, decoded = pcall(HttpService.JSONDecode, HttpService, json)
		if not ok then
			return nil, "Users must be a JSON array of user IDs."
		end
		users = decoded
	else
		users = { string.match(value, "^(%d+)") }
	end
	if type(users) ~= "table" or #users == 0 or #users > 50 then
		return nil, "Provide 1–50 user IDs."
	end
	local ids = {}
	local seen = {}
	for _, valueId in users do
		local id = tonumber(valueId)
		if not id or id < 1 or id % 1 ~= 0 then
			return nil, "Every user ID must be a positive integer."
		end
		if not seen[id] then
			seen[id] = true
			table.insert(ids, id)
		end
	end
	return ids, nil
end

return {
	{
		Name = "Kill",
		Description = CommandIndex.Kill.Description,
		Icon = "AppDefaults",
		Flags = {
			Users = {
				Type = "json",
				Description = "Target user IDs (for example, [123456]).",
				Required = true,
			},
		},
		Execute = function(_player: Player, arguments: string)
			local ids, err = parseUsers(arguments)
			if not ids then
				return { false, err }
			end
			local count = 0
			for _, id in ids do
				local target = Players:GetPlayerByUserId(id)
				if target and CommandIndex.Kill.Trigger(target) then
					count += 1
				end
			end
			return { count > 0, count > 0 and `Killed {count} player(s).` or "No target players are alive in this server." }
		end,
	},
}
