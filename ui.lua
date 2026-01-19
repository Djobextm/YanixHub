-- Замени 'ТВОЙ_НИК' на свой логин GitHub
local BaseURL = "https://raw.githubusercontent.com/Djobextm/YanixHub/main/"

local function LoadModule(name)
    return loadstring(game:HttpGet(BaseURL .. "Modules/" .. name .. ".lua"))()
end

-- Загружаем конфигурацию
_G.Config = {
    ESP = false, GunESP = false, SilentAim = false,
    Speed = 16, AutoFarm = false
}

-- Загружаем модули по очереди
local Window = LoadModule("UI")
LoadModule("Visuals")
LoadModule("Combat")
LoadModule("Player")

Window:SelectTab(1)

