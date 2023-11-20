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
    local matrix = ffi.new("struct Particle*[?]", width)

    for x = start_index, width - end_index do
        matrix[x] = ffi.new("struct Particle*", ffi.new("struct Particle[?]", height))
        for y = start_index, height - end_index do
            matrix[x][y] = Particle(empty_particle_id, false)
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

return ParticleChunk