local computeGridSizeAndThreads = require("computeGridAndThreads")


local function test_computeGridSizeAndThreads()
    -- Test case 1
    local gridSize, numThreads = computeGridSizeAndThreads(100)
    assert(gridSize == 2, "Test case 1 failed: Incorrect gridSize " .. gridSize .. " " .. numThreads)
    assert(numThreads == 2, "Test case 1 failed: Incorrect numThreads " .. gridSize .. " " .. numThreads)

    -- Test case 2
    gridSize, numThreads = computeGridSizeAndThreads(800)
    assert(gridSize == 4, "Test case 2 failed: Incorrect gridSize " .. gridSize .. " " .. numThreads)
    assert(numThreads == 8, "Test case 2 failed: Incorrect numThreads " .. gridSize .. " " .. numThreads)

    -- Test case 3
    gridSize, numThreads = computeGridSizeAndThreads(400)
    assert(gridSize == 4, "Test case 3 failed: Incorrect gridSize " .. gridSize .. " " .. numThreads)
    assert(numThreads == 8, "Test case 3 failed: Incorrect numThreads " .. gridSize .. " " .. numThreads)

    print("All test cases passed")
end

test_computeGridSizeAndThreads()
