local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("RunService")
local Tab = _G.Tabs.Visuals

Tab:AddToggle("PESP", {Title = "Player ESP", Default = false}):OnChanged(function(v) _G.Config.ESP = v end)
Tab:AddToggle("GESP", {Title = "Gun ESP (Lightweight)", Default = false}):OnChanged(function(v) _G.Config.GunESP = v end)

RS.Heartbeat:Connect(function()
    if _G.Config.ESP then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local h = p.Character:FindFirstChild("ESP_H") or Instance.new("Highlight", p.Character)
                h.Name = "ESP_H"; h.FillTransparency = 0.5
                local isMur = p.Character:FindFirstChild("Knife") or p.Backpack:FindFirstChild("Knife")
                h.FillColor = isMur and Color3.new(1,0,0) or Color3.new(0,1,0)
            end
        end
    end
    
    if _G.Config.GunESP then
        local gun = workspace:FindFirstChild("GunDrop")
        if gun and not gun:FindFirstChild("GunUI") then
            local box = Instance.new("SelectionBox", gun)
            box.Name = "GunUI"; box.Adornee = gun; box.Color3 = Color3.new(0,1,1); box.LineThickness = 0.05
            local bill = Instance.new("BillboardGui", gun)
            bill.AlwaysOnTop = true; bill.Size = UDim2.new(0,100,0,50); bill.ExtentsOffset = Vector3.new(0,1,0)
            local lab = Instance.new("TextLabel", bill)
            lab.BackgroundTransparency = 1; lab.Size = UDim2.new(1,0,1,0); lab.Text = "DROPPED GUN"; lab.TextColor3 = Color3.new(0,1,1); lab.Font = "SourceSansBold"
        end
    end
end)
