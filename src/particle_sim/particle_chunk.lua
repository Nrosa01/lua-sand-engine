local ffi = require("ffi")
require("Particle")

---@class ParticleChunk
---@field bytecode love.ByteData
---@field matrix Particle*
---@field width number
---@field height number
---@field clock boolean
---@field quad Quad

local ParticleChunk = {}
ParticleChunk.__index = ParticleChunk

local empty_particle_id = 1
local start_index = 0
local end_index = 1

function ParticleChunk:new(bytecode, width, height, quad)
    local instance = {
        bytecode = bytecode,
        matrix = nil,
        width = width,
        height = height,
        clock = false,
        quad = quad
    }

    instance.matrix = ffi.cast("Particle*", instance.bytecode:getPointer())

    setmetatable(instance, self)
    return instance
end

function ParticleChunk:index(x, y)
    return x + y * self.width
end

function ParticleChunk:reset()
    -- set all matrix data to 0
    local width = self.width
    local height = self.height

    for y = start_index, width - end_index do
        for x = start_index, height - end_index do
            self.matrix[self:index(x, y)].type = Particle(empty_particle_id)
        end
    end
end

function ParticleChunk:updateParticle(x, y)
    local data = ParticleDefinitionsHandler:getParticleData(self:getParticleType(x, y))

    -- data.interactions is a code string, so we need to load it
    -- local interactions = load(data.interactions)

    -- if interactions then
    --     interactions(x, y, self)
    -- end

    data.interactions(x, y, self)
end

-- Resto de métodos y propiedades de ParticleChunk

function ParticleChunk:update()
    for y = start_index, self.width - end_index do
        for x = start_index, self.height - end_index do
            self:updateParticle(x, y)
        end
    end

    self.clock = not self.clock
end

function ParticleChunk:setNewParticleById(x, y, id)
    if x >= start_index and x <= self.width - end_index and y >= start_index and y <= self.height - end_index then
        self.matrix[self:index(x, y)].type = id
        self.matrix[self:index(x, y)].clock = false

        local color = ParticleDefinitionsHandler:getParticleData(id).color
        self.quad:setPixel(x, y, color.r, color.g, color.b, color.a)
    end
end

function ParticleChunk:setParticle(x, y, particle)
    if x >= start_index and x <= self.width - end_index and y >= start_index and y <= self.height - end_index then
        self.matrix[self:index(x, y)].type = particle.type
        self.matrix[self:index(x, y)].clock = particle.clock

        local color = ParticleDefinitionsHandler:getParticleData(particle.type).color
        self.quad:setPixel(x, y, color.r, color.g, color.b, color.a)
    end
end

function ParticleChunk:tryPushParticle(x, y, dir_x, dir_y)
    local new_x, new_y = x + dir_x, y + dir_y

    if self:isInside(new_x, new_y) and self:canPush(new_x, new_y, x, y) then
        local aux = self.matrix[self:index(new_x, new_y)]
        local auxParticle = Particle(aux.type, aux.clock)
        self:setParticle(new_x, new_y, self.matrix[self:index(x, y)])
        self:setNewParticleById(x, y, empty_particle_id)

        for i = -5, 5 - 1 do
            for j = -1, 20 - 1 do
                if self:isInside(new_x + i, new_y - j) and self:isEmpty(new_x + i, new_y - j) then
                    self:setParticle(new_x + i, new_y - j, auxParticle)
                    return true
                end
            end
        end
        return true
    else
        return false
    end
end

function ParticleChunk:moveParticle(x, y, dir_x, dir_y)
    local new_x, new_y = x + dir_x, y + dir_y

    if self:isInside(new_x, new_y) and self:isEmpty(new_x, new_y) then
        self:setParticle(new_x, new_y, self.matrix[self:index(x, y)])
        self:setNewParticleById(x, y, empty_particle_id)
        return true
    else
        return false
    end
end

-- Define getwitdth function with different notation using self as parameter

function ParticleChunk:getWidth()
    return self.width
end

function ParticleChunk:getHeight()
    return self.height
end

function ParticleChunk:getParticle(x, y)
    return self.matrix[self:index(x, y)]
end

function ParticleChunk:isInside(x, y)
    return x >= start_index and x <= self.width - end_index and y >= start_index and y <= self.height - end_index
end

function ParticleChunk:isEmpty(x, y)
    return self.matrix[self:index(x, y)].type == empty_particle_id
end

function ParticleChunk:canPush(other_x, other_y, x, y)
    return ParticleDefinitionsHandler:getParticleData(self:getParticleType(other_x, other_y)).properties.density <
    ParticleDefinitionsHandler:getParticleData(self:getParticleType(x, y)).properties.density
end

function ParticleChunk:getParticleType(x, y)
    return self.matrix[self:index(x, y)].type
end

return ParticleChunk
