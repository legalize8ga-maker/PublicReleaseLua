--[=[
    -- NPC Invisibility & God Mode System (v3) --
    -- Architect: You
    -- Revision: Integrated a client-sided "God Mode" to provide invulnerability.
    --           This feature runs on RenderStepped for maximum efficiency.
]=]

--// Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService") --// NEW: Added for the health loop
local Lighting = game:GetService("Lighting")

--// Local Player
local localPlayer = Players.LocalPlayer

--// =============================== CONFIGURATION ================================================
local IGNORE_KEY = Enum.KeyCode.G
local GOD_MODE_KEY = Enum.KeyCode.H --// NEW: Key to toggle infinite health
--// ==============================================================================================

--// State Management
-- NPC Ignore State
local isIgnored = false
local storedHrp = nil
local originalHrpParent = nil

--// NEW: God Mode State
local isGodModeActive = false
local healthConnection = nil

--// Shared State
local character = nil

--// =============================== CORE LOGIC ===================================================

--// Logic for NPC Ignore
local function setIgnoreState(state)
    if not character or not character.Parent then
        warn("Cannot toggle ignore: Character not found.")
        return
    end

    if state == true then
        if isIgnored then return end
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then
            warn("Failed to enable ignore: HumanoidRootPart not found.")
            return
        end
        print("Enabling NPC Ignore...")
        storedHrp = humanoidRootPart
        originalHrpParent = storedHrp.Parent
        storedHrp.Parent = Lighting
        isIgnored = true
        print("NPCs should now ignore you. Press [" .. IGNORE_KEY.Name .. "] again to disable.")
    elseif state == false then
        if not isIgnored then return end
        print("Disabling NPC Ignore...")
        if not storedHrp or not storedHrp.Parent then
            warn("Could not disable ignore: Stored HumanoidRootPart is missing.")
            isIgnored = false
            return
        end
        if not originalHrpParent or not originalHrpParent.Parent then
            warn("Could not disable ignore: Original character parent is gone.")
            isIgnored = false
            return
        end
        storedHrp.Parent = originalHrpParent
        isIgnored = false
        storedHrp = nil
        originalHrpParent = nil
        print("You are now visible to NPCs again.")
    end
end

--// NEW: Logic for God Mode (Infinite Health)
local function maintainHealth()
    -- This function runs every frame when god mode is active
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        -- Check if the humanoid exists and is not dead
        if humanoid and humanoid.Health > 0 then
            humanoid.Health = humanoid.MaxHealth
        end
    end
end

local function setGodModeState(state)
    if state == true then
        --// ENABLE GOD MODE
        if isGodModeActive then return end
        print("Enabling God Mode...")
        isGodModeActive = true
        -- Connect the health maintenance function to run every frame
        healthConnection = RunService.RenderStepped:Connect(maintainHealth)
        print("God Mode is now ACTIVE. Press [".. GOD_MODE_KEY.Name .."] to disable.")
    elseif state == false then
        --// DISABLE GOD MODE
        if not isGodModeActive then return end
        print("Disabling God Mode...")
        isGodModeActive = false
        -- Disconnect the function to stop it from running
        if healthConnection then
            healthConnection:Disconnect()
            healthConnection = nil
        end
        print("God Mode is now INACTIVE.")
    end
end


--// =============================== EVENT HANDLING ===============================================

local function onCharacterAdded(newCharacter)
    character = newCharacter
    -- Cleanly reset the state if the player respawns
    if isIgnored then
        print("Character respawned. Ignore state reset.")
        setIgnoreState(false)
    end
    --// NEW: Reset god mode on respawn as well
    if isGodModeActive then
        print("Character respawned. God Mode state reset.")
        setGodModeState(false)
    end
end

if localPlayer.Character then
    onCharacterAdded(localPlayer.Character)
end
localPlayer.CharacterAdded:Connect(onCharacterAdded)

--// Input Handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == IGNORE_KEY then
        setIgnoreState(not isIgnored)
    end
    
    --// NEW: Handle input for God Mode
    if input.KeyCode == GOD_MODE_KEY then
        setGodModeState(not isGodModeActive)
    end
end)

print("NPC Utility (v3) loaded.")
print(" > Press [" .. IGNORE_KEY.Name .. "] to toggle NPC Ignore.")
print(" > Press [" .. GOD_MODE_KEY.Name .. "] to toggle God Mode.")
