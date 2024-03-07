addParticle(
    "Plant",                            -- Text id
    { r = 0, g = 255, b = 0, a = 255 }, -- Color
    function(api)
        local dirY = 1
        local below = api:getParticleType(0, dirY)
        if below == ParticleType.EMPTY then
            if math.random(10) == 1 then
                api:setNewParticleById(0, 1, ParticleType.PLANT)
            end
        end

        local mask = { ParticleType.EMPTY, ParticleType.WATER }

        local tries = 6

        while tries > 0 do
            local dirX, dirY = math.random(-1, 1), math.random(-1, 1)
            if api:getParticleType(dirX, dirY) == ParticleType.WATER and math.random(5) == 1 then
                local randomDirX, randomDirY = math.random(-1, 1) + dirX, math.random(-1, 1) + dirY
                if api:check_neighbour_multi(randomDirX, randomDirY, mask) then
                    api:setNewParticleById(randomDirX, randomDirY, ParticleType.PLANT)
                    api:setNewParticleById(dirX, dirY, ParticleType.EMPTY)
                    break
                end
            end

            tries = tries - 1
        end
    end
)

addParticle(
    "Fire",                             -- Text id
    { r = 255, g = 0, b = 0, a = 255 }, -- Color
    function(api)
        -- Iterate over all directions
        local burnt = false

        for _, dir in ipairs(api:get_neighbours()) do
            if api:getParticleType(dir.x, dir.y) == ParticleType.WATER then
                api:setNewParticleById(dir.x, dir.y, ParticleType.STEAM)
            end

            if api:getParticleType(dir.x, dir.y) == ParticleType.PLANT then
                if math.random(2) == 1 then
                    api:setNewParticleById(dir.x, dir.y, ParticleType.FIRE)
                end
                burnt = true
            end
        end


        -- 20% chance to turn into smoke
        if math.random(5) == 1 and not burnt then
            api:setNewParticleById(0, 0, ParticleType.SMOKE)
        end
    end
)

addParticle(
    "Smoke",                                -- Text id
    { r = 100, g = 100, b = 100, a = 255 }, -- Color
    function(api)
        local dirY = -1
        local dirX = math.random(-1, 1)
        if api:isEmpty(dirX, dirY) then
            api:swap(dirX, dirY)
        else
            dirX = 0
            dirY = 0
        end

        -- Has 1 in 200 chance to turn into water or else dissapear
        if math.random(30) == 1 then
            api:setNewParticleById(dirX, dirY, ParticleType.EMPTY)
        end
    end
)