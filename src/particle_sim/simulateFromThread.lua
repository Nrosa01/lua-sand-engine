local ffi = require("ffi")
local Particle = require("Particle")
local ParticleDefinitionsHandler =  require("ParticleDefinitionsHandler")
--load love timer
local love_timer = require("love.timer")


-- Receive values sent via thread:start
local chunk, particle_data, text_to_id_map = ...

ParticleDefinitionsHandler = ParticleDefinitionsHandler.new(particle_data, text_to_id_map)

local ptr = ffi.cast("Particle*", chunk:getFFIPointer())
ptr[0].type = 2
print("Chunk test " .. ptr[0].type)
io.write("Handler ")
-- yield the love thread 1 second
love_timer.sleep(1)
-- get particle data for id 2
local data = ParticleDefinitionsHandler:getParticleData(2)
print(data.text_id)