local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

Vars48320 = Vars48320 or {}
Vars48320.ItemESP = {}

Vars48320.ItemESP.Settings = {
    HighlightEnabled = true,
    TracerEnabled = true
}

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
    ["Straplight"] = true
}

local highlightColor = Color3.fromRGB(0, 255, 255)
local outlineColor = Color3.fromRGB(255, 255, 255)

local highlights = {}
local tracers = {}
local connections = {}
local renderConnection

local function isIgnored(model)
    return model:IsDescendantOf(LocalPlayer.Backpack) or model:IsDescendantOf(LocalPlayer.Character)
end

local function createHighlight(model)
    if highlights[model] or isIgnored(model) then return end

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
    if tracers[model] or not Vars48320.ItemESP.Settings.TracerEnabled or isIgnored(model) then return end

    local line = Drawing.new("Line")
    line.Thickness = 1.5
    line.Color = highlightColor
    line.Visible = false
    tracers[model] = line
end

local function removeAll()
    for model, h in pairs(highlights) do
        if h then
            pcall(function() h:Destroy() end)
        end
    end
    for model, t in pairs(tracers) do
        if t then
            pcall(function() t:Remove() end)
        end
    end
    highlights = {}
    tracers = {}
end

local function scanWorkspace()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if targetNames[obj.Name] and obj:IsA("Model") and not isIgnored(obj) then
            if Vars48320.ItemESP.Settings.HighlightEnabled then
                createHighlight(obj)
            end
            if Vars48320.ItemESP.Settings.TracerEnabled then
                createTracer(obj)
            end
        end
    end
end

local function handleNew(child)
    if targetNames[child.Name] and child:IsA("Model") and not isIgnored(child) then
        if Vars48320.ItemESP.Settings.HighlightEnabled then
            createHighlight(child)
        end
        if Vars48320.ItemESP.Settings.TracerEnabled then
            createTracer(child)
        end
    end
end

function Vars48320.ItemESP:Enable()
    self:Disable()
    scanWorkspace()

    table.insert(connections, Workspace.DescendantAdded:Connect(handleNew))
    table.insert(connections, Workspace.ChildAdded:Connect(handleNew))

    renderConnection = RunService.RenderStepped:Connect(function()
        for model, line in pairs(tracers) do
            if not model or not model.Parent or isIgnored(model) or not Vars48320.ItemESP.Settings.TracerEnabled then
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

        for model, highlight in pairs(highlights) do
            if not model or not model.Parent or isIgnored(model) then
                pcall(function() highlight:Destroy() end)
                highlights[model] = nil
            elseif not Vars48320.ItemESP.Settings.HighlightEnabled then
                pcall(function() highlight:Destroy() end)
                highlights[model] = nil
            end
        end
    end)
end

function Vars48320.ItemESP:Disable()
    if renderConnection then
        renderConnection:Disconnect()
        renderConnection = nil
    end
    for _, conn in pairs(connections) do
        conn:Disconnect()
    end
    connections = {}
    removeAll()
end
