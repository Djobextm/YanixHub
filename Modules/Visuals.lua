local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("RunService")
local Tab = _G.Tabs.Visuals

-- Функция определения роли и цвета
local function GetPlayerRole(p)
    if not p.Character then return nil, nil end
    
    local isMur = p.Character:FindFirstChild("Knife") or p.Backpack:FindFirstChild("Knife")
    if isMur then return "Murderer", Color3.fromRGB(255, 0, 0) end -- Красный
    
    local isShr = p.Character:FindFirstChild("Gun") or p.Backpack:FindFirstChild("Gun")
    if isShr then return "Sheriff", Color3.fromRGB(0, 0, 255) end -- Синий
    
    local isHero = p.Character:FindFirstChild("Revolver") or p.Backpack:FindFirstChild("Revolver")
    if isHero then return "Hero", Color3.fromRGB(255, 255, 0) end -- Желтый
    
    return "Innocent", Color3.fromRGB(0, 255, 0) -- Зеленый
end

Tab:AddToggle("PESP", {Title = "ESP игроков (Роли)", Default = false}):OnChanged(function(v) 
    _G.Config.ESP = v 
end)

Tab:AddToggle("GESP", {Title = "Gun ESP (Упавший пистолет)", Default = false}):OnChanged(function(v) 
    _G.Config.GunESP = v 
end)

RS.Heartbeat:Connect(function()
    -- ESP ИГРОКОВ
    if _G.Config.ESP then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local roleName, roleColor = GetPlayerRole(p)
                
                -- Подсветка (Highlight)
                local h = p.Character:FindFirstChild("ESP_H") or Instance.new("Highlight", p.Character)
                h.Name = "ESP_H"
                h.FillColor = roleColor
                h.FillTransparency = 0.5
                h.OutlineColor = Color3.new(1,1,1)
                
                -- Надпись над головой (BillboardGui)
                local tag = p.Character.Head:FindFirstChild("ESP_Tag") or Instance.new("BillboardGui", p.Character.Head)
                if not tag:FindFirstChild("TextLabel") then
                    tag.Name = "ESP_Tag"
                    tag.AlwaysOnTop = true
                    tag.Size = UDim2.new(0, 100, 0, 50)
                    tag.ExtentsOffset = Vector3.new(0, 3, 0)
                    local l = Instance.new("TextLabel", tag)
                    l.BackgroundTransparency = 1
                    l.Size = UDim2.new(1, 0, 1, 0)
                    l.Font = Enum.Font.SourceSansBold
                    l.TextSize = 14
                    l.TextStrokeTransparency = 0
                end
                
                local label = tag.TextLabel
                label.Text = string.format("[%s]\n%s", roleName, p.Name)
                label.TextColor3 = roleColor
            end
        end
    else
        -- Очистка при выключении
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character then
                if p.Character:FindFirstChild("ESP_H") then p.Character.ESP_H:Destroy() end
                if p.Character.Head:FindFirstChild("ESP_Tag") then p.Character.Head.ESP_Tag:Destroy() end
            end
        end
    end
    
    -- GUN ESP (Упавший пистолет)
    if _G.Config.GunESP then
        local gun = workspace:FindFirstChild("GunDrop")
        if gun and not gun:FindFirstChild("GunUI") then
            local box = Instance.new("SelectionBox", gun)
            box.Name = "GunUI"
            box.Adornee = gun
            box.Color3 = Color3.new(0, 1, 1)
            box.LineThickness = 0.05
            
            local bill = Instance.new("BillboardGui", gun)
            bill.AlwaysOnTop = true
            bill.Size = UDim2.new(0, 100, 0, 50)
            bill.ExtentsOffset = Vector3.new(0, 1, 0)
            
            local lab = Instance.new("TextLabel", bill)
            lab.BackgroundTransparency = 1
            lab.Size = UDim2.new(1, 0, 1, 0)
            lab.Text = "DROPPED GUN"
            lab.TextColor3 = Color3.new(0, 1, 1)
            lab.Font = Enum.Font.SourceSansBold
            lab.TextSize = 16
            lab.TextStrokeTransparency = 0
        end
    end
end)

return true
