-- https://love2d.org/wiki/Config_Files
function love.conf(t)
	t.identity              = nil
	t.appendidentity        = false
	t.version               = "11.4"
	t.console               = false
	t.accelerometerjoystick = false
	t.externalstorage       = false
	t.gammacorrect          = false

	t.audio.mic             = false
	t.audio.mixwithsystem   = true

	t.window.title          = "Sand Simulation"
	t.window.icon           = nil
	t.window.width          = 800
	t.window.height         = 800
	t.window.borderless     = false
	t.window.resizable      = false
	t.window.minwidth       = 1
	t.window.minheight      = 1
	t.window.fullscreen     = false
	t.window.fullscreentype = "desktop"
	t.window.vsync          = 1
	t.window.msaa           = 0
	t.window.depth          = nil
	t.window.stencil        = nil
	t.window.display        = 1
	t.window.highdpi        = false
	t.window.usedpiscale    = true
	t.window.x              = nil
	t.window.y              = nil

	t.modules.audio         = false
	t.modules.data          = true
	t.modules.event         = true
	t.modules.font          = true
	t.modules.graphics      = true
	t.modules.image         = true
	t.modules.joystick      = false
	t.modules.keyboard      = true
	t.modules.math          = false
	t.modules.mouse         = true
	t.modules.physics       = false
	t.modules.sound         = false
	t.modules.system        = false
	t.modules.thread        = true
	t.modules.timer         = true
	t.modules.touch         = false
	t.modules.video         = false
	t.modules.window        = true
end
