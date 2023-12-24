
local ffi = require("ffi")
local ffi = require("ffi")

-- Reescales an image to a new size
-- If downscaled, it uses a point filter (nearest neighbor)
-- If upscaled, it uses a linear filter
-- This could be done faster with multiple threads
---@param image_Data love.ImageData
---@param new_size_x number
---@param new_size_y number
---@return love.ImageData
local function resize(image_Data, new_size_x, new_size_y)
    local raw = ffi.cast("uint8_t*", image_Data:getFFIPointer())
    local raw_size_x = image_Data:getWidth()
    local raw_size_y = image_Data:getHeight()

    local new_image_data = love.image.newImageData(new_size_x, new_size_y)
    local raw_new = ffi.cast("uint8_t*", new_image_data:getFFIPointer())

    local x_ratio = raw_size_x / new_size_x
    local y_ratio = raw_size_y / new_size_y

    local new_size_x_4 = new_size_x * 4
    local raw_size_x_4 = raw_size_x * 4

    local floor = math.floor

    for y = 0, new_size_y - 1 do
        local y_floor = floor(y * y_ratio) * raw_size_x_4
        local new_index_base = y * new_size_x_4

        for x = 0, new_size_x - 1 do
            local x_floor = floor(x * x_ratio) * 4

            local index = new_index_base + x * 4
            local index_raw = y_floor + x_floor

            raw_new[index] = raw[index_raw]
            raw_new[index + 1] = raw[index_raw + 1]
            raw_new[index + 2] = raw[index_raw + 2]
            raw_new[index + 3] = raw[index_raw + 3]
        end
    end

    return new_image_data
end


local functions =
{
    resize = resize,
}

return functions
