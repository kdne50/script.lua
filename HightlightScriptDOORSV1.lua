local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

--------------------------------------------------
-- == ПАРАМЕТРЫ == --
--------------------------------------------------
local highlightColor = Color3.fromRGB(0, 255, 255)
local outlineColor = Color3.fromRGB(255, 255, 255)
local baseFOV = Camera.FieldOfView
local baseTextSize = 24
local baseBillboardSize = UDim2.new(0, 200, 0, 50)

--------------------------------------------------
-- == НАСТРОЙКИ == --
--------------------------------------------------
local settings = {
    HighlightEnabled = true,
    TracerEnabled = true,
    NameTagEnabled = true,
    ArrowsEnabled = false,
    DoorESPEnabled = false,
    TextSize = 35,
    Font = Enum.Font.Oswald,
    TextTransparency = 0,
    TextOutlineTransparency = 0.5,
    ShowDistance = false,
    MatchColors = true
}

--------------------------------------------------
-- == ПАПКИ И ОБЪЕКТЫ == --
--------------------------------------------------
local ScreenGui = CoreGui:FindFirstChild("ItemESP_GUI") or Instance.new("ScreenGui")
ScreenGui.Name = "ItemESP_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = CoreGui

local ArrowsFrame = Instance.new("Frame")
ArrowsFrame.Name = "ArrowsFrame"
ArrowsFrame.Size = UDim2.new(1, 0, 1, 0)
ArrowsFrame.BackgroundTransparency = 1
ArrowsFrame.Parent = ScreenGui

local HighlightsFolder = CoreGui:FindFirstChild("HighlightsFolder_ItemESP") or Instance.new("Folder")
HighlightsFolder.Name = "HighlightsFolder_ItemESP"
HighlightsFolder.Parent = CoreGui

local ArrowTemplate = Instance.new("ImageLabel")
ArrowTemplate.Image = "rbxassetid://2418687610"
ArrowTemplate.Size = UDim2.new(0, 72, 0, 72)
ArrowTemplate.AnchorPoint = Vector2.new(0.5, 0.5)
ArrowTemplate.BackgroundTransparency = 1
ArrowTemplate.ImageTransparency = 0
local ratio = Instance.new("UIAspectRatioConstraint", ArrowTemplate)
ratio.AspectRatio = 0.75

--------------------------------------------------
-- == СПИСКИ == --
--------------------------------------------------
local TargetItemsHighlights51 = {
    ["LiveHintBook"] = "Book",
    ["KeyObtain"] = "Key",
    ["LiveBreakerPolePickup"] = "Breaker",
    ["SmoothieSpawner"] = "Smoothie",
    ["Shears"] = "Shears",
    ["Lighter"] = "Lighter",
    ["Crucifix"] = "Crucifix",
    ["Lockpick"] = "Lockpick",
    ["Battery"] = "Battery",
    ["Vitamins"] = "Vitamins",
    ["Smoothie"] = "Smoothie",
    ["AlarmClock"] = "Alarm-Clock",
    ["Bandage"] = "Bandage",
    ["Candle"] = "Candle",
    ["LibraryHintPaper"] = "Paper",
    ["SkeletonKey"] = "SkeletonKey",
    ["Flashlight"] = "Flashlight",
    ["RiftSmoothie"] = "Rift-Smoothie",
    ["FuseObtain"] = "Fuse",
    ["BandagePack"] = "Bandage-Pack",
    ["Bulklight"] = "Bulklight",
    ["CrucifixWall"] = "Crucifix",
    ["Straplight"] = "Straplight",
    ["Glowsticks"] = "Glowsticks",
    ["BatteryPack"] = "Battery-Pack",
    ["LaserPointer"] = "Laser",
    ["ElectricalKeyObtain"] = "Key",
    ["Starlight Bottle"] = "Starlight-Bottle",
    ["Starlight Jug"] = "Starlight-Jug",
    ["Shakelight"] = "Shakelight",
    ["Gween Soda"] = "Gween-Soda",
    ["Bread"] = "Bread",
    ["Cheese"] = "Cheese",
    ["StarVial"] = "Star-Vial",
    ["StarBottle"] = "Star-Bottle",
    ["TimerLever"] = "Lever",
    ["Lantern"] = "Lantern",
    ["BigPropTool"] = "BigPropTool",
    ["Multitool"] = "Multi-Tool",
    ["GoldGun"] = "Gun",
    ["RiftCandle"] = "Rift-Candle",
    ["RiftJar"] = "Rift-Jar",
    ["TipJar"] = "Tip-Jar",
    ["Knockbomb"] = "Knock-Bomb",
    ["Bomb"] = "Bomb",
    ["Donut"] = "Donut",
    ["BigBomb"] = "Big-Bomb",
    ["StarJug"] = "Star-Jug",
    ["Nanner"] = "Nanner",
    ["SnakeBox"] = "Box",
    ["AloeVera"] = "Aloe-Vera",
    ["Compass"] = "Compass",
    ["Lotus"] = "Big-Lotus",
    ["NannerPeel"] = "NannerPeel",
    ["HolyGrenade"] = "Holy-Grenade",
    ["StopSign"] = "Stop-Sign",
    ["StardustPickup"] = "Stardust",
    ["GoldPile"] = "Gold",
    ["LotusPetalPickup"] = "Lotus",
    ["GlitchCube"] = "Glitch-Fragment",
}
local EntitiesHighlights203 = {}

