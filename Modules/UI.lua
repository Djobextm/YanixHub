local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "🔥 YanixHub | MM2 🔥",
    SubTitle = "by Yanix",
    TabWidth = 160, Size = UDim2.fromOffset(580, 460),
    Acrylic = false, Theme = "Dark"
})

-- Исправленная кнопка (БЕЗ ОШИБОК NIL)
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
local Btn = Instance.new("TextButton", ScreenGui)
local UIStroke = Instance.new("UIStroke", Btn)
local UICorner = Instance.new("UICorner", Btn)

Btn.Size = UDim2.new(0, 80, 0, 30)
Btn.Position = UDim2.new(0.5, -40, 0, 15)
Btn.Text = "YanixHub"
Btn.BackgroundColor3 = Color3.fromRGB(30,30,30)
Btn.TextColor3 = Color3.new(1,1,1)
Btn.Draggable = true
UICorner.CornerRadius = UDim.new(0, 8)
UIStroke.Thickness = 2

task.spawn(function()
    while true do
        UIStroke.Color = Color3.fromHSV(tick() % 5 / 5, 1, 1)
        task.wait()
    end
end)

Btn.MouseButton1Click:Connect(function()
    if Window then pcall(function() Window:Minimize() end) end
end)

game:GetService("RunService").RenderStepped:Connect(function()
    pcall(function() if Window then Btn.Visible = Window.Minimized end end)
end)

_G.Tabs = {
    Main = Window:AddTab({ Title = "Combat", Icon = "sword" }),
    Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" }),
    Player = Window:AddTab({ Title = "Player", Icon = "user" }),
    Farm = Window:AddTab({ Title = "Farm", Icon = "coins" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

return Window
