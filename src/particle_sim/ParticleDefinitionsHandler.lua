local ParticleDefinition = require("ParticleDefinition")

-- ParticleDefinitionsHandler.lua
local ParticleDefinitionsHandlerConstructor = {
    particle_data = {},
    text_to_id_map = {},
    funcs = {},
}

ParticleDefinitionsHandlerConstructor.__index = ParticleDefinitionsHandlerConstructor

ParticleDefinitionsHandler = 
{
    particle_data = ParticleDefinitionsHandlerConstructor.particle_data,
    text_to_id_map = ParticleDefinitionsHandlerConstructor.text_to_id_map,
    funcs = ParticleDefinitionsHandlerConstructor.funcs,
}

setmetatable(ParticleDefinitionsHandler, ParticleDefinitionsHandlerConstructor)

_G.addParticle = function (text, color, func)
    ParticleDefinitionsHandler:addParticleData(ParticleDefinition.new(text, color, func))
end

_G.getFuncOf = function (id)
    return ParticleDefinitionsHandler.particle_data[id].interactions
end

_G.getColorOf = function (id)
    return ParticleDefinitionsHandler.particle_data[id].color
end

_G.ParticleType = {}

function ParticleDefinitionsHandlerConstructor:addParticleData(data)
    -- If data is already registered in text_to_id_map, then we overwrite it in particle_data
    -- Otherwise we add it to the end of the particle_data vector and add it to the text_to_id_map
    
    local index = self.text_to_id_map[data.text_id]
    
    if index then
        self.particle_data[index] = data
    else
        table.insert(self.particle_data, data)
        local replace_space_with_underscore_to_upper = string.gsub(string.upper(data.text_id), " ", "_")
        _G.ParticleType[replace_space_with_underscore_to_upper] = #self.particle_data
        self.text_to_id_map[data.text_id] = #self.particle_data
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
