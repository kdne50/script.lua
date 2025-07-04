local Library = {

	ObjectsFolder = Instance.new("Folder"),
	ScreenGui = Instance.new("ScreenGui"),
	OtherGui = Instance.new("ScreenGui"),
	HighlightsFolder = Instance.new("Folder"),
	BillboardsFolder = Instance.new("Folder"),
	TracersFrame = Instance.new("Frame"),
	Highlights = {},
	Labels = {},
	Elements = {},
	ElementsEnabled = {},
	Frames = {},
	TotalObjects = {},
	TransparencyEnabled = {},
	Connections = {},
	Billboards = {},
	ColorTable = {},
	TextTable = {},
	Lines = {},
	Font = Enum.Font.Oswald,
	ConnectionsTable = {},
	Objects = {},
	TracerTable = {},
	HighlightNames = {},
	HighlightedObjects = {},
	RemoveIfNotVisible = true,
	Rainbow = false,
	UseBillboards = false,
	Tracers = false,
	Bold = false,
	Unloaded = false,
	ShowDistance = false,
	MatchColors = true,
	TextTransparency = 0,
	TracerOrigin = "Bottom",
	FillTransparency = 0.75,
	OutlineTransparency = 0,
	TextOffset = 0,
	TextOutlineTransparency = 0,
	FadeTime = 0,
	TracerThickness = 0.85,
	TextSize = 20,
	DistanceSizeRatio = 1,
	OutlineColor = Color3.fromRGB(255,255,255)
}

local RainbowTable = {
	HueSetup = 0,
	Hue = 0,
	Step = 0,
	Color = Color3.new(),
	Enabled = false,
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local ScreenGui = Library.ScreenGui
local HighlightsFolder = Library.HighlightsFolder
local BillboardsFolder = Library.BillboardsFolder
local TracersFrame = Library.TracersFrame

local CoreGui = (identifyexecutor ~= nil and game:GetService("CoreGui") or Players.LocalPlayer.PlayerGui)
ScreenGui.Parent = CoreGui
HighlightsFolder.Parent = ScreenGui
BillboardsFolder.Parent = ScreenGui
TracersFrame.Parent = ScreenGui

TracersFrame.Size = UDim2.new(1,0,1,0)
TracersFrame.BackgroundTransparency = 1
TracersFrame.Visible = false -- по умолчанию выключено

-- Функции из твоей библиотеки (сокращённо для примера, основные логики смотри в твоём коде)
-- Полный код должен содержать все функции из твоего примера (AddESP, RemoveESP, Update и т.д.)
-- Для краткости ниже — ключевые моменты:

function Library:SetRainbow(value)
	Library.Rainbow = value
end

function Library:SetTracers(value)
	Library.Tracers = value
	TracersFrame.Visible = value
end

function Library:EnableAllESP()
	for _, obj in pairs(Library.TotalObjects) do
		Library.ElementsEnabled[obj] = true
	end
end

function Library:DisableAllESP()
	for _, obj in pairs(Library.TotalObjects) do
		Library.ElementsEnabled[obj] = false
		Library:RemoveESP(obj)
	end
end

-- Обновление радуги в 2 раза медленнее:

Library.ConnectionsTable.RainbowConnection = RunService.RenderStepped:Connect(function(Delta)
	RainbowTable.Step = RainbowTable.Step + Delta
	if RainbowTable.Step >= (1 / 30) then -- было 1/60, стало в 2 раза медленнее
		RainbowTable.Step = 0
		RainbowTable.HueSetup = RainbowTable.HueSetup + (1 / 800) -- было 1/400, стало в 2 раза медленнее
		if RainbowTable.HueSetup > 1 then RainbowTable.HueSetup = 0 end
		RainbowTable.Hue = RainbowTable.HueSetup
		RainbowTable.Color = Color3.fromHSV(RainbowTable.Hue, 0.8, 1)
	end
end)

-- Главный цикл для обновления ESP (от твоего кода)

local ElementsCooldown = false
local ConnectionType = "Heartbeat"

ElementsConnection = RunService[ConnectionType]:Connect(function()
	if ElementsCooldown == false then
		ElementsCooldown = true
		for i,Object in pairs(Library.TotalObjects) do
			if Library.ElementsEnabled[Object] then
				-- Здесь обновление позиции, цвета, линий, подсветок и т.п. по твоему коду (скопируй полный цикл из твоего примера)
			end
		end
		task.wait(0.01)
		ElementsCooldown = false
	end
end)


-- Список предметов для подсветки (твой targetNames из первого кода)
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

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Функция проверки, нужно ли игнорировать предмет
local function isIgnored(model)
	local Players = game:GetService("Players")
	local LocalPlayer = Players.LocalPlayer
	return model:IsDescendantOf(LocalPlayer.Backpack) or model:IsDescendantOf(LocalPlayer.Character)
end

-- Функция для добавления предмета в ESP
local function addObjectToESP(model)
	if Library.ElementsEnabled[model] then return end

	local part = nil
	if model:IsA("BasePart") then
		part = model
	elseif model:IsA("Model") then
		part = model:FindFirstChildWhichIsA("BasePart") or model.PrimaryPart
	end

	if part then
		Library:AddESP{
			Object = part,
			BasePart = part,
			Text = model.Name,
			Color = Color3.fromRGB(0, 255, 255) -- cyan color, можно менять
		}
		Library.ElementsEnabled[part] = true
		table.insert(Library.TotalObjects, part)
	end
end

-- Функция сканирования всех предметов в workspace и добавления в ESP
local function scanWorkspace()
	for _, obj in pairs(Workspace:GetDescendants()) do
		if targetNames[obj.Name] and obj:IsA("Model") and not isIgnored(obj) then
			addObjectToESP(obj)
		end
	end
end

-- Включение ESP с предметами
function Library:EnableESP()
	scanWorkspace()
end

-- Отключение ESP — удаляем все
function Library:DisableESP()
	for _, obj in pairs(Library.TotalObjects) do
		Library:RemoveESP(obj)
	end
	Library.TotalObjects = {}
	Library.ElementsEnabled = {}
end

return Library
