
--[[
    @Author: Zuka Tech
    @Date: 11/20/2025
    @Description: A modular, client-sided chat command system for Myself in Roblox.
                 This version includes a centralized command registry and a fully-featured
                 command bar with real-time auto-completion. --WIP
]]

local function showSplashScreen()
    
    local CoreGui = game:GetService("CoreGui")
    local TweenService = game:GetService("TweenService")
    
    
    local sg = Instance.new("ScreenGui")
    sg.Name = "ZukaSplashScreen"
    sg.ResetOnSpawn = false
    sg.Parent = CoreGui

    
    local mainFrame = Instance.new("Frame", sg)
    mainFrame.Size = UDim2.fromScale(1, 1)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    mainFrame.BackgroundTransparency = 1 

    
    local title = Instance.new("TextLabel", mainFrame)
    title.Size = UDim2.new(0, 500, 0, 50)
    title.Position = UDim2.new(0.5, -250, 0.5, -60)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.Code
    title.Text = "" 
    title.TextColor3 = Color3.fromRGB(200, 220, 255)
    title.TextSize = 38

    
    local subtitle = Instance.new("TextLabel", mainFrame)
    subtitle.Size = UDim2.new(0, 500, 0, 20)
    subtitle.Position = UDim2.new(0.5, -250, 0.5, -15)
    subtitle.BackgroundTransparency = 1
    subtitle.Font = Enum.Font.Code
    subtitle.Text = "" 
    subtitle.TextColor3 = Color3.fromRGB(120, 140, 180)
    subtitle.TextSize = 16
    subtitle.TextXAlignment = Enum.TextXAlignment.Left

    
    local loadingBarBG = Instance.new("Frame", mainFrame)
    loadingBarBG.Size = UDim2.new(0, 300, 0, 8)
    loadingBarBG.Position = UDim2.new(0.5, -150, 0.5, 20)
    loadingBarBG.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    loadingBarBG.BorderSizePixel = 0
    Instance.new("UICorner", loadingBarBG).CornerRadius = UDim.new(1, 0)

    
    local loadingBarFill = Instance.new("Frame", loadingBarBG)
    loadingBarFill.Size = UDim2.new(0, 0, 1, 0) 
    loadingBarFill.BackgroundColor3 = Color3.fromRGB(80, 130, 255)
    loadingBarFill.BorderSizePixel = 0
    Instance.new("UICorner", loadingBarFill).CornerRadius = UDim.new(1, 0)

    
    task.spawn(function()
        
        for i = 1, 0, -0.05 do
            mainFrame.BackgroundTransparency = i
            task.wait()
        end
        mainFrame.BackgroundTransparency = 0

        
        local titleText = "Zuka's Admin"
        for i = 1, #titleText do
            title.Text = string.sub(titleText, 1, i)
            task.wait(0.04)
        end

        
        local subtitleText = "Initializing Modules..."
        for i = 1, #subtitleText do
            subtitle.Text = string.sub(subtitleText, 1, i)
            task.wait(0.02)
        end
        
        
        local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local goal = { Size = UDim2.new(1, 0, 1, 0) }
        local tween = TweenService:Create(loadingBarFill, tweenInfo, goal)
        tween:Play()
        tween.Completed:Wait() 

        task.wait(0.5) 

        
        for i = 0, 1, 0.05 do
            mainFrame.BackgroundTransparency = i
            task.wait()
        end

        
        sg:Destroy()
    end)
    
    
    
    task.wait(4.5) 
end


showSplashScreen()




local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer


local function DoNotif(message, duration) print("NOTIFICATION: " .. tostring(message) .. " (for " .. tostring(duration) .. "s)") end
local function NaProtectUI(gui) if gui then gui.Parent = CoreGui or LocalPlayer:WaitForChild("PlayerGui") end; print("UI Protection applied to: " .. gui.Name) end
if not setclipboard then setclipboard = function(text) print("Clipboard (fallback): " .. text); DoNotif("setclipboard is not available. See console for output.", 5) end end




local Prefix = ";"
local Commands = {}
local CommandInfo = {} 
local Modules = {}




function RegisterCommand(info, func)
    if not info or not info.Name or not func then
        warn("Command registration failed: Missing info, name, or function.")
        return
    end

    local name = info.Name:lower()

    
    if Commands[name] then
        warn("Command registration skipped: Command '" .. name .. "' already exists.")
        return
    end

    
    Commands[name] = func

    
    if info.Aliases then
        for _, alias in ipairs(info.Aliases) do
            local aliasLower = alias:lower()
            if Commands[aliasLower] then
                warn("Alias '" .. aliasLower .. "' for command '" .. name .. "' conflicts with an existing command and was not registered.")
            else
                Commands[aliasLower] = func
            end
        end
    end


    table.insert(CommandInfo, info)
end



Modules.AutoComplete = {}; function Modules.AutoComplete:GetMatches(prefix)
    local matches = {}
    if typeof(prefix) ~= "string" or #prefix == 0 then return matches end
    prefix = prefix:lower()

    for cmdName, _ in pairs(Commands) do
        if cmdName:sub(1, #prefix) == prefix then
            table.insert(matches, cmdName)
        end
    end
    table.sort(matches) 
    return matches
end






Modules.CommandBar = {
    State = {
        UI = nil,
        TextBox = nil,
        SuggestionsFrame = nil,
        KeybindConnection = nil,
        PrefixKey = Enum.KeyCode.Semicolon
    }
}

--- Toggles the command bar's visibility and input focus.
function Modules.CommandBar:Toggle()
    if not self.State.UI then return end

    local isEnabled = not self.State.UI.Enabled
    self.State.UI.Enabled = isEnabled

    if isEnabled then
        self.State.TextBox:CaptureFocus()
    else
        self.State.TextBox:ReleaseFocus()
        self:_ClearSuggestions() -- Clear suggestions when closing the bar
    end
end

--- Clears all suggestion buttons from the UI.
function Modules.CommandBar:_ClearSuggestions()
    self.State.SuggestionsFrame.Visible = false
    for _, child in ipairs(self.State.SuggestionsFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
end

--- Initializes and builds the command bar UI one time when the script loads.
function Modules.CommandBar:Initialize()
    -- This function runs only once to create the UI components.
    
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")

    local ui = Instance.new("ScreenGui"); ui.Name = "CommandBarUI"; NaProtectUI(ui); self.State.UI = ui
    ui.ResetOnSpawn = false
    ui.Enabled = false -- Start hidden

    local container = Instance.new("Frame", ui)
    container.Size = UDim2.new(0, 450, 0, 32)
    container.Position = UDim2.new(0.5, -225, 0, 10)
    container.BackgroundTransparency = 1

    local bar = Instance.new("Frame", container)
    bar.Size = UDim2.new(1, 0, 1, 0)
    bar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    bar.BackgroundTransparency = 0.8
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 6)
    local barStroke = Instance.new("UIStroke", bar)
    barStroke.Color = Color3.fromRGB(80, 80, 100)
    barStroke.Thickness = 1
    local barGradient = Instance.new("UIGradient", bar)
    barGradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(55, 55, 70)), ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 35)) }); barGradient.Rotation = 90

    local prefixLabel = Instance.new("TextLabel", bar)
    prefixLabel.Size = UDim2.new(0, 30, 0, 20)
    prefixLabel.Position = UDim2.new(0, 6, 0.5, -10)
    prefixLabel.BackgroundColor3 = Color3.fromRGB(80, 100, 255)
    prefixLabel.Font = Enum.Font.GothamSemibold
    prefixLabel.Text = Prefix
    prefixLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    prefixLabel.TextSize = 16
    Instance.new("UICorner", prefixLabel).CornerRadius = UDim.new(0, 4)

    local textBox = Instance.new("TextBox", bar)
    textBox.Size = UDim2.new(1, -42, 1, 0)
    textBox.Position = UDim2.fromOffset(38, 0)
    textBox.BackgroundTransparency = 1
    textBox.Font = Enum.Font.Gotham
    textBox.PlaceholderText = "Enter command..."
    textBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 140)
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.TextSize = 16
    textBox.ClearTextOnFocus = false
    self.State.TextBox = textBox -- Store reference

    local suggestionsFrame = Instance.new("ScrollingFrame", container)
    suggestionsFrame.Size = UDim2.new(1, 0, 0, 120); suggestionsFrame.Position = UDim2.new(0, 0, 1, 4)
    suggestionsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30); suggestionsFrame.BackgroundTransparency = 0.25
    suggestionsFrame.BorderSizePixel = 0; suggestionsFrame.ScrollBarThickness = 5; suggestionsFrame.Visible = false
    self.State.SuggestionsFrame = suggestionsFrame -- Store reference
    Instance.new("UICorner", suggestionsFrame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", suggestionsFrame).Color = barStroke.Color

    local listLayout = Instance.new("UIListLayout", suggestionsFrame)
    listLayout.Padding = UDim.new(0, 3); listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() suggestionsFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y) end)
    
    local isScriptUpdatingText = false
    local MAX_SUGGESTIONS = 5

    local function createSuggestionButton(text)
        local button = Instance.new("TextButton", suggestionsFrame); button.Text = "  " .. text; button.TextSize = 14; button.Font = Enum.Font.Gotham; button.TextColor3 = Color3.fromRGB(210, 210, 220); button.TextXAlignment = Enum.TextXAlignment.Left; button.BackgroundTransparency = 1; button.Size = UDim2.new(1, 0, 0, 24); Instance.new("UICorner", button).CornerRadius = UDim.new(0, 4); local tweenInfo = TweenInfo.new(0.15); button.MouseEnter:Connect(function() TweenService:Create(button, tweenInfo, {BackgroundTransparency = 0.8, BackgroundColor3 = Color3.fromRGB(255,255,255)}):Play() end); button.MouseLeave:Connect(function() TweenService:Create(button, tweenInfo, {BackgroundTransparency = 1}):Play() end);
        button.MouseButton1Click:Connect(function() isScriptUpdatingText = true; textBox.Text = text .. " "; textBox:CaptureFocus(); isScriptUpdatingText = false; self:_ClearSuggestions() end)
    end

    local function updateSuggestions() if isScriptUpdatingText then return end; self:_ClearSuggestions(); local inputText=textBox.Text:match("^%s*(%S*)"); if not inputText or #inputText==0 then return end; local matches=Modules.AutoComplete:GetMatches(inputText); if #matches > 0 then suggestionsFrame.Visible=true; for i, match in ipairs(matches) do if i > MAX_SUGGESTIONS then break end; createSuggestionButton(match) end end end
    
    textBox.Changed:Connect(function(prop) if prop == "Text" then updateSuggestions() end end)
    textBox.FocusLost:Connect(function(enterPressed) if enterPressed and textBox.Text:len()>0 then processCommand(Prefix..textBox.Text); textBox.Text="" end; task.wait(0.1); self:_ClearSuggestions() end)
    textBox.Focused:Connect(updateSuggestions)
    
    local function drag(o) local d,s,p; o.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then d,s,p=true,i.Position,o.Position;i.Changed:Connect(function()if i.UserInputState==Enum.UserInputState.End then d=false end end)end end); o.InputChanged:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseMovement and d then o.Position=UDim2.new(p.X.Scale,p.X.Offset+i.Position.X-s.X,p.Y.Scale,p.Y.Offset+i.Position.Y-s.Y)end end)end
    drag(container)

    -- [UPGRADE] This connection now calls the master :Toggle() function.
    self.State.KeybindConnection = UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == self.State.PrefixKey then
            self:Toggle()
        end
    end)
    
    DoNotif("Command bar initialized. Press '".. self.State.PrefixKey.Name .."' to toggle.", 5)
end

--======================================================================================
-- INITIALIZATION AND COMMAND REGISTRATION
--======================================================================================

-- Build the UI as soon as the script is loaded.
Modules.CommandBar:Initialize()




Modules.Fly = {
    State = {
        IsActive = false,
        Speed = 60, 
        SprintMultiplier = 2.5,
        Connections = {},
        BodyMovers = {} 
    }
}

function Modules.Fly:SetSpeed(s)
    local n = tonumber(s)
    if n and n > 0 then
        self.State.Speed = n
        DoNotif("Fly speed set to: " .. n, 3)
    else
        DoNotif("Invalid speed.", 3)
    end
end

function Modules.Fly:Disable()
    if not self.State.IsActive then return end
    self.State.IsActive = false

    local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if h then h.PlatformStand = false end

    
    for _, mover in pairs(self.State.BodyMovers) do
        if mover and mover.Parent then
            mover:Destroy()
        end
    end

    
    for _, connection in ipairs(self.State.Connections) do
        connection:Disconnect()
    end

    table.clear(self.State.BodyMovers)
    table.clear(self.State.Connections)
    DoNotif("Fly disabled.", 3)
end

function Modules.Fly:Enable()
    if self.State.IsActive then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not (hrp and humanoid) then
        DoNotif("Character required.", 3)
        return
    end

    self.State.IsActive = true
    DoNotif("Fly Enabled.", 3)
    humanoid.PlatformStand = true

    
    
    local hrpAttachment = Instance.new("Attachment", hrp)
    local worldAttachment = Instance.new("Attachment", workspace.Terrain)
    worldAttachment.WorldCFrame = hrp.CFrame 

    
    local alignOrientation = Instance.new("AlignOrientation")
    alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
    alignOrientation.Attachment0 = hrpAttachment
    alignOrientation.Responsiveness = 200 
    alignOrientation.MaxTorque = math.huge
    alignOrientation.Parent = hrp

    
    local linearVelocity = Instance.new("LinearVelocity")
    linearVelocity.Attachment0 = hrpAttachment
    linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
    linearVelocity.MaxForce = math.huge
    linearVelocity.VectorVelocity = Vector3.zero
    linearVelocity.Parent = hrp

    
    self.State.BodyMovers.HRPAttachment = hrpAttachment
    self.State.BodyMovers.WorldAttachment = worldAttachment
    self.State.BodyMovers.AlignOrientation = alignOrientation
    self.State.BodyMovers.LinearVelocity = linearVelocity

    
    local keys = {}
    local function onInput(input, gameProcessed)
        if not gameProcessed then
            keys[input.KeyCode] = (input.UserInputState == Enum.UserInputState.Begin)
        end
    end
    table.insert(self.State.Connections, UserInputService.InputBegan:Connect(onInput))
    table.insert(self.State.Connections, UserInputService.InputEnded:Connect(onInput))

    
    local loop = RunService.RenderStepped:Connect(function()
        if not self.State.IsActive or not hrp.Parent then return end

        local camera = workspace.CurrentCamera
        alignOrientation.CFrame = camera.CFrame 

        local direction = Vector3.new()
        if keys[Enum.KeyCode.W] then direction += camera.CFrame.LookVector end
        if keys[Enum.KeyCode.S] then direction -= camera.CFrame.LookVector end
        if keys[Enum.KeyCode.D] then direction += camera.CFrame.RightVector end
        if keys[Enum.KeyCode.A] then direction -= camera.CFrame.RightVector end
        if keys[Enum.KeyCode.Space] or keys[Enum.KeyCode.E] then direction += Vector3.yAxis end
        if keys[Enum.KeyCode.LeftControl] or keys[Enum.KeyCode.Q] then direction -= Vector3.yAxis end

        local speed = keys[Enum.KeyCode.LeftShift] and self.State.Speed * self.State.SprintMultiplier or self.State.Speed
        
        
        linearVelocity.VectorVelocity = direction.Magnitude > 0 and direction.Unit * speed or Vector3.zero
    end)
    table.insert(self.State.Connections, loop)
end

function Modules.Fly:Toggle()
    if self.State.IsActive then
        self:Disable()
    else
        self:Enable()
    end
end

Modules.Noclip = { State = { IsActive = false, Connection = nil } }; function Modules.Noclip:Enable() if self.State.IsActive then return end; self.State.IsActive = true; self.State.Connection = RunService.Stepped:Connect(function() if LocalPlayer.Character then for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end end); DoNotif("Noclip enabled.", 3) end; function Modules.Noclip:Disable() if not self.State.IsActive then return end; self.State.IsActive = false; if self.State.Connection then self.State.Connection:Disconnect(); self.State.Connection = nil end; DoNotif("Noclip disabled.", 3) end; function Modules.Noclip:Toggle() if self.State.IsActive then self:Disable() else self:Enable() end end




local DEFAULT_GRAVITY = Vector3.new(0, -196.2, 0)
local RAY_DISTANCE = 15 

Modules.WallWalk = { State = { IsActive = false, Connection = nil } };

function Modules.WallWalk:Enable()
    if self.State.IsActive then return end
    self.State.IsActive = true

    if not (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) then
        DoNotif("Character required for WallWalk.", 3)
        self.State.IsActive = false
        return
    end

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}

    self.State.Connection = RunService.RenderStepped:Connect(function()
        local character = LocalPlayer.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        local camera = Workspace.CurrentCamera

        
        if not (self.State.IsActive and hrp and camera) then
            if Workspace.Gravity ~= DEFAULT_GRAVITY then Workspace.Gravity = DEFAULT_GRAVITY end
            return
        end

        
        local origin = hrp.Position
        local direction = camera.CFrame.LookVector * RAY_DISTANCE
        local result = Workspace:Raycast(origin, direction, raycastParams)

        
        if result and result.Instance and result.Instance.CanCollide then
            Workspace.Gravity = -result.Normal * 196.2
        else
            
            Workspace.Gravity = DEFAULT_GRAVITY
        end
    end)
    DoNotif("WallWalk enabled.", 3)
end

function Modules.WallWalk:Disable()
    if not self.State.IsActive then return end
    self.State.IsActive = false
    if self.State.Connection then
        self.State.Connection:Disconnect()
        self.State.Connection = nil
    end
    
    workspace.Gravity = DEFAULT_GRAVITY
    DoNotif("WallWalk disabled.", 3)
end

function Modules.WallWalk:Toggle()
    if self.State.IsActive then self:Disable() else self:Enable() end
end

Modules.CommandsUI = { State = { UI = nil } }

