local ffi = require("ffi")

-- Must be defined outside
-- require("Particle")

---@class ParticleChunk
---@field bytecode love.ByteData
---@field matrix Particle*
---@field width number
---@field height number
---@field clock boolean
---@field currentX number
---@field currentY number
---@field updateData table

local ParticleChunk = {}
ParticleChunk.__index = ParticleChunk

local empty_particle_id = 1
local start_index = 0
local end_index = 1

function ParticleChunk:new(chunkData, updateData)
    local instance = {
        matrix = ffi.cast("Particle*", chunkData.bytecode:getFFIPointer()),
        width = chunkData.width,
        height = chunkData.height,
        clock = false,
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
    local funcs = ParticleDefinitionsHandler.funcs

    for y = self.updateData.yStart, self.updateData.yEnd, self.updateData.increment do
        for x = self.updateData.xStart, self.updateData.xEnd, self.updateData.increment do
            local index = self:index(x, y)
            if self.matrix[index].clock ~= self.clock then
                -- print("Current update on: " .. x .. ", " .. y .. " with type: " .. self.matrix[index].type)
                self.matrix[index].clock = not self.clock
            else
                self.currentX = x
                self.currentY = y

                self.matrix[index].clock = not self.clock
                funcs[self.matrix[index].type](self)
            end
        end
    end
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
    return self:isInside(rx, ry) and self.matrix[self:index(x, y)].type == empty_particle_id
end

function ParticleChunk:getParticleType(rx, ry)
    local x = rx + self.currentX
    local y = ry + self.currentY
    return self.matrix[self:index(x, y)].type
end

return ParticleChunk
