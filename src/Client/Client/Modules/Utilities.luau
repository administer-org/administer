local Utilities = {
	Logging = {}
}

--local RequestSettingsRemote = AdministerRemotes:WaitForChild("SettingsRemote", 10):WaitForChild("RequestSettings", 10)
--local Settings = RequestSettingsRemote:InvokeServer()

-- local Frontend = require(script.Parent.Frontend)
-- TODO fix this
local Frontend = { Log = function(...) end }
local Var = require(script.Parent.Variables)

function Utilities.GetSetting(Setting: string): any
	local setting = Var.Remotes.GetSetting:InvokeServer("Administer", Setting)
	
	return setting
end

function Utilities.GetSettings(settingsArray: {Types.Setting}, UserID: number?): Types.SettingResponse
	local settingData = Var.Remotes.GetSettings:InvokeServer("Administer", settingsArray)

	return settingData
end

function Utilities.GetSettingChanged(Setting: string): RemoteEvent
	local remote = Var.Remotes.GetRemote:InvokeServer("Administer", Setting)
	
	return remote
end

function Utilities.ShortNumber(Number: number): string
	return math.floor(
		((Number < 1 and Number) or math.floor(Number) / 10 ^ (math.log10(Number) - math.log10(Number) % 3))
			* 10 ^ (Var.ShortNumberDecimals)
	) / 10 ^ (Var.ShortNumberDecimals) .. (({
		"k",
		"M",
		"B",
		"T",
		"Qa",
		"Qn",
		"Sx",
		"Sp",
		"Oc",
		"N"
	})[math.floor(math.log10(Number) / 3)] or "")
end

function Utilities.FormatRelativeTime(Unix: number): string
	local TimeDifference = os.time() - (Unix or 0)
	
	if TimeDifference == 1 then
		
	end

	if TimeDifference < 60 then
		return Utilities.Translate("reltime.Now")
	elseif TimeDifference < 3600 then
		local Minutes = math.floor(TimeDifference / 60)
		return string.format(
			Utilities.Translate("reltime.Format"),
			Minutes,
			Utilities.Translate(Minutes == 1 and "reltime.Minute" or "reltime.Minutes")
		)
	elseif TimeDifference < 86400 then
		local Hours = math.floor(TimeDifference / 3600)
		return string.format(
			Utilities.Translate("reltime.Format"),
			Hours,
			Utilities.Translate(Hours == 1 and "reltime.Hour" or "reltime.Hours")
		)
	elseif TimeDifference < 604800 then
		local Days = math.floor(TimeDifference / 86400)
		return string.format(
			Utilities.Translate("reltime.Format"),
			Days,
			Utilities.Translate(Days == 1 and "reltime.Day" or "reltime.Days")
		)
	elseif TimeDifference < 31536000 then
		local Weeks = math.floor(TimeDifference / 604800)
		return string.format(
			Utilities.Translate("reltime.Format"),
			Weeks,
			Utilities.Translate(Weeks == 1 and "reltime.Week" or "reltime.Weeks")
		)
	else
		local Years = math.floor(TimeDifference / 31536000)
		return string.format(
			Utilities.Translate("reltime.Format"),
			Years,
			Utilities.Translate(Years == 1 and "reltime.Year" or "reltime.Years")
		)
	end
end


Utilities.Logging.Print = function(...)
	if Var.Verbosity == "log" then
		print("[Administer] [log]", ...)
		Frontend.Log("log", ...)
	end
end

Utilities.Logging.Warn = function(...)
	warn("[Administer] [warn]", ..., debug.traceback(""))
	Frontend.Log("wrn", ...)
end

Utilities.Logging.Error = function(message: string)
	Frontend.Log("err", message)
	error(`[Administer] [fault] {message}`)
end

