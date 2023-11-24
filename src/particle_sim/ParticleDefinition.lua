-- This is just a constructor
local ParticleDefinitionLib = {}

function ParticleDefinitionLib.new(text_id, particle_color, interaction)
    local instance = {
        text_id = text_id,
        color = {r = particle_color.r / 255.0, g = particle_color.g / 255.0, b = particle_color.b / 255.0, a = particle_color.a / 255.0},
        func = interaction or function(api) end
    }

    return instance
end

return ParticleDefinitionLib
