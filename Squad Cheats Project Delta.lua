-- // CLEANUP: Remove old UI before running
local UI_NAME = "DeltaProjectUI"
local CoreGui = game:GetService("CoreGui")
local existing = CoreGui:FindFirstChild(UI_NAME) or (gethui and gethui():FindFirstChild(UI_NAME))
if existing then 
    existing:Destroy() 
end

-- // SERVICES
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- // VARIABLES
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local AiZones = workspace:FindFirstChild("AiZones")

-- // REQUIRE PROJECT DELTA BULLET MODULE
local Success, BulletModule = pcall(require, ReplicatedStorage.Modules.FPS.Bullet)

if not hookfunction then 
    return LocalPlayer:Kick("Executor missing hookfunction") 
end

-- // SETTINGS
local SilentAim_Enabled = false
local SilentAim_Prediction = true
local SilentAim_HitPart = "Head"
local SilentAim_Radius = 200
local SilentAim_ShowFOV = true

local ESP_Enabled = false
local AI_ESP_Enabled = false
local Skeleton_Enabled = false
local Health_Enabled = false
local Tracers_Enabled = false
local Visibility_Check = false

local Visible_Color = Color3.fromRGB(0, 255, 0)
local Hidden_Color = Color3.fromRGB(255, 0, 0)
local Bone_Thickness = 2

-- // DRAWING OBJECTS
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.Color = Color3.fromRGB(255, 50, 0)
FOVCircle.Transparency = 1
FOVCircle.Filled = false
FOVCircle.Visible = false

local SnapLine = Drawing.new("Line")
SnapLine.Thickness = 1
SnapLine.Color = Color3.fromRGB(255, 255, 255)
SnapLine.Transparency = 1
SnapLine.Visible = false

-- // MAIN UI SETUP
local ScreenGui = Instance.new("ScreenGui", (gethui and gethui()) or CoreGui)
ScreenGui.Name = UI_NAME

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 550, 0, 420)
MainFrame.Position = UDim2.new(0.5, -275, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 10, 10)
MainFrame.BorderColor3 = Color3.fromRGB(255, 50, 0)
MainFrame.Active = true
MainFrame.Draggable = true 

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, -10, 0, 30)
Title.Position = UDim2.new(0, 10, 0, 5)
Title.BackgroundTransparency = 1
Title.Text = "SQUAD CHEATS | PROJECT DELTA"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.Code
Title.TextXAlignment = Enum.TextXAlignment.Left

local TabHolder = Instance.new("Frame", MainFrame)
TabHolder.Size = UDim2.new(1, -20, 0, 30)
TabHolder.Position = UDim2.new(0, 10, 0, 40)
TabHolder.BackgroundTransparency = 1

local TabList = Instance.new("UIListLayout", TabHolder)
TabList.FillDirection = Enum.FillDirection.Horizontal
TabList.Padding = UDim.new(0, 5)

local PageContainer = Instance.new("Frame", MainFrame)
PageContainer.Size = UDim2.new(1, -20, 1, -85)
PageContainer.Position = UDim2.new(0, 10, 0, 75)
PageContainer.BackgroundColor3 = Color3.fromRGB(10, 5, 5)
PageContainer.BorderColor3 = Color3.fromRGB(150, 0, 0)

local Pages = {}

local function CreateTab(name)
    local Page = Instance.new("ScrollingFrame", PageContainer)
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.Visible = false
    Page.ScrollBarThickness = 0
    Pages[name] = Page

    local TabBtn = Instance.new("TextButton", TabHolder)
    TabBtn.Size = UDim2.new(0, 95, 1, 0)
    TabBtn.BackgroundColor3 = Color3.fromRGB(30, 10, 10)
    TabBtn.Text = name
    TabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    TabBtn.Font = Enum.Font.Code

    TabBtn.MouseButton1Click:Connect(function()
        for _, p in pairs(Pages) do 
            p.Visible = false 
        end
        Page.Visible = true
    end)
end

CreateTab("Combat")
CreateTab("Visuals")
CreateTab("Misc")
CreateTab("Settings")

Pages["Combat"].Visible = true

-- // UI BUILDER FUNCTIONS
local function AddToggle(text, page, pos, callback)
    local btn = Instance.new("TextButton", Pages[page])
    btn.Size = UDim2.new(0, 130, 0, 30)
    btn.Position = pos
    btn.BackgroundColor3 = Color3.fromRGB(25, 10, 10)
    btn.Text = text .. ": OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Code

    btn.MouseButton1Click:Connect(function()
        local s = callback()
        btn.Text = text .. ": " .. (s and "ON" or "OFF")
    end)
end

