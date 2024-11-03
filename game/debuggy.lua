local debuggy = setmetatable({}, {__index = debug})

debug.enabled = true
debug.draw = true
debug.lines = {}

function debuggy.can_draw()
	return debuggy.enabled and debuggy.draw
end

function debuggy.printlines(line, x, y)
	if not debuggy.can_draw() then
		return
	end
	local counter = 0
	for k, v in pairs(debuggy.lines) do
		if v == "" then
			graphics.print(k, x, counter * 12)
			v = "nil"
		else
			graphics.print(k .. ": " .. tostring(v), x, counter * 12)
		end

		counter = counter + 1
	end

end

function debuggy.clear(key)
	key = key or nil
	if key then
		debuggy.lines[key] = nil
		return
	end
	debuggy.lines = {}
end

function debuggy.update(dt)
	if input.debug_draw_toggle_pressed then 
		debuggy.draw = not debuggy.draw
	end
	if input.debug_shader_toggle_pressed then 
		usersettings.use_screen_shader = not usersettings.use_screen_shader
	end
end

function dbg(k, v)
	if type(k) == "table" then
		for k2, v2 in pairs(k) do
			dbg(k2, v2)
		end
		return
	end
	if v == nil then
		v = ""
	end
	debuggy.lines[k] = v
end

return debuggy
