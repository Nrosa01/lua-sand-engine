---@class Quad
---@field width number
---@field height number
---@field textWidth number
---@field textHeight number
---@field scaleX number
---@field scaleY number
---@field imageData love.ImageData
---@field texture love.Texture
local Quad = {}

-- Constructor
----@class Quad 
function Quad:new(width, height, textWidth, textHeight)
  local obj = {
    width = width,
    height = height,
    textWidth = textWidth,
    textHeight = textHeight,
    scaleX = width / textWidth,
    scaleY = height / textHeight,
    imageData = love.image.newImageData(textWidth, textHeight),
    texture = nil
  }

  obj.texture = love.graphics.newImage(obj.imageData)
  
  setmetatable(obj, self)
  self.__index = self
  return obj
end

-- Render method that uploads the texture to the GPU and draws it
function Quad:render(x, y)
    self.texture:replacePixels(self.imageData)
    love.graphics.draw(self.texture, x or 0, y or 0, 0, self.scaleX, self.scaleY)
end

-- Simple set pixel method (RGBA)
function Quad:setPixel(x, y, r, g, b, a)
    self.imageData:setPixel(x, y, r, g, b, a)
end

return Quad