function Modules.CommandsUI:Toggle()
    if self.State.UI then self.State.UI:Destroy(); self.State.UI = nil; return end

    
    local TweenService = game:GetService("TweenService")

    
    local ui = Instance.new("ScreenGui"); ui.Name = "CommandsUI"; NaProtectUI(ui); self.State.UI = ui
    local mainFrame = Instance.new("Frame", ui)
    mainFrame.Size = UDim2.fromOffset(500, 350); mainFrame.Position = UDim2.new(0.5, -250, 0.5, -175)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35); mainFrame.BackgroundTransparency = 0.15
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", mainFrame).Color = Color3.fromRGB(80, 80, 100)
    
    local header = Instance.new("Frame", mainFrame)
    header.Size = UDim2.new(1, 0, 0, 32); header.BackgroundTransparency = 1
    local headerGradient = Instance.new("UIGradient", header)
    headerGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(55,55,70)), ColorSequenceKeypoint.new(1, Color3.fromRGB(25,25,35))}); headerGradient.Rotation = 90
    local title = Instance.new("TextLabel", header)
    title.Size = UDim2.new(1, -30, 1, 0); title.Position = UDim2.fromOffset(10, 0)
    title.BackgroundTransparency = 1; title.Font = Enum.Font.GothamSemibold; title.Text = "Command List"
    title.TextColor3 = Color3.fromRGB(220, 220, 255); title.TextXAlignment = Enum.TextXAlignment.Left; title.TextSize = 16
    local closeButton = Instance.new("TextButton", header)
    closeButton.Size = UDim2.fromOffset(32, 32); closeButton.Position = UDim2.new(1, -32, 0, 0)
    closeButton.BackgroundTransparency = 1; closeButton.Font = Enum.Font.Code; closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(200, 200, 220); closeButton.TextSize = 24
    closeButton.MouseButton1Click:Connect(function() self:Toggle() end)

    
    local searchBox = Instance.new("TextBox", mainFrame)
    searchBox.Size = UDim2.new(1, -20, 0, 28); searchBox.Position = UDim2.new(0, 10, 0, 40)
    searchBox.BackgroundColor3 = Color3.fromRGB(20, 20, 30); searchBox.Font = Enum.Font.Gotham
    searchBox.Text = "" 
    searchBox.PlaceholderText = "Search commands..."; searchBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 140)
    searchBox.TextColor3 = Color3.fromRGB(255, 255, 255); searchBox.TextSize = 14
    searchBox.ClearTextOnFocus = false
    Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 5)
    Instance.new("UIStroke", searchBox).Color = Color3.fromRGB(60, 60, 80)

    
    local scrollingFrame = Instance.new("ScrollingFrame", mainFrame)
    scrollingFrame.Size = UDim2.new(1, -20, 1, -80); scrollingFrame.Position = UDim2.fromOffset(10, 75)
    scrollingFrame.BackgroundTransparency = 1; scrollingFrame.BorderSizePixel = 0; scrollingFrame.ScrollBarThickness = 6
    local listLayout = Instance.new("UIListLayout", scrollingFrame)
    listLayout.Padding = UDim.new(0, 5); listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y) end)

    
    local function createCommandEntry(info) local entryButton=Instance.new("TextButton"); entryButton.Name=info.Name; entryButton.AutomaticSize=Enum.AutomaticSize.Y; entryButton.Size=UDim2.new(1,0,0,40); entryButton.BackgroundColor3=Color3.fromRGB(40,40,55); entryButton.BackgroundTransparency=1; entryButton.Parent=scrollingFrame; Instance.new("UICorner",entryButton).CornerRadius=UDim.new(0,5); local nameLabel=Instance.new("TextLabel",entryButton); nameLabel.Size=UDim2.new(1,-10,0,18); nameLabel.Position=UDim2.fromOffset(5,4); nameLabel.BackgroundTransparency=1; nameLabel.Font=Enum.Font.GothamBold; nameLabel.Text=Prefix..info.Name; nameLabel.TextColor3=Color3.fromRGB(80,150,255); nameLabel.TextXAlignment=Enum.TextXAlignment.Left; nameLabel.TextSize=16; local aliasText=#info.Aliases>0 and "Aliases: "..table.concat(info.Aliases,", ") or ""; local aliasLabel=Instance.new("TextLabel",entryButton); aliasLabel.Size=UDim2.new(1,-10,0,14); aliasLabel.Position=UDim2.fromOffset(5,22); aliasLabel.BackgroundTransparency=1; aliasLabel.Font=Enum.Font.Gotham; aliasLabel.Text=aliasText; aliasLabel.TextColor3=Color3.fromRGB(150,160,180); aliasLabel.TextXAlignment=Enum.TextXAlignment.Left; aliasLabel.TextSize=12; local descLabel=Instance.new("TextLabel",entryButton); descLabel.Size=UDim2.new(1,-10,0,30); descLabel.Position=UDim2.fromOffset(5,38); descLabel.BackgroundTransparency=1; descLabel.Font=Enum.Font.Gotham; descLabel.Text=info.Description or ""; descLabel.TextColor3=Color3.fromRGB(210,210,220); descLabel.TextXAlignment=Enum.TextXAlignment.Left; descLabel.TextSize=14; descLabel.TextWrapped=true; descLabel.AutomaticSize=Enum.AutomaticSize.Y; local tweenInfo=TweenInfo.new(0.15); entryButton.MouseEnter:Connect(function() TweenService:Create(entryButton,tweenInfo,{BackgroundTransparency=0.8}):Play() end); entryButton.MouseLeave:Connect(function() TweenService:Create(entryButton,tweenInfo,{BackgroundTransparency=1}):Play() end); entryButton.MouseButton1Click:Connect(function() local commandBarUI=Modules.CommandBar and Modules.CommandBar.State.UI; if commandBarUI then local textBox=commandBarUI:FindFirstChild("Frame",true):FindFirstChild("TextBox",true); if textBox then textBox.Text=info.Name.." "; textBox:CaptureFocus() end end; self:Toggle() end); return entryButton end
    local allEntries = {}; for _, info in ipairs(CommandInfo) do table.insert(allEntries, createCommandEntry(info)) end
    searchBox.Changed:Connect(function() local searchText=searchBox.Text:lower(); for _, entry in ipairs(allEntries) do local info=CommandInfo[tonumber(entry.Name)] or {}; local nameMatch=entry.Name:lower():find(searchText,1,true); local aliasMatch=table.concat(info.Aliases or {}):lower():find(searchText,1,true); local descMatch=(info.Description or ""):lower():find(searchText,1,true); entry.Visible=(searchText=="") or nameMatch or aliasMatch or descMatch end end)
    local function drag(o) local d,s,p; o.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then d,s,p=true,i.Position,o.Position;i.Changed:Connect(function()if i.UserInputState==Enum.UserInputState.End then d=false end end)end end); o.InputChanged:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseMovement and d then o.Position=UDim2.new(p.X.Scale,p.X.Offset+i.Position.X-s.X,p.Y.Scale,p.Y.Offset+i.Position.Y-s.Y)end end)end; drag(mainFrame)
end


Modules.ClickFling = {
    State = {
        IsActive = false,
        Connection = nil,
        UI = nil
    }
}


local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer


function Modules.ClickFling:Disable()
    self.State.IsActive = false
    if self.State.UI then
        self.State.UI:Destroy()
    end
    if self.State.Connection then
        self.State.Connection:Disconnect()
    end
    self.State.UI, self.State.Connection = nil, nil
    
end


function Modules.ClickFling:Enable()
    self:Disable()
    self.State.IsActive = true

    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ClickFlingUI"
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.State.UI = screenGui
    

    local toggleButton = Instance.new("TextButton", screenGui)
    toggleButton.Size = UDim2.fromOffset(120, 40)
    toggleButton.Text = "ClickFling: ON"
    toggleButton.Position = UDim2.new(0.5, -60, 0, 10)
    toggleButton.TextColor3 = Color3.new(1, 1, 1);
    toggleButton.Font = Enum.Font.GothamBold;
    toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40);
    Instance.new("UICorner", toggleButton).CornerRadius = UDim.new(0, 8);

    toggleButton.MouseButton1Click:Connect(function()
        self.State.IsActive = not self.State.IsActive
        toggleButton.Text = "ClickFling: " .. (self.State.IsActive and "ON" or "OFF")
    end)

    local function makeDraggable(uiObject)
        local isDragging = false; local dragStart, startPosition;
        uiObject.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isDragging = true; dragStart = input.Position; startPosition = uiObject.Position
                input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then isDragging = false end end)
            end
        end)
        uiObject.InputChanged:Connect(function(input)
            if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and isDragging then
                local delta = input.Position - dragStart; uiObject.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
            end
        end)
    end
    makeDraggable(toggleButton)

    
    self.State.Connection = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if not self.State.IsActive or gameProcessedEvent or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end

        
        
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        
        raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, screenGui}

        
        local mouseRay = Workspace.CurrentCamera:ScreenPointToRay(input.Position.X, input.Position.Y)
        
        
        local raycastResult = Workspace:Raycast(mouseRay.Origin, mouseRay.Direction * 1000, raycastParams)
        

        local targetPlayer = raycastResult and Players:GetPlayerFromCharacter(raycastResult.Instance:FindFirstAncestorOfClass("Model"))
        if not targetPlayer or targetPlayer == LocalPlayer then return end

        local localChar = LocalPlayer.Character
        local localHRP = localChar and localChar:FindFirstChild("HumanoidRootPart")
        local targetHRP = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not (localHRP and targetHRP) then return end

        

        local originalCFrame = localHRP.CFrame
        local originalFallenPartsHeight = Workspace.FallenPartsDestroyHeight
        Workspace.FallenPartsDestroyHeight = math.huge

        for i = 1, 7 do
            localHRP.CFrame = targetHRP.CFrame
            RunService.Heartbeat:Wait()
        end
        
        localHRP.Anchored = true
        RunService.Heartbeat:Wait()
        
        localHRP.CFrame = originalCFrame
        Workspace.FallenPartsDestroyHeight = originalFallenPartsHeight
        localHRP.Anchored = false
    end)

    
end

