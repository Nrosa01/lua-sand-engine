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
        threads                    = {},
        chunk                      = nil,
        clock                      = false,
        updateData                 = {},
        updateDataReversed         = {},
        chunkData                  = {},
        quadData                   = {},
        channel                    = love.thread.getChannel("mainThreadChannel"),
        chunkChannel               = love.thread.getChannel("chunkChannel"),
        gridSize                   = 4
    }

    o.simulaton_buffer_ptr = ffi.cast("Particle*", o.simulation_buffer_bytecode:getFFIPointer())

    for i = 0, simulation_width * simulation_height - 1 do
        o.simulaton_buffer_ptr[i].type = 1
        o.simulaton_buffer_ptr[i].clock = false
    end

    local chunkData = { bytecode = o.simulation_buffer_bytecode, width = simulation_width, height = simulation_height }
    o.chunk = ParticleChunk:new(chunkData, {}, o.quad)

    -- Build update data
    local numThreads = love.system.getProcessorCount()

    -- We will create numThreads threads
    for i = 1, numThreads do
        o.threads[i] = love.thread.newThread("src/particle_sim/simulateFromThread.lua")
        o.threads[i]:start(chunkData, {}, ParticleDefinitionsHandler.particle_data,
            ParticleDefinitionsHandler.text_to_id_map, i)
    end

    -- We will divide the world in 4*4 chunks regardless of the number of threads
    local gridSize = o.gridSize -- Default to a 4x4 grid
    local xStep = math.floor(simulation_width / gridSize)
    local yStep = math.floor(simulation_height / gridSize)

    for i = 1, gridSize do
        o.updateData[i] = {}
        for j = 1, gridSize do
            o.updateData[i][j] = {
                xStart = (i - 1) * xStep,
                xEnd = i * xStep - 1,
                yStart = (j - 1) * yStep,
                yEnd = j * yStep - 1,
                increment = 1
            }
        end
    end

    local table = {}

    local iterator = 1
    -- 1

    -- 1
    for i = 1, gridSize, 2 do
        for j = 1, gridSize, 2 do
            table[iterator] = o.updateData[i][j]
            iterator = iterator + 1
        end
    end

    -- 2
    for i = 2, gridSize, 2 do
        for j = 2, gridSize, 2 do
            table[iterator] = o.updateData[i][j]
            iterator = iterator + 1
        end
    end

    -- 3
    for i = 2, gridSize, 2 do
        for j = 1, gridSize, 2 do
            table[iterator] = o.updateData[i][j]
            iterator = iterator + 1
        end
    end

    -- 4
    for i = 1, gridSize, 2 do
        for j = 2, gridSize, 2 do
            table[iterator] = o.updateData[i][j]
            iterator = iterator + 1
        end
    end

    o.updateData = table

    -- Updatedata odds will be the reverse
    for i = 1, #o.updateData do
        o.updateDataReversed[i] = {
            xStart = o.updateData[i].xEnd,
            xEnd = o.updateData[i].xStart,
            yStart = o.updateData[i].yEnd,
            yEnd = o.updateData[i].yStart,
            increment = -1
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
    self:updateFrom(self.updateData)
    self:updateFrom(self.updateDataReversed)
end

function ParticleSimulation:updateFrom(updateData)
    -- Get num of threads supported
    local updateDataCount = #updateData
    local threadCount = #self.threads

    -- Init all threads
    for i = 1, threadCount do
        self.channel:push({ updateData = updateData[i], clock = self.clock })
    end

    -- Wait for any of them to finish, then run another until it's all done
    for i = threadCount + 1, updateDataCount do
        self.chunkChannel:demand() -- A thread is done
        self.channel:push({ updateData = updateData[i], clock = self.clock })
    end

    -- Wait for the rest of the threads to finish
    for i = 1, threadCount do
        self.chunkChannel:demand() -- A thread is done
    end

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

    -- Draw grid
    love.graphics.setColor(1, 0.1, 0.1, 0.25)
    for i = 1, self.gridSize - 1 do
        love.graphics.line(i * self.window_width / self.gridSize, 0, i * self.window_width / self.gridSize,
            self.window_height)
        love.graphics.line(0, i * self.window_height / self.gridSize, self.window_width,
            i * self.window_height / self.gridSize)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return ParticleSimulation
