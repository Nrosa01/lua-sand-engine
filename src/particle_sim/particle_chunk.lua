-- ParticleChunk.lua
local ffi = require("ffi")
local ParticleFactory = require("ParticleFactory")

local ParticleMatrix = {
    data = nil,
    width = 0,
    height = 0,
}

ParticleChunk = {
    matrix = nil,
    clock = false,
}

function ParticleMatrix.new(width, height)
    local matrix = {
        data = {},
        width = width,
        height = height,
    }

    for x = 1, width do
        matrix.data[x] = {}
        for y = 1, height do
            matrix.data[x][y] = ParticleFactory.createParticle(1)
        end
    end

    return setmetatable(matrix, { __index = ParticleMatrix })
end

function ParticleChunk.new(width, height)
    local instance = {
        matrix = ParticleMatrix.new(width, height),
        clock = false,
    }

    return setmetatable(instance, { __index = ParticleChunk })
end

function ParticleChunk:reset()
    -- set all matrix data to 0
    local width = self.matrix.width
    local height = self.matrix.height

    for y = 1, height do
        for x = 1, width do
            self.matrix.data[x][y].type = 1
        end
    end
end


function ParticleChunk:updateParticle(x, y)
    local registry = ParticleDefinitionsHandler
    local data = registry:getParticleData(self:getParticleType(x, y))
    local interactions = data.interactions
    local particle_movement_passes_amount = #data.movement_passes

    if self.matrix.data[x][y].clock ~= self.clock or particle_movement_passes_amount == 0 then
        self.matrix.data[x][y].clock = not self.clock
        return
    end

    local particle_movement_passes_index = 1
    local pixelsToMove = 1
    local particleIsMoving = true
    local particleCollidedLastIteration = false
    local new_pos_x, new_pos_y = x, y

    while pixelsToMove > 0 and particleIsMoving do
        local dir_x, dir_y = data.movement_passes[particle_movement_passes_index].x, data.movement_passes[particle_movement_passes_index].y
        local particleMoved = self:moveParticle(new_pos_x, new_pos_y, dir_x, dir_y)

        if not particleMoved then
            particleMoved = self:tryPushParticle(new_pos_x, new_pos_y, dir_x, dir_y)
        end

        if not particleMoved then
            particle_movement_passes_index = particle_movement_passes_index + 1

            if particle_movement_passes_index > particle_movement_passes_amount then
                particle_movement_passes_index = 1

                if particleCollidedLastIteration then
                    particleIsMoving = false
                end

                particleCollidedLastIteration = true
            end
        else
            particleCollidedLastIteration = false
            particleIsMoving = true
            pixelsToMove = pixelsToMove - 1
            new_pos_x, new_pos_y = new_pos_x + dir_x, new_pos_y + dir_y
        end
    end

    self.matrix.data[x][y].clock = not self.clock
    self.matrix.data[new_pos_x][new_pos_y].clock = not self.clock
end

-- Resto de métodos y propiedades de ParticleChunk

function ParticleChunk:update()
    local width = self.matrix.width
    local height = self.matrix.height

    for y = 1, height do
        for x = 1, width do
            self:updateParticle(x, y)
        end
    end

    self.clock = not self.clock
end

function ParticleChunk:setNewParticleById(x, y, id)
    if x >= 0 and x < self.matrix.width and y >= 0 and y < self.matrix.height then
        self.matrix.data[x][y] = ParticleFactory.createParticle(id)
    end
end

function ParticleChunk:setParticle(x, y, particle)
    if x >= 0 and x < self.matrix.width and y >= 0 and y < self.matrix.height then
        self.matrix.data[x][y] = particle
    end
end

function ParticleChunk:tryPushParticle(x, y, dir_x, dir_y)
    local new_x, new_y = x + dir_x, y + dir_y

    if self:isInside(new_x, new_y) and self:canPush(new_x, new_y, x, y) then
        local aux = ffi.new("struct Particle", ParticleFactory.createParticle(1))
        aux = self.matrix.data[new_y][new_x]
        self.matrix.data[new_y][new_x] = self.matrix.data[y][x]
        self.matrix.data[y][x] = aux

        for i = -5, 5 - 1 do
            for j = 1, 20 - 1 do
                if self:isInside(new_x + i, new_y + j) and self:isEmpty(new_x + i, new_y + j) then
                    self.matrix.data[new_y + j][new_x + i] = aux
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
        self.matrix.data[new_y][new_x] = self.matrix.data[y][x]
        self.matrix.data[y][x] = ParticleFactory.createParticle(1)
        return true
    else
        return false
    end
end

-- Define getwitdth function with different notation using self as parameter

function ParticleChunk:getWidth()
    return self.matrix.width
end

function ParticleChunk:getHeight()
    return self.matrix.height
end

function ParticleChunk:getParticle(x, y)
    return self.matrix.data[y][x]
end

function ParticleChunk:isInside(x, y)
    return x >= 1 and x <= self.matrix.width and y >= 1 and y <= self.matrix.height
end

function ParticleChunk:isEmpty(x, y)
    return self.matrix.data[y][x].type == 1
end

function ParticleChunk:canPush(other_x, other_y, x, y)
    return ParticleDefinitionsHandler:getParticleData(self:getParticleType(other_x, other_y)).properties.density < ParticleDefinitionsHandler:getParticleData(self:getParticleType(x, y)).properties.density
end

function ParticleChunk:getParticleType(x, y)
    return self.matrix.data[y][x].type
end

return ParticleChunk
