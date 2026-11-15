local Commands = {
	"Anchor",
	"Blind",
	"Blur",
	"Bring",
	"BuildTools",
	"Crash",
	"Fling",
	"Fly",
	"Jail",
	"Kill",
	"Morph",
	"NoClip",
	"PlaySound",
	"PromptPurchase",
	"SendTo",
	"SetJP",
	"SetSpeed",
	"Sit",
	"Teleport",
	"Watch",
}

local CommandModules = script.Parent.CommandModules

return {
	GetCommandIndex = function(Remote)
		local Index = {}

		for _, name in Commands do
			local moduleScript = CommandModules:FindFirstChild(name)
			if moduleScript then
				Index[name] = require(moduleScript)(Remote)
			end
		end

		return Index
	end,

	Commands = Commands,
}
