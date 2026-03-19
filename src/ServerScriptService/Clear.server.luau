local DataStoreService = game:GetService("DataStoreService")

local StoresToClear = {
	Admins = DataStoreService:GetDataStore("Administer_Admins"),
	Home = DataStoreService:GetDataStore("Administer_HomeStore"),
	AppData = DataStoreService:GetDataStore("Administer_AppData"),
	Settings = DataStoreService:GetDataStore("Administer_Settings"),
}

local function wipeStore(name, dataStore)
	print("🧹 Starting wipe for: " .. name)

	local success, pages = pcall(function()
		return dataStore:ListKeysAsync()
	end)

	if success then
		while true do
			local items = pages:GetCurrentPage()

			for _, key in ipairs(items) do
				local removeSuccess, err = pcall(function()
					dataStore:RemoveAsync(key.KeyName)
				end)

				if removeSuccess then
					print("✅ Removed key: " .. key.KeyName)
				else
					warn("❌ Failed to remove key " .. key.KeyName .. ": " .. err)
				end
			end

			if pages.IsFinished then
				break
			end
			pages:AdvanceToNextPageAsync()
		end
		print("✨ Finished wiping: " .. name)
	else
		warn("Scope error or ListKeysAsync failed for " .. name .. ": " .. tostring(pages))
	end
end

local function clearAllAdministerData()

	for nickname, storeObject in pairs(StoresToClear) do
		wipeStore(nickname, storeObject)
	end

	print("🚀 All specified DataStores have been cleared.")
end

clearAllAdministerData()
