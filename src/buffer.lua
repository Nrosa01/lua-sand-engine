local stringBuffer = require("string.buffer")
local ffi = require("ffi")

local buffer = stringBuffer.new(
    {
        metatable =
        {
            require("ParticleDefinitionsHandler"),
        }
    }
)

Encode = function (data)
    return buffer:reset():encode(data):get()
end

Decode = function (data)
    return buffer:set(data):decode()
end