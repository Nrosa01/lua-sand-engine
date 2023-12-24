local image_utils = require "image_utils"
local EVENTS = require("src.core.observable_events")
local beholder = require("beholder")
local ffi = require("ffi")

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
    self:paint_from_image(image_data)
end

---Function that returns a value that represents the distance between two colors
local function colourDistance(r1, g1, b1, r2, g2, b2)
    return math.abs(r1 - r2) + math.abs(g1 - g2) + math.abs(b1 - b2)
end

local function get_closest_particle(r, g, b, a, colors)
    r = math.floor(r * 255)
    g = math.floor(g * 255)
    b = math.floor(b * 255)
    a = math.floor(a * 255)

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
function image_dropped:paint_from_image(image)
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
            local particle_id = get_closest_particle(r, g, b, a, colors)
            self.particle_simulation:setParticle(px, py, particle_id)
        end
    end
end

return image_dropped
