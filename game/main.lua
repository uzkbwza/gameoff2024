game = require "game"
input = require "input"
conf = require "conf"
graphics = require "graphics"
rng = require "lib.rng"
gametime = require "time"
audio = require "audio"

palette = nil
textures = nil

local accumulated_time = 0
local frame_time = 1 / conf.fixed_tickrate

function love.run()
	if love.math then
		love.math.setRandomSeed(os.time())
	end

	if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then love.timer.step() end

	local dt = 0

	-- Main loop time.
	return function()
		-- Process events.
		if love.event then
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						return a or 0
					end
				end
				love.handlers[name](a,b,c,d,e,f)
			end
		end

		-- Update dt, as we'll be passing it to update
		if love.timer then dt = love.timer.step() end

		-- Call update and draw
		if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled

		if love.graphics and love.graphics.isActive() then
			love.graphics.origin()
			love.graphics.clear(love.graphics.getBackgroundColor())

			if love.draw then love.draw() end

			love.graphics.present()
		end

		if love.timer then love.timer.sleep(0.001) end
	end
end

function love.load()
	input.load()
	game.load()
	palette = graphics.palette
	textures = graphics.textures
end

function love.update(dt)
	accumulated_time = accumulated_time + dt
	local delta_frame = min(dt * 60, conf.max_delta * 60)

	input.update(dt)
	game.update(delta_frame)
	gametime.time = gametime.time + dt
	gametime.frames = gametime.frames + 1
	
	for i = 1, conf.max_fixed_ticks_per_frame do
		if accumulated_time < frame_time then
			break
		end
		
		-- print("fixed")
		game.fixed_update(frame_time * 60)
		-- fixed_update input AFTER game always! or else it will clear pressed inputs before the game can read them
		input.fixed_update(dt)
		accumulated_time = accumulated_time - frame_time
		gametime.ticks = gametime.ticks + 1
	end
	-- print(fixed_updated)
	

	
	-- print(graphics.interp_fraction)

	dbg("fps", love.timer.getFPS())
	dbg("memory use (kB)", floor(collectgarbage("count")))
	debug.update(dt)
end

function love.draw()
	graphics.interp_fraction = conf.enable_fixed_timestep_interpolation and clamp(accumulated_time / frame_time, 0, 1) or 1
	-- graphics.interp_fraction = stepify(graphics.interp_fraction, 0.1)

	game.draw()
end

function love.joystickadded(joystick)
	input.joystick_added(joystick)
end

function love.joystickremoved(joystick)
	input.joystick_removed(joystick)
end
