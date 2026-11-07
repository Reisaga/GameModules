local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	return
end

local requestFunc = (syn and syn.request)
	or (http and http.request)
	or http_request
	or (fluxus and fluxus.request)
	or request

if type(requestFunc) ~= "function" then
	return
end

local placeId = game.PlaceId
local currentJobId = game.JobId

local env = (getgenv and getgenv()) or _G
env.HopVisitedServers = env.HopVisitedServers or {}
if currentJobId and currentJobId ~= "" then
	env.HopVisitedServers[currentJobId] = true
end

local autoHopEnabled = true
local autoHopInProgress = false
local minPlayersLimit = 1
local maxPlayersLimit = 1
local hopDelay = 30
local apiRequestDelay = 0.25
local isScanning = false
local scanGeneration = 0
local allDiscoveredServers = {}
local statusParagraph = nil

local gameName = "Roblox Experience"
pcall(function()
	local info = MarketplaceService:GetProductInfo(placeId)
	if info and info.Name then
		gameName = info.Name
	end
end)

local VindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Skinny-yz/VVind-UI/refs/heads/main/src.lua"))()
VindUI:PreloadIcons({ "Lucide", "Material", "Phosphor", "SF" })
VindUI:SetScaleRange(0.75, 1.35)

local Window = VindUI:CreateWindow({
	Title = "Low Server Finder",
	Subtitle = gameName,
	Icon = "Lucide:server",
	Size = UDim2.fromOffset(590, 440),
	MinSize = Vector2.new(460, 330),
	Draggable = true,
	Resizable = true,
	UseBlur = true,
	DefaultTab = "Finder",
})

local Tabs = {}
Tabs.Finder = Window:AddTab({ Name = "Server Finder", Icon = "Lucide:server" })
Tabs.Settings = Window:AddTab({ Name = "Settings", Icon = "Lucide:settings" })

local updateStatusText = function(title, body)
	if statusParagraph and statusParagraph.Set then
		statusParagraph:SetTitle(title)
		statusParagraph:Set(body)
	end
end

Tabs.Finder:AddSection("Cau hinh Auto Hop Chuyen Sau", "Lucide:sliders")

Tabs.Finder:AddToggle({
	Text = "Auto Hop (Tu dong vao)",
	Description = "Tu dong tim va chuyen den server it nguoi nhat",
	Icon = "Lucide:zap",
	Flag = "autoHop",
	Default = true,
	Callback = function(value)
		autoHopEnabled = value
		if autoHopEnabled then
			updateStatusText("Auto Hop", string.format("Bat: Uu tien server <= %d nguoi...", maxPlayersLimit))
		else
			autoHopInProgress = false
			updateStatusText("Auto Hop", "Da tat Auto Hop.")
		end
	end,
})

Tabs.Finder:AddSlider({
	Text = "So nguoi toi da chap nhan",
	Description = "Dat 1 de chi tim server dung 1 nguoi",
	Icon = "Lucide:users",
	Flag = "maxPlayers",
	Min = 1,
	Max = 5,
	Default = 1,
	Increment = 1,
	Suffix = " nguoi",
	Callback = function(value)
		maxPlayersLimit = math.floor(tonumber(value) or 1)
	end,
})

Tabs.Finder:AddSlider({
	Text = "Delay moi lan Hop (Cooldown)",
	Description = "Thoi gian cho truoc khi hop sang server tiep theo",
	Icon = "Lucide:clock",
	Flag = "hopDelay",
	Min = 5,
	Max = 60,
	Default = 30,
	Increment = 5,
	Suffix = "s",
	Callback = function(value)
		hopDelay = math.floor(tonumber(value) or 30)
	end,
})

Tabs.Finder:AddSlider({
	Text = "Do tre quet API",
	Description = "Thoi gian nghi giua cac trang API",
	Icon = "Lucide:timer",
	Flag = "apiRequestDelay",
	Min = 0.15,
	Max = 1.0,
	Default = 0.25,
	Increment = 0.05,
	Suffix = "s",
	Callback = function(value)
		apiRequestDelay = tonumber(value) or 0.25
	end,
})

Tabs.Finder:AddDivider()
Tabs.Finder:AddSection("Trang thai & Dieu khien", "Lucide:activity")

statusParagraph = Tabs.Finder:AddParagraph({
	Title = "Trang thai",
	Icon = "Lucide:info",
	Text = "Dang kiem tra so nguoi trong server...",
})

