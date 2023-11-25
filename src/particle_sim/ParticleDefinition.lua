-- This is just a constructor
require "colour_t"
local ffi = require("ffi")
local ParticleDefinitionLib = {}

function ParticleDefinitionLib.new(text_id, particle_color, interaction)
    local instance = {
        text_id = text_id,
        color = particle_color,
        func = interaction or function(api) end
    }

    return instance
end

return ParticleDefinitionLib
