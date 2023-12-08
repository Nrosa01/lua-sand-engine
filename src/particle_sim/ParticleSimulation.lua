local ffi = require("ffi")
require("Particle")
local Quad = require("Quad")
local ParticleChunk = require("particle_chunk")
require("love.system")
local CheckerGrid = require("CheckerGrid")
local computeGridSizeAndThreads = require("computeGridAndThreads")
local queue = require("queue")

---@class ParticleSimulation
---@field window_width number
---@field window_height number
---@field simulation_width number
---@field simulation_height number
---@field simulation_buffer_front_bytecode love.ByteData
---@field simulaton_buffer_front_ptr Particle*
---@field simulation_buffer_back_bytecode love.ByteData
---@field simulaton_buffer_back_ptr Particle*
---@field quad Quad
---@field threads table
---@field chunk ParticleChunk
---@field clock boolean
---@field updateData table
---@field updateDataReversed table
---@field chunkData table
---@field quadData table
---@field channel love.Channel
---@field commonThreadChannel love.Channel
---@field threadChannels table
---@field gridSize number
---@field thread_count number
---@field command_queue Queue
local ParticleSimulation = {}

ParticleSimulation.__index = ParticleSimulation

-- Todo, refactor so simulation width and height are not needed, only size
-- This is because it's easier to do multithreading
function ParticleSimulation:new(window_width, window_height, simulation_width, simulation_height)
    -- I guess here I define fields
    local o =
    {
        window_width                     = window_width,
        window_height                    = window_height,
        simulation_width                 = simulation_width,
        simulation_height                = simulation_height,
        simulation_buffer_front_bytecode = love.data.newByteData(simulation_width * simulation_height *
            ffi.sizeof("Particle")),
        simulation_buffer_back_bytecode  = love.data.newByteData(simulation_width * simulation_height *
            ffi.sizeof("Particle")),
        simulaton_buffer_front_ptr       = nil,
        simulaton_buffer_back_ptr        = nil,
        quad                             = Quad:new(window_width, window_height, simulation_width, simulation_height),
        threads                          = {},
        chunk                            = nil,
        clock                            = false,
        updateData                       = {},
        updateDataReversed               = {},
        chunkData                        = {},
        quadData                         = {},
        channel                          = love.thread.getChannel("mainThreadChannel"),
        commonThreadChannel              = love.thread.getChannel("commonThreadChannel"),
        threadChannels                   = {},
        gridSize                         = 0,
        thread_count                     = 0,
        command_queue                    = queue:new(),
        pcount                           = 0
    }

    o.simulaton_buffer_front_ptr = ffi.cast("Particle*", o.simulation_buffer_front_bytecode:getFFIPointer())
    o.simulaton_buffer_back_ptr = ffi.cast("Particle*", o.simulation_buffer_back_bytecode:getFFIPointer())

    for row = 0, simulation_width * simulation_height - 1 do
        o.simulaton_buffer_front_ptr[row].type = 1
        o.simulaton_buffer_front_ptr[row].clock = false
        o.simulaton_buffer_back_ptr[row].type = 1
        o.simulaton_buffer_back_ptr[row].clock = false
    end

    local chunkData =
    {
        bytecode_read = o.simulation_buffer_front_bytecode,
        bytecode_write = o.simulation_buffer_back_bytecode,
        width = simulation_width,
        height = simulation_height
    }

    o.chunk = ParticleChunk:new(chunkData)

    o.gridSize, o.thread_count = computeGridSizeAndThreads(simulation_width)

    -- We will create numThreads threads
    for row = 1, o.thread_count do
        o.threads[row] = love.thread.newThread("src/particle_sim/simulateFromThread.lua")
        o.threads[row]:start(chunkData, ParticleDefinitionsHandler.particle_data, o.quad.imageData, row)
        o.threadChannels[row] = love.thread.getChannel("threadChannel" .. row)
    end

    o.updateData = CheckerGrid(o.gridSize, o.gridSize, simulation_width, simulation_height, false)
    o.updateDataReversed = CheckerGrid(o.gridSize, o.gridSize, simulation_width, simulation_height, true)

    -- We will create numThreads chunkData tables
    o.chunkData = {
        bytecode = o.simulation_buffer_front_bytecode,
        width = o.simulation_width,
        height = o.simulation_height
    }

    o.quadData = { width = o.window_width, height = o.simulation_height, imageData = o.quad.imageData }

    setmetatable(o, self)
    return o
end

_G.TESTFlag = false

function ParticleSimulation:send(file)
    for i, v in ipairs(self.threadChannels) do
        v:push(file)
    end
end

function ParticleSimulation:setParticle(x, y, particleType)
    -- if self.chunk:isInside(x, y) then
    self.command_queue:enqueue(function()
        self.chunk:setNewParticleById(x, y, particleType)
    end)

    -- Even if writing to the matrix is delayed, we still update this texture
    -- This is not reliable but rather for testing purposes
    local color = ParticleDefinitionsHandler:getParticleData(particleType).color
    local index = self.chunk:index(x, y) * 4
    local imageDataPtr = ffi.cast("uint8_t*", self.quad.imageData:getFFIPointer())
    imageDataPtr[index] = color.r
    imageDataPtr[index + 1] = color.g
    imageDataPtr[index + 2] = color.b
    imageDataPtr[index + 3] = color.a
