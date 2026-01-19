local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("RunService")
local Tab = _G.Tabs.Visuals

local CurrentMap = nil

-- Функция поиска текущей карты
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

-- Логика ролей
local function GetPlayerRole(p)
    if not p.Character then return nil, nil end
    
    local isMur = p.Character:FindFirstChild("Knife") or p.Backpack:FindFirstChild("Knife")
    if isMur then return "Murderer", Color3.fromRGB(255, 0, 0) end
    
    local isHero = p.Character:FindFirstChild("Revolver") or p.Backpack:FindFirstChild("Revolver")
    if isHero then return "Hero", Color3.fromRGB(255, 255, 0) end
    
    local isShr = p.Character:FindFirstChild("Gun") or p.Backpack:FindFirstChild("Gun")
    if isShr then return "Sheriff", Color3.fromRGB(0, 0, 255) end
    
    return "Innocent", Color3.fromRGB(0, 255, 0)
end

-- Функция удаления ESP (Очистка)
local function CleanupESP()
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character then
            local h = p.Character:FindFirstChild("ESP_H")
            if h then h:Destroy() end
            if p.Character:FindFirstChild("Head") then
                local t = p.Character.Head:FindFirstChild("ESP_Tag")
                if t then t:Destroy() end
            end
        end
    end
end

-- Функция удаления Gun ESP
local function CleanupGunESP()
    local map = GetMap()
    if map then
        local gun = map:FindFirstChild("GunDrop")
        if gun then
            local h = gun:FindFirstChild("GunUI_High")
            if h then h:Destroy() end
            local t = gun:FindFirstChild("GunTag")
            if t then t:Destroy() end
        end
    end
end

Tab:AddToggle("PESP", {Title = "ESP игроков", Default = false}):OnChanged(function(v) 
    _G.Config.ESP = v 
    if not v then CleanupESP() end
end)

Tab:AddToggle("GESP", {Title = "Gun ESP (Highlight)", Default = false}):OnChanged(function(v) 
    _G.Config.GunESP = v 
    if not v then CleanupGunESP() end
end)

RS.Heartbeat:Connect(function()
    -- ESP ИГРОКОВ
    if _G.Config.ESP then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Head") then
                local roleName, roleColor = GetPlayerRole(p)
                
                local h = p.Character:FindFirstChild("ESP_H") or Instance.new("Highlight", p.Character)
                h.Name = "ESP_H"
                h.FillColor = roleColor
                h.FillTransparency = 0.5
                h.OutlineColor = Color3.new(1, 1, 1)
                h.Enabled = true
                
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
                tag.Enabled = true
                tag.TextLabel.Text = string.format("[%s]\n%s", roleName, p.Name)
                tag.TextLabel.TextColor3 = roleColor
            end
        end
    end
    
    -- GUN ESP
    if _G.Config.GunESP then
        local map = GetMap()
        if map then
            local gun = map:FindFirstChild("GunDrop")
            if gun and gun:IsA("BasePart") then
                if not gun:FindFirstChild("GunUI_High") then
                    local high = Instance.new("Highlight", gun)
                    high.Name = "GunUI_High"
                    high.FillColor = Color3.fromRGB(0, 255, 255)
                    high.FillTransparency = 0.4
                    high.OutlineColor = Color3.new(1, 1, 1)
                    high.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    
                    local bill = Instance.new("BillboardGui", gun)
                    bill.Name = "GunTag"
                    bill.AlwaysOnTop = true
                    bill.Size = UDim2.new(0, 150, 0, 50)
                    bill.ExtentsOffset = Vector3.new(0, 1.5, 0)
                    local lab = Instance.new("TextLabel", bill)
                    lab.BackgroundTransparency = 1
                    lab.Size = UDim2.new(1, 0, 1, 0)
                    lab.Text = "★ FALLING GUN ★"
                    lab.TextColor3 = Color3.fromRGB(0, 255, 255)
                    lab.Font = Enum.Font.SourceSansBold
                    lab.TextSize = 18
                    lab.TextStrokeTransparency = 0
                else
                    gun.GunUI_High.Enabled = true
                    gun.GunTag.Enabled = true
                end
            end
        end
    end
end)

return true
