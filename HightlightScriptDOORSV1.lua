--// ✅ Улучшенный Item ESP с корректным удалением и повторной инициализацией после смерти

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
    ["FuseObtain"] = true, ["BandagePack"] = true, ["Bulklight"] = true, ["CrucifixWall"] = true,
    ["Straplight"] = true, ["Glowsticks"] = true, ["BatteryPack"] = true,
    ["LaserPointer"] = true, ["ElectricalKeyObtain"] = true, ["Starlight Bottle"] = true,
    ["Starlight Jug"] = true, ["Shakelight"] = true, ["Gween Soda"] = true,
    ["Bread"] = true, ["Cheese"] = true, ["StarVial"] = true, ["StarBottle"] = true, ["TimerLever"] = true, 
    ["Lantern"] = true, ["BigPropTool"] = true, ["Multitool"] = true, ["GoldGun"] = true, ["RiftCandle"] = true,
    ["RiftJar"] = true, ["TipJar"] = true, ["Knockbomb"] = true, ["Bomb"] = true, ["Donut"] = true, ["BigBomb"] = true,
    ["StarJug"] = true, ["Nanner"] = true, ["SnakeBox"] = true, ["AloeVera"] = true, ["Compass"] = true, ["Lotus"] = true, ["NannerPeel"] = true, ["HolyGrenade"] = true, ["StopSign"] = true,
}

local highlightColor = Color3.fromRGB(0, 255, 255)
local outlineColor = Color3.fromRGB(255, 255, 255)

local highlights, tracers, nametags = {}, {}, {}
local connections, renderConnection = {}, nil

local settings = {
    HighlightEnabled = true,
    TracerEnabled = true,
    NameTagEnabled = false,

    TextSize = 20,
    Font = Enum.Font.Oswald,
    TextTransparency = 0,
    TextOutlineTransparency = 0.5,
    ShowDistance = false,
    DistanceSizeRatio = 1.0,
    MatchColors = true
}

local baseFOV = Camera.FieldOfView
local baseTextSize = 24
local baseBillboardSize = UDim2.new(0, 200, 0, 50)

local function isHeldByPlayer(model)
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character and model:IsDescendantOf(player.Character) then return true end
        if player:FindFirstChild("Backpack") and model:IsDescendantOf(player.Backpack) then return true end
    end
    return false
end

local function isIgnored(model)
    return model:IsDescendantOf(LocalPlayer.Backpack) or model:IsDescendantOf(LocalPlayer.Character) or isHeldByPlayer(model)
end

local function clearESP()
    for _, h in pairs(highlights) do pcall(function() h:Destroy() end) end
    for _, t in pairs(tracers) do pcall(function() t:Remove() end) end
    for _, n in pairs(nametags) do pcall(function() n:Destroy() end) end
    highlights, tracers, nametags = {}, {}, {}
end

local function removeModelRefs(model)
    if highlights[model] then pcall(function() highlights[model]:Destroy() end) highlights[model] = nil end
    if tracers[model] then pcall(function() tracers[model]:Remove() end) tracers[model] = nil end
    if nametags[model] then pcall(function() nametags[model]:Destroy() end) nametags[model] = nil end
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
        label.Text = model.Name

        nametags[model] = billboard
    end
end

local function processModel(model)
    if targetNames[model.Name] and model:IsA("Model") and model:IsDescendantOf(Workspace) and not isIgnored(model) then
        addHighlight(model)
        addTracer(model)
        addNameTag(model)
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

local function onNewChild(obj)
    task.delay(0.05, function()
        processModel(obj)
    end)
end

local function enable()
    disable()
    scan()

    table.insert(connections, Workspace.DescendantAdded:Connect(onNewChild))
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

        for model, tag in pairs(nametags) do
            if not model or not model:IsDescendantOf(Workspace) or isIgnored(model) or not settings.NameTagEnabled then
                pcall(function() tag:Destroy() end)
                nametags[model] = nil
            else
                local part = model:FindFirstChildWhichIsA("BasePart")
                local label = tag:FindFirstChildOfClass("TextLabel")
                if part and label then
                    if root and settings.ShowDistance then
                        local distance = math.floor((root.Position - part.Position).Magnitude)
                        label.Text = string.format("%s [%d]", model.Name, distance)
                    else
                        label.Text = model.Name
                    end
                    local newTextSize = math.clamp(baseTextSize * fovRatio, 12, 48)
                    label.TextSize = newTextSize

                    local scaleFactor = newTextSize / baseTextSize
                    tag.Size = UDim2.new(baseBillboardSize.X.Scale, baseBillboardSize.X.Offset * scaleFactor,
                                         baseBillboardSize.Y.Scale, baseBillboardSize.Y.Offset * scaleFactor)
                end
            end
        end
    end)
end

function disable()
    if renderConnection then renderConnection:Disconnect() renderConnection = nil end
    for _, conn in pairs(connections) do conn:Disconnect() end
    connections = {}
    clearESP()
end

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
    SetFont = setFont,
    SetTextSize = setTextSize,
    SetTextTransparency = setTextTransparency,
    SetTextOutlineTransparency = setTextOutlineTransparency,
    SetShowDistance = setShowDistance,
    SetMatchColors = setMatchColors,
    SetDistanceSizeRatio = setDistanceSizeRatio
}
