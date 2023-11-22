local ffi = require("ffi")
require("Particle")

---@class ParticleChunk
---@field bytecode love.ByteData
---@field matrix Particle*
---@field width number
---@field height number
---@field clock boolean
---@field quad Quad
---@field currentX number
---@field currentY number
---@field updateData table

local ParticleChunk = {}
ParticleChunk.__index = ParticleChunk

local empty_particle_id = 1
local start_index = 0
local end_index = 1

function ParticleChunk:new(chunkData, updateData, quad)
    local instance = {
        matrix = ffi.cast("Particle*", chunkData.bytecode:getFFIPointer()),
        width = chunkData.width,
        height = chunkData.height,
        clock = false,
        quad = quad,
        currentX = 0,
        currentY = 0,
        updateData = updateData
    }

    setmetatable(instance, self)
    return instance
end

function ParticleChunk:index(x, y)
    return x + y * self.width
end

function ParticleChunk:update()
    for y = self.updateData.yStart, self.updateData.yEnd do
        for x = self.updateData.xStart, self.updateData.xEnd do
            if self.matrix[self:index(x, y)].clock ~= self.clock then
                self.matrix[self:index(x, y)].clock = not self.clock
            else
                self.currentX = x
                self.currentY = y
                
                local data = ParticleDefinitionsHandler:getParticleData(self:getParticleType(x, y))
                data.interactions(x, y, self)
            end
        end
    end
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
