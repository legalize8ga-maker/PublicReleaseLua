--[[
    Standalone Reach Script
    Authored by Callum (Based on user-provided module)

    Description:
    Modifies the size of a player's equipped tool to extend its reach.
    Features a custom UI to select reach type, size, and reset changes.
]]

--//==================================================================================//--
--// Configuration
--//==================================================================================//--

local Config = {
    UIToggleKey = Enum.KeyCode.G, -- Key to toggle the UI
    DefaultReachSize = 25
}

--//==================================================================================//--
--// Services & Core Variables
--//==================================================================================//--

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Master ScreenGui for all UI elements
local MainGui = Instance.new("ScreenGui")
MainGui.Name = "ReachScriptGui"
MainGui.ResetOnSpawn = false
MainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
MainGui.Parent = CoreGui

--//==================================================================================//--
--// UI Creation & Helper Functions
--//==================================================================================//--

-- Re-implementation of the missing DoNotif function
local function DoNotif(text, duration)
    local notifGui = Instance.new("ScreenGui", CoreGui)
    notifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 300, 0, 40)
    label.Position = UDim2.new(0.5, -150, -0.1, 0)
    label.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    label.BorderSizePixel = 0
    label.Font = Enum.Font.Code
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextSize = 16
    label.Parent = notifGui
    Instance.new("UICorner", label).CornerRadius = UDim.new(0, 6)
    
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    TweenService:Create(label, tweenInfo, {Position = UDim2.new(0.5, -150, 0, 10)}):Play()
    
    task.wait(duration or 3)
    
    TweenService:Create(label, tweenInfo, {Position = UDim2.new(0.5, -150, -0.1, 0)}):Play()
    task.wait(0.5)
    notifGui:Destroy()
end

-- Dummy function for NaProtectUI to avoid errors
local function NaProtectUI(ui)
    -- In a real environment, this would protect the GUI. Here, it does nothing.
end

-- Create the main window
local MainWindow = Instance.new("Frame")
MainWindow.Size = UDim2.new(0, 300, 0, 180)
MainWindow.Position = UDim2.new(0.5, -150, 0.5, -90)
MainWindow.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
MainWindow.BorderSizePixel = 0
MainWindow.Visible = true
MainWindow.Parent = MainGui
Instance.new("UICorner", MainWindow).CornerRadius = UDim.new(0, 8)

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainWindow
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 6)

local TitleLabel = Instance.new("TextLabel", TitleBar)
TitleLabel.Size = UDim2.new(1, 0, 1, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.SourceSansSemibold
TitleLabel.Text = "Tool Reach"
TitleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
TitleLabel.TextSize = 16

-- Drag functionality
local function makeDraggable(gui, dragHandle)
    local dragging = false
    local dragStart
    local startPos
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = gui.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                local delta = input.Position - dragStart
                gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end
    end)
end
makeDraggable(MainWindow, TitleBar)

-- UI Content
local ContentFrame = Instance.new("Frame", MainWindow)
ContentFrame.Size = UDim2.new(1, 0, 1, -30)
ContentFrame.Position = UDim2.new(0, 0, 0, 30)
ContentFrame.BackgroundTransparency = 1
local ListLayout = Instance.new("UIListLayout", ContentFrame)
ListLayout.Padding = UDim.new(0, 8)
ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local ReachSizeBox = Instance.new("TextBox")
ReachSizeBox.Size = UDim2.new(1, -20, 0, 30)
ReachSizeBox.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
ReachSizeBox.BorderSizePixel = 0
ReachSizeBox.Font = Enum.Font.Code
ReachSizeBox.Text = tostring(Config.DefaultReachSize)
ReachSizeBox.TextColor3 = Color3.fromRGB(220, 220, 220)
ReachSizeBox.TextSize = 14
ReachSizeBox.PlaceholderText = "Reach Size"
ReachSizeBox.Parent = ContentFrame
Instance.new("UICorner", ReachSizeBox).CornerRadius = UDim.new(0, 4)

local function CreateButton(text, parent, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    btn.TextColor3 = Color3.fromRGB(220, 220, 230)
    btn.Font = Enum.Font.Code
    btn.Text = text
    btn.TextSize = 14
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

--//==================================================================================//--
--// Reach Module (User-Provided)
--//==================================================================================//--

local Modules = {}
Modules.Reach = { State = { UI = nil } }

function Modules.Reach:_getTool()
    return (LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")) or (LocalPlayer.Backpack and LocalPlayer.Backpack:FindFirstChildOfClass("Tool"))
end

function Modules.Reach:Apply(reachType, size)
    if self.State.UI then self.State.UI:Destroy() end
    local tool = self:_getTool()
    if not tool then return DoNotif("No tool equipped.", 3) end
    local parts = {}
    for _, p in ipairs(tool:GetDescendants()) do
        if p:IsA("BasePart") then table.insert(parts, p) end
    end
    if #parts == 0 then return DoNotif("Tool has no parts.", 3) end
    
    local ui = Instance.new("ScreenGui")
    ui.Name = "ReachPartSelector"
    NaProtectUI(ui)
    self.State.UI = ui
    
    local frame = Instance.new("Frame", ui)
    frame.Size = UDim2.fromOffset(250, 200)
    frame.Position = UDim2.new(0.5, -125, 0.5, -100)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    
    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.Code
    title.Text = "Select a Part"
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
            if not part or not part.Parent then ui:Destroy(); return DoNotif("Part no longer exists.", 3) end
            
            if not part:FindFirstChild("OGSize3") then
                local v = Instance.new("Vector3Value", part)
                v.Name = "OGSize3"
                v.Value = part.Size
            end
            
            if part:FindFirstChild("FunTIMES") then part.FunTIMES:Destroy() end
            
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
            self.State.UI = nil
            DoNotif("Applied reach to " .. part.Name, 3)
        end)
    end
end

function Modules.Reach:Reset()
    local tool = self:_getTool()
    if not tool then return DoNotif("No tool to reset.", 3) end
    
    for _, p in ipairs(tool:GetDescendants()) do
        if p:IsA("BasePart") then
            if p:FindFirstChild("OGSize3") then
                p.Size = p.OGSize3.Value
                p.OGSize3:Destroy()
            end
            if p:FindFirstChild("FunTIMES") then
                p.FunTIMES:Destroy() -- Corrected typo from FUNTIMES to FunTIMES
            end
        end
    end
    DoNotif("Tool reach reset.", 3)
end

--//==================================================================================//--
--// UI Connections & Input Handling
--//==================================================================================//--

local function getReachSize()
    local num = tonumber(ReachSizeBox.Text)
    return num and num > 0 and num or Config.DefaultReachSize
end

CreateButton("Apply Box Reach", ContentFrame, function()
    Modules.Reach:Apply("box", getReachSize())
end)

CreateButton("Apply Z-Axis Reach", ContentFrame, function()
    Modules.Reach:Apply("z-axis", getReachSize())
end)

CreateButton("Reset Reach", ContentFrame, function()
    Modules.Reach:Reset()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    if input.KeyCode == Config.UIToggleKey then
        MainWindow.Visible = not MainWindow.Visible
    end
end)

print("Reach Script Loaded. Press '" .. Config.UIToggleKey.Name .. "' to toggle UI.")