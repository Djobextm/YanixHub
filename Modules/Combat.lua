-- ================================================
--  MM2 Silent Aim | Fluent UI Fix
-- ================================================

local Players    = game:GetService("Players")
local RS         = game:GetService("RunService")
local VIM        = game:GetService("VirtualInputManager")
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
if getgenv().CombatVisuals then
    pcall(function() getgenv().CombatVisuals:Destroy() end)
    getgenv().CombatVisuals = nil
end
if getgenv().SAConnections then
    for _, c in ipairs(getgenv().SAConnections) do
        pcall(function() c:Disconnect() end)
    end
end
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

-- Dot
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

-- FOV круг
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
--  ПЕРЕТАСКИВАЕМАЯ КНОПКА
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

-- Drag
local dragging, dragStart, startPos, wasDragged = false, nil, nil, false

ShootBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging   = true
        wasDragged = false
        dragStart  = input.Position
        startPos   = ShootBtn.Position
    end
end)

ShootBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement
    and input.UserInputType ~= Enum.UserInputType.Touch then return end
    local delta = input.Position - dragStart
    if delta.Magnitude > 5 then wasDragged = true end
    ShootBtn.Position = UDim2.new(
        startPos.X.Scale, startPos.X.Offset + delta.X,
        startPos.Y.Scale, startPos.Y.Offset + delta.Y
    )
end)

-- ================================================
--  PREDICTION
-- ================================================
local PosHistory = {}

local function RecordPositions()
    local now = tick()
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP or not p.Character then continue end
        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        PosHistory[p] = PosHistory[p] or {}
        table.insert(PosHistory[p], { pos = hrp.Position, t = now })
        if #PosHistory[p] > 10 then table.remove(PosHistory[p], 1) end
    end
end

local function PredictPos(player, basePos)
    if not getgenv().Config.Prediction then return basePos end
    local hist = PosHistory[player]
    if not hist or #hist < 2 then return basePos end
    local dt = hist[#hist].t - hist[1].t
    if dt <= 0 then return basePos end
    local vel = (hist[#hist].pos - hist[1].pos) / dt
    return basePos + vel * getgenv().Config.PredictTime
end

-- ================================================
--  ПОИСК МАРДЕРА
-- ================================================
local function GetMurderer()
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP or not p.Character then continue end
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
end

local function GetAimPos()
    local cfg = getgenv().Config
    local player, torso = GetMurderer()
    if not player then return nil, nil end
    local predicted = PredictPos(player, torso.Position)
    if cfg.FOVEnabled then
        local sp, onScreen = Camera:WorldToViewportPoint(predicted)
        if not onScreen then return nil, nil end
        local center = Camera.ViewportSize / 2
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
    local cfg = getgenv().Config
    RecordPositions()

    local vp = Camera.ViewportSize
    FOVFrame.Size     = UDim2.new(0, cfg.FOVRadius * 2, 0, cfg.FOVRadius * 2)
    FOVFrame.Position = UDim2.new(0, vp.X / 2, 0, vp.Y / 2)
    FOVFrame.Visible  = cfg.SilentAim and cfg.FOVEnabled

    if cfg.SilentAim and cfg.ShowDot then
        local _, torso = GetMurderer()
        if torso then
            local sp, onScreen = Camera:WorldToViewportPoint(torso.Position)
            if onScreen then
                Dot.Position = UDim2.new(0, sp.X, 0, sp.Y)
                Dot.Visible  = true
                return
            end
        end
    end
    Dot.Visible = false
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
    if getgenv().Config.SilentAim and not checkcaller() and self == Mouse then
        local aimPos, torso = GetAimPos()
        if aimPos and torso then
            if key == "Hit"    then return CFrame.new(aimPos) end
            if key == "Target" then return torso end
        end
    end
    return oldIndex(self, key)
end)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args   = {...}

    if getgenv().Config.SilentAim and not checkcaller() then
        if method == "InvokeServer" or method == "FireServer" then
            local aimPos = GetAimPos()
            if aimPos then
                for i, v in ipairs(args) do
                    if typeof(v) == "Vector3" then
                        args[i] = aimPos
                        break
                    elseif typeof(v) == "CFrame" then
                        args[i] = CFrame.new(aimPos)
                        break
                    end
                end
                return oldNamecall(self, table.unpack(args))
            end
        end
    end

    return oldNamecall(self, ...)
end)

setreadonly(mt, true)

-- ================================================
--  ВЫСТРЕЛ
-- ================================================
local function SilentShoot()
    local char = LP.Character
    if not char then return end
    local gun = char:FindFirstChild("Gun") or LP.Backpack:FindFirstChild("Gun")
    if not gun then return end
    if gun.Parent == LP.Backpack then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum:EquipTool(gun) task.wait(0.3) end
    end
    VIM:SendMouseButtonEvent(0, 0, 0, true,  game, 0)
    task.wait(0.06)
    VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

ShootBtn.MouseButton1Click:Connect(function()
    if not wasDragged then SilentShoot() end
end)

-- ================================================
--  FLUENT UI ИНТЕГРАЦИЯ
-- ================================================
task.spawn(function()
    -- Ждём пока Fluent и таб Combat загрузятся
    local Tab
    for _ = 1, 40 do
        if _G.Tabs and _G.Tabs.Combat then
            Tab = _G.Tabs.Combat
            break
        end
        task.wait(0.2)
    end
    if not Tab then
        warn("Silent Aim: Combat таб не найден")
        return
    end

    -- Fluent синтаксис
    Tab:AddToggle("SilentAim", {
        Title   = "Silent Aim",
        Default = false,
        Callback = function(v)
            getgenv().Config.SilentAim = v
        end
    })

    Tab:AddToggle("ShowDot", {
        Title   = "Show Target Dot",
        Default = true,
        Callback = function(v)
            getgenv().Config.ShowDot = v
        end
    })

    Tab:AddToggle("FOVEnabled", {
        Title   = "FOV Circle",
        Default = true,
        Callback = function(v)
            getgenv().Config.FOVEnabled = v
        end
    })

    Tab:AddSlider("FOVRadius", {
        Title   = "FOV Radius",
        Min     = 50,
        Max     = 700,
        Default = 250,
        Rounding = 0,
        Callback = function(v)
            getgenv().Config.FOVRadius = v
        end
    })

    Tab:AddToggle("Prediction", {
        Title   = "Movement Prediction",
        Default = true,
        Callback = function(v)
            getgenv().Config.Prediction = v
        end
    })

    Tab:AddSlider("PredictTime", {
        Title    = "Prediction Strength",
        Min      = 0,
        Max      = 30,
        Default  = 9,
        Rounding = 0,
        Callback = function(v)
            getgenv().Config.PredictTime = v / 100
        end
    })

    Tab:AddToggle("ShowBtn", {
        Title   = "Show Shoot Button",
        Default = false,
        Callback = function(v)
            ShootBtn.Visible = v
        end
    })
end)

return true
