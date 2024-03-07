require("particle_definition_handler")
require("love.image")

local Commands = require("job_commands")

local ffi = require("ffi")
local ParticleChunk = require "particle_chunk"
local width, height, pdata, imageData, index = ...

ParticleDefinitionsHandler:loadParticleData(pdata)

-- As I saved code as string, I need to load it
-- This is the only way to pass functions to the thread
for i = 1, ParticleDefinitionsHandler:getRegisteredParticlesCount() do
    local data = ParticleDefinitionsHandler:getParticleData(i)
    ParticleDefinitionsHandler.funcs[i] = load(data.interactions)
end

local chunk = ParticleChunk:new(width, height)
local imageDataptr = ffi.cast("uint8_t*", imageData:getFFIPointer())

local mainThreadChannel = love.thread.getChannel("mainThreadChannel")
local commonThreadChannel = love.thread.getChannel("commonThreadChannel")
local threadChannel = love.thread.getChannel("threadChannel" .. index)

local function updateSimulation(data)
    -- print("Thread " .. index .. " received command " .. command)
    chunk.updateData = data.updateData
    chunk.clock = data.clock
    chunk.read_matrix = ffi.cast("Particle*", data.read:getFFIPointer())
    chunk.write_matrix = ffi.cast("Particle*", data.write:getFFIPointer())
    chunk:update(data.simulation_tick)
end

-- Updatedata here should be a start index and end index to iterate over an array
local function updateBuffers(data)
    local updateData = data.updateData
    local read = ffi.cast("Particle*", data.read:getFFIPointer())
    local write = ffi.cast("Particle*", data.write:getFFIPointer())

    local p_count = 0

    for y = updateData.yStart, updateData.yEnd, updateData.increment do
        for x = updateData.xStart, updateData.xEnd, updateData.increment do
            local index = chunk:index(x, y)
            read[index].type = write[index].type
            read[index].clock = false

            if read[index].type ~= ParticleType.EMPTY then
                p_count = p_count + 1
            end

            local color = ParticleDefinitionsHandler:getParticleData(read[index].type).color
            local pIndex = index * 4
            imageDataptr[pIndex] = color.r
            imageDataptr[pIndex + 1] = color.g
            imageDataptr[pIndex + 2] = color.b
            imageDataptr[pIndex + 3] = color.a
        end
    end

    return p_count
end

while true do
    local message = mainThreadChannel:demand()
    local file = threadChannel:pop()

    if file then
        
        dofile(file:getFilename())
        
        for i = 1, ParticleDefinitionsHandler:getRegisteredParticlesCount() do
            local data = ParticleDefinitionsHandler:getParticleData(i)
            ParticleDefinitionsHandler.funcs[i] = load(data.interactions)
        end
    end

    local p_count = -1

    if message.command == Commands.TICK_SIMULATION then
        updateSimulation(message.data)
    elseif message.command == Commands.UPDATE_BUFFERS then
        p_count = updateBuffers(message.data)
    end

    commonThreadChannel:performAtomic(function(channel)
        channel:push(p_count)
    end)
end
