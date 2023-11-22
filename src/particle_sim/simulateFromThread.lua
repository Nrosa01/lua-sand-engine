require "buffer"
require "Particle"
require "love.graphics"
require "love.image"

local ParticleChunk = require "particle_chunk"
local Quad = require "quad"

local chunk, imageData, ParticleDefinitionsHandler = ...

ParticleDefinitionsHandler = Decode(ParticleDefinitionsHandler)
_G.ParticleDefinitionsHandler = ParticleDefinitionsHandler

-- Iterate all interactions in particle definition handler and load them
for i = 1, ParticleDefinitionsHandler:getRegisteredParticlesCount() do
    local data = ParticleDefinitionsHandler:getParticleData(i)
    data.interactions = load(data.interactions)
end

local quad = Quad:from(love.graphics.getWidth(), love.graphics.getHeight(), chunk.width, chunk.height, imageData)
local chunk = ParticleChunk:from(chunk.bytecode, chunk.width, chunk.height, quad)
chunk:update()