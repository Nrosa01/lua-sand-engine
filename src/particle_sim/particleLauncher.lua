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
        "Sand",                               -- Text id
        { r = 255, g = 255, b = 0, a = 255 }, -- Color
        function(api)
            local dirY = 1
            local dirX = math.random(-1, 1)
            local below = api:getParticleType(0, dirY)
            if below == ParticleType.EMPTY or below == ParticleType.WATER then
                api:swap(0, dirY)
            elseif api:isEmpty(dirX, dirY) then
                api:swap(dirX, dirY)
            elseif api:isEmpty(-dirX, dirY) then
                api:swap(-dirX, dirY)
            end
        end
    )

    addParticle(
        "Dust",                                 -- Text id
        { r = 128, g = 128, b = 128, a = 255 }, -- Color
        function(api)
            local dirY = 1
            local dirX = math.random(-1, 1)
            if api:isEmpty(dirX, dirY) then
                api:swap(dirX, dirY)
            end
        end
    )

    addParticle(
        "Steam",                                -- Text id
        { r = 200, g = 200, b = 200, a = 255 }, -- Color
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
            local dirX = math.random(-1, 1)
            if api:isEmpty(0, 1) then
                api:swap(0, 1)
            elseif api:isEmpty(dirX, 1) then
                api:swap(dirX, 1)
            elseif api:isEmpty(-dirX, 1) then
                api:swap(-dirX, 1)
            elseif api:isEmpty(dirX, 0) then
                api:swap(dirX, 0)
            elseif api:isEmpty(-dirX, 0) then
                api:swap(-dirX, 0)
            end
        end
    )

    addParticle(
        "Lava",                             -- Text id
        { r = 255, g = 0, b = 0, a = 255 }, -- Color
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

    local function getDirections()
        local directions = {}

        for dirX = -1, 1 do
            for dirY = -1, 1 do
                if dirX ~= 0 or dirY ~= 0 then
                    table.insert(directions, { x = dirX, y = dirY })
                end
            end
        end

        return directions
    end


    addParticle(
        "Plant",                        -- Text id
        { r = 0, g = 255, b = 0, a = 255 }, -- Color
        function(api)
            local dirY = 1
            local below = api:getParticleType(0, dirY)
            if below == ParticleType.EMPTY then
                if math.random(10) == 1 then
                    api:setNewParticleById(0, 1, ParticleType.PLANT)
                end
            end

            for dirX = -1, 1 do
                for dirY = -1, 1 do
                    if api:getParticleType(dirX, dirY) == ParticleType.WATER then
                        if math.random(5) == 1 then
                            -- Set new particle to plant in a random free direction
                            local directions = getDirections()
                            -- If chosen direction is not empty, remove it from the list
                            -- and try again
                            while #directions > 0 do
                                local index = math.random(#directions)
                                local dir = directions[index]
                                if api:isEmpty(dir.x, dir.y) then
                                    api:setNewParticleById(dir.x, dir.y, ParticleType.PLANT)
                                    break
                                else
                                    table.remove(directions, index)
                                end
                            end

                            api:setNewParticleById(dirX, dirY, ParticleType.EMPTY)
                        end
                    end
                end
            end
        end
    )

    addParticle(
        "Fire",                         -- Text id
        { r = 255, g = 0, b = 0, a = 255 }, -- Color
        function(api)
            -- Iterate over all directions
            for dirX = -1, 1 do
                for dirY = -1, 1 do
                    -- If the particle below is water, turn it into steam
                    if api:getParticleType(dirX, dirY) == ParticleType.WATER then
                        api:setNewParticleById(dirX, dirY, ParticleType.STEAM)
                    end

                    -- If the particle below is plant, turn it into fire
                    if api:getParticleType(dirX, dirY) == ParticleType.PLANT then
                        api:setNewParticleById(dirX, dirY, ParticleType.FIRE)
                    end
                end
            end

            -- 20% chance to turn into smoke
            if math.random(5) == 1 then
                api:setNewParticleById(0, 0, ParticleType.SMOKE)
            end
        end
    )

    addParticle(
        "Smoke",                            -- Text id
        { r = 100, g = 100, b = 100, a = 255 }, -- Color
        function(api)
            local dirY = -1
            local dirX = math.random(-1, 1)
            if api:isEmpty(dirX, dirY) then
                api:swap(dirX, dirY)
            end

            -- Has 1 in 200 chance to turn into water or else dissapear
            if math.random(20) == 1 then
                api:setNewParticleById(0, 0, ParticleType.EMPTY)
            end
        end
    )
end

-- Llamada a la función para agregar una partícula al registro
addParticleToRegistry()
