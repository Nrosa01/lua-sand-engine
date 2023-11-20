-- ParticleChunk.lua
local ffi = require("ffi")
local Particle = require("Particle")
local empty_particle_id = 1
local start_index = 0
local end_index = 1

ParticleChunk = {
    matrix = nil,
    width = 0,
    height = 0,
    clock = false,
}


local function newArray2D(width, height)
    local matrix = ffi.new("Particle*[?]", width)

    for x = 0, width - 1 do
        matrix[x] = ffi.new("Particle[?]", height)
        for y = 0, height - 1 do
            matrix[x][y].type = 1
            matrix[x][y].clock = false
        end
    end

    return matrix
end

function ParticleChunk.new(width, height)
    local instance = {
        matrix = newArray2D(width, height),
        width = width,
        height = height,
        clock = false,
    }

    return setmetatable(instance, { __index = ParticleChunk })
end

function ParticleChunk:reset()
    -- set all matrix data to 0
    local width = self.width
    local height = self.height

    for y = start_index, width - end_index do
        for x = start_index, height - end_index do
            self.matrix[x][y].type = Particle(empty_particle_id)
        end
    end
end


function ParticleChunk:updateParticle(x, y)
    local data = ParticleDefinitionsHandler:getParticleData(self:getParticleType(x, y))
    -- local interactions = data.interactions
    local particle_movement_passes_amount = #data.movement_passes

    if self.matrix[x][y].clock ~= self.clock or particle_movement_passes_amount == 0 then
        self.matrix[x][y].clock = not self.clock
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

    self.matrix[x][y].clock = not self.clock
    self.matrix[new_pos_x][new_pos_y].clock = not self.clock
end

-- Resto de métodos y propiedades de ParticleChunk

function ParticleChunk:update()
    local width = self.width
    local height = self.height

    for y = start_index, width - end_index do
        for x = start_index, height - end_index do
            self:updateParticle(x, y)
        end
    end

    self.clock = not self.clock
end

function ParticleChunk:setNewParticleById(x, y, id)
    if x >= start_index and x <= self.width - end_index and y >= start_index and y <= self.height - end_index then
        self.matrix[x][y].type = id
        self.matrix[x][y].clock = false
    end
end

function ParticleChunk:setParticle(x, y, particle)
    if x >= start_index and x <= self.width - end_index and y >= start_index and y <= self.height - end_index then
        self.matrix[x][y] = particle
    end
end

function ParticleChunk:tryPushParticle(x, y, dir_x, dir_y)
    local new_x, new_y = x + dir_x, y + dir_y

    if self:isInside(new_x, new_y) and self:canPush(new_x, new_y, x, y) then
        local aux = self.matrix[new_y][new_x]
        self.matrix[new_x][new_y] = self.matrix[x][y]
        self.matrix[x][y] = aux

        for i = -5, 5 - 1 do
            for j = 1, 20 - 1 do
                if self:isInside(new_x + i, new_y + j) and self:isEmpty(new_x + i, new_y + j) then
                    self.matrix[new_y + j][new_x + i] = aux
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
        self.matrix[new_x][new_y] = self.matrix[x][y]
        self.matrix[x][y].type = empty_particle_id
        self.matrix[x][y].clock = false
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
    return self.matrix[x][y]
end

function ParticleChunk:isInside(x, y)
    return x >= start_index and x <= self.width - end_index and y >= start_index and y <= self.height - end_index
end

function ParticleChunk:isEmpty(x, y)
    return self.matrix[x][y].type == empty_particle_id
end

function ParticleChunk:canPush(other_x, other_y, x, y)
    return ParticleDefinitionsHandler:getParticleData(self:getParticleType(other_x, other_y)).properties.density < ParticleDefinitionsHandler:getParticleData(self:getParticleType(x, y)).properties.density
end

function ParticleChunk:getParticleType(x, y)
    return self.matrix[x][y].type
end

return ParticleChunk
