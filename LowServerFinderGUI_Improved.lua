local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    return
end

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local requestFunc = (syn and syn.request)
    or (http and http.request)
    or http_request
    or (fluxus and fluxus.request)
    or request

if type(requestFunc) ~= "function" then
    return
end

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
    Text = "LOW SERVER FINDER AUTO  /  " .. gameName,
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

local SearchBox = createInstance("TextBox", {
    Name = "SearchBox",
    Position = UDim2.new(0, 12, 0, 54),
    Size = UDim2.new(0.46, -7, 0, 34),
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

local SortButton = createInstance("TextButton", {
    Name = "SortButton",
    Position = UDim2.new(0.48, 0, 0, 54),
    Size = UDim2.new(0.25, -5, 0, 34),
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
    Position = UDim2.new(0.74, 0, 0, 54),
    Size = UDim2.new(0.25, -4, 0, 34),
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
    Size = UDim2.new(0, 160, 0, 29),
    BackgroundColor3 = Color3.fromRGB(32, 146, 104),
    BorderSizePixel = 0,
    Font = Enum.Font.GothamBold,
    Text = "AUTO HOP: ON (1-2)",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 12,
    AutoButtonColor = true,
}, MainFrame)
addCorner(AutoHopButton, 7)

local StatusLabel = createInstance("TextLabel", {
    Name = "StatusLabel",
    Position = UDim2.new(0, 180, 0, 94),
    Size = UDim2.new(1, -192, 0, 29),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = "Dang tu dong quet va hop may chu 1-2 nguoi...",
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
local autoHopEnabled = true
local autoHopInProgress = false
local autoHopAttempted = {}
local sortAscending = true
local scanGeneration = 0
local pagesScanned = 0
local allServers = {}
local entryPool = {}
local emptyStateLabel = nil
local searchDebounceTimer = nil

local function updateStatus(message)
    StatusLabel.Text = string.format("%s  |  Da nap: %d  |  Trang: %d", tostring(message or "San sang"), #allServers, pagesScanned)
end

local function getOrCreateEmptyState()
    if not emptyStateLabel then
        emptyStateLabel = createInstance("TextLabel", {
            Name = "EmptyState",
            LayoutOrder = 1000000,
            Size = UDim2.new(1, -4, 0, 74),
            BackgroundColor3 = Color3.fromRGB(20, 29, 46),
            BorderSizePixel = 0,
            Font = Enum.Font.Gotham,
            Text = "",
            TextColor3 = Color3.fromRGB(159, 175, 201),
            TextSize = 13,
            TextWrapped = true,
            Visible = false,
        }, ServerListFrame)
        addCorner(emptyStateLabel, 8)
    end
    return emptyStateLabel
end

local function createEntryTemplate(order)
    local entry = createInstance("Frame", {
        Name = "ServerEntry_" .. tostring(order),
        LayoutOrder = order,
        Size = UDim2.new(1, -4, 0, 56),
        BackgroundColor3 = order % 2 == 0 and Color3.fromRGB(24, 35, 54) or Color3.fromRGB(21, 31, 48),
        BorderSizePixel = 0,
        Visible = false,
    }, ServerListFrame)
    addCorner(entry, 8)

    local info = createInstance("TextLabel", {
        Name = "ServerInfo",
        Position = UDim2.new(0, 10, 0, 4),
        Size = UDim2.new(1, -125, 1, -8),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = "",
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
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(110, 231, 183),
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

    local currentServer = nil
    local isJoining = false

    joinButton.Activated:Connect(function()
        if isJoining or not currentServer then
            return
        end
        isJoining = true
        joinButton.Text = "DANG VAO"
        joinButton.Active = false
        updateStatus("Dang gui yeu cau vao may chu...")

        local ok, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, currentServer.id, LocalPlayer)
        end)

        if not ok then
            isJoining = false
            joinButton.Text = "THU LAI"
            joinButton.Active = true
            updateStatus("Khong the vao may chu: " .. tostring(err))
        else
            updateStatus("Da gui yeu cau dich chuyen. Dang cho Roblox xu ly...")
            task.delay(6, function()
                if ScreenGui.Parent and entry.Parent then
                    isJoining = false
                    joinButton.Text = "THAM GIA"
                    joinButton.Active = true
                end
            end)
        end
    end)

    return {
        Frame = entry,
        Info = info,
        Fill = fill,
        JoinButton = joinButton,
        SetData = function(data, layoutOrder)
            currentServer = data
            isJoining = false
            entry.LayoutOrder = layoutOrder
            entry.BackgroundColor3 = layoutOrder % 2 == 0 and Color3.fromRGB(24, 35, 54) or Color3.fromRGB(21, 31, 48)

            local playersNow = tonumber(data.playing) or 0
            local maxPlayers = tonumber(data.maxPlayers) or 0
            local freeSlots = math.max(0, maxPlayers - playersNow)
            local ratio = maxPlayers > 0 and (playersNow / maxPlayers) or 0
            local statusColor = ratio >= 0.9 and Color3.fromRGB(244, 114, 114)
                or (ratio >= 0.65 and Color3.fromRGB(250, 204, 120) or Color3.fromRGB(110, 231, 183))

            info.Text = string.format("Nguoi choi: %d / %d   |   Trong: %d\nID: %s", playersNow, maxPlayers, freeSlots, tostring(data.id))
            fill.Size = UDim2.new(math.clamp(ratio, 0, 1), 0, 1, 0)
            fill.BackgroundColor3 = statusColor
            joinButton.Text = "THAM GIA"
            joinButton.Active = true
            entry.Visible = true
        end,
        Hide = function()
            currentServer = nil
            isJoining = false
            entry.Visible = false
        end,
    }
end

local function renderServers()
    if not ScreenGui.Parent then
        return
    end

    local query = safeLower(trim(SearchBox.Text))
    local filtered = {}

    for _, server in ipairs(allServers) do
        local playersNow = tonumber(server.playing) or 0
        local maxPlayers = tonumber(server.maxPlayers) or 0
        local idText = safeLower(server.id)
        local isOpen = playersNow < maxPlayers
        local inBand = playersNow >= 1 and playersNow <= 2
        local matchesSearch = query == "" or string.find(idText, query, 1, true) ~= nil
            or string.find(tostring(playersNow), query, 1, true) ~= nil

        if isOpen and inBand and matchesSearch then
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

    local visibleCount = math.min(#filtered, 300)
    local emptyState = getOrCreateEmptyState()

    for index = 1, visibleCount do
        if not entryPool[index] then
            entryPool[index] = createEntryTemplate(index)
        end
        entryPool[index].SetData(filtered[index], index)
    end

    for index = visibleCount + 1, #entryPool do
        entryPool[index].Hide()
    end

    if visibleCount == 0 then
        emptyState.Visible = true
        if isScanning then
            emptyState.Text = "Dang tim may chu cong khai 1-2 nguoi..."
        elseif #allServers == 0 then
            emptyState.Text = "Chua co du lieu. Nhan QUET LAI de thu lai."
        else
            emptyState.Text = "Chua tim thay may chu 1-2 nguoi. Dang tiep tuc quet..."
        end
    else
        emptyState.Visible = false
    end

    SortButton.Text = sortAscending and "It nguoi truoc" or "Nhieu nguoi truoc"
end

local startScan

local function attemptAutoHop()
    if not autoHopEnabled or autoHopInProgress or not ScreenGui.Parent then
        return
    end

    local candidates = {}
    for _, server in ipairs(allServers) do
        local playing = tonumber(server.playing) or 0
        local maximum = tonumber(server.maxPlayers) or 0
        if maximum > playing and playing >= 1 and playing <= 2 and not autoHopAttempted[server.id] then
            table.insert(candidates, server)
        end
    end

    table.sort(candidates, function(a, b)
        local ap, bp = tonumber(a.playing) or 0, tonumber(b.playing) or 0
        if ap == bp then
            return tostring(a.id) < tostring(b.id)
        end
        return ap < bp
    end)

    local target = candidates[1]
    if not target then
        task.delay(1.5, function()
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
        updateStatus("Auto hop loi: " .. tostring(err) .. "; thu may chu tiep theo")
        task.delay(0.5, function()
            if autoHopEnabled and ScreenGui.Parent then
                attemptAutoHop()
            end
        end)
    else
        updateStatus(string.format("Auto hop: da gui yeu cau vao may chu %d nguoi", target.playing))
        task.delay(10, function()
            if autoHopInProgress and ScreenGui.Parent then
                autoHopInProgress = false
                if autoHopEnabled then
                    attemptAutoHop()
                end
            end
        end)
    end
end

local function fetchServers(cursor)
    local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId)
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
                local decodedOk, payload = pcall(function()
                    return HttpService:JSONDecode(body)
                end)
                if decodedOk and type(payload) == "table" and type(payload.data) == "table" then
                    return payload
                end
            end
        end
        task.wait(attempt * 0.5)
    end
    return nil
end

startScan = function()
    if isScanning then
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
    updateStatus("Bat dau tim may chu 1-2 nguoi...")
    renderServers()

    task.spawn(function()
        local cursor = nil
        local seenIds = {}
        local foundIdealServer = false

        for pageNumber = 1, 50 do
            if thisGeneration ~= scanGeneration or not ScreenGui.Parent then
                return
            end

            updateStatus(string.format("Dang quet trang %d...", pageNumber))
            local payload = fetchServers(cursor)
            if not payload then
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

                        if playing >= 1 and playing <= 2 and not autoHopAttempted[server.id] then
                            foundIdealServer = true
                        end
                    end
                end
            end

            if pageNumber == 1 or pageNumber % 2 == 0 then
                renderServers()
            end

            if autoHopEnabled and foundIdealServer and not autoHopInProgress then
                task.spawn(attemptAutoHop)
                break
            end

            cursor = payload.nextPageCursor
            if not cursor or cursor == "" then
                break
            end
            task.wait(0.2)
        end

        if thisGeneration ~= scanGeneration or not ScreenGui.Parent then
            return
        end

        isScanning = false
        RefreshButton.Text = "QUET LAI"
        RefreshButton.Active = true
        RefreshButton.AutoButtonColor = true
        renderServers()

        if autoHopEnabled and not autoHopInProgress then
            task.delay(0.1, attemptAutoHop)
        end
    end)
end

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    if searchDebounceTimer then
        task.cancel(searchDebounceTimer)
    end
    searchDebounceTimer = task.delay(0.12, function()
        renderServers()
    end)
end)

SortButton.Activated:Connect(function()
    sortAscending = not sortAscending
    autoHopAttempted = {}
    renderServers()
end)

RefreshButton.Activated:Connect(startScan)

AutoHopButton.Activated:Connect(function()
    autoHopEnabled = not autoHopEnabled
    AutoHopButton.Text = autoHopEnabled and "AUTO HOP: ON (1-2)" or "AUTO HOP: OFF"
    AutoHopButton.BackgroundColor3 = autoHopEnabled and Color3.fromRGB(32, 146, 104) or Color3.fromRGB(75, 79, 91)
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

pcall(function()
    TeleportService.TeleportInitFailed:Connect(function(player, result, errorMessage)
        if player == LocalPlayer and ScreenGui.Parent then
            autoHopInProgress = false
            updateStatus("Dich chuyen that bai: " .. tostring(result) .. " - " .. tostring(errorMessage))
            if autoHopEnabled then
                task.delay(1, attemptAutoHop)
            end
        end
    end)
end)

startScan()
