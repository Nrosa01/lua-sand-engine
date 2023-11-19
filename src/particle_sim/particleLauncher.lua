-- init.lua
print("Loading Lua scripts...")
-- init.lua
require("ParticleDefinitionsHandler")
require("ParticleDefinition")

-- Función para agregar una partícula al registro
local function addParticleToRegistry()
    print("Adding particle to registry")
    local yellow = { r = 255, g = 255, b = 0, a = 255 } -- ejemplo de color amarillo en RGBA
    local blue = { r = 0, g = 0, b = 255, a = 255 } -- ejemplo de color azul en RGBA
    local emptyColor = { r = 0, g = 0, b = 0, a = 0 } -- ejemplo de color transparente en RGBA

    ParticleDefinitionsHandler:addParticleData(ParticleDefinition.new(
        "Empty", -- Text id
        emptyColor, -- Color
        0, -- Random granularity
        {}, -- Movement passes
        {
            density = 0,
            flammability = 0,
            explosiveness = 0,
            boilingPoint = 0,
            startingTemperature = 0
        }, -- Properties
        {} -- No interactions for now
    ))

    ParticleDefinitionsHandler:addParticleData(ParticleDefinition.new(
        "Sand", -- Text id
        yellow, -- Color
        30, -- Random granularity
        {
            { x = 0, y = 1 }, -- down
            { x = -1, y = 1 }, -- down_left
            { x = 1, y = 1 } -- down_right
        }, -- Movement passes
        {
            density = 1,
            flammability = 0,
            explosiveness = 0,
            boilingPoint = 0,
            startingTemperature = 0
        }, -- Properties
        {} -- No interactions for now
    ))

    ParticleDefinitionsHandler:addParticleData(ParticleDefinition.new(
        "Water", -- Text id
        blue, -- Color
        0, -- Random granularity
        {
            { x = 0, y = 1 }, -- down
            { x = -1, y = 1 }, -- down_left
            { x = 1, y = 1 }, -- down_right
            { x = -1, y = 0 }, -- left
            { x = 1, y = 0 }, -- right
        }, -- Movement passes
        {
            density = 0,
            flammability = 0,
            explosiveness = 0,
            boilingPoint = 0,
            startingTemperature = 0
        }, -- Properties
        {} -- No interactions for now
    ))
end

-- Llamada a la función para agregar una partícula al registro
addParticleToRegistry()