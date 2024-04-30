-- init.lua
print("Loading Lua scripts...")
-- init.lua
require("particle_definition_handler")

print("Adding particle to registry")

addParticle(
    "Empty",                           -- Text id
    { r = 0, g = 0, b = 0, a = 0 }     -- Color
)

addParticle(
    "Sand",                                   -- Text id
    { r = 255, g = 255, b = 0, a = 255 },     -- Color
    function(api)
        local dirY = -1
        local dirX = math.random(-1, 1) -- Extra part
        local mask = { ParticleType.EMPTY, ParticleType.WATER }

        if api:check_neighbour_multi(0, dirY, mask) then
            api:swap(0, dirY)
        elseif api:check_neighbour_multi(dirX, dirY, mask) then
            api:swap(dirX, dirY)
        elseif api:check_neighbour_multi(-dirX, dirY, mask) then
            api:swap(-dirX, dirY)
        end
    end
)

addParticle(
    "Water",                                   -- Text id
    { r = 39, g = 221, b = 245, a = 255 },     -- Color
    function(api)
        local dirY = -1
        local dirX = math.random(-1, -1)
        if api:isEmpty(0, dirY) then
            api:swap(0, dirY)
        elseif api:isEmpty(dirX, dirY) then
            api:swap(dirX, 1)
        elseif api:isEmpty(-dirX, dirY) then
            api:swap(-dirX, dirY)
        elseif api:isEmpty(dirX, 0) then
            api:swap(dirX, 0)
        elseif api:isEmpty(-dirX, 0) then
            api:swap(-dirX, 0)
        end
    end
)

addParticle(
    "Steam",                                    -- Text id
    { r = 200, g = 200, b = 200, a = 255 },     -- Color
    function(api)
        local dirY = 1
        local dirX = math.random(-1, 1) -- Extra part
        local mask = { ParticleType.EMPTY, ParticleType.WATER }

        if api:check_neighbour_multi(0, dirY, mask) then
            api:swap(0, dirY)
        elseif api:check_neighbour_multi(dirX, dirY, mask) then
            api:swap(dirX, dirY)
        elseif api:check_neighbour_multi(-dirX, dirY, mask) then
            api:swap(-dirX, dirY)
        end
    end
)

addParticle(
    "Lava",                                 -- Text id
    { r = 255, g = 0, b = 0, a = 255 },     -- Color
    function(api)
        local dirY = -1
        local dirX = math.random(-1, 1) -- Extra part

        if api:isEmpty(0, dirY) then
            api:swap(0, dirY)
        elseif api:isEmpty(dirX, dirY) then
            api:swap(dirX, dirY)
        elseif api:isEmpty(-dirX, dirY) then
            api:swap(-dirX, dirY)
        end

        for _, dir in ipairs(api:get_neighbours()) do
            if api:getParticleType(dir.x, dir.y) == ParticleType.WATER then
                api:setNewParticleById(dir.x, dir.y, ParticleType.STEAM)
            end
        end
    end
)