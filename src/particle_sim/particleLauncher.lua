-- init.lua
print("Loading Lua scripts...")
-- init.lua
require("ParticleDefinitionsHandler")
local ParticleDefinition = require("ParticleDefinition")

-- Función para agregar una partícula al registro
local function addParticleToRegistry()
    print("Adding particle to registry")
    local yellow = { r = 255, g = 255, b = 0, a = 255 }
    -- local blue = { r = 173, g = 216, b = 230, a = 255 }
    local emptyColor = { r = 0, g = 0, b = 0, a = 0 }
    -- local lavaColor = { r = 255, g = 0, b = 0, a = 255 }
    -- local stoneColor = { r = 128, g = 128, b = 128, a = 255 }

    addParticle(
        "Empty",   -- Text id
        emptyColor -- Color
    )

    addParticle(
        "Sand", -- Text id
        { r = 255, g = 255, b = 0, a = 255 }, -- Color
        function(api)
            local dirY = 1
            local dirX = math.random
            local below = api:getParticleType(0, dirY)
            if below == ParticleType.EMPTY or below == ParticleType.WATER then
                api:swap(0, dirY)
            elseif api:isEmpty(-1, dirY) and api:isEmpty(1, dirY) then
                api:swap(dirX, dirY)
            elseif api:isEmpty(-1, dirY) then
                api:swap(-1, dirY)
            elseif api:isEmpty(1, dirY) then
                api:swap(1, dirY)
            end
        end
    )

    addParticle(
        "Dust",                                  -- Text id
        { r = 128, g = 128, b = 128, a = 255 },  -- Color
        function(api)
            local dirY = 1
            local dirX = math.random(-1, 1)
            if api:isEmpty(dirX, dirY) then
                api:swap(dirX, dirY)
            end
        end
    )

    addParticle(
        "Steam",                                   -- Text id
        { r = 200, g = 200, b = 200, a = 255 },  -- Color
        function(api)
            local dirY = -1
            local dirX = math.random(-1, 1)
            if api:isEmpty(dirX, dirY) then
                api:swap(dirX, dirY)
            end
        end
    )

    addParticle(
        "Water",                               -- Text id
        { r = 39, g = 221, b = 245, a = 255 }, -- Color
        function(api)
            local dirX = -1
            if api:isEmpty(0, 1) then
                api:swap(0, 1)
            elseif api:isEmpty(dirX, 0) then
                api:swap(dirX, 0)
            elseif api:isEmpty(-dirX, 0) then
                api:swap(-dirX, 0)
            end
        end
    )

    addParticle(
        "Lava",                                 -- Text id
        { r = 255, g = 0, b = 0, a = 255 },     -- Color
        function(api)
            local dirX = math.random(-1, 1)
            if api:getParticleType(0, -1) == ParticleType.WATER or api:getParticleType(0, 1) == ParticleType.WATER then
                api:setNewParticleById(0, 0, ParticleType.STONE)
            elseif api:isEmpty(0, 1) then
                api:swap(0, 1)
            elseif api:isEmpty(dirX, 0) then
                api:swap(dirX, 0)
            elseif api:isEmpty(-dirX, 0) then
                api:swap(-dirX, 0)
            end
        end
    )
    
    addParticle(
        "Stone",                               -- Text id
        { r = 128, g = 128, b = 178, a = 255 } -- Color
    )
end

-- Llamada a la función para agregar una partícula al registro
addParticleToRegistry()
