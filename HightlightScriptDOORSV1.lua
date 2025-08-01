--// ✅ Полный ESP-модуль: Item ESP + Entity ESP (CylinderHandleAdornment)

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Список имен предметов для Item ESP
local itemNames = {
    LiveHintBook=true, KeyObtain=true, LiveBreakerPolePickup=true,
    SmoothieSpawner=true, Shears=true, Lighter=true,
    Crucifix=true, Lockpick=true, Battery=true,
    Vitamins=true, Smoothie=true, AlarmClock=true,
    Bandage=true, Candle=true, LibraryHintPaper=true,
    SkeletonKey=true, Flashlight=true, RiftSmoothie=true,
    FuseObtain=true, BandagePack=true, Bulklight=true,
    CrucifixWall=true, Straplight=true, Glowsticks=true,
    BatteryPack=true, LaserPointer=true, ElectricalKeyObtain=true,
    ["Starlight Bottle"]=true, ["Starlight Jug"]=true, Shakelight=true,
    ["Gween Soda"]=true, Bread=true, Cheese=true,
    StarVial=true, StarBottle=true, TimerLever=true,
}

-- Сопоставление моделей сущностей к их Part для Entity ESP
local entityMap = {
    RushMoving="RushNew", AmbushMoving="RushNew", Eyes="Core",
    BackdoorRush="Main", BackdoorLookman="Core", A60="Main", A120="Main",
}

-- Цвета
local highlightColor = Color3.fromRGB(0,255,255)
local tracerColor = Color3.fromRGB(0,255,255)
local entityColor = Color3.fromRGB(255,128,0)

-- Хранилища ESP
local highlights = {}      -- Highlight Instances per model
local tracers = {}         -- Drawing Lines per model
local nametags = {}        -- BillboardGui per model
local entities = {}        -- CylinderHandleAdornment per entity part

-- Настройки ESP
local settings = {
    Highlight = true,
    Tracer = true,
    NameTag = false,
    ShowDistance = false,
}

-- Вспомогательные функции
local function isIgnored(item)
    return item:IsDescendantOf(LocalPlayer.Character) or item:IsDescendantOf(LocalPlayer.Backpack)
end

-- Очистка нужного ESP типа
local function clearTable(tbl)
    for obj, inst in pairs(tbl) do
        pcall(function() inst:Destroy() end)
    end
    table.clear(tbl)
end

-- Добавление Highlight
local function addHighlight(model)
    if not settings.Highlight or highlights[model] then return end
    local h = Instance.new("Highlight")
    h.Adornee = model
    h.FillColor = highlightColor
    h.OutlineColor = highlightColor
    h.Parent = model
    highlights[model] = h
end

-- Добавление Tracer (только одна линия на модель)
local function addTracer(model)
    if not settings.Tracer or tracers[model] then return end
    local primary = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not primary then return end
    local line = Drawing.new("Line")
    line.Thickness = 1.5
    line.Color = tracerColor
    line.Transparency = 1
    line.Visible = false
    tracers[model] = {line=line, part=primary}
end

-- Добавление NameTag (только одна на модель)
local function addNameTag(model)
    if not settings.NameTag or nametags[model] then return end
    local primary = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not primary then return end
    local gui = Instance.new("BillboardGui")
    gui.Adornee = primary
    gui.Size = UDim2.new(0,100,0,30)
    gui.AlwaysOnTop = true
    gui.Parent = primary
    local lbl = Instance.new("TextLabel", gui)
    lbl.Size = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = model.Name
    lbl.TextColor3 = Color3.new(1,1,1)
    nametags[model] = gui
end

-- Добавление Entity ESP (CylinderHandleAdornment по размеру Part)
local function addEntity(part)
    if entities[part] then return end
    local ch = Instance.new("CylinderHandleAdornment")
    ch.Adornee = part
    ch.AlwaysOnTop = true
    ch.Color3 = entityColor
    -- радиус по XZ половина, уменьшенный для визуала
    local radius = math.max(part.Size.X, part.Size.Z) / 2 * 0.8
    ch.Radius = radius
    -- высота чуть меньше части
    ch.Height = part.Size.Y * 0.8
    ch.Transparency = 0.4
    ch.ZIndex = 5
    ch.Parent = part
    entities[part] = ch
end

-- Процессинг модели или Part
local function process(obj)
    if isIgnored(obj) then return end
    -- Item ESP
    if obj:IsA("Model") and itemNames[obj.Name] then
        addHighlight(obj)
        addTracer(obj)
        addNameTag(obj)
    end
    -- Entity ESP
    if obj:IsA("Model") then
        local partName = entityMap[obj.Name]
        if partName then
            local p = obj:FindFirstChild(partName)
            if p and p:IsA("BasePart") then
                addEntity(p)
            end
        end
    end
end

-- Сканирование всего рабочего пространства
local function scanAll()
    clearTable(highlights)
    clearTable(tracers)
    clearTable(nametags)
    clearTable(entities)
    for _, obj in pairs(Workspace:GetDescendants()) do
        process(obj)
    end
end

-- Обработка обновления визуалов (трасеры, дистанция)
local function onRender()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    for model, data in pairs(tracers) do
        local line, part = data.line, data.part
        if model and part and part:IsDescendantOf(Workspace) and root then
            local p2, onScreen = Camera:WorldToViewportPoint(part.Position)
            line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
            line.To = Vector2.new(p2.X, p2.Y)
            line.Visible = onScreen
        else
            line.Visible = false
        end
    end
    if settings.ShowDistance then
        for model, gui in pairs(nametags) do
            local part = gui.Adornee
            if part and root then
                local dist = (root.Position - part.Position).Magnitude
                gui:FindFirstChildOfClass("TextLabel").Text = string.format("%s [%.0f]", model.Name, dist)
            end
        end
    end
end

-- Подключение/отключение слушателей
local connections = {}
local function startESP()
    scanAll()
    table.insert(connections, Workspace.DescendantAdded:Connect(process))
    table.insert(connections, Workspace.DescendantRemoving:Connect(function(o)
        highlights[o] = nil
        tracers[o] = nil
        nametags[o] = nil
        -- entities очищаются при удалении самого Part через Workspace.DescendantRemoving
        entities[o] = nil
    end))
    table.insert(connections, RunService.RenderStepped:Connect(onRender))
end

local function stopESP()
    for _, conn in ipairs(connections) do conn:Disconnect() end
    connections = {}
    clearTable(highlights)
    clearTable(tracers)
    clearTable(nametags)
    clearTable(entities)
end

-- Экспорт функций
return {
    EnableItemESP = startESP,
    DisableItemESP = stopESP,
    EnableEntityESP = startESP,
    DisableEntityESP = stopESP,
    SetHighlight = function(v) settings.Highlight = v; scanAll() end,
    SetTracer = function(v) settings.Tracer = v; scanAll() end,
    SetNameTag = function(v) settings.NameTag = v; scanAll() end,
    SetShowDistance = function(v) settings.ShowDistance = v; scanAll() end,
}
