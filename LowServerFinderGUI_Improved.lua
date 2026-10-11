-- Low Server Finder GUI - ban cai tien
-- Chuc nang: quet may chu cong khai, loc theo so nguoi choi, tim ID, sap xep,
-- lam moi danh sach, xu ly loi HTTP va gioi han so trang de tranh gui qua nhieu request.

local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    error("Low Server Finder can phai chay o client.")
end

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Cau hinh quet. 30 trang tuong duong toi da 3.000 muc du lieu neu API tra du.
local MAX_PAGES = 30
local MAX_RETRIES = 4
local REQUEST_DELAY = 0.35
local MAX_VISIBLE_SERVERS = 250
local DEFAULT_PLAYER_LIMIT = 8

-- Tuong thich voi mot so moi truong chay Lua co ho tro HTTP request.
local requestFunc
if syn and syn.request then
    requestFunc = syn.request
elseif http and http.request then
    requestFunc = http.request
elseif http_request then
    requestFunc = http_request
elseif fluxus and fluxus.request then
    requestFunc = fluxus.request
elseif request then
    requestFunc = request
end

if type(requestFunc) ~= "function" then
    error("Khong tim thay ham HTTP request duoc ho tro trong moi truong hien tai.")
end

-- Xoa giao dien cu neu script duoc chay lai.
local oldGui = PlayerGui:FindFirstChild("LowServerFinder")
if oldGui then
    oldGui:Destroy()
end

local gameName = "Roblox Experience"
pcall(function()
    local info = MarketplaceService:GetProductInfo(game.PlaceId)
    if info and info.Name then
        gameName = info.Name
    end
end)

local function createInstance(className, properties, parent)
    local object = Instance.new(className)
    for property, value in pairs(properties or {}) do
        object[property] = value
    end
    object.Parent = parent
    return object
end

local function addCorner(parent, radius)
    return createInstance("UICorner", {
        CornerRadius = UDim.new(0, radius or 8),
    }, parent)
end

local function addStroke(parent, color, thickness, transparency)
    return createInstance("UIStroke", {
        Color = color or Color3.fromRGB(70, 82, 105),
        Thickness = thickness or 1,
        Transparency = transparency or 0,
    }, parent)
end

local function trim(text)
    return (tostring(text or ""):gsub("^%s*(.-)%s*$", "%1"))
end

local function safeLower(text)
    return string.lower(tostring(text or ""))
end

-- Tao giao dien chinh.
local ScreenGui = createInstance("ScreenGui", {
    Name = "LowServerFinder",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 50,
}, PlayerGui)

local MainFrame = createInstance("Frame", {
    Name = "MainFrame",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.new(0.78, 0, 0.76, 0),
    BackgroundColor3 = Color3.fromRGB(17, 24, 39),
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, ScreenGui)
addCorner(MainFrame, 14)
addStroke(MainFrame, Color3.fromRGB(74, 105, 160), 1.5, 0)
createInstance("UISizeConstraint", {
    MinSize = Vector2.new(350, 320),
    MaxSize = Vector2.new(900, 650),
}, MainFrame)

createInstance("UIGradient", {
    Rotation = 115,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 39, 61)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 18, 30)),
    }),
}, MainFrame)

local TitleBar = createInstance("Frame", {
    Name = "TitleBar",
    Position = UDim2.new(0, 0, 0, 0),
    Size = UDim2.new(1, 0, 0, 46),
    BackgroundColor3 = Color3.fromRGB(25, 36, 56),
    BackgroundTransparency = 0.08,
    BorderSizePixel = 0,
}, MainFrame)

local Title = createInstance("TextLabel", {
    Name = "Title",
    Position = UDim2.new(0, 15, 0, 0),
    Size = UDim2.new(1, -140, 1, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "LOW SERVER FINDER  /  " .. gameName,
    TextColor3 = Color3.fromRGB(238, 244, 255),
    TextSize = 15,
    TextTruncate = Enum.TextTruncate.AtEnd,
    TextXAlignment = Enum.TextXAlignment.Left,
}, TitleBar)

local CloseButton = createInstance("TextButton", {
    Name = "CloseButton",
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -9, 0.5, 0),
    Size = UDim2.fromOffset(34, 30),
    BackgroundColor3 = Color3.fromRGB(190, 55, 65),
    BorderSizePixel = 0,
    Font = Enum.Font.GothamBold,
    Text = "X",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 14,
    AutoButtonColor = true,
}, TitleBar)
addCorner(CloseButton, 7)