local startAutoScan
local attemptAutoHop

attemptAutoHop = function()
	if not autoHopEnabled or autoHopInProgress then
		return
	end

	local candidates = {}
	for _, s in ipairs(allDiscoveredServers) do
		local pl = tonumber(s.playing) or 0
		local mx = tonumber(s.maxPlayers) or 0
		if mx > pl and pl >= minPlayersLimit and pl <= maxPlayersLimit and not env.HopVisitedServers[s.id] then
			table.insert(candidates, s)
		end
	end

	table.sort(candidates, function(a, b)
		local ap = tonumber(a.playing) or 0
		local bp = tonumber(b.playing) or 0
		if ap ~= bp then
			return ap < bp
		end
		local aFree = (tonumber(a.maxPlayers) or 0) - ap
		local bFree = (tonumber(b.maxPlayers) or 0) - bp
		return aFree > bFree
	end)

	local target = candidates[1]
	if not target then
		updateStatusText("Dang tim", string.format("Chua thay server <= %d nguoi. Tiep tuc quet...", maxPlayersLimit))
		task.delay(1.5, function()
			if autoHopEnabled and not isScanning then
				startAutoScan()
			end
		end)
		return
	end

	env.HopVisitedServers[target.id] = true
	autoHopInProgress = true
	updateStatusText("Dich chuyen", string.format("Dang vao server %d nguoi (ID: %s)", target.playing, target.id))
	VindUI:Notify({ Title = "Auto Hop", Text = string.format("Vao server %d nguoi...", target.playing), Type = "success", Duration = 3 })

	local ok, err = pcall(function()
		TeleportService:TeleportToPlaceInstance(placeId, target.id, LocalPlayer)
	end)

	if not ok then
		autoHopInProgress = false
		updateStatusText("Loi vao server", tostring(err) .. "; thu server khac sau 2s...")
		task.delay(2.0, function()
			if autoHopEnabled then
				attemptAutoHop()
			end
		end)
	else
		task.delay(12, function()
			if autoHopInProgress then
				autoHopInProgress = false
				if autoHopEnabled then
					attemptAutoHop()
				end
			end
		end)
	end
end

local fetchServers = function(cursor)
	local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", placeId)
	if cursor and cursor ~= "" then
		url = url .. "&cursor=" .. HttpService:UrlEncode(cursor)
	end

	for attempt = 1, 4 do
		local ok, response = pcall(function()
			return requestFunc({
				Url = url,
				Method = "GET",
				Headers = {
					["Accept"] = "application/json",
					["Cache-Control"] = "no-cache",
				},
			})
		end)

		if ok and type(response) == "table" then
			local statusCode = tonumber(response.StatusCode or response.Status)
			local body = response.Body or response.body
			if body and (statusCode == nil or statusCode == 200) and response.Success ~= false then
				local decOk, payload = pcall(function()
					return HttpService:JSONDecode(body)
				end)
				if decOk and type(payload) == "table" and type(payload.data) == "table" then
					return payload
				end
			end
		end
		task.wait(attempt * 0.4)
	end
	return nil
end

