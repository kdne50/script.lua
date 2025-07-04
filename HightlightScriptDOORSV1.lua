-- ✅ Оптимизированный ESP с Highlight, Tracer, Billboard + анимации и авто-очисткой

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

local highlights, tracers, nametags, animations = {}, {}, {}, {}
local connections, renderConnection = {}, nil

local settings = {
    HighlightEnabled = true,
    TracerEnabled = true,
    NameTagEnabled = true
}

local function isIgnored(model)
    return model:IsDescendantOf(LocalPlayer.Backpack) or model:IsDescendantOf(LocalPlayer.Character)
end

local function clearESP()
    for model, v in pairs(highlights) do pcall(function() v:Destroy() end) end
    for model, v in pairs(tracers) do pcall(function() v:Remove() end) end
    for model, v in pairs(nametags) do pcall(function() v:Destroy() end) end
    for model, v in pairs(animations) do if v then v.running = false end end
    highlights, tracers, nametags, animations = {}, {}, {}, {}
end

local function addHighlight(model)
    if highlights[model] or not settings.HighlightEnabled then return end
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

local function addRotation(model)
    if animations[model] or not model:IsA("Model") then return end
    local primary = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not primary then return end

    local running = true
    animations[model] = {running = running}
    task.spawn(function()
        while running and model and model.Parent do
            primary.CFrame = primary.CFrame * CFrame.Angles(0, math.rad(1), 0)
            task.wait(0.03)
        end
    end)
end

local function processModel(model)
    if not targetNames[model.Name] or not model:IsA("Model") or isIgnored(model) then return end
    addHighlight(model)
    addTracer(model)
    addNameTag(model)
    addRotation(model)
end

local function scan()
    clearESP()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        processModel(obj)
    end
end

local function onNewChild(obj)
    task.delay(0.05, function() processModel(obj) end)
end

local function enable()
    disable()
    scan()
    table.insert(connections, Workspace.DescendantAdded:Connect(onNewChild))

    renderConnection = RunService.RenderStepped:Connect(function()
        for model, line in pairs(tracers) do
            local part = model:FindFirstChildWhichIsA("BasePart")
            if not model or not model.Parent or isIgnored(model) or not settings.TracerEnabled or not part then
                pcall(function() line:Remove() end)
                tracers[model] = nil
            else
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                line.To = Vector2.new(pos.X, pos.Y)
                line.Visible = onScreen
            end
        end
        for model, tag in pairs(nametags) do
            if not model or not model.Parent or isIgnored(model) or not settings.NameTagEnabled then
                pcall(function() tag:Destroy() end)
                nametags[model] = nil
            end
        end
    end)
end

function disable()
    if renderConnection then renderConnection:Disconnect() end
    for _, conn in ipairs(connections) do conn:Disconnect() end
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

return {
    EnableESP = enable,
    DisableESP = disable,
    SetHighlight = setHighlight,
    SetTracer = setTracer,
    SetNameTag = setNameTag
}
