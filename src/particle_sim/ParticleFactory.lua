-- ParticleFactory.lua
local ffi = require("ffi")
local Particle = require("Particle")
local ParticleFactory = {}

function ParticleFactory.createParticle(particle_type)
    local particle = ffi.new("struct Particle", Particle())

    particle.type = particle_type

    -- Otras inicializaciones aquí (temperature, life_time, etc.)

    local random_granularity = math.random(0, ParticleDefinitionsHandler:getParticleData(particle_type).random_granularity)
    particle.random_granularity = random_granularity

    return particle
end

return ParticleFactory
