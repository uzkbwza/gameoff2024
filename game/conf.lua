---@diagnostic disable: lowercase-global
Object = require "lib.object"
table = require "lib.tabley"
string = require "lib.stringy"
debug = require "debuggy"
filesystem = require "lib.file"
ease = require "lib.ease"
usersettings = require "usersettings"


require "lib.mathy"
require "lib.vector"
require "lib.signal"
require "lib.sequencer"
require "lib.random_crap"

require "obj.game_object"
require "lib.anim"

require "datastructure.bst"
require "datastructure.bst2"

local IS_DEBUG = os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" and arg[2] == "debug"
if IS_DEBUG then
	require("lldebugger").start()

	function love.errorhandler(msg)
		error(msg, 2)
	end
end

local conf = {
	-- display
	viewport_size = Vec2(
		240,
		160
	),

	display_scale = 3,

	-- delta
	fixed_tickrate = 60,
	max_delta = 1,
	max_fixed_ticks_per_frame = 5,
	enable_fixed_timestep_interpolation = true,

	-- assets
	asset_folder_scan = {
		"assets",
		"obj",
		"screen",
		"ui",
		"fx",
	},

	-- input
	input_actions = {
		primary = {
			keyboard = { "z", "return" }
		},

		secondary = {
			keyboard = { "x", "rshift" }
		},

		menu = {
			keyboard = { "escape", }
		},

		move_up = {
			keyboard = {"up"}
		},

		move_down = {
			keyboard = {"down"}
		},

		move_left = {
			keyboard = {"left"}
		},

		move_right = {
			keyboard = {"right"}
		},

		fullscreen_toggle = {
			keyboard = {"f11", {"ralt", "return"}, {"lalt", "return"}}
		},

		debug_draw_toggle = {
			debug = true,
			keyboard = { { "lctrl", "d" }, { "rctrl", "d" } }
		},

		debug_shader_toggle = {
			debug = true,
			keyboard = { {"lctrl", "s"}, {"rctrl", "s"}}
		}
	},

	input_vectors = {
		move = {
			left = "move_left",
			right = "move_right",
			up = "move_up",
			down = "move_down",
		}
	},
}

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

	t.window.title          = "Untitled"
	t.window.icon           = nil
	t.window.width          = conf.viewport_size.x * conf.display_scale
	t.window.height         = conf.viewport_size.y * conf.display_scale
	t.window.borderless     = false
	t.window.resizable      = true
	t.window.minwidth       = conf.viewport_size.x
	t.window.minheight      = conf.viewport_size.y
	t.window.fullscreen     = false
	t.window.fullscreentype = "desktop"
	t.window.vsync          = 0
	t.window.msaa           = 0
	t.window.depth          = nil
	t.window.stencil        = nil
	t.window.display        = 1
	t.window.highdpi        = false
	t.window.usedpiscale    = true
	t.window.x              = nil
	t.window.y              = nil

	t.modules.audio         = true
	t.modules.data          = true
	t.modules.event         = true
	t.modules.font          = true
	t.modules.graphics      = true
	t.modules.image         = true
	t.modules.joystick      = true
	t.modules.keyboard      = true
	t.modules.math          = true
	t.modules.mouse         = true
	t.modules.physics       = true
	t.modules.sound         = true
	t.modules.system        = true
	t.modules.thread        = true
	t.modules.timer         = true
	t.modules.touch         = true
	t.modules.video         = true
	t.modules.window        = true
end

return conf
