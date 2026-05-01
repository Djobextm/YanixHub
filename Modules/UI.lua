local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/main/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/main/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "🔥 YanixHub | MM2 🔥",
    SubTitle = "Advanced Cheat Hub",
    TabWidth = 160, 
    Size = UDim2.fromOffset(680, 560),
    Acrylic = true, 
    Theme = "Dark",
    ShowRobloxVersion = true
})

-- Улучшенная кнопка сворачивания
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
ScreenGui.Name = "YanixHubToggle"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local Btn = Instance.new("TextButton", ScreenGui)
local UIStroke = Instance.new("UIStroke", Btn)
local UICorner = Instance.new("UICorner", Btn)
local UIGradient = Instance.new("UIGradient", Btn)

Btn.Size = UDim2.new(0, 100, 0, 35)
Btn.Position = UDim2.new(0.5, -50, 0, 20)
Btn.Text = "🔥 YanixHub"
Btn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
Btn.TextColor3 = Color3.new(1, 1, 1)
Btn.Font = Enum.Font.GothamBold
Btn.TextSize = 12
Btn.Draggable = true
Btn.Active = true
Btn.Selectable = true

UICorner.CornerRadius = UDim.new(0, 10)
UIStroke.Thickness = 2
UIStroke.Color = Color3.fromRGB(255, 60, 60)
UIGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 30, 30))
})
UIGradient.Rotation = 90

-- Анимация кнопки
local hoverConnection
hoverConnection = Btn.MouseEnter:Connect(function()
    Btn:TweenSize(UDim2.new(0, 120, 0, 35), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
    UIStroke.Thickness = 2.5
end)

Btn.MouseLeave:Connect(function()
    Btn:TweenSize(UDim2.new(0, 100, 0, 35), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
    UIStroke.Thickness = 2
end)

-- Анимация цвета кнопки
task.spawn(function()
    while ScreenGui and ScreenGui.Parent do
        local hue = (tick() % 5) / 5
        local color = Color3.fromHSV(hue, 0.8, 1)
        UIStroke.Color = color
        task.wait(0.05)
    end
end)

Btn.MouseButton1Click:Connect(function()
    if Window then pcall(function() Window:Minimize() end) end
end)

game:GetService("RunService").RenderStepped:Connect(function()
    pcall(function() 
        if Window then 
            Btn.Visible = Window.Minimized 
        end 
    end)
end)

-- Вкладки
_G.Tabs = {
    Main = Window:AddTab({ Title = "⚔️ Combat", Icon = "sword" }),
    Visuals = Window:AddTab({ Title = "👁️ Visuals", Icon = "eye" }),
    Player = Window:AddTab({ Title = "🧑 Player", Icon = "user" }),
    Farm = Window:AddTab({ Title = "💰 Farm", Icon = "coins" }),
    Misc = Window:AddTab({ Title = "🔧 Misc", Icon = "sliders" }),
    Settings = Window:AddTab({ Title = "⚙️ Settings", Icon = "settings" })
}

-- Settings Tab - Сохранение конфига
local SettingsTab = _G.Tabs.Settings

SettingsTab:AddSection("Управление конфигурацией")

SettingsTab:AddButton({
    Title = "Сохранить конфиг",
    Description = "Сохраняет все текущие настройки",
    Callback = function()
        SaveManager:SaveProject("YanixHub_Config")
        Fluent:Notify({
            Title = "✅ Успешно",
            Content = "Конфиг сохранен!",
            Duration = 3
        })
    end
})

SettingsTab:AddButton({
    Title = "Загрузить конфиг",
    Description = "Загружает сохраненные настройки",
    Callback = function()
        SaveManager:LoadProject("YanixHub_Config")
        Fluent:Notify({
            Title = "✅ Успешно",
            Content = "Конфиг загружен!",
            Duration = 3
        })
    end
})

SettingsTab:AddButton({
    Title = "Сбросить конфиг",
    Description = "Вернет настройки по умолчанию",
    Callback = function()
        SaveManager:ResetProject()
        Fluent:Notify({
            Title = "✅ Сброшено",
            Content = "Все настройки сброшены!",
            Duration = 3
        })
    end
})

SettingsTab:AddSection("Информация")

SettingsTab:AddParagraph({
    Title = "YanixHub v2.0",
    Content = "Advanced Cheat для Murder Mystery 2\n\n" ..
              "📌 Разработчик: NexaSquad\n" ..
              "🔗 GitHub: Djobextm/YanixHub\n" ..
              "⭐ Features: SilentAim, ESP, AutoFarm"
})

-- InterfaceManager для перемещения окна
InterfaceManager:SetLibrary(Fluent)
InterfaceManager:BuildInterfaceSection(SettingsTab)

SaveManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
SaveManager:BuildConfigSection(SettingsTab)

Window:SelectTab(1)

return Window