startAutoScan = function()
	if isScanning then
		return
	end

	isScanning = true
	scanGeneration = scanGeneration + 1
	local thisGen = scanGeneration
	allDiscoveredServers = {}
	updateStatusText("Dang quet", "Bat dau quet tim server it nguoi nhat...")

	task.spawn(function()
		local cursor = nil
		local seenIds = {}
		local foundTarget = false

		for page = 1, 60 do
			if thisGen ~= scanGeneration then
				return
			end

			updateStatusText("Dang quet", string.format("Trang %d | Tim duoc %d server hop le", page, #allDiscoveredServers))
			local payload = fetchServers(cursor)
			if not payload then
				break
			end

			for _, s in ipairs(payload.data) do
				if type(s) == "table" and type(s.id) == "string" and s.id ~= "" then
					local playing = tonumber(s.playing)
					local maxPlayers = tonumber(s.maxPlayers)
					local isCurrent = (currentJobId ~= "" and s.id == currentJobId)

					if playing and maxPlayers and not isCurrent and not seenIds[s.id] and not env.HopVisitedServers[s.id] then
						seenIds[s.id] = true
						table.insert(allDiscoveredServers, {
							id = s.id,
							playing = playing,
							maxPlayers = maxPlayers,
						})

						if playing >= minPlayersLimit and playing <= maxPlayersLimit then
							foundTarget = true
						end
					end
				end
			end

			if autoHopEnabled and foundTarget and not autoHopInProgress then
				task.spawn(attemptAutoHop)
				break
			end

			cursor = payload.nextPageCursor
			if not cursor or cursor == "" then
				break
			end
			task.wait(apiRequestDelay)
		end

		if thisGen ~= scanGeneration then
			return
		end

		isScanning = false
		updateStatusText("Hoan tat", string.format("Quet xong. Tong: %d server.", #allDiscoveredServers))

		if autoHopEnabled and not autoHopInProgress then
			task.delay(0.1, attemptAutoHop)
		end
	end)
end

Tabs.Finder:AddButton({
	Text = "Quet & Hop ngay lap tuc",
	Description = "Bo qua thoi gian cho 30s de tim server moi ngay",
	Icon = "Lucide:fast-forward",
	Callback = function()
		startAutoScan()
	end,
})

Tabs.Finder:AddButton({
	Text = "Dung Auto Hop",
	Description = "Dung quet va dung tu dong hop",
	Icon = "Lucide:circle-stop",
	Callback = function()
		autoHopEnabled = false
		autoHopInProgress = false
		scanGeneration = scanGeneration + 1
		isScanning = false
		updateStatusText("Da dung", "Da dung Auto Hop.")
	end,
})

Tabs.Settings:AddSection("Giao dien & Cai dat", "Lucide:sliders-horizontal")

Tabs.Settings:AddToggle({
	Text = "Dark Mode",
	Description = "Bat hoac tat che do toi",
	Icon = "Lucide:moon",
	Flag = "darkMode",
	Default = true,
	Callback = function() end,
})

Tabs.Settings:AddToggle({
	Text = "Background Blur",
	Description = "Lam mo the gioi khi mo menu",
	Icon = "Lucide:sparkles",
	Flag = "blur",
	Default = true,
	Callback = function(value)
		VindUI:SetBlurEnabled(value)
	end,
})

Tabs.Settings:AddKeybind({
	Text = "Phim mo/dong menu",
	Description = "Nhan phim de bat hoac tat menu",
	Icon = "Lucide:keyboard",
	Flag = "toggleKey",
	Default = Enum.KeyCode.RightShift,
	Callback = function(key, kind)
		if kind == "press" then
			Window:Toggle()
		end
	end,
})

Tabs.Settings:AddDivider()
Tabs.Settings:AddParagraph({
	Title = "Co che Delay 30s & Loc 1 nguoi",
	Icon = "Lucide:shield-check",
	Text = "Moi server se duoc danh gia trong 30 giay. Neu sau 30 giay (hoac khi vua vao) server vuot qua so nguoi cho phep, he thong se thuc hien hop tiep theo dung delay 30s de tranh bi Roblox gioi han toc do (rate-limit).",
})

pcall(function()
	TeleportService.TeleportInitFailed:Connect(function(player, result, errorMessage)
		if player == LocalPlayer then
			autoHopInProgress = false
			updateStatusText("Dich chuyen that bai", tostring(result) .. " - " .. tostring(errorMessage))
			if autoHopEnabled then
				task.delay(3, attemptAutoHop)
			end
		end
	end)
end)

Window:SelectTab("Server Finder")
Window:Open()

VindUI:Notify({
	Title = "Low Server Finder",
	Text = "Che do tim server it nguoi (Delay 30s) da bat!",
	Type = "success",
	Duration = 3,
})

task.spawn(function()
	task.wait(3.0)
	while true do
		local currentCount = #Players:GetPlayers()
		if not autoHopEnabled then
			task.wait(2)
		elseif currentCount > maxPlayersLimit then
			for remaining = hopDelay, 1, -1 do
				if not autoHopEnabled then
					break
				end
				updateStatusText(
					string.format("Server dong (%d nguoi)", currentCount),
					string.format("Vuot qua muc toi da (%d nguoi). Se hop sau %d giay...", maxPlayersLimit, remaining)
				)
				task.wait(1)
			end
			if autoHopEnabled and not autoHopInProgress then
				startAutoScan()
			end
		else
			updateStatusText(
				string.format("Server chuan (%d nguoi)", currentCount),
				string.format("Server hien tai dat yeu cau (<= %d nguoi). Tiep tuc giam sat...", maxPlayersLimit)
			)
			task.wait(5)
		end
	end
end)
