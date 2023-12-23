
    -- Write to file all the key-value pairs of imgui
    -- If some is a function, we also write it's parameters using debugger.getArgs
    local file = love.filesystem.newFile("./imgui.txt")
    file:open("w")
    for k, v in pairs(imgui) do
        if type(v) == "function" then
            local args = debugger.getArgs(v)
            local args_str = ""

            for i = 1, #args do
                args_str = args_str .. args[i] .. ", "
            end

            file:write(k .. "(" .. args_str .. ")\n")
        else
            file:write(k .. " = " .. tostring(v) .. "\n")
        end
    end

    file:close()

    -- Open the file
    love.system.openURL("file://" .. love.filesystem.getSaveDirectory() .. "/imgui.txt")