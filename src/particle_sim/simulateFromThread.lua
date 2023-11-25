require ("ParticleDefinitionsHandler")
require ("love.image")
require("colour_t")

local ffi = require("ffi")
local ParticleChunk = require "particle_chunk"
local chunkData, pdata, tdata, imageData, index = ...

ParticleDefinitionsHandler.particle_data = pdata
ParticleDefinitionsHandler.text_to_id_map = tdata

-- As I saved code as string, I need to load it
-- This is the only way to pass functions to the thread
for i = 1, ParticleDefinitionsHandler:getRegisteredParticlesCount() do
    local data = ParticleDefinitionsHandler:getParticleData(i)
    data.color = ffi.new("struct colour_t", data.color.r, data.color.g, data.color.b, data.color.a)
    ParticleDefinitionsHandler.funcs[i] = load(data.interactions)
end

local chunk = ParticleChunk:new(chunkData)
local imageDataptr = ffi.cast("uint8_t*", imageData:getFFIPointer())

local channel = love.thread.getChannel("mainThreadChannel")
local chunkChannel = love.thread.getChannel("chunkChannel")

while true do
    local data = channel:demand()
    -- print("Thread " .. index .. " received command " .. command)
    chunk.updateData = data.updateData
    chunk.clock = data.clock
    chunk.read_matrix = ffi.cast("Particle*", data.read:getFFIPointer())
    chunk.write_matrix = ffi.cast("Particle*", data.write:getFFIPointer())
    chunk:update()

    -- Once we have written into the write buffer, we send copy it to the read buffer
    -- to have it ready for the next iteration, iterate using updateData

    local updateData = chunk.updateData
    --print(casted)
    for y = updateData.yStart, updateData.yEnd, updateData.increment do
        for x = updateData.xStart, updateData.xEnd, updateData.increment do
            local index = chunk:index(x, y)
            chunk.read_matrix[index].type = chunk.write_matrix[index].type
            local color = ParticleDefinitionsHandler:getParticleData(chunk.read_matrix[index].type).color
            
            -- This is fast (the cast is done only once outside, this is only for showcasing)
            local pIndex = index * 4
            imageDataptr[pIndex] = color.r
            imageDataptr[pIndex + 1] = color.g
            imageDataptr[pIndex + 2] = color.b
            imageDataptr[pIndex + 3] = color.a
        end
    end

    chunkChannel:performAtomic(function(channel)
        channel:push(1)
    end)
end