local HideButton = createInstance("TextButton", {
    Name = "HideButton",
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -50, 0.5, 0),
    Size = UDim2.fromOffset(34, 30),
    BackgroundColor3 = Color3.fromRGB(58, 75, 105),
    BorderSizePixel = 0,
    Font = Enum.Font.GothamBold,
    Text = "—",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 16,
    AutoButtonColor = true,
}, TitleBar)
addCorner(HideButton, 7)

-- Cac dieu khien loc va sap xep.
local SearchBox = createInstance("TextBox", {
    Name = "SearchBox",
    Position = UDim2.new(0, 12, 0, 54),
    Size = UDim2.new(0.42, -7, 0, 34),
    BackgroundColor3 = Color3.fromRGB(29, 41, 62),
    BorderSizePixel = 0,
    ClearTextOnFocus = false,
    Font = Enum.Font.Gotham,
    PlaceholderText = "Tim theo Server ID...",
    PlaceholderColor3 = Color3.fromRGB(145, 158, 180),
    Text = "",
    TextColor3 = Color3.fromRGB(240, 245, 255),
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
}, MainFrame)
addCorner(SearchBox, 7)
addStroke(SearchBox, Color3.fromRGB(59, 76, 106), 1, 0)
createInstance("UIPadding", {
    PaddingLeft = UDim.new(0, 10),
    PaddingRight = UDim.new(0, 8),
}, SearchBox)

local PlayerLimitBox = createInstance("TextBox", {
    Name = "PlayerLimitBox",
    Position = UDim2.new(0.44, 0, 0, 54),
    Size = UDim2.new(0.14, -4, 0, 34),
    BackgroundColor3 = Color3.fromRGB(29, 41, 62),
    BorderSizePixel = 0,
    ClearTextOnFocus = false,
    Font = Enum.Font.Gotham,
    PlaceholderText = "So nguoi",
    Text = tostring(DEFAULT_PLAYER_LIMIT),
    TextColor3 = Color3.fromRGB(240, 245, 255),
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Center,
}, MainFrame)
addCorner(PlayerLimitBox, 7)
addStroke(PlayerLimitBox, Color3.fromRGB(59, 76, 106), 1, 0)

local SortButton = createInstance("TextButton", {
    Name = "SortButton",
    Position = UDim2.new(0.60, 0, 0, 54),
    Size = UDim2.new(0.20, -5, 0, 34),
    BackgroundColor3 = Color3.fromRGB(54, 91, 150),
    BorderSizePixel = 0,
    Font = Enum.Font.GothamSemibold,
    Text = "It nguoi truoc",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 12,
    AutoButtonColor = true,
}, MainFrame)
addCorner(SortButton, 7)

local RefreshButton = createInstance("TextButton", {
    Name = "RefreshButton",
    Position = UDim2.new(0.81, 0, 0, 54),
    Size = UDim2.new(0.17, -4, 0, 34),
    BackgroundColor3 = Color3.fromRGB(32, 146, 104),
    BorderSizePixel = 0,
    Font = Enum.Font.GothamBold,
    Text = "QUET LAI",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 12,
    AutoButtonColor = true,
}, MainFrame)
addCorner(RefreshButton, 7)

local AutoHopButton = createInstance("TextButton", {
    Name = "AutoHopButton",
    Position = UDim2.new(0, 12, 0, 94),
    Size = UDim2.new(0, 150, 0, 29),
    BackgroundColor3 = Color3.fromRGB(75, 79, 91),
    BorderSizePixel = 0,
    Font = Enum.Font.GothamBold,
    Text = "AUTO HOP: OFF",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 12,
    AutoButtonColor = true,
}, MainFrame)
addCorner(AutoHopButton, 7)

local StatusLabel = createInstance("TextLabel", {
    Name = "StatusLabel",
    Position = UDim2.new(0, 172, 0, 94),
    Size = UDim2.new(1, -184, 0, 29),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = "San sang quet may chu cong khai.",
    TextColor3 = Color3.fromRGB(163, 180, 207),
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
}, MainFrame)

