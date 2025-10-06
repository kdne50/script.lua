-- 🧠 HightlightsLibrary.lua (финальная версия)
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

--------------------------------------------------
-- === СПИСКИ === --
--------------------------------------------------
local TargetItemsHighlights51 = {
    ["LiveHintBook"] = "Book", ["KeyObtain"] = "Key", ["LiveBreakerPolePickup"] = "Breaker",
    ["SmoothieSpawner"] = "Smoothie", ["Shears"] = "Shears", ["Lighter"] = "Lighter",
    ["Crucifix"] = "Crucifix", ["Lockpick"] = "Lockpick", ["Battery"] = "Battery",
    ["Vitamins"] = "Vitamins", ["Smoothie"] = "Smoothie", ["AlarmClock"] = "Alarm-Clock",
    ["Bandage"] = "Bandage", ["Candle"] = "Candle", ["LibraryHintPaper"] = "Paper",
    ["SkeletonKey"] = "SkeletonKey", ["Flashlight"] = "Flashlight", ["RiftSmoothie"] = "Rift-Smoothie",
    ["FuseObtain"] = "Fuse", ["BandagePack"] = "Bandage-Pack", ["Bulklight"] = "Bulklight",
    ["CrucifixWall"] = "Crucifix", ["Straplight"] = "Straplight", ["Glowsticks"] = "Glowsticks",
    ["BatteryPack"] = "Battery-Pack", ["LaserPointer"] = "Laser", ["ElectricalKeyObtain"] = "Key",
    ["Starlight Bottle"] = "Starlight-Bottle", ["Starlight Jug"] = "Starlight-Jug",
    ["Shakelight"] = "Shakelight", ["Gween Soda"] = "Gween-Soda", ["Bread"] = "Bread",
    ["Cheese"] = "Cheese", ["StarVial"] = "Star-Vial", ["StarBottle"] = "Star-Bottle",
    ["TimerLever"] = "Lever", ["Lantern"] = "Lantern", ["BigPropTool"] = "BigPropTool",
    ["Multitool"] = "Multi-Tool", ["GoldGun"] = "Gun", ["RiftCandle"] = "Rift-Candle",
    ["RiftJar"] = "Rift-Jar", ["TipJar"] = "Tip-Jar", ["Knockbomb"] = "Knock-Bomb",
    ["Bomb"] = "Bomb", ["Donut"] = "Donut", ["BigBomb"] = "Big-Bomb", ["StarJug"] = "Star-Jug",
    ["Nanner"] = "Nanner", ["SnakeBox"] = "Box", ["AloeVera"] = "Aloe-Vera", ["Compass"] = "Compass",
    ["Lotus"] = "Big-Lotus", ["NannerPeel"] = "NannerPeel", ["HolyGrenade"] = "Holy-Grenade",
    ["StopSign"] = "Stop-Sign", ["StardustPickup"] = "Stardust", ["GoldPile"] = "Gold",
    ["LotusPetalPickup"] = "Lotus", ["GlitchCube"] = "Glitch-Fragment",
}

-- дверь
local TargetOtherThingsHighlights51 = { ["Door"] = true }

-- шкафы, кровати и т.д.
local TargetOtherThingsForClosetAndMoreHighlights51 = {
    ["Wardrobe"] = true, ["Locker_Large"] = true, ["Rooms_Locker"] = true,
    ["Backdoor_Wardrobe"] = true, ["Bed"] = true, ["DoubleBed"] = true,
    ["Toolshed"] = true, ["CircularVent"] = true, ["Rooms_Locker_Fridge"] = true,
    ["RetroWardrobe"] = true, ["Dumpster"] = true, ["Double_Bed"] = true,
}

--------------------------------------------------
-- === НАСТРОЙКИ === --
--------------------------------------------------
local settings = {
    HighlightEnabled = true, TracerEnabled = true, NameTagEnabled = true,
    ArrowsEnabled = false, ShowDistance = false, MatchColors = true,
}

-- цвета для разных типов
local itemESPColor = Color3.fromRGB(0, 255, 0)
local doorESPColor = Color3.fromRGB(255, 128, 0)
local closetESPColor = Color3.fromRGB(0, 120, 0)
local outlineColor = Color3.fromRGB(255, 255, 255)

--------------------------------------------------
-- === ПЕРЕМЕННЫЕ === --
--------------------------------------------------
local highlights, tracers, nametags, arrows = {}, {}, {}, {}
local connections, renderConnection = {}, nil

