local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

_G.Tabs.Main:AddToggle("SAim", {Title = "Silent Aim (Redirect)", Default = false}):OnChanged(function(v) 
    _G.Config.SilentAim = v 
end)

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    if _G.Config.SilentAim and method == "FireServer" and (self.Name == "ShootGun" or self.Name == "Shoot") then
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character and (p.Character:FindFirstChild("Knife") or p.Backpack:FindFirstChild("Knife")) then
                args[1] = p.Character.HumanoidRootPart.Position
                return oldNamecall(self, unpack(args))
            end
        end
    end
    return oldNamecall(self, ...)
end)
