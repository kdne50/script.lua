local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local targetNames = {
    ["LiveHintBook"] = true, ["KeyObtain"] = true, ["LiveBreakerPolePickup"] = true,
    ["SmoothieSpawner"] = true, ["Shears"] = true, ["Lighter"] = true,
    ["Crucifix"] = true, ["Lockpick"] = true, ["Battery"] = true,
    ["Vitamins"] = true, ["Smoothie"] = true, ["AlarmClock"] = true,
    ["Bandage"] = true, ["Candle"] = true, ["LibraryHintPaper"] = true,
    ["SkeletonKey"] = true, ["Flashlight"] = true, ["RiftSmoothie"] = true,
    ["FuseObtain"] = true, ["BandagePack"] = true, ["Bulklight"] = true,
    ["Straplight"] = true, ["Glowsticks"] = true, ["BatteryPack"] = true,
    ["LaserPointer"] = true, ["ElectricalKeyObtain"] = true, ["Starlight Bottle"] = true,
    ["Starlight Jug"] = true, ["Shakelight"] = true, ["Gween Soda"] = true,
    ["Bread"] = true, ["Cheese"] = true
}

local highlightColor = Color3.fromRGB(0, 255, 255)
local outlineColor = Color3.fromRGB(255, 255, 255)

local highlights, tracers, nametags = {}, {}, {}
local connections, renderConnection = {}, nil
local settings = {
    HighlightEnabled = true,
    TracerEnabled = true,
    NameTagEnabled = false,
    ShowDistance = false,
    RainbowEnabled = false
}

local RunConnection

-- Проверка, игнорируем ли объект (например, у игрока в рюкзаке или персонаже)
local function isIgnored(model)
    return model:IsDescendantOf(LocalPlayer.Backpack) or model:IsDescendantOf(LocalPlayer.Character)
end

-- Очистка всех ESP элементов
local function clearESP()
    for model, h in pairs(highlights) do
        if h then pcall(function() h:Destroy() end) end
        highlights[model] = nil
    end
    for model, t in pairs(tracers) do
        if t then pcall(function() t:Remove() end) end
        tracers[model] = nil
    end
    for model, n in pairs(nametags) do
        if n then pcall(function() n:Destroy() end) end
        nametags[model] = nil
    end
end

-- Добавить Highlight
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

-- Добавить Tracer (линия от низа экрана к объекту)
local function addTracer(model)
    if not tracers[model] and settings.TracerEnabled then
        local line = Drawing.new("Line")
        line.Thickness = 1.5
        line.Color = highlightColor
        line.Visible = false
        tracers[model] = line
    end
end

-- Добавить NameTag
local function addNameTag(model)
    if not nametags[model] and settings.NameTagEnabled then
        local part = model:FindFirstChildWhichIsA("BasePart")
        if not part then return end

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "_ESP_NameTag"
        billboard.Adornee = part
        billboard.AlwaysOnTop = true
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 2, 0)
        billboard.Parent = model

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = model.Name
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextStrokeTransparency = 0.5
        label.TextScaled = true
        label.Font = Enum.Font.SourceSansBold
        label.Parent = billboard

        nametags[model] = billboard
    end
end

-- Обновление цвета хайлайта и трейсера (для радуги)
local function updateColors(color)
    for _, h in pairs(highlights) do
        if h and h.FillColor then
            h.FillColor = color
            h.OutlineColor = color
        end
    end
    for _, t in pairs(tracers) do
        if t then
            t.Color = color
        end
    end
end

-- Обработка одной модели (добавление ESP если нужно)
local function processModel(model)
    if targetNames[model.Name] and model:IsA("Model") and not isIgnored(model) then
        addHighlight(model)
        addTracer(model)
        addNameTag(model)
    end
end

-- Сканы всех объектов в Workspace
local function scan()
    clearESP()
    for _, obj in pairs(Workspace:GetDescendants()) do
        processModel(obj)
    end
end

-- Обработка нового объекта
local function onNewChild(obj)
    task.delay(0.05, function()
        processModel(obj)
    end)
end

-- Основной цикл для обновления трейсеров и отображения
local function onRenderStep()
    local color = highlightColor
    if settings.RainbowEnabled then
        local hue = tick() % 5 / 5 -- плавный переход цвета за 5 секунд
        color = Color3.fromHSV(hue, 1, 1)
        updateColors(color)
    end

    for model, line in pairs(tracers) do
        if not model or not model.Parent or isIgnored(model) or not settings.TracerEnabled then
            pcall(function() line:Remove() end)
            tracers[model] = nil
        else
            local part = model:FindFirstChildWhichIsA("BasePart")
            if part then
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                line.To = Vector2.new(pos.X, pos.Y)
                line.Visible = onScreen
            else
                line.Visible = false
            end
        end
    end

    for model, tag in pairs(nametags) do
        if not model or not model.Parent or isIgnored(model) or not settings.NameTagEnabled then
            pcall(function() tag:Destroy() end)
            nametags[model] = nil
        end
    end
end

-- Включение ESP
local function EnableESP()
    DisableESP()
    scan()
    table.insert(connections, Workspace.DescendantAdded:Connect(onNewChild))
    RunConnection = RunService.RenderStepped:Connect(onRenderStep)
end

-- Отключение ESP
function DisableESP()
    if RunConnection then
        RunConnection:Disconnect()
        RunConnection = nil
    end
    for _, conn in pairs(connections) do conn:Disconnect() end
    connections = {}
    clearESP()
end

-- Сеттеры настроек
local function SetHighlight(value)
    settings.HighlightEnabled = value
    scan()
end

local function SetTracer(value)
    settings.TracerEnabled = value
    scan()
end

local function SetNameTag(value)
    settings.NameTagEnabled = value
    scan()
end

local function SetShowDistance(value)
    settings.ShowDistance = value
    -- реализуй, если хочешь, отображение расстояния в NameTag или Label
end

local function SetRainbow(value)
    settings.RainbowEnabled = value
    if not value then
        updateColors(highlightColor)
    end
end

return {
    EnableESP = EnableESP,
    DisableESP = DisableESP,
    SetHighlight = SetHighlight,
    SetTracer = SetTracer,
    SetNameTag = SetNameTag,
    SetShowDistance = SetShowDistance,
    SetRainbow = SetRainbow
}
