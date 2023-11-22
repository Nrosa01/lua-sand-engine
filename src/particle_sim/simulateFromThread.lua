require "buffer"
require "Particle"
require "love.graphics"
require "love.image"

local ParticleChunk = require "particle_chunk"
local Quad = require "quad"

local chunkData, quadData, ParticleDefinitionsHandler = ...

ParticleDefinitionsHandler = Decode(ParticleDefinitionsHandler)

if not ParticleDefinitionsHandler then
    error("ParticleDefinitionsHandler is nil")
end

_G.ParticleDefinitionsHandler = ParticleDefinitionsHandler

-- As I saved code as string, I need to load it
-- This is the only way to pass functions to the thread
for i = 1, ParticleDefinitionsHandler:getRegisteredParticlesCount() do
    local data = ParticleDefinitionsHandler:getParticleData(i)
    data.interactions = load(data.interactions)
end

local quad = Quad:from(quadData.width, quadData.height, chunkData.width, chunkData.height, quadData.imageData)
local chunk = ParticleChunk:new(chunkData, quad)
chunk:update()