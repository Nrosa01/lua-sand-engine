-- Creates a path for the require function to search for files in the src folder and subfolders recursively
local function createPath()
    local path = love.filesystem.getRequirePath() .. ";src/?.lua;libs/?.lua;src/gui/?.lua;"
    local srcPath = "src"
    local files = love.filesystem.getDirectoryItems(srcPath)
    for _, file in ipairs(files) do
        local file = srcPath .. "/" .. file
        if love.filesystem.getInfo(file, "directory") then
        path = path .. ";" .. file .. "/?.lua"
        end
    end

    return path
end

love.filesystem.setRequirePath(createPath())

-- Set filtering to nearest to avoid blurring
love.graphics.setDefaultFilter("nearest", "nearest")

Libs = {}