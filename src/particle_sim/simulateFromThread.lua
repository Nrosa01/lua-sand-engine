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

local ParticleChunk = require "particle_chunk"

local chunkData, updateData, pdata, tdata, index = ...


ParticleDefinitionsHandler.particle_data = pdata
ParticleDefinitionsHandler.text_to_id_map = tdata

-- As I saved code as string, I need to load it
-- This is the only way to pass functions to the thread
for i = 1, ParticleDefinitionsHandler:getRegisteredParticlesCount() do
    local data = ParticleDefinitionsHandler:getParticleData(i)
    ParticleDefinitionsHandler.funcs[i] = load(data.interactions)
end

local chunk = ParticleChunk:new(chunkData, updateData)

local channel = love.thread.getChannel("mainThreadChannel")
local chunkChannel = love.thread.getChannel("chunkChannel")

while true do
    local data = channel:demand()
    -- print("Thread " .. index .. " received command " .. command)
    chunk.updateData = data.updateData
    chunk.clock = data.clock
    chunk.matrixes = 
    {
        read = ffi.cast("Particle*",  data.read:getFFIPointer()),
        write = ffi.cast("Particle*", data.write:getFFIPointer())
    }
    chunk:update()

    -- Once we have written into the write buffer, we send copy it to the read buffer
    -- to have it ready for the next iteration, iterate using updateData

    local updateData = chunk.updateData
    for y = updateData.yStart, updateData.yEnd, updateData.increment do
        for x = updateData.xStart, updateData.xEnd, updateData.increment do
            local index = chunk:index(x, y)
            chunk.matrixes.read[index].type = chunk.matrixes.write[index].type
        end
    end

    chunkChannel:performAtomic(function(channel)
        channel:push(1)
    end)
end
