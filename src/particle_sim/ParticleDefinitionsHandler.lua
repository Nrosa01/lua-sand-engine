-- ParticleDefinitionsHandler.lua
local ParticleDefinitionsHandlerConstructor = {
    particle_data = {}
}

_G.ParticleType = {}

ParticleDefinitionsHandlerConstructor.__index = ParticleDefinitionsHandlerConstructor

ParticleDefinitionsHandler = 
{
    particle_data = ParticleDefinitionsHandlerConstructor.particle_data,
}

setmetatable(ParticleDefinitionsHandler, ParticleDefinitionsHandlerConstructor)

function ParticleDefinitionsHandlerConstructor:addParticleData(data)
    -- If data is already registered in text_to_id_map, then we overwrite it in particle_data
    -- Otherwise we add it to the end of the particle_data vector and add it to the text_to_id_map
    
    local index = ParticleType[data.text_id]
    
    if index then
        self.particle_data[index] = data
    else
        table.insert(self.particle_data, data)
        ParticleType[data.text_id] = #self.particle_data
    end
end

function ParticleDefinitionsHandlerConstructor:getParticleId(particle_text_id)
    local index = self.text_to_id_map[particle_text_id]
    return index or -1
end

function ParticleDefinitionsHandlerConstructor:getRegisteredParticlesCount()
    return #self.particle_data
end

function ParticleDefinitionsHandlerConstructor:getParticleData(index)
        return self.particle_data[index]
end

function ParticleDefinitionsHandlerConstructor:getParticleDataVector()
    return self.particle_data
end

return ParticleDefinitionsHandlerConstructor
