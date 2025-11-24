--[[
    Script: OnDemandLoadout_V2.local
    Architect: Your Name/Alias
    Date: 2025-11-24

    Description:
    [VERSION 2 - KEYBINDS CORRECTED] The ultimate inventory control script.
    This version corrects the Enum.KeyCode names for the number row keys,
    making the keybind system fully operational.
--]]

--// Services
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Remote Reference (The Proven Vulnerability)
local EQUIP_ITEM_REMOTE = ReplicatedStorage.events:WaitForChild("equipItem")

--// --- YOUR ULTIMATE LOADOUT CONFIGURATION ---
local Loadout = {
    Primary = "Nekomancer Staff",        -- Press 1 to equip
    Secondary = "The Last Laugh",        -- Press 2 to equip
    Melee = "Death Harvester",           -- Press 3 to equip
    Ability = "Black Hole",              -- Press 4 to equip
    AlternatePrimary = "Nyx Echo"        -- Press 5 to equip
}
--// ------------------------------------------

--// --- CORRECTED Keybind Mapping ---
local Keybinds = {
    [Enum.KeyCode.Four] = Loadout.Primary,
    [Enum.KeyCode.Five] = Loadout.Secondary,
    [Enum.KeyCode.Six] = Loadout.Melee,
    [Enum.KeyCode.Seven] = Loadout.Ability,
    [Enum.KeyCode.Eight] = Loadout.AlternatePrimary
}
--// ---------------------------------

--// Core Logic
local function onInputBegan(input, gameProcessed)
    if gameProcessed then return end

    local itemName = Keybinds[input.KeyCode]
    
    if itemName then
        print(string.format("Requesting instant equip: %s", itemName))
        
        pcall(function()
            EQUIP_ITEM_REMOTE:InvokeServer(itemName)
        end)
        
        print("Equip command sent.")
    end
end

--// Connections
UserInputService.InputBegan:Connect(onInputBegan)

print("--- On-Demand Loadout Manager V2 ---")
print("Press 4 for Primary: " .. Loadout.Primary)
print("Press 5 for Secondary: " .. Loadout.Secondary)
print("Press 6 for Melee: " .. Loadout.Melee)
print("Press 7 for Ability: " .. Loadout.Ability)
print("Press 8 for Alternate: " .. Loadout.AlternatePrimary)
print("Script is now active.")
