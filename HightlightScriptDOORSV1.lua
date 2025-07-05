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

    -- 🔤 Текстовые настройки:
    TextSize = 20,
    Font = Enum.Font.Oswald,
    TextTransparency = 0,
    TextOutlineTransparency = 0.5,
    ShowDistance = false,
    DistanceSizeRatio = 1.0,
    MatchColors = true
}

local function isIgnored(model)
    return model:IsDescendantOf(LocalPlayer.Backpack) or model:IsDescendantOf(LocalPlayer.Character)
end

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
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, -0.5, 0)
        billboard.Parent = model

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1

        -- 🧠 Расстояние (если включено)
        local distanceText = ""
        if settings.ShowDistance then
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local distance = (root.Position - part.Position).Magnitude
                local size = math.round(settings.TextSize * settings.DistanceSizeRatio)
                distanceText = string.format(' <font size="%d">[%d]</font>', size, distance)
            end
        end

        label.Text = settings.ShowDistance and (model.Name .. distanceText) or model.Name
        label.TextColor3 = settings.MatchColors and highlightColor or Color3.new(1, 1, 1)
        label.TextStrokeTransparency = settings.TextOutlineTransparency
        label.TextTransparency = settings.TextTransparency
        label.Font = settings.Font
        label.TextSize = settings.TextSize
        label.RichText = true
        label.TextScaled = false
        label.Parent = billboard

        nametags[model] = billboard
    end
end

local function processModel(model)
    if targetNames[model.Name] and model:IsA("Model") and not isIgnored(model) then
        addHighlight(model)
        addTracer(model)
        addNameTag(model)
    end
end

local function scan()
    clearESP()
    for _, obj in pairs(Workspace:GetDescendants()) do
        processModel(obj)
    end
end

local function onNewChild(obj)
    task.delay(0.05, function()
        processModel(obj)
    end)
end

local function enable()
    disable()
    scan()
    table.insert(connections, Workspace.DescendantAdded:Connect(onNewChild))

renderConnection = RunService.RenderStepped:Connect(function()
    for model, line in pairs(tracers) do
        if not model or not model.Parent or isIgnored(model) or not settings.TracerEnabled then
            pcall(function() line:Remove() end)
            tracers[model] = nil
            continue
        end

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

    for model, tag in pairs(nametags) do
        if not model or not model.Parent or isIgnored(model) or not settings.NameTagEnabled then
            pcall(function() tag:Destroy() end)
            nametags[model] = nil
        end
    end
end)

function disable()
    if renderConnection then renderConnection:Disconnect() end
    for _, conn in pairs(connections) do conn:Disconnect() end
    connections = {}
    clearESP()
end

-- 🔧 Методы настройки
function setHighlight(v) settings.HighlightEnabled = v scan() end
function setTracer(v) settings.TracerEnabled = v scan() end
function setNameTag(v) settings.NameTagEnabled = v scan() end
function setFont(font) settings.Font = font scan() end
function setTextSize(size) settings.TextSize = size scan() end
function setTextTransparency(val) settings.TextTransparency = val scan() end
function setTextOutlineTransparency(val) settings.TextOutlineTransparency = val scan() end
function setShowDistance(val) settings.ShowDistance = val scan() end
function setMatchColors(val) settings.MatchColors = val scan() end
function setDistanceSizeRatio(val) settings.DistanceSizeRatio = val scan() end

return {
    EnableESP = enable,
    DisableESP = disable,
    SetHighlight = setHighlight,
    SetTracer = setTracer,
    SetNameTag = setNameTag,

    -- 📦 Текстовые настройки
    SetFont = setFont,
    SetTextSize = setTextSize,
    SetTextTransparency = setTextTransparency,
    SetTextOutlineTransparency = setTextOutlineTransparency,
    SetShowDistance = setShowDistance,
    SetMatchColors = setMatchColors,
    SetDistanceSizeRatio = setDistanceSizeRatio
}
