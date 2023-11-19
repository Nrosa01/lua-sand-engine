-- Quad.lua

-- Definición de la clase Quad
Quad = {}

-- Constructor
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
  
  -- Inicializar la textura con colores aleatorios
  for y = 0, textHeight - 1 do
    for x = 0, textWidth - 1 do
      local r = love.math.random(0, 255)
      local g = love.math.random(0, 255)
      local b = love.math.random(0, 255)
      obj.imageData:setPixel(x, y, r, g, b, 255)
    end
  end

  setmetatable(obj, self)
  self.__index = self
  return obj
end

-- Render method that uploads the texture to the GPU and draws it
function Quad:render(x, y)
    self.texture:replacePixels(self.imageData)
    love.graphics.draw(self.texture, x, y, 0, self.scaleX, self.scaleY)
end

-- Simple set pixel method (RGBA)
function Quad:setPixel(x, y, r, g, b, a)
    self.imageData:setPixel(x, y, r, g, b, a)
end

return Quad
