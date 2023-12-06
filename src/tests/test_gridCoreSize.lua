local computeGridSizeAndThreads = require("computeGridAndThreads")


local function test_computeGridSizeAndThreads()
    local function assertCase(actual, expected, testIndex, testVariable)
        if actual ~= expected then
            error("Test case " .. testIndex .. " failed: Incorrect " .. testVariable .. ": Expected " .. expected .. ", but got " .. actual )
        end
    end

    -- Test case 1
    local gridSize, numThreads = computeGridSizeAndThreads(100)
    assertCase(gridSize, 2, 1, "gridSize")
    assertCase(numThreads, 2, 1, "numThreads")

    -- Test case 2
    gridSize, numThreads = computeGridSizeAndThreads(800)
    assertCase(gridSize, 4, 2, "gridSize")
    assertCase(numThreads, 8, 2, "numThreads")

    -- Test case 3
    gridSize, numThreads = computeGridSizeAndThreads(400)
    assertCase(gridSize, 4, 3, "gridSize")
    assertCase(numThreads, 8, 3, "numThreads")

    -- Test case 4
    gridSize, numThreads = computeGridSizeAndThreads(50) -- Monothreaded
    assertCase(gridSize, 1, 4, "gridSize")
    assertCase(numThreads, 1, 4, "numThreads")

    -- Test case 5
    gridSize, numThreads = computeGridSizeAndThreads(100, 2)
    assertCase(gridSize, 2, 5, "gridSize")
    assertCase(numThreads, 2, 5, "numThreads")
    
    print("All test cases passed")
end

test_computeGridSizeAndThreads()
