local ffi = require("ffi")

-- Must be defined outside
-- require("Particle")

---@class ParticleChunk
---@field matrix Particle*
---@field width number
---@field height number
---@field clock boolean
---@field currentX number
---@field currentY number

local ParticleChunk = {}
ParticleChunk.__index = ParticleChunk

local start_index = 0
local end_index = 1

function ParticleChunk:new(width, height)
    local instance = {
        matrix = ffi.new("Particle[?]", width * height),
        width = width,
        height = height,
        clock = false,
        currentX = 0,
        currentY = 0,
    }

    for i = 0, width * height - 1 do
        instance.matrix[i].type = ParticleType.EMPTY
        instance.matrix[i].clock = false
    end

    setmetatable(instance, self)
    return instance
end

function ParticleChunk:index(x, y)
    return x + y * self.width
end

function ParticleChunk:update(updateData)
    local data = ParticleDefinitionsHandler.particle_data

    for y = updateData.yStart, updateData.yEnd, updateData.incrementY do
        for x = updateData.xStart, updateData.xEnd, updateData.incrementX do
            local index = self:index(x, y)

            if self.matrix[index].clock ~= self.clock then
                self.matrix[index].clock = not self.clock
            else
                self.currentX = x
                self.currentY = y

                self.matrix[index].clock = not self.clock
                data[self.matrix[index].type].func(self)
            end
        end
    end

    self.currentX = 0
    self.currentY = 0
    self.clock = not self.clock
end

-- Swaps particle in direction with current particle
function ParticleChunk:swap(rx, ry)
    local x = rx + self.currentX
    local y = ry + self.currentY

    local current_index = self:index(x, y)
    local swap_index = self:index(self.currentX, self.currentY)

    -- This doesn work because these are pointers
    -- local copy = self.matrix[index]
    -- self.matrix[index] = self.matrix[current_index]
    -- self.matrix[current_index] = copy

    local tempType = self.matrix[current_index].type
    local tempClock = self.matrix[current_index].clock
    self.matrix[current_index].type = self.matrix[swap_index].type
    self.matrix[current_index].clock = self.matrix[swap_index].clock
    self.matrix[swap_index].type = tempType
    self.matrix[swap_index].clock = tempClock
end

function ParticleChunk:setNewParticleById(rx, ry, id)
    local x = rx + self.currentX
    local y = ry + self.currentY
    if x >= start_index and x <= self.width - end_index and y >= start_index and y <= self.height - end_index then
        self.matrix[self:index(x, y)].type = id
    end
end

function ParticleChunk:setParticle(rx, ry, particle)
    local x = rx + self.currentX
    local y = ry + self.currentY
    if x >= start_index and x <= self.width - end_index and y >= start_index and y <= self.height - end_index then
        self.matrix[self:index(x, y)].type = particle.type
        self.matrix[self:index(x, y)].clock = particle.clock
    end
end

function ParticleChunk:getWidth()
    return self.width
end

function ParticleChunk:getHeight()
    return self.height
end

function ParticleChunk:getParticle(rx, ry)
    local x = rx + self.currentX
    local y = ry + self.currentY
    return self.matrix[self:index(x, y)]
end

function ParticleChunk:isInside(rx, ry)
    local x = rx + self.currentX
    local y = ry + self.currentY
    return x >= start_index and x <= self.width - end_index and y >= start_index and y <= self.height - end_index
end

function ParticleChunk:isEmpty(rx, ry)
    local x = rx + self.currentX
    local y = ry + self.currentY
    return self:isInside(rx, ry) and self.matrix[self:index(x, y)].type == ParticleType.EMPTY
end

function ParticleChunk:getParticleType(rx, ry)
    local x = rx + self.currentX
    local y = ry + self.currentY
    return self.matrix[self:index(x, y)].type
end

return ParticleChunk
