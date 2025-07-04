local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local ESP = {}
local settings = {
    Highlight = true,
    Tracer = true,
    NameTag = true,
    Rainbow = false,
    ShowDistance = true
}

local targets = {
    ["KeyObtain"] = true, ["Flashlight"] = true, ["Lockpick"] = true,
    ["Crucifix"] = true, ["Vitamins"] = true, ["Lighter"] = true,
    ["SkeletonKey"] = true, ["Battery"] = true, ["Bandage"] = true,
    ["Smoothie"] = true, ["Candle"] = true, ["Shears"] = true,
    ["AlarmClock"] = true, ["LiveHintBook"] = true, ["LiveBreakerPolePickup"] = true
}

local active = {highlights = {}, tracers = {}, tags = {}}
local connections, renderConnection = {}, nil
local hue = 0

local function getPart(model)
    return model:FindFirstChildWhichIsA("BasePart")
end

local function isIgnored(model)
    return model:IsDescendantOf(LocalPlayer.Character) or model:IsDescendantOf(LocalPlayer.Backpack)
end

local function rainbowColor()
    hue = (hue + 0.0025) % 1
    return Color3.fromHSV(hue, 1, 1)
end

local function clear(model)
    if active.highlights[model] then pcall(function() active.highlights[model]:Destroy() end) end
    if active.tracers[model] then pcall(function() active.tracers[model]:Remove() end) end
    if active.tags[model] then pcall(function() active.tags[model]:Destroy() end) end
    active.highlights[model] = nil
    active.tracers[model] = nil
    active.tags[model] = nil
end

local function addHighlight(model)
    if not settings.Highlight then return end
    if active.highlights[model] then return end

    local h = Instance.new("Highlight")
    h.Name = "_ESP_HL"
    h.FillColor = settings.Rainbow and rainbowColor() or Color3.fromRGB(0, 255, 255)
    h.OutlineColor = Color3.fromRGB(255, 255, 255)
    h.FillTransparency = 1
    h.OutlineTransparency = 1
    h.Adornee = model
    h.Parent = model

    TweenService:Create(h, TweenInfo.new(0.25), {
        FillTransparency = 0.75,
        OutlineTransparency = 0
    }):Play()

    active.highlights[model] = h
end

local function addTracer(model)
    if not settings.Tracer then return end
    if active.tracers[model] then return end

    local line = Drawing.new("Line")
    line.Thickness = 1.5
    line.Color = settings.Rainbow and rainbowColor() or Color3.fromRGB(0, 255, 255)
    line.Visible = false

    active.tracers[model] = line
end

local function addNameTag(model)
    if not settings.NameTag then return end
    if active.tags[model] then return end

    local part = getPart(model)
    if not part then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "_ESP_Tag"
    billboard.Adornee = part
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 1.5, 0)
    billboard.Parent = model

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0.5
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    label.Text = model.Name
    label.Parent = billboard

    active.tags[model] = billboard
end

local function process(model)
    if not targets[model.Name] then return end
    if isIgnored(model) then return end
    addHighlight(model)
    addTracer(model)
    addNameTag(model)
end

local function updateRender()
    for model, line in pairs(active.tracers) do
        if not model or not model.Parent or not getPart(model) then clear(model) continue end
        local part = getPart(model)
        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
        line.Visible = onScreen
        if onScreen then
            line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
            line.To = Vector2.new(screenPos.X, screenPos.Y)
            line.Color = settings.Rainbow and rainbowColor() or Color3.fromRGB(0, 255, 255)
        end
    end

    for model, tag in pairs(active.tags) do
        if tag and tag:FindFirstChildOfClass("TextLabel") then
            local part = getPart(model)
            if part and settings.ShowDistance then
                local dist = math.floor((part.Position - Camera.CFrame.Position).Magnitude)
                tag.TextLabel.Text = model.Name .. " [" .. dist .. "m]"
            end
        end
    end

    for model, hl in pairs(active.highlights) do
        if hl then
            hl.FillColor = settings.Rainbow and rainbowColor() or Color3.fromRGB(0, 255, 255)
            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        end
    end
end

local function scan()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then process(obj) end
    end
end

local function onAdd(obj)
    task.wait(0.1)
    if obj:IsA("Model") then process(obj) end
end

function ESP:Enable()
    ESP:Disable()
    scan()
    table.insert(connections, Workspace.DescendantAdded:Connect(onAdd))
    renderConnection = RunService.RenderStepped:Connect(updateRender)
end

function ESP:Disable()
    if renderConnection then renderConnection:Disconnect() end
    for _, c in pairs(connections) do c:Disconnect() end
    connections = {}
    for m in pairs(active.highlights) do clear(m) end
end

function ESP:ToggleRainbow(v) settings.Rainbow = v end
function ESP:ToggleDistance(v) settings.ShowDistance = v end
function ESP:ToggleTracer(v) settings.Tracer = v end
function ESP:ToggleHighlight(v) settings.Highlight = v end
function ESP:ToggleNameTag(v) settings.NameTag = v end

return ESP
