local IS_DEBUG = os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" and arg[2] == "debug"
if IS_DEBUG then
    lldebugger = require("lldebugger")
    lldebugger.start()

    function love.errorhandler(msg)
        error(msg, 2)
    end
end

local mouse = { x = 0, y = 0, button = "" }
local canvas_size = 100
local brush_size = math.floor(canvas_size / 20);
local sensitivy = brush_size / 10
local currentParticle = 2

local imgui = require "imgui"
require "src"
require "ParticleDefinitionsHandler"
require "particleLauncher"
require "quad"
require "particle_chunk"

local myQuad;
local chunk;

function love.load()
    -- create quad with the same size as the window getting the size from the window
    myQuad = Libs.Quad:new(love.graphics.getWidth(), love.graphics.getHeight(), canvas_size, canvas_size)
    chunk = ParticleChunk.new(canvas_size, canvas_size, myQuad)
end

local function drawParticleMenu()
    -- const auto count = ParticleDefinitionsHandler::getInstance().getRegisteredParticlesCount();

	-- for (uint8_t i = 0; i < count; i++)
	-- {
	-- 	auto data = ParticleDefinitionsHandler::getInstance().getParticleData(i);

	-- 	if (ImGui::Selectable(data.text_id.c_str(), selectedParticleIndex == i)) {
	-- 		selectedParticleIndex = i;
	-- 	}
	-- 	ImGui::SameLine();
	-- 	ImGui::ColorButton((data.text_id + "Color").c_str(), ImVec4(data.color.r / 255.0, data.color.g / 255.0, data.color.b / 255.0, data.color.a / 255.0), ImGuiColorEditFlags_NoTooltip, ImVec2(20, 20));
	-- }

    -- Equivalent to the above code

    local count = ParticleDefinitionsHandler:getRegisteredParticlesCount()

    imgui.Begin("Material selector", true, { "ImGuiWindowFlags_AlwaysAutoResize" });

    for i = 1, count do
        local data = ParticleDefinitionsHandler:getParticleData(i)

        if imgui.Selectable(data.text_id, currentParticle == i) then
            currentParticle = i
        end
        imgui.SameLine()
        imgui.ColorButton(data.text_id .. "Color", data.color.r, data.color.g, data.color.b, data.color.a)
    end

    imgui.End()
end

function love.keypressed(key, scancode, isrepeat)
    imgui.KeyPressed(key)
    if not imgui.GetWantCaptureKeyboard() then
        if tonumber(key) ~= nil and tonumber(key) <= ParticleDefinitionsHandler:getRegisteredParticlesCount() then
            currentParticle = tonumber(key)
        end
    end
end

function love.keyreleased(key)
    imgui.KeyReleased(key)
    if not imgui.GetWantCaptureKeyboard() then
        -- Pass event to the game
    end
end

function love.update(dt)
    imgui.NewFrame()

    if (mouse ~= nil and mouse.button == "left") then
        for x = -brush_size, brush_size do
            for y = -brush_size, brush_size do
                local px = mouse.x + x
                local py = mouse.y + y
                if chunk:isInside(px, py) and (chunk:isEmpty(px, py) or currentParticle == 1) then
                    chunk:setNewParticleById(px, py, currentParticle)
                end
            end
        end
    end

    chunk:update()
end

function love.quit()
    imgui.ShutDown()
end

function love.wheelmoved(x, y)
    imgui.WheelMoved(y)
    if not imgui.GetWantCaptureMouse() then
        if y > 0 then
            brush_size = brush_size + sensitivy
        elseif y < 0 then
            brush_size = brush_size - sensitivy
            -- use math.max to avoid negative values
            brush_size = math.max(brush_size, 1)
        end
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    imgui.MousePressed(button)
    if not imgui.GetWantCaptureMouse() then
        -- Checks which button was pressed.
        local buttonname = ""
        if button == 1 then
            buttonname = "left"
        elseif button == 2 then
            buttonname = "right"
        end

        local chunkX = math.floor(x / (love.graphics.getWidth() / chunk.width)) + 1
        local chunkY = math.floor(y / (love.graphics.getHeight() / chunk.height)) + 1
        mouse = { x = chunkX, y = chunkY, button = buttonname }
    end
end

function love.mousemoved(x, y, dx, dy)
    imgui.MouseMoved(x, y)
    if not imgui.GetWantCaptureMouse() then
        local chunkX = math.floor(x / (love.graphics.getWidth() / chunk.width)) + 1
        local chunkY = math.floor(y / (love.graphics.getHeight() / chunk.height)) + 1
        mouse = { x = chunkX, y = chunkY, button = mouse.button }
    end
end

function love.mousereleased(x, y, button, istouch)
    imgui.MouseReleased(button)
    if not imgui.GetWantCaptureMouse() then
        mouse.button = ""
    end
end

function love.draw(dt)
    -- clear color
    love.graphics.clear(0.07, 0.13, 0.17, 1.0)

    myQuad:render(0, 0)
    drawParticleMenu()
    imgui.Render();
    
    -- Print a circunference around the mouse
    local mouseX = love.mouse.getX()
    local mouseY = love.mouse.getY()
    love.graphics.circle("line", mouseX, mouseY, brush_size)
    
    love.graphics.print("Current FPS: " .. tostring(love.timer.getFPS() .. " GC: " .. gcinfo()), 10, 10)
end

function love.filedropped(file)
    -- Only run if the file is a lua file
    if file:getExtension() == "lua" then
        print("Running file: " .. file:getFilename())
        local fileRunner = require "fileRunner"
        fileRunner(file)
    else
        -- Show an error message as a popup (later I should make this a toast)
        local message = "The file you dropped is not a lua file"
        love.window.showMessageBox("Error", message, "error")
    end
end
