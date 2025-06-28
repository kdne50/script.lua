local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local targetNames = {
    ["LiveHintBook"] = true,
    ["KeyObtain"] = true,
    ["LiveBreakerPolePickup"] = true,
    ["SmoothieSpawner"] = true,
    ["Shears"] = true,
    ["Lighter"] = true,
    ["Crucifix"] = true,
    ["Lockpick"] = true,
    ["Battery"] = true,
    ["Vitamins"] = true,
    ["Smoothie"] = true,
    ["AlarmClock"] = true,
    ["Bandage"] = true,
    ["Candle"] = true,
    ["LibraryHintPaper"] = true,
    ["SkeletonKey"] = true,
    ["Flashlight"] = true,
    ["RiftSmoothie"] = true,
    ["FuseObtain"] = true,
    ["BandagePack"] = true,
    ["Bulklight"] = true,
    ["Straplight"] = true,
    ["Glowsticks"] = true,
    ["BatteryPack"] = true,
    ["LaserPointer"] = true
}

local highlightColor = Color3.fromRGB(0, 255, 255)
local outlineColor = Color3.fromRGB(255, 255, 255)

local highlights = {}
local tracers = {}
local nametags = {}
local connections = {}
local renderConnection

local settings = {
    HighlightEnabled = true,
    TracerEnabled = true,
    NameTagEnabled = false
}

local function isIgnored(model)
    return model:IsDescendantOf(LocalPlayer.Backpack) or model:IsDescendantOf(LocalPlayer.Character)
end

local function createHighlight(model)
    if highlights[model] or isIgnored(model) or not settings.HighlightEnabled then return end
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

local function createTracer(model)
    if tracers[model] or isIgnored(model) or not settings.TracerEnabled then return end
    local line = Drawing.new("Line")
    line.Thickness = 1.5
    line.Color = highlightColor
    line.Visible = false
    tracers[model] = line
end

local function createNameTag(model)
    if nametags[model] or isIgnored(model) or not settings.NameTagEnabled then return end
    local text = Drawing.new("Text")
    text.Size = 14
    text.Center = true
    text.Outline = true
    text.OutlineColor = Color3.new(0, 0, 0)
    text.Color = Color3.fromRGB(255, 255, 255)
    text.Text = model.Name
    text.Visible = false
    nametags[model] = text
end

local function removeAll()
    for _, h in pairs(highlights) do pcall(function() h:Destroy() end) end
    for _, t in pairs(tracers) do pcall(function() t:Remove() end) end
    for _, n in pairs(nametags) do pcall(function() n:Remove() end) end
    highlights, tracers, nametags = {}, {}, {}
end

local function scanWorkspace()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if targetNames[obj.Name] and obj:IsA("Model") and not isIgnored(obj) then
            createHighlight(obj)
            createTracer(obj)
            createNameTag(obj)
        end
    end
end

local function handleNew(child)
    if targetNames[child.Name] and child:IsA("Model") and not isIgnored(child) then
        createHighlight(child)
        createTracer(child)
        createNameTag(child)
    end
end

local function enableESP()
    disableESP()
    scanWorkspace()
    table.insert(connections, Workspace.DescendantAdded:Connect(handleNew))
    table.insert(connections, Workspace.ChildAdded:Connect(handleNew))

    renderConnection = RunService.RenderStepped:Connect(function()
        for model, tracer in pairs(tracers) do
            if not model or not model.Parent or isIgnored(model) or not settings.TracerEnabled then
                pcall(function() tracer:Remove() end)
                tracers[model] = nil
            else
                local part = model:FindFirstChildWhichIsA("BasePart")
                if part then
                    local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    tracer.To = Vector2.new(pos.X, pos.Y)
                    tracer.Visible = onScreen
                else
                    tracer.Visible = false
                end
            end
        end

        for model, tag in pairs(nametags) do
            if not model or not model.Parent or isIgnored(model) or not settings.NameTagEnabled then
                pcall(function() tag:Remove() end)
                nametags[model] = nil
            else
                local part = model:FindFirstChildWhichIsA("BasePart")
                if part then
                    local pos, onScreen = Camera:WorldToViewportPoint(part.Position + Vector3.new(0, 2, 0))
                    tag.Position = Vector2.new(pos.X, pos.Y)
                    tag.Visible = onScreen
                else
                    tag.Visible = false
                end
            end
        end

        for model, highlight in pairs(highlights) do
            if not model or not model.Parent or isIgnored(model) or not settings.HighlightEnabled then
                pcall(function() highlight:Destroy() end)
                highlights[model] = nil
            end
        end

        if settings.HighlightEnabled then
            for _, model in pairs(Workspace:GetDescendants()) do
                if targetNames[model.Name] and model:IsA("Model") and not highlights[model] and not isIgnored(model) then
                    createHighlight(model)
                end
            end
        end
    end)
end

function disableESP()
    if renderConnection then renderConnection:Disconnect() end
    for _, conn in pairs(connections) do conn:Disconnect() end
    connections = {}
    removeAll()
end

function enableNameTags()
    settings.NameTagEnabled = true
end

function disableNameTags()
    settings.NameTagEnabled = false
    for _, tag in pairs(nametags) do
        pcall(function() tag:Remove() end)
    end
    nametags = {}
end

function setHighlightEnabled(state)
    settings.HighlightEnabled = state
end

function setTracerEnabled(state)
    settings.TracerEnabled = state
end

function setNameTagEnabled(state)
    if state then
        enableNameTags()
    else
        disableNameTags()
    end
end

-- Возврат функций наружу (можно подключить в библиотеку):
return {
    EnableESP = enableESP,
    DisableESP = disableESP,
    SetHighlight = setHighlightEnabled,
    SetTracer = setTracerEnabled,
    SetNameTag = setNameTagEnabled
}
