local ffi = require("ffi")
local clear = require "table.clear"

-- I use in32_t because when adding the colors, they can overflow
-- And for some reason with int16_t it doesn't work
ffi.cdef [[
    typedef int32_t centroid[4];
]]

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

local function distance_between_centroids(a, b)
    local sum = 0
    for i = 0, 3 do
        local diff = math.abs(a[i] - b[i])
        sum = sum + diff
    end
    return sum
end

local function average(clusterIndices, pixel_buffer)
    local centroid = ffi.new("centroid", 0, 0, 0, 0)
    local count = #clusterIndices
    for _, index in ipairs(clusterIndices) do
        for i = 0, 3 do
            centroid[i] = centroid[i] + pixel_buffer[index + i]
        end
    end

    for i = 0, 3 do
        centroid[i] = math.floor(centroid[i] / count)
    end

    return centroid
end


local function distance_using_buffer(pixel_buffer, index, centroid)
    local sum = 0
    for i = 0, 3 do
        local diff = math.abs(pixel_buffer[index + i] - centroid[i])
        sum = sum + diff
    end
    return sum
end

local function kmeans(pixel_buffer, buffer_size, num_clusters, sample)
    local clusters = {}
    for i = 1, num_clusters do
        clusters[i] = { centroid = sample[i], pixels = {} }
    end

    local changed = true
    while changed do
        -- Assign each pixel to the closest cluster, just that
        -- Complexity: O(n * k) where n is the number of pixels and k is the number of clusters
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

        -- Recalculate centroids and check for changes
        -- Complexity: O(k * n) where n is the number of pixels and k is the number of clusters
        changed = false
        for _, cluster in ipairs(clusters) do
            local new_centroid = average(cluster.pixels, pixel_buffer)
            if distance_between_centroids(cluster.centroid, new_centroid) > 0.01 then
                cluster.centroid = new_centroid
                --cluster.pixels = {} -- This creates more tables and don't reuse memory, but it's a little faster
                clear(cluster.pixels) -- This reuses the same table, but it's a little slower (still worthy to use, less time spent in GC)
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
            table.insert(sample, ffi.new("centroid", r * 255, g * 255, b * 255, a * 255))
        end
    end

    local filtered_sample = {}
    -- Given the distance formular is a-b, that means the maximum distance is 255 * 4 = 1020
    -- If we assume that the bigger the distance the more different the colors are, and we want to keep colours that are
    -- at least a 5% different, that means the threshold is 1020 * 0.05 = 51
    local threshold = 51

    local function filter(sample, threshold)
        -- Copy only the colors that are different enough to a new table
        -- I don't reusae the table because calling table.remove is slow (it has to shift all the elements)
        local filtered_sample = {}

        for i = 1, #sample do
            local color = sample[i]
            local unique = true
            for j = 1, #filtered_sample do
                local other_color = filtered_sample[j]
                if distance_between_centroids(color, other_color) < threshold then
                    unique = false
                    break
                end
            end

            if unique then
                table.insert(filtered_sample, color)
            end
        end

        return filtered_sample
    end

    filtered_sample = filter(sample, threshold)

    -- If the number of colors is less than the number of clusters, add random colors from the original sample
    -- This is because the kmeans algorithm needs at least as many samples as clusters
    for i = #filtered_sample + 1, num_colors do
        local random_index = math.random(1, #sample)
        table.insert(filtered_sample, sample[random_index])
    end

    -- Table that contains the number of times each color appears
    -- Keys are literally the color concatenated as a string
    -- Probably I could avoid this intermiate table if I create it before filtering the sample but whatever
    local count = {}
    for _, color in ipairs(filtered_sample) do
        local key = color[0] .. color[1] .. color[2] .. color[3]
        if count[key] then
            count[key] = count[key] + 1
        else
            count[key] = 1
        end
    end

    -- Thanks to the mighty power of lua supporting closures, I sort the samples by the number of times they appear
    table.sort(filtered_sample, function(a, b)
        local key_a = a[0] .. a[1] .. a[2] .. a[3]
        local key_b = b[0] .. b[1] .. b[2] .. b[3]
        return count[key_a] > count[key_b]
    end)

    return filtered_sample
end

local function quantize(image, num_colors)
    local width, height = image:getDimensions()

    local raw = ffi.cast("uint8_t*", image:getFFIPointer())
    local raw_size = width * height * 4

    -- Create a new image with quantized colors
    local new_image_data = love.image.newImageData(width, height)
    local raw_new = ffi.cast("uint8_t*", new_image_data:getFFIPointer())

    -- Perform k-means clustering
    local clusters = kmeans(raw, raw_size, num_colors, getSample(image, num_colors))

    -- Replace each pixel with the centroid of the cluster it belongs to
    -- I could perfectly harcode this inside the kmeans min_cluster search
    -- But I want to keep this readable (also I measure and this didn't affect performance in a noticeable way,
    -- I would have hardcoded it if it did lmao)
    for _, cluster in ipairs(clusters) do
        local cluster_color = cluster.centroid
        for _, index in ipairs(cluster.pixels) do
            raw_new[index] = math.floor(cluster_color[0])
            raw_new[index + 1] = math.floor(cluster_color[1])
            raw_new[index + 2] = math.floor(cluster_color[2])
            raw_new[index + 3] = math.floor(cluster_color[3])
        end
    end

    return new_image_data
end


local functions =
{
    resize = resize,
    quantize = quantize
}

return functions
