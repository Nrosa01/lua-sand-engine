local function createGridCell(row, col, xStep, yStep, inverted)
    local cell = {
        xStart = (row - 1) * xStep,
        xEnd = row * xStep - 1,
        yStart = (col - 1) * yStep,
        yEnd = col * yStep - 1,
        increment = 1
    }

    if inverted then
        cell.xStart, cell.xEnd = cell.xEnd, cell.xStart
        cell.yStart, cell.yEnd = cell.yEnd, cell.yStart
        cell.increment = -1
    end

    return cell
end

local function GridStructure(grid_sides_x, grid_sides_y, width, height, inverted)
    local temp_table = {}
    
    local xStep = math.floor(width / grid_sides_x)
    local yStep = math.floor(height / grid_sides_y)

    for row = 1, grid_sides_x do
        temp_table[row] = {}
        for col = 1, grid_sides_y do
            temp_table[row][col] = createGridCell(row, col, xStep, yStep, inverted)
        end
    end

    -- Now we reorder the table in a checkerboard pattern. I have no idea
    -- how to do this in a more elegant way
    local table = {}
    local iterator = 1

    local loop_data = {
        {2, 1, grid_sides_x, grid_sides_y, 2},
        {1, 2, grid_sides_x, grid_sides_y, 2},
        {1, 1, grid_sides_x, grid_sides_y, 2},
        {2, 2, grid_sides_x, grid_sides_y, 2},
    }

    local loop_data_inverted = {
        {grid_sides_x, grid_sides_y, 1, 1, -2},
        {grid_sides_x - 1, grid_sides_y - 1, 1, 1, -2},
        {grid_sides_x, grid_sides_y - 1, 1, 1, -2},
        {grid_sides_x - 1, grid_sides_y, 1, 1, -2},
    }

    if inverted then
        loop_data = loop_data_inverted
    end

    for _, data in ipairs(loop_data) do
        local row_start = data[1]
        local col_start = data[2]
        local row_end = data[3]
        local col_end = data[4]
        local increment = data[5]

        for row = row_start, row_end, increment do
            for col = col_start, col_end, increment do
                table[iterator] = temp_table[row][col]
                iterator = iterator + 1
            end
        end
    end

    return table
end

return GridStructure