local ServerListFrame = createInstance("ScrollingFrame", {
    Name = "ServerListFrame",
    Position = UDim2.new(0, 10, 0, 132),
    Size = UDim2.new(1, -20, 1, -144),
    BackgroundColor3 = Color3.fromRGB(12, 18, 30),
    BorderSizePixel = 0,
    Active = true,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness = 5,
    ScrollBarImageColor3 = Color3.fromRGB(93, 122, 168),
}, MainFrame)
addCorner(ServerListFrame, 9)
createInstance("UIPadding", {
    PaddingTop = UDim.new(0, 7),
    PaddingBottom = UDim.new(0, 7),
    PaddingLeft = UDim.new(0, 6),
    PaddingRight = UDim.new(0, 6),
}, ServerListFrame)
createInstance("UIListLayout", {
    Name = "EntryLayout",
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 6),
}, ServerListFrame)

-- Nut thu gon luon nam ben ngoai cua so chinh.
local ToggleButton = createInstance("TextButton", {
    Name = "ToggleButton",
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(0, 8, 0.5, 0),
    Size = UDim2.fromOffset(56, 34),
    BackgroundColor3 = Color3.fromRGB(36, 116, 91),
    BorderSizePixel = 0,
    Font = Enum.Font.GothamBold,
    Text = "AN",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 12,
    AutoButtonColor = true,
}, ScreenGui)
addCorner(ToggleButton, 8)

local isHidden = false
local isScanning = false
local autoHopEnabled = false
local autoHopInProgress = false
local autoHopAttempted = {}
local sortAscending = true
local scanGeneration = 0
local pagesScanned = 0
local allServers = {}
local lastStatus = "San sang"

local function currentPlayerLimit()
    local value = tonumber(trim(PlayerLimitBox.Text))
    if not value then
        value = DEFAULT_PLAYER_LIMIT
    end
    value = math.clamp(math.floor(value), 0, 100)
    return value
end

local function updateStatus(message)
    lastStatus = tostring(message or "San sang")
    StatusLabel.Text = string.format(
        "%s  |  Da nap: %d  |  Trang: %d  |  Gioi han hien thi: %d",
        lastStatus,
        #allServers,
        pagesScanned,
        MAX_VISIBLE_SERVERS
    )
end

local function clearServerEntries()
    for _, child in ipairs(ServerListFrame:GetChildren()) do
        if child:GetAttribute("LowServerFinderEntry") or child.Name == "EmptyState" then
            child:Destroy()
        end
    end
end

local function createEmptyState(message)
    local empty = createInstance("TextLabel", {
        Name = "EmptyState",
        LayoutOrder = 100000,
        Size = UDim2.new(1, -4, 0, 74),
        BackgroundColor3 = Color3.fromRGB(20, 29, 46),
        BorderSizePixel = 0,
        Font = Enum.Font.Gotham,
        Text = message,
        TextColor3 = Color3.fromRGB(159, 175, 201),
        TextSize = 13,
        TextWrapped = true,
    }, ServerListFrame)
    addCorner(empty, 8)
end

