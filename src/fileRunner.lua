local function runFile(file)
    local contents = file:read()
    local chunk = loadstring(contents)
    if chunk then
        chunk()
    end
end

return runFile