local ffi = require("ffi")
require("particle")

---@class ParticleChunk
---@field bytecode love.ByteData
---@field matrixes Particle*
---@field width number
---@field height number
---@field clock boolean
---@field currentX number
---@field currentY number
---@field updateData table
---@field randomized_neighbours table

local ParticleChunk = {}
ParticleChunk.__index = ParticleChunk

local start_index = 0
local end_index = 1

function ParticleChunk:new(width, height)
	local instance = {
		read_matrix = {},
		write_matrix = {},
		width = width,
		height = height,
		clock = false,
		currentX = 0,
		currentY = 0,
		currenType = 1,
		currentIndex = 0,
		updateData = {},
		randomized_neighbours = {},
		neighbours = self:create_neighbours()
	}

	setmetatable(instance, self)
	return instance
end

function ParticleChunk:index(x, y)
	return x + y * self.width
end

function ParticleChunk:create_neighbours()
	local directions = {}

	for dirX = -1, 1 do
		for dirY = -1, 1 do
			if dirX ~= 0 or dirY ~= 0 then
				table.insert(directions, { x = dirX, y = dirY })
			end
		end
	end

	return directions
end

function ParticleChunk:create_random_neighbours()
	-- Creates a table of neighbours in random order
	local directions = self:create_neighbours()

	-- Shuffle the directions table using Fisher-Yates algorithm
	local n = #directions
	for i = n, 2, -1 do
		local j = math.random(i)
		directions[i], directions[j] = directions[j], directions[i]
	end

	return directions
end

function ParticleChunk:get_neighbours()
	return self.neighbours
end

function ParticleChunk:get_randomized_neighbours()
	return self.randomized_neighbours
end

function ParticleChunk:update(simulation_tick)
	local funcs = ParticleDefinitionsHandler.funcs
	self.randomized_neighbours = self:create_random_neighbours()

	for y = self.updateData.yStart, self.updateData.yEnd, self.updateData.increment do
		for x = self.updateData.xStart, self.updateData.xEnd, self.updateData.increment do
			self.currentX = x
			self.currentY = y
			self.currentIndex = self:index(x, y)
			self.currentType = self.read_matrix[self.currentIndex].type

			if not self.write_matrix[self.currentIndex].clock then
				funcs[self.currentType](self, simulation_tick)
			end
		end
	end
end

-- Sets a particle at the given position if it hasn't been set yet this frame
function ParticleChunk:setNewParticleById(rx, ry, id)
	local x = rx + self.currentX
	local y = -ry + self.currentY

	if x >= start_index and x <= self.width - end_index and y >= start_index and y <= self.height - end_index then
		self.write_matrix[self:index(x, y)].type = id
		self.write_matrix[self:index(x, y)].clock = true
	end
end

function ParticleChunk:isParticleWritten(rx, ry)
	local x = rx + self.currentX
	local y = -ry + self.currentY
	return self.write_matrix[self:index(x, y)].clock
end

function ParticleChunk:swap(rx, ry)
	local new_x = rx + self.currentX
	local new_y = -ry + self.currentY
	local new_index = self:index(new_x, new_y)

	local type_copy = self.read_matrix[new_index].type
	self.write_matrix[new_index].type = self.currentType
	self.write_matrix[new_index].clock = true
	self.write_matrix[self.currentIndex].type = type_copy
	self.write_matrix[self.currentIndex].clock = true
	--self.write_matrix[self.currentIndex].clock = true
end

-- function ParticleChunk:setParticle(rx, ry, particle)
--     local x = rx + self.currentX
--     local y = -ry + self.currentY
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
	local y = -ry + self.currentY
	return self.read_matrix[self:index(x, y)]
end

function ParticleChunk:isInside(rx, ry)
	local x = rx + self.currentX
	local y = -ry + self.currentY
	return x >= start_index and x <= self.width - end_index and y >= start_index and y <= self.height - end_index
end

function ParticleChunk:isEmpty(rx, ry)
	local x = rx + self.currentX
	local y = -ry + self.currentY
	return self:isInside(rx, ry) and
		self.read_matrix[self:index(x, y)].type == ParticleType.EMPTY and
		not self.write_matrix[self:index(x, y)].clock
end

function ParticleChunk:getParticleType(rx, ry)
	local x = rx + self.currentX
	local y = -ry + self.currentY
	
	if not self:isInside(rx, ry) then
		return -1
	end

	return self.read_matrix[self:index(x, y)].type
end

function ParticleChunk:check_neighbour_multi(rx, ry, mask)
	local x = rx + self.currentX
	local y = -ry + self.currentY
	if not self:isInside(rx, ry) or self.write_matrix[self:index(x, y)].clock then
		return false
	end

	local type  = self.read_matrix[self:index(x, y)].type
	for _, v in ipairs(mask) do
		if type == v then
			return true
		end
	end

	return false
end

return ParticleChunk
