--[[
    Script: MasterEquipperGUI_V6.local
    Architect: Your Name/Alias
    Date: 2025-11-24
    Description:
    [VERSION 6 - DUAL-ARGUMENT FIX] This version implements the breakthrough discovery that
    the 'equipItem' remote likely requires two arguments: a BaseName and a VariantName.
    The script's data engine has been re-architected to store a map of {Variant > Base},
    allowing it to send the correct dual-argument payload to the server. This is the
    definitive fix for equipping variants.

    *** USAGE: Press RIGHT CONTROL to toggle the GUI. Click any weapon to equip. ***
--]]

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

--// Remote Path (The Core Vulnerability)
local EQUIP_ITEM_REMOTE = ReplicatedStorage.events:WaitForChild("equipItem")

--// State
local LOCAL_PLAYER = Players.LocalPlayer
local masterWeaponMap = {} -- Re-architected from a list to a map {VariantName = BaseName}
local guiVisible = false
local isGuiPopulated = false

--// --- RE-ARCHITECTED DATA ENGINE ---
local function buildMasterWeaponMap()
    -- 1. Ingest base weapons. For these, the variant name IS the base name.
    local itemData = require(ReplicatedStorage.modules.itemData)
    for itemName, data in pairs(itemData) do
        if data.itemType == "weapons" then
            masterWeaponMap[itemName] = itemName
        end
    end

    -- 2. Scan for variants and map them to their base weapon name.
    local variantsFolder = ReplicatedStorage.assets:WaitForChild("variants")
    for _, baseWeaponFolder in ipairs(variantsFolder:GetChildren()) do
        local baseName = baseWeaponFolder.Name
        for _, variant in ipairs(baseWeaponFolder:GetChildren()) do
            local variantName = variant.Name
            masterWeaponMap[variantName] = baseName
        end
    end
    
    print(string.format("--> MasterEquipperGUI: Database built. %d total weapons mapped.", #masterWeaponMap))
end

--// --- GUI CONSTRUCTION ---
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MasterEquipperGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = LOCAL_PLAYER:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 400, 0, 500)
mainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderColor3 = Color3.fromRGB(80, 80, 80)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Visible = false
mainFrame.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
titleLabel.Text = "Master Equipper V6"
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 18
titleLabel.Parent = mainFrame

local scrollingFrame = Instance.new("ScrollingFrame")
scrollingFrame.Name = "WeaponList"
scrollingFrame.Size = UDim2.new(1, 0, 1, -30)
scrollingFrame.Position = UDim2.new(0, 0, 0, 30)
scrollingFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
scrollingFrame.ScrollBarThickness = 8
scrollingFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 5)
listLayout.SortOrder = Enum.SortOrder.Name
listLayout.Parent = scrollingFrame

--// --- GUI POPULATION & LOGIC ---
local function populateGui()
    -- Create a sorted list of keys to ensure the GUI is alphabetical
    local sortedWeaponNames = {}
    for weaponName in pairs(masterWeaponMap) do
        table.insert(sortedWeaponNames, weaponName)
    end
    table.sort(sortedWeaponNames)

    for _, variantName in ipairs(sortedWeaponNames) do
        local baseName = masterWeaponMap[variantName]
        
        local button = Instance.new("TextButton")
        button.Name = variantName
        button.Size = UDim2.new(1, -10, 0, 25)
        button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        button.Text = variantName
        button.Font = Enum.Font.SourceSans
        button.TextColor3 = Color3.fromRGB(220, 220, 220)
        button.TextSize = 14
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.Parent = scrollingFrame
        
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 10)
        padding.Parent = button

        -- [THE FIX] The remote is now invoked with BOTH the base and variant names.
        button.MouseButton1Click:Connect(function()
            print(string.format("--> GUI: Equipping Base:'%s' Variant:'%s'", baseName, variantName))
            EQUIP_ITEM_REMOTE:InvokeServer(baseName, variantName)
        end)
    end
    
    task.wait() 
    
    scrollingFrame.CanvasSize = UDim2.fromOffset(0, listLayout.AbsoluteContentSize.Y)
end

--// --- TOGGLE FUNCTIONALITY ---
local function toggleGui()
    guiVisible = not guiVisible
    mainFrame.Visible = guiVisible

    if guiVisible and not isGuiPopulated then
        isGuiPopulated = true
        populateGui()
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent and input.KeyCode ~= Enum.KeyCode.RightControl then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        toggleGui()
    end
end)

--// --- INITIALIZATION ---
buildMasterWeaponMap()
print("--- MasterEquipperGUI_V6 Initialized (Dual-Argument Fix) ---")
print("--> Press [RIGHT CONTROL] to toggle the weapon list.")
