-- ================================================
--  MM2 Silent Aim | Final Stable Version
--  + Wall/Distance bypass + Movement Prediction
-- ================================================

local Players    = game:GetService("Players")
local RS         = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local VIM        = game:GetService("VirtualInputManager")
local Camera     = workspace.CurrentCamera
local LP         = Players.LocalPlayer
local Mouse      = LP:GetMouse()

-- ================================================
--  CONFIG
-- ================================================
getgenv().Config = getgenv().Config or {
    SilentAim   = false,
    ShowDot     = true,
    FOVEnabled  = true,
    FOVRadius   = 250,
    Prediction  = true,
    PredictTime = 0.09,  -- секунд вперёд (подбери под пинг)
}

-- ================================================
--  ОЧИСТКА ПРЕДЫДУЩЕГО ЗАПУСКА
-- ================================================
if getgenv().CombatVisuals then
    pcall(function() getgenv().CombatVisuals:Destroy() end)
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
local Visuals            = Instance.new("ScreenGui")
Visuals.Name             = "CombatVisuals"
Visuals.ResetOnSpawn     = false
Visuals.DisplayOrder     = 999
Visuals.IgnoreGuiInset   = true
Visuals.Parent           = game:GetService("CoreGui")
getgenv().CombatVisuals  = Visuals

-- Красная точка на цели
local Dot                = Instance.new("Frame", Visuals)
Dot.Size                 = UDim2.new(0, 12, 0, 12)
Dot.BackgroundColor3     = Color3.fromRGB(255, 40, 40)
Dot.Visible              = false
Dot.AnchorPoint          = Vector2.new(0.5, 0.5)
Dot.ZIndex               = 100
Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)
local DotStroke          = Instance.new("UIStroke", Dot)
DotStroke.Color          = Color3.new(1, 1, 1)
DotStroke.Thickness      = 1.5

-- FOV круг
local FOVFrame           = Instance.new("Frame", Visuals)
FOVFrame.BackgroundTransparency = 1
FOVFrame.AnchorPoint     = Vector2.new(0.5, 0.5)
FOVFrame.ZIndex          = 98
Instance.new("UICorner", FOVFrame).CornerRadius = UDim.new(1, 0)
local FOVStroke          = Instance.new("UIStroke", FOVFrame)
FOVStroke.Color          = Color3.fromRGB(200, 200, 200)
FOVStroke.Thickness      = 1

-- ================================================
--  PREDICTION (история позиций)
-- ================================================
local PosHistory = {}  -- { [player] = { {pos, time}, ... } }

local function RecordPositions()
    local now = tick()
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP or not p.Character then continue end
        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        if not PosHistory[p] then PosHistory[p] = {} end
        table.insert(PosHistory[p], { pos = hrp.Position, t = now })
        -- храним только последние 10 записей
        if #PosHistory[p] > 10 then
            table.remove(PosHistory[p], 1)
        end
    end
end

-- Считаем среднюю скорость и предсказываем позицию
local function PredictPosition(player, torso)
    local cfg = getgenv().Config
    if not cfg.Prediction then return torso.Position end

    local hist = PosHistory[player]
    if not hist or #hist < 2 then return torso.Position end

    local oldest = hist[1]
    local newest = hist[#hist]
    local dt = newest.t - oldest.t
    if dt <= 0 then return torso.Position end

    local velocity = (newest.pos - oldest.pos) / dt
    return torso.Position + velocity * cfg.PredictTime
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

-- Получить финальную позицию цели (с prediction и FOV проверкой)
local function GetTargetPosition()
    local cfg = getgenv().Config
    local player, torso = GetMurderer()
    if not torso then return nil, nil end

    local predicted = PredictPosition(player, torso)

    -- FOV проверка (по predicted позиции)
    if cfg.FOVEnabled then
        local sp, onScreen = Camera:WorldToViewportPoint(predicted)
        if not onScreen then return nil, nil end
        local center = Camera.ViewportSize / 2
        local dist   = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if dist > cfg.FOVRadius then return nil, nil end
    end

    return predicted, torso
end

-- ================================================
--  RENDER LOOP
-- ================================================
local renderConn = RS.RenderStepped:Connect(function()
    local cfg = getgenv().Config

    -- Обновляем историю позиций каждый кадр
    RecordPositions()

    -- FOV круг
    local vp = Camera.ViewportSize
    FOVFrame.Size     = UDim2.new(0, cfg.FOVRadius * 2, 0, cfg.FOVRadius * 2)
    FOVFrame.Position = UDim2.new(0, vp.X / 2, 0, vp.Y / 2)
    FOVFrame.Visible  = cfg.SilentAim and cfg.FOVEnabled

    -- Точка на цели
    if cfg.SilentAim and cfg.ShowDot then
        local predicted, torso = GetTargetPosition()
        if predicted then
            local sp, onScreen = Camera:WorldToViewportPoint(predicted)
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
        local predicted, torso = GetTargetPosition()
        if predicted and torso then
            if key == "Hit" then
                -- CFrame смотрит от камеры на predicted позицию
                return CFrame.new(predicted)
            elseif key == "Target" then
                return torso
            end
        end
    end
    return oldIndex(self, key)
end)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args   = {...}

    if getgenv().Config.SilentAim and not checkcaller() then
        -- Прямая подмена точки попадания в сетевом запросе выстрела
        if method == "InvokeServer" and tostring(self) == "ShootGun" then
            local predicted, _ = GetTargetPosition()
            if predicted then
                args[2] = predicted
                return oldNamecall(self, table.unpack(args))
            end
        end

        -- Подмена FireServer (на случай если игра использует RemoteEvent)
        if method == "FireServer" and tostring(self) == "ShootGun" then
            local predicted, _ = GetTargetPosition()
            if predicted then
                args[2] = predicted
                return oldNamecall(self, table.unpack(args))
            end
        end
    end

    return oldNamecall(self, ...)
end)