Modules.Reach = { State = { UI = nil } }; function Modules.Reach:_getTool() return (LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")) or (LocalPlayer:FindFirstChildOfClass("Backpack") and LocalPlayer.Backpack:FindFirstChildOfClass("Tool")) end; function Modules.Reach:Apply(reachType, size) if self.State.UI then self.State.UI:Destroy() end; local tool = self:_getTool(); if not tool then return DoNotif("No tool equipped.", 3) end; local parts = {}; for _, p in ipairs(tool:GetDescendants()) do if p:IsA("BasePart") then table.insert(parts, p) end end; if #parts == 0 then return DoNotif("Tool has no parts.", 3) end; local ui = Instance.new("ScreenGui"); ui.Name = "ReachPartSelector"; NaProtectUI(ui); self.State.UI = ui; local frame = Instance.new("Frame", ui); frame.Size = UDim2.fromOffset(250, 200); frame.Position = UDim2.new(0.5, -125, 0.5, -100); frame.BackgroundColor3 = Color3.fromRGB(35, 35, 45); Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8); local title = Instance.new("TextLabel", frame); title.Size = UDim2.new(1, 0, 0, 30); title.BackgroundTransparency = 1; title.Font = Enum.Font.Code; title.Text = "Select a Part"; title.TextColor3 = Color3.fromRGB(200, 220, 255); title.TextSize = 16; local scroll = Instance.new("ScrollingFrame", frame); scroll.Size = UDim2.new(1, -20, 1, -40); scroll.Position = UDim2.fromOffset(10, 35); scroll.BackgroundColor3 = frame.BackgroundColor3; scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 6; local layout = Instance.new("UIListLayout", scroll); layout.Padding = UDim.new(0, 5); for _, part in ipairs(parts) do local btn = Instance.new("TextButton", scroll); btn.Size = UDim2.new(1, 0, 0, 30); btn.BackgroundColor3 = Color3.fromRGB(50, 50, 65); btn.TextColor3 = Color3.fromRGB(220, 220, 230); btn.Font = Enum.Font.Code; btn.Text = part.Name; btn.TextSize = 14; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4); btn.MouseButton1Click:Connect(function() if not part.Parent then ui:Destroy(); return DoNotif("Part gone.", 3) end; if not part:FindFirstChild("OGSize3") then local v = Instance.new("Vector3Value", part); v.Name = "OGSize3"; v.Value = part.Size end; if part:FindFirstChild("FunTIMES") then part.FunTIMES:Destroy() end; local sb = Instance.new("SelectionBox", part); sb.Adornee = part; sb.Name = "FunTIMES"; sb.LineThickness = 0.02; sb.Color3 = reachType == "box" and Color3.fromRGB(0,100,255) or Color3.fromRGB(255,0,0); if reachType == "box" then part.Size = Vector3.one * size else part.Size = Vector3.new(part.Size.X, part.Size.Y, size) end; part.Massless = true; ui:Destroy(); self.State.UI = nil; DoNotif("Applied reach.", 3) end) end end; function Modules.Reach:Reset() local tool = self:_getTool(); if not tool then return DoNotif("No tool to reset.", 3) end; for _, p in ipairs(tool:GetDescendants()) do if p:IsA("BasePart") then if p:FindFirstChild("OGSize3") then p.Size = p.OGSize3.Value; p.OGSize3:Destroy() end; if p:FindFirstChild("FunTIMES") then p.FUNTIMES:Destroy() end end end; DoNotif("Tool reach reset.", 3) end





Modules.ModelReach = {
    State = {
        ActiveUIs = {} 
    }
}


function Modules.ModelReach:_findModel(modelName)
    if not modelName or modelName == "" then return nil end
    local inputName = modelName:lower()
    local exactMatch = nil
    local partialMatch = nil

    for _, child in ipairs(workspace:GetChildren()) do
        if child:IsA("Model") then
            local modelLowerName = child.Name:lower()
            if modelLowerName == inputName then
                exactMatch = child
                break
            end
            if not partialMatch and modelLowerName:sub(1, #inputName) == inputName then
                partialMatch = child
            end
        end
    end
    return exactMatch or partialMatch
end


function Modules.ModelReach:_getToolFromModel(model)
    if not model then return nil end
    return model:FindFirstChildOfClass("Tool")
end


function Modules.ModelReach:Apply(modelName, reachType, size)
    local model = self:_findModel(modelName)
    if not model then
        return DoNotif("Model '" .. tostring(modelName) .. "' not found.", 3)
    end

    
    if self.State.ActiveUIs[model] then
        self.State.ActiveUIs[model]:Destroy()
        self.State.ActiveUIs[model] = nil
    end

    local tool = self:_getToolFromModel(model)
    if not tool then
        return DoNotif("No tool found in model '" .. model.Name .. "'.", 3)
    end

    local parts = {}
    for _, p in ipairs(tool:GetDescendants()) do
        if p:IsA("BasePart") then
            table.insert(parts, p)
        end
    end

    if #parts == 0 then
        return DoNotif("Tool '" .. tool.Name .. "' has no parts to modify.", 3)
    end

    
    local ui = Instance.new("ScreenGui")
    ui.Name = "ModelReachPartSelector"
    NaProtectUI(ui)
    self.State.ActiveUIs[model] = ui

    local frame = Instance.new("Frame", ui)
    frame.Size = UDim2.fromOffset(250, 200)
    frame.Position = UDim2.new(0.5, -125, 0.5, -100)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.Code
    title.Text = "Select a Part from " .. tool.Name
    title.TextColor3 = Color3.fromRGB(200, 220, 255)
    title.TextSize = 16

    local scroll = Instance.new("ScrollingFrame", frame)
    scroll.Size = UDim2.new(1, -20, 1, -40)
    scroll.Position = UDim2.fromOffset(10, 35)
    scroll.BackgroundColor3 = frame.BackgroundColor3
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 6

    local layout = Instance.new("UIListLayout", scroll)
    layout.Padding = UDim.new(0, 5)

    for _, part in ipairs(parts) do
        local btn = Instance.new("TextButton", scroll)
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
        btn.TextColor3 = Color3.fromRGB(220, 220, 230)
        btn.Font = Enum.Font.Code
        btn.Text = part.Name
        btn.TextSize = 14
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

        btn.MouseButton1Click:Connect(function()
            if not part or not part.Parent then
                ui:Destroy()
                self.State.ActiveUIs[model] = nil
                return DoNotif("Part no longer exists.", 3)
            end

            
            if not part:FindFirstChild("OGSize3") then
                local v = Instance.new("Vector3Value", part)
                v.Name = "OGSize3"
                v.Value = part.Size
            end

            
            if part:FindFirstChild("FunTIMES") then
                part.FunTIMES:Destroy()
            end

            
            local sb = Instance.new("SelectionBox", part)
            sb.Adornee = part
            sb.Name = "FunTIMES"
            sb.LineThickness = 0.02
            sb.Color3 = reachType == "box" and Color3.fromRGB(0, 100, 255) or Color3.fromRGB(255, 0, 0)

            
            if reachType == "box" then
                part.Size = Vector3.one * size
            else 
                part.Size = Vector3.new(part.Size.X, part.Size.Y, size)
            end
            part.Massless = true

            
            ui:Destroy()
            self.State.ActiveUIs[model] = nil
            DoNotif("Applied reach to '" .. part.Name .. "' in model '" .. model.Name .. "'.", 3)
        end)
    end
end


function Modules.ModelReach:Reset(modelName)
    local model = self:_findModel(modelName)
    if not model then
        return DoNotif("Model '" .. tostring(modelName) .. "' not found.", 3)
    end

    local tool = self:_getToolFromModel(model)
    local wasReset = false
    
    local descendants = tool and tool:GetDescendants() or model:GetDescendants()

    for _, p in ipairs(descendants) do
        if p:IsA("BasePart") then
            if p:FindFirstChild("OGSize3") then
                p.Size = p.OGSize3.Value
                p.OGSize3:Destroy()
                wasReset = true
            end
            if p:FindFirstChild("FunTIMES") then
                p.FunTIMES:Destroy()
                wasReset = true
            end
        end
    end
    
    if wasReset then
        DoNotif("Tool reach reset for model '" .. model.Name .. "'.", 3)
    else
        DoNotif("No active reach found on model '" .. model.Name .. "'.", 3)
    end
end

Modules.IDE = { State = { UI = nil } }; function Modules.IDE:Toggle() if self.State.UI then self.State.UI:Destroy(); self.State.UI = nil; return end; local u = Instance.new("ScreenGui"); u.Name = "IDE_UI"; NaProtectUI(u); self.State.UI = u; local f = Instance.new("Frame", u); f.Size = UDim2.fromOffset(550, 400); f.Position = UDim2.new(0.5, -275, 0.5, -200); f.BackgroundColor3 = Color3.fromRGB(35, 35, 45); Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8); local h = Instance.new("Frame", f); h.Size = UDim2.new(1, 0, 0, 32); h.BackgroundColor3 = Color3.fromRGB(25, 25, 35); local t = Instance.new("TextLabel", h); t.Size = UDim2.new(1, -30, 1, 0); t.Position = UDim2.fromOffset(10, 0); t.BackgroundTransparency = 1; t.Font = Enum.Font.Code; t.Text = "Zuka IDE"; t.TextColor3 = Color3.fromRGB(200, 220, 255); t.TextXAlignment = Enum.TextXAlignment.Left; t.TextSize = 16; local c = Instance.new("TextButton", h); c.Size = UDim2.fromOffset(32, 32); c.Position = UDim2.new(1, -32, 0, 0); c.BackgroundTransparency = 1; c.Font = Enum.Font.Code; c.Text = "X"; c.TextColor3 = Color3.fromRGB(200, 200, 220); c.TextSize = 20; c.MouseButton1Click:Connect(function() self:Toggle() end); local sf = Instance.new("ScrollingFrame", f); sf.Size = UDim2.new(1, -20, 1, -82); sf.Position = UDim2.fromOffset(10, 37); sf.BackgroundColor3 = Color3.fromRGB(25, 25, 35); sf.BorderSizePixel = 0; sf.ScrollBarThickness = 8; local tb = Instance.new("TextBox", sf); tb.Size = UDim2.new(1, 0, 0, 0); tb.AutomaticSize = Enum.AutomaticSize.Y; tb.BackgroundColor3 = Color3.fromRGB(25, 25, 35); tb.MultiLine = true; tb.Font = Enum.Font.Code; tb.TextColor3 = Color3.fromRGB(220, 220, 230); tb.TextSize = 14; tb.TextXAlignment = Enum.TextXAlignment.Left; tb.TextYAlignment = Enum.TextYAlignment.Top; tb.ClearTextOnFocus = false; local eb = Instance.new("TextButton", f); eb.Size = UDim2.fromOffset(100, 30); eb.Position = UDim2.new(1, -120, 1, -40); eb.BackgroundColor3 = Color3.fromRGB(80, 160, 80); eb.Font = Enum.Font.Code; eb.Text = "Execute"; eb.TextColor3 = Color3.white; eb.TextSize = 16; Instance.new("UICorner", eb).CornerRadius = UDim.new(0, 5); local cb = Instance.new("TextButton", f); cb.Size = UDim2.fromOffset(80, 30); cb.Position = UDim2.new(1, -210, 1, -40); cb.BackgroundColor3 = Color3.fromRGB(180, 80, 80); cb.Font = Enum.Font.Code; cb.Text = "Clear"; cb.TextColor3 = Color3.white; cb.TextSize = 16; Instance.new("UICorner", cb).CornerRadius = UDim.new(0, 5); eb.MouseButton1Click:Connect(function() local code = tb.Text; if #code > 0 then local s, r = pcall(function() local f, e = loadstring(code); if typeof(f) ~= "function" then error("Syntax error: " .. tostring(e or f)) end; setfenv(f, getfenv()); f() end); if s then DoNotif("Script executed.", 3) else DoNotif("Error: " .. tostring(r), 6) end end end); cb.MouseButton1Click:Connect(function() tb.Text = "" end); local function drag(o) local d, s, p; o.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then d, s, p = true, i.Position, o.Position; i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then d = false end end) end end); o.InputChanged:Connect(function(i) if (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) and d then local delta = i.Position - s; o.Position = UDim2.new(p.X.Scale, p.X.Offset + delta.X, p.Y.Scale, p.Y.Offset + delta.Y) end end) end; drag(f) end
Modules.ESP = {
    State = {
        IsActive = false,
        Connections = {}, 
        TrackedPlayers = {}  
    }
}


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer


function Modules.ESP:Toggle()
    self.State.IsActive = not self.State.IsActive

    if self.State.IsActive then
        

        
        local function createEspForPlayer(player)
            
            if player == LocalPlayer then return end

            local function setupVisuals(character)
                
                if self.State.TrackedPlayers[player] then
                    self.State.TrackedPlayers[player].Highlight:Destroy()
                    self.State.TrackedPlayers[player].Billboard:Destroy()
                end

                local head = character:WaitForChild("Head")

                
                local highlight = Instance.new("Highlight")
                highlight.FillColor = Color3.fromRGB(255, 60, 60)
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.FillTransparency = 0.8
                highlight.OutlineTransparency = 0.3
                highlight.Parent = character

                
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

                
                self.State.TrackedPlayers[player] = { Highlight = highlight, Billboard = billboard }
            end

            
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

        
        for _, player in ipairs(Players:GetPlayers()) do
            createEspForPlayer(player)
        end

        
        self.State.Connections.PlayerAdded = Players.PlayerAdded:Connect(createEspForPlayer)
        self.State.Connections.PlayerRemoving = Players.PlayerRemoving:Connect(removeEspForPlayer)

    else
        

        
        for _, connection in pairs(self.State.Connections) do
            connection:Disconnect()
        end
        self.State.Connections = {}

        
        for _, data in pairs(self.State.TrackedPlayers) do
            data.Highlight:Destroy()
            data.Billboard:Destroy()
        end
        self.State.TrackedPlayers = {}
    end

    
end

Modules.ClickTP = { State = { IsActive = false, Connection = nil } };
function Modules.ClickTP:Toggle()
    self.State.IsActive = not self.State.IsActive
    if self.State.IsActive then
        self.State.Connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if not gameProcessed and input.KeyCode == Enum.KeyCode.LeftControl then
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                
                
                local mouseLocation = UserInputService:GetMouseLocation()
                local mouseRay = Workspace.CurrentCamera:ScreenPointToRay(mouseLocation.X, mouseLocation.Y)
                
                local raycastParams = RaycastParams.new()
                raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
                
                local result = Workspace:Raycast(mouseRay.Origin, mouseRay.Direction * 1000, raycastParams)
                
                if result and result.Position then
                    hrp.CFrame = CFrame.new(result.Position)
                end
            end
        end)
    else
        if self.State.Connection then
            self.State.Connection:Disconnect()
            self.State.Connection = nil
        end
    end
    DoNotif("Click TP " .. (self.State.IsActive and "Enabled" or "Disabled"), 3)
end

Modules.GrabTools = { State = { IsActive = false, Connection = nil } }; function Modules.GrabTools:Toggle() self.State.IsActive = not self.State.IsActive; if self.State.IsActive then self.State.Connection = workspace.ChildAdded:Connect(function(c) if c:IsA("Tool") then local bp = LocalPlayer:FindFirstChildOfClass("Backpack"); if bp then c:Clone().Parent = bp; DoNotif("Grabbed " .. c.Name, 2) end end end) else if self.State.Connection then self.State.Connection:Disconnect(); self.State.Connection = nil end end; DoNotif("Grab Tools " .. (self.State.IsActive and "Enabled" or "Disabled"), 3) end

Modules.AntiKick = { State = { IsHooked = false, Originals = { kicks = {} } } }; function Modules.AntiKick:Enable() if self.State.IsHooked then return end; local getRawMetatable = (debug and debug.getmetatable) or getrawmetatable; local setReadOnly = setreadonly or (make_writeable and function(t, ro) if ro then make_readonly(t) else make_writeable(t) end end); if not (getRawMetatable and setReadOnly and newcclosure and hookfunction and getnamecallmethod) then return DoNotif("Your environment does not support the required functions for AntiKick.", 5) end; local meta = getRawMetatable(game); if not meta then return DoNotif("Could not get game metatable.", 3) end; if not LocalPlayer then return DoNotif("LocalPlayer not found.", 3) end; self.State.Originals.namecall = meta.__namecall; self.State.Originals.index = meta.__index; self.State.Originals.newindex = meta.__newindex; for _, kickFunc in ipairs({ LocalPlayer.Kick, LocalPlayer.kick }) do if type(kickFunc) == "function" then local originalKick; originalKick = hookfunction(kickFunc, newcclosure(function(self, ...) if self == LocalPlayer then DoNotif("Kick blocked (direct hook).", 2); return end; return originalKick(self, ...) end)); self.State.Originals.kicks[kickFunc] = originalKick end end; setReadOnly(meta, false); meta.__namecall = newcclosure(function(self, ...) local method = getnamecallmethod(); if self == LocalPlayer and method and method:lower() == "kick" then DoNotif("Kick blocked (__namecall).", 2); return end; return self.State.Originals.namecall(self, ...) end); meta.__index = newcclosure(function(self, key) if self == LocalPlayer then local k = tostring(key):lower(); if k:find("kick") or k:find("destroy") then DoNotif("Blocked access to: " .. tostring(key), 2); return function() end end end; return self.State.Originals.index(self, key) end); meta.__newindex = newcclosure(function(self, key, value) if self == LocalPlayer then local k = tostring(key):lower(); if k:find("kick") or k:find("destroy") then DoNotif("Blocked overwrite of: " .. tostring(key), 2); return end end; return self.State.Originals.newindex(self, key, value) end); setReadOnly(meta, true); self.State.IsHooked = true; DoNotif("Anti-Kick enabled.", 3) end; function Modules.AntiKick:Disable() if not self.State.IsHooked then return end; local getRawMetatable = (debug and debug.getmetatable) or getrawmetatable; local setReadOnly = setreadonly or (make_writeable and function(t, ro) if ro then make_readonly(t) else make_writeable(t) end end); if unhookfunction then for func, orig in pairs(self.State.Originals.kicks) do unhookfunction(func) end end; local meta = getRawMetatable and getRawMetatable(game); if meta and setReadOnly then setReadOnly(meta, false); meta.__namecall = self.State.Originals.namecall; meta.__index = self.State.Originals.index; meta.__newindex = self.State.Originals.newindex; setReadOnly(meta, true) end; self.State.IsHooked = false; self.State.Originals = { kicks = {} }; DoNotif("Anti-Kick disabled.", 3) end; function Modules.AntiKick:Toggle() if self.State.IsHooked then self:Disable() else self:Enable() end end
Modules.Decompiler = {State = {IsInitialized = false}}; function Modules.Decompiler:Initialize() if self.State.IsInitialized then return DoNotif("Decompiler is already initialized.", 3) end; if not getscriptbytecode then return DoNotif("Decompiler Error: 'getscriptbytecode' is not available in your environment.", 5) end; local httpRequest = (syn and syn.request) or http_request; if not httpRequest then return DoNotif("Decompiler Error: A compatible HTTP POST function (e.g., syn.request) is required.", 5) end; task.spawn(function() local API_URL = "http://api.plusgiant5.com"; local last_call_time = 0; local function callAPI(endpoint, scriptInstance) local success, bytecode = pcall(getscriptbytecode, scriptInstance); if not success then DoNotif("Failed to get bytecode: " .. tostring(bytecode), 4); return end; local time_elapsed = os.clock() - last_call_time; if time_elapsed < 0.5 then task.wait(0.5 - time_elapsed) end; local success, httpResult = pcall(httpRequest, {Url = API_URL .. endpoint, Body = bytecode, Method = "POST", Headers = { ["Content-Type"] = "text/plain" }}); last_call_time = os.clock(); if not success then DoNotif("HTTP request failed: " .. tostring(httpResult), 5); return end; if httpResult.StatusCode == 200 then return httpResult.Body else DoNotif("API Error " .. httpResult.StatusCode .. ": " .. httpResult.StatusMessage, 4); return end end; local function decompile_func(scriptInstance) if not (scriptInstance and (scriptInstance:IsA("LocalScript") or scriptInstance:IsA("ModuleScript"))) then warn("Decompile target must be a LocalScript or ModuleScript instance."); return nil end; return callAPI("/konstant/decompile", scriptInstance) end; local function disassemble_func(scriptInstance) if not (scriptInstance and (scriptInstance:IsA("LocalScript") or scriptInstance:IsA("ModuleScript"))) then warn("Disassemble target must be a LocalScript or ModuleScript instance."); return nil end; return callAPI("/konstant/disassemble", scriptInstance) end; local env = getfenv(); env.decompile = decompile_func; env.disassemble = disassemble_func; self.State.IsInitialized = true; DoNotif("Decompiler initialized.", 4); DoNotif("Use 'decompile(script_instance)' in the IDE or your executor.", 6) end) end
Modules.Godmode = { State = { IsEnabled = false, Method = nil, UI = nil, Connection = nil, LastHealth = 100 } }; function Modules.Godmode:_CleanupUI() if self.State.UI then self.State.UI:Destroy(); self.State.UI = nil end end; function Modules.Godmode:Disable() if not self.State.IsEnabled then return end; self:_CleanupUI(); local char = LocalPlayer.Character; if self.State.Method == "ForceField" and char then local ff = char:FindFirstChild("ZukaGodmodeFF"); if ff then ff:Destroy() end elseif self.State.Method == "HealthLock" and self.State.Connection then self.State.Connection:Disconnect(); self.State.Connection = nil end; self.State.IsEnabled = false; self.State.Method = nil; DoNotif("Godmode OFF", 2) end; function Modules.Godmode:EnableForceField() self:Disable(); local char = LocalPlayer.Character; if not char then return DoNotif("Character not found.", 3) end; local ff = Instance.new("ForceField", char); ff.Name = "ZukaGodmodeFF"; self.State.IsEnabled = true; self.State.Method = "ForceField"; DoNotif("Godmode ON (ForceField)", 2) end; function Modules.Godmode:EnableHealthLock() self:Disable(); local char = LocalPlayer.Character; local humanoid = char and char:FindFirstChildOfClass("Humanoid"); if not humanoid then return DoNotif("Humanoid not found.", 3) end; self.State.LastHealth = humanoid.Health; self.State.Connection = humanoid.HealthChanged:Connect(function(newHealth) if newHealth < self.State.LastHealth and newHealth > 0 then humanoid.Health = self.State.LastHealth else self.State.LastHealth = newHealth end end); self.State.IsEnabled = true; self.State.Method = "HealthLock"; DoNotif("Godmode ON (Health Lock)", 2) end; function Modules.Godmode:ShowMenu() self:_CleanupUI(); local gui = Instance.new("ScreenGui"); gui.Name = "GodmodeUI"; NaProtectUI(gui); self.State.UI = gui; local frame = Instance.new("Frame", gui); frame.Size = UDim2.fromOffset(250, 210); frame.Position = UDim2.new(0.5, -125, 0.5, -105); frame.BackgroundColor3 = Color3.fromRGB(35, 35, 45); Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8); local title = Instance.new("TextLabel", frame); title.Size = UDim2.new(1, 0, 0, 30); title.BackgroundTransparency = 1; title.Font = Enum.Font.Code; title.Text = "Godmode Methods"; title.TextColor3 = Color3.fromRGB(200, 220, 255); title.TextSize = 16; local buttonContainer = Instance.new("Frame", frame); buttonContainer.Size = UDim2.new(1, -20, 1, -40); buttonContainer.Position = UDim2.fromOffset(10, 35); buttonContainer.BackgroundTransparency = 1; local list = Instance.new("UIListLayout", buttonContainer); list.Padding = UDim.new(0, 5); list.SortOrder = Enum.SortOrder.LayoutOrder; local function makeButton(text, callback) local btn = Instance.new("TextButton", buttonContainer); btn.Size = UDim2.new(1, 0, 0, 35); btn.BackgroundColor3 = Color3.fromRGB(50, 50, 65); btn.TextColor3 = Color3.fromRGB(220, 220, 230); btn.Font = Enum.Font.Code; btn.Text = text; btn.TextSize = 14; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4); btn.MouseButton1Click:Connect(callback); return btn end; makeButton("Enable: ForceField (Visual)", function() self:_CleanupUI(); self:EnableForceField() end); makeButton("Enable: Health Lock (Silent)", function() self:_CleanupUI(); self:EnableHealthLock() end); if self.State.IsEnabled then makeButton("Disable Godmode", function() self:_CleanupUI(); self:Disable() end) end; makeButton("Close", function() self:_CleanupUI() end).BackgroundColor3 = Color3.fromRGB(180, 80, 80) end; function Modules.Godmode:HandleCommand(args) local choice = args[1] and args[1]:lower() or nil; if choice == "strong" or choice == "forcefield" or choice == "ff" then return self:EnableForceField() end; if choice == "hook" or choice == "hooking" or choice == "healthlock" or choice == "lock" then return self:EnableHealthLock() end; if choice == "off" or choice == "disable" then return self:Disable() end; self:ShowMenu() end
Modules.iBTools = { State = { IsActive = false, Tool = nil, UI = nil, Highlight = nil, Connections = {}, History = {}, SaveHistory = {}, CurrentPart = nil, CurrentMode = "delete" } }; function Modules.iBTools:_CleanupUI() if self.State.UI then self.State.UI:Destroy() end; if self.State.Highlight then self.State.Highlight:Destroy() end; for _, conn in ipairs(self.State.Connections) do conn:Disconnect() end; self.State.UI, self.State.Highlight = nil, nil; table.clear(self.State.Connections) end; function Modules.iBTools:Disable() if not self.State.IsActive then return end; self:_CleanupUI(); if self.State.Tool then self.State.Tool:Destroy() end; self.State = { IsActive = false, Tool = nil, UI = nil, Highlight = nil, Connections = {}, History = {}, SaveHistory = {}, CurrentPart = nil, CurrentMode = "delete" }; DoNotif("iBTools unloaded.", 3) end; function Modules.iBTools:Enable() if self.State.IsActive then return DoNotif("iBTools is already active.", 3) end; local backpack = LocalPlayer:FindFirstChildOfClass("Backpack"); if not backpack then return DoNotif("Backpack not found.", 3) end; self.State.IsActive = true; self.State.Tool = Instance.new("Tool", backpack); self.State.Tool.Name = "iBTools"; self.State.Tool.RequiresHandle = false; self.State.Tool.Equipped:Connect(function(mouse) local state = self.State; state.Highlight = Instance.new("SelectionBox"); state.Highlight.Name = "iBToolsSelection"; state.Highlight.LineThickness = 0.04; state.Highlight.Color3 = Color3.fromRGB(0, 170, 255); state.Highlight.Parent = workspace.CurrentCamera; local function formatVectorString(vec) return string.format("Vector3.new(%s,%s,%s)", tostring(vec.X), tostring(vec.Y), tostring(vec.Z)) end; local function updateStatus(part) if not state.UI then return end; local statusLabel = state.UI:FindFirstChild("Panel", true) and state.UI.Panel:FindFirstChild("Status"); if not statusLabel then return end; local targetText = "none"; if part then targetText = part:GetFullName() end; statusLabel.Text = string.format("Mode: %s | Target: %s", state.CurrentMode:upper(), targetText) end; local function setTarget(part) if part and not part:IsA("BasePart") then part = nil end; state.CurrentPart = part; if state.Highlight then state.Highlight.Adornee = part end; updateStatus(part) end; local modeHandlers = { delete = function(part) table.insert(state.History, {part = part, parent = part.Parent, cframe = part.CFrame}); table.insert(state.SaveHistory, {name = part.Name, position = part.Position}); part.Parent = nil; setTarget(nil); DoNotif("Deleted '"..part.Name.."'", 2) end, anchor = function(part) part.Anchored = not part.Anchored; updateStatus(part); DoNotif(string.format("%s anchored %s", part.Name, part.Anchored and "enabled" or "disabled"), 2) end, collide = function(part) part.CanCollide = not part.CanCollide; updateStatus(part); DoNotif(string.format("%s CanCollide %s", part.Name, part.CanCollide and "enabled" or "disabled"), 2) end }; local uiActions = { setMode = function(mode) state.CurrentMode = mode; updateStatus(state.CurrentPart) end, undo = function() local r = table.remove(state.History); if r then r.part.Parent = r.parent; pcall(function() r.part.CFrame = r.cframe end); setTarget(r.part); DoNotif("Restored '"..r.part.Name.."'", 2) else DoNotif("Nothing to undo.", 2) end end, copy = function() if #state.SaveHistory == 0 then return DoNotif("No deleted parts to export.", 3) end; local l = {}; for _, d in ipairs(state.SaveHistory) do table.insert(l, string.format("for _,v in ipairs(workspace:FindPartsInRegion3(Region3.new(%s, %s), nil, math.huge)) do if v.Name == %q then v:Destroy() end end", formatVectorString(d.position), formatVectorString(d.position), d.name)) end; setclipboard(table.concat(l, "\n")); DoNotif("Copied delete script to clipboard.", 3) end }; local gui = Instance.new("ScreenGui"); gui.Name = "iBToolsUI"; NaProtectUI(gui); self.State.UI = gui; local f = Instance.new("Frame", gui); f.Name = "Panel"; f.Size = UDim2.new(0, 240, 0, 260); f.Position = UDim2.new(0.05, 0, 0.4, 0); f.BackgroundColor3 = Color3.fromRGB(26, 26, 26); Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8); local h = Instance.new("Frame", f); h.Name = "Header"; h.Size = UDim2.new(1, 0, 0, 36); h.BackgroundColor3 = Color3.fromRGB(38, 38, 38); h.Active = true; local t = Instance.new("TextLabel", h); t.BackgroundTransparency=1;t.Font=Enum.Font.GothamSemibold;t.Text="iB Tools";t.Size=UDim2.new(1,-40,1,0);t.Position=UDim2.new(0,12,0,0);t.TextColor3=Color3.new(1,1,1);t.TextXAlignment=Enum.TextXAlignment.Left;local s=Instance.new("TextLabel",f);s.Name="Status";s.BackgroundTransparency=1;s.Size=UDim2.new(1,-24,0,20);s.Position=UDim2.new(0,12,0,40);s.Font=Enum.Font.Code;s.TextColor3=Color3.fromRGB(200,200,200);s.TextXAlignment=Enum.TextXAlignment.Left;s.Text="Mode: DELETE | Target: none";local bH=Instance.new("Frame",f);bH.BackgroundTransparency=1;bH.Size=UDim2.new(1,-24,1,-72);bH.Position=UDim2.new(0,12,0,68);local l=Instance.new("UIListLayout",bH);l.Padding=UDim.new(0,6);local mB={};local function btn(txt)local b=Instance.new("TextButton",bH);b.Name=txt;b.Size=UDim2.new(1,0,0,32);b.Font=Enum.Font.GothamSemibold;b.Text=txt;b.TextColor3=Color3.new(1,1,1);b.TextSize=14;local c=Instance.new("UICorner",b);c.CornerRadius=UDim.new(0,5);return b end;local function rMB()for m,b in pairs(mB)do b.BackgroundColor3=(state.CurrentMode==m and Color3.fromRGB(80,110,255)or Color3.fromRGB(52,52,52))end end;for m,lbl in pairs({delete="Delete",anchor="Toggle Anchor",collide="Toggle CanCollide"})do local b=btn(lbl);mB[m]=b;b.MouseButton1Click:Connect(function()uiActions.setMode(m);rMB()end)end;btn("Undo Last Delete").MouseButton1Click:Connect(uiActions.undo);btn("Copy Delete Script").MouseButton1Click:Connect(uiActions.copy);local function drag(o,h) local d,s,p; h.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then d,s,p=true,i.Position,o.Position;i.Changed:Connect(function()if i.UserInputState==Enum.UserInputState.End then d=false end end)end end); h.InputChanged:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseMovement and d then o.Position=UDim2.new(p.X.Scale,p.X.Offset+i.Position.X-s.X,p.Y.Scale,p.Y.Offset+i.Position.Y-s.Y)end end)end;drag(f,h);rMB(); table.insert(state.Connections, mouse.Move:Connect(function() setTarget(mouse.Target) end)); table.insert(state.Connections, mouse.Button1Down:Connect(function() if state.CurrentPart then modeHandlers[state.CurrentMode](state.CurrentPart) end end)) end); self.State.Tool.Unequipped:Connect(function() self:_CleanupUI() end); self.State.Tool.AncestryChanged:Connect(function(_, parent) if not parent then self:Disable() end end); DoNotif("iBTools loaded. Equip the tool to use it.", 3) end; function Modules.iBTools:Toggle() if self.State.IsActive then self:Disable() else self:Enable() end end

Modules.AntiKB = {
    State = {
        IsActive = false,
        HealthConnection = nil,
        CharacterConnection = nil,
        LastHealth = 100 
    }
}

function Modules.AntiKB:_cleanup()
    if self.State.HealthConnection then
        self.State.HealthConnection:Disconnect()
        self.State.HealthConnection = nil
    end
    if self.State.CharacterConnection then
        self.State.CharacterConnection:Disconnect()
        self.State.CharacterConnection = nil
    end
end

function Modules.AntiKB:Disable()
    if not self.State.IsActive then return end
    self.State.IsActive = false
    self:_cleanup()
    DoNotif("Anti Kill Brick disabled.", 3)
end

function Modules.AntiKB:Enable()
    if self.State.IsActive then return end
    local char = LocalPlayer.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    
    
    local function onCharacterAdded()
        task.wait(0.1) 
        if LocalPlayer.Character and self.State.IsActive then
            self:Enable() 
        end
    end

    if not humanoid then
        
        self.State.CharacterConnection = LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
        return DoNotif("Character not available. Waiting for spawn.", 3)
    end
    
    self:Disable() 
    self.State.IsActive = true
    
    
    self.State.LastHealth = humanoid.Health or 100
    
    
    self.State.HealthConnection = humanoid.HealthChanged:Connect(function(newHealth)
        if not self.State.IsActive then return end
        
        
        if newHealth < self.State.LastHealth and newHealth > 0 then
            humanoid.Health = self.State.LastHealth 
        end
        
        
        self.State.LastHealth = humanoid.Health
    end)
    
    
    self.State.CharacterConnection = LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

    DoNotif("Anti Kill Brick enabled (Health Lock).", 3)
end

function Modules.AntiKB:Toggle()
    if self.State.IsActive then
        self:Disable()
    else
        self:Enable()
    end
end

Modules.PartSelector = {
    State = {
        IsActive = false,
        Connection = nil,
        UI = nil
    }
}

function Modules.PartSelector:Disable()
    if not self.State.IsActive then return end
    self.State.IsActive = false

    if self.State.Connection then
        self.State.Connection:Disconnect()
        self.State.Connection = nil
    end

    if self.State.UI then
        self.State.UI:Destroy()
        self.State.UI = nil
    end

    DoNotif("Part Selector disabled.", 3)
end

function Modules.PartSelector:Enable()
    if self.State.IsActive then return end
    self:Disable() 
    self.State.IsActive = true

    
    local RunService = game:GetService("RunService")
    local mouse = LocalPlayer:GetMouse() 

    
    local ui = Instance.new("ScreenGui")
    ui.Name = "PartSelectorUI"
    NaProtectUI(ui)
    self.State.UI = ui

    local mainFrame = Instance.new("Frame", ui)
    mainFrame.Size = UDim2.fromOffset(350, 110)
    mainFrame.Position = UDim2.new(0.5, -175, 1, -130)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    mainFrame.BackgroundTransparency = 0.2
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", mainFrame).Color = Color3.fromRGB(80, 80, 100)

    local title = Instance.new("TextLabel", mainFrame)
    title.Size = UDim2.new(1, 0, 0, 25)
    title.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
    title.Font = Enum.Font.GothamSemibold
    title.Text = "Part & Model Selector"
    title.TextColor3 = Color3.fromRGB(220, 220, 255)
    title.TextSize = 16
    local titleCorner = Instance.new("UICorner", title)
    titleCorner.CornerRadius = UDim.new(0, 6)
    
    local contentFrame = Instance.new("Frame", mainFrame)
    contentFrame.Size = UDim2.new(1, 0, 1, -25)
    contentFrame.Position = UDim2.fromOffset(0, 25)
    contentFrame.BackgroundTransparency = 1
    
    local listLayout = Instance.new("UIListLayout", contentFrame)
    listLayout.Padding = UDim.new(0, 4)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    local padding = Instance.new("UIPadding", contentFrame)
    padding.PaddingTop = UDim.new(0, 5)
    padding.PaddingLeft = UDim.new(0, 5)
    padding.PaddingRight = UDim.new(0, 5)

    local fullPathLabel = Instance.new("TextLabel", contentFrame)
    fullPathLabel.Name = "FullPathLabel"
    fullPathLabel.Size = UDim2.new(1, 0, 0, 16)
    fullPathLabel.BackgroundTransparency = 1
    fullPathLabel.Font = Enum.Font.Code
    fullPathLabel.Text = "Path: None"
    fullPathLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    fullPathLabel.TextXAlignment = Enum.TextXAlignment.Left
    fullPathLabel.TextSize = 12

    local modelNameLabel = Instance.new("TextLabel", contentFrame)
    modelNameLabel.Name = "ModelNameLabel"
    modelNameLabel.Size = UDim2.new(1, 0, 0, 18)
    modelNameLabel.BackgroundTransparency = 1
    modelNameLabel.Font = Enum.Font.GothamBold
    modelNameLabel.Text = "Model: None"
    modelNameLabel.TextColor3 = Color3.fromRGB(80, 150, 255)
    modelNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    modelNameLabel.TextSize = 14

    local copyButton = Instance.new("TextButton", contentFrame)
    copyButton.Name = "CopyButton"
    copyButton.Size = UDim2.new(1, 0, 0, 22)
    copyButton.BackgroundColor3 = Color3.fromRGB(80, 160, 80)
    copyButton.Font = Enum.Font.Code
    copyButton.Text = "Copy Model Name"
    copyButton.TextColor3 = Color3.white
    copyButton.TextSize = 14
    copyButton.Visible = false
    Instance.new("UICorner", copyButton).CornerRadius = UDim.new(0, 4)
    
    local currentModelName = nil
    copyButton.MouseButton1Click:Connect(function()
        if currentModelName then
            setclipboard(currentModelName)
            DoNotif("Copied '" .. currentModelName .. "' to clipboard.", 3)
        end
    end)
    
    
    self.State.Connection = RunService.RenderStepped:Connect(function()
        
        mouse.TargetFilter = LocalPlayer.Character or nil
        
        local part = mouse.Target
        
        if part then
            fullPathLabel.Text = "Path: " .. part:GetFullName()

            
            local topModel = nil
            local ancestor = part
            while ancestor and ancestor.Parent ~= workspace do
                ancestor = ancestor.Parent
            end
            if ancestor and ancestor:IsA("Model") then
                topModel = ancestor
            end

            if topModel then
                modelNameLabel.Text = "Model: " .. topModel.Name
                copyButton.Visible = true
                currentModelName = topModel.Name
            else
                modelNameLabel.Text = "Model: (Not in a model)"
                copyButton.Visible = false
                currentModelName = nil
            end
        else
            fullPathLabel.Text = "Path: None"
            modelNameLabel.Text = "Model: None"
            copyButton.Visible = false
            currentModelName = nil
        end
    end)

    DoNotif("Part Selector enabled.", 3)
end

function Modules.PartSelector:Toggle()
    if self.State.IsActive then
        self:Disable()
    else
        self:Enable()
    end
end

local isCameraFixed = false
local originalMaxZoom = nil
local originalOcclusionMode = nil
local cameraFixConnection = nil







local Players = game:GetService("Players")


Modules.HighlightPlayer = {
    State = {
        TargetPlayer = nil,
        HighlightInstance = nil,
        CharacterAddedConnection = nil
    }
}


local function findFirstPlayer(partialName)
    local lowerPartialName = string.lower(partialName)
    for _, player in ipairs(Players:GetPlayers()) do
        if string.lower(player.Name):sub(1, #lowerPartialName) == lowerPartialName then
            return player
        end
    end
    return nil
end



function Modules.HighlightPlayer:ApplyHighlight(character)
    if not character then return end

    
    if self.State.HighlightInstance then
        self.State.HighlightInstance:Destroy()
    end

    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(0, 255, 255) 
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.7
    highlight.OutlineTransparency = 0.2
    highlight.Parent = character

    
    self.State.HighlightInstance = highlight
end


function Modules.HighlightPlayer:ClearHighlight()
    if self.State.HighlightInstance then
        self.State.HighlightInstance:Destroy()
        self.State.HighlightInstance = nil
    end
    if self.State.CharacterAddedConnection then
        self.State.CharacterAddedConnection:Disconnect()
        self.State.CharacterAddedConnection = nil
    end
    if self.State.TargetPlayer then
        print("Highlight cleared from: " .. self.State.TargetPlayer.Name)
        self.State.TargetPlayer = nil
    end
end


RegisterCommand({
    Name = "highlightplayer",
    Aliases = {"highlight", "hlp", "findplayer"},
    Description = "Highlights a single player. Usage: highlight <PlayerName> | clear"
}, function(args)
    local argument = args[1]

    if not argument then
        print("Usage: highlight <PlayerName> | clear")
        return
    end

    
    if string.lower(argument) == "clear" or string.lower(argument) == "reset" then
        if not Modules.HighlightPlayer.State.TargetPlayer then
            print("No player is currently highlighted.")
            return
        end
        Modules.HighlightPlayer:ClearHighlight()
        return
    end

    
    local targetPlayer = findFirstPlayer(argument)
    if not targetPlayer then
        print("Error: Player '" .. argument .. "' not found.")
        return
    end

    
    Modules.HighlightPlayer:ClearHighlight()

    
    Modules.HighlightPlayer.State.TargetPlayer = targetPlayer
    print("Now highlighting: " .. targetPlayer.Name)

    
    if targetPlayer.Character then
        Modules.HighlightPlayer:ApplyHighlight(targetPlayer.Character)
    end

    
    Modules.HighlightPlayer.State.CharacterAddedConnection = targetPlayer.CharacterAdded:Connect(function(newCharacter)
        Modules.HighlightPlayer:ApplyHighlight(newCharacter)
    end)
end)







local Players = game:GetService("Players")


Modules.BypassPropertyChecks = {
    State = {
        Enabled = false,
        OriginalMetatable = nil,
        FakeProperties = {
            WalkSpeed = 16,
            JumpPower = 50,
            JumpHeight = 7.2
        }
    }
}


RegisterCommand({
    Name = "bypasspropertychecks",
    Aliases = {"bprop", "bpc"},
    Description = "Toggles a metamethod hook to hide changes to WalkSpeed/JumpPower from local anti-cheats."
}, function(args)
    local localPlayer = Players.LocalPlayer
    local character = localPlayer and localPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if not humanoid then
        print("Error: Humanoid not found. Cannot apply bypass.")
        return
    end

    
    Modules.BypassPropertyChecks.State.Enabled = not Modules.BypassPropertyChecks.State.Enabled

    if Modules.BypassPropertyChecks.State.Enabled then
        print("Property Check Bypass: [Enabled]")
        
        Modules.BypassPropertyChecks.State.OriginalMetatable = getmetatable(humanoid)

        local newMt = {
            __index = function(self, key)
                
                if Modules.BypassPropertyChecks.State.FakeProperties[key] then
                    return Modules.BypassPropertyChecks.State.FakeProperties[key]
                end
                
                return Modules.BypassPropertyChecks.State.OriginalMetatable.__index(self, key)
            end
        }
        
        
        setmetatable(humanoid, newMt)
    else
        print("Property Check Bypass: [Disabled]")
        
        if Modules.BypassPropertyChecks.State.OriginalMetatable then
            setmetatable(humanoid, Modules.BypassPropertyChecks.State.OriginalMetatable)
            Modules.BypassPropertyChecks.State.OriginalMetatable = nil
        end
    end
end)







local RunService = game:GetService("RunService")
local Players = game:GetService("Players")


Modules.AntiCFrameTeleport = {
    State = {
        Enabled = false,
        Connection = nil,
        LastCFrame = nil,
        
        
        MaxDistancePerFrame = 75
    }
}


function Modules.AntiCFrameTeleport:CheckForTeleport()
    local localPlayer = Players.LocalPlayer
    local character = localPlayer and localPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")

    if not rootPart then return end

    local currentCFrame = rootPart.CFrame
    
    
    if Modules.AntiCFrameTeleport.State.LastCFrame then
        local distance = (currentCFrame.Position - Modules.AntiCFrameTeleport.State.LastCFrame.Position).Magnitude
        
        
        if distance > Modules.AntiCFrameTeleport.State.MaxDistancePerFrame then
            rootPart.CFrame = Modules.AntiCFrameTeleport.State.LastCFrame 
            return 
        end
    end
    
    
    Modules.AntiCFrameTeleport.State.LastCFrame = rootPart.CFrame
end


RegisterCommand({
    Name = "anticframetp",
    Aliases = {"antiteleport", "actp"},
    Description = "Toggles an anti-teleport system that reverts sudden CFrame changes."
}, function(args)
    
    Modules.AntiCFrameTeleport.State.Enabled = not Modules.AntiCFrameTeleport.State.Enabled

    if Modules.AntiCFrameTeleport.State.Enabled then
        print("Anti-CFrame TP: [Enabled]")
        
        
        Modules.AntiCFrameTeleport.State.Connection = RunService.Stepped:Connect(function()
            Modules.AntiCFrameTeleport:CheckForTeleport()
        end)
    else
        print("Anti-CFrame TP: [Disabled]")
        
        if Modules.AntiCFrameTeleport.State.Connection then
            Modules.AntiCFrameTeleport.State.Connection:Disconnect()
            Modules.AntiCFrameTeleport.State.Connection = nil
            Modules.AntiCFrameTeleport.State.LastCFrame = nil 
        end
    end
end)







local Workspace = game:GetService("Workspace")


Modules.FovChanger = {
    State = {
        
        DefaultFov = 70
    }
}


RegisterCommand({
    Name = "fov",
    Aliases = {"fieldofview", "camfov"},
    Description = "Changes the client's camera Field of View. Usage: fov <1-120> | reset"
}, function(args)
    local camera = Workspace.CurrentCamera
    if not camera then
        print("Error: Could not find the game camera.")
        return
    end

    local argument = args[1]

    
    if not argument then
        print("Usage: fov <number between 1-120> or 'reset'")
        print("Your current FOV is: " .. camera.FieldOfView)
        return
    end

    
    if string.lower(argument) == "reset" then
        camera.FieldOfView = Modules.FovChanger.State.DefaultFov
        print("FOV has been reset to " .. Modules.FovChanger.State.DefaultFov .. ".")
        return
    end

    
    local newFov = tonumber(argument)

    
    if not newFov then
        print("Error: Invalid argument. Please provide a number (e.g., 'fov 90') or 'reset'.")
        return
    end

    
    local clampedFov = math.clamp(newFov, 1, 120)
    
    
    camera.FieldOfView = clampedFov
    print("Camera FOV set to " .. clampedFov .. ".")
end)







local Players = game:GetService("Players")


Modules.HitboxAlter = {
    State = {
        Enabled = false,
        
        
        OriginalSizes = {},
        CharacterAddedConnection = nil,
        
        BodyPartNames = {
            "Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand",
            "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
            "RightUpperLeg", "RightLowerLeg", "RightFoot", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"
        }
    }
}


function Modules.HitboxAlter:AlterCharacter(character)
    if not character then return end

    
    local newSize = Vector3.new(0.5, 0.5, 0.5)

    for _, partName in ipairs(self.State.BodyPartNames) do
        local part = character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            
            
            if not self.State.OriginalSizes[partName] then
                self.State.OriginalSizes[partName] = part.Size
            end
            part.Size = newSize
        end
    end
end

function Modules.HitboxAlter:RestoreCharacter(character)
    if not character then return end

    for partName, originalSize in pairs(self.State.OriginalSizes) do
        local part = character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            part.Size = originalSize
        end
    end
end


function Modules.HitboxAlter:OnCharacterAdded(newCharacter)
    
    task.wait(0.1)
    self:AlterCharacter(newCharacter)
end


RegisterCommand({
    Name = "alterhitbox",
    Aliases = {"smallhitbox", "ahb"},
    Description = "Shrinks your character's limbs to make your hitbox smaller."
}, function(args)
    
    Modules.HitboxAlter.State.Enabled = not Modules.HitboxAlter.State.Enabled
    local localPlayer = Players.LocalPlayer

    if Modules.HitboxAlter.State.Enabled then
        print("Hitbox Alteration: [Enabled]")
        
        
        if localPlayer.Character then
            Modules.HitboxAlter:AlterCharacter(localPlayer.Character)
        end

        
        Modules.HitboxAlter.State.CharacterAddedConnection = localPlayer.CharacterAdded:Connect(function(char)
            Modules.HitboxAlter:OnCharacterAdded(char)
        end)
    else
        print("Hitbox Alteration: [Disabled]")
        
        
        if localPlayer.Character then
            Modules.HitboxAlter:RestoreCharacter(localPlayer.Character)
        end
        
        
        if Modules.HitboxAlter.State.CharacterAddedConnection then
            Modules.HitboxAlter.State.CharacterAddedConnection:Disconnect()
            Modules.HitboxAlter.State.CharacterAddedConnection = nil
        end

        
        Modules.HitboxAlter.State.OriginalSizes = {}
    end
end)







local Players = game:GetService("Players")


Modules.SetSpawnPoint = {
    State = {
        
        CustomSpawnCFrame = nil,
        
        CharacterAddedConnection = nil
    }
}



function Modules.SetSpawnPoint:OnCharacterAdded(newCharacter)
    
    if not self.State.CustomSpawnCFrame then return end

    
    local rootPart = newCharacter:WaitForChild("HumanoidRootPart", 5) 

    if rootPart then
        
        
        task.wait() 
        rootPart.CFrame = self.State.CustomSpawnCFrame
    end
end


RegisterCommand({
    Name = "setspawnpoint",
    Aliases = {"setspawn", "ssp"},
    Description = "Sets your respawn point to your current location. Use 'clear' to reset."
}, function(args)
    local localPlayer = Players.LocalPlayer
    local commandArg = args[1] and string.lower(args[1])

    
    if commandArg == "clear" or commandArg == "reset" then
        if Modules.SetSpawnPoint.State.CustomSpawnCFrame then
            Modules.SetSpawnPoint.State.CustomSpawnCFrame = nil
            print("Custom spawn point cleared. You will now use the default spawn.")
            
            
            if Modules.SetSpawnPoint.State.CharacterAddedConnection then
                Modules.SetSpawnPoint.State.CharacterAddedConnection:Disconnect()
                Modules.SetSpawnPoint.State.CharacterAddedConnection = nil
            end
        else
            print("No custom spawn point was set.")
        end
        return 
    end

    
    local character = localPlayer and localPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")

    if not rootPart then
        print("Error: Could not set spawn point. Player character not found.")
        return
    end

    
    Modules.SetSpawnPoint.State.CustomSpawnCFrame = rootPart.CFrame
    print("Custom spawn point set at: " .. tostring(rootPart.Position))

    
    
    if not Modules.SetSpawnPoint.State.CharacterAddedConnection then
        Modules.SetSpawnPoint.State.CharacterAddedConnection = localPlayer.CharacterAdded:Connect(function(char)
            Modules.SetSpawnPoint:OnCharacterAdded(char)
        end)
    end
end)







local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")


Modules.AntiVoid = {
    State = {
        Enabled = false,
        Connection = nil,
        LastSafePosition = nil,
        
        VoidThreshold = Workspace.FallenPartsDestroyHeight
    }
}


function Modules.AntiVoid:CheckVoid()
    local localPlayer = Players.LocalPlayer
    local character = localPlayer and localPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not rootPart then return end
    
    local currentPosition = rootPart.Position

    
    
    if humanoid.FloorMaterial ~= Enum.Material.Air then
        Modules.AntiVoid.State.LastSafePosition = currentPosition
    end

    
    if currentPosition.Y < Modules.AntiVoid.State.VoidThreshold then
        
        if Modules.AntiVoid.State.LastSafePosition then
            rootPart.CFrame = CFrame.new(Modules.AntiVoid.State.LastSafePosition)
        end
    end
end


RegisterCommand({
    Name = "antivoid",
    Aliases = {"novoid", "av"},
    Description = "Toggles an anti-void system that saves you from falling out of the map."
}, function(args)
    
    Modules.AntiVoid.State.Enabled = not Modules.AntiVoid.State.Enabled

    if Modules.AntiVoid.State.Enabled then
        print("Anti-Void: [Enabled]")
        
        Modules.AntiVoid.State.Connection = RunService.Heartbeat:Connect(function()
            Modules.AntiVoid:CheckVoid()
        end)
    else
        print("Anti-Void: [Disabled]")
        
        if Modules.AntiVoid.State.Connection then
            Modules.AntiVoid.State.Connection:Disconnect()
            Modules.AntiVoid.State.Connection = nil
            Modules.AntiVoid.State.LastSafePosition = nil 
        end
    end
end)



--======================================================================================
-- MODULE: RemoteBypass (v2)
-- PURPOSE: Bypasses client-side hooks on FireServer/InvokeServer by using the
--          '__namecall' hooking technique to reliably retrieve the original C functions.
--          This is a more robust method than metatable indexing.
-- USAGE: Run 'remotebypass'. Use _G.SafeFireServer() and _G.SafeInvokeServer() globally.
--======================================================================================

Modules.RemoteBypass = {
    State = {
        IsActive = false,
        OriginalFire = nil,
        OriginalInvoke = nil
    }
};

--- Initializes the bypass by temporarily hooking '__namecall' to capture the functions.
function Modules.RemoteBypass:Initialize()
    -- This function is the core of the bypass. It will be temporarily set as the
    -- namecall handler to intercept method calls.
    local namecall_hook = function(instance, ...)
        if not Modules.RemoteBypass.State.OriginalFire and typeof(instance) == "Instance" and instance.ClassName == "RemoteEvent" then
            -- The moment a RemoteEvent method is called, getnamecallmethod() returns the
            -- actual C function we want to capture.
            Modules.RemoteBypass.State.OriginalFire = getnamecallmethod()
        elseif not Modules.RemoteBypass.State.OriginalInvoke and typeof(instance) == "Instance" and instance.ClassName == "RemoteFunction" then
            -- Same logic for RemoteFunction.
            Modules.RemoteBypass.State.OriginalInvoke = getnamecallmethod()
        end
        -- We return nil to prevent the original call from going through and erroring.
        return nil
    end

    -- Step 1: Store the original namecall method so we can restore it later. This is critical.
    local original_namecall = getnamecallmethod()

    -- Step 2: Create temporary, clean instances.
    local tempEvent = Instance.new("RemoteEvent")
    local tempFunc = Instance.new("RemoteFunction")

    -- Step 3: Set our hook as the new namecall method.
    setnamecallmethod(namecall_hook)

    -- Step 4: Trigger the hook by attempting to call the methods. We use pcall because we
    -- expect our hook to intercept and stop the call, not for it to succeed.
    pcall(function() tempEvent:FireServer() end)
    pcall(function() tempFunc:InvokeServer() end)

    -- Step 5: CRITICAL - Restore the original namecall method immediately.
    setnamecallmethod(original_namecall)

    -- Step 6: Clean up the temporary instances.
    tempEvent:Destroy()
    tempFunc:Destroy()

    -- Step 7: Final validation and creation of global wrappers.
    if not (self.State.OriginalFire and self.State.OriginalInvoke) then
        error("Bypass failed: Could not capture remote functions via __namecall hook.")
        return
    end

    _G.SafeFireServer = function(remote, ...)
        return pcall(self.State.OriginalFire, remote, ...)
    end

    _G.SafeInvokeServer = function(remote, ...)
        local success, result = pcall(self.State.OriginalInvoke, remote, ...)
        if success then
            return result
        else
            warn("[SafeInvokeServer Error] " .. tostring(result))
        end
    end
end

--======================================================================================
-- COMMAND REGISTRATION (No changes needed here)
--======================================================================================
RegisterCommand({
    Name = "remotebypass",
    Aliases = {"rb", "safeinvoke"},
    Description = "Enables global SafeFireServer/SafeInvokeServer to bypass remote spies."
}, function(args)
    if Modules.RemoteBypass.State.IsActive then
        print("--> Remote Bypass is already active.")
        return
    end

    local success, err = pcall(function()
        Modules.RemoteBypass:Initialize()
    end)

    if success then
        Modules.RemoteBypass.State.IsActive = true
        print("￯﾿ﾯ￯ﾾ﾿￯ﾾﾢ￯﾿ﾯ￯ﾾﾾ￯ﾾﾜ￯﾿ﾯ￯ﾾﾾ￯ﾾﾅ Remote Bypass Initialized (v2). Your scripts can now use the safe functions.")
        print("   -> Usage: _G.SafeFireServer(RemoteEvent, ...)")
        print("   -> Usage: _G.SafeInvokeServer(RemoteFunction, ...)")
    else
        print("￯﾿ﾯ￯ﾾ﾿￯ﾾﾢ￯﾿ﾯ￯ﾾﾾ￯ﾾﾝ￯﾿ﾯ￯ﾾﾾ￯ﾾﾌ Remote Bypass Failed: " .. tostring(err))
    end
end)



local Players = game:GetService("Players")


Modules.SpoofOwnerId = {
    State = {
        
        OriginalCreatorId = game.CreatorId,
        IsSpoofed = false
    }
}


local function findFirstPlayer(partialName)
    local lowerPartialName = string.lower(partialName)
    for _, player in ipairs(Players:GetPlayers()) do
        if string.lower(player.Name):sub(1, #lowerPartialName) == lowerPartialName then
            return player
        end
    end
    return nil
end


RegisterCommand({
    Name = "spoofownerid",
    Aliases = {"spoofowner", "soid"},
    Description = "Spoofs the game's owner ID locally. Usage: spoofownerid <PlayerName/UserId> | clear"
}, function(args)
    local argument = args[1]

    
    if not argument then
        print("Usage: spoofownerid <PlayerName/UserId> | clear")
        return
    end

    if string.lower(argument) == "clear" or string.lower(argument) == "reset" then
        if not Modules.SpoofOwnerId.State.IsSpoofed then
            print("Owner ID is not currently spoofed.")
            return
        end
        
        
        game.CreatorId = Modules.SpoofOwnerId.State.OriginalCreatorId
        Modules.SpoofOwnerId.State.IsSpoofed = false
        print("Owner ID has been reverted to the original: " .. game.CreatorId)
        return
    end

    
    if Modules.SpoofOwnerId.State.IsSpoofed then
        print("An owner ID is already being spoofed. Use 'spoofownerid clear' to reset it first.")
        return
    end

    local targetId = nil
    
    
    local isUserId = tonumber(argument)
    if isUserId then
        targetId = isUserId
    else
        
        local targetPlayer = findFirstPlayer(argument)
        if targetPlayer then
            targetId = targetPlayer.UserId
        else
            print("Error: Player '" .. argument .. "' not found.")
            return
        end
    end

    
    if targetId then
        game.CreatorId = targetId
        Modules.SpoofOwnerId.State.IsSpoofed = true
        print("Successfully spoofed game Owner ID to: " .. targetId)
    else
        print("Error: Could not determine a valid target ID.")
    end
end)








local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ProximityPromptService = game:GetService("ProximityPromptService")


Modules.FireInteractables = {
    State = {} 
}


RegisterCommand({
    Name = "fireall",
    Aliases = {"triggerall", "fa"},
    Description = "Fires all ProximityPrompts and TouchEvents in a radius. Usage: fireall <radius>"
}, function(args)
    
    local localPlayer = Players.LocalPlayer
    local character = localPlayer and localPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")

    if not rootPart then
        print("Error: Could not find HumanoidRootPart. Is your character loaded?")
        return
    end

    
    local radius = tonumber(args[1]) or 25 
    local playerPosition = rootPart.Position

    
    local touchCount = 0
    local promptCount = 0

    print(string.format("Searching for interactables within a %d stud radius...", radius))

    
    for _, descendant in ipairs(Workspace:GetDescendants()) do
        
        local success, err = pcall(function()
            
            if descendant:IsA("ProximityPrompt") and descendant.Enabled then
                local part = descendant.Parent
                if part and part:IsA("BasePart") then
                    if (part.Position - playerPosition).Magnitude <= radius then
                        
                        ProximityPromptService:InputTriggered(descendant)
                        promptCount = promptCount + 1
                    end
                end
            
            
            elseif descendant:IsA("BasePart") then
                if (descendant.Position - playerPosition).Magnitude <= radius then
                    
                    if not descendant:IsDescendantOf(character) then
                        
                        descendant.Touched:Fire(rootPart)
                        touchCount = touchCount + 1
                    end
                end
            end
        end)

        if not success then
            warn("FireInteractables Warning: Could not process an object. Details: " .. err)
        end
    end

    
    print(string.format("Execution complete. Triggered: %d ProximityPrompts and fired %d TouchEvents.", promptCount, touchCount))
    print("Note: ClickDetectors cannot be fired from a LocalScript and were ignored.")
end)








local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")


Modules.ServerHop = {
    State = {} 
}


RegisterCommand({
    Name = "serverhop",
    Aliases = {"hop", "sh"},
    Description = "Finds a new server and teleports you to it."
}, function(args)
    local localPlayer = Players.LocalPlayer
    local currentPlaceId = game.PlaceId
    local currentJobId = game.JobId

    print("Fetching server list, please wait...")

    
    local requestUrl = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", currentPlaceId)

    local success, response = pcall(function()
        return HttpService:GetAsync(requestUrl)
    end)

    if not success then
        print("Server Hop Error: Could not fetch the server list. The API may be down or unreachable.")
        return
    end

    local decodedResponse = HttpService:JSONDecode(response)
    local serverList = decodedResponse and decodedResponse.data

    if not serverList or #serverList == 0 then
        print("Server Hop Error: No other servers were found.")
        return
    end

    
    local validServers = {}
    for _, server in ipairs(serverList) do
        
        if server.id ~= currentJobId and server.playing < server.maxPlayers then
            table.insert(validServers, server)
        end
    end

    if #validServers == 0 then
        print("Server Hop: No other non-full servers are available right now.")
        return
    end

    
    local targetServer = validServers[math.random(1, #validServers)]
    print(string.format("Found %d valid servers. Hopping to server with %d/%d players.", #validServers, targetServer.playing, targetServer.maxPlayers))

    
    local teleportSuccess, teleportError = pcall(function()
        TeleportService:TeleportToPlaceInstance(currentPlaceId, targetServer.id, localPlayer)
    end)

    if not teleportSuccess then
        print("Server Hop failed: " .. teleportError)
    end
end)







local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")


Modules.RejoinServer = {
    State = {} 
}


RegisterCommand({
    Name = "rejoin",
    Aliases = {"rj", "reconnect"},
    Description = "Teleports you back to the current server."
}, function(args)
    local localPlayer = Players.LocalPlayer
    
    if not localPlayer then
        print("Error: Could not find LocalPlayer.")
        return
    end

    local placeId = game.PlaceId
    local jobId = game.JobId

    print("Rejoining server... Please wait.")

    
    local success, errorMessage = pcall(function()
        TeleportService:TeleportToPlaceInstance(placeId, jobId, localPlayer)
    end)

    if not success then
        print("Rejoin failed: " .. errorMessage)
    end
end)







local ReplicatedStorage = game:GetService("ReplicatedStorage")


Modules.BypassChatFilter = {
    State = {
        Enabled = false,
        ChatRemote = nil,
        OriginalNamecall = nil
    },
    
    BypassFont = {
        ['a'] = '￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾐ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾰ', ['b'] = '￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾐ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾬ', ['c'] = '￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾑ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾁ', ['d'] = '￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾔ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾁ', ['e'] = '￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾐ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾵ',
        ['f'] = 'f', ['g'] = '￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾉ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾡ', ['h'] = '￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾒ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾻ', ['i'] = '￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾑ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾖ', ['j'] = '￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾑ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾘ',
        ['k'] = 'k', ['l'] = 'l', ['m'] = 'm', ['n'] = 'n', ['o'] = '￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾐ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ',
        ['p'] = '￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾑ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾀ', ['q'] = '￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾔ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾛ', ['r'] = '￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾐ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾳ', ['s'] = '￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾑ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾕ', ['t'] = 't',
        ['u'] = 'u', ['v'] = 'v', ['w'] = 'w', ['x'] = '￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾑ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾅ', ['y'] = '￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾑ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾃ',
        ['z'] = 'z',
        ['A'] = '￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾐ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾐ', ['B'] = '￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾐ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾒ', ['C'] = '￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾐ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾡ', ['D'] = '￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾄ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾎ', ['E'] = '￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾐ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾕ',
        ['F'] = 'F', ['G'] = 'G', ['H'] = '￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾐ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾝ', ['I'] = '￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾐ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾆ', ['J'] = '￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾐ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾈ',
        ['K'] = 'K', ['L'] = 'L', ['M'] = '￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾐ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾜ', ['N'] = 'N', ['O'] = '￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾐ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾞ',
        ['P'] = '￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾐ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾠ', ['Q'] = '￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾔ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾚ', ['R'] = 'R', ['S'] = '￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾐ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾅ', ['T'] = '￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾐ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾢ',
        ['U'] = 'U', ['V'] = 'V', ['W'] = 'W', ['X'] = '￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾐ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾥ', ['Y'] = '￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾐ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾯ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾣ',
        ['Z'] = 'Z'
    }
}



function Modules.BypassChatFilter:ConvertToBypass(text)
    local bypassedText = ""
    for i = 1, #text do
        local char = text:sub(i, i)
        
        bypassedText = bypassedText .. (self.BypassFont[char] or char)
    end
    return bypassedText
end


RegisterCommand({
    Name = "bypasschatfilter",
    Aliases = {"bcf", "chatbypass"},
    Description = "Toggles a chat filter bypass by replacing characters with Unicode equivalents."
}, function(args)
    
    Modules.BypassChatFilter.State.Enabled = not Modules.BypassChatFilter.State.Enabled

    if Modules.BypassChatFilter.State.Enabled then
        
        local success, chatRemote = pcall(function()
            return ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents"):WaitForChild("SayMessageRequest")
        end)

        if not success then
            print("Chat Bypass Error: Could not find the standard chat RemoteEvent. This game may use a custom chat system.")
            Modules.BypassChatFilter.State.Enabled = false 
            return
        end

        Modules.BypassChatFilter.State.ChatRemote = chatRemote
        
        
        local mt = getrawmetatable(chatRemote)
        Modules.BypassChatFilter.State.OriginalNamecall = mt.__namecall

        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}

            
            if method == "FireServer" and #args > 0 then
                
                args[1] = Modules.BypassChatFilter:ConvertToBypass(args[1])
                print("Bypassed message: " .. args[1])
            end

            
            return Modules.BypassChatFilter.State.OriginalNamecall(self, table.unpack(args))
        end)
        
        print("Chat Filter Bypass: [Enabled]")
    else
        
        if Modules.BypassChatFilter.State.ChatRemote and Modules.BypassChatFilter.State.OriginalNamecall then
            local mt = getrawmetatable(Modules.BypassChatFilter.State.ChatRemote)
            mt.__namecall = Modules.BypassChatFilter.State.OriginalNamecall
            
            
            Modules.BypassChatFilter.State.ChatRemote = nil
            Modules.BypassChatFilter.State.OriginalNamecall = nil
            
            print("Chat Filter Bypass: [Disabled]")
        else
            print("Chat Filter Bypass: Was not active or already disabled.")
        end
    end
end)









local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")


Modules.AutoAttack = {
    State = {
        Enabled = false,
        ClickDelay = 0.1, 
        Connection = nil,
        LastClickTime = 0
    }
}


function Modules.AutoAttack:AttackLoop()
    
    if UserInputService:GetFocusedTextBox() then
        return
    end

    local currentTime = os.clock()
    
    
    if currentTime - self.State.LastClickTime > self.State.ClickDelay then
        
        
        mouse1press()
        task.wait() 
        mouse1release()

        
        self.State.LastClickTime = currentTime
    end
end


function Modules.AutoAttack:Enable()
    self.State.Enabled = true
    self.State.LastClickTime = 0 
    
    
    self.State.Connection = RunService.Heartbeat:Connect(function()
        self:AttackLoop()
    end)
    print("￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾢ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾜ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾅ Auto-Attack: [Enabled] | Delay: " .. self.State.ClickDelay * 1000 .. "ms")
end


function Modules.AutoAttack:Disable()
    self.State.Enabled = false
    if self.State.Connection then
        self.State.Connection:Disconnect()
        self.State.Connection = nil
    end
    print("￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾢ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾚ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾪ Auto-Attack: [Disabled]")
end





RegisterCommand({
    Name = "autoattack",
    Aliases = {"aa", "autoclick"},
    Description = "Toggles auto-click. Usage: autoattack [delay_in_ms]"
}, function(args)
    
    local newDelay = tonumber(args[1])
    if newDelay and newDelay > 0 then
        
        Modules.AutoAttack.State.ClickDelay = newDelay / 1000
        print("--> Auto-Attack delay set to: " .. newDelay .. "ms")
        
        
        if Modules.AutoAttack.State.Enabled then
            print("￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾢ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾜ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾅ Auto-Attack: [Enabled] | Delay: " .. newDelay .. "ms")
        end
        return 
    end

    
    if Modules.AutoAttack.State.Enabled then
        Modules.AutoAttack:Disable()
    else
        Modules.AutoAttack:Enable()
    end
end)

--======================================================================================
-- MODULE: AntiRagdoll (v2 - Re-architected)
-- PURPOSE: Prevents the player's character from entering a ragdoll or physics state.
--          This version is architected to be robust and automatically handle
--          character respawns.
--======================================================================================
-- Services
local Players = game:GetService("Players")

-- Module Definition
Modules.AntiRagdoll = {
    State = {
        Enabled = false,
        -- We store connections here to manage them and prevent memory leaks.
        -- Using a nested table allows for managing multiple connections at once.
        Connections = {}
    }
}

--- The core logic that checks and overrides the Humanoid's state.
-- @param humanoid The Humanoid instance to monitor.
function Modules.AntiRagdoll:OnStateChanged(humanoid, newState)
    -- We check for Ragdoll, Physics, and FallingDown, as they are often related.
    if newState == Enum.HumanoidStateType.Ragdoll or newState == Enum.HumanoidStateType.Physics or newState == Enum.HumanoidStateType.FallingDown then
        -- This command instantly forces the Humanoid to attempt recovery.
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end

--- Sets up the anti-ragdoll logic for a given character model.
-- @param character The player's character model.
function Modules.AntiRagdoll:SetupCharacter(character)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not humanoid then return end

    -- Disconnect any previous connection for this specific character to be safe.
    if self.State.Connections.StateChanged then
        self.State.Connections.StateChanged:Disconnect()
    end

    -- Connect to the StateChanged event of the new humanoid.
    self.State.Connections.StateChanged = humanoid.StateChanged:Connect(function(_, newState)
        self:OnStateChanged(humanoid, newState)
    end)
end

--- Activates the entire anti-ragdoll system.
function Modules.AntiRagdoll:Enable()
    self.State.Enabled = true
    local localPlayer = Players.LocalPlayer

    -- Set up a connection that listens for when a new character spawns.
    -- This is the key to handling respawns correctly.
    self.State.Connections.CharacterAdded = localPlayer.CharacterAdded:Connect(function(character)
        self:SetupCharacter(character)
    end)

    -- If the character already exists when this is enabled, set it up immediately.
    if localPlayer.Character then
        self:SetupCharacter(localPlayer.Character)
    end

    print("￯﾿ﾯ￯ﾾ﾿￯ﾾﾢ￯﾿ﾯ￯ﾾﾾ￯ﾾﾜ￯﾿ﾯ￯ﾾﾾ￯ﾾﾅ Anti-Ragdoll: [Enabled]")
end

--- Deactivates the system and cleans up all connections.
function Modules.AntiRagdoll:Disable()
    self.State.Enabled = false

    -- Disconnect all active connections to stop the script's behavior and prevent memory leaks.
    for key, connection in pairs(self.State.Connections) do
        if typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        end
    end
    -- Clear the table for a clean state.
    self.State.Connections = {}

    print("￯﾿ﾯ￯ﾾ﾿￯ﾾﾢ￯﾿ﾯ￯ﾾﾾ￯ﾾﾚ￯﾿ﾯ￯ﾾﾾ￯ﾾﾪ Anti-Ragdoll: [Disabled]")
end

--======================================================================================
-- COMMAND REGISTRATION
-- This is now in the main scope, so it runs immediately when the script is loaded.
--======================================================================================
RegisterCommand({
    Name = "antiragdoll",
    Aliases = {"ar", "noragdoll"},
    Description = "Toggles a state that prevents your character from being ragdolled."
}, function(args)
    -- The command now simply acts as a toggle, calling the robust enable/disable functions.
    if Modules.AntiRagdoll.State.Enabled then
        Modules.AntiRagdoll:Disable()
    else
        Modules.AntiRagdoll:Enable()
    end
end)


local RunService = game:GetService("RunService")
local Players = game:GetService("Players")


Modules.AntiFling = {
    State = {
        Enabled = false,
        Connection = nil,
        MaxVelocity = 200 
    }
}


function Modules.AntiFling:CheckVelocity()
    local localPlayer = Players.LocalPlayer
    local character = localPlayer and localPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")

    if not rootPart then return end

    
    if rootPart.AssemblyLinearVelocity.Magnitude > Modules.AntiFling.State.MaxVelocity then
        rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    end

    
    if rootPart.AssemblyAngularVelocity.Magnitude > Modules.AntiFling.State.MaxVelocity then
        rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end
end


RegisterCommand({
    Name = "antifling",
    Aliases = {"nofling", "af"},
    Description = "Toggles an anti-fling system to prevent high-velocity character flinging."
}, function(args)
    
    Modules.AntiFling.State.Enabled = not Modules.AntiFling.State.Enabled

    if Modules.AntiFling.State.Enabled then
        
        print("Anti-Fling: [Enabled]")
        Modules.AntiFling.State.Connection = RunService.Heartbeat:Connect(function()
            Modules.AntiFling:CheckVelocity()
        end)
    else
        
        print("Anti-Fling: [Disabled]")
        if Modules.AntiFling.State.Connection then
            Modules.AntiFling.State.Connection:Disconnect()
            Modules.AntiFling.State.Connection = nil
        end
    end
end)


--======================================================================================
-- MODULE: AntiRubberband (v2 - Loop Based)
-- PURPOSE: Bypasses server-sided rubberbanding using a high-frequency loop. This is a
--          more compatible method that does not rely on protected functions like
--          setmetatable, making it suitable for hardened execution environments.
--======================================================================================

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Module Definition
Modules.AntiRubberband = {
    State = {
        Enabled = false,
        Connection = nil,
        LastCFrame = nil,
        -- CONFIGURATION: The maximum distance your character can be moved in a single
        -- frame before it's considered a server rubberband and is reverted.
        REJECTION_DISTANCE = 15 -- in studs
    }
};

--- This is the core function, connected to RunService.Stepped. It runs before each physics frame.
function Modules.AntiRubberband:ValidateCFrame()
    local localPlayer = Players.LocalPlayer
    local character = localPlayer and localPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")

    -- If we can't find the root part, reset our state and do nothing.
    if not rootPart then
        self.State.LastCFrame = nil
        return
    end

    local currentCFrame = rootPart.CFrame

    -- If we have a record of the last known "good" CFrame, we perform our check.
    if self.State.LastCFrame then
        local distance = (currentCFrame.Position - self.State.LastCFrame.Position).Magnitude
        
        -- If the distance change is huge, it's a server-forced teleport.
        -- We instantly reject it by setting the CFrame back to our last known good position.
        if distance > self.State.REJECTION_DISTANCE then
            rootPart.CFrame = self.State.LastCFrame
        else
            -- If the distance change is small, it's the player's own noclip/movement.
            -- We accept it by updating our last known "good" position to the current one.
            self.State.LastCFrame = currentCFrame
        end
    else
        -- If we don't have a last CFrame, this is the first run. We'll initialize it.
        self.State.LastCFrame = currentCFrame
    end
end

--======================================================================================
-- COMMAND REGISTRATION
--======================================================================================
RegisterCommand({
    Name = "antirubberband",
    Aliases = {"antirp", "arb"},
    Description = "Toggles an anti-rubberband system to allow noclip to bypass server checks."
}, function(args)
    Modules.AntiRubberband.State.Enabled = not Modules.AntiRubberband.State.Enabled

    if Modules.AntiRubberband.State.Enabled then
        print("￯﾿ﾯ￯ﾾ﾿￯ﾾﾢ￯﾿ﾯ￯ﾾﾾ￯ﾾﾜ￯﾿ﾯ￯ﾾﾾ￯ﾾﾅ Anti-Rubberband: [Enabled]")
        -- Connect our validation function to RunService.Stepped, which runs every frame.
        Modules.AntiRubberband.State.Connection = RunService.Stepped:Connect(function()
            Modules.AntiRubberband:ValidateCFrame()
        end)
    else
        print("￯﾿ﾯ￯ﾾ﾿￯ﾾﾢ￯﾿ﾯ￯ﾾﾾ￯ﾾﾚ￯﾿ﾯ￯ﾾﾾ￯ﾾﾪ Anti-Rubberband: [Disabled]")
        -- If the connection exists, disconnect it to stop the loop and save performance.
        if Modules.AntiRubberband.State.Connection then
            Modules.AntiRubberband.State.Connection:Disconnect()
            Modules.AntiRubberband.State.Connection = nil
            Modules.AntiRubberband.State.LastCFrame = nil -- Clear state
        end
    end
end)


--======================================================================================
-- MODULE: StandReach (v7 - Definitive Pathing)
-- PURPOSE: A final, surgically precise script that uses the exact, known object
--          hierarchy with WaitForChild to be 100% reliable.
-- ARCHITECTURE:
--  - Abandons ALL generic searching (_findFirstDescendant is removed).
--  - Uses a direct path: standModel:WaitForChild("Sword"):WaitForChild("Sword").
--  - Leverages Roblox's built-in WaitForChild to handle all timing issues robustly.
--======================================================================================

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Module Definition
Modules.StandReach = {
    State = { OriginalSizes = {} },
    Config = { PossibleStandNames = { "Summer Chariot", "Silver Chariot" } }
}

--- Patiently finds the root Stand model by its name.
function Modules.StandReach:_findPlayerStand()
    local myCharacter = LocalPlayer.Character
    if not myCharacter then return nil end
    local timeout = 3; local startTime = os.clock();
    repeat
        for _, standName in ipairs(self.Config.PossibleStandNames) do
            local standModel = myCharacter:FindFirstChild(standName)
            if standModel and standModel:IsA("Model") then return standModel end
        end
        RunService.Heartbeat:Wait()
    until os.clock() - startTime > timeout
    return nil
end

--- [FINAL FIX] Applies the hitbox extension using the direct, known path.
function Modules.StandReach:Apply(size)
    DoNotif("1/2: Finding Stand model ('Summer Chariot')...", 2)
    local standModel = self:_findPlayerStand()
    if not standModel then
        return DoNotif("FAIL: Could not find the root Stand model in your character.", 4)
    end

    DoNotif("2/2: Found Stand! Waiting for 'Sword' path...", 3)
    
    local tool, damagePart
    
    -- pcall is a "protected call" that prevents the script from erroring if the path fails.
    local success, result = pcall(function()
        -- [PATH] standModel -> Sword (Model) -> Sword (Tool)
        local nestedSwordModel = standModel:WaitForChild("Sword", 3) -- Wait for the nested Sword MODEL
        tool = nestedSwordModel:WaitForChild("Sword", 3)             -- Wait for the Sword TOOL inside it
        damagePart = tool:WaitForChild("Blade", 3)                   -- Wait for the Blade PART inside the tool
    end)

    if not success or not damagePart then
        return DoNotif("FAIL: Path is invalid or timed out. Could not find '...:Sword:Sword:Blade'.", 5)
    end

    if not self.State.OriginalSizes[damagePart] then
        self.State.OriginalSizes[damagePart] = damagePart.Size
    end

    damagePart.Size = Vector3.new(size, size, size)
    damagePart.CanCollide = false
    damagePart.Massless = true
    damagePart.Transparency = 0.5

    DoNotif("SUCCESS: Extended '" .. damagePart.Name .. "' on '" .. tool.Name .. "' to size " .. size .. ".", 5)
end

--- Restores the original sizes (no changes needed).
function Modules.StandReach:Reset()
    if not next(self.State.OriginalSizes) then return DoNotif("No active modifications to reset.", 3) end
    local resetCount = 0
    for part, originalSize in pairs(self.State.OriginalSizes) do
        if part and part.Parent then
            part.Size = originalSize; part.CanCollide = true; part.Massless = false; part.Transparency = 1;
            self.State.OriginalSizes[part] = nil; resetCount = resetCount + 1;
        end
    end
    if resetCount > 0 then DoNotif("Reset " .. resetCount .. " hitbox(es).", 3)
    else DoNotif("Could not find previously modified parts to reset.", 3) end
end

--======================================================================================
-- COMMAND REGISTRATION
--======================================================================================
RegisterCommand({Name = "standreach", Aliases = {"sr", "standhitbox"}, Description = "Extends the hitbox of your Stand's weapon."}, function(args)
    local size = tonumber(args[1]) or 30
    if size <= 0 then return DoNotif("Size must be a positive number.", 3) end
    Modules.StandReach:Apply(size)
end)

RegisterCommand({Name = "unstandreach", Aliases = {"unsr", "resetstand"}, Description = "Resets your Stand's weapon hitbox to its original size."}, function(args)
    Modules.StandReach:Reset()
end)

--======================================================================================
-- MODULE: HitboxExtender
-- PURPOSE: Intelligently finds and resizes custom hitbox parts within a tool that
--          lacks a traditional "Handle". This is a targeted reach method.
-- USAGE: Equip the tool, then use ";hitbox [size]" or ";unhitbox".
--======================================================================================

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Module Definition
Modules.HitboxExtender = {
    State = {
        -- This dictionary is crucial for cleanly restoring original sizes.
        -- It will map a Part instance to its original Vector3 size.
        OriginalSizes = {}
    }
}

--- Finds the currently equipped tool in the player's character.
function Modules.HitboxExtender:_getEquippedTool()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
end

--- Scans a tool for parts that appear to be hitboxes based on their name.
-- @param tool The Tool instance to scan.
-- @return An array of BasePart instances identified as hitboxes.
function Modules.HitboxExtender:_findHitboxParts(tool)
    local foundParts = {}
    if not tool then return foundParts end

    for _, descendant in ipairs(tool:GetDescendants()) do
        if descendant:IsA("BasePart") then
            local name = descendant.Name:lower()
            -- Add other common hitbox names here if needed in the future
            if name:find("hitbox") or name:find("damage") or name:find("range") then
                table.insert(foundParts, descendant)
            end
        end
    end
    return foundParts
end

--- Applies the hitbox extension.
-- @param size The new uniform size for the hitbox parts.
function Modules.HitboxExtender:Apply(size)
    local tool = self:_getEquippedTool()
    if not tool then
        return DoNotif("No tool is currently equipped.", 3)
    end

    local hitboxParts = self:_findHitboxParts(tool)
    if #hitboxParts == 0 then
        return DoNotif("Could not find any hitbox parts in '" .. tool.Name .. "'.", 4)
    end

    for _, part in ipairs(hitboxParts) do
        -- IMPORTANT: Store the original size *only if we haven't already*.
        if not self.State.OriginalSizes[part] then
            self.State.OriginalSizes[part] = part.Size
        end
        
        -- Apply the new size and make it massless to avoid physics issues.
        part.Size = Vector3.new(size, size, size)
        part.CanCollide = false
        part.Massless = true
        part.Transparency = 0.5 -- Make it visible for debugging
    end

    DoNotif("Extended " .. #hitboxParts .. " hitbox(es) on '" .. tool.Name .. "' to size " .. size .. ".", 4)
end

--- Restores the original sizes of any modified hitboxes on the current tool.
function Modules.HitboxExtender:Reset()
    local tool = self:_getEquippedTool()
    if not tool then
        return DoNotif("Equip a tool to reset its hitboxes.", 3)
    end
    
    local resetCount = 0
    for part, originalSize in pairs(self.State.OriginalSizes) do
        -- Check if the part still exists and belongs to the currently held tool.
        if part and part.Parent and part:IsDescendantOf(tool) then
            part.Size = originalSize
            part.CanCollide = true -- Restore default properties
            part.Massless = false
            part.Transparency = 1 -- Hide it again
            
            -- Remove it from the state table so we don't try to reset it again.
            self.State.OriginalSizes[part] = nil
            resetCount = resetCount + 1
        end
    end

    if resetCount > 0 then
        DoNotif("Reset " .. resetCount .. " hitbox(es) on '" .. tool.Name .. "'.", 3)
    else
        DoNotif("No active hitbox modifications found for '" .. tool.Name .. "'.", 3)
    end
end

--======================================================================================
-- COMMAND REGISTRATION
--======================================================================================
RegisterCommand({
    Name = "hitbox",
    Aliases = {"extendhitbox", "resizepart"},
    Description = "Extends the hitbox of your equipped tool. Usage: hitbox [size]"
}, function(args)
    local size = tonumber(args[1]) or 20 -- Default to a large size of 20
    if size <= 0 then
        return DoNotif("Size must be a positive number.", 3)
    end
    Modules.HitboxExtender:Apply(size)
end)

RegisterCommand({
    Name = "unhitbox",
    Aliases = {"resethitbox"},
    Description = "Resets the hitbox of your equipped tool to its original size."
}, function(args)
    Modules.HitboxExtender:Reset()
end)

--======================================================================================
-- MODULE: EditStats (v3 with Attribute Support)
-- PURPOSE: Provides a UI to edit Humanoid properties AND dynamically discovered custom
--          attributes. The "Lock" feature works for both, bypassing server reverts.
--======================================================================================

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer

-- Module Definition
Modules.EditStats = {
    State = {
        UI = nil,
        -- The override table now stores more data to handle properties vs attributes.
        -- Example: { WalkSpeed = { Value = 200, IsAttribute = false } }
        ActiveOverrides = {},
        HeartbeatConnection = nil
    }
}

--- The core bypass function, now aware of properties vs. attributes.
function Modules.EditStats:ForceProperties()
    if not next(self.State.ActiveOverrides) then
        if self.State.HeartbeatConnection then
            self.State.HeartbeatConnection:Disconnect()
            self.State.HeartbeatConnection = nil
        end
        return
    end

    local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    for name, data in pairs(self.State.ActiveOverrides) do
        if data.IsAttribute then
            -- Handle Attributes using Get/SetAttribute methods.
            if humanoid:GetAttribute(name) ~= data.Value then
                humanoid:SetAttribute(name, data.Value)
            end
        else
            -- Handle standard Properties using direct indexing.
            if humanoid[name] ~= data.Value then
                humanoid[name] = data.Value
            end
        end
    end
end

--- Creates the user interface.
function Modules.EditStats:CreateUI()
    if self.State.UI then return end

    local screenGui = Instance.new("ScreenGui", localPlayer:WaitForChild("PlayerGui"))
    screenGui.Name = "HumanoidEditor"
    screenGui.ResetOnSpawn = false
    self.State.UI = screenGui

    local mainFrame = Instance.new("Frame", screenGui)
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 300, 0, 400) -- Made taller for more properties
    mainFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    mainFrame.BorderSizePixel = 1
    mainFrame.BorderColor3 = Color3.fromRGB(120, 120, 120)
    mainFrame.Active = true
    mainFrame.Draggable = true

    local titleLabel = Instance.new("TextLabel", mainFrame)
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    titleLabel.Text = "Humanoid Editor"
    titleLabel.Font = Enum.Font.Code
    titleLabel.TextSize = 16
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

    local closeButton = Instance.new("TextButton", titleLabel)
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -30, 0, 0)
    closeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    closeButton.Text = "X"
    closeButton.Font = Enum.Font.Code
    closeButton.TextSize = 16
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.MouseButton1Click:Connect(function() screenGui.Enabled = false end)

    local propertyList = Instance.new("ScrollingFrame", mainFrame)
    propertyList.Name = "PropertyList"
    propertyList.Size = UDim2.new(1, 0, 1, -30)
    propertyList.Position = UDim2.new(0, 0, 0, 30)
    propertyList.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    propertyList.CanvasSize = UDim2.new(0, 0, 4, 0) -- Increased canvas size
    
    local listLayout = Instance.new("UIListLayout", propertyList)
    listLayout.Padding = UDim.new(0, 5)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- This is a generic "factory" function to create a UI row for any stat.
    local function CreateStatRow(name, value, isAttribute, layoutOrder)
        local propFrame = Instance.new("Frame", propertyList)
        propFrame.Name = name .. "Frame"
        propFrame.Size = UDim2.new(1, -10, 0, 30)
        propFrame.Position = UDim2.new(0, 5, 0, 0)
        propFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        propFrame.LayoutOrder = layoutOrder

        local nameLabel = Instance.new("TextLabel", propFrame)
        nameLabel.Size = UDim2.new(0.4, 0, 1, 0)
        nameLabel.Text = name
        nameLabel.Font = Enum.Font.Code
        nameLabel.TextSize = 14
        nameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        local valueBox = Instance.new("TextBox", propFrame)
        valueBox.Size = UDim2.new(0.4, 0, 1, 0)
        valueBox.Position = UDim2.new(0.4, 0, 0, 0)
        valueBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        valueBox.Font = Enum.Font.Code
        valueBox.TextSize = 14
        valueBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        valueBox.Text = tostring(value)

        local lockButton = Instance.new("TextButton", propFrame)
        lockButton.Size = UDim2.new(0.2, 0, 1, 0)
        lockButton.Position = UDim2.new(0.8, 0, 0, 0)
        lockButton.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
        lockButton.Font = Enum.Font.Code
        lockButton.TextSize = 14
        lockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        lockButton.Text = "Lock"

        lockButton.MouseButton1Click:Connect(function()
            local numValue = tonumber(valueBox.Text)
            if not numValue then return end

            if Modules.EditStats.State.ActiveOverrides[name] then
                Modules.EditStats.State.ActiveOverrides[name] = nil
                lockButton.BackgroundColor3 = Color3.fromRGB(80, 20, 20); lockButton.Text = "Lock"
            else
                -- Store the value AND whether it's an attribute
                Modules.EditStats.State.ActiveOverrides[name] = { Value = numValue, IsAttribute = isAttribute }
                lockButton.BackgroundColor3 = Color3.fromRGB(20, 80, 20); lockButton.Text = "Locked"
                
                if not Modules.EditStats.State.HeartbeatConnection then
                    Modules.EditStats.State.HeartbeatConnection = RunService.Heartbeat:Connect(function()
                        Modules.EditStats:ForceProperties()
                    end)
                end
            end
        end)

        valueBox.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                local newValue = tonumber(valueBox.Text)
                local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
                if not humanoid then return end

                if newValue then
                    if isAttribute then
                        humanoid:SetAttribute(name, newValue)
                    else
                        humanoid[name] = newValue
                    end
                    
                    if Modules.EditStats.State.ActiveOverrides[name] then
                        Modules.EditStats.State.ActiveOverrides[name].Value = newValue
                    end
                    
                    valueBox.Text = tostring(isAttribute and humanoid:GetAttribute(name) or humanoid[name])
                else
                    valueBox.Text = tostring(isAttribute and humanoid:GetAttribute(name) or humanoid[name] or "N/A")
                end
            end
        end)
    end

    local function populateProperties()
        local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        
        for _, child in ipairs(propertyList:GetChildren()) do if child:IsA("UIListLayout") == false then child:Destroy() end end
        
        local layoutCounter = 1

        -- [NEW] Header for standard properties
        local propHeader = Instance.new("TextLabel", propertyList); propHeader.Name = "PropHeader"; propHeader.Size = UDim2.new(1,-10,0,20); propHeader.Text = "-- Properties --"; propHeader.TextColor3 = Color3.new(1,1,1); propHeader.BackgroundColor3 = Color3.fromRGB(50,50,50); propHeader.LayoutOrder = layoutCounter;
        layoutCounter = layoutCounter + 1

        -- Create rows for standard properties
        local propertiesToEdit = {"WalkSpeed", "JumpPower", "JumpHeight", "HipHeight", "MaxHealth", "Health"}
        for _, propName in ipairs(propertiesToEdit) do
            CreateStatRow(propName, humanoid[propName], false, layoutCounter)
            layoutCounter = layoutCounter + 1
        end

        -- [NEW] Header for custom attributes
        local attrHeader = Instance.new("TextLabel", propertyList); attrHeader.Name = "AttrHeader"; attrHeader.Size = UDim2.new(1,-10,0,20); attrHeader.Text = "-- Attributes --"; attrHeader.TextColor3 = Color3.new(1,1,1); attrHeader.BackgroundColor3 = Color3.fromRGB(50,50,50); attrHeader.LayoutOrder = layoutCounter;
        layoutCounter = layoutCounter + 1
        
        -- Create rows for custom attributes
        for attrName, attrValue in pairs(humanoid:GetAttributes()) do
            -- Only show attributes that can be edited as numbers
            if typeof(attrValue) == "number" then
                CreateStatRow(attrName, attrValue, true, layoutCounter)
                layoutCounter = layoutCounter + 1
            end
        end
    end
    
    if localPlayer.Character then populateProperties() end
    localPlayer.CharacterAdded:Connect(function() task.wait(0.5); populateProperties() end)
end

--======================================================================================
-- COMMAND REGISTRATION
--======================================================================================
RegisterCommand({
    Name = "editstats",
    Aliases = {"stats", "humanoideditor", "prop"},
    Description = "Opens a properties window to edit and lock Humanoid stats and attributes."
}, function(args)
    Modules.EditStats:CreateUI()
    local ui = Modules.EditStats.State.UI
    ui.Enabled = not ui.Enabled
    print("Humanoid Properties window " .. (ui.Enabled and "shown." or "hidden."))
end)




local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")


Modules.AdvancedReach = {
    State = {
        Enabled = false,
        ReachDistance = 50, 
        Connection = nil
    }
}




function Modules.AdvancedReach:OnInputBegan(input, gameProcessed)
    
    if gameProcessed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
        return
    end

    local localPlayer = Players.LocalPlayer
    local character = localPlayer and localPlayer.Character
    local myRootPart = character and character:FindFirstChild("HumanoidRootPart")
    local mouse = localPlayer:GetMouse()

    if not myRootPart or not mouse then return end

    local target = mouse.Target
    if not target then return end

    
    local targetModel = target.Parent
    local targetHumanoid = targetModel:FindFirstChildOfClass("Humanoid")
    
    if not targetHumanoid or targetHumanoid.Health <= 0 or targetModel == character then
        return
    end

    local targetRootPart = targetModel:FindFirstChild("HumanoidRootPart")
    if not targetRootPart then return end

    
    local distance = (myRootPart.Position - targetRootPart.Position).Magnitude
    if distance > self.State.ReachDistance then
        return
    end
    
    
    task.spawn(function()
        
        local originalCFrame = myRootPart.CFrame
        
        
        
        local hitPosition = targetRootPart.CFrame * CFrame.new(0, 0, 3)
        
        
        myRootPart.CFrame = hitPosition
        
        
        
        
        RunService.Heartbeat:Wait()
        
        
        myRootPart.CFrame = originalCFrame
    end)
end


function Modules.AdvancedReach:Enable()
    self.State.Enabled = true
    
    self.State.Connection = UserInputService.InputBegan:Connect(function(...)
        self:OnInputBegan(...)
    end)
    print("￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾢ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾜ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾅ Advanced Reach: [Enabled] | Distance: " .. self.State.ReachDistance .. " studs")
end


function Modules.AdvancedReach:Disable()
    self.State.Enabled = false
    if self.State.Connection then
        self.State.Connection:Disconnect()
        self.State.Connection = nil
    end
    print("￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾢ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾚ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾪ Advanced Reach: [Disabled]")
end





RegisterCommand({
    Name = "advreach",
    Aliases = {"longarms", "extendo"},
    Description = "Toggles an advanced reach bypass. Usage: advreach [distance]"
}, function(args)
    
    local newDistance = tonumber(args[1])
    if newDistance and newDistance > 0 then
        Modules.AdvancedReach.State.ReachDistance = newDistance
        print("--> Reach distance set to: " .. newDistance)
        
        if Modules.AdvancedReach.State.Enabled then
            print("￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾ﾿￯﾿ﾯ￯ﾾﾾ￯ﾾﾢ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾜ￯﾿ﾯ￯ﾾ﾿￯ﾾﾯ￯﾿ﾯ￯ﾾﾾ￯ﾾﾾ￯﾿ﾯ￯ﾾﾾ￯ﾾﾅ Advanced Reach: [Enabled] | Distance: " .. newDistance .. " studs")
        end
        return 
    end

    
    if Modules.AdvancedReach.State.Enabled then
        Modules.AdvancedReach:Disable()
    else
        Modules.AdvancedReach:Enable()
    end
end)







local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")


Modules.BypassAntiAFK = {
    State = {
        Enabled = false,
        Connection = nil,
        TickCounter = 0,
        Interval = 60 
    }
}


function Modules.BypassAntiAFK:SimulateInput()
    
    self.State.TickCounter = self.State.TickCounter + RunService.Heartbeat:Wait()

    if self.State.TickCounter >= self.State.Interval then
        self.State.TickCounter = 0 
        
        
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.RightArrow, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.RightArrow, false, game)
        
        print("Anti-AFK Bypass: Simulated input to remain active.")
    end
end


RegisterCommand({
    Name = "bypassantiafk",
    Aliases = {"antiafk", "bafk"},
    Description = "Toggles a bypass to prevent being kicked for being idle."
}, function(args)
    
    Modules.BypassAntiAFK.State.Enabled = not Modules.BypassAntiAFK.State.Enabled

    if Modules.BypassAntiAFK.State.Enabled then
        print("Anti-AFK Bypass: [Enabled]")
        Modules.BypassAntiAFK.State.Connection = RunService.Heartbeat:Connect(function()
            Modules.BypassAntiAFK:SimulateInput()
        end)
    else
        print("Anti-AFK Bypass: [Disabled]")
        if Modules.BypassAntiAFK.State.Connection then
            Modules.BypassAntiAFK.State.Connection:Disconnect()
            Modules.BypassAntiAFK.State.Connection = nil
        end
        Modules.BypassAntiAFK.State.TickCounter = 0
    end
end)

RegisterCommand({
    Name = "fixcam",
    Aliases = {"fix", "unlockcam"},
    Description = "Unlocks camera, allows zooming through walls, and forces third-person."
}, function(args)
    
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local RunService = game:GetService("RunService")

    if not LocalPlayer then return end

    if isCameraFixed and cameraFixConnection and cameraFixConnection.Connected then
        
        
        cameraFixConnection:Disconnect()
        cameraFixConnection = nil
        
        
        pcall(function()
            if originalOcclusionMode and originalOcclusionMode ~= nil then
                LocalPlayer.DevCameraOcclusionMode = originalOcclusionMode
            end
            if originalMaxZoom and originalMaxZoom ~= nil then
                LocalPlayer.CameraMaxZoomDistance = originalMaxZoom
            end
        end)
        
        isCameraFixed = false
        DoNotif("Camera override disabled.", 3)
    else
        
        
        
        originalMaxZoom = LocalPlayer.CameraMaxZoomDistance
        originalOcclusionMode = LocalPlayer.DevCameraOcclusionMode
        
        
        
        
        LocalPlayer.CameraMaxZoomDistance = 10000 
        
        
        local success, err = pcall(function()
            
            LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.None
        end)

        if not success then
            
            
            LocalPlayer.DevCameraOcclusionMode = 0 
            
            
            warn("Failed to set DevCameraOcclusionMode to Enum.None. Falling back to numeric value 0. Error: " .. tostring(err))
        end
        
        
        cameraFixConnection = RunService.RenderStepped:Connect(function()
            
            if LocalPlayer.CameraMode ~= Enum.CameraMode.Classic then
                LocalPlayer.CameraMode = Enum.CameraMode.Classic
            end
        end)
        
        isCameraFixed = true
        DoNotif("Camera override enabled (with wall-zoom).", 3)
    end
end)

RegisterCommand({Name = "cmds", Aliases = {"help"}, Description = "Shows this command list."}, function() Modules.CommandsUI:Toggle() end)

RegisterCommand({Name = "cmdbar", Aliases = {"cbar"}, Description = "Toggles the private command bar."}, function()
    Modules.CommandBar:Toggle()
end)

RegisterCommand({Name = "ide", Aliases = {}, Description = "Opens a script execution window."}, function() Modules.IDE:Toggle() end)

RegisterCommand({Name = "decompile", Aliases = {"decomp", "disassemble"}, Description = "Initializes the Konstant decompiler functions."}, function() Modules.Decompiler:Initialize() end)


RegisterCommand({Name = "fly", Aliases = {}, Description = "Toggles smooth flight mode."}, function() Modules.Fly:Toggle() end)
RegisterCommand({Name = "flyspeed", Aliases = {}, Description = "Sets fly speed. ;flyspeed [num]"}, function(args) Modules.Fly:SetSpeed(args[1]) end)
RegisterCommand({Name = "speed", Aliases = {}, Description = "Sets walkspeed. ;speed [num]"}, function(args) local s=tonumber(args[1]); local h=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"); if not h then DoNotif("Humanoid not found!", 3) return end; if s and s > 0 then h.WalkSpeed = s; DoNotif("WalkSpeed set to: " .. s, 3) else DoNotif("Invalid speed.", 3) end end)
RegisterCommand({Name = "noclip", Aliases = {}, Description = "Toggles walking through walls."}, function() Modules.Noclip:Toggle() end)
RegisterCommand({Name = "wallwalk", Aliases = {"ww"}, Description = "Toggles walking on walls."}, function() Modules.WallWalk:Toggle() end)
RegisterCommand({Name = "godmode", Aliases = {"god"}, Description = "Toggles invincibility. Use ;god [method|off] or ;god for a menu."}, function(args) Modules.Godmode:HandleCommand(args) end)
RegisterCommand({Name = "ungodmode", Aliases = {"ungod"}, Description = "Disables invincibility."}, function() Modules.Godmode:Disable() end)
RegisterCommand({Name = "goto", Aliases = {}, Description = "Teleports to a player. ;goto [player]"}, function(args)
RegisterCommand({Name = "antikb", Aliases = {"akb"}, Description = "Toggles client-side anti-kill-brick (health lock)."}, function() Modules.AntiKB:Toggle() end)

    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    
    local inputName = args[1] and tostring(args[1]):lower()
    if not inputName or inputName == "" then
        return DoNotif("Specify a player's name.", 3)
    end

    
    local exactMatch = nil
    local partialMatch = nil

    
    for _, player in ipairs(Players:GetPlayers()) do
        local username = player.Name:lower()
        local displayName = player.DisplayName:lower()

        
        if username == inputName or displayName == inputName then
            exactMatch = player
            break 
        end

        
        if not partialMatch then
            if username:sub(1, #inputName) == inputName or displayName:sub(1, #inputName) == inputName then
                partialMatch = player 
            end
        end
    end

    
    local targetPlayer = exactMatch or partialMatch

    
    if targetPlayer then
        local localHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local targetHRP = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")

        if localHRP and targetHRP then
            
            localHRP.CFrame = targetHRP.CFrame + Vector3.new(0, 3, 0)
            
            DoNotif("Teleported to " .. targetPlayer.Name, 3)
        else
            DoNotif("Target player's character could not be found.", 3)
        end
    else
        DoNotif("Player not found.", 3)
    end
end)

RegisterCommand({
    Name = "fireclick",
    Aliases = {"fclick", "click"},
    Description = "Fires a ClickDetector on the part under your mouse. Use 'all' to fire every ClickDetector in a 50 stud radius."
}, function(args)
    
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local UserInputService = game:GetService("UserInputService")
    local LocalPlayer = Players.LocalPlayer

    
    if args[1] and args[1]:lower() == "all" then
        
        local character = LocalPlayer.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        if not hrp then
            return DoNotif("Your character could not be found.", 3)
        end

        local RADIUS = 50
        local partsInRadius = Workspace:GetPartBoundsInRadius(hrp.Position, RADIUS)
        local fireCount = 0

        for _, part in ipairs(partsInRadius) do
            local clickDetector = part:FindFirstChildOfClass("ClickDetector")
            if clickDetector then
                fireclickdetector(part, 0)
                fireCount = fireCount + 1
            end
        end
        DoNotif("Fired " .. fireCount .. " ClickDetectors within " .. RADIUS .. " studs.", 4)
    else
        
        local mouseLocation = UserInputService:GetMouseLocation()
        local camera = Workspace.CurrentCamera
        local mouseRay = camera:ScreenPointToRay(mouseLocation.X, mouseLocation.Y)
        
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
        
        local raycastResult = Workspace:Raycast(mouseRay.Origin, mouseRay.Direction * 1000, raycastParams)
        local targetPart = raycastResult and raycastResult.Instance

        if not targetPart then
            return DoNotif("No target part found under the mouse.", 3)
        end

        local clickDetector = targetPart:FindFirstChildOfClass("ClickDetector")
        if clickDetector then
            fireclickdetector(targetPart, 0)
            DoNotif("Fired ClickDetector on: " .. targetPart.Name, 3)
        else
            DoNotif("No ClickDetector found on the target part.", 3)
        end
    end
end)

RegisterCommand({
    Name = "firetouch",
    Aliases = {"ftouch", "touch"},
    Description = "Fires a Touched event on the part under your mouse. Use 'all' to touch every part in a 50 stud radius."
}, function(args)
    
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local UserInputService = game:GetService("UserInputService")
    local LocalPlayer = Players.LocalPlayer
    local localCharacter = LocalPlayer.Character

    if not localCharacter then return DoNotif("Your character could not be found.", 3) end
    local touchPart = localCharacter:FindFirstChild("HumanoidRootPart")
    if not touchPart then return DoNotif("Your HumanoidRootPart could not be found.", 3) end

    
    if args[1] and args[1]:lower() == "all" then
        
        local RADIUS = 50
        local partsInRadius = Workspace:GetPartBoundsInRadius(touchPart.Position, RADIUS)
        local fireCount = 0

        for _, part in ipairs(partsInRadius) do
            
            if not Players:GetPlayerFromCharacter(part:FindFirstAncestorOfClass("Model")) then
                firetouchinterest(touchPart, part, 0)
                firetouchinterest(touchPart, part, 1)
                fireCount = fireCount + 1
            end
        end
        DoNotif("Fired Touched event on " .. fireCount .. " parts within " .. RADIUS .. " studs.", 4)
    else
        
        local mouseLocation = UserInputService:GetMouseLocation()
        local camera = Workspace.CurrentCamera
        local mouseRay = camera:ScreenPointToRay(mouseLocation.X, mouseLocation.Y)
        
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {localCharacter}
        
        local raycastResult = Workspace:Raycast(mouseRay.Origin, mouseRay.Direction * 1000, raycastParams)
        local targetPart = raycastResult and raycastResult.Instance

        if not targetPart then
            return DoNotif("No target part found under the mouse.", 3)
        end

        firetouchinterest(touchPart, targetPart, 0)
        firetouchinterest(touchPart, targetPart, 1)
        DoNotif("Fired Touched event on: " .. targetPart.Name, 3)
    end
end)


RegisterCommand({Name = "reach", Aliases = {"swordreach"}, Description = "Extends sword reach. ;reach [num]"}, function(args) Modules.Reach:Apply("directional", tonumber(args[1]) or 15) end)
RegisterCommand({Name = "boxreach", Aliases = {}, Description = "Creates a box hitbox. ;boxreach [num]"}, function(args) Modules.Reach:Apply("box", tonumber(args[1]) or 15) end)
RegisterCommand({Name = "resetreach", Aliases = {"unreach"}, Description = "Resets tool reach to normal."}, function() Modules.Reach:Reset() end)
RegisterCommand({Name = "clickfling", Aliases = {}, Description = "Enables click to fling players."}, function() Modules.ClickFling:Enable() end)
RegisterCommand({Name = "unclickfling", Aliases = {}, Description = "Disables click to fling."}, function() Modules.ClickFling:Disable() end)
RegisterCommand({Name = "clicktp", Aliases = {}, Description = "Hold Left CTRL to teleport to cursor."}, function() Modules.ClickTP:Toggle() end)
RegisterCommand({
    Name = "modelreach",
    Aliases = {"mreach"},
    Description = "Extends tool reach on a specified model. ;mreach [model_name] [size]"
}, function(args)
    local modelName = args[1]
    local size = tonumber(args[2]) or 15
    if not modelName then
        return DoNotif("Please specify a model name.", 3)
    end
    Modules.ModelReach:Apply(modelName, "directional", size)
end)

RegisterCommand({
    Name = "modelboxreach",
    Aliases = {"mboxreach"},
    Description = "Creates a box hitbox on a tool in a model. ;mboxreach [model_name] [size]"
}, function(args)
    local modelName = args[1]
    local size = tonumber(args[2]) or 15
    if not modelName then
        return DoNotif("Please specify a model name.", 3)
    end
    Modules.ModelReach:Apply(modelName, "box", size)
end)

RegisterCommand({
    Name = "resetmodelreach",
    Aliases = {"unmreach"},
    Description = "Resets tool reach on a specified model. ;unmreach [model_name]"
}, function(args)
    local modelName = args[1]
    if not modelName then
        return DoNotif("Please specify a model name.", 3)
    end
    Modules.ModelReach:Reset(modelName)
end)


RegisterCommand({Name = "esp", Aliases = {}, Description = "Toggles player outline, name, and team."}, function() Modules.ESP:Toggle() end)
RegisterCommand({Name = "antikick", Aliases = {"ak"}, Description = "Hooks metamethods to prevent being kicked."}, function() Modules.AntiKick:Toggle() end)
RegisterCommand({Name = "grabtools", Aliases = {}, Description = "Auto-grabs tools that appear."}, function() Modules.GrabTools:Toggle() end)
RegisterCommand({Name = "ibtools", Aliases = {}, Description = "Loads a building helper tool for deleting/modifying parts."}, function() Modules.iBTools:Toggle() end)
RegisterCommand({Name = "selector", Aliases = {"partselector", "ps"}, Description = "Toggles a HUD to identify parts and models under the cursor."}, function() Modules.PartSelector:Toggle() end)

local function loadstringCmd(url, notif) pcall(function() loadstring(game:HttpGet(url))() end); DoNotif(notif, 3) end
RegisterCommand({Name = "zui", Aliases = {}, Description = "Loads the Zombie Hub"}, function() loadstringCmd("https://raw.githubusercontent.com/scriptlisenbe-stack/luaprojectse3/refs/heads/main/ZGUI.txt", "Loading Zombie Hub...") end)
RegisterCommand({Name = "zukahub", Aliases = {"zhub"}, Description = "Loads the Zuka Hub"}, function() loadstringCmd("https://raw.githubusercontent.com/zukatechdevelopment-ux/thingsandstuff/refs/heads/main/ZukaHub.lua", "Loading Zuka's Hub...") end)
RegisterCommand({Name = "cat", Aliases = {"catexec"}, Description = "Loads CatBypasser"}, function() loadstringCmd("https://raw.githubusercontent.com/shadow62x/catbypass/main/upfix", "Loading Chat...") end)
RegisterCommand({Name = "dex", Aliases = {"explorer"}, Description = "Opens the Dark Dex explorer for developers."}, function() loadstringCmd("https://raw.githubusercontent.com/scriptlisenbe-stack/luaprojectse3/refs/heads/main/CustomDex.lua", "Loading Dex++") end)
RegisterCommand({Name = "pentest", Aliases = {"ptest"}, Description = "Opens a versatile Remote View GUI."}, function() loadstringCmd("https://raw.githubusercontent.com/InfernusScripts/Ketamine/refs/heads/main/Ketamine.lua", "Loading Script Hub...") end)
RegisterCommand({Name = "teleportgui", Aliases = {"tpui", "uviewer"}, Description = "Opens a GUI to teleport to other game places."}, function() loadstringCmd("https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/main/Universe%20Viewer", "Loading Teleport GUI...") end)
RegisterCommand({Name = "aimbot", Aliases = {"aim"}, Description = "Loads an aimbot script."}, function() loadstringCmd("https://raw.githubusercontent.com/zukatechdevelopment-ux/thingsandstuff/refs/heads/main/ZukasAimbot.lua", "Loading Aimbot...") end)
RegisterCommand({Name = "ghost", Aliases = {"invis"}, Description = "OP Works on some games.."}, function() loadstringCmd("https://raw.githubusercontent.com/legalize8ga-maker/PublicReleaseLua/refs/heads/main/soulform.lua", "Loading Invis Mode Use G and H for toggle...") end)
RegisterCommand({Name = "flyr15", Aliases = {"pfly"}, Description = "Loads a specific R15 flight script."}, function() loadstringCmd("https://raw.githubusercontent.com/396abc/Script/refs/heads/main/FlyR15.lua", "Loading R15 Fly...") end)
RegisterCommand({Name = "playerfarm", Aliases = {"pfarm"}, Description = "Loads a GUI addon for farming players."}, function() loadstringCmd("https://raw.githubusercontent.com/zukatechdevelopment-ux/thingsandstuff/refs/heads/main/ragebot.lua", "Loading Farming Addon...") end)
RegisterCommand({Name = "bloxfruits", Aliases = {"bfruit"}, Description = "Loads the one piece script hub."}, function() loadstringCmd("https://raw.githubusercontent.com/AhmadV99/Speed-Hub-X/main/Speed%20Hub%20X.lua", "Loading s0ulzV4...") end)
RegisterCommand({Name = "rspy", Aliases = {"spy"}, Description = "Remote Functions"}, function() loadstringCmd("https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/main/simplee%20spyyy%20mobilee", "Loading Invis Mode Use G and H for toggle...") end)


local auraConn, auraViz
RegisterCommand({Name = "aura", Aliases = {}, Description = "Continuously damages nearby players. ;aura [distance]"}, function(args)
	local dist=tonumber(args[1]) or 20
	if not firetouchinterest then return DoNotif("firetouchinterest unsupported",2) end
	if auraConn then auraConn:Disconnect() end; if auraViz then auraViz:Destroy() end
	auraViz=Instance.new("Part", workspace); auraViz.Shape=Enum.PartType.Ball; auraViz.Size=Vector3.new(dist*2,dist*2,dist*2)
	auraViz.Transparency=0.8; auraViz.Color=Color3.fromRGB(255,0,0); auraViz.Material=Enum.Material.Neon
	auraViz.Anchored=true; auraViz.CanCollide=false
	local function getHandle() local c=LocalPlayer.Character; if not c then return end; local t=c:FindFirstChildWhichIsA("Tool"); if not t then return end; return t:FindFirstChild("Handle") or t:FindFirstChildWhichIsA("BasePart") end
	auraConn=RunService.RenderStepped:Connect(function()
		local handle, root = getHandle(), LocalPlayer.Character and LocalPlayer.Character.HumanoidRootPart
		if not handle or not root then return end
		auraViz.CFrame=root.CFrame
		for _,plr in ipairs(Players:GetPlayers()) do
			if plr~=LocalPlayer and plr.Character then
				local hum=plr.Character:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health>0 then
					for _,part in ipairs(plr.Character:GetChildren()) do
						if part:IsA("BasePart") and (part.Position-handle.Position).Magnitude<=dist then
							firetouchinterest(handle,part,0); task.wait(); firetouchinterest(handle,part,1); break
						end
					end
				end
			end
		end
	end)
	DoNotif("Aura enabled at "..dist,1.2)
end)
RegisterCommand({Name = "unaura", Aliases = {}, Description = "Stops aura loop and removes visualizer."}, function()
	if auraConn then auraConn:Disconnect(); auraConn=nil end
	if auraViz then auraViz:Destroy(); auraViz=nil end
	DoNotif("Aura disabled",1.2)
end)




function processCommand(message)
    
    if not message:sub(1, #Prefix) == Prefix then
        return false 
    end

    
    local args = {}
    for word in message:sub(#Prefix + 1):gmatch("%S+") do
        table.insert(args, word)
    end

    if #args == 0 then
        return true 
    end

    local cmdName = table.remove(args, 1):lower()
    local cmdFunc = Commands[cmdName]

    if cmdFunc then
        
        local success, err = pcall(cmdFunc, args)
        if not success then
            
            warn("Command Error:", err)
            DoNotif("Error executing '" .. cmdName .. "': " .. tostring(err), 5)
        end
    else
        DoNotif("Unknown command: " .. cmdName, 3)
    end

    return true 
end


LocalPlayer.Chatted:Connect(processCommand)
Modules.CommandBar:Toggle() 


local TextChatService = game:GetService("TextChatService")
if TextChatService then
    TextChatService.Sending:Connect(function(message)
        
        
        if processCommand(message.Text) then
            message.Text = "" 
            return Enum.TextChatMessageStatus.Success
        end
    end)
    DoNotif("Hooked into modern TextChatService.", 4)
else
    
    LocalPlayer.Chatted:Connect(processCommand)
    DoNotif("Hooked into legacy Chat system.", 4)
end

DoNotif("Zuka's Admin (Reworked) | Prefix: '" .. Prefix .. "' | ;cmds for help", 6)