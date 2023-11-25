local ffi = require("ffi")
require("Particle")

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

local start_index = 0
local end_index = 1

function ParticleChunk:new(chunkData)
	local instance = {
		read_matrix = {},
		write_matrix = {},
		width = chunkData.width,
		height = chunkData.height,
		clock = false,
		currentX = 0,
		currentY = 0,
		currenType = 1,
		currentIndex = 0,
		updateData = {}
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
			self.currentX = x
			self.currentY = y
			self.currentIndex = self:index(x, y)
			self.currentType = self.read_matrix[self.currentIndex].type

			funcs[self.currentType](self)
		end
	end
end

function ParticleChunk:setNewParticleById(rx, ry, id)
	local x = rx + self.currentX
	local y = ry + self.currentY
	if x >= start_index and x <= self.width - end_index and y >= start_index and y <= self.height - end_index then
		self.write_matrix[self:index(x, y)].type = id
	end
end

function ParticleChunk:swap(rx, ry)
	local new_x = rx + self.currentX
	local new_y = ry + self.currentY
	local new_index = self:index(new_x, new_y)

	local type_copy = self.read_matrix[new_index].type
	self.write_matrix[new_index].type = self.currentType
	self.write_matrix[self.currentIndex].type = type_copy
end

-- function ParticleChunk:setParticle(rx, ry, particle)
--     local x = rx + self.currentX
--     local y = ry + self.currentY
--     if x >= start_index and x <= self.width - end_index and y >= start_index and y <= self.height - end_index then
--         self.write_matrix[self:index(x, y)].type = particle.type
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
	return self.read_matrix[self:index(x, y)]
end

function ParticleChunk:isInside(rx, ry)
	local x = rx + self.currentX
	local y = ry + self.currentY
	return x >= start_index and x <= self.width - end_index and y >= start_index and y <= self.height - end_index
end

function ParticleChunk:isEmpty(rx, ry)
	local x = rx + self.currentX
	local y = ry + self.currentY
	return self:isInside(rx, ry) and self.read_matrix[self:index(x, y)].type == ParticleType.EMPTY
end

function ParticleChunk:getParticleType(rx, ry)
	if not self:isInside(rx, ry) then
        return -1
    end

	local x = rx + self.currentX
	local y = ry + self.currentY
	return self.read_matrix[self:index(x, y)].type
end

return ParticleChunk
