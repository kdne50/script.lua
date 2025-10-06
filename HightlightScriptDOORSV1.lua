local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

--------------------------------------------------
-- === СПИСОК ЦЕЛЕЙ (всё, что подсвечивается) === --
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

--------------------------------------------------
-- === НАСТРОЙКИ === --
--------------------------------------------------
local highlightColor = Color3.fromRGB(0, 255, 255)
local outlineColor = Color3.fromRGB(255, 255, 255)
local baseFOV = Camera.FieldOfView
local baseTextSize = 24
local baseBillboardSize = UDim2.new(0, 200, 0, 50)

local settings = {
    HighlightEnabled = true,
    TracerEnabled = true,
    NameTagEnabled = true,
    ArrowsEnabled = false,
    TextSize = 35,
    Font = Enum.Font.Oswald,
    TextTransparency = 0,
    TextOutlineTransparency = 0.5,
    ShowDistance = false,
    DistanceSizeRatio = 1.0,
    MatchColors = true
}

--------------------------------------------------
-- === СЛУЖЕБНЫЕ === --
--------------------------------------------------
local highlights, tracers, nametags, arrows = {}, {}, {}, {}
local connections, renderConnection = {}, nil

local ArrowsFrame = Instance.new("Frame")
ArrowsFrame.Name = "ArrowsFrame"
ArrowsFrame.Size = UDim2.new(1, 0, 1, 0)
ArrowsFrame.BackgroundTransparency = 1
ArrowsFrame.Parent = CoreGui

local ArrowTemplate = Instance.new("ImageLabel")
ArrowTemplate.Image = "rbxassetid://2418687610"
ArrowTemplate.Size = UDim2.new(0, 72, 0, 72)
ArrowTemplate.AnchorPoint = Vector2.new(0.5, 0.5)
ArrowTemplate.BackgroundTransparency = 1
local ratio = Instance.new("UIAspectRatioConstraint", ArrowTemplate)
ratio.AspectRatio = 0.75

--------------------------------------------------
-- === ПРОВЕРКИ === --
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
-- === ОСНОВНЫЕ ФУНКЦИИ === --
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
        h.Parent = model
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
-- === ЛОГИКА ESP === --
--------------------------------------------------
local function processModel(model)
    if (TargetItemsHighlights51[model.Name] or model.Name == "Door") and model:IsA("Model") and model:IsDescendantOf(Workspace) and not isIgnored(model) then
        addHighlight(model)
        addTracer(model)
        addNameTag(model)
        addArrow(model)
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

--------------------------------------------------
-- === ОСНОВНОЙ ЦИКЛ === --
--------------------------------------------------
local function enable()
    disable()
    scan()

    table.insert(connections, Workspace.DescendantAdded:Connect(function(obj)
        task.defer(processModel, obj)
    end))
    table.insert(connections, Workspace.DescendantRemoving:Connect(removeModelRefs))
    table.insert(connections, LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        scan()
    end))

    renderConnection = RunService.RenderStepped:Connect(function()
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local currentFOV = Camera.FieldOfView
        local fovRatio = currentFOV / baseFOV

        for model, line in pairs(tracers) do
            if not model or not model:IsDescendantOf(Workspace) or isIgnored(model) or not settings.TracerEnabled then
                pcall(function() line:Remove() end)
                tracers[model] = nil
            else
                local part = model:FindFirstChildWhichIsA("BasePart")
                if part and root then
                    local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    line.To = Vector2.new(pos.X, pos.Y)
                    line.Visible = onScreen
                else
                    line.Visible = false
                end
            end
        end

        for model, _ in pairs(highlights) do
            updateArrow(model)
        end
    end)
end

function disable()
    if renderConnection then renderConnection:Disconnect() renderConnection = nil end
    for _, conn in pairs(connections) do conn:Disconnect() end
    connections = {}
    clearESP()
end

--------------------------------------------------
-- === ВОЗВРАТ МЕТОДОВ === --
--------------------------------------------------
return {
    EnableESP = enable,
    DisableESP = disable,
    SetHighlight = function(v) settings.HighlightEnabled = v scan() end,
    SetTracer = function(v) settings.TracerEnabled = v scan() end,
    SetNameTag = function(v) settings.NameTagEnabled = v scan() end,
    SetArrowsEnabled = function(v) settings.ArrowsEnabled = v scan() end,
    SetFont = function(font) settings.Font = font scan() end,
    SetTextSize = function(size) settings.TextSize = size scan() end,
    SetTextTransparency = function(val) settings.TextTransparency = val scan() end,
    SetTextOutlineTransparency = function(val) settings.TextOutlineTransparency = val scan() end,
    SetShowDistance = function(val) settings.ShowDistance = val scan() end,
    SetMatchColors = function(val) settings.MatchColors = val scan() end,
    SetDistanceSizeRatio = function(val) settings.DistanceSizeRatio = val scan() end,
    TargetItemsHighlights51 = TargetItemsHighlights51,
    EntitiesHighlights203 = EntitiesHighlights203
}
