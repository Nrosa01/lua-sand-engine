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
        chunk                      = nil
    }

    o.simulaton_buffer_ptr = ffi.cast("Particle*", o.simulation_buffer_bytecode:getFFIPointer())

    for i = 0, simulation_width * simulation_height - 1 do
        o.simulaton_buffer_ptr[i].type = 1
        o.simulaton_buffer_ptr[i].clock = false
    end

    o.chunk = ParticleChunk:new(o.simulation_buffer_bytecode, simulation_width, simulation_height, o.quad)
    setmetatable(o, self)
    return o
end

function ParticleSimulation:update()
    self.thread:start(
        { bytecode = self.simulation_buffer_bytecode, width = self.simulation_width, height = self.simulation_height },
        self.quad.imageData, Encode(ParticleDefinitionsHandler))
    self.thread:wait()
end

function ParticleSimulation:render()
    self.quad:render(0, 0)
end

return ParticleSimulation
