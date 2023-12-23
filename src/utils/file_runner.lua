local function runFile(file)
    local contents = file:read()
    local chunk = load(contents)
    if chunk then
        chunk()
    end
end

return runFile