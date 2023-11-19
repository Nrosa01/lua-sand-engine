-- ParticleDefinition.lua
ParticleDefinition = {}

function ParticleDefinition.new(text_id, particle_color, random_granularity, movement_passes, properties, interactions)
    local instance = {
        text_id = text_id,
        particle_color = particle_color,
        random_granularity = random_granularity,
        movement_passes = movement_passes,
        properties = properties,
        interactions = interactions,
    }

    setmetatable(instance, { __index = ParticleDefinition })
    return instance
end

return ParticleDefinition
