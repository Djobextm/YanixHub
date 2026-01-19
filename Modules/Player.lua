local LP = game:GetService("Players").LocalPlayer
_G.Tabs.Player:AddSlider("WS", {Title = "Speed", Default = 16, Min = 16, Max = 100, Callback = function(v) _G.Config.Speed = v end})

game:GetService("RunService").Heartbeat:Connect(function()
    if LP.Character and LP.Character:FindFirstChild("Humanoid") then
        LP.Character.Humanoid.WalkSpeed = _G.Config.Speed
    end
end)