local highlights, tracers, nametags, arrows = {}, {}, {}, {}
local connections, renderConnection, doorConnection = {}, nil, nil

--------------------------------------------------
-- == ПРОВЕРКИ == --
--------------------------------------------------
local function isHeldByPlayer(model)
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character and model:IsDescendantOf(player.Character) then return true end
        if player:FindFirstChild("Backpack") and model:IsDescendantOf(player.Backpack) then return true end
    end
    return false
end

local function isIgnored(model)
    return model:IsDescendantOf(LocalPlayer.Backpack)
        or model:IsDescendantOf(LocalPlayer.Character)
        or isHeldByPlayer(model)
end

--------------------------------------------------
-- == ОСНОВНЫЕ ФУНКЦИИ == --
--------------------------------------------------
local function clearESP()
    for _, h in pairs(highlights) do pcall(function() h:Destroy() end) end
    for _, t in pairs(tracers) do pcall(function() t:Remove() end) end
    for _, n in pairs(nametags) do pcall(function() n:Destroy() end) end
    for _, a in pairs(arrows) do pcall(function() a:Destroy() end) end
    highlights, tracers, nametags, arrows = {}, {}, {}, {}
end

local function removeModelRefs(model)
    if highlights[model] then pcall(function() highlights[model]:Destroy() end) highlights[model] = nil end
    if tracers[model] then pcall(function() tracers[model]:Remove() end) tracers[model] = nil end
    if nametags[model] then pcall(function() nametags[model]:Destroy() end) nametags[model] = nil end
    if arrows[model] then pcall(function() arrows[model]:Destroy() end) arrows[model] = nil end
end

local function addHighlight(model)
    if not highlights[model] and settings.HighlightEnabled then
        local h = Instance.new("Highlight")
        h.Name = "_ItemESP"
        h.FillColor = highlightColor
        h.OutlineColor = outlineColor
        h.FillTransparency = 0.8
        h.OutlineTransparency = 0
        h.Adornee = model
        h.Parent = HighlightsFolder
        highlights[model] = h
    end
end

local function addTracer(model)
    if not tracers[model] and settings.TracerEnabled then
        local line = Drawing.new("Line")
        line.Thickness = 1.5
        line.Color = highlightColor
        line.Visible = false
        tracers[model] = line
    end
end

local function addNameTag(model)
    if not nametags[model] and settings.NameTagEnabled then
        local part = model:FindFirstChildWhichIsA("BasePart")
        if not part then return end

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "_ESP_NameTag"
        billboard.Adornee = part
        billboard.AlwaysOnTop = true
        billboard.Size = baseBillboardSize
        billboard.StudsOffset = Vector3.new(0, -0.5, 0)
        billboard.Parent = model

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = settings.MatchColors and highlightColor or Color3.new(1, 1, 1)
        label.TextStrokeTransparency = settings.TextOutlineTransparency
        label.TextTransparency = settings.TextTransparency
        label.Font = settings.Font
        label.TextSize = baseTextSize
        label.RichText = true
        label.TextScaled = false
        label.Parent = billboard
        label.Text = TargetItemsHighlights51[model.Name] or model.Name
        nametags[model] = billboard
    end
end

local function addArrow(model)
    if not arrows[model] and settings.ArrowsEnabled then
        local arrow = ArrowTemplate:Clone()
        arrow.Parent = ArrowsFrame
        arrow.Visible = true
        arrows[model] = arrow
    end