local function AddSlider(text, page, pos, min, max, default, callback)
    local label = Instance.new("TextLabel", Pages[page])
    label.Size = UDim2.new(0, 130, 0, 20)
    label.Position = pos
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. default
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Code

    local sliderFrame = Instance.new("Frame", Pages[page])
    sliderFrame.Size = UDim2.new(0, 130, 0, 5)
    sliderFrame.Position = pos + UDim2.new(0, 0, 0, 22)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)

    local sliderPart = Instance.new("Frame", sliderFrame)
    sliderPart.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    sliderPart.BackgroundColor3 = Color3.fromRGB(255, 50, 0)

    local function update()
        local mousePos = UserInputService:GetMouseLocation().X
        local relativePos = math.clamp((mousePos - sliderFrame.AbsolutePosition.X) / sliderFrame.AbsoluteSize.X, 0, 1)
        sliderPart.Size = UDim2.new(relativePos, 0, 1, 0)
        local val = math.floor(min + (relativePos * (max - min)))
        label.Text = text .. ": " .. val
        callback(val)
    end

    sliderFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local connection
            connection = RunService.RenderStepped:Connect(function()
                if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                    connection:Disconnect()
                else
                    update()
                end
            end)
        end
    end)
end

-- // COMBAT PAGE SETUP
AddToggle("Silent Aim", "Combat", UDim2.new(0, 10, 0, 10), function()
    SilentAim_Enabled = not SilentAim_Enabled
    return SilentAim_Enabled
end)

AddToggle("Prediction", "Combat", UDim2.new(0, 150, 0, 10), function()
    SilentAim_Prediction = not SilentAim_Prediction
    return SilentAim_Prediction
end)

AddToggle("Show FOV", "Combat", UDim2.new(0, 10, 0, 50), function()
    SilentAim_ShowFOV = not SilentAim_ShowFOV
    return SilentAim_ShowFOV
end)

AddSlider("FOV Size", "Combat", UDim2.new(0, 10, 0, 100), 10, 800, 200, function(v)
    SilentAim_Radius = v
end)

-- // VISUALS PAGE SETUP
AddToggle("Box Esp", "Visuals", UDim2.new(0, 10, 0, 10), function()
    ESP_Enabled = not ESP_Enabled
    return ESP_Enabled
end)

AddToggle("AI Esp", "Visuals", UDim2.new(0, 150, 0, 10), function()
    AI_ESP_Enabled = not AI_ESP_Enabled
    return AI_ESP_Enabled
end)

AddToggle("Skeleton", "Visuals", UDim2.new(0, 10, 0, 50), function()
    Skeleton_Enabled = not Skeleton_Enabled
    return Skeleton_Enabled
end)

AddToggle("Health Bar", "Visuals", UDim2.new(0, 150, 0, 50), function()
    Health_Enabled = not Health_Enabled
    return Health_Enabled
end)

AddToggle("Tracers", "Visuals", UDim2.new(0, 10, 0, 90), function()
    Tracers_Enabled = not Tracers_Enabled
    return Tracers_Enabled
end)

AddToggle("Vis Check", "Visuals", UDim2.new(0, 150, 0, 90), function()
    Visibility_Check = not Visibility_Check
    return Visibility_Check
end)

-- // MULTI-POINT VISIBILITY CHECK (FOR ESP ONLY)
local function IsPlayerVisible(char)
    if not Visibility_Check then 
        return true 
    end
    
    local checkParts = {
        char:FindFirstChild("Head"),
        char:FindFirstChild("UpperTorso"),
        char:FindFirstChild("LeftUpperArm"),
        char:FindFirstChild("RightUpperArm")
    }
    
    local ignoreList = {Camera, LocalPlayer.Character, char}
    
    for _, part in pairs(checkParts) do
        if part then
            local castPoints = {part.Position}
            local blockingParts = Camera:GetPartsObscuringTarget(castPoints, ignoreList)
            
            local isPartVisible = true
            for _, block in pairs(blockingParts) do
                if block.CanCollide == false or block.Transparency > 0.4 or block.Name:lower():find("grass") or block.Name:lower():find("bush") or block.Name:lower():find("leaf") then
                    continue
                end
                isPartVisible = false
                break
            end
            
            if isPartVisible then 
                return true 
            end
        end
    end
    
    return false
end

-- // SILENT AIM LOGIC (WALL CHECK REMOVED)
local function IsAlive(char)
    return char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0
end

local function GetAiCharacters()
    local chars = {}
    if AiZones then
        for _, zone in pairs(AiZones:GetChildren()) do
            for _, ai in pairs(zone:GetChildren()) do 
                table.insert(chars, ai) 
            end
        end
    end
    return chars
end

