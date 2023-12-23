local beholder = require "beholder"
local EVENTS = require "src.observable_events"

local mods_handler = {}

function mods_handler:file_dropped(file)
    if file:getExtension() == "lua" then
        print("Running file: " .. file:getFilename())
        local fileRunner = require "fileRunner"
        fileRunner(file)
        beholder.trigger(EVENTS.MOD_ADDED)
    else
        -- Show an error message as a popup (later I should make this a toast)
        local message = "The file you dropped is not a lua file"
        love.window.showMessageBox("Error", message, "error")
    end
end

return mods_handler