setreadonly(mt, true)

-- ================================================
--  КНОПКА ВЫСТРЕЛА
-- ================================================
local ShootBtn               = Instance.new("TextButton", Visuals)
ShootBtn.Size                = UDim2.new(0, 170, 0, 50)
ShootBtn.Position            = UDim2.new(0.5, -85, 0.75, 0)
ShootBtn.Text                = "🔫 SHOOT MURDERER"
ShootBtn.Visible             = false
ShootBtn.BackgroundColor3    = Color3.fromRGB(18, 18, 18)
ShootBtn.TextColor3          = Color3.fromRGB(255, 60, 60)
ShootBtn.Font                = Enum.Font.GothamBold
ShootBtn.TextSize            = 14
ShootBtn.AutoButtonColor     = true
ShootBtn.ZIndex              = 200
Instance.new("UICorner", ShootBtn)
local BtnStroke              = Instance.new("UIStroke", ShootBtn)
BtnStroke.Color              = Color3.fromRGB(255, 60, 60)
BtnStroke.Thickness          = 1

local function SilentShoot()
    local char = LP.Character
    if not char then return end

    local gun = char:FindFirstChild("Gun") or LP.Backpack:FindFirstChild("Gun")
    if not gun then return end

    -- Достать пистолет из рюкзака если нужно
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
end

ShootBtn.MouseButton1Click:Connect(SilentShoot)

-- ================================================
--  ИНТЕГРАЦИЯ В МЕНЮ
-- ================================================
task.spawn(function()
    local Tab
    for _ = 1, 25 do
        if _G.Tabs and _G.Tabs.Main then
            Tab = _G.Tabs.Main
            break
        end
        task.wait(0.2)
    end
    if not Tab then return end

    Tab:AddToggle("SilentAim", {
        Title   = "Silent Aim",
        Default = false,
    }):OnChanged(function(v)
        getgenv().Config.SilentAim = v
    end)

    Tab:AddToggle("ShowDot", {
        Title   = "Show Target Dot",
        Default = true,
    }):OnChanged(function(v)
        getgenv().Config.ShowDot = v
    end)

    Tab:AddToggle("FOVEnabled", {
        Title   = "FOV Circle",
        Default = true,
    }):OnChanged(function(v)
        getgenv().Config.FOVEnabled = v
    end)

    Tab:AddSlider("FOVRadius", {
        Title   = "FOV Radius",
        Min     = 50,
        Max     = 700,
        Default = 250,
    }):OnChanged(function(v)
        getgenv().Config.FOVRadius = v
    end)

    Tab:AddToggle("Prediction", {
        Title   = "Movement Prediction",
        Default = true,
    }):OnChanged(function(v)
        getgenv().Config.Prediction = v
    end)

    Tab:AddSlider("PredictTime", {
        Title   = "Prediction Strength",
        Min     = 0,
        Max     = 30,
        Default = 9,
    }):OnChanged(function(v)
        -- слайдер 0–30 → реальное значение 0.00–0.30
        getgenv().Config.PredictTime = v / 100
    end)

    Tab:AddToggle("ShowBtn", {
        Title   = "Show Shoot Button",
        Default = false,
    }):OnChanged(function(v)
        ShootBtn.Visible = v
    end)
end)

return true
