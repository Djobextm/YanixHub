local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

local RoleColors = {
    Murderer = Color3.fromRGB(255, 0, 0),
    Sheriff = Color3.fromRGB(0, 0, 255),
    Hero = Color3.fromRGB(255, 255, 0),
    Innocent = Color3.fromRGB(0, 255, 0),
    Gun = Color3.fromRGB(0, 255, 255)
}

-- Функции очистки (чтобы не было дублей и лагов)
local function CleanESP(char)
    if char:FindFirstChild("P_E") then char.P_E:Destroy() end
    if char:FindFirstChild("Head") and char.Head:FindFirstChild("P_T") then char.Head.P_T:Destroy() end
end

-- Основные функции визуалов
_G.Tabs.Visuals:AddToggle("PESP", {Title = "ESP Ролей + Ники", Default = false}):OnChanged(function(v) 
    _G.Config.ESP = v 
    if not v then
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character then CleanESP(p.Character) end
        end
    end
end)

_G.Tabs.Visuals:AddToggle("GESP", {Title = "Gun ESP (Подсветка пистолета)", Default = false}):OnChanged(function(v) 
    _G.Config.GunESP = v 
    if not v then
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name == "G_H" then obj:Destroy() end
        end
    end
end)

-- Вспомогательная функция определения роли
local function GetPlayerRole(p)
    if not p or not p.Character then return "Innocent" end
    if p.Character:FindFirstChild("Knife") or p.Backpack:FindFirstChild("Knife") then return "Murderer" end
    if p.Character:FindFirstChild("Gun") or p.Backpack:FindFirstChild("Gun") then return "Sheriff" end
    if p.Character:FindFirstChild("Revolver") or p.Backpack:FindFirstChild("Revolver") then return "Hero" end
    return "Innocent"
end

-- ГЛАВНЫЙ ЦИКЛ ОБНОВЛЕНИЯ
RunService.Heartbeat:Connect(function()
    -- 1. Player ESP + Ники
    if _G.Config.ESP then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("HumanoidRootPart") then
                local role = GetPlayerRole(p)
                local color = RoleColors[role]
                
                -- Подсветка тела (Highlight)
                local h = p.Character:FindFirstChild("P_E") or Instance.new("Highlight", p.Character)
                h.Name = "P_E"
                h.FillColor = color
                h.OutlineColor = Color3.new(1,1,1)
                h.FillTransparency = 0.5

                -- Ники над головой (BillboardGui)
                local head = p.Character.Head
                local tag = head:FindFirstChild("P_T") or Instance.new("BillboardGui", head)
                tag.Name = "P_T"
                tag.Size = UDim2.new(0, 100, 0, 50)
                tag.AlwaysOnTop = true
                tag.ExtentsOffset = Vector3.new(0, 3, 0)

                local label = tag:FindFirstChild("L") or Instance.new("TextLabel", tag)
                label.Name = "L"
                label.BackgroundTransparency = 1
                label.Size = UDim2.new(1, 0, 1, 0)
                label.Text = string.format("[%s]\n%s", role:upper(), p.Name)
                label.TextColor3 = color
                label.Font = Enum.Font.SourceSansBold
                label.TextSize = 14
                label.TextStrokeTransparency = 0 -- Обводка текста для читаемости
            end
        end
    end

    -- 2. Gun ESP (Поиск выпавшего пистолета)
    if _G.Config.GunESP then
        for _, v in pairs(workspace:GetDescendants()) do
            if (v.Name == "GunDrop" or v.Name == "Gun") and v:IsA("BasePart") then
                if not v:FindFirstChild("G_H") then
                    local h = Instance.new("Highlight", v)
                    h.Name = "G_H"
                    h.FillColor = RoleColors.Gun
                    h.OutlineColor = Color3.new(1,1,1)
                end
            end
        end
    end
end)

return true
