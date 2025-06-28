local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

Vars48320 = Vars48320 or {}
Vars48320.ItemESP = {}

local targetNames = {
    ["LiveHintBook"] = true,
    ["KeyObtain"] = true,
    ["LiveBreakerPolePickup"] = true,
    ["SmoothieSpawner"] = true,
    ["Shears"] = true
}

local highlightColor = Color3.fromRGB(0, 255, 255)
local outlineColor = Color3.fromRGB(255, 255, 255)

local highlights = {}
local tracers = {}
local connections = {}
local renderConnection

local function createHighlight(model)
    if highlights[model] then return end

    local h = Instance.new("Highlight")
    h.Name = "_ItemESP"
    h.FillColor = highlightColor
    h.OutlineColor = outlineColor
    h.FillTransparency = 0
    h.OutlineTransparency = 0
    h.Adornee = model
    h.Parent = model
    highlights[model] = h
end

local function createTracer(model)
    if tracers[model] then return end

    local line = Drawing.new("Line")
    line.Thickness = 1.5
    line.Color = highlightColor
    line.Visible = false
    tracers[model] = line
end

local function removeAll()
    for model, h in pairs(highlights) do
        if h and h.Parent then
            h:Destroy()
        end
    end
    for model, t in pairs(tracers) do
        if t then
            t:Remove()
        end
    end
    highlights = {}
    tracers = {}
end

local function scanWorkspace()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if targetNames[obj.Name] and obj:IsA("Model") then
            createHighlight(obj)
            createTracer(obj)
        end
    end
end

local function handleNew(child)
    if targetNames[child.Name] and child:IsA("Model") then
        createHighlight(child)
        createTracer(child)
    end
end

function Vars48320.ItemESP:Enable()
    removeAll()
    scanWorkspace()

    table.insert(connections, Workspace.ChildAdded:Connect(handleNew))
    table.insert(connections, Workspace.DescendantAdded:Connect(handleNew))

    renderConnection = RunService.RenderStepped:Connect(function()
        for model, line in pairs(tracers) do
            local adornee = model:FindFirstChildWhichIsA("BasePart")
            if adornee and Camera then
                local pos, onScreen = Camera:WorldToViewportPoint(adornee.Position)
                if onScreen then
                    line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    line.To = Vector2.new(pos.X, pos.Y)
                    line.Visible = true
                else
                    line.Visible = false
                end
            else
                line.Visible = false
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
