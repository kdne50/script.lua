-- Обновлённая ESP-библиотека
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
    ["Bread"] = true, ["Cheese"] = true
}

local entityTargets = {
    A120 = "Main",
    A60 = "Main",
    RushMoving = "RushNew",
    AmbushMoving = "RushNew",
    Eyes = "Core",
    BackdoorRush = "Main",
    BackdoorLookman = "Core",
}

local highlightColor = Color3.fromRGB(0, 255, 255)
local outlineColor = Color3.fromRGB(255, 255, 255)

local highlights, tracers, nametags, adornments = {}, {}, {}, {}
local connections, renderConnection = {}, nil

local settings = {
    HighlightEnabled = true,
    TracerEnabled = true,
    NameTagEnabled = false,
    EntityESPEnabled = false,

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
    for _, a in pairs(adornments) do pcall(function() a:Destroy() end) end
    highlights, tracers, nametags, adornments = {}, {}, {}, {}
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

local function addEntityAdornment(model)
    if not settings.EntityESPEnabled then return end
    local partName = entityTargets[model.Name]
    if not partName then return end

    local part = model:FindFirstChild(partName)
    if part and not adornments[model] then
        local adorn = Instance.new("SphereHandleAdornment")
        adorn.Adornee = part
        adorn.Color3 = highlightColor
        adorn.Transparency = 0.5
        adorn.Radius = 4
        adorn.AlwaysOnTop = true
        adorn.ZIndex = 10
        adorn.AdornCullingMode = Enum.AdornCullingMode.AlwaysOn
        adorn.Parent = Workspace
        adornments[model] = adorn
    end
end

local function processModel(model)
    if model:IsA("Model") then
        if targetNames[model.Name] and not isIgnored(model) then
            addHighlight(model)
            addTracer(model)
            addNameTag(model)
        end
        if entityTargets[model.Name] then
            addEntityAdornment(model)
        end
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

local function startRender()
    if renderConnection then renderConnection:Disconnect() end
    renderConnection = RunService.RenderStepped:Connect(function()
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local currentFOV = Camera.FieldOfView
        local fovRatio = currentFOV / baseFOV

        for model, line in pairs(tracers) do
            local part = model:FindFirstChildWhichIsA("BasePart")
            if not part or isIgnored(model) or not settings.TracerEnabled then
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
            local part = model:FindFirstChildWhichIsA("BasePart")
            local label = tag:FindFirstChildOfClass("TextLabel")
            if not part or not label or not settings.NameTagEnabled or isIgnored(model) then
                pcall(function() tag:Destroy() end)
                nametags[model] = nil
            else
                if settings.ShowDistance then
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
    end)
end

-- Автозапуск + подписки
scan()
table.insert(connections, Workspace.DescendantAdded:Connect(onNewChild))
table.insert(connections, Workspace.DescendantRemoving:Connect(function(obj)
    if highlights[obj] then pcall(function() highlights[obj]:Destroy() end) highlights[obj] = nil end
    if tracers[obj] then pcall(function() tracers[obj]:Remove() end) tracers[obj] = nil end
    if nametags[obj] then pcall(function() nametags[obj]:Destroy() end) nametags[obj] = nil end
    if adornments[obj] then pcall(function() adornments[obj]:Destroy() end) adornments[obj] = nil end
end))
startRender()

-- Интерфейс управления
return {
    SetHighlight = function(v) settings.HighlightEnabled = v scan() end,
    SetTracer = function(v) settings.TracerEnabled = v scan() end,
    SetNameTag = function(v) settings.NameTagEnabled = v scan() end,
    SetEntityESP = function(v) settings.EntityESPEnabled = v scan() end,
    SetFont = function(v) settings.Font = v scan() end,
    SetTextSize = function(v) settings.TextSize = v scan() end,
    SetTextTransparency = function(v) settings.TextTransparency = v scan() end,
    SetTextOutlineTransparency = function(v) settings.TextOutlineTransparency = v scan() end,
    SetShowDistance = function(v) settings.ShowDistance = v scan() end,
    SetMatchColors = function(v) settings.MatchColors = v scan() end,
    SetDistanceSizeRatio = function(v) settings.DistanceSizeRatio = v scan() end,
}
