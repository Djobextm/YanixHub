_G.Tabs.Misc = _G.Tabs.Settings -- Можно использовать вкладку Settings или создать новую

_G.Tabs.Settings:AddButton({
    Title = "Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, game:GetService("Players").LocalPlayer)
    end
})

_G.Tabs.Settings:AddToggle("AntiAFK", {Title = "Anti-AFK", Default = true}):OnChanged(function(v)
    if v then
        local virtualUser = game:GetService("VirtualUser")
        game:GetService("Players").LocalPlayer.Idled:Connect(function()
            virtualUser:CaptureController()
            virtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

return true

