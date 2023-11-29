local webviewLib = require('webview')

local content

-- Load contents from file examples/htdocs/test.html
local file = io.open('libs/webview/simple.html', 'r')

if file then
    content = file:read('*a')
    file:close()
else
    print('Cannot open file examples/htdocs/test.html')
    os.exit(1)
end

content = string.gsub(content, "[ %c!#$%%&'()*+,/:;=?@%[%]]", function(c)
    return string.format('%%%02X', string.byte(c))
end)

local webview = webviewLib.new('data:text/html,'..content, 'Example', 480, 240, false, false)

webviewLib.callback(webview, function(value)
    if value == 'print_date' then
        print(os.date())
    elseif value == 'show_date' then
        webviewLib.eval(webview, 'showText("Lua date is '..os.date()..'")', true)
    elseif value == 'fullscreen' then
        webviewLib.fullscreen(webview, true)
    elseif value == 'exit_fullscreen' then
        webviewLib.fullscreen(webview, false)
    elseif value == 'terminate' then
        webviewLib.terminate(webview, true)
    elseif string.find(value, '^title=') then
        webviewLib.title(webview, string.sub(value, 7))
    elseif value == 'hide' then
        webviewLib:hide()
    elseif value == 'show' then
        
    else
        print('callback received', value)
    end
end)

webviewLib.loop(webview)