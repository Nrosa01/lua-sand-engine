local ffi = require("ffi")
require("Particle")
local Quad = require("Quad")
local ParticleChunk = require("particle_chunk")
require("love.system")

---@class ParticleSimulation
---@field window_width number
---@field window_height number
---@field simulation_width number
---@field simulation_height number
---@field simulation_buffer_bytecode love.ByteData
---@field simulaton_buffer_ptr Particle*
---@field quad Quad
---@field threads table
---@field chunk ParticleChunk
---@field clock boolean
---@field updateData table
---@field chunkData table
---@field quadData table
local ParticleSimulation = {}

ParticleSimulation.__index = ParticleSimulation

function ParticleSimulation:new(window_width, window_height, simulation_width, simulation_height)
    -- I guess here I define fields
    local o =
    {
        window_width               = window_width,
        window_height              = window_height,
        simulation_width           = simulation_width,
        simulation_height          = simulation_height,
        simulation_buffer_bytecode = love.data.newByteData(simulation_width * simulation_height * ffi.sizeof("Particle")),
        simulaton_buffer_ptr       = nil,
        quad                       = Quad:new(window_width, window_height, simulation_width, simulation_height),
        threads                    = {},
        chunk                      = nil,
        clock                      = false,
        updateData                 = {},
        chunkData                  = {},
        quadData                   = {},
    }

    o.simulaton_buffer_ptr = ffi.cast("Particle*", o.simulation_buffer_bytecode:getFFIPointer())

    for i = 0, simulation_width * simulation_height - 1 do
        o.simulaton_buffer_ptr[i].type = 1
        o.simulaton_buffer_ptr[i].clock = false
    end

    local chunkData = { bytecode = o.simulation_buffer_bytecode, width = simulation_width, height = simulation_height }
    o.chunk = ParticleChunk:new(chunkData, {}, o.quad)

    -- Build update data
    local numThreads = love.system:getProcessorCount()

    -- We will create numThreads threads
    for i = 1, numThreads do
        o.threads[i] = love.thread.newThread("src/particle_sim/simulateFromThread.lua")
    end

    -- We will create numThreads updateData tables
    local xStep = math.floor(simulation_width / numThreads)
    local yStep = math.floor(simulation_height / numThreads)

    for i = 1, numThreads do
        o.updateData[i] =
        {
            xStart = (i - 1) * xStep,
            xEnd = i * xStep - 1,
            yStart = (i - 1) * yStep,
            yEnd = i * yStep - 1
        }
    end

    -- We will create numThreads chunkData tables
    o.chunkData = {
        bytecode = o.simulation_buffer_bytecode,
        width = o.simulation_width,
        height = o.simulation_height
    }

    o.quadData = { width = o.window_width, height = o.simulation_height, imageData = o.quad.imageData }

    setmetatable(o, self)
    return o
end

function ParticleSimulation:update()
    -- Get num of threads supported
    local ParticleDefinitionsHandler = Encode(_G.ParticleDefinitionsHandler)
    local threadCount = #self.threads

    -- Run all odd threds
    for i = 1, threadCount, 2 do
        self:runThread(self.threads[i], i, ParticleDefinitionsHandler)
    end

    -- Wait for all odd threads to finish
    for i = 1, threadCount, 2 do
        self.threads[i]:wait()
    end

    -- Run all even threads
    for i = 2, threadCount, 2 do
        self:runThread(self.threads[i], i, ParticleDefinitionsHandler)
    end

    -- Wait for all even threads to finish
    for i = 2, threadCount, 2 do
        self.threads[i]:wait()
    end

    self.clock = not self.clock
end

function ParticleSimulation:runThread(thread, updateDataIndex, ParticleDefinitionsHandler)
    thread:start(self.chunkData, self.updateData[updateDataIndex], self.quadData, ParticleDefinitionsHandler)
end

function ParticleSimulation:render()
    self.quad:render(0, 0)
end

return ParticleSimulation
