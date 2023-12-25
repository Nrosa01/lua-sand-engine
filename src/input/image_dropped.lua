local image_utils = require "image_utils"
local EVENTS = require("src.core.observable_events")
local beholder = require("beholder")
local ffi = require("ffi")

local quantized = false

local image_dropped =
{}

beholder.observe(EVENTS.CANVAS_SIZE_CHANGED, function(canvas_size)
    image_dropped.canvas_size = canvas_size
end)

function image_dropped:construct(canvas_size, particle_simulation)
    self.particle_simulation = particle_simulation
    self.canvas_size = canvas_size
end

function image_dropped:file_dropped(file)
    if file:getExtension() == "png" then
        self:handle_png(file)
    end
end

function image_dropped:handle_png(file)
    local image_data = love.image.newImageData(file)
    image_data = image_utils.resize(image_data, self.canvas_size, self.canvas_size)
    if quantized then
        local centroids_table = {}
        image_data, centroids_table = image_utils.quantize(image_data,
            ParticleDefinitionsHandler:getRegisteredParticlesCount())
        self:paint_from_image_quantized(image_data, centroids_table)
    else
        self:paint_from_image_normal(image_data)
    end
end

---Function that returns a value that represents the distance between two colors
local function colourDistance(r1, g1, b1, r2, g2, b2)
    return math.abs(r1 - r2) + math.abs(g1 - g2) + math.abs(b1 - b2)
end

local function get_closest_particle(r, g, b, a, colors)
    -- Transparent pixel corresponds to empty space
    -- Black also corresponds to empty space unless there is another particle dark defined
    if a < 10 then
        return 1
    end

    local closest_id = 1
    local closest_distance = 1000000

    for i = 1, #colors do
        local color = colors[i]
        local distance = colourDistance(r, g, b, color.r, color.g, color.b)

        if distance <= closest_distance then
            closest_distance = distance
            closest_id = i
        end
    end

    return closest_id
end

local function getColors()
    local data = ParticleDefinitionsHandler.particle_data

    local colors = {}

    for i = 1, #data do
        local color = data[i].color
        colors[i] = { r = color.r, g = color.g, b = color.b, a = color.a }
    end

    return colors
end

--- Paints the image on the canvas
--- It takes a pixel colour and paints the particle whose colour is the closest to it
function image_dropped:paint_from_image_normal(image)
    local width = image:getWidth()
    local height = image:getHeight()
    local canvas_size = self.canvas_size

    local ratio_x = width / canvas_size
    local ratio_y = height / canvas_size

    local colors = getColors()

    for x = 0, width - 1 do
        for y = 0, height - 1 do
            local px, py = math.floor(x / ratio_x), math.floor(y / ratio_y)
            local r, g, b, a = image:getPixel(x, y)
            r = math.floor(r * 255)
            g = math.floor(g * 255)
            b = math.floor(b * 255)
            a = math.floor(a * 255)
            local particle_id = get_closest_particle(r, g, b, a, colors)
            self.particle_simulation:setParticle(px, py, particle_id)
        end
    end
end

-- Colours and centroids table are tables of the form: { {r, g, b, a}, ... }
-- I want the map to be of the form: { [r .. g .. b .. a] = particle_id, ... }
local function generate_map_from_centroids(colours, centroids_table)
    local map = {}
    local free_indexes = {} -- To keep track of assigned indices
    for i = 1, #colours do
        free_indexes[i] = true
    end

    for i, centroid in ipairs(centroids_table) do
        local minDistance = math.huge
        local particleID

        for j, color in ipairs(colours) do
            local distance = colourDistance(centroid.r, centroid.g, centroid.b, color.r, color.g, color.b)

            if distance < minDistance then
                minDistance = distance
                particleID = j -- Assign the particle ID of the closest centroid
            end
        end

        map[centroid.r .. centroid.g .. centroid.b .. centroid.a] = particleID
        free_indexes[particleID] = false
    end

    local free = {}
    for i = 1, #free_indexes do
        if free_indexes[i] then
            table.insert(free, i)
        end
    end

    free_indexes = free

    local dups = {}
    local pending_to_assign = {}
    -- We will iterate to find duplicates. These will be added to the dups list
    for i, centroid in ipairs(centroids_table) do
        local particleID = map[centroid.r .. centroid.g .. centroid.b .. centroid.a]
        
        if dups[particleID] == nil then
            dups[particleID] = {}
        else
            print("2. Duplicate found at index " .. i .. " with particleID " .. particleID .. " and centroid " .. centroid.r .. " " .. centroid.g .. " " .. centroid.b .. " " .. centroid.a .. "")
        end

        table.insert(dups[particleID], centroid)
    end

    -- dups whose size are greater than 1 are duplicates
    for particleID, collection in pairs(dups) do
        if #collection > 1 then
            -- We want to see which centroid is closer to the particle color
            local minDistance = math.huge
            local closestCentroid

            for _, centroid in ipairs(collection) do
                local distance = colourDistance(centroid.r, centroid.g, centroid.b, colours[particleID].r,
                    colours[particleID].g, colours[particleID].b)

                if distance < minDistance then
                    minDistance = distance
                    closestCentroid = centroid
                end
            end

            -- The centroid who arent the closest will be pending to assign
            for _, centroid in ipairs(collection) do
                if centroid ~= closestCentroid then
                    table.insert(pending_to_assign, centroid)
                end
            end
        end
    end

    -- Assign the pending centroids to the free indexes
    for _, centroid in ipairs(pending_to_assign) do
        -- Search the index who's closest to the centroid
        local minDistance = math.huge
        local closestIndex

        for _, index in ipairs(free_indexes) do
            local distance = colourDistance(centroid.r, centroid.g, centroid.b, colours[index].r, colours[index].g,
                colours[index].b)

            if distance < minDistance then
                minDistance = distance
                closestIndex = index
            end
        end

        map[centroid.r .. centroid.g .. centroid.b .. centroid.a] = closestIndex
        table.remove(free_indexes, closestIndex)
    end

    return map
end

function image_dropped:paint_from_image_quantized(image, centroids_table)
    local width, height = image:getWidth(), image:getHeight()
    local canvas_size = self.canvas_size

    local ratio_x = width / canvas_size
    local ratio_y = height / canvas_size

    local colors = getColors()
    local map = generate_map_from_centroids(colors, centroids_table)

    for x = 0, width - 1 do
        for y = 0, height - 1 do
            local px, py = math.floor(x / ratio_x), math.floor(y / ratio_y)
            local r, g, b, a = image:getPixel(x, y)
            r = math.floor(r * 255)
            g = math.floor(g * 255)
            b = math.floor(b * 255)
            a = math.floor(a * 255)
            local particle_id = map[r .. g .. b .. a]
            self.particle_simulation:setParticle(px, py, particle_id)
        end
    end
end

return image_dropped
