local function runner()
    require("tests/test_gridCoreSize")
    require("tests/test_queue")

    print("All tests passed")
end

return runner