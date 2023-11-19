require "src"

local Quad = require "src/libs/quad"

local myQuad;

function love.load()
    -- Set windows size to 800*800
    love.window.setMode(800, 800)
    -- create quad with the same size as the window getting the size from the window
    myQuad = Quad:new(love.graphics.getWidth(), love.graphics.getHeight(), 100, 100)
end

function love.draw()
    love.graphics.print("Hello World", 400, 300)
    myQuad:render(0, 0)
end

function love.filedropped(file)
    -- Only run if the file is a lua file
    if file:getExtension() == "lua" then
        local fileRunner = require "fileRunner"
        fileRunner(file)
    else
        -- Show an error message as a popup (later I should make this a toast)
        local message = "The file you dropped is not a lua file"
        love.window.showMessageBox("Error", message, "error")
    end
end