end

function ParticleSimulation:get_write_buffer_ptr()
    if self.clock then
        return self.simulaton_buffer_back_ptr
    else
        return self.simulaton_buffer_front_ptr
    end
end

function ParticleSimulation:get_read_buffer_ptr()
    if self.clock then
        return self.simulaton_buffer_front_ptr
    else
        return self.simulaton_buffer_back_ptr
    end
end

function ParticleSimulation:get_read_buffer()
    if self.clock then
        return self.simulation_buffer_front_bytecode
    else
        return self.simulation_buffer_back_bytecode
    end
end

function ParticleSimulation:get_write_buffer()
    if self.clock then
        return self.simulation_buffer_back_bytecode
    else
        return self.simulation_buffer_front_bytecode
    end
end

function ParticleSimulation:updateSimulation(clock)
    local data = self.clock and self.updateData or self.updateDataReversed
    self:updateFrom(data, self:get_read_buffer(), self:get_write_buffer())
end

function ParticleSimulation:updateBuffersTmp(clock)
    local data = self.clock and self.updateData or self.updateDataReversed
    self:updateBuffers(data, self:get_read_buffer(), self:get_write_buffer())
end

function ParticleSimulation:execute_command_queue()
    while not self.command_queue:isEmpty() do
        local command = self.command_queue:dequeue()
        command()
    end
end

function ParticleSimulation:count()
    -- Count all particles from the read buffer
    local count = 0
    local read = self:get_read_buffer_ptr()
    for row = 0, self.simulation_width * self.simulation_height - 1 do
        if read[row].type ~= 1 then
            count = count + 1
        end
    end
    return count
end

function ParticleSimulation:post_simulation_update()
    -- Set chunk buffers
    self.chunk.read_matrix = self:get_read_buffer_ptr()
    self.chunk.write_matrix = self:get_write_buffer_ptr()

    -- We want to do all this queue workaround to avoid
    -- modifying the chunk from multiple threads
    self:execute_command_queue()

    self:updateBuffersTmp(self.clock)
    local count = self:count()
    
    if count < self.pcount then
        error("Particle count decreased")
    end
    
    self.pcount = count
    self.clock = not self.clock
end

function ParticleSimulation:update()
    local clock = self.clock
    self:updateSimulation(clock)
    self:post_simulation_update()
end

function ParticleSimulation:updateBuffers(updateData, read, write)
    -- Update read, write buffer and color buffer
    -- Get num of threads supported
    local updateDataCount = #updateData
    local threadCount = #self.threads

    -- Init all threads
    for row = 1, threadCount do
        self.channel:push({
            command = "UpdateBuffers",
            data =
            {
                updateData = updateData[row],
                read = read,
                write = write
            }
        })
    end

    -- Wait for any of them to finish, then run another until it's all done
    for row = threadCount + 1, updateDataCount do
        self.commonThreadChannel:demand() -- A thread is done
        self.channel:push({
            command = "UpdateBuffers",
            data =
            {
                updateData = updateData[row],
                read = read,
                write = write
            }
        })
    end

    -- Wait for the rest of the threads to finish
    for row = 1, threadCount do
        self.commonThreadChannel:demand() -- A thread is done
    end
end

function ParticleSimulation:updateFrom(updateData, read, write)
    -- Get num of threads supported
    local updateDataCount = #updateData
    local threadCount = #self.threads

    -- Init all threads
    for row = 1, threadCount do
        self.channel:push({
            command = "TickSimulation",
            data =
            {
                updateData = updateData[row],
                clock = self.clock,
                read = read,
                write = write
            }
        })
    end

    -- Wait for any of them to finish, then run another until it's all done
    for row = threadCount + 1, updateDataCount do
        self.commonThreadChannel:demand() -- A thread is done
        self.channel:push({
            command = "TickSimulation",
            data =
            {
                updateData = updateData[row],
                clock = self.clock,
                read = read,
                write = write
            }
        })
    end

    -- Wait for the rest of the threads to finish
    for row = 1, threadCount do
        self.commonThreadChannel:demand() -- A thread is done
    end
end

local draw_full_grid = false

function ParticleSimulation:render()
    self.quad:render(0, 0)

    -- Draw grid
    love.graphics.setColor(0.1, 1, 0.1, TESTFlag and 0 or 0.25)
    for row = 1, self.gridSize - 1 do
        love.graphics.line(row * self.window_width / self.gridSize, 0, row * self.window_width / self.gridSize,
            self.window_height)
        love.graphics.line(0, row * self.window_height / self.gridSize, self.window_width,
            row * self.window_height / self.gridSize)
    end

    -- draw full grid
    if draw_full_grid then
        love.graphics.setColor(0.1, 1, 0.1, TESTFlag and 0 or 0.25)
        for row = 1, self.simulation_width - 1 do
            love.graphics.line(row * self.window_width / self.simulation_width, 0,
                row * self.window_width / self.simulation_width, self.window_height)
        end

        for row = 1, self.simulation_height - 1 do
            love.graphics.line(0, row * self.window_height / self.simulation_height, self.window_width,
                row * self.window_height / self.simulation_height)
        end
    end

    -- Draw particle count
    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.print("Particle count: " .. self.pcount, 10, 40)
    love.graphics.setColor(1, 1, 1, 1)
end

return ParticleSimulation
