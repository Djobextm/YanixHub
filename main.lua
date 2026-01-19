-- [[ YanixHub | Main Loader ]]
local BaseURL = "https://raw.githubusercontent.com/Djobextm/YanixHub/main/" -- ЗАМЕНИ ТВОЙ_НИК

_G.Config = {
    Speed = 16, Jump = 50, SilentAim = false, 
    ESP = false, GunESP = false, AutoFarm = false, 
    AutoPickup = false, FarmWait = 0.1
}

local function LoadModule(name)
    local success, result = pcall(function()
        return loadstring(game:HttpGet(BaseURL .. "Modules/" .. name .. ".lua"))()
    end)
    if not success then warn("YanixHub: Ошибка загрузки модуля " .. name .. ": " .. result) end
    return result
end

-- Загрузка модулей
local Window = LoadModule("UI")
LoadModule("Visuals")
LoadModule("Combat")
LoadModule("Player")
LoadModule("Farm")

Window:SelectTab(1)
