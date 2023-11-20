local ffi = require("ffi")

-- Define el struct para el vector2d
ffi.cdef[[
    typedef struct {
        int16_t x;
        int16_t y;
    } Vector2D;
]]

-- Define el struct para el color
ffi.cdef[[
    typedef struct {
        float r;
        float g;
        float b;
        float a;
    } Color;
]]

-- Define el struct para las propiedades
ffi.cdef[[
    typedef struct {
        uint32_t density;
        uint32_t flammability;
        uint32_t explosiveness;
        uint32_t boilingPoint;
        uint32_t startingTemperature;
    } Properties;
]]

-- This is just a constructor
local ParticleDefinitionLib = {}

function ParticleDefinitionLib.new(text_id, particle_color, random_granularity, movement_passes, properties, interactions)
    local instance = {
        text_id = text_id,
        color = ffi.new("Color", particle_color.r / 255.0, particle_color.g / 255.0, particle_color.b / 255.0, particle_color.a / 255.0),
        random_granularity = random_granularity,
        movement_passes_count = #movement_passes,
        movement_passes = nil,
        properties = ffi.new("Properties", properties.density or 0, properties.flammability or 0, properties.explosiveness or 0, properties.boilingPoint or 0, properties.startingTemperature or 0),
        interactions = interactions or {}
    }

    if instance.movement_passes_count > 0 then
        instance.movement_passes = ffi.new("Vector2D[?]", instance.movement_passes_count)
        for i, v in ipairs(movement_passes) do
            instance.movement_passes[i - 1].x = v.x or 0
            instance.movement_passes[i - 1].y = v.y or 0
        end
    end


    return instance
end

return ParticleDefinitionLib
