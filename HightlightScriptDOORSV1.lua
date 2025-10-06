-- ✅ ДОРАБОТАННАЯ ВЕРСИЯ
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

--------------------------------------------------
-- == ПАРАМЕТРЫ ==
--------------------------------------------------
local highlightColor = Color3.fromRGB(0, 255, 255)
local outlineColor = Color3.fromRGB(255, 255, 255)
local baseFOV = Camera.FieldOfView
local baseTextSize = 24
local baseBillboardSize = UDim2.new(0, 200, 0, 50)

--------------------------------------------------
-- == НАСТРОЙКИ ==
--------------------------------------------------
local settings = {
    HighlightEnabled = true,
    TracerEnabled = true,
    NameTagEnabled = true,
    ArrowsEnabled = false,
    DoorESPEnabled = false,
    TextSize = 35,
    Font = Enum.Font.Oswald,
    TextTransparency = 0,
    TextOutlineTransparency = 0.5,
    ShowDistance = false,
    MatchColors = true
}

--------------------------------------------------
-- == ПАПКИ ==
--------------------------------------------------
local ScreenGui = CoreGui:FindFirstChild("ItemESP_GUI") or Instance.new("ScreenGui")
ScreenGui.Name = "ItemESP_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = CoreGui

local HighlightsFolder = CoreGui:FindFirstChild("HighlightsFolder_ItemESP") or Instance.new("Folder")
HighlightsFolder.Name = "HighlightsFolder_ItemESP"
HighlightsFolder.Parent = CoreGui

--------------------------------------------------
-- == СПИСКИ ==
--------------------------------------------------
local TargetItemsHighlights51 = {
    ["LiveHintBook"] = "Book",
    ["KeyObtain"] = "Key",
    ["LiveBreakerPolePickup"] = "Breaker",
    ["SmoothieSpawner"] = "Smoothie",
    ["Shears"] = "Shears",
    ["Lighter"] = "Lighter",
    ["Crucifix"] = "Crucifix",
    ["Lockpick"] = "Lockpick",
    ["Battery"] = "Battery",
    ["Vitamins"] = "Vitamins",
    ["Smoothie"] = "Smoothie",
    ["AlarmClock"] = "Alarm-Clock",
    ["Bandage"] = "Bandage",
    ["Candle"] = "Candle",
    ["LibraryHintPaper"] = "Paper",
    ["SkeletonKey"] = "SkeletonKey",
    ["Flashlight"] = "Flashlight",
    ["RiftSmoothie"] = "Rift-Smoothie",
    ["FuseObtain"] = "Fuse",
    ["BandagePack"] = "Bandage-Pack",
    ["Bulklight"] = "Bulklight",
    ["CrucifixWall"] = "Crucifix",
    ["Straplight"] = "Straplight",
    ["Glowsticks"] = "Glowsticks",
    ["BatteryPack"] = "Battery-Pack",
    ["LaserPointer"] = "Laser",
    ["ElectricalKeyObtain"] = "Key",
    ["Starlight Bottle"] = "Starlight-Bottle",
    ["Starlight Jug"] = "Starlight-Jug",
    ["Shakelight"] = "Shakelight",
    ["Gween Soda"] = "Gween-Soda",
    ["Bread"] = "Bread",
    ["Cheese"] = "Cheese",
    ["StarVial"] = "Star-Vial",
    ["StarBottle"] = "Star-Bottle",
    ["TimerLever"] = "Lever",
    ["Lantern"] = "Lantern",
    ["BigPropTool"] = "BigPropTool",
    ["Multitool"] = "Multi-Tool",
    ["GoldGun"] = "Gun",
    ["RiftCandle"] = "Rift-Candle",
    ["RiftJar"] = "Rift-Jar",
    ["TipJar"] = "Tip-Jar",
    ["Knockbomb"] = "Knock-Bomb",
    ["Bomb"] = "Bomb",
    ["Donut"] = "Donut",
    ["BigBomb"] = "Big-Bomb",
    ["StarJug"] = "Star-Jug",
    ["Nanner"] = "Nanner",
    ["SnakeBox"] = "Box",
    ["AloeVera"] = "Aloe-Vera",
    ["Compass"] = "Compass",
    ["Lotus"] = "Big-Lotus",
    ["NannerPeel"] = "NannerPeel",
    ["HolyGrenade"] = "Holy-Grenade",
    ["StopSign"] = "Stop-Sign",
    ["StardustPickup"] = "Stardust",
    ["GoldPile"] = "Gold",
    ["LotusPetalPickup"] = "Lotus",
    ["GlitchCube"] = "Glitch-Fragment",
}

local EntitiesHighlights203 = {}

local highlights, tracers, nametags = {}, {}, {}
local connections, renderConnection = {}, nil

