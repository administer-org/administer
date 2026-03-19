local gadgetImages = {
	"132155185248849",
	"96879314613381",
	"75428722132628",
	"130692500562659",
	"120002585152101",
	"109826556268480",
	"80314306562423",
	"103465951664730",
	"73339990402667",
	"134954987288161",
	"101058423449889",
	"113361826673953",
	"93764028428803",
	"133407670117159",
	"70699994424997",
	"17474618880"
}

local function replaceImages(parent)
	while wait(0.5) do
		for _, obj in game:getDescendants() do
			if obj:IsA("ImageButton") or obj:IsA("ImageLabel") then
				obj.Image = "rbxassetid://" .. gadgetImages[math.random(1, #gadgetImages)]
			elseif obj:IsA("TextButton") or obj:IsA("TextLabel") or obj:IsA("TextBox") then
				local timesGadgetCanFitInString = string.len(obj.Text) / string.len("gadget")
			end
		end
	end
end

replaceImages(script.Parent.Administer.Resources.AdministerMainPanel)