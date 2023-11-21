-- ParticleDefinitionsHandler.lua
ParticleDefinitionsHandler = {
    particle_data = {},
    text_to_id_map = {},
}

ParticleDefinitionsHandler.__index = ParticleDefinitionsHandler

function ParticleDefinitionsHandler.new(particle_data, text_to_id_map)
    local instance = {
        particle_data = particle_data or {},
        text_to_id_map = text_to_id_map or {}
    }

    setmetatable(instance, ParticleDefinitionsHandler)
    return instance
end

function ParticleDefinitionsHandler:addParticleData(data)
    -- If data is already registered in text_to_id_map, then we overwrite it in particle_data
    -- Otherwise we add it to the end of the particle_data vector and add it to the text_to_id_map

    local index = self.text_to_id_map[data.text_id]

    if index then
        self.particle_data[index] = data
    else
        table.insert(self.particle_data, data)
        self.text_to_id_map[data.text_id] = #self.particle_data
    end
end

function ParticleDefinitionsHandler:getParticleId(particle_text_id)
    local index = self.text_to_id_map[particle_text_id]
    return index or -1
end

function ParticleDefinitionsHandler:getRegisteredParticlesCount()
    return #self.particle_data
end

function ParticleDefinitionsHandler:getParticleData(index)
    return self.particle_data[index]
end

function ParticleDefinitionsHandler:getParticleDataVector()
    return self.particle_data
end

return ParticleDefinitionsHandler
