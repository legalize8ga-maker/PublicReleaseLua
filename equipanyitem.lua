--[[
    Script: GhostEquipper_V2.local
    Architect: Your Name/Alias
    Date: 2025-11-24

    Description:
    [VERSION 2 - CORRECTED] Targets the 'equipItem' RemoteFunction. This version
    uses ':InvokeServer()' as required by the remote's type. This script allows
    the user to force the server to equip any item by name.

    *** USAGE: Type "/equip [item name]" in chat. ***
--]]

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// -- Corrected Remote Path --
local EQUIP_ITEM_REMOTE = ReplicatedStorage.events:WaitForChild("equipItem")

--// Module References
local itemData = require(ReplicatedStorage.modules.itemData)

--// Configuration
local COMMAND_PREFIX = "/equip "

--// State
local LOCAL_PLAYER = Players.LocalPlayer

--// Core Logic
local function findItemByName(query)
    query = query:lower()
    for itemName, _ in pairs(itemData) do
        if itemName:lower() == query then return itemName end
    end
    for itemName, _ in pairs(itemData) do
        if itemName:lower():find(query, 1, true) then return itemName end
    end
    return nil
end

local function onChatted(message)
    if message:lower():sub(1, #COMMAND_PREFIX) ~= COMMAND_PREFIX then return end

    local searchQuery = message:sub(#COMMAND_PREFIX + 1)
    if #searchQuery == 0 then return end
    
    local targetItemName = findItemByName(searchQuery)
    
    if targetItemName then
        print(string.format("Targeting RemoteFunction 'equipItem' with item: '%s'", targetItemName))
        
        -- The Exploit: We use InvokeServer as required. The server might return true/false,
        -- but we don't need to capture the result. The command itself is what matters.
        EQUIP_ITEM_REMOTE:InvokeServer(targetItemName)
        
        print("Invoked 'equipItem' remote. The item should now be equipped.")
    else
        print(string.format("Could not find an item matching '%s'.", searchQuery))
    end
end

--// Connections
LOCAL_PLAYER.Chatted:Connect(onChatted)

print("Ghost Equipper V2 loaded. Type '/equip [item name]' to equip any item.")
