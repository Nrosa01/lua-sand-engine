require "buffer"
require "Particle"
require "love.graphics"
require "love.image"

local ParticleChunk = require "particle_chunk"
local Quad = require "quad"

local chunk, imageData, ParticleDefinitionsHandler = ...

imageData:setPixel(1,1,1,1,1,1)

local quad = Quad:from(love.graphics.getWidth(), love.graphics.getHeight(), chunk.width, chunk.height, imageData)
ParticleDefinitionsHandler = Decode(ParticleDefinitionsHandler)
local chunk = ParticleChunk:from(chunk.bytecode, chunk.width, chunk.height, quad)