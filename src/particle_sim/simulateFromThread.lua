require ("ParticleDefinitionsHandler")
require ("love.image")
require("colour_t")

local ffi = require("ffi")
local ParticleChunk = require "particle_chunk"
local chunkData, pdata, tdata, imageData, index = ...

ParticleDefinitionsHandler.particle_data = pdata
ParticleDefinitionsHandler.text_to_id_map = tdata


_G.ParticleType = {}

-- As I saved code as string, I need to load it
-- This is the only way to pass functions to the thread
for i = 1, ParticleDefinitionsHandler:getRegisteredParticlesCount() do
    local data = ParticleDefinitionsHandler:getParticleData(i)
    data.color = ffi.new("colour_t", data.color.r, data.color.g, data.color.b, data.color.a)
    ParticleDefinitionsHandler.funcs[i] = load(data.interactions)
    ParticleType[string.upper(data.text_id)] = i
end

local chunk = ParticleChunk:new(chunkData)
local imageDataptr = ffi.cast("uint8_t*", imageData:getFFIPointer())

local channel = love.thread.getChannel("mainThreadChannel")
local chunkChannel = love.thread.getChannel("chunkChannel")

local function updateSimulation(data)
        -- print("Thread " .. index .. " received command " .. command)
        chunk.updateData = data.updateData
        chunk.clock = data.clock
        chunk.read_matrix = ffi.cast("Particle*", data.read:getFFIPointer())
        chunk.write_matrix = ffi.cast("Particle*", data.write:getFFIPointer())
        chunk:update() 
end

-- Updatedata here should be a start index and end index to iterate over an array
local function updateBuffers(data)
    local updateData = data.updateData
    local read = ffi.cast("Particle*", data.read:getFFIPointer())
    local write = ffi.cast("Particle*", data.write:getFFIPointer())

    for y = updateData.yStart, updateData.yEnd, updateData.increment do
        for x = updateData.xStart, updateData.xEnd, updateData.increment do
            local index = chunk:index(x, y)
            read[index].type = write[index].type
            read[index].clock = false
            
            local color = ParticleDefinitionsHandler:getParticleData(read[index].type).color
            local pIndex = index * 4
            imageDataptr[pIndex] = color.r
            imageDataptr[pIndex + 1] = color.g
            imageDataptr[pIndex + 2] = color.b
            imageDataptr[pIndex + 3] = color.a
        end
    end
end

while true do
    local message = channel:demand()

    if message.command == "TickSimulation" then
        updateSimulation(message.data)
    elseif message.command == "UpdateBuffers" then
        updateBuffers(message.data)
    end

    chunkChannel:performAtomic(function(channel)
        channel:push(1)
    end)
end
