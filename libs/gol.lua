addParticle(
    "Alive Cell",
    { r = 255, g = 255, b = 255, a = 255 },
    function(api, ticks)
        if ticks % 3 ~= 0 then return end

        local neighbours = 0

        for _, dir in ipairs(api:get_neighbours()) do
            if api:getParticleType(dir.x, dir.y) == ParticleType.ALIVE_CELL then
                neighbours = neighbours + 1
            end
        end

        if neighbours < 2 or neighbours > 3 then
            api:setNewParticleById(0, 0, ParticleType.EMPTY)
        end
    end
)

addParticle(
    "Empty",
    { r = 0, g = 0, b = 0, a = 255 },
    function(api, ticks)
        if ticks % 3 ~= 0 then return end

        local neighbours = 0

        for _, dir in ipairs(api:get_neighbours()) do
            if api:getParticleType(dir.x, dir.y) == ParticleType.ALIVE_CELL then
                neighbours = neighbours + 1
            end
        end

        if neighbours == 3 then
            api:setNewParticleById(0, 0, ParticleType.ALIVE_CELL)
        end
    end
)

addParticle(
    "Blinker",
    { r = 255, g = 255, b = 255, a = 255 },
    function(api)
        api:setNewParticleById(0, 0, ParticleType.ALIVE_CELL)
        api:setNewParticleById(0, 1, ParticleType.ALIVE_CELL)
        api:setNewParticleById(0, -1, ParticleType.ALIVE_CELL)
    end
)

addParticle(
    "Glider",
    { r = 255, g = 255, b = 255, a = 255 },
    function(api)
        api:setNewParticleById(0, 0, ParticleType.ALIVE_CELL)
        api:setNewParticleById(1, 0, ParticleType.ALIVE_CELL)
        api:setNewParticleById(1, 1, ParticleType.ALIVE_CELL)
        api:setNewParticleById(0, -1, ParticleType.ALIVE_CELL)
        api:setNewParticleById(-1, 1, ParticleType.ALIVE_CELL)
    end
)
