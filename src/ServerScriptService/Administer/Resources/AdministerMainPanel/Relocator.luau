--// Administer - UIScript Relocator
--// Moves scripts from the UIScripts holder folder to their correct UI parents,
--// then enables them. Called once at the top of Client/init.client.luau.

local Panel = script.Parent
local Holder = script.Parent.UIScripts

local function place(scriptName: string, getParent: () -> Instance)
	local s = Holder:FindFirstChild(scriptName)
	if not s then
		warn("[Relocator] Script not found: " .. scriptName)
		return
	end

	local ok, parent = pcall(getParent)
	if not ok or parent == nil then
		warn("[Relocator] Could not find parent for: " .. scriptName)
		return
	end

	s.Parent = parent
	s.Enabled = true
end

local M = Panel:WaitForChild("Main")

return function()
	place("FullscreenMessage_Fade", function()
		return Panel:WaitForChild("FullscreenMessage")
	end)

	place("Spinner_NewAdmin", function()
		return M:WaitForChild("Configuration")
			:WaitForChild("Admins")
			:WaitForChild("NewAdmin")
			:WaitForChild("SideDecor")
			:WaitForChild("AdmSpinner")
			:WaitForChild("InnerSpin")
	end)

	place("Spinner_SetupFull", function()
		return M:WaitForChild("Welcome")
			:WaitForChild("SetupFull")
			:WaitForChild("SideDecor")
			:WaitForChild("AdmSpinner")
			:WaitForChild("InnerSpin")
	end)

	place("Notifications_Watcher", function()
		return Panel:WaitForChild("Notifications")
	end)

	place("Notifications_Template_Neon", function()
		return Panel:WaitForChild("Notifications")
			:WaitForChild("Template")
			:WaitForChild("NotificationContent")
			:WaitForChild("Background")
	end)

	place("Notifications_InitialTemplate_Neon", function()
		return Panel:WaitForChild("Notifications")
			:WaitForChild("InitialTemplate")
			:WaitForChild("NotificationContent")
			:WaitForChild("Background")
	end)
end
