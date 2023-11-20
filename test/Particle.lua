local ffi = require("ffi")

ffi.cdef [[
    struct Particle {
        uint32_t type;
        bool clock;
    };
]]

local Particle = ffi.metatype("struct Particle", {})

function create1darray(n)
    local img = ffi.new("struct Particle[?]", n)

    for i = 0, n - 1 do
        img[i].type = 1
        img[i].clock = false
    end
    return img
end

function create2darray(width, height)
    local img = ffi.new("struct Particle*[?]", width)

    for x = 0, width - 1 do
        img[x] = ffi.new("struct Particle[?]", height)
        for y = 0, height - 1 do
            img[x][y].type = 1
            img[x][y].clock = false
        end
    end
    return img
end

return Particle