-- Arrow UI
local ArrowsFrame = Instance.new("Frame")
ArrowsFrame.Name = "ArrowsFrame"
ArrowsFrame.Size = UDim2.new(1, 0, 1, 0)
ArrowsFrame.BackgroundTransparency = 1
ArrowsFrame.Parent = CoreGui

local ArrowTemplate = Instance.new("ImageLabel")
ArrowTemplate.Image = "rbxassetid://2418687610"
ArrowTemplate.Size = UDim2.new(0, 72, 0, 72)
ArrowTemplate.AnchorPoint = Vector2.new(0.5, 0.5)
ArrowTemplate.BackgroundTransparency = 1
local ratio = Instance.new("UIAspectRatioConstraint", ArrowTemplate)
ratio.AspectRatio = 0.75

--------------------------------------------------
-- === СЛУЖЕБНЫЕ === --
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
-- === ФУНКЦИИ === --
--------------------------------------------------
local function clearESP()
    for _, h in pairs(highlights) do pcall(function() h:Destroy() end) end
    for _, t in pairs(tracers) do pcall(function() t:Remove() end) end
    for _, n in pairs(nametags) do pcall(function() n:Destroy() end) end
    for _, a in pairs(arrows) do pcall(function() a:Destroy() end) end
    highlights, tracers, nametags, arrows = {}, {}, {}, {}
end

local function addHighlight(model, color)
    if highlights[model] then return end
    local h = Instance.new("Highlight")
    h.FillColor = color
    h.OutlineColor = outlineColor
    h.FillTransparency = 0.8
    h.OutlineTransparency = 0
    h.Adornee = model
    h.Parent = model
    highlights[model] = h
end

--------------------------------------------------
-- === PROCESS === --
--------------------------------------------------
local function processModel(model)
    if isIgnored(model) then return end

    -- предметы
    if TargetItemsHighlights51[model.Name] then
        addHighlight(model, itemESPColor)
        return
    end

    -- дверь
    if TargetOtherThingsHighlights51[model.Name] then
        local doorPart = model:FindFirstChild("Door")
        if doorPart then addHighlight(doorPart, doorESPColor) end
        return
    end

    -- шкафы / кровати
    if TargetOtherThingsForClosetAndMoreHighlights51[model.Name] then
        addHighlight(model, closetESPColor)
        return
    end
end

local function scan()
    clearESP()
    for _, obj in pairs(Workspace:GetDescendants()) do
        processModel(obj)
    end
end

--------------------------------------------------
-- === ОСНОВНОЙ ЦИКЛ === --
--------------------------------------------------
local function enable()
    disable()
    scan()
    table.insert(connections, Workspace.DescendantAdded:Connect(function(obj)
        task.defer(processModel, obj)
    end))
end

function disable()
    if renderConnection then renderConnection:Disconnect() renderConnection = nil end
    for _, conn in pairs(connections) do conn:Disconnect() end
    connections = {}
    clearESP()
end

--------------------------------------------------
-- === ОБНОВЛЕНИЕ ЦВЕТОВ === --
--------------------------------------------------
local function updateColorForAll(colorType, newColor)
    if colorType == "Item" then itemESPColor = newColor end
    if colorType == "Door" then doorESPColor = newColor end
    if colorType == "Closet" then closetESPColor = newColor end

    for model, highlight in pairs(highlights) do
        if TargetItemsHighlights51[model.Name] and colorType == "Item" then
            highlight.FillColor = newColor
        elseif TargetOtherThingsHighlights51[model.Name] and colorType == "Door" then
            highlight.FillColor = newColor
        elseif TargetOtherThingsForClosetAndMoreHighlights51[model.Name] and colorType == "Closet" then
            highlight.FillColor = newColor
        end
    end
end

--------------------------------------------------
-- === ВОЗВРАТ === --
--------------------------------------------------
return {
    EnableESP = enable,
    DisableESP = disable,

    EnableItemESP = enable,
    DisableItemESP = disable,
    EnableDoorESP = enable,
    DisableDoorESP = disable,
    EnableClosetESP = enable,
    DisableClosetESP = disable,

    UpdateItemESPColor = function(c) updateColorForAll("Item", c) end,
    UpdateDoorESPColor = function(c) updateColorForAll("Door", c) end,
    UpdateClosetESPColor = function(c) updateColorForAll("Closet", c) end,

    TargetItemsHighlights51 = TargetItemsHighlights51,
    TargetOtherThingsHighlights51 = TargetOtherThingsHighlights51,
    TargetOtherThingsForClosetAndMoreHighlights51 = TargetOtherThingsForClosetAndMoreHighlights51
}