local function GetClosestTarget()
    local target = nil
    local shortestDistance = SilentAim_Radius
    local mousePos = UserInputService:GetMouseLocation()

    local function Scan(char)
        if not IsAlive(char) or char == LocalPlayer.Character then 
            return 
        end
        
        local hitPart = char:FindFirstChild(SilentAim_HitPart)
        if not hitPart then 
            return 
        end

        local pos, onScreen = Camera:WorldToViewportPoint(hitPart.Position)
        if onScreen then
            local distance = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                target = hitPart
            end
        end
    end

    for _, p in pairs(Players:GetPlayers()) do 
        Scan(p.Character) 
    end
    
    for _, ai in pairs(GetAiCharacters()) do 
        Scan(ai) 
    end
    
    return target
end

-- // SILENT AIM HOOK
if Success and BulletModule then
    local oldCreateBullet
    oldCreateBullet = hookfunction(BulletModule.CreateBullet, function(a, b, c, d, aim, e, ammo, tickVal, recoil)
        if not SilentAim_Enabled then 
            return oldCreateBullet(a, b, c, d, aim, e, ammo, tickVal, recoil) 
        end

        local targetPart = GetClosestTarget()

        if targetPart then
            local ammoData = ReplicatedStorage.AmmoTypes:FindFirstChild(ammo)
            if ammoData then
                local dropScale = ammoData:GetAttribute("ProjectileDrop")
                local velocity = ammoData:GetAttribute("MuzzleVelocity")
                ammoData:SetAttribute("Drag", 0)

                local finalPos = targetPart.Position
                local g = Vector3.yAxis * (dropScale * 2)

                if SilentAim_Prediction then
                    local dist = (targetPart.Position - aim.Position).Magnitude
                    local time = dist / velocity
                    finalPos = targetPart.Position + (targetPart.Velocity * time)
                end

                local timeFinal = (finalPos - aim.Position).Magnitude / velocity
                local dropCorrection = 0.5 * g * timeFinal^2
                
                local newAim = {
                    ["CFrame"] = CFrame.new(aim.Position, finalPos + dropCorrection)
                }
                
                return oldCreateBullet(a, b, c, d, newAim, e, ammo, tickVal, recoil)
            end
        end

        return oldCreateBullet(a, b, c, d, aim, e, ammo, tickVal, recoil)
    end)
end

-- // ESP DRAWING LOGIC
local function NewLine(thick)
    local l = Drawing.new("Line")
    l.Thickness = thick or 1
    l.Visible = false
    return l
end

