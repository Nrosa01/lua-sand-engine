-- ParticleDefinitionsHandler.lua
ParticleDefinitionsHandler = {
    particle_data = {},
    text_to_id_map = {},
}

ParticleDefinitionsHandler.__index = ParticleDefinitionsHandler

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
    if index >= 1 and index <= #self.particle_data then
        -- print("Data at index " .. index .. ": " .. self.particle_data[index].text_id)
        return self.particle_data[index]
    else
        error("Index was out of range on getParticleData (index: " .. index .. ")")
    end
end

function ParticleDefinitionsHandler:getParticleDataVector()
    return self.particle_data
end

return ParticleDefinitionsHandler
