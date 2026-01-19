local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RunService = game:GetService("RunService")

local Tab = _G.Tabs.Visuals
local ESP_Objects = {} -- Таблица для хранения созданных объектов

-- Параметры оптимизации
local UpdateRate = 0.1 -- Обновлять раз в 0.1 сек, а не каждый кадр
local MaxDistance = 500 -- Не рисовать ESP дальше 500 стадов
local lastUpdate = 0

-- Очистка при выключении
local function ClearESP()
    for _, obj in pairs(ESP_Objects) do
        if obj then obj:Destroy() end
    end
    ESP_Objects = {}
end

Tab:AddToggle("PESP", {Title = "Player ESP (Optimized)", Default = false}):OnChanged(function(v) 
    _G.Config.ESP = v 
    if not v then ClearESP() end
end)

Tab:AddToggle("GESP", {Title = "Gun ESP", Default = false}):OnChanged(function(v) 
    _G.Config.GunESP = v 
    if not v then ClearESP() end
end)

-- Основной цикл с ограничением FPS
RunService.Heartbeat:Connect(function()
    if tick() - lastUpdate < UpdateRate then return end
    lastUpdate = tick()

    if _G.Config.ESP then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local char = p.Character
                local root = char.HumanoidRootPart
                local dist = (LP.Character.HumanoidRootPart.Position - root.Position).Magnitude

                -- Рисуем только если игрок близко
                if dist < MaxDistance then
                    local isMur = char:FindFirstChild("Knife") or p.Backpack:FindFirstChild("Knife")
                    local isShr = char:FindFirstChild("Gun") or p.Backpack:FindFirstChild("Gun")
                    local color = isMur and Color3.new(1,0,0) or isShr and Color3.new(0,0,1) or Color3.new(0,1,0)

                    -- Используем Highlight (он менее затратный, чем Box ESP)
                    local h = char:FindFirstChild("ESP_H") or Instance.new("Highlight", char)
                    h.Name = "ESP_H"
                    h.FillColor = color
                    h.FillTransparency = 0.6
                    h.OutlineTransparency = 0
                    
                    -- Храним для очистки
                    ESP_Objects[p.Name] = h
                else
                    if char:FindFirstChild("ESP_H") then char.ESP_H:Destroy() end
                end
            end
        end
    end

    -- Оптимизированный Gun ESP
    if _G.Config.GunESP then
        local gun = workspace:FindFirstChild("GunDrop", true)
        if gun and gun:IsA("BasePart") then
            local h = gun:FindFirstChild("G_H") or Instance.new("Highlight", gun)
            h.Name = "G_H"
            h.FillColor = Color3.new(0, 1, 1)
            ESP_Objects["GunDrop"] = h
        end
    end
end)

return true
