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
local maxPlayersLimit = 2
local requestDelay = 0.20
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
	Size = UDim2.fromOffset(580, 430),
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

Tabs.Finder:AddSection("Cau hinh Auto Hop Chuan", "Lucide:sliders")

Tabs.Finder:AddToggle({
	Text = "Auto Hop (Tu dong vao)",
	Description = "Tu dong quet va vao server it nguoi nhat",
	Icon = "Lucide:zap",
	Flag = "autoHop",
	Default = true,
	Callback = function(value)
		autoHopEnabled = value
		if autoHopEnabled then
			updateStatusText("Auto Hop", string.format("Bat: Uu tien server %d-%d nguoi...", minPlayersLimit, maxPlayersLimit))
			startAutoScan()
		else
			autoHopInProgress = false
			updateStatusText("Auto Hop", "Da tat Auto Hop.")
		end
	end,
})

Tabs.Finder:AddSlider({
	Text = "Nguoi choi toi thieu",
	Description = "So nguoi it nhat trong server",
	Icon = "Lucide:user",
	Flag = "minPlayers",
	Min = 0,
	Max = 5,
	Default = 1,
	Increment = 1,
	Suffix = " nguoi",
	Callback = function(value)
		minPlayersLimit = math.floor(tonumber(value) or 1)
	end,
})

Tabs.Finder:AddSlider({
	Text = "Nguoi choi toi da",
	Description = "So nguoi nhieu nhat chap nhan",
	Icon = "Lucide:users",
	Flag = "maxPlayers",
	Min = 1,
	Max = 5,
	Default = 2,
	Increment = 1,
	Suffix = " nguoi",
	Callback = function(value)
		maxPlayersLimit = math.floor(tonumber(value) or 2)
	end,
})

Tabs.Finder:AddSlider({
	Text = "Do tre quet (Delay)",
	Description = "Thoi gian cho giua cac trang API",
	Icon = "Lucide:timer",
	Flag = "requestDelay",
	Min = 0.15,
	Max = 1.0,
	Default = 0.20,
	Increment = 0.05,
	Suffix = "s",
	Callback = function(value)
		requestDelay = tonumber(value) or 0.20
	end,
})

Tabs.Finder:AddDivider()
Tabs.Finder:AddSection("Trang thai & Dieu khien", "Lucide:activity")

statusParagraph = Tabs.Finder:AddParagraph({
	Title = "Trang thai",
	Icon = "Lucide:info",
	Text = "Dang kiem tra so nguoi trong server hien tai...",
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
		updateStatusText("Dang quet", string.format("Chua co server %d-%d nguoi. Dang tiep tuc quet sau...", minPlayersLimit, maxPlayersLimit))
		task.delay(1.0, function()
			if autoHopEnabled and not isScanning then
				startAutoScan()
			end
		end)
		return
	end

	env.HopVisitedServers[target.id] = true
	autoHopInProgress = true
	updateStatusText("Dich chuyen", string.format("Dang vao server %d nguoi (ID: %s)", target.playing, target.id))
	VindUI:Notify({ Title = "Auto Hop", Text = string.format("Dang vao server %d nguoi...", target.playing), Type = "success", Duration = 3 })

	local ok, err = pcall(function()
		TeleportService:TeleportToPlaceInstance(placeId, target.id, LocalPlayer)
	end)

	if not ok then
		autoHopInProgress = false
		updateStatusText("Loi vao server", tostring(err) .. "; chuyen server khac...")
		task.delay(0.5, function()
			if autoHopEnabled then
				attemptAutoHop()
			end
		end)
	else
		task.delay(10, function()
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
	updateStatusText("Dang quet", "Bat dau quet may chu cong khai...")

	task.spawn(function()
		local cursor = nil
		local seenIds = {}
		local foundIdealTarget = false

		for page = 1, 60 do
			if thisGen ~= scanGeneration then
				return
			end

			updateStatusText("Dang quet", string.format("Trang %d | Tim thay %d server", page, #allDiscoveredServers))
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
							foundIdealTarget = true
						end
					end
				end
			end

			if autoHopEnabled and foundIdealTarget and not autoHopInProgress then
				task.spawn(attemptAutoHop)
				break
			end

			cursor = payload.nextPageCursor
			if not cursor or cursor == "" then
				break
			end
			task.wait(requestDelay)
		end

		if thisGen ~= scanGeneration then
			return
		end

		isScanning = false
		updateStatusText("Hoan tat", string.format("Da quet xong. Tong cong: %d server.", #allDiscoveredServers))

		if autoHopEnabled and not autoHopInProgress then
			task.delay(0.1, attemptAutoHop)
		end
	end)
end

Tabs.Finder:AddButton({
	Text = "Quet lai ngay",
	Description = "Lam moi danh sach va quet may chu moi",
	Icon = "Lucide:refresh-cw",
	Callback = function()
		startAutoScan()
	end,
})

Tabs.Finder:AddButton({
	Text = "Vao server it nguoi nhat",
	Description = "Dich chuyen den server it nguoi nhat da tim thay",
	Icon = "Lucide:log-in",
	Callback = function()
		attemptAutoHop()
	end,
})

Tabs.Finder:AddButton({
	Text = "Dung quet",
	Description = "Dung tien trinh quet may chu",
	Icon = "Lucide:circle-stop",
	Callback = function()
		scanGeneration = scanGeneration + 1
		isScanning = false
		autoHopInProgress = false
		updateStatusText("Da dung", "Da dung qua trinh quet may chu.")
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
	Title = "Co che Auto Hop chuan 1-2 nguoi",
	Icon = "Lucide:info",
	Text = "He thong luu danh sach server da ghe qua de khong vao lai server cu. Khi vao server ma so nguoi vuot qua muc toi da, script se tu dong hop tiep ngay lap tuc.",
})

pcall(function()
	TeleportService.TeleportInitFailed:Connect(function(player, result, errorMessage)
		if player == LocalPlayer then
			autoHopInProgress = false
			updateStatusText("Dich chuyen that bai", tostring(result) .. " - " .. tostring(errorMessage))
			if autoHopEnabled then
				task.delay(1, attemptAutoHop)
			end
		end
	end)
end)

Window:SelectTab("Server Finder")
Window:Open()

VindUI:Notify({
	Title = "Low Server Finder",
	Text = "Giao dien Vind UI da san sang!",
	Type = "success",
	Duration = 3,
})

task.spawn(function()
	task.wait(2.5)
	local currentCount = #Players:GetPlayers()
	if currentCount > maxPlayersLimit then
		updateStatusText("Server dong (" .. tostring(currentCount) .. " nguoi)", "So nguoi vuot qua gioi han (" .. tostring(maxPlayersLimit) .. "). Dang tu dong tim server 1-2 nguoi...")
		VindUI:Notify({
			Title = "Auto Re-Hop",
			Text = string.format("Server hien tai co %d nguoi. Dang tu dong hop tiep...", currentCount),
			Type = "warning",
			Duration = 4,
		})
		startAutoScan()
	else
		updateStatusText("Server ly tuong (" .. tostring(currentCount) .. " nguoi)", "Server hien tai dat yeu cau (<= " .. tostring(maxPlayersLimit) .. " nguoi).")
		VindUI:Notify({
			Title = "Dat yeu cau",
			Text = string.format("Server hien tai chi co %d nguoi!", currentCount),
			Type = "success",
			Duration = 4,
		})
	end
end)
