local MOUSE_BUTTONS = require("src.input.mouse_buttons")
local EVENTS = require("src.core.observable_events")
local beholder = require("beholder")

---@class Brush
---@field brush_size number
---@field sensitivity number
---@field particle_simulation ParticleSimulation
---@field canvas_size number
local brush = {}
brush.brush_size = 1
brush.sensitivity = 1
brush.particle_simulation = nil
brush.canvas_size = 1

local mouse = { x = 0, y = 0, button = nil }
local current_particle = 2

beholder.observe(EVENTS.CURRENT_PARTICLE_CHANGED, function(particle)
    current_particle = particle
end)

beholder.observe(EVENTS.CANVAS_SIZE_CHANGED, function(canvas_size)
    brush.brush_size = math.floor(canvas_size / 20) * 7
    brush.sensitivity = brush.brush_size / 10
end)

function brush:construct(canvas_size, particle_simulation)
    self.particle_simulation = particle_simulation
    brush.brush_size = math.floor(canvas_size / 20) * 7
    brush.sensitivity = brush.brush_size / 10
end

function brush:draw()
    love.graphics.setColor(1, 1, 1, 1)
    local drawCircleSize = self.brush_size * (love.graphics.getWidth() / self.particle_simulation.simulation_width)
    love.graphics.circle("line", love.mouse.getX(), love.mouse.getY(), drawCircleSize)
end

function brush:mouse_pressed(x, y, button, istouch, presses)
    if button == MOUSE_BUTTONS.LEFT then
        local x = math.floor(love.mouse.getX() * (self.particle_simulation.simulation_width / love.graphics.getWidth()))
        local y = math.floor(love.mouse.getY() * (self.particle_simulation.simulation_height / love.graphics.getHeight()))
        mouse = { x = x, y = y, button = button }
    end
end

function brush:mouse_moved(x, y, dx, dy)
    mouse.x = math.floor(love.mouse.getX() / (love.graphics.getWidth() / self.particle_simulation.simulation_width))
    mouse.y = math.floor(love.mouse.getY() / (love.graphics.getHeight() / self.particle_simulation.simulation_height))
end

function brush:mouse_released(x, y, button, istouch, presses)
    mouse.button = MOUSE_BUTTONS.NONE
end

function brush:update(dt)
    if mouse.button == MOUSE_BUTTONS.LEFT then
        if brush.brush_size > 1 then
            for x = -brush.brush_size, brush.brush_size do
                for y = -brush.brush_size, brush.brush_size do
                    local posX = mouse.x + x
                    local posY = mouse.y + y

                    local distance_squared = (posX - mouse.x) ^ 2 + (posY - mouse.y) ^ 2
                    if distance_squared <= self.brush_size ^ 2 then
                        self.particle_simulation:setParticle(posX, posY, current_particle)
                    end
                end
            end
        else
            self.particle_simulation:setParticle(mouse.x, mouse.y, current_particle)
        end
    end
end

function brush:wheel_moved(x, y)
    if y > 0 then
        self.brush_size = self.brush_size + self.sensitivity
    elseif y < 0 then
        self.brush_size = self.brush_size - self.sensitivity
        self.brush_size = math.max(self.brush_size, 1)
    end

    self.brush_size = math.ceil(self.brush_size)
end

return brush
