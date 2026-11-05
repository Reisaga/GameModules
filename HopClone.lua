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
local autoHopEnabled = true
local autoHopInProgress = false
local attemptedServers = {}
local minPlayersLimit = 1
local maxPlayersLimit = 2
local requestDelay = 0.25
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

local Lumen = loadstring(game:HttpGet("https://raw.githubusercontent.com/chromatiks/Lumen/main/Library.lua"))()

Lumen.SetConfigFolder("LowServerFinder")
Lumen:LoadingScreen({ Title = "Low Server Finder"; Subtitle = gameName; Duration = 1.0 })
Lumen.SetWatermark("Low Server Finder", true)
Lumen.SetKeybindList(true)

local Window = Lumen:Window({
	Title = "Low Server Finder";
	Footer = gameName;
})

local FinderPage = Window:Page({ Icon = "server" })
local ConfigSection = FinderPage:Section({ Name = "Cau hinh Auto Hop"; Side = "Left"; Icon = "sliders" })
local ActionSection = FinderPage:Section({ Name = "Trang thai & Dieu khien"; Side = "Right"; Icon = "activity" })

local updateStatusText = function(title, body)
	if statusParagraph and statusParagraph.SetBody then
		statusParagraph:SetTitle(title)
		statusParagraph:SetBody(body)
	end
end

statusParagraph = ActionSection:Paragraph({
	Title = "Trang thai";
	Body = "Dang khoi tao...";
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
		if mx > pl and pl >= minPlayersLimit and pl <= maxPlayersLimit and not attemptedServers[s.id] then
			table.insert(candidates, s)
		end
	end

	table.sort(candidates, function(a, b)
		return a.playing < b.playing
	end)

	local target = candidates[1]
	if not target then
		updateStatusText("Dang quet", string.format("Chua tim thay server %d-%d nguoi. Dang tiep tuc quet...", minPlayersLimit, maxPlayersLimit))
		task.delay(1.5, function()
			if autoHopEnabled and not isScanning then
				startAutoScan()
			end
		end)
		return
	end

	attemptedServers[target.id] = true
	autoHopInProgress = true
	updateStatusText("Dich chuyen", string.format("Dang vao server %d nguoi (ID: %s)", target.playing, target.id))
	Lumen.Notify({ Title = "Auto Hop"; Text = string.format("Dang vao server %d nguoi...", target.playing); Type = "Success"; Duration = 3 })

	local ok, err = pcall(function()
		TeleportService:TeleportToPlaceInstance(placeId, target.id, LocalPlayer)
	end)

	if not ok then
		autoHopInProgress = false
		updateStatusText("Loi vao server", tostring(err) .. "; dang thu server khac...")
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
		task.wait(attempt * 0.5)
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
		local foundTarget = false

		for page = 1, 50 do
			if thisGen ~= scanGeneration then
				return
			end

			updateStatusText("Dang quet", string.format("Trang %d | Da tim duoc %d server", page, #allDiscoveredServers))
			local payload = fetchServers(cursor)
			if not payload then
				break
			end

			for _, s in ipairs(payload.data) do
				if type(s) == "table" and type(s.id) == "string" and s.id ~= "" then
					local playing = tonumber(s.playing)
					local maxPlayers = tonumber(s.maxPlayers)
					local isCurrent = (currentJobId ~= "" and s.id == currentJobId)

					if playing and maxPlayers and not isCurrent and not seenIds[s.id] then
						seenIds[s.id] = true
						table.insert(allDiscoveredServers, {
							id = s.id,
							playing = playing,
							maxPlayers = maxPlayers,
						})

						if playing >= minPlayersLimit and playing <= maxPlayersLimit and not attemptedServers[s.id] then
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

local AutoHopToggle = ConfigSection:Label({ Text = "Auto Hop (Tu dong vao)" })
AutoHopToggle:Toggle({
	State = true;
	Flag = "AutoHopEnabled";
	Callback = function(state)
		autoHopEnabled = state
		if autoHopEnabled then
			updateStatusText("Auto Hop", string.format("Bat: Tim server tu %d den %d nguoi...", minPlayersLimit, maxPlayersLimit))
			attemptedServers = {}
			startAutoScan()
		else
			autoHopInProgress = false
			updateStatusText("Auto Hop", "Da tat Auto Hop.")
		end
	end;
})

ConfigSection:Slider({
	Name = "Nguoi choi toi thieu";
	Suffix = " nguoi";
	Value = 1;
	Min = 0;
	Max = 10;
	Increment = 1;
	Flag = "MinPlayers";
	Callback = function(val)
		minPlayersLimit = math.floor(tonumber(val) or 1)
	end;
})

ConfigSection:Slider({
	Name = "Nguoi choi toi da";
	Suffix = " nguoi";
	Value = 2;
	Min = 1;
	Max = 15;
	Increment = 1;
	Flag = "MaxPlayers";
	Callback = function(val)
		maxPlayersLimit = math.floor(tonumber(val) or 2)
	end;
})

ConfigSection:Slider({
	Name = "Do tre moi trang (Delay)";
	Suffix = "s";
	Value = 0.25;
	Min = 0.15;
	Max = 1.0;
	Increment = 0.05;
	Flag = "RequestDelay";
	Callback = function(val)
		requestDelay = tonumber(val) or 0.25
	end;
})

ActionSection:Button({
	Name = "Quet lai ngay";
	Callback = function()
		attemptedServers = {}
		startAutoScan()
	end;
})

ActionSection:Button({
	Name = "Vao server it nguoi nhat";
	Callback = function()
		attemptAutoHop()
	end;
})

ActionSection:Button({
	Name = "Dung quet";
	Callback = function()
		scanGeneration = scanGeneration + 1
		isScanning = false
		autoHopInProgress = false
		updateStatusText("Da dung", "Da dung qua trinh quet may chu.")
	end;
})

local Settings = Window:Page({ Icon = "settings" })
local AboutSection = Settings:Section({ Name = "Thong tin"; Side = "Left"; Icon = "info" })
AboutSection:Paragraph({
	Title = "Low Server Finder";
	Body = "Script tu dong quet danh sach may chu Roblox cong khai va ho tro Auto Hop vao server it nguoi nhat (1-2 nguoi) voi giao dien Lumen.";
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

Lumen:BuildConfigPage(Window)
Lumen.Notify({ Title = "Low Server Finder"; Text = "Giao dien da san sang!"; Type = "Success"; Duration = 3 })

startAutoScan()
