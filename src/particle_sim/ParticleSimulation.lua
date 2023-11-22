local ffi = require("ffi")
require("Particle")
local Quad = require("Quad")
local ParticleChunk = require("particle_chunk")

---@class ParticleSimulation
---@field window_width number
---@field window_height number
---@field simulation_width number
---@field simulation_height number
---@field simulation_buffer_bytecode love.ByteData
---@field simulaton_buffer_ptr Particle*
---@field quad Quad
---@field thread love.thread
---@field chunk ParticleChunk
---@field clock boolean
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
        thread                     = love.thread.newThread("src/particle_sim/simulateFromThread.lua"),
        chunk                      = nil,
        clock                      = false
    }

    o.simulaton_buffer_ptr = ffi.cast("Particle*", o.simulation_buffer_bytecode:getFFIPointer())

    for i = 0, simulation_width * simulation_height - 1 do
        o.simulaton_buffer_ptr[i].type = 1
        o.simulaton_buffer_ptr[i].clock = false
    end

    local chunkData = { bytecode = o.simulation_buffer_bytecode, width = simulation_width, height = simulation_height }
    o.chunk = ParticleChunk:new(chunkData, o.quad)
    setmetatable(o, self)
    return o
end

function ParticleSimulation:update()
    local updateData =
    {
        xStart = 0,
        xEnd = self.simulation_width - 1,
        yStart = 0,
        yEnd = self.simulation_height - 1
    }

    local chunkData = { bytecode = self.simulation_buffer_bytecode, width = self.simulation_width, height = self.simulation_height, updateData = updateData }
    local quadData = { width = self.window_width, height = self.simulation_height, imageData = self.quad.imageData }
    local ParticleDefinitionsHandler = Encode(_G.ParticleDefinitionsHandler)

    self.thread:start(chunkData, quadData, ParticleDefinitionsHandler)
    self.thread:wait()

    self.clock = not self.clock
end

function ParticleSimulation:render()
    self.quad:render(0, 0)
end

return ParticleSimulation
