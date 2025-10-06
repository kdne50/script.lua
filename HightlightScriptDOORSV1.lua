local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local highlightColor = Color3.fromRGB(0, 255, 255)
local outlineColor = Color3.fromRGB(255, 255, 255)
local baseTextSize = 24
local baseBillboardSize = UDim2.new(0, 200, 0, 50)

--------------------------------------------------
-- Папки под CoreGui
--------------------------------------------------
local ScreenGui = CoreGui:FindFirstChild("ItemESP_GUI") or Instance.new("ScreenGui")
ScreenGui.Name = "ItemESP_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = CoreGui

local HighlightsFolder = CoreGui:FindFirstChild("HighlightsFolder_ItemESP") or Instance.new("Folder")
HighlightsFolder.Name = "HighlightsFolder_ItemESP"
HighlightsFolder.Parent = CoreGui

--------------------------------------------------
-- Настройки
--------------------------------------------------
local settings = {
    HighlightEnabled = true,
    TracerEnabled = true,
    NameTagEnabled = true,
    Font = Enum.Font.Oswald,
    TextTransparency = 0,
    TextOutlineTransparency = 0.5,
    ShowDistance = false,
    MatchColors = true
}

--------------------------------------------------
-- Полный список предметов
--------------------------------------------------
local TargetItemsHighlights51 = {
    ["LiveHintBook"] = "Book",
    ["KeyObtain"] = "Key",
    ["ElectricalKeyObtain"] = "Key",
    ["LiveBreakerPolePickup"] = "Breaker",
    ["SmoothieSpawner"] = "Smoothie",
    ["Shears"] = "Shears",
    ["Lighter"] = "Lighter",
    ["Crucifix"] = "Crucifix",
    ["CrucifixWall"] = "Crucifix",
    ["Lockpick"] = "Lockpick",
    ["Battery"] = "Battery",
    ["BatteryPack"] = "Battery-Pack",
    ["Bandage"] = "Bandage",
    ["BandagePack"] = "Bandage-Pack",
    ["Vitamins"] = "Vitamins",
    ["Candle"] = "Candle",
    ["Lantern"] = "Lantern",
    ["Bulklight"] = "Bulklight",
    ["Straplight"] = "Straplight",
    ["Glowsticks"] = "Glowsticks",
    ["Flashlight"] = "Flashlight",
    ["Shakelight"] = "Shakelight",
    ["LaserPointer"] = "Laser",
    ["Starlight Bottle"] = "Starlight-Bottle",
    ["Starlight Jug"] = "Starlight-Jug",
    ["StarVial"] = "Star-Vial",
    ["StarBottle"] = "Star-Bottle",
    ["StarJug"] = "Star-Jug",
    ["Multitool"] = "Multi-Tool",
    ["BigPropTool"] = "BigPropTool",
    ["GoldGun"] = "Gun",
    ["HolyGrenade"] = "Holy-Grenade",
    ["StopSign"] = "Stop-Sign",
    ["TimerLever"] = "Lever",
    ["FuseObtain"] = "Fuse",
    ["GoldPile"] = "Gold",
    ["TipJar"] = "Tip-Jar",
    ["RiftCandle"] = "Rift-Candle",
    ["RiftJar"] = "Rift-Jar",
    ["RiftSmoothie"] = "Rift-Smoothie",
    ["RiftPotion"] = "Rift-Potion",
    ["Smoothie"] = "Smoothie",
    ["Gween Soda"] = "Gween-Soda",
    ["Bread"] = "Bread",
    ["Donut"] = "Donut",
    ["Cheese"] = "Cheese",
    ["BigBomb"] = "Big-Bomb",
    ["Knockbomb"] = "Knock-Bomb",
    ["Bomb"] = "Bomb",
    ["Nanner"] = "Nanner",
    ["NannerPeel"] = "Nanner-Peel",
    ["SnakeBox"] = "Snake-Box",
    ["Compass"] = "Compass",
    ["AloeVera"] = "Aloe-Vera",
    ["Lotus"] = "Lotus",
    ["LotusPetalPickup"] = "Lotus-Petal",
    ["GlitchCube"] = "Glitch-Fragment",
    ["StardustPickup"] = "Stardust",
    ["SkeletonKey"] = "SkeletonKey",
    ["Door"] = "Door", -- теперь двери в общем списке
}

