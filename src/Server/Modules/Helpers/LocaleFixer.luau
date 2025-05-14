local Fixes = {
    
}

local function requireModulesInDir(directory)
	local modules = {}
	local function scan(dir)
		for _, item in ipairs(dir:GetChildren()) do
			if item:IsA("ModuleScript") then
				modules[item.Name] = require(item) :: any
			elseif item:IsA("Folder") then
				scan(item)
			end
		end
	end
	scan(directory)
	return modules
end

return function(directory)
	local modules = requireModulesInDir(directory)
	local baseModule = modules["en"]
	if not baseModule then error("Missing reference module: 'en'") end

	local MissingKeys = {}

	for moduleName, module in modules do
        local missing = {}
		if moduleName ~= "en" then
			for key in pairs(baseModule) do
				if module[key] == nil then table.insert(missing, key) end
			end
			MissingKeys[moduleName] = missing
		end
	end

	for moduleName, keys in MissingKeys do
		print("* Module:", moduleName)
		for _, key in keys do
			print("  - Missing key:", key)
		end
	end
end
