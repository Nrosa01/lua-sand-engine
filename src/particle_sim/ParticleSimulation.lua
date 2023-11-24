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
        }
    }

    setmetatable(o, self)
    return o
end

function ParticleSimulation:update()
    if self.chunk.clock then
        self.chunk:update(self.updateData)
    else
        self.chunk:update(self.updateDataReversed)
    end
end

function ParticleSimulation:render()
    self.quad.imageData:mapPixel(function(x, y, r, g, b, a)
        local color = ParticleDefinitionsHandler:getParticleData(self.chunk:getParticleType(x, y)).color
        return color.r, color.g, color.b, color.a
    end)
    self.quad:render(0, 0)
end

return ParticleSimulation
