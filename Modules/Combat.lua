-- ================================================
--  MM2 Silent Aim | Final Fixed (No Nils)
-- ================================================

local Players    = game:GetService("Players")
local RS         = game:GetService("RunService")
local VIM        = game:GetService("VirtualInputManager")
local UIS        = game:GetService("UserInputService")
local Camera     = workspace.CurrentCamera
local LP         = Players.LocalPlayer
local Mouse      = LP:GetMouse()

-- ================================================
--  CONFIG
-- ================================================
getgenv().Config = {
    SilentAim   = false,
    ShowDot     = true,
    ShowBtn     = false,
    FOVEnabled  = true,
    FOVRadius   = 250,
    Prediction  = true,
    PredictTime = 0.09,
}

-- ================================================
--  ОЧИСТКА
-- ================================================
pcall(function()
    if getgenv().CombatVisuals then
        getgenv().CombatVisuals:Destroy()
        getgenv().CombatVisuals = nil
    end
end)
pcall(function()
    if getgenv().SAConnections then
        for _, c in ipairs(getgenv().SAConnections) do
            pcall(function() c:Disconnect() end)
        end
        getgenv().SAConnections = {}
    end
end)
getgenv().SAConnections = {}

-- ================================================
--  GUI
-- ================================================
local Visuals           = Instance.new("ScreenGui")
Visuals.Name            = "CombatVisuals"
Visuals.ResetOnSpawn    = false
Visuals.DisplayOrder    = 999
Visuals.IgnoreGuiInset  = true
Visuals.Parent          = game:GetService("CoreGui")
getgenv().CombatVisuals = Visuals

local Dot             = Instance.new("Frame", Visuals)
Dot.Size              = UDim2.new(0, 12, 0, 12)
Dot.BackgroundColor3  = Color3.fromRGB(255, 40, 40)
Dot.Visible           = false
Dot.AnchorPoint       = Vector2.new(0.5, 0.5)
Dot.ZIndex            = 100
Dot.BorderSizePixel   = 0
Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)
local DotStroke       = Instance.new("UIStroke", Dot)
DotStroke.Color       = Color3.new(1, 1, 1)
DotStroke.Thickness   = 1.5

local FOVFrame        = Instance.new("Frame", Visuals)
FOVFrame.BackgroundTransparency = 1
FOVFrame.AnchorPoint  = Vector2.new(0.5, 0.5)
FOVFrame.ZIndex       = 98
FOVFrame.Visible      = false
FOVFrame.BorderSizePixel = 0
Instance.new("UICorner", FOVFrame).CornerRadius = UDim.new(1, 0)
local FOVStroke       = Instance.new("UIStroke", FOVFrame)
FOVStroke.Color       = Color3.fromRGB(220, 220, 220)
FOVStroke.Thickness   = 1

-- ================================================
--  КНОПКА
-- ================================================
local ShootBtn            = Instance.new("TextButton", Visuals)
ShootBtn.Size             = UDim2.new(0, 180, 0, 50)
ShootBtn.Position         = UDim2.new(0.5, -90, 0.85, 0)
ShootBtn.Text             = "🔫  SHOOT"
ShootBtn.Visible          = false
ShootBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
ShootBtn.TextColor3       = Color3.fromRGB(255, 60, 60)
ShootBtn.Font             = Enum.Font.GothamBold
ShootBtn.TextSize         = 15
ShootBtn.ZIndex           = 200
ShootBtn.BorderSizePixel  = 0
Instance.new("UICorner", ShootBtn)
local BtnStroke           = Instance.new("UIStroke", ShootBtn)
BtnStroke.Color           = Color3.fromRGB(255, 60, 60)
BtnStroke.Thickness       = 1.2

local dragging, dragStart, startPos, wasDragged = false, nil, nil, false

ShootBtn.InputBegan:Connect(function(input)
    if not input then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging   = true
        wasDragged = false
        dragStart  = input.Position
        startPos   = ShootBtn.Position
    end
end)

