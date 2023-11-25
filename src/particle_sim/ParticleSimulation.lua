local ffi = require("ffi")
require("Particle")
local Quad = require("Quad")
local ParticleChunk = require("particle_chunk")
require("love.system")

---@class ParticleSimulation
---@field quad Quad
---@field chunk ParticleChunk
---@field clock boolean
---@field updateData table
---@field updateDataReversed table
local ParticleSimulation = {}

ParticleSimulation.__index = ParticleSimulation

function ParticleSimulation:new(window_width, window_height, simulation_width, simulation_height)
    -- I guess here I define fields
    local o =
    {
        quad               = Quad:new(window_width, window_height, simulation_width, simulation_height),
        chunk              = ParticleChunk:new(simulation_width, simulation_height),
        updateData         =
        {
            xStart = 0,
            xEnd = simulation_width - 1,
            yStart = simulation_height - 1,
            yEnd = 0,
            incrementX = 1,
            incrementY = -1
        },
        updateDataReversed =
        {
            xStart = simulation_width - 1,
            xEnd = 0,
            yStart = simulation_height - 1,
            yEnd = 0,
            incrementX = -1,
            incrementY = -1
        },
        imageDataPtr       = {},
        imageSize          = simulation_width * simulation_height,
        channel            = love.thread.getChannel("mainThreadChannel"),
        chunkChannel       = love.thread.getChannel("chunkChannel"),
        threads            = {},
        particle_buffer    = love.data.newByteData(simulation_width * simulation_height *
            ffi.sizeof("Particle"))
    }

    o.imageDataPtr = ffi.cast("uint8_t*", o.quad.imageData:getFFIPointer())

    local colorArray = {}   
    local registeredParticleCount = ParticleDefinitionsHandler:getRegisteredParticlesCount()

    for i = 1, registeredParticleCount do
        local color = ParticleDefinitionsHandler:getParticleData(i).color
        colorArray[i] = color
    end

    local processorCount = love.system.getProcessorCount()
    for i = 1, processorCount do
        o.threads[i] = love.thread.newThread("src/particle_sim/render_thread.lua")
        local startIndex = math.floor((i - 1) * o.imageSize / processorCount)
        local endIndex = math.floor(i * o.imageSize / processorCount) - 1
        o.threads[i]:start(o.quad.imageData, startIndex, endIndex, o.particle_buffer, colorArray)
    end

    local particle_buffer_ptr = ffi.cast("Particle*", o.particle_buffer:getFFIPointer())

    for row = 0, simulation_width * simulation_height - 1 do
        particle_buffer_ptr[row].type = ParticleType.EMPTY
        particle_buffer_ptr[row].clock = false
    end

    o.chunk.matrix = particle_buffer_ptr

    setmetatable(o, self)
    return o
end

function ParticleSimulation:update()
    if self.chunk.clock then
        self.chunk:update(self.updateData)
    else
        self.chunk:update(self.updateDataReversed)
    end

    self:updateTexture()
end

function ParticleSimulation:updateTexture()
    -- Init all threads to start
    for i = 1, #self.threads do
        self.channel:push(i)
    end

    -- Wait for all threads to finish
    for i = 1, #self.threads do
        self.chunkChannel:demand()
    end
end

function ParticleSimulation:render()
    -- for i = 0, self.imageSize - 1 do
    --     local index = i * 4
    --     local color = getColorOf(self.chunk.matrix[i].type)
    --     self.imageDataPtr[index] = color.r
    --     self.imageDataPtr[index + 1] = color.g
    --     self.imageDataPtr[index + 2] = color.b
    --     self.imageDataPtr[index + 3] = color.a
    -- end

    self.quad:render(0, 0)
end

return ParticleSimulation
