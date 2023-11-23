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
    funcs = ParticleDefinitionsHandlerConstructor.funcs
}

setmetatable(ParticleDefinitionsHandler, ParticleDefinitionsHandlerConstructor)


function ParticleDefinitionsHandlerConstructor:addParticleData(data)
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

local ffi = require("ffi")

ffi.cdef [[
typedef struct { uint8_t type; bool clock; } Particle;
]]

local a={}a.__index=a;local b=1;local c=0;local d=1;function a:new(e,f)local g={matrix=ffi.cast("Particle*",e.bytecode:getFFIPointer()),width=e.width,height=e.height,clock=false,currentX=0,currentY=0,updateData=f}setmetatable(g,self)return g end;function a:index(h,i)return h+i*self.width end;function a:update()local j=ParticleDefinitionsHandler.funcs;for i=self.updateData.yStart,self.updateData.yEnd do for h=self.updateData.xStart,self.updateData.xEnd do local k=self:index(h,i)if self.matrix[k].clock~=self.clock then self.matrix[k].clock=not self.clock else self.currentX=h;self.currentY=i;j[self.matrix[k].type](h,i,self)end end end end;function a:setNewParticleById(h,i,l)if h>=c and h<=self.width-d and i>=c and i<=self.height-d then self.matrix[self:index(h,i)].type=l;self.matrix[self:index(h,i)].clock=false end end;function a:setParticle(h,i,m)if h>=c and h<=self.width-d and i>=c and i<=self.height-d then self.matrix[self:index(h,i)].type=m.type;self.matrix[self:index(h,i)].clock=m.clock end end;function a:getWidth()return self.width end;function a:getHeight()return self.height end;function a:getParticle(h,i)return self.matrix[self:index(h,i)]end;function a:isInside(h,i)return h>=c and h<=self.width-d and i>=c and i<=self.height-d end;function a:isEmpty(h,i)return self.matrix[self:index(h,i)].type==b end;function a:getParticleType(h,i)return self.matrix[self:index(h,i)].type end
-- local ParticleChunk = require "particle_chunk"

local chunkData, updateData, pdata, tdata, index = ...


ParticleDefinitionsHandler.particle_data = pdata
ParticleDefinitionsHandler.text_to_id_map = tdata

-- As I saved code as string, I need to load it
-- This is the only way to pass functions to the thread
for i = 1, ParticleDefinitionsHandler:getRegisteredParticlesCount() do
    local data = ParticleDefinitionsHandler:getParticleData(i)
    ParticleDefinitionsHandler.funcs[i] = load(data.interactions)
end

local chunk = a:new(chunkData, updateData)

local channel = love.thread.getChannel("particle_sim_channel")

chunk:update()



-- while true do
--     local command = channel:demand()
    
-- end
