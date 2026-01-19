local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Tab = _G.Tabs.Visuals

-- Цвета ролей
local function GetRoleColor(p)
    if not p or not p.Character then return Color3.fromRGB(0, 255, 0) end
    local char = p.Character
    local backpack = p:FindFirstChild("Backpack")
    
    if char:FindFirstChild("Knife") or (backpack and backpack:FindFirstChild("Knife")) then
        return Color3.fromRGB(255, 0, 0) -- Мардер
    elseif char:FindFirstChild("Gun") or (backpack and backpack:FindFirstChild("Gun")) then
        return Color3.fromRGB(0, 0, 255) -- Шериф
    elseif char:FindFirstChild("Revolver") or (backpack and backpack:FindFirstChild("Revolver")) then
        return Color3.fromRGB(255, 255, 0) -- Герой
    end
    return Color3.fromRGB(0, 255, 0) -- Невинный
end

-- Универсальная функция текста
local function CreateTag(parent, text, color)
    if parent:FindFirstChild("YnxTag") then parent.YnxTag:Destroy() end
    local bgu = Instance.new("BillboardGui", parent)
    bgu.Name = "YnxTag"
    bgu.Size = UDim2.new(0, 200, 0, 50)
    bgu.StudsOffset = Vector3.new(0, 2, 0)
    bgu.AlwaysOnTop = true
    local lbl = Instance.new("TextLabel", bgu)
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.Text = text
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 14
    lbl.TextColor3 = color
    lbl.TextStrokeTransparency = 0
    return bgu
end

-- ФУНКЦИЯ ОПРЕДЕЛЕНИЯ ТЕКУЩЕЙ КАРТЫ И ПОИСКА ПУШКИ
local function FindGunInCurrentMap()
    local currentMap = nil
    
    -- В MM2 активная карта — это модель в workspace, у которой есть CoinContainer или Spawns
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("Model") and (obj:FindFirstChild("CoinContainer") or obj:FindFirstChild("Spawns")) then
            currentMap = obj
            break
        end
    end
    
    if currentMap then
        return currentMap:FindFirstChild("GunDrop")
    end
    
    -- Запасной вариант, если карта называется специфически
    return workspace:FindFirstChild("GunDrop") 
end

RunService.RenderStepped:Connect(function()
    -- 1. Player ESP
    if _G.Config.ESP then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and p.Character:FindFirstChild("Head") then
                local char = p.Character
                local highlight = char:FindFirstChild("YnxHighlight") or Instance.new("Highlight", char)
                highlight.Name = "YnxHighlight"
                highlight.Enabled = true
                highlight.FillColor = GetRoleColor(p)
                highlight.OutlineColor = highlight.FillColor
                
                local tag = char.Head:FindFirstChild("YnxTag") or CreateTag(char.Head, p.Name, highlight.FillColor)
                tag.Enabled = true
                tag.TextLabel.TextColor3 = highlight.FillColor
            end
        end
    end

    -- 2. Gun ESP (Поиск строго в текущей карте)
    if _G.Config.GunESP then
        local gun = FindGunInCurrentMap()
        if gun and gun:IsA("BasePart") then
            local gHighlight = gun:FindFirstChild("YnxGunHighlight") or Instance.new("Highlight", gun)
            gHighlight.Name = "YnxGunHighlight"
            gHighlight.Enabled = true
            gHighlight.FillColor = Color3.fromRGB(255, 255, 255)
            
            local gTag = gun:FindFirstChild("YnxTag") or CreateTag(gun, "★ FALLING GUN ★", Color3.fromRGB(255, 255, 255))
            gTag.Enabled = true
        end
    end
end)

-- ОЧИСТКА ПРИ ВЫКЛЮЧЕНИИ
Tab:AddToggle("ESP", {Title = "Player ESP + Names", Default = false}):OnChanged(function(v) 
    _G.Config.ESP = v 
    if not v then
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character then
                local h = p.Character:FindFirstChild("YnxHighlight")
                if h then h:Destroy() end
                if p.Character:FindFirstChild("Head") and p.Character.Head:FindFirstChild("YnxTag") then
                    p.Character.Head.YnxTag:Destroy()
                end
            end
        end
    end
end)

Tab:AddToggle("GunESP", {Title = "Dropped Gun ESP", Default = false}):OnChanged(function(v) 
    _G.Config.GunESP = v 
    if not v then
        -- Ищем и удаляем везде, где может быть
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name == "YnxGunHighlight" or (obj.Name == "YnxTag" and obj.Parent.Name == "GunDrop") then
                obj:Destroy()
            end
        end
    end
end)

return true
