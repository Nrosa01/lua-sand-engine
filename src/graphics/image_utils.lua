local ffi = require("ffi")
local clear = require "table.clear"

-- Reescales an image to a new size
-- If downscaled, it uses a point filter (nearest neighbor)
-- If upscaled, it uses a linear filter
-- This could be done faster with multiple threads
---@param image_data love.ImageData
---@param new_size_x number
---@param new_size_y number
---@return love.ImageData
local function resize(image_data, new_size_x, new_size_y)
    local raw = ffi.cast("uint8_t*", image_data:getFFIPointer())
    local raw_size_x = image_data:getWidth()
    local raw_size_y = image_data:getHeight()

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

local function distance(a, b)
    local sum = 0
    for i = 1, #a do
        local diff = math.abs(a[i] - b[i])
        sum = sum + diff
    end
    return sum
end

local function average(clusterIndices, pixel_buffer)
    local centroid = { 0, 0, 0, 0 }
    local count = 0
    for _, index in ipairs(clusterIndices) do
        for i = 1, 4 do
            centroid[i] = centroid[i] + pixel_buffer[index + i - 1]
        end
        count = count + 1
    end

    for i = 1, 4 do
        centroid[i] = centroid[i] / count
    end

    return centroid
end


local function distance_using_buffer(pixel_buffer, index, centroid)
    local sum = 0
    for i = 1, 4 do
        local diff = math.abs(pixel_buffer[index + i - 1] - centroid[i])
        sum = sum + diff
    end
    return sum
end

local function kmeans(pixel_buffer, buffer_size, num_clusters, sample)
    -- Initialize clusters with random pixels
    local pixel_count = buffer_size / 4

    local clusters = {}
    for i = 1, num_clusters do
        clusters[i] = { centroid = sample[i], pixels = {} }
    end

    local changed = true
    while changed do
        
        -- Refactor: Assign each pixel to the closest cluster
        for index = 0, buffer_size, 4 do
            local min_distance = math.huge
            local min_cluster
            for _, cluster in ipairs(clusters) do
                local dist = distance_using_buffer(pixel_buffer, index, cluster.centroid)
                if dist < min_distance then
                    min_distance = dist
                    min_cluster = cluster
                end
            end

            table.insert(min_cluster.pixels, index) -- Store the index of the pixel
        end

        -- Refactor: Recalculate centroids and check for changes
        changed = false
        for _, cluster in ipairs(clusters) do
            local new_centroid = average(cluster.pixels, pixel_buffer)
            if distance(cluster.centroid, new_centroid) > 0.01 then
                cluster.centroid = new_centroid
                --cluster.pixels = {}
                clear(cluster.pixels)
                changed = true
            end
        end
    end

    return clusters
end

local function getSample(image, num_colors)
    local resized = resize(image, 32, 32)

    local sample = {}

    local dimX, dimY = resized:getDimensions()

    for y = 0, dimX - 1 do
        for x = 0, dimY - 1 do
            local r, g, b, a = resized:getPixel(x, y)
            table.insert(sample, { r, g, b, a })
        end
    end

    -- Remove colors that are too similar
    local i = 1
    local threshold = 0.2
    while i <= #sample do
        local color = sample[i]
        local j = i + 1
        while j <= #sample do
            local other = sample[j]
            if distance(color, other) < threshold then
                table.remove(sample, j)

                -- If table size is already num_colors, we can stop
                if #sample == num_colors then
                    return sample
                end
            else
                j = j + 1
            end
        end
        i = i + 1
    end

    -- Count the times each color appears
    local counts = {}
    for _, color in ipairs(sample) do
        local count = counts[color]
        if count then
            counts[color] = count + 1
        else
            counts[color] = 1
        end
    end

    -- Sort the colors by frequency
    local sorted = {}
    for color, count in pairs(counts) do
        table.insert(sorted, { color = color, count = count })
    end

    table.sort(sorted, function(a, b) return a.count > b.count end)

    -- Return the most frequent colors
    local result = {}
    for i = 1, num_colors do
        table.insert(result, sorted[i].color)
    end

    -- Multiply each color by 255
    for _, color in ipairs(result) do
        for i = 1, 4 do
            color[i] = color[i] * 255
        end
    end

    return result
end

local function quantize(image, num_colors)
    local width, height = image:getDimensions()

    local raw = ffi.cast("uint8_t*", image:getFFIPointer())
    local raw_size = width * height * 4

    -- Perform k-means clustering
    local clusters = kmeans(raw, raw_size, num_colors, getSample(image, num_colors))

    -- Create a new image with quantized colors
    local new_image_data = love.image.newImageData(width, height)
    local raw_new = ffi.cast("uint8_t*", new_image_data:getFFIPointer())

    for index = 0, raw_size, 4 do
        local min_distance = math.huge
        local min_cluster
        for _, cluster in ipairs(clusters) do
            local dist = distance_using_buffer(raw, index, cluster.centroid)
            if dist < min_distance then
                min_distance = dist
                min_cluster = cluster
            end
        end

        local color = min_cluster.centroid
        raw_new[index] = color[1]
        raw_new[index + 1] = color[2]
        raw_new[index + 2] = color[3]
        raw_new[index + 3] = color[4]
    end

    return new_image_data
end


local functions =
{
    resize = resize,
    quantize = quantize
}

return functions
