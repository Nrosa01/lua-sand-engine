-- This is just a constructor
local ParticleDefinitionLib = {}

function ParticleDefinitionLib.new(text_id, particle_color, interactions)
    local instance = {
        text_id = text_id,
        color = particle_color,
        interactions =
            interactions and
            string.dump(interactions) or
            string.dump(function(api) end)
        -- interactions = interactions and string.dump(interactions) or ""
    }

    return instance
end

return ParticleDefinitionLib