--------------------------------------------------
-- == СЛУЖЕБНЫЕ ==
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
-- == ФУНКЦИИ ==
--------------------------------------------------
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
	if highlights[model] or not settings.HighlightEnabled then return end
	local h = Instance.new("Highlight")
	h.Name = "_ItemESP"
	h.FillColor = highlightColor
	h.OutlineColor = outlineColor
	h.FillTransparency = 0.8
	h.OutlineTransparency = 0
	h.Adornee = model
	h.Parent = HighlightsFolder
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

--------------------------------------------------
-- == ESP ДЛЯ ДВЕРЕЙ ==
--------------------------------------------------
local function addDoorHighlight(doorModel)
	if not doorModel or not doorModel:IsA("Model") then return end
	local doorPart = doorModel:FindFirstChild("Door")
	if not doorPart then return end

	if not highlights[doorPart] then
		local h = Instance.new("Highlight")
		h.Name = "_DoorESP"
		h.FillColor = Color3.fromRGB(0, 255, 255)
		h.OutlineColor = Color3.fromRGB(255, 255, 255)
		h.FillTransparency = 0.5
		h.OutlineTransparency = 0
		h.Adornee = doorPart
		h.Parent = HighlightsFolder
		highlights[doorPart] = h
	end
end

local function scanDoors()
	for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
		local door = room:FindFirstChild("Door")
		if door then
			addDoorHighlight(door)
		end
	end
end

--------------------------------------------------
-- == ОБНОВЛЕНИЕ TRACERS ==
--------------------------------------------------
local function updateTracers()
	local character = LocalPlayer.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	for model, line in pairs(tracers) do
		if not model or not model:IsDescendantOf(Workspace) or isIgnored(model) then
			pcall(function() line:Remove() end)
			tracers[model] = nil
		else
			local part = model:FindFirstChildWhichIsA("BasePart")
			if part and hrp then
				local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
				line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
				line.To = Vector2.new(pos.X, pos.Y)
				line.Visible = onScreen
			else
				line.Visible = false
			end
		end
	end
end

--------------------------------------------------
-- == ПРОЦЕССИНГ ==
--------------------------------------------------
local function processModel(model)
	if TargetItemsHighlights51[model.Name] and model:IsA("Model") and model:IsDescendantOf(Workspace) and not isIgnored(model) then
		addHighlight(model)
		addTracer(model)
	else
		removeModelRefs(model)
	end
end

local function scan()
	clearESP()
	for _, obj in pairs(Workspace:GetDescendants()) do
		processModel(obj)
	end
	if settings.DoorESPEnabled then
		scanDoors()
	end
end

--------------------------------------------------
-- == ГЛАВНЫЙ ЦИКЛ ==
--------------------------------------------------
local function enable()
	disable()
	scan()

	table.insert(connections, Workspace.DescendantAdded:Connect(function(obj)
		task.defer(processModel, obj)
	end))

	table.insert(connections, Workspace.DescendantRemoving:Connect(removeModelRefs))

	table.insert(connections, workspace.CurrentRooms.ChildAdded:Connect(function(room)
		if settings.DoorESPEnabled then
			task.wait(0.05)
			local door = room:FindFirstChild("Door")
			if door then addDoorHighlight(door) end
		end
	end))

	table.insert(connections, LocalPlayer.CharacterAdded:Connect(function()
		task.wait(1)
		scan()
	end))

	renderConnection = RunService.RenderStepped:Connect(function()
		updateTracers()
	end)
end

function disable()
	if renderConnection then renderConnection:Disconnect() renderConnection = nil end
	for _, conn in pairs(connections) do conn:Disconnect() end
	connections = {}
	clearESP()
end

--------------------------------------------------
-- == ТОГГЛЫ ДЛЯ ВКЛ/ВЫКЛ ==
--------------------------------------------------
function EnableDoors()
	settings.DoorESPEnabled = true
	scanDoors()
end

function DisableDoors()
	settings.DoorESPEnabled = false
	for _, h in pairs(highlights) do
		if h.Name == "_DoorESP" then
			pcall(function() h:Destroy() end)
		end
	end
end

--------------------------------------------------
-- == ВОЗВРАТ ==
--------------------------------------------------
return {
	EnableESP = enable,
	DisableESP = disable,
	EnableDoors = EnableDoors,
	DisableDoors = DisableDoors,
	SetHighlight = function(v) settings.HighlightEnabled = v scan() end,
	SetTracer = function(v) settings.TracerEnabled = v scan() end,
	SetNameTag = function(v) settings.NameTagEnabled = v scan() end,
	TargetItemsHighlights51 = TargetItemsHighlights51,
	EntitiesHighlights203 = EntitiesHighlights203
}
