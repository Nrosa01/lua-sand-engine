local ffi = require("ffi")
require("particle")
local Quad = require("quad")
local Commands = require("job_commands")

local CheckerGrid = require("checker_grid")
local computeGridSizeAndThreads = require("grid_thread_comp")

---@class ParticleSimulation
---@field public simulation_width number
---@field public simulation_height number
---@field private simulation_buffer_front_bytecode love.ByteData
---@field private simulation_buffer_back_bytecode love.ByteData
---@field private quad Quad
---@field private threads table
---@field public clock boolean
---@field private updateData table
---@field private updateDataReversed table
---@field private channel love.Channel
---@field private commonThreadChannel love.Channel
---@field private threadChannels table
---@field private gridSize number
---@field private pcount number
---@field private simulation_tick number -- This stores the number of times the simulation has been updated
local ParticleSimulation = {}

ParticleSimulation.__index = ParticleSimulation

-- Todo, refactor so simulation width and height are not needed, only size
-- This is because it's easier to do multithreading
function ParticleSimulation:new(window_width, window_height, simulation_width, simulation_height)
    -- I guess here I define fields
    local o =
    {
        simulation_width                 = simulation_width,
        simulation_height                = simulation_height,
        simulation_buffer_front_bytecode = love.data.newByteData(simulation_width * simulation_height *
            ffi.sizeof("Particle")),
        simulation_buffer_back_bytecode  = love.data.newByteData(simulation_width * simulation_height *
            ffi.sizeof("Particle")),
        quad                             = Quad:new(window_width, window_height, simulation_width, simulation_height),
        threads                          = {},
        clock                            = false,
        updateData                       = {},
        updateDataReversed               = {},
        channel                          = love.thread.getChannel("mainThreadChannel"),
        commonThreadChannel              = love.thread.getChannel("commonThreadChannel"),
        threadChannels                   = {},
        gridSize                         = 0,
        pcount                           = 0,
        simulation_tick                  = 0
    }

    local simulaton_buffer_front_ptr = ffi.cast("Particle*", o.simulation_buffer_front_bytecode:getFFIPointer())
    local simulaton_buffer_back_ptr = ffi.cast("Particle*", o.simulation_buffer_back_bytecode:getFFIPointer())

    for row = 0, simulation_width * simulation_height - 1 do
        simulaton_buffer_front_ptr[row].type = 1
        simulaton_buffer_front_ptr[row].clock = false
        simulaton_buffer_back_ptr[row].type = 1
        simulaton_buffer_back_ptr[row].clock = false
    end

    local gridSize, thread_count = computeGridSizeAndThreads(simulation_width)
    o.gridSize = gridSize

    for row = 1, thread_count do
        o.threads[row] = love.thread.newThread("src/jobs/thread_job.lua")
        o.threads[row]:start(simulation_width, simulation_height, ParticleDefinitionsHandler.particle_data,
            o.quad.imageData, row)
        o.threadChannels[row] = love.thread.getChannel("threadChannel" .. row)
    end

    o.updateData = CheckerGrid(o.gridSize, o.gridSize, simulation_width, simulation_height, false)
    o.updateDataReversed = CheckerGrid(o.gridSize, o.gridSize, simulation_width, simulation_height, true)

    setmetatable(o, self)
    return o
end

function ParticleSimulation:file_dropped(file)
    if file:getExtension() == "lua" then
        for _, v in ipairs(self.threadChannels) do
            v:push(file)
        end
    end
end

-- Helper method for the simulation, they work the same way as the ones in ParticleChunk clas
function ParticleSimulation:index(x, y)
    return x + y * self.simulation_width
end

-- Helper method for the simulation, they work the same way as the ones in ParticleChunk clas
function ParticleSimulation:isInside(x, y)
    return x >= 0 and x < self.simulation_width and y >= 0 and y < self.simulation_height
end

function ParticleSimulation:setParticle(x, y, particleType)
    if not self:isInside(x, y) then
        return
    end

    local index = self:index(x, y)

    -- We set clock to false so the particle gets updated in the next frame
    local write_matrix = ffi.cast("Particle*", self:get_write_buffer():getFFIPointer())
    write_matrix[index].type = particleType
    write_matrix[index].clock = false

    local read_matrix = ffi.cast("Particle*", self:get_read_buffer():getFFIPointer())
    read_matrix[index].type = particleType
    read_matrix[index].clock = false

    -- We want to update this because render texture only updates when the simulation updates
    -- So if the simulation is paused, we wouldn't see the particle. We have to force this

    -- You might wonder "we could separate the render texture from the simulation"
    -- Yes we could, but that would mean to run another loop and I want maximum performance
    -- Texture only changes when particle changes, including here
    local color = ParticleDefinitionsHandler:getParticleData(particleType).color
    index = index * 4
    local imageDataPtr = ffi.cast("uint8_t*", self.quad.imageData:getFFIPointer())
    imageDataPtr[index] = color.r
    imageDataPtr[index + 1] = color.g
    imageDataPtr[index + 2] = color.b
    imageDataPtr[index + 3] = color.a
end

function ParticleSimulation:get_read_buffer()
    return self.clock and self.simulation_buffer_front_bytecode or self.simulation_buffer_back_bytecode
end

function ParticleSimulation:get_write_buffer()
    return self.clock and self.simulation_buffer_back_bytecode or self.simulation_buffer_front_bytecode
end

function ParticleSimulation:updateSimulation()
    local data = self.clock and self.updateData or self.updateDataReversed
    self:doThreadedJob(data, self:get_read_buffer(), self:get_write_buffer(), Commands.TICK_SIMULATION)
end

function ParticleSimulation:updateBuffers()
    local data = self.clock and self.updateData or self.updateDataReversed
    self.pcount = self:doThreadedJob(data, self:get_read_buffer(), self:get_write_buffer(), Commands.UPDATE_BUFFERS)
end

function ParticleSimulation:update()
    self:updateSimulation()
    self:updateBuffers()
    self.clock = not self.clock
    self.simulation_tick = self.simulation_tick + 1
end

function ParticleSimulation:doThreadedJob(updateData, read, write, command)
    for row = 1, #updateData do
        self.channel:push({
            command = command,
            data =
            {
                updateData = updateData[row],
                clock = self.clock,
                read = read,
                write = write,
                simulation_tick = self.simulation_tick
            }
        })
    end

    local p_count = 0

    for _, _ in ipairs(updateData) do
        local count = self.commonThreadChannel:demand()
        p_count = p_count + count
    end

    return p_count
end

_G.TESTFlag = true

function ParticleSimulation:draw()
    self.quad:render(0, 0)

    -- Draw grid
    if not TESTFlag then
        Gizmos:drawGrid(self.gridSize, self.gridSize, { 0.1, 1, 0.1, 0.25 })
    end

    Gizmos:drawText("Particle Count: " .. self.pcount, 10, 40, { 1, 0, 0, 1 })
end

return ParticleSimulation
