local module = {}
local Variables = require(script.Parent.Parent.Variables)
local settings = Variables.MainFrame.Configuration.Settings

type settingProperties = { title: string, subtitle: string, description: string, placeholder: string }
type category = { title: string, containers: { title: string, entries: { settingProperties } } }

function module.createCategory(input: category)
	local categoryTemplate = settings
end

return module
