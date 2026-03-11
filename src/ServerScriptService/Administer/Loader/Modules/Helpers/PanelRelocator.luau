--// Administer
--// CodingAgent 2026

--// Administer - PanelRelocator
--// Patches AdministerMainPanel's script Sources from the Rojo-managed
--// PanelScripts folder at server startup, before any panel is cloned.
--//
--// HOW IT WORKS:
--//   PanelScripts/ mirrors the script hierarchy inside AdministerMainPanel.
--//   At startup this module walks every Script/LocalScript/ModuleScript in
--//   PanelScripts and resolves the matching instance inside the Panel template
--//   using the same relative path. It then overwrites .Source so players
--//   always get the latest code even though the UI lives in a .rbxm.
--//
--// TO ADD A NEW SCRIPT TO THE SYNC:
--//   Just create the .luau file in PanelScripts/ at the correct path.
--//   No config changes needed — paths are resolved automatically.
--//
--// PATH RULES (PanelScripts/ folder mirrors AdministerMainPanel children):
--//   PanelScripts/Client.client.luau
--//     → AdministerMainPanel.Client
--//   PanelScripts/Client/Modules/Frontend.luau
--//     → AdministerMainPanel.Client.Modules.Frontend
--//   PanelScripts/Client/Modules/Helpers/FirstTimeSetup/init.luau
--//     → AdministerMainPanel.Client.Modules.Helpers.FirstTimeSetup
--//   PanelScripts/Client/Modules/Helpers/FirstTimeSetup/Tour.luau
--//     → AdministerMainPanel.Client.Modules.Helpers.FirstTimeSetup.Tour

local SCRIPT_CLASSES = {
	LocalScript = true,
	ModuleScript = true,
	Script = true,
}

local function resolvePath(root: Instance, parts: { string }): Instance?
	local cur: Instance? = root
	for _, part in parts do
		if cur == nil then
			return nil
		end
		cur = (cur :: Instance):FindFirstChild(part)
	end
	return cur
end

local function getPanelPathParts(src: Instance, psRoot: Instance): { string }
	local parts: { string } = {}
	local cur: Instance? = src
	while cur ~= nil and cur ~= psRoot do
		table.insert(parts, 1, (cur :: Instance).Name)
		cur = (cur :: Instance).Parent
	end
	if parts[#parts] == "init" then
		table.remove(parts)
	end
	return parts
end

return function(panelTemplate: Instance, panelScriptsFolder: Instance): number
	local patched = 0
	local missed = 0

	for _, src in panelScriptsFolder:GetDescendants() do
		if not SCRIPT_CLASSES[src.ClassName] then
			continue
		end

		local parts = getPanelPathParts(src, panelScriptsFolder)
		local target = resolvePath(panelTemplate, parts)

		if target and SCRIPT_CLASSES[target.ClassName] then
			(target :: Script).Source = (src :: Script).Source
			patched += 1
		else
			warn(
				string.format(
					"[PanelRelocator] No match for '%s' (looked for '%s' in %s)",
					src:GetFullName(),
					table.concat(parts, "."),
					panelTemplate:GetFullName()
				)
			)
			missed += 1
		end
	end

	print(string.format("[PanelRelocator] Done — %d scripts patched, %d unmatched.", patched, missed))

	return patched
end
