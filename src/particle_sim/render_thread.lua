require "love.image"
require "Particle"
require "ParticleDefinitionsHandler"
require "colour_t"

local ffi = require("ffi")

-- Thread start parameters
local imageData, startIndex, endIndex, particle_buffer, colors = ...

-- Init
local particle_buffer_ptr = ffi.cast("Particle*", particle_buffer:getFFIPointer())
local channel = love.thread.getChannel("mainThreadChannel")
local chunkChannel = love.thread.getChannel("chunkChannel")
local imageDataPtr = ffi.cast("uint8_t*", imageData:getFFIPointer())

-- Convert colour table to ffi struct
for i = 1, #colors do
    local color = colors[i]
    colors[i] = ffi.new("colour_t", color.r, color.g, color.b, color.a)
end

while true do
    channel:demand()
    
    for i = startIndex, endIndex do
        local index = i * 4
        local particleType = particle_buffer_ptr[i].type
        local color = colors[particleType]
        imageDataPtr[index] = color.r
        imageDataPtr[index + 1] = color.g
        imageDataPtr[index + 2] = color.b
        imageDataPtr[index + 3] = color.a
    end

    chunkChannel:performAtomic(function(channel)
        channel:push(1)
    end)
end