--------------------------------------------------
-- Таблицы объектов
--------------------------------------------------
local highlights, tracers, nametags = {}, {}, {}
local connections, renderConnection = {}, nil

--------------------------------------------------
-- Проверки
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
-- Создание Highlight / Tracer / NameTag
--------------------------------------------------
local function addHighlight(model)
    if highlights[model] or not settings.HighlightEnabled then return end
    local h = Instance.new("Highlight")
    h.Name = "_ESP_Highlight"
    h.FillColor = highlightColor
    h.OutlineColor = outlineColor
    h.FillTransparency = 0.8
    h.OutlineTransparency = 0
    h.Adornee = model
    h.Parent = HighlightsFolder
    highlights[model] = h
end

local function addTracer(model)
    if tracers[model] or not settings.TracerEnabled then return end
    local line = Drawing.new("Line")
    line.Thickness = 1.5
    line.Color = highlightColor
    line.Visible = false
    tracers[model] = line
end

local function addNameTag(model)
    if nametags[model] or not settings.NameTagEnabled then return end
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
    label.TextColor3 = highlightColor
    label.TextStrokeTransparency = settings.TextOutlineTransparency
    label.TextTransparency = settings.TextTransparency
    label.Font = settings.Font
    label.TextSize = baseTextSize
    label.RichText = true
    label.Text = TargetItemsHighlights51[model.Name] or model.Name
    label.Parent = billboard

    nametags[model] = billboard
end

--------------------------------------------------
-- Обработка дверей и предметов
--------------------------------------------------
local function processModel(model)
    if model:IsA("Model") and not isIgnored(model) then
        -- обрабатываем предметы
        if TargetItemsHighlights51[model.Name] then
            addHighlight(model)
            addTracer(model)
            addNameTag(model)
        end
        -- отдельная логика для дверей
        if model.Name == "Door" and model:FindFirstChild("Door") then
            local mesh = model:FindFirstChild("Door")
            addHighlight(mesh)
            addTracer(mesh)
            addNameTag(mesh)
        end
    end
end

local function scanAll()
    for _, obj in pairs(Workspace:GetDescendants()) do
        processModel(obj)
    end
end

--------------------------------------------------
-- Обновление Tracers
--------------------------------------------------
local function updateTracers()
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for model, line in pairs(tracers) do
        if not model or not model:IsDescendantOf(Workspace) or isIgnored(model) then
            pcall(function() line:Remove() end)
            tracers[model] = nil
        else
            local part = model:FindFirstChildWhichIsA("BasePart") or model
            if part and hrp then
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                line.To = Vector2.new(pos.X, pos.Y)
                line.Visible = onScreen
            else
                line.Visible = false
            end
        end
    end
end

--------------------------------------------------
-- Главный цикл
--------------------------------------------------
local function enable()
    disable()
    scanAll()

    table.insert(connections, Workspace.DescendantAdded:Connect(function(obj)
        task.defer(processModel, obj)
    end))

    table.insert(connections, LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        scanAll()
    end))

    renderConnection = RunService.RenderStepped:Connect(function()
        updateTracers()
    end)
end

function disable()
    if renderConnection then renderConnection:Disconnect() renderConnection = nil end
    for _, conn in pairs(connections) do conn:Disconnect() end
    connections = {}

    for _, h in pairs(highlights) do pcall(function() h:Destroy() end) end
    for _, t in pairs(tracers) do pcall(function() t:Remove() end) end
    for _, n in pairs(nametags) do pcall(function() n:Destroy() end) end
    highlights, tracers, nametags = {}, {}, {}
end

--------------------------------------------------
-- Возврат
--------------------------------------------------
return {
    EnableESP = enable,
    DisableESP = disable,
    SetHighlight = function(v) settings.HighlightEnabled = v scanAll() end,
    SetTracer = function(v) settings.TracerEnabled = v scanAll() end,
    SetNameTag = function(v) settings.NameTagEnabled = v scanAll() end,
    TargetItemsHighlights51 = TargetItemsHighlights51
}
