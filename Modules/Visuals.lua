local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("RunService")
local Tab = _G.Tabs.Visuals

local CurrentMap = nil

-- Функция поиска текущей карты с автосбросом кеша
local function GetMap()
    if CurrentMap and not CurrentMap:IsDescendantOf(workspace) then
        CurrentMap = nil
    end
    if not CurrentMap then
        for _, v in pairs(workspace:GetChildren()) do
            if v:IsA("Model") and v:FindFirstChild("CoinContainer") then
                CurrentMap = v
                return v
            end
        end
    end
    return CurrentMap
end

-- ИСПРАВЛЕННАЯ логика ролей (Герой теперь приоритетнее Шерифа для невинных)
local function GetPlayerRole(p)
    if not p.Character then return nil, nil end
    
    -- 1. Мардер (Красный)
    local isMur = p.Character:FindFirstChild("Knife") or p.Backpack:FindFirstChild("Knife")
    if isMur then return "Murderer", Color3.fromRGB(255, 0, 0) end
    
    -- 2. ГЕРОЙ (Желтый) - проверяем, есть ли Револьвер (поднятый пистолет)
    local isHero = p.Character:FindFirstChild("Revolver") or p.Backpack:FindFirstChild("Revolver")
    if isHero then return "Hero", Color3.fromRGB(255, 255, 0) end
    
    -- 3. ШЕРИФ (Синий) - начальный шериф с Gun
    local isShr = p.Character:FindFirstChild("Gun") or p.Backpack:FindFirstChild("Gun")
    if isShr then return "Sheriff", Color3.fromRGB(0, 0, 255) end
    
    -- 4. Невинный (Зеленый)
    return "Innocent", Color3.fromRGB(0, 255, 0)
end

Tab:AddToggle("PESP", {Title = "ESP игроков", Default = false}):OnChanged(function(v) _G.Config.ESP = v end)
Tab:AddToggle("GESP", {Title = "Gun ESP (Highlight)", Default = false}):OnChanged(function(v) _G.Config.GunESP = v end)

RS.Heartbeat:Connect(function()
    -- ESP ИГРОКОВ
    if _G.Config.ESP then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local roleName, roleColor = GetPlayerRole(p)
                
                -- Highlight для игрока
                local h = p.Character:FindFirstChild("ESP_H") or Instance.new("Highlight", p.Character)
                h.Name = "ESP_H"
                h.FillColor = roleColor
                h.FillTransparency = 0.5
                h.OutlineColor = Color3.new(1, 1, 1)
                
                -- Текст над головой
                local tag = p.Character.Head:FindFirstChild("ESP_Tag") or Instance.new("BillboardGui", p.Character.Head)
                if not tag:FindFirstChild("TextLabel") then
                    tag.Name = "ESP_Tag"
                    tag.AlwaysOnTop = true
                    tag.Size = UDim2.new(0, 100, 0, 50)
                    tag.ExtentsOffset = Vector3.new(0, 3, 0)
                    local l = Instance.new("TextLabel", tag)
                    l.BackgroundTransparency = 1
                    l.Size = UDim2.new(1, 0, 1, 0)
                    l.Font = "SourceSansBold"
                    l.TextSize = 14
                    l.TextStrokeTransparency = 0
                end
                tag.TextLabel.Text = string.format("[%s]\n%s", roleName, p.Name)
                tag.TextLabel.TextColor3 = roleColor
            end
        end
    end
    
    -- GUN ESP (Highlight для GunDrop)
    if _G.Config.GunESP then
        local map = GetMap()
        if map then
            local gun = map:FindFirstChild("GunDrop")
            if gun then
                -- Привязываем визуал к модели пистолета
                if not gun:FindFirstChild("GunUI_High") then
                    -- HIGHLIGHT (Подсветка всей модели через стены)
                    local high = Instance.new("Highlight", gun)
                    high.Name = "GunUI_High"
                    high.FillColor = Color3.fromRGB(0, 255, 255)
                    high.FillTransparency = 0.4
                    high.OutlineColor = Color3.new(1, 1, 1)
                    high.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    
                    -- Надпись "FALLEN GUN"
                    local bill = Instance.new("BillboardGui", gun)
                    bill.Name = "GunTag"
                    bill.AlwaysOnTop = true
                    bill.Size = UDim2.new(0, 150, 0, 50)
                    bill.ExtentsOffset = Vector3.new(0, 1.5, 0)
                    local lab = Instance.new("TextLabel", bill)
                    lab.BackgroundTransparency = 1
                    lab.Size = UDim2.new(1, 0, 1, 0)
                    lab.Text = "★ FALLEN GUN ★"
                    lab.TextColor3 = Color3.fromRGB(0, 255, 255)
                    lab.Font = "SourceSansBold"
                    lab.TextSize = 18
                    lab.TextStrokeTransparency = 0
                end
            end
        end
    end
end)

return true
