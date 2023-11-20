-- init.lua
print("Loading Lua scripts...")
-- init.lua
require("ParticleDefinitionsHandler")
local ParticleDefinition = require("ParticleDefinition")

-- Función para agregar una partícula al registro
local function addParticleToRegistry()
    print("Adding particle to registry")
    local yellow = { r = 255, g = 255, b = 0, a = 255 } -- ejemplo de color amarillo en RGBA
    local blue = { r = 0, g = 0, b = 255, a = 255 } -- ejemplo de color azul en RGBA
    local emptyColor = { r = 0, g = 0, b = 0, a = 0 } -- ejemplo de color transparente en RGBA
    local lavaColor = { r = 255, g = 0, b = 0, a = 255 } -- ejemplo de color rojo en RGBA
    local stoneColor = { r = 128, g = 128, b = 128, a = 255 } -- ejemplo de color gris en RGBA

    ParticleDefinitionsHandler:addParticleData(ParticleDefinition.new(
        "Empty", -- Text id
        emptyColor, -- Color
        0, -- Random granularity
        {}, -- Movement passes
        {} -- Properties
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
        } -- Properties
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
        {}, -- Properties
        {   
            function(posX, posY, dirX, dirY, collided, api)
                local newPosX = posX + dirX;
                local newPosY = posY + dirY;
                local lavaId = ParticleDefinitionsHandler:getParticleId("Lava");
                local stoneId = ParticleDefinitionsHandler:getParticleId("Stone");

                -- Look in the direction of movement
                if collided and api:isInside(newPosX, newPosY) and api:getParticleType(newPosX, newPosY) == lavaId then
                    api:setParticle(posX, posY, api:setNewParticleById(0));
                    api:setParticle(newPosX, newPosY, api:setNewParticleById(stoneId));
                    return false
                end

                -- Look below
                if api:isInside(posX, posY - 1) and api:getParticleType(posX, posY - 1) == lavaId then
                    api:setParticle(posX, posY, api:setNewParticleById(0));
                    api:setParticle(posX, posY - 1, api:setNewParticleById(stoneId));
                    return false
                end

                return true
            end          
        }
    ))

    ParticleDefinitionsHandler:addParticleData(ParticleDefinition.new(
        "Lava", -- Text id
        lavaColor, -- Color
        0, -- Random granularity
        {
            { x = 0, y = 1 }, -- down
            { x = -1, y = 1 }, -- down_left
            { x = 1, y = 1 }, -- down_right
            { x = -1, y = 0 }, -- left
            { x = 1, y = 0 }, -- right
        }, -- Movement passes
        {}, -- Properties
        {   
            function(posX, posY, dirX, dirY, collided, api)
                local newPosX = posX + dirX;
                local newPosY = posY + dirY;
                local waterId = ParticleDefinitionsHandler:getParticleId("Water");
                local stoneId = ParticleDefinitionsHandler:getParticleId("Stone");

                -- Look in the direction of movement
                if collided and api:isInside(newPosX, newPosY) and api:getParticleType(newPosX, newPosY) == waterId then
                    api:setParticle(posX, posY, api:setNewParticleById(0));
                    api:setParticle(newPosX, newPosY, api:setNewParticleById(stoneId));
                    return false
                end

                -- Look below
                if api:isInside(posX, posY - 1) and api:getParticleType(posX, posY - 1) == waterId then
                    api:setParticle(posX, posY, api:setNewParticleById(0));
                    api:setParticle(posX, posY - 1, api:setNewParticleById(stoneId));
                    return false
                end

                return true
            end          
        }
    ))

    ParticleDefinitionsHandler:addParticleData(ParticleDefinition.new(
        "Stone", -- Text id
        stoneColor, -- Color
        0, -- Random granularity
        {}, -- Movement passes
        {
            density = 20,
        } -- Properties
    ))
end

-- Llamada a la función para agregar una partícula al registro
addParticleToRegistry()