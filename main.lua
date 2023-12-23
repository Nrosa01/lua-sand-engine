local debugger = require "src.utils.debugger"
require "src.init"

local canvas_size = 300
local paused = false

ParticleDefinitionsHandler = require "particle_definition_handler"
Gizmos = require "src.graphics.gizmos"

local imgui = require "imgui"
require "particle_first_load"
local ParticleSimulation = require "particle_simulation"
local brush = require "brush"
local entity_system = require "src.core.entity_system"
local mods_handler = require "src.mods.mods_handler"
local particle_menu = require("particle_menu")

function love.load()
    local particleSimulation = ParticleSimulation:new(love.graphics.getWidth(), love.graphics.getHeight(), canvas_size,
    canvas_size)
    brush:construct(canvas_size, particleSimulation)
    entity_system:add_entity(mods_handler)
    entity_system:add_entity(particleSimulation)
    entity_system:add_entity(particle_menu)
    entity_system:add_entity(brush)
    entity_system:init()
end

function love.keypressed(key, scancode, isrepeat)
    imgui.KeyPressed(key)
    if not imgui.GetWantCaptureKeyboard() then
        entity_system:key_pressed(key, scancode, isrepeat)
    end
end

function love.keyreleased(key)
    imgui.KeyReleased(key)
    if not imgui.GetWantCaptureKeyboard() then
       entity_system:key_released(key)
    end
end

function love.update(dt)
    imgui.NewFrame()
    entity_system:update(dt)
end

function love.wheelmoved(x, y)
    imgui.WheelMoved(y)
    if not imgui.GetWantCaptureMouse() then
        entity_system:wheel_moved(x, y)
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    imgui.MousePressed(button)
    if not imgui.GetWantCaptureMouse() then
        entity_system:mouse_pressed(x, y, button, istouch, presses)
    end
end

function love.mousemoved(x, y, dx, dy)
    imgui.MouseMoved(x, y)
    if not imgui.GetWantCaptureMouse() then
        entity_system:mouse_moved(x, y, dx, dy)
    end
end

function love.mousereleased(x, y, button, istouch)
    imgui.MouseReleased(button)
    if not imgui.GetWantCaptureMouse() then
        entity_system:mouse_released(x, y, button, istouch)
    end
end

function love.draw(dt)
    love.graphics.clear(0.07, 0.13, 0.17, 1.0)
    
    entity_system:draw()

    imgui.Begin("Fused: " .. tostring(love.filesystem.isFused()))
    imgui.End()

    imgui.Render();

    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.print("Current FPS: " .. love.timer.getFPS() .. " GC: " .. gcinfo(), 10, 10)
    love.graphics.setColor(1, 1, 1, 1)
end

function love.focus(focused)
    entity_system:focus(focused)
end

function love.quit()
    entity_system:quit()
    imgui.ShutDown()
end

function love.filedropped(file)
    entity_system:file_dropped(file)
end
