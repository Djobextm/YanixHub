local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

-- Добавляем вкладку в глобальную таблицу Tabs
_G.Tabs.Farm = _G.Tabs.Farm or nil -- На случай, если вкладка еще не создана

-- Создаем вкладку (если UI.lua еще не создал её)
if _G.Tabs.Farm == nil then
    -- Этот блок сработает, если в UI.lua ты еще не прописал Farm
end

-- ==========================================
-- ИНТЕРФЕЙС ВКЛАДКИ FARM
-- ==========================================

_G.Tabs.Farm:AddToggle("AFarm", {Title = "Авто-фарм монет", Default = false}):OnChanged(function(v) 
    _G.Config.AutoFarm = v 
end)

_G.Tabs.Farm:AddToggle("APickup", {Title = "Авто-подбор пистолета", Default = false}):OnChanged(function(v) 
    _G.Config.AutoPickup = v 
end)

_G.Tabs.Farm:AddSlider("FSlider", {
    Title = "Задержка фарма (сек)", 
    Default = 0.1, Min = 0, Max = 1, Rounding = 2,
    Callback = function(v) _G.Config.FarmWait = v end
})

-- ==========================================
-- ЛОГИКА РАБОТЫ
-- ==========================================

task.spawn(function()
    while task.wait(_G.Config.FarmWait or 0.1) do
        pcall(function()
            local char = LP.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local root = char.HumanoidRootPart

            -- 1. ЛОГИКА СБОРА МОНЕТ
            if _G.Config.AutoFarm then
                local container = workspace:FindFirstChild("CoinContainer", true)
                if container then
                    local coin = container:FindFirstChildWhichIsA("Part", true)
                    if coin then
                        -- Телепорт к монете
                        root.CFrame = coin.CFrame
                        root.Velocity = Vector3.zero
                    end
                end
            end

            -- 2. ЛОГИКА ПОДБОРА ПИСТОЛЕТА
            if _G.Config.AutoPickup then
                local gunDrop = workspace:FindFirstChild("GunDrop", true)
                if gunDrop and gunDrop:IsA("BasePart") then
                    -- Телепорт к пистолету
                    root.CFrame = gunDrop.CFrame
                end
            end
        end)
    end
end)

return true