ShootBtn.InputEnded:Connect(function(input)
    if not input then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UIS.InputChanged:Connect(function(input)
    if not dragging or not input or not dragStart or not startPos then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement
    and input.UserInputType ~= Enum.UserInputType.Touch then return end
    local ok, delta = pcall(function() return input.Position - dragStart end)
    if not ok or not delta then return end
    if delta.Magnitude > 5 then wasDragged = true end
    pcall(function()
        ShootBtn.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end)
end)

-- ================================================
--  PREDICTION
-- ================================================
local PosHistory = {}

local function RecordPositions()
    local ok, err = pcall(function()
        local now = tick()
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LP or not p or not p.Character then continue end
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end
            PosHistory[p] = PosHistory[p] or {}
            table.insert(PosHistory[p], { pos = hrp.Position, t = now })
            if #PosHistory[p] > 10 then table.remove(PosHistory[p], 1) end
        end
    end)
end

local function PredictPos(player, basePos)
    if not player or not basePos then return basePos end
    if not getgenv().Config or not getgenv().Config.Prediction then return basePos end
    local hist = PosHistory[player]
    if not hist or #hist < 2 then return basePos end
    local ok, result = pcall(function()
        local dt = hist[#hist].t - hist[1].t
        if dt <= 0 then return basePos end
        local vel = (hist[#hist].pos - hist[1].pos) / dt
        return basePos + vel * getgenv().Config.PredictTime
    end)
    return (ok and result) or basePos
end

-- ================================================
--  ПОИСК МАРДЕРА
-- ================================================
local function GetMurderer()
    local ok, player, torso = pcall(function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LP or not p or not p.Character then continue end
            local hasKnife = p.Character:FindFirstChild("Knife")
                          or p.Backpack:FindFirstChild("Knife")
            if not hasKnife then continue end
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then continue end
            local torso = p.Character:FindFirstChild("UpperTorso")
                       or p.Character:FindFirstChild("Torso")
                       or p.Character:FindFirstChild("HumanoidRootPart")
            if not torso then continue end
            return p, torso
        end
        return nil, nil
    end)
    if not ok then return nil, nil end
    return player, torso
end

local function GetAimPos()
    local cfg = getgenv().Config
    if not cfg or not cfg.SilentAim then return nil, nil end

    local player, torso = GetMurderer()
    if not player or not torso then return nil, nil end

    local predicted = PredictPos(player, torso.Position)
    if not predicted then return nil, nil end

    if cfg.FOVEnabled then
        local ok, sp, onScreen = pcall(function()
            return Camera:WorldToViewportPoint(predicted)
        end)
        if not ok or not onScreen then return nil, nil end
        local vp = Camera.ViewportSize
        if not vp then return nil, nil end
        local center = Vector2.new(vp.X / 2, vp.Y / 2)
        if (Vector2.new(sp.X, sp.Y) - center).Magnitude > cfg.FOVRadius then
            return nil, nil
        end
    end

    return predicted, torso
end

-- ================================================
--  RENDER LOOP
-- ================================================
local renderConn = RS.RenderStepped:Connect(function()
    pcall(function()
        local cfg = getgenv().Config
        if not cfg then return end

        RecordPositions()

        -- Обновляем камеру на случай если она поменялась
        Camera = workspace.CurrentCamera
        if not Camera then return end

        local vp = Camera.ViewportSize
        if not vp or vp.X <= 0 or vp.Y <= 0 then return end

        -- FOV круг
        local fovR = tonumber(cfg.FOVRadius) or 250
        FOVFrame.Size     = UDim2.new(0, fovR * 2, 0, fovR * 2)
        FOVFrame.Position = UDim2.new(0, vp.X / 2, 0, vp.Y / 2)
        FOVFrame.Visible  = (cfg.SilentAim == true) and (cfg.FOVEnabled == true)

        -- Dot
        if cfg.SilentAim == true and cfg.ShowDot == true then
            local _, torso = GetMurderer()
            if torso and torso.Parent then
                local ok, sp, onScreen = pcall(function()
                    return Camera:WorldToViewportPoint(torso.Position)
                end)
                if ok and onScreen and sp then
                    Dot.Position = UDim2.new(0, sp.X, 0, sp.Y)
                    Dot.Visible  = true
                    return
                end
            end
        end

        Dot.Visible = false
    end)
end)
table.insert(getgenv().SAConnections, renderConn)

-- ================================================
--  МЕТАТАБЛИЦА
-- ================================================
local mt          = getrawmetatable(game)
local oldIndex    = mt.__index
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__index = newcclosure(function(self, key)
    pcall(function()
        if not getgenv().Config or not getgenv().Config.SilentAim then return end
        if checkcaller() or self ~= Mouse then return end
        local aimPos, torso = GetAimPos()
        if not aimPos or not torso then return end
        if key == "Hit"    then return CFrame.new(aimPos) end
        if key == "Target" then return torso end
    end)
    return oldIndex(self, key)
end)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args   = {...}

    pcall(function()
        if not getgenv().Config or not getgenv().Config.SilentAim then return end
        if checkcaller() then return end
        if method ~= "InvokeServer" and method ~= "FireServer" then return end
        local aimPos = GetAimPos()
        if not aimPos then return end
        for i, v in ipairs(args) do
            if typeof(v) == "Vector3" then
                args[i] = aimPos
                break
            elseif typeof(v) == "CFrame" then
                args[i] = CFrame.new(aimPos)
                break
            end
        end
    end)

    return oldNamecall(self, table.unpack(args))
end)

setreadonly(mt, true)

-- ================================================
--  ВЫСТРЕЛ
-- ================================================
local function SilentShoot()
    pcall(function()
        local char = LP.Character
        if not char then return end
        local gun = char:FindFirstChild("Gun") or LP.Backpack:FindFirstChild("Gun")
        if not gun then return end
        if gun.Parent == LP.Backpack then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:EquipTool(gun)
                task.wait(0.3)
            end
        end
        VIM:SendMouseButtonEvent(0, 0, 0, true,  game, 0)
        task.wait(0.06)
        VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end)
end

ShootBtn.MouseButton1Click:Connect(function()
    if not wasDragged then SilentShoot() end
end)

-- ================================================
--  FLUENT (_G.Tabs.Main)
-- ================================================
task.spawn(function()
    local Tab, Options

    for _ = 1, 50 do
        if _G.Tabs and _G.Tabs.Main and _G.Options then
            Tab     = _G.Tabs.Main
            Options = _G.Options
            break
        end
        task.wait(0.2)
    end

    if not Tab or not Options then
        warn("[SilentAim] _G.Tabs.Main или _G.Options не найдены!")
        return
    end

    local ok1, tSA = pcall(function()
        return Tab:AddToggle("SA_SilentAim", { Title = "Silent Aim", Default = false })
    end)
    if ok1 and tSA then
        tSA:OnChanged(function()
            if Options.SA_SilentAim then
                getgenv().Config.SilentAim = Options.SA_SilentAim.Value
            end
        end)
    end

    local ok2, tDot = pcall(function()
        return Tab:AddToggle("SA_ShowDot", { Title = "Show Target Dot", Default = true })
    end)
    if ok2 and tDot then
        tDot:OnChanged(function()
            if Options.SA_ShowDot then
                getgenv().Config.ShowDot = Options.SA_ShowDot.Value
            end
        end)
    end

    local ok3, tFOV = pcall(function()
        return Tab:AddToggle("SA_FOVEnabled", { Title = "FOV Circle", Default = true })
    end)
    if ok3 and tFOV then
        tFOV:OnChanged(function()
            if Options.SA_FOVEnabled then
                getgenv().Config.FOVEnabled = Options.SA_FOVEnabled.Value
            end
        end)
    end

    pcall(function()
        Tab:AddSlider("SA_FOVRadius", {
            Title = "FOV Radius", Min = 50, Max = 700, Default = 250, Rounding = 0,
            Callback = function(v)
                getgenv().Config.FOVRadius = tonumber(v) or 250
            end,
        })
    end)

    local ok5, tPred = pcall(function()
        return Tab:AddToggle("SA_Prediction", { Title = "Movement Prediction", Default = true })
    end)
    if ok5 and tPred then
        tPred:OnChanged(function()
            if Options.SA_Prediction then
                getgenv().Config.Prediction = Options.SA_Prediction.Value
            end
        end)
    end

    pcall(function()
        Tab:AddSlider("SA_PredictTime", {
            Title = "Prediction Strength", Min = 0, Max = 30, Default = 9, Rounding = 0,
            Callback = function(v)
                getgenv().Config.PredictTime = (tonumber(v) or 9) / 100
            end,
        })
    end)

    local ok7, tBtn = pcall(function()
        return Tab:AddToggle("SA_ShowBtn", { Title = "Show Shoot Button", Default = false })
    end)
    if ok7 and tBtn then
        tBtn:OnChanged(function()
            if Options.SA_ShowBtn then
                ShootBtn.Visible = Options.SA_ShowBtn.Value
            end
        end)
    end
end)

return true
