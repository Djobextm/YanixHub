local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "🔥 YanixHub | Модульный 🔥",
    SubTitle = "by Yanix",
    TabWidth = 160, Size = UDim2.fromOffset(580, 460),
    Acrylic = false, Theme = "Dark"
})

-- Кнопка YanixHub
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
local Btn = Instance.new("TextButton", ScreenGui)
Btn.Size = UDim2.new(0, 80, 0, 30)
Btn.Position = UDim2.new(0.5, -40, 0, 15)
Btn.Text = "YanixHub"
Btn.Draggable = true

Btn.MouseButton1Click:Connect(function()
    pcall(function() Window:Minimize() end)
end)

_G.Tabs = {
    Main = Window:AddTab({ Title = "Бой", Icon = "sword" }),
    Visuals = Window:AddTab({ Title = "Визуалы", Icon = "eye" }),
    Player = Window:AddTab({ Title = "Игрок", Icon = "user" })
}

return Window