local function createServerEntry(serverData, order)
    local entry = createInstance("Frame", {
        Name = "ServerEntry_" .. tostring(order),
        LayoutOrder = order,
        Size = UDim2.new(1, -4, 0, 56),
        BackgroundColor3 = order % 2 == 0 and Color3.fromRGB(24, 35, 54) or Color3.fromRGB(21, 31, 48),
        BorderSizePixel = 0,
    }, ServerListFrame)
    entry:SetAttribute("LowServerFinderEntry", true)
    addCorner(entry, 8)

    local playersNow = tonumber(serverData.playing) or 0
    local maxPlayers = tonumber(serverData.maxPlayers) or 0
    local freeSlots = math.max(0, maxPlayers - playersNow)
    local ratio = maxPlayers > 0 and (playersNow / maxPlayers) or 0
    local statusColor = ratio >= 0.9 and Color3.fromRGB(244, 114, 114)
        or (ratio >= 0.65 and Color3.fromRGB(250, 204, 120) or Color3.fromRGB(110, 231, 183))

    local info = createInstance("TextLabel", {
        Name = "ServerInfo",
        Position = UDim2.new(0, 10, 0, 4),
        Size = UDim2.new(1, -125, 1, -8),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = string.format("Nguoi choi: %d / %d   |   Trong: %d\nID: %s", playersNow, maxPlayers, freeSlots, tostring(serverData.id)),
        TextColor3 = Color3.fromRGB(231, 238, 250),
        TextSize = 12,
        TextWrapped = true,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
    }, entry)

    local occupancy = createInstance("Frame", {
        Name = "OccupancyTrack",
        Position = UDim2.new(0, 10, 1, -5),
        Size = UDim2.new(1, -130, 0, 2),
        BackgroundColor3 = Color3.fromRGB(55, 67, 88),
        BorderSizePixel = 0,
    }, entry)
    local fill = createInstance("Frame", {
        Name = "OccupancyFill",
        Size = UDim2.new(math.clamp(ratio, 0, 1), 0, 1, 0),
        BackgroundColor3 = statusColor,
        BorderSizePixel = 0,
    }, occupancy)
    addCorner(fill, 2)

    local joinButton = createInstance("TextButton", {
        Name = "JoinButton",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -7, 0.5, 0),
        Size = UDim2.fromOffset(99, 36),
        BackgroundColor3 = Color3.fromRGB(55, 111, 190),
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        Text = "THAM GIA",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 11,
        AutoButtonColor = true,
    }, entry)
    addCorner(joinButton, 7)

    local joining = false
    joinButton.Activated:Connect(function()
        if joining then
            return
        end
        joining = true
        joinButton.Text = "DANG VAO"
        joinButton.Active = false
        updateStatus("Dang gui yeu cau vao may chu...")

        local ok, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, serverData.id, LocalPlayer)
        end)

        if not ok then
            joining = false
            if joinButton.Parent then
                joinButton.Text = "THU LAI"
                joinButton.Active = true
            end
            updateStatus("Khong the vao may chu: " .. tostring(err))
        else
            updateStatus("Da gui yeu cau dich chuyen. Dang cho Roblox xu ly...")
            task.delay(6, function()
                if joinButton.Parent and ScreenGui.Parent then
                    joining = false
                    joinButton.Text = "THAM GIA"
                    joinButton.Active = true
                end
            end)
        end
    end)
end

