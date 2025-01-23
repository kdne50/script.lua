local targetRoomNumber = 50
local roomLoaded = false
local highlights = {}
local isToggleActive = false

local function highlightLiveHintBook(model)
    if not model:FindFirstChildOfClass("Highlight") then
        local highlight = Instance.new("Highlight")
        highlight.Parent = model
        highlight.FillColor = Color3.fromRGB(69, 199, 255)
        highlight.FillTransparency = 0.5
        highlight.OutlineColor = Color3.fromRGB(188, 240, 255)
        highlight.OutlineTransparency = 0.1
        highlights[model] = highlight
    end
end

local function removeHighlightLiveHintBook(model)
    local highlight = highlights[model]
    if highlight then
        highlight:Destroy()
        highlights[model] = nil
    end
end

local function checkRoomForLiveHintBook(room)
    for _, descendant in ipairs(room:GetDescendants()) do
        if descendant.Name == "LiveHintBook" and descendant:IsA("Model") then
            highlightLiveHintBook(descendant)
        end
    end
end

local function monitorRoom(roomNumber)
    local room = workspace.CurrentRooms:FindFirstChild(tostring(roomNumber))
    if room then
        checkRoomForLiveHintBook(room)
    end
end

local function waitForRoomAndHighlight()
    workspace.CurrentRooms.ChildAdded:Connect(function(child)
        if isToggleActive and child:IsA("Model") then
            local roomNumber = tonumber(child.Name)
            if roomNumber == targetRoomNumber then
                roomLoaded = true
                monitorRoom(targetRoomNumber)
            end
        end
    end)

    workspace.CurrentRooms.DescendantAdded:Connect(function(descendant)
        if isToggleActive and roomLoaded and descendant.Name == "LiveHintBook" and descendant:IsA("Model") then
            highlightLiveHintBook(descendant)
        end
    end)

    local room50 = workspace.CurrentRooms:FindFirstChild(tostring(targetRoomNumber))
    if isToggleActive and room50 then
        roomLoaded = true
        monitorRoom(targetRoomNumber)
    end
end

local function clearHighlights()
    for model, highlight in pairs(highlights) do
        removeHighlightLiveHintBook(model)
    end
end

LeftGroupBox:AddToggle("LiveHintToggle", {
    Text = "Highlight LiveHintBook",
    Default = false,
    Callback = function(state)
        isToggleActive = state

        if isToggleActive then
            waitForRoomAndHighlight()
        else
            clearHighlights()
        end
    end
})
