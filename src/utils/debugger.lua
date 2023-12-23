local IS_DEBUG = os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" and arg[2] == "debug"
if IS_DEBUG then
    lldebugger = require("lldebugger")
    lldebugger.start()

    function love.errorhandler(msg)
        error(msg, 2)
    end
end

local function getArgs(func)
    local info = debug.getinfo(func, "u")
    local params = {}

    if info and info.nparams then
        for i = 1, info.nparams do
            local paramName = debug.getlocal(func, i)
            table.insert(params, paramName)
        end
    end

    return params
end

local function print_table(table)
    for key, value in pairs(table) do
        print(key, value)
    end
end

local debug = 
{
    getArgs = getArgs,
    print_table = print_table
}

return debug