local function renderServers()
    if not ScreenGui.Parent then
        return
    end

    clearServerEntries()

    local query = safeLower(trim(SearchBox.Text))
    local playerLimit = currentPlayerLimit()
    local filtered = {}

    for _, server in ipairs(allServers) do
        local playersNow = tonumber(server.playing) or 0
        local maxPlayers = tonumber(server.maxPlayers) or 0
        local idText = safeLower(server.id)
        local isOpen = playersNow < maxPlayers
        local underLimit = playersNow <= playerLimit
        local matchesSearch = query == "" or string.find(idText, query, 1, true) ~= nil
            or string.find(tostring(playersNow), query, 1, true) ~= nil

        if isOpen and underLimit and matchesSearch then
            table.insert(filtered, server)
        end
    end

    table.sort(filtered, function(a, b)
        local aPlayers = tonumber(a.playing) or 0
        local bPlayers = tonumber(b.playing) or 0
        if aPlayers == bPlayers then
            return tostring(a.id) < tostring(b.id)
        end
        if sortAscending then
            return aPlayers < bPlayers
        end
        return aPlayers > bPlayers
    end)

    local visibleCount = math.min(#filtered, MAX_VISIBLE_SERVERS)
    if visibleCount == 0 then
        if isScanning then
            createEmptyState("Dang tai danh sach may chu cong khai...")
        elseif #allServers == 0 then
            createEmptyState("Chua co du lieu. Nhan QUET LAI de thu lai.")
        else
            createEmptyState("Khong co may chu phu hop. Tang gioi han nguoi choi hoac xoa tu khoa tim kiem.")
        end
    else
        for index = 1, visibleCount do
            createServerEntry(filtered[index], index)
        end
        if #filtered > visibleCount then
            createEmptyState(string.format("Dang hien thi %d / %d may chu phu hop. Cac ket qua it nguoi choi hon duoc uu tien.", visibleCount, #filtered))
        end
    end

    SortButton.Text = sortAscending and "It nguoi truoc" or "Nhieu nguoi truoc"
end

local function setAutoHopEnabled(enabled)
    autoHopEnabled = enabled
    AutoHopButton.Text = enabled and "AUTO HOP: ON" or "AUTO HOP: OFF"
    AutoHopButton.BackgroundColor3 = enabled and Color3.fromRGB(32, 146, 104) or Color3.fromRGB(75, 79, 91)
    if enabled then
        updateStatus("Auto hop bat: uu tien " .. (sortAscending and "may chu it nguoi" or "may chu nhieu nguoi"))
    else
        autoHopInProgress = false
        updateStatus("Auto hop da tat")
    end
end

local startScan

local function attemptAutoHop()
    if not autoHopEnabled or autoHopInProgress or not ScreenGui.Parent then
        return
    end

    local candidates = {}
    local playerLimit = currentPlayerLimit()
    for _, server in ipairs(allServers) do
        local playing = tonumber(server.playing) or 0
        local maximum = tonumber(server.maxPlayers) or 0
        if maximum > playing and not autoHopAttempted[server.id]
            and (not sortAscending or playing <= playerLimit) then
            table.insert(candidates, server)
        end
    end

    table.sort(candidates, function(a, b)
        local ap, bp = tonumber(a.playing) or 0, tonumber(b.playing) or 0
        if ap == bp then return tostring(a.id) < tostring(b.id) end
        return sortAscending and ap < bp or (not sortAscending and ap > bp)
    end)

    local target = candidates[1]
    if not target then
        updateStatus("Auto hop: khong co may chu phu hop; dang quet lai sau 3 giay")
        task.delay(3, function()
            if autoHopEnabled and ScreenGui.Parent and not isScanning then
                startScan()
            end
        end)
        return
    end

    autoHopAttempted[target.id] = true
    autoHopInProgress = true
    updateStatus(string.format("Auto hop: dang vao may chu %d nguoi, ID %s", target.playing, target.id))
    local ok, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, target.id, LocalPlayer)
    end)
    if not ok then
        autoHopInProgress = false
        updateStatus("Auto hop loi: " .. tostring(err) .. "; dang thu may chu tiep theo")
        task.delay(1, function()
            if autoHopEnabled and ScreenGui.Parent then attemptAutoHop() end
        end)
    else
        task.delay(8, function()
            if autoHopEnabled and ScreenGui.Parent then
                autoHopInProgress = false
                attemptAutoHop()
            end
        end)
    end
end

-- Goi API co thu lai khi bi gioi han hoac loi may chu.
local function fetchServers(cursor)
    local url = string.format(
        "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100",
        game.PlaceId
    )
    if cursor and cursor ~= "" then
        url = url .. "&cursor=" .. HttpService:UrlEncode(cursor)
    end

    local lastError = "Khong ro loi HTTP"
    for attempt = 1, MAX_RETRIES do
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
            local statusAllowsDecode = statusCode == nil or statusCode == 200

            if body and statusAllowsDecode and response.Success ~= false then
                local decodedOk, payload = pcall(function()
                    return HttpService:JSONDecode(body)
                end)
                if decodedOk and type(payload) == "table" and type(payload.data) == "table" then
                    return payload
                end
                lastError = decodedOk and "Phan hoi API khong co danh sach data hop le" or ("JSON khong hop le: " .. tostring(payload))
            else
                lastError = string.format("HTTP %s: %s", tostring(statusCode or "?"), tostring(body or "khong co noi dung"))
                local retryable = statusCode == nil or statusCode == 408 or statusCode == 429 or (statusCode and statusCode >= 500)
                if not retryable then
                    return nil, lastError
                end
            end
        else
            lastError = ok and "API tra ve phan hoi khong hop le" or tostring(response)
        end

        if attempt < MAX_RETRIES then
            task.wait(math.min(attempt * 1.25, 5))
        end
    end

    return nil, lastError
end

startScan = function()
    if isScanning then
        updateStatus("Dang quet, vui long doi...")
        return
    end

    isScanning = true
    scanGeneration += 1
    local thisGeneration = scanGeneration
    pagesScanned = 0
    allServers = {}
    RefreshButton.Text = "DANG QUET"
    RefreshButton.Active = false
    RefreshButton.AutoButtonColor = false
    updateStatus("Bat dau quet may chu cong khai...")
    renderServers()

    task.spawn(function()
        local cursor = nil
        local seenIds = {}
        local scanError = nil
        local reachedEnd = false
        local seenCursors = {}

        for pageNumber = 1, MAX_PAGES do
            if thisGeneration ~= scanGeneration or not ScreenGui.Parent then
                return
            end

            updateStatus(string.format("Dang quet trang %d / %d...", pageNumber, MAX_PAGES))
            local payload, fetchError = fetchServers(cursor)
            if not payload then
                scanError = fetchError or "Khong lay duoc du lieu tu API"
                break
            end

            pagesScanned += 1
            for _, server in ipairs(payload.data) do
                if type(server) == "table" and type(server.id) == "string" and server.id ~= "" then
                    local playing = tonumber(server.playing)
                    local maxPlayers = tonumber(server.maxPlayers)
                    local isCurrentServer = game.JobId ~= "" and server.id == game.JobId

                    if playing and maxPlayers and not isCurrentServer and not seenIds[server.id] then
                        seenIds[server.id] = true
                        table.insert(allServers, {
                            id = server.id,
                            playing = playing,
                            maxPlayers = maxPlayers,
                        })
                    end
                end
            end

            cursor = payload.nextPageCursor

            -- Hien ket qua tim duoc ngay, khong doi quet het moi hien danh sach.
            renderServers()

            if not cursor or cursor == "" then
                reachedEnd = true
                break
            end

            -- Bao ve khi API tra ve cursor lap, tranh quet vong lap vo han.
            if seenCursors[cursor] then
                scanError = "API tra ve cursor lap; da dung quet de tranh lap vo han"
                break
            end
            seenCursors[cursor] = true
            task.wait(REQUEST_DELAY)
        end

        if thisGeneration ~= scanGeneration or not ScreenGui.Parent then
            return
        end

        isScanning = false
        RefreshButton.Text = "QUET LAI"
        RefreshButton.Active = true
        RefreshButton.AutoButtonColor = true

        if scanError then
            updateStatus("Quet chua day du: " .. scanError)
        elseif reachedEnd then
            updateStatus("Quet xong danh sach cong khai")
        elseif pagesScanned >= MAX_PAGES and cursor then
            updateStatus(string.format("Da quet %d trang (%d may chu); co the quet lai de cap nhat", pagesScanned, #allServers))
        else
            updateStatus("Quet xong")
        end

        renderServers()
        if autoHopEnabled then
            task.delay(0.35, attemptAutoHop)
        end
    end)
end

-- Tim kiem cap nhat truc tiep, loc so nguoi cap nhat khi roi khoi o nhap.
SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    renderServers()
end)

PlayerLimitBox.FocusLost:Connect(function()
    PlayerLimitBox.Text = tostring(currentPlayerLimit())
    renderServers()
end)

SortButton.Activated:Connect(function()
    sortAscending = not sortAscending
    autoHopAttempted = {}
    renderServers()
    if autoHopEnabled and not isScanning then task.delay(0.2, attemptAutoHop) end
end)

RefreshButton.Activated:Connect(startScan)

AutoHopButton.Activated:Connect(function()
    setAutoHopEnabled(not autoHopEnabled)
    if autoHopEnabled and not isScanning then
        autoHopAttempted = {}
        startScan()
    end
end)

HideButton.Activated:Connect(function()
    isHidden = true
    MainFrame.Visible = false
    ToggleButton.Text = "MO"
end)

ToggleButton.Activated:Connect(function()
    isHidden = not isHidden
    MainFrame.Visible = not isHidden
    ToggleButton.Text = isHidden and "MO" or "AN"
end)

CloseButton.Activated:Connect(function()
    scanGeneration += 1
    ScreenGui:Destroy()
end)

-- Keo cua so bang thanh tieu de; giu nguyen toa do scale ban dau.
do
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPosition = nil

    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    TitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput and dragStart and startPosition and MainFrame.Parent then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)
end

-- Cap nhat trang thai neu Roblox tu choi yeu cau dich chuyen.
pcall(function()
    TeleportService.TeleportInitFailed:Connect(function(player, result, errorMessage)
        if player == LocalPlayer and ScreenGui.Parent then
            updateStatus("Dich chuyen that bai: " .. tostring(result) .. " - " .. tostring(errorMessage))
            if autoHopEnabled then
                autoHopInProgress = false
                task.delay(1, attemptAutoHop)
            end
        end
    end)
end)

-- Bat dau quet tu dong khi giao dien duoc tao.
startScan()
