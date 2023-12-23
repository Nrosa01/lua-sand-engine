local Gizmos = {}

Gizmos.__index = Gizmos

--- Draws a grid on the screen
--- @param width number 
--- @param height number
--- @param rgba table
function Gizmos:drawGrid(width, height, rgba)
    local window_width, window_height = love.graphics.getDimensions()

    love.graphics.setColor(rgba)
    for row = 1, width - 1 do
        love.graphics.line(row * window_width / width, 0,
            row * window_width / width, window_height)
    end

    for row = 1, height - 1 do
        love.graphics.line(0, row * window_height / height, window_width,
            row * window_height / height)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

--- Simple function to draw colored text on the screen. It lacks many functions from love.graphics.print
---@param text string
---@param x number
---@param y number
---@param rgba table
function Gizmos:drawText(text, x, y, rgba)
    love.graphics.setColor(rgba)
    love.graphics.print(text, x, y)
    love.graphics.setColor(1, 1, 1, 1)
end

return Gizmos