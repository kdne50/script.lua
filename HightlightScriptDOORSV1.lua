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

local highlights = {}
local tracers = {}
local nametags = {}

local connections = {}
local renderConnection = nil

local settings = {
    HighlightEnabled = true,
    TracerEnabled = true,
    NameTagEnabled = false,
    RainbowHighlight = false,
}

local function isIgnored(model)
    return model:IsDescendantOf(LocalPlayer.Backpack) or model:IsDescendantOf(LocalPlayer.Character)
end

local function clearESP()
    for model, h in pairs(highlights) do
        if h and h.Parent then
            pcall(function() h:Destroy() end)
        end
    end
    highlights = {}

    for model, line in pairs(tracers) do
        if line then
            pcall(function() line:Remove() end)
        end
    end
    tracers = {}

    for model, billboard in pairs(nametags) do
        if billboard and billboard.Parent then
            pcall(function() billboard:Destroy() end)
        end
    end
    nametags = {}
end

local function addHighlight(model)
    if highlights[model] or not settings.HighlightEnabled then return end

    local basePart = model:FindFirstChildWhichIsA("BasePart")
    if not basePart then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "_ItemESP"
    highlight.Adornee = model
    highlight.FillColor = highlightColor
    highlight.OutlineColor = outlineColor
    highlight.FillTransparency = 0.8
    highlight.OutlineTransparency = 0
    highlight.Parent = model

    highlights[model] = highlight
end

local function addTracer(model)
    if tracers[model] or not settings.TracerEnabled then return end

    local basePart = model:FindFirstChildWhichIsA("BasePart")
    if not basePart then return end

    -- Проверяем доступность Drawing API
    if not (Drawing and Drawing.new) then return end

    local line = Drawing.new("Line")
    line.Thickness = 1.5
    line.Color = highlightColor
    line.Visible = false

    tracers[model] = line
end

local function addNameTag(model)
    if nametags[model] or not settings.NameTagEnabled then return end

    local basePart = model:FindFirstChildWhichIsA("BasePart")
    if not basePart then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "_ESP_NameTag"
    billboard.Adornee = basePart
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, -0.5, 0)
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

local function processModel(model)
    if not model or not model.Parent then return end
    if not targetNames[model.Name] then return end
    if not model:IsA("Model") then return end
    if isIgnored(model) then return end

    addHighlight(model)
    addTracer(model)
    addNameTag(model)
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

local function HSVToRGB(h, s, v)
    local c = v * s
    local x = c * (1 - math.abs((h * 6) % 2 - 1))
    local m = v - c
    local r, g, b

    if h < 1/6 then
        r, g, b = c, x, 0
    elseif h < 2/6 then
        r, g, b = x, c, 0
    elseif h < 3/6 then
        r, g, b = 0, c, x
    elseif h < 4/6 then
        r, g, b = 0, x, c
    elseif h < 5/6 then
        r, g, b = x, 0, c
    else
        r, g, b = c, 0, x
    end

    return Color3.new(r + m, g + m, b + m)
end

local hue = 0

local function enable()
    disable()
    scan()
    table.insert(connections, Workspace.DescendantAdded:Connect(onNewChild))

    renderConnection = RunService.RenderStepped:Connect(function(dt)
        hue = (hue + dt * 0.5) % 1 -- скорость радужного эффекта

        -- Обновляем Highlight цвета
        for model, h in pairs(highlights) do
            if h and h.Parent then
                if settings.RainbowHighlight then
                    local color = HSVToRGB(hue, 1, 1)
                    h.FillColor = color
                    h.OutlineColor = color:lerp(Color3.new(1,1,1), 0.4)
                else
                    h.FillColor = highlightColor
                    h.OutlineColor = outlineColor
                end
            end
        end

        -- Обновляем Tracers
        for model, line in pairs(tracers) do
            if not model or not model.Parent or isIgnored(model) or not settings.TracerEnabled then
                pcall(function() line:Remove() end)
                tracers[model] = nil
            else
                local basePart = model:FindFirstChildWhichIsA("BasePart")
                if basePart then
                    local pos, onScreen = Camera:WorldToViewportPoint(basePart.Position)
                    line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    line.To = Vector2.new(pos.X, pos.Y)
                    line.Visible = onScreen
                else
                    line.Visible = false
                end
            end
        end

        -- Обновляем NameTags
        for model, billboard in pairs(nametags) do
            if not model or not model.Parent or isIgnored(model) or not settings.NameTagEnabled then
                pcall(function() billboard:Destroy() end)
                nametags[model] = nil
            end
        end
    end)
end

function disable()
    if renderConnection then
        renderConnection:Disconnect()
        renderConnection = nil
    end

    for _, conn in pairs(connections) do
        if conn.Connected then
            conn:Disconnect()
        end
    end
    connections = {}

    clearESP()
end

function setHighlight(v)
    settings.HighlightEnabled = v
    scan()
end

function setTracer(v)
    settings.TracerEnabled = v
    scan()
end

function setNameTag(v)
    settings.NameTagEnabled = v
    scan()
end

function setRainbowHighlight(v)
    settings.RainbowHighlight = v
    -- Немного обновим цвета сразу при переключении
    for model, h in pairs(highlights) do
        if h and h.Parent then
            if settings.RainbowHighlight then
                local color = HSVToRGB(hue, 1, 1)
                h.FillColor = color
                h.OutlineColor = color:lerp(Color3.new(1,1,1), 0.4)
            else
                h.FillColor = highlightColor
                h.OutlineColor = outlineColor
            end
        end
    end
end

return {
    EnableESP = enable,
    DisableESP = disable,
    SetHighlight = setHighlight,
    SetTracer = setTracer,
    SetNameTag = setNameTag,
    SetRainbowHighlight = setRainbowHighlight,
}
