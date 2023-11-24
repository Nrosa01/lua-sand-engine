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
---@field updateDataReversed table
---@field chunkData table
---@field quadData table
---@field channel love.Channel
---@field chunkChannel love.Channel
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
        simulation_thread          = {},
        chunk                      = nil,
        clock                      = false,
        updateData                 = {},
        updateDataReversed         = {},
        chunkData                  = {},
        quadData                   = {},
        channel                    = love.thread.getChannel("mainThreadChannel"),
        chunkChannel               = love.thread.getChannel("chunkChannel"),
        gridSize                   = 8
    }

    o.simulaton_buffer_ptr = ffi.cast("Particle*", o.simulation_buffer_bytecode:getFFIPointer())

    for row = 0, simulation_width * simulation_height - 1 do
        o.simulaton_buffer_ptr[row].type = 1
        o.simulaton_buffer_ptr[row].clock = false
    end

    local chunkData = { bytecode = o.simulation_buffer_bytecode, width = simulation_width, height = simulation_height }

    o.chunk = ParticleChunk:new(chunkData, {})

    o.updateData =
    {
        xStart = 0,
        xEnd = simulation_width - 1,
        yStart = simulation_height - 1,
        yEnd = 0,
        incrementX = 1,
        incrementY = -1
    }

    o.updateDataReversed =
    {
        xStart = simulation_width - 1,
        xEnd = 0,
        yStart = simulation_height - 1,
        yEnd = 0,
        incrementX = -1,
        incrementY = -1
    }

    -- We will create numThreads threads
    o.simulation_thread = love.thread.newThread("src/particle_sim/simulateFromThread.lua")
    o.simulation_thread:start(chunkData, {}, ParticleDefinitionsHandler.particle_data,
        ParticleDefinitionsHandler.text_to_id_map)

    o.quadData = { width = o.window_width, height = o.simulation_height, imageData = o.quad.imageData }

    setmetatable(o, self)
    return o
end

function ParticleSimulation:update()
    if self.clock then
        self:updateFrom(self.updateData)
    else
        self:updateFrom(self.updateDataReversed)
    end
end

function ParticleSimulation:updateFrom(updateData)
    self.channel:push({ updateData = updateData, clock = self.clock })
    self.chunkChannel:demand() -- A thread is done

    self.clock = not self.clock
end

function ParticleSimulation:render()
    local function pixels(x, y, r, g, b, a)
        local index = self.chunk:index(x, y)
        local particle = self.simulaton_buffer_ptr[index]
        local color = ParticleDefinitionsHandler:getParticleData(particle.type).color

        return color.r, color.g, color.b, color.a
    end

    self.quad.imageData:mapPixel(pixels)
    self.quad:render(0, 0)
end

return ParticleSimulation
