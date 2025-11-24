--[[
    World of Stands - Dedicated Item Spawner
    Description: A client-side script with a GUI to request items from the server.
    
    -- IMPORTANT SETUP --
    You MUST find the correct RemoteEvent name inside:
    game.ReplicatedStorage.Communication.Events

    Common names might be "RequestItem", "GiveItem", "ClaimReward", etc.
    Replace the value of 'REMOTE_EVENT_NAME' below with the correct name.
]]

--//=======================================================================\\
--|| CONFIGURATION
--\\=======================================================================//

local REMOTE_EVENT_NAME = "ChangeThisToTheRealRemoteName" -- e.g., "GiveItem"
local TOGGLE_KEY = Enum.KeyCode.RightControl

--//=======================================================================\\
--|| SERVICES & VARIABLES
--\\=======================================================================//

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local localPlayer = Players.LocalPlayer
local itemsFolder = ReplicatedStorage:WaitForChild("Items")
local remoteFolder = ReplicatedStorage:WaitForChild("Communication"):WaitForChild("Events")

local selectedItemName = nil

--//=======================================================================\\
--|| CORE FUNCTIONS
--\\=======================================================================//

local function fireAddItemEvent(itemName, amount)
    if not itemName then
        warn("No item selected.")
        return
    end

    local itemObject = itemsFolder:FindFirstChild(itemName)
    if not itemObject then
        warn("Could not find item instance:", itemName)
        return
    end

    local remoteEvent = remoteFolder:FindFirstChild(REMOTE_EVENT_NAME)
    if not remoteEvent then
        warn("CRITICAL: RemoteEvent named '" .. REMOTE_EVENT_NAME .. "' not found.")
        warn("Please update the REMOTE_EVENT_NAME variable in the script.")
        return
    end

    -- The arguments table. Most games expect the Item Instance and a quantity.
    local args = {
        [1] = itemObject,
        [2] = tonumber(amount) or 1
    }

    -- Fire the event. Using a pcall to prevent errors if the arguments are wrong.
    pcall(function()
        firesignal(remoteEvent.OnClientEvent, unpack(args))
        print("Fired '"..REMOTE_EVENT_NAME.."' for "..amount.."x "..itemName)
    end)
end

--//=======================================================================\\
--|| GUI CREATION & MANAGEMENT
--\\=======================================================================//

-- Main GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ItemSpawnerGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = CoreGui

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 500, 0, 400)
mainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
mainFrame.BorderColor3 = Color3.fromRGB(80, 80, 100)
mainFrame.BorderSizePixel = 2
mainFrame.Draggable = true
mainFrame.Active = true
mainFrame.Visible = true
mainFrame.Parent = screenGui

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
titleLabel.BorderColor3 = Color3.fromRGB(80, 80, 100)
titleLabel.Text = "World of Stands - Item Spawner"
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.Parent = mainFrame

-- Search Box
local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -20, 0, 30)
searchBox.Position = UDim2.new(0, 10, 0, 40)
searchBox.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
searchBox.BorderColor3 = Color3.fromRGB(80, 80, 100)
searchBox.TextColor3 = Color3.new(1, 1, 1)
searchBox.PlaceholderText = "Search for an item..."
searchBox.ClearTextOnFocus = false
searchBox.Font = Enum.Font.SourceSans
searchBox.Parent = mainFrame

-- Scrolling Frame for Items
local scrollingFrame = Instance.new("ScrollingFrame")
scrollingFrame.Size = UDim2.new(1, -20, 0, 240)
scrollingFrame.Position = UDim2.new(0, 10, 0, 80)
scrollingFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
scrollingFrame.BorderColor3 = Color3.fromRGB(80, 80, 100)
scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollingFrame.Parent = mainFrame

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.Padding = UDim.new(0, 5)
uiListLayout.SortOrder = Enum.SortOrder.Name
uiListLayout.Parent = scrollingFrame

-- Bottom Controls Frame
local controlsFrame = Instance.new("Frame")
controlsFrame.Size = UDim2.new(1, -20, 0, 50)
controlsFrame.Position = UDim2.new(0, 10, 1, -60)
controlsFrame.BackgroundTransparency = 1
controlsFrame.Parent = mainFrame

-- Quantity Box
local quantityBox = Instance.new("TextBox")
quantityBox.Size = UDim2.new(0.3, -5, 1, 0)
quantityBox.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
quantityBox.BorderColor3 = Color3.fromRGB(80, 80, 100)
quantityBox.TextColor3 = Color3.new(1, 1, 1)
quantityBox.Text = "1"
quantityBox.Font = Enum.Font.SourceSans
quantityBox.TextXAlignment = Enum.TextXAlignment.Center
quantityBox.Parent = controlsFrame
quantityBox.TextScaled = true

-- Spawn Button
local spawnButton = Instance.new("TextButton")
spawnButton.Size = UDim2.new(0.7, -5, 1, 0)
spawnButton.Position = UDim2.new(0.3, 5, 0, 0)
spawnButton.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
spawnButton.BorderColor3 = Color3.fromRGB(120, 120, 140)
spawnButton.Text = "Spawn Item"
spawnButton.TextColor3 = Color3.new(1, 1, 1)
spawnButton.Font = Enum.Font.SourceSansBold
spawnButton.Parent = controlsFrame

--//=======================================================================\\
--|| GUI LOGIC & POPULATION
--\\=======================================================================//

-- Populate Item List
local itemButtons = {}
for _, item in pairs(itemsFolder:GetChildren()) do
    if item:IsA("Model") or item:IsA("Tool") or item:IsA("Configuration") then
        local itemButton = Instance.new("TextButton")
        itemButton.Name = item.Name
        itemButton.Text = item.Name
        itemButton.Size = UDim2.new(1, 0, 0, 30)
        itemButton.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        itemButton.BorderColor3 = Color3.fromRGB(80, 80, 100)
        itemButton.TextColor3 = Color3.new(1, 1, 1)
        itemButton.Font = Enum.Font.SourceSans
        itemButton.Parent = scrollingFrame
        
        table.insert(itemButtons, itemButton)
        
        itemButton.MouseButton1Click:Connect(function()
            selectedItemName = item.Name
            titleLabel.Text = "Selected: " .. item.Name
            -- Visual feedback
            for _, btn in pairs(itemButtons) do
                btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
            end
            itemButton.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
        end)
    end
end

-- Search Box Logic
searchBox.TextChanged:Connect(function()
    local searchText = string.lower(searchBox.Text)
    for _, button in pairs(itemButtons) do
        if string.find(string.lower(button.Name), searchText) then
            button.Visible = true
        else
            button.Visible = false
        end
    end
end)

-- Spawn Button Logic
spawnButton.MouseButton1Click:Connect(function()
    fireAddItemEvent(selectedItemName, quantityBox.Text)
end)

-- Toggle GUI Visibility
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == TOGGLE_KEY then
        mainFrame.Visible = not mainFrame.Visible
    end
end)