end

local function updateArrow(model)
    if not settings.ArrowsEnabled then
        if arrows[model] then arrows[model].Visible = false end
        return
    end
    local part = model:FindFirstChildWhichIsA("BasePart")
    if not part then return end
    local screenPoint, onScreen = Camera:WorldToViewportPoint(part.Position)
    if onScreen and screenPoint.Z > 0 then
        if arrows[model] then arrows[model].Visible = false end
    else
        if not arrows[model] then addArrow(model) end
        local screenSize = Camera.ViewportSize
        local screenCenter = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
        local dir = Vector2.new(screenPoint.X, screenPoint.Y) - screenCenter
        if dir.Magnitude == 0 then dir = Vector2.new(0.01, 0.01) end
        local angle = math.atan2(dir.Y, dir.X)
        local radius = math.min(screenSize.X, screenSize.Y) / 2 - 200
        local arrowPos = screenCenter + dir.Unit * radius
        arrows[model].Position = UDim2.new(0, arrowPos.X, 0, arrowPos.Y)
        arrows[model].Rotation = math.deg(angle) - 180
        arrows[model].ImageColor3 = highlightColor
        arrows[model].Visible = true
    end
end

--------------------------------------------------
-- == ДОПОЛНИТЕЛЬНЫЕ == --
--------------------------------------------------
local function processModel(model)
    if TargetItemsHighlights51[model.Name] and model:IsA("Model") and model:IsDescendantOf(Workspace) and not isIgnored(model) then
        addHighlight(model)
        addTracer(model)
        addNameTag(model)
        if settings.ArrowsEnabled then addArrow(model) end
    else
        removeModelRefs(model)
    end
end

local function scan()
    clearESP()
    for _, obj in pairs(Workspace:GetDescendants()) do
        processModel(obj)
    end
end

local function getNearestDoor()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local nearest, dist = nil, math.huge
    for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
        local door = room:FindFirstChild("Door")
        if door and door:FindFirstChildWhichIsA("BasePart") then
            local d = (door:GetPivot().Position - hrp.Position).Magnitude
            if d < dist then
                dist = d
                nearest = door
            end
        end
    end
    return nearest
end

local currentDoor = nil
local function updateDoorESP()
    if not settings.DoorESPEnabled then
        if currentDoor then
            removeModelRefs(currentDoor)
            currentDoor = nil
        end
        return
    end
    local door = getNearestDoor()
    if door ~= currentDoor then
        if currentDoor then removeModelRefs(currentDoor) end
        if door then addHighlight(door) end
        currentDoor = door
    end
end

--------------------------------------------------
-- == ГЛАВНЫЙ ЦИКЛ == --
--------------------------------------------------
local function enable()
    disable()
    scan()
    table.insert(connections, Workspace.DescendantAdded:Connect(function(obj) task.defer(processModel, obj) end))
    table.insert(connections, Workspace.DescendantRemoving:Connect(removeModelRefs))
    renderConnection = RunService.RenderStepped:Connect(function()
        for model, _ in pairs(highlights) do
            updateArrow(model)
        end
        updateDoorESP()
    end)
end

function disable()
    if renderConnection then renderConnection:Disconnect() renderConnection = nil end
    for _, conn in pairs(connections) do conn:Disconnect() end
    connections = {}
    clearESP()
end

--------------------------------------------------
-- == ДОПОЛНИТЕЛЬНЫЕ ВКЛ/ВЫКЛ == --
--------------------------------------------------
function EnableArrows() settings.ArrowsEnabled = true end
function DisableArrows() settings.ArrowsEnabled = false end
function EnableDoors() settings.DoorESPEnabled = true end
function DisableDoors() settings.DoorESPEnabled = false end

--------------------------------------------------
-- == ВОЗВРАТ == --
--------------------------------------------------
return {
    EnableESP = enable,
    DisableESP = disable,
    EnableArrows = EnableArrows,
    DisableArrows = DisableArrows,
    EnableDoors = EnableDoors,
    DisableDoors = DisableDoors,
    SetHighlight = function(v) settings.HighlightEnabled = v scan() end,
    SetTracer = function(v) settings.TracerEnabled = v scan() end,
    SetNameTag = function(v) settings.NameTagEnabled = v scan() end,
    TargetItemsHighlights51 = TargetItemsHighlights51,
    EntitiesHighlights203 = EntitiesHighlights203
}
