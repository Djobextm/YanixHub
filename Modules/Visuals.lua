local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("RunService")
local Tab = _G.Tabs.Visuals

-- Переменная для хранения текущей папки карты
local CurrentMap = nil

-- Функция поиска текущей карты с проверкой на валидность
local function GetMap()
    -- Если карта была удалена (раунд окончен), сбрасываем кэш
    if CurrentMap and not CurrentMap:IsDescendantOf(workspace) then
        CurrentMap = nil
    end

    -- Если кэш пуст, ищем новую карту
    if not CurrentMap then
        for _, v in pairs(workspace:GetChildren()) do
            -- В MM2 папка активной карты всегда содержит CoinContainer
            if v:IsA("Model") and v:FindFirstChild("CoinContainer") then
                CurrentMap = v
                warn("YanixHub: Новая карта обнаружена, кэш обновлен.")
                return v
            end
        end
    end
    
    return CurrentMap
end

-- Функция определения роли
local function GetPlayerRole(p)
    if not p.Character then return nil, nil end
    local isMur = p.Character:FindFirstChild("Knife") or p.Backpack:FindFirstChild("Knife")
    if isMur then return "Murderer", Color3.fromRGB(255, 0, 0) end
    
    local isShr = p.Character:FindFirstChild("Gun") or p.Backpack:FindFirstChild("Gun")
    if isShr then return "Sheriff", Color3.fromRGB(0, 0, 255) end
    
    local isHero = p.Character:FindFirstChild("Revolver") or p.Backpack:FindFirstChild("Revolver")
    if isHero then return "Hero", Color3.fromRGB(255, 255, 0) end
    
    return "Innocent", Color3.fromRGB(0, 255, 0)
end

Tab:AddToggle("PESP", {Title = "ESP игроков", Default = false}):OnChanged(function(v) _G.Config.ESP = v end)
Tab:AddToggle("GESP", {Title = "Gun ESP (Dropped)", Default = false}):OnChanged(function(v) _G.Config.GunESP = v end)

RS.Heartbeat:Connect(function()
    -- ESP ИГРОКОВ
    if _G.Config.ESP then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local roleName, roleColor = GetPlayerRole(p)
                local h = p.Character:FindFirstChild("ESP_H") or Instance.new("Highlight", p.Character)
                h.Name = "ESP_H"; h.FillColor = roleColor; h.FillTransparency = 0.5
                
                local tag = p.Character.Head:FindFirstChild("ESP_Tag") or Instance.new("BillboardGui", p.Character.Head)
                if not tag:FindFirstChild("TextLabel") then
                    tag.Name = "ESP_Tag"; tag.AlwaysOnTop = true; tag.Size = UDim2.new(0, 100, 0, 50); tag.ExtentsOffset = Vector3.new(0, 3, 0)
                    local l = Instance.new("TextLabel", tag)
                    l.BackgroundTransparency = 1; l.Size = UDim2.new(1, 0, 1, 0); l.Font = "SourceSansBold"; l.TextSize = 14; l.TextStrokeTransparency = 0
                    l.Parent = tag
                end
                tag.TextLabel.Text = string.format("[%s]\n%s", roleName, p.Name)
                tag.TextLabel.TextColor3 = roleColor
            end
        end
    end
    
    -- GUN ESP (Поиск внутри папки карты с автосбросом)
    if _G.Config.GunESP then
        local map = GetMap() -- Эта функция сама сбросит кеш, если раунд кончился
        if map then
            local gun = map:FindFirstChild("GunDrop")
            if gun then
                local handle = gun:IsA("Model") and (gun:FindFirstChild("Handle") or gun:FindFirstChildWhichIsA("BasePart")) or gun
                if handle and not handle:FindFirstChild("GunUI") then
                    -- Обводка
                    local box = Instance.new("SelectionBox", handle)
                    box.Name = "GunUI"; box.Adornee = handle; box.Color3 = Color3.new(0, 1, 1)
                    box.LineThickness = 0.05; box.AlwaysOnTop = true
                    
                    -- Надпись
                    local bill = Instance.new("BillboardGui", handle)
                    bill.Name = "GunTag"; bill.AlwaysOnTop = true; bill.Size = UDim2.new(0, 150, 0, 50); bill.ExtentsOffset = Vector3.new(0, 1, 0)
                    local lab = Instance.new("TextLabel", bill)
                    lab.BackgroundTransparency = 1; lab.Size = UDim2.new(1, 0, 1, 0); lab.Text = "★ GUN DROPPED ★"; lab.TextColor3 = Color3.new(0, 1, 1); lab.Font = "SourceSansBold"; lab.TextSize = 18; lab.TextStrokeTransparency = 0
                    lab.Parent = bill
                end
            end
        end
    end
end)

return true