local function CreateESP(obj, isAI)
    local Box = Drawing.new("Square")
    Box.Filled = false
    Box.Thickness = 1

    local Tracer = NewLine(1)
    
    local HealthBar = Drawing.new("Square")
    HealthBar.Filled = true

    local Skeleton = {
        Neck = NewLine(Bone_Thickness),
        Spine = NewLine(Bone_Thickness),
        L_S = NewLine(Bone_Thickness),
        L_E = NewLine(Bone_Thickness),
        L_W = NewLine(Bone_Thickness),
        R_S = NewLine(Bone_Thickness),
        R_E = NewLine(Bone_Thickness),
        R_W = NewLine(Bone_Thickness),
        L_H = NewLine(Bone_Thickness),
        L_K = NewLine(Bone_Thickness),
        L_A = NewLine(Bone_Thickness),
        R_H = NewLine(Bone_Thickness),
        R_K = NewLine(Bone_Thickness),
        R_A = NewLine(Bone_Thickness)
    }

    RunService.RenderStepped:Connect(function()
        local char = isAI and obj or obj.Character
        local is_tagged = (not isAI) or (isAI and AI_ESP_Enabled)

        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
            local Root = char.HumanoidRootPart
            local Pos, OnScreen = Camera:WorldToViewportPoint(Root.Position)

            if OnScreen and is_tagged then
                local isVisible = IsPlayerVisible(char)
                local currentColor = isVisible and Visible_Color or Hidden_Color
                
                local Top = Camera:WorldToViewportPoint(Root.Position + Vector3.new(0, 3, 0))
                local Bottom = Camera:WorldToViewportPoint(Root.Position - Vector3.new(0, 3.5, 0))
                
                local SizeY = math.abs(Top.Y - Bottom.Y)
                local SizeX = SizeY / 1.5

                Box.Visible = ESP_Enabled
                Box.Size = Vector2.new(SizeX, SizeY)
                Box.Position = Vector2.new(Pos.X - SizeX/2, Pos.Y - SizeY/2)
                Box.Color = currentColor

                Tracer.Visible = Tracers_Enabled
                Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                Tracer.To = Vector2.new(Pos.X, Pos.Y + SizeY/2)
                Tracer.Color = currentColor

                if Health_Enabled then
                    local HP = char.Humanoid.Health / char.Humanoid.MaxHealth
                    HealthBar.Visible = true
                    HealthBar.Size = Vector2.new(2, SizeY * HP)
                    HealthBar.Position = Vector2.new(Pos.X - SizeX/2 - 6, Pos.Y + SizeY/2 - (SizeY * HP))
                    HealthBar.Color = Color3.fromHSV(HP * 0.3, 1, 1)
                else
                    HealthBar.Visible = false
                end

                if Skeleton_Enabled then
                    local function GetV2(p)
                        local pt = char:FindFirstChild(p)
                        if pt then
                            local v3 = Camera:WorldToViewportPoint(pt.Position)
                            return Vector2.new(v3.X, v3.Y)
                        end
                    end
                    
                    local function Connect(l, p1, p2)
                        if p1 and p2 then
                            l.From = p1
                            l.To = p2
                            l.Color = currentColor
                            l.Visible = true
                        else
                            l.Visible = false
                        end
                    end

                    Connect(Skeleton.Neck, GetV2("Head"), GetV2("UpperTorso"))
                    Connect(Skeleton.Spine, GetV2("UpperTorso"), GetV2("LowerTorso"))
                    Connect(Skeleton.L_S, GetV2("UpperTorso"), GetV2("LeftUpperArm"))
                    Connect(Skeleton.L_E, GetV2("LeftUpperArm"), GetV2("LeftLowerArm"))
                    Connect(Skeleton.L_W, GetV2("LeftLowerArm"), GetV2("LeftHand"))
                    Connect(Skeleton.R_S, GetV2("UpperTorso"), GetV2("RightUpperArm"))
                    Connect(Skeleton.R_E, GetV2("RightUpperArm"), GetV2("RightLowerArm"))
                    Connect(Skeleton.R_W, GetV2("RightLowerArm"), GetV2("RightHand"))
                    Connect(Skeleton.L_H, GetV2("LowerTorso"), GetV2("LeftUpperLeg"))
                    Connect(Skeleton.L_K, GetV2("LeftUpperLeg"), GetV2("LeftLowerLeg"))
                    Connect(Skeleton.L_A, GetV2("LeftLowerLeg"), GetV2("LeftFoot"))
                    Connect(Skeleton.R_H, GetV2("LowerTorso"), GetV2("RightUpperLeg"))
                    Connect(Skeleton.R_K, GetV2("RightUpperLeg"), GetV2("RightLowerLeg"))
                    Connect(Skeleton.R_A, GetV2("RightLowerLeg"), GetV2("RightFoot"))
                else
                    for _, l in pairs(Skeleton) do 
                        l.Visible = false 
                    end
                end
            else
                Box.Visible = false
                Tracer.Visible = false
                HealthBar.Visible = false
                for _, l in pairs(Skeleton) do 
                    l.Visible = false 
                end
            end
        else
            Box.Visible = false
            Tracer.Visible = false
            HealthBar.Visible = false
            for _, l in pairs(Skeleton) do 
                l.Visible = false 
            end
        end
    end)
end

-- // MAIN RENDERING LOOP
RunService.RenderStepped:Connect(function()
    local mousePos = UserInputService:GetMouseLocation()
    
    FOVCircle.Visible = SilentAim_ShowFOV
    FOVCircle.Radius = SilentAim_Radius
    FOVCircle.Position = mousePos

    if SilentAim_Enabled then
        local target = GetClosestTarget()
        if target then
            local pos, onScreen = Camera:WorldToViewportPoint(target.Position)
            if onScreen then
                SnapLine.Visible = true
                SnapLine.From = mousePos
                SnapLine.To = Vector2.new(pos.X, pos.Y)
            else
                SnapLine.Visible = false
            end
        else
            SnapLine.Visible = false
        end
    else
        SnapLine.Visible = false
    end
end)

-- // INITIALIZATION
for _, v in pairs(Players:GetPlayers()) do
    if v ~= LocalPlayer then 
        CreateESP(v, false) 
    end
end

Players.PlayerAdded:Connect(function(v)
    CreateESP(v, false)
end)

local function ScanAI()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(v) and v ~= LocalPlayer.Character and not v:FindFirstChild("ESP_Tagged") then
            Instance.new("BoolValue", v).Name = "ESP_Tagged"
            CreateESP(v, true)
        end
    end
end

task.spawn(function()
    while task.wait(5) do 
        ScanAI() 
    end
end)

UserInputService.InputBegan:Connect(function(i)
    if i.KeyCode == Enum.KeyCode.RightShift then 
        MainFrame.Visible = not MainFrame.Visible 
    end
end)
