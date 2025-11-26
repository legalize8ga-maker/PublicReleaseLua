--[[
    Standalone ESP Script
    Authored by Callum (Based on user-provided module)

    Description:
    A clean, modular Extra Sensory Perception (ESP) script that highlights
    other players and displays their name and team information.
]]

--//==================================================================================//--
--// Configuration
--//==================================================================================//--

local Config = {
    ToggleKey = Enum.KeyCode.L  -- The key to press to toggle the ESP on and off.
}

--//==================================================================================//--
--// Services & Local Player
--//==================================================================================//--

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

--//==================================================================================//--
--// ESP Module
--//==================================================================================//--

local ESP = {}
ESP.State = {
    IsActive = false,
    Connections = {}, 
    TrackedPlayers = {}  
}

function ESP:Toggle()
    self.State.IsActive = not self.State.IsActive
    print("ESP Toggled: " .. (self.State.IsActive and "Enabled" or "Disabled"))

    if self.State.IsActive then
        --// ACTIVATION LOGIC

        local function createEspForPlayer(player)
            if player == LocalPlayer then return end

            local function setupVisuals(character)
                -- Clean up old visuals if they exist (e.g., on respawn)
                if self.State.TrackedPlayers[player] then
                    self.State.TrackedPlayers[player].Highlight:Destroy()
                    self.State.TrackedPlayers[player].Billboard:Destroy()
                end

                local head = character:WaitForChild("Head")

                -- Create a highlight for the character model
                local highlight = Instance.new("Highlight")
                highlight.FillColor = Color3.fromRGB(255, 60, 60)
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.FillTransparency = 0.8
                highlight.OutlineTransparency = 0.3
                highlight.Parent = character

                -- Create a Billboard GUI for name and team
                local billboard = Instance.new("BillboardGui")
                billboard.Adornee = head
                billboard.AlwaysOnTop = true
                billboard.Size = UDim2.new(0, 200, 0, 50)
                billboard.StudsOffset = Vector3.new(0, 2.5, 0)
                billboard.Parent = head

                local nameLabel = Instance.new("TextLabel", billboard)
                nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
                nameLabel.Text = player.Name
                nameLabel.BackgroundTransparency = 1
                nameLabel.Font = Enum.Font.Code
                nameLabel.TextSize = 18
                nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

                local teamLabel = Instance.new("TextLabel", billboard)
                teamLabel.Size = UDim2.new(1, 0, 0.5, 0)
                teamLabel.Position = UDim2.new(0, 0, 0.5, 0)
                teamLabel.BackgroundTransparency = 1
                teamLabel.Font = Enum.Font.Code
                teamLabel.TextSize = 14
                if player.Team then
                    teamLabel.Text = player.Team.Name
                    teamLabel.TextColor3 = player.Team.TeamColor.Color
                else
                    teamLabel.Text = "No Team"
                    teamLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                end
                
                -- Store the created instances for later cleanup
                self.State.TrackedPlayers[player] = { Highlight = highlight, Billboard = billboard }
            end

            -- Run setup when the character appears
            if player.Character then
                setupVisuals(player.Character)
            end
            player.CharacterAdded:Connect(setupVisuals)
        end

        local function removeEspForPlayer(player)
            if self.State.TrackedPlayers[player] then
                self.State.TrackedPlayers[player].Highlight:Destroy()
                self.State.TrackedPlayers[player].Billboard:Destroy()
                self.State.TrackedPlayers[player] = nil
            end
        end

        -- Initial setup for all players currently in the game
        for _, player in ipairs(Players:GetPlayers()) do
            createEspForPlayer(player)
        end

        -- Connect events to handle players joining and leaving
        self.State.Connections.PlayerAdded = Players.PlayerAdded:Connect(createEspForPlayer)
        self.State.Connections.PlayerRemoving = Players.PlayerRemoving:Connect(removeEspForPlayer)

    else
        --// DEACTIVATION LOGIC (CLEANUP)

        -- Disconnect all events to prevent memory leaks
        for _, connection in pairs(self.State.Connections) do
            connection:Disconnect()
        end
        self.State.Connections = {}

        -- Destroy all created visuals
        for _, data in pairs(self.State.TrackedPlayers) do
            data.Highlight:Destroy()
            data.Billboard:Destroy()
        end
        self.State.TrackedPlayers = {}
    end
end

--//==================================================================================//--
--// Input Handler & Initialization
--//==================================================================================//--

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    -- Ignore input if the user is typing in a textbox (e.g., chat)
    if gameProcessedEvent then return end

    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Config.ToggleKey then
            -- Use a colon to call the method, which passes the 'ESP' table as 'self'
            ESP:Toggle()
        end
    end
end)

print("ESP Script Loaded. Press '" .. Config.ToggleKey.Name .. "' to toggle.")
