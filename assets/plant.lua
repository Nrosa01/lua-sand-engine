addParticle({
    "Plant",                                 -- Text id
    { r = 0, g = 255, b = 0, a = 255 },     -- Color
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
                        api:setNewParticleById(dirX, dirY, ParticleType.PLANT)
                    end
                end
            end
        end
       
    end
})