local LP = game:GetService("Players").LocalPlayer
local RS = game:GetService("RunService")

_G.Tabs.Farm:AddToggle("AFarm", {Title = "Smooth Auto-Farm (Fly)", Default = false}):OnChanged(function(v) _G.Config.AutoFarm = v end)

RS.Stepped:Connect(function()
    if _G.Config.AutoFarm and LP.Character then
        -- NoClip: отключаем коллизии, чтобы лететь через стены
        for _, part in pairs(LP.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

task.spawn(function()
    while task.wait() do
        if _G.Config.AutoFarm and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            local c = workspace:FindFirstChild("CoinContainer", true)
            local coin = c and c:FindFirstChildWhichIsA("Part", true)
            
            if coin then
                local root = LP.Character.HumanoidRootPart
                -- Плавное движение (Lerp) вместо телепорта
                root.CFrame = root.CFrame:Lerp(coin.CFrame, 0.15)
                root.Velocity = Vector3.new(0,0,0)
            end
        end
    end
end)