function Utilities.NewNotification(
	AppTitle: string,
	Icon: string,
	Body: string,
	Heading: string,
	Duration: number?,
	Options: { any }?
): ()
	local Panel = script.Parent.Parent.Parent

	local OpenTime = Var.AnimationSpeed * 1.25
	Options = Options or {}

	local Placeholder = Instance.new("Frame")
	Placeholder.BackgroundTransparency = 1
	Placeholder.Size = UDim2.fromScale(1.036, 0.142)
	Placeholder.Parent = Panel.Notifications

	local Notification = Panel.Notifications.Template:Clone()
	local NotificationContent = Notification.NotificationContent
	Notification.Visible = true
	Notification.Position = UDim2.fromScale(0, 1.3)
	NotificationContent.Body.Text = Body
	NotificationContent.Header.Title.Text = `<b>{AppTitle}</b> · {Heading}`
	NotificationContent.Header.ImageL.Image = Icon

	if Options then
		for _, Object in Options do
			local NewButton = NotificationContent.Buttons.DismissButton:Clone()
			NewButton.Name = Object["Text"]
			NewButton.Title.Text = Object["Text"]
			NewButton.ImageL.Image = Object["Icon"]
			NewButton.MouseButton1Click:Connect(function()
				Object["OnClick"]()
			end)

			NewButton.Parent = NotificationContent.Buttons
		end
	end

	local NewSound = Instance.new("Sound")
	NewSound.SoundId = "rbxassetid://9770089602"
	NewSound.Parent = NotificationContent
	NewSound:Play()

	Notification.Parent = Panel.NotificationsTweening

	local Tweens: { Tween } = {
		Var.Services.TweenService:Create(
			Notification,
			TweenInfo.new(OpenTime, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{
				Position = UDim2.fromScale(-0.018, 0.858),
			}
		),
		Var.Services.TweenService:Create(
			NotificationContent,
			TweenInfo.new(OpenTime, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{
				GroupTransparency = 0,
			}
		)
	}

	for _, Tween: Tween in Tweens do
		Tween:Play()
	end

	Tweens[1].Completed:Wait()
	Placeholder:Destroy()
	Notification.Parent = Panel.Notifications

	local function Close(Instant: boolean): ()
		if not Instant then Instant = false end

		local NotifTween = Var.Services.TweenService:Create(
			NotificationContent,
			TweenInfo.new((Instant and 0 or OpenTime :: number * 0.7), Enum.EasingStyle.Quad),
			{
				Position = UDim2.fromScale(1, 0),
				GroupTransparency = 1,
			}
		)

		NotifTween:Play()
		NotifTween.Completed:Wait()
		Notification:Destroy()
	end

	NotificationContent.Buttons.DismissButton.MouseButton1Click:Connect(Close)
	task.delay(Duration, Close, false)
end

function Utilities.CreateReflection(Image: string): EditableImage
	--// TODO: I hate this code can we fix it pls
	local RealEI = Var.Services.AssetService:CreateEditableImageAsync(Content.fromUri(Image))
	local Resized = Vector2.new(RealEI.Size.X, RealEI.Size.Y)

	local px = RealEI:ReadPixelsBuffer(Vector2.zero, Resized)
	local rpx = {}

	for i = 1, Resized.X * Resized.Y * 4 do
		table.insert(rpx, buffer.readu8(px, i - 1))
	end

	local npx = {}

	for Chunk = 0, (Resized.X * Resized.Y - 1) do
		local Index = Resized.Y * 4 - (Chunk % Resized.Y) * 4 + math.floor(Chunk / Resized.Y) * Resized.Y * 4 - 3
		table.move(rpx, Chunk * 4 + 1, Chunk * 4 + 4, Index, npx)
	end

	local FinalBuffer = buffer.create(Resized.X * Resized.Y * 4)

	for i = 1, #npx do
		buffer.writeu8(FinalBuffer, i - 1, npx[i])
	end

	RealEI:WritePixelsBuffer(Vector2.zero, Resized, FinalBuffer)

	return RealEI
end

function Utilities.Translate(StringIdentifier: string): string | { string }
	local Locale, LocaleSetting = string.split(Var.Services.LocalizationService.RobloxLocaleId, "-")[1], Utilities.GetSetting("Language")
	
	if Locale ~= LocaleSetting and LocaleSetting ~= "en" then
		--// prefer the setting
		Locale = LocaleSetting
	end
	
	if Var.LocaleModule["_"] == "_init" then
		Utilities.Logging.Print(`Getting locale {Locale}`)

		Var.LocaleModule = Var.Remotes.GetTranslationModule:InvokeServer(
			Locale
		)
	end

	if not Var.LocaleModule[StringIdentifier] then
		if not StringIdentifier:find("__") then
			return StringIdentifier
		else
			return { StringIdentifier, StringIdentifier, StringIdentifier, StringIdentifier, StringIdentifier }
		end
	end

	return Var.LocaleModule[StringIdentifier]
end

Utilities.Icon = function(IconName)
	if not Var.Icons then 
		Utilities.Logging.Print(`Fetching icon pack...`)

		Var.Icons = Var.Remotes.GetIconPack:InvokeServer()
	end

	return `rbxassetid://{Var.Icons[IconName]}`
end

function Utilities.ToSentenceCase(Sentence)
	return Sentence:sub(1, 1):upper() .. Sentence:sub(2):lower()
end

function Utilities.Heartbeat(): ()
	local Ticks = 0

	while true do
		local PingStart = tick()

		Var.Remotes.Ping:InvokeServer()

		table.insert(Var.Ping, (tick() - PingStart) * 1000)

		pcall(function()
			Var.MainFrame.AppDrawer.AppHolder.Apps.ZZ_AdministerData.Version.Text = `{Var.Version.String} ({Var.Services.HttpService:JSONDecode(Var.MainFrame.Parent:GetAttribute("_CurrentBranch")).BranchName}); connected ({tostring((tick() - PingStart) * 1000):sub(1, 5)}ms)`
		end)

		Ticks += 1
		if Ticks == Var.PingTicksLog then
			local sum = 0

			for _, Num in Var.Ping do
				sum += Num
			end

			Utilities.Logging.Print(`Heartbeat staistics: {sum / #Var.Ping}ms avg, {Var.Ping[#Var.Ping - 1]} currently`)
			Ticks = 0
		end

		task.wait(Var.HeartbeatDuration)
	end
end

function Utilities.ProcessDono(
	Player: Player,
	GamePassId: number, 
	WasPurchased: boolean
)
	if WasPurchased and Var.Remotes.GetPasses:InvokeServer()[GamePassId] ~= nil then
		Frontend.Close(false)

		script.Parent.Parent.Parent.FullscreenMessage.LocalScript.Enabled = true
		require(Var.AdministerRoot.Client.Libraries.ConfettiCreator)()
	end
end

function Utilities.CountryToFlag(CountryCode)
	local Flag = ""

	for i = 1, string.len(CountryCode) do
		Flag = Flag .. utf8.char((CountryCode:sub(i, i):byte() % 32) + 0x1F1E5)
	end

	return Flag
end

return Utilities
