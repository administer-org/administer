--// pyxfluff 2024
--// Player Management

--// Modules

--// Variables
local IsAdmin
--local BaseAnnouncementsGui = script.Parent:WaitForChild("UI"):WaitForChild("Announcements")
--local ControllsCanvas = BaseAnnouncementsGui:WaitForChild("Controls")
--local BaseButtons = {
--	BaseAnnouncementsGui:WaitForChild("BannerSend"),
--	BaseAnnouncementsGui:WaitForChild("FullscreenSend"),
--	BaseAnnouncementsGui:WaitForChild("SmallAlertSend"),
--}
--local TextBoxes = {
--	["Duration"] = ControllsCanvas:WaitForChild("AnnouncementDuration"),
--	["Text"] = ControllsCanvas:WaitForChild("AnnouncementText"),
--	["AnonMode"] = ControllsCanvas:WaitForChild("AnonMode"),
--	["Image"] = ControllsCanvas:WaitForChild("DecalID"),
--	["IDBox"] = ControllsCanvas:WaitForChild("IDSpecifier"),
--}

----// Functions
local function CommunicateWithClient(Player, ...) end

--local function FormatSeconds()
--	local DurationBox = TextBoxes.Duration
--	local Sep = string.split(string.lower(DurationBox.Text), " ")

--	if not tonumber(Sep[1]) then
--		DurationBox.Text = "Bad input, try again (according to \"x (time unit)\")"
--		Shm:Pause()
--		Shm:GetFrame():Destroy()

--		return
--	end

--	local Seconds = ((
--		Sep[2] == "seconds" and 1 or
--			Sep[2] == "minutes" and 60 or
--			Sep[2] == "hours" and (60 * 60) or
--			Sep[2] == "days" and (60 * 60 * 24) or
--			Sep[2] == "weeks" and (60 * 60 * 24 * 7) or
--			Sep[2] == "months" and (60 * 60 * 24 * 7 * 30) or --// 30 just to be safe
--			Sep[2] == "years" and (60 * 60 * 24 * 7 * 30 * 365) or
--			Sep[2] == "year" and (60 * 60 * 24 * 7 * 30 * 365) or
--			Sep[2] == "month" and (60 * 60 * 24 * 7 * 30) or
--			Sep[2] == "week" and (60 * 60 * 24 * 7) or
--			Sep[2] == "day" and (60 * 60 * 24) or
--			Sep[2] == "hour" and (60 * 60) or
--			Sep[2] == "minute" and 60 or
--			Sep[2] == "second" and 1
--			or 0
--		) * tonumber(Sep[1])
--	)

--	return Seconds
--end

--local function GetAnnouncementBoxData()
--	local Data = {
--		DurationTime = FormatDuration()
--	}

--	warn(Data.DurationTime)
--end

--local function GetAnnnouncementType(Data)

--end

--local function SendAnnnouncement(Player,Button)
--	warn(1)
--	local Data = GetAnnouncementBoxData()
--	local Type = GetAnnnouncementType(Data)
--end

local UIFolder = script.Parent:WaitForChild("UI")

--// Run

--task.wait(1)

--for Index, Value : Frame in pairs(BaseButtons) do
--	if Value and Value:IsA("Frame") then
--		local Hitbox = Instance.new("TextButton")
--		Hitbox.Text = ""
--		Hitbox.Size = Value.Size
--		Hitbox.Position = Value.Position
--		Hitbox.AnchorPoint = Value.AnchorPoint
--		Hitbox.ZIndex = (1 / 0)
--		Hitbox.Name = "_Hitbox_"
--		Hitbox.Parent = Value.Parent
--		Hitbox.MouseEnter:Connect(function()
--			warn("IT WORKS")
--		end)
--	end
--end
