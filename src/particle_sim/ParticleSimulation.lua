local ffi = require("ffi")
require("Particle")
local Quad = require("Quad")
local ParticleChunk = require("particle_chunk")
require("love.system")
local CheckerGrid = require("CheckerGrid")

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
local ParticleSimulation = {}

ParticleSimulation.__index = ParticleSimulation

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
        gridSize                         = 4 -- TODO: Algorithm to find this numbers
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

    -- Build update data
    local numThreads = math.min(love.system.getProcessorCount(), o.gridSize * o.gridSize)
    -- numThreads = 1

    -- We will create numThreads threads
    for row = 1, numThreads do
        o.threads[row] = love.thread.newThread("src/particle_sim/simulateFromThread.lua")
        o.threads[row]:start(chunkData, ParticleDefinitionsHandler.particle_data, o.quad.imageData, row)
        o.threadChannels[row] = love.thread.getChannel("threadChannel" .. row)
    end

    -- We will divide the world in 4*4 chunks regardless of the number of threads
    local gridSize = o.gridSize -- Default to a 4x4 grid
    local xStep = math.floor(simulation_width / gridSize)
    local yStep = math.floor(simulation_height / gridSize)

    for row = 1, gridSize do
        o.updateData[row] = {}
        for col = 1, gridSize do
            o.updateData[row][col] = {
                xStart = (row - 1) * xStep,
                xEnd = row * xStep - 1,
                yStart = (col - 1) * yStep,
                yEnd = col * yStep - 1,
                increment = 1
            }
        end
    end

    local table = {}

    local iterator = 1
    -- 1

    -- 2
    for row = 2, gridSize, 2 do
        for col = 1, gridSize, 2 do
            table[iterator] = o.updateData[row][col]
            iterator = iterator + 1
        end
    end

    -- 1
    for row = 1, gridSize, 2 do
        for col = 2, gridSize, 2 do
            table[iterator] = o.updateData[row][col]
            iterator = iterator + 1
        end
    end

    -- 3
    for row = 1, gridSize, 2 do
        for col = 1, gridSize, 2 do
            table[iterator] = o.updateData[row][col]
            iterator = iterator + 1
        end
    end

    -- 4
    for row = 2, gridSize, 2 do
        for col = 2, gridSize, 2 do
            table[iterator] = o.updateData[row][col]
            iterator = iterator + 1
        end
    end

    local t2 = {}
    iterator = 1


    -- 2
    for row = gridSize, 1, -2 do
        for col = gridSize, 1, -2 do
            t2[iterator] =
            {
                xStart = o.updateData[row][col].xEnd,
                xEnd = o.updateData[row][col].xStart,
                yStart = o.updateData[row][col].yEnd,
                yEnd = o.updateData[row][col].yStart,
                increment = -1
            }
            iterator = iterator + 1
        end
    end

    -- 1
    for row = gridSize - 1, 1, -2 do
        for col = gridSize - 1, 1, -2 do
            t2[iterator] =
            {
                xStart = o.updateData[row][col].xEnd,
                xEnd = o.updateData[row][col].xStart,
                yStart = o.updateData[row][col].yEnd,
                yEnd = o.updateData[row][col].yStart,
                increment = -1
            }
            iterator = iterator + 1
        end
    end

    -- 3
    for row = gridSize, 1, -2 do
        for col = gridSize - 1, 1, -2 do
            t2[iterator] =
            {
                xStart = o.updateData[row][col].xEnd,
                xEnd = o.updateData[row][col].xStart,
                yStart = o.updateData[row][col].yEnd,
                yEnd = o.updateData[row][col].yStart,
                increment = -1
            }
            iterator = iterator + 1
        end
    end

    -- 4
    for row = gridSize - 1, 1, -2 do
        for col = gridSize, 1, -2 do
            t2[iterator] =
            {
                xStart = o.updateData[row][col].xEnd,
                xEnd = o.updateData[row][col].xStart,
                yStart = o.updateData[row][col].yEnd,
                yEnd = o.updateData[row][col].yStart,
                increment = -1
            }
            iterator = iterator + 1
        end
    end


    o.updateData = table
    o.updateDataReversed = t2

    local updateData = CheckerGrid(gridSize, gridSize, simulation_width, simulation_height, false)

    local updateDataReversed = CheckerGrid(gridSize, gridSize, simulation_width, simulation_height, true)

    -- Let's compare the two to see if they are the same

    local failed = false
    for row = 1, #updateData do
        -- compare every updateData field to o.updateData
        -- They should be the same (and they should have the same fields)
        local updateDataField = updateData[row]
        local oUpdateDataField = o.updateData[row]

        for k, v in pairs(updateDataField) do
            if v ~= oUpdateDataField[k] then
                print("Error: updateData and o.updateData are not the same")
                print("updateDataField: " .. k .. " " .. v)
                print("o.updateDataField: " .. k .. " " .. oUpdateDataField[k])
                failed = true
            end
        end
    end

    -- Close the program if failed
    if failed then
        love.event.quit()
    end

    for row = 1, #updateDataReversed do
        -- compare every updateData field to o.updateData
        -- They should be the same (and they should have the same fields)
        local updateDataField = updateDataReversed[row]
        local oUpdateDataField = o.updateDataReversed[row]

        for k, v in pairs(updateDataField) do
            if v ~= oUpdateDataField[k] then
                print("Error: updateDataReversed and o.updateDataReversed are not the same")
                print("updateDataReversed: " .. k .. " " .. v)
                print("o.updateDataReversed: " .. k .. " " .. oUpdateDataField[k])
                failed = true
            end
        end
    end

    -- Close the program if failed
    if failed then
        love.event.pause()
    end


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

function ParticleSimulation:setBuffers()
    if self.clock then
        self.chunk.read_matrix = self.simulaton_buffer_front_ptr
        self.chunk.write_matrix = self.simulaton_buffer_back_ptr
    else
        self.chunk.read_matrix = self.simulaton_buffer_back_ptr
        self.chunk.write_matrix = self.simulaton_buffer_front_ptr
    end
end

function ParticleSimulation:setParticle(x, y, particleType)
    if self.chunk:isInside(x, y) then
        local index = self.chunk:index(x, y)
        self.simulaton_buffer_front_ptr[index].type = particleType
        self.simulaton_buffer_back_ptr[index].type = particleType
    end
end

function ParticleSimulation:update()
    if self.clock then
        self:updateFrom(
            self.updateData,
            self.simulation_buffer_front_bytecode,
            self.simulation_buffer_back_bytecode)
        self:updateBuffers(
            self.updateData,
            self.simulation_buffer_front_bytecode,
            self.simulation_buffer_back_bytecode)
    else
        self:updateFrom(
            self.updateDataReversed,
            self.simulation_buffer_back_bytecode,
            self.simulation_buffer_front_bytecode)
        self:updateBuffers(
            self.updateDataReversed,
            self.simulation_buffer_back_bytecode,
            self.simulation_buffer_front_bytecode)
    end
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

    self.clock = not self.clock
end

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
    love.graphics.setColor(1, 1, 1, 1)
end

return ParticleSimulation
