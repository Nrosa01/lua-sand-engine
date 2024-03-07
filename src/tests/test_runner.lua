local function runner()
    require("src.tests.test_grid_thread_comp")
    require("tests/test_queue")

    print("All tests passed")
end

return runner