-- Returns gridSize and numThreads given the size of the simulation

-- Preconditions:
-- ChunkSize == size / (gridSize * gridSize)
-- ChunkSize >= minChunkSize
-- (gridSize * gridSize) / 2 >= numProcessors (to avoid writing to the same buffer)
-- If we can't find a suitable gridSize, we decrease proccessors until we find one
-- Processor count must be and even number or 1

-- Algorithm:
-- We start with numProccesors
-- We get the smallest gridSize that satisfies the preconditions
-- If the gridSize produces chunks that aren't whole, we increase gridSize until it does or until chunkSize < minChunkSize
-- If we don't find a gridSize, we decrease numProcessors by 2 and repeat the process
local function computeGridSizeAndThreads(size, cores)
    local minChunkSize = 16
    local numProcessors = cores or love.system.getProcessorCount()

    while numProcessors > 0 do
        -- Get smallest gridSize
        local gridSize =  math.ceil(math.sqrt(numProcessors * 2))
        local chunkSize = size / (gridSize^2)

        -- Now we will increase gridSize by 1 until preconditions are satisfied
        -- (if they are already satisfied, we don't enter the loop)
        local is_whole = chunkSize % 1 == 0
        while chunkSize > minChunkSize and not is_whole do
            gridSize = gridSize + 1
            chunkSize = size / (gridSize^2)
            is_whole = chunkSize % 1 == 0
        end

        if chunkSize > minChunkSize and is_whole then
            return gridSize, numProcessors
        else
            numProcessors = numProcessors - 2
        end
    end
end

return computeGridSizeAndThreads