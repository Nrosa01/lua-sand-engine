local ffi = require("ffi")

-- Must be defined outside
-- require("Particle")

---@class ParticleChunk
---@field bytecode love.ByteData
---@field matrixes Particle*
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
        matrixes = {},
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
            self.currentX = x
            self.currentY = y

            funcs[self.matrixes.read[index].type](self)
        end
    end
end

function ParticleChunk:setNewParticleById(rx, ry, id)
    local x = rx + self.currentX
    local y = ry + self.currentY
    if x >= start_index and x <= self.width - end_index and y >= start_index and y <= self.height - end_index then
        self.matrixes.write[self:index(x, y)].type = id
    end
end

-- function ParticleChunk:setParticle(rx, ry, particle)
--     local x = rx + self.currentX
--     local y = ry + self.currentY
--     if x >= start_index and x <= self.width - end_index and y >= start_index and y <= self.height - end_index then
--         self.matrixes.write[self:index(x, y)].type = particle.type
--     end
-- end

function ParticleChunk:getWidth()
    return self.width
end

function ParticleChunk:getHeight()
    return self.height
end

function ParticleChunk:getParticle(rx, ry)
    local x = rx + self.currentX
    local y = ry + self.currentY
    return self.matrixes.read[self:index(x, y)]
end

function ParticleChunk:isInside(rx, ry)
    local x = rx + self.currentX
    local y = ry + self.currentY
    return x >= start_index and x <= self.width - end_index and y >= start_index and y <= self.height - end_index
end

function ParticleChunk:isEmpty(rx, ry)
    local x = rx + self.currentX
    local y = ry + self.currentY
    return self:isInside(rx, ry) and self.matrixes.read[self:index(x, y)].type == empty_particle_id
end

function ParticleChunk:getParticleType(rx, ry)
    local x = rx + self.currentX
    local y = ry + self.currentY
    return self.matrixes.read[self:index(x, y)].type
end

return ParticleChunk
