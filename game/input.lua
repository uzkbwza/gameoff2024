local input = {}

input.mapping = nil
input.vectors = nil

input.dummy = {}
input.fixed = {}
input.joysticks = {}

input.generated_action_names = {}

function input.load()
	local g = input.generated_action_names

	input.mapping = conf.input_actions
	input.vectors = conf.input_vectors
	
	input.dummy.mapping = conf.input_actions
	input.dummy.vectors = conf.input_vectors
	
	input.fixed.mapping = conf.input_actions
	input.fixed.vectors = conf.input_vectors

	for action, _ in pairs(input.mapping) do
		g[action] = {
			pressed = action .. "_pressed",
			released = action .. "_released",
			amount = action .. "_amount"
		}

		input[action] = false
		input[action .. "_pressed"] = false
		input[action .. "_released"] = false
		
		input.dummy[action] = false
		input.dummy[action .. "_pressed"] = false
		input.dummy[action .. "_released"] = false

		input.fixed[action] = false
		input.fixed[action .. "_pressed"] = false
		input.fixed[action .. "_released"] = false

		if input.mapping[action].joystick_axis then 
			input[action .. "_amount"] = 0
			input.dummy[action .. "_amount"] = 0
			input.fixed[action .. "_amount"] = 0
		end

	end

	for vector, _ in pairs(input.vectors) do
		g[vector] = {
			normalized = vector .. "_normalized",
			clamped = vector .. "_clamped"
		}
		input[vector] = Vec2(0, 0)
		input.dummy[vector] = Vec2(0, 0)
		input.fixed[vector] = Vec2(0, 0)
		input[vector .. "_normalized"] = Vec2(0, 0)
		input.dummy[vector .. "_normalized"] = Vec2(0, 0)
		input.fixed[vector .. "_normalized"] = Vec2(0, 0)
		input[vector .. "_clamped"] = Vec2(0, 0)
		input.dummy[vector .. "_clamped"] = Vec2(0, 0)
		input.fixed[vector .. "_clamped"] = Vec2(0, 0)

	end
	
end

function input.joystick_added(joystick)
	input.joysticks[#input.joysticks+1] = joystick
end

function input.joystick_removed(joystick)
	for i, joy in ipairs(input.joysticks) do
		if joy == joystick then
			table.remove(input.joysticks, i)
			break
		end
	end
end

function input.check_input_combo(table, joystick)
	if table == nil then
		return false
	end
	local pressed = false

	for _, keycombo in ipairs(table) do
		if type(keycombo) == "string" then
			if joystick == nil then 
				if love.keyboard.isDown(keycombo) then
					pressed = true
				end
			else
				if joystick:isGamepadDown(keycombo) then
					pressed = true
				end
			end

		else
			local all_pressed = true
			for _, key in ipairs(keycombo) do
				if joystick == nil then 
					if not love.keyboard.isDown(key) then
						all_pressed = false
						break
					end
				else
					if not joystick:isGamepadDown(key, joystick) then
						all_pressed = false
						break
					end
				end
			end
			pressed = all_pressed
		end

		if pressed then
			break
		end

	end
	return pressed 

end

function input.process(table)
	local g = input.generated_action_names

	for action, _ in pairs(table.mapping) do
		table[g[action].pressed] = false
		table[g[action].released] = false
	end

	for action, mapping in pairs(table.mapping) do
		local pressed = false

		if action.debug and not debug.enabled then
			goto skip
		end

		if input.check_input_combo(mapping.keyboard) then
			pressed = true
		end

		for _, joystick in ipairs(input.joysticks) do
			if input.check_input_combo(mapping.joystick, joystick) then
				pressed = true
			end

			if pressed then break end

			if mapping.joystick_axis then
				local axis = mapping.joystick_axis.axis
				local dir = mapping.joystick_axis.dir
				local value = joystick:getGamepadAxis(axis)
				local deadzone = mapping.joystick_axis.deadzone or 0.1
				if dir == 1 then
					if value > deadzone then
						pressed = true
						table[g[action].amount] = abs(value)
					end
				else
					if value < -deadzone then
						pressed = true
						table[g[action].amount] = abs(value)
					end
				end
				if not pressed then
					table[g[action].amount] = 0
				end
			end
			if pressed then break end
		end
		
		if pressed then
			if not table[action] then
				table[g[action].pressed] = true
			end
			if table[g[action].amount] == 0 then
				table[g[action].amount] = 1
			end
		else
			if table[action] then
				table[g[action].released] = true
			end
			table[g[action].amount] = 0
		end

		::skip::

		table[action] = pressed
	end

	for k, dirs in pairs(table.vectors) do

		local v = table[k]
		v.x = 0
		v.y = 0

		if table[g[dirs.left].amount] then
			v.x = v.x - table[g[dirs.left].amount]
		elseif table[dirs.left] then
			v.x = v.x - 1
		end
		if table[g[dirs.right].amount] then
			v.x = v.x + table[g[dirs.right].amount]
		elseif table[dirs.right] then
			v.x = v.x + 1
		end
		if table[g[dirs.up].amount] then
			v.y = v.y - table[g[dirs.up].amount]
		elseif table[dirs.up] then
			v.y = v.y - 1
		end
		if table[g[dirs.down].amount] then
			v.y = v.y + table[g[dirs.down].amount]
		elseif table[dirs.down] then
			v.y = v.y + 1
		end

		table[k] = v

		local nv = table[g[k].normalized]
		local nx, ny = vec2_normalized(v.x, v.y)
		nv.x = nx
		nv.y = ny

		local cv = table[g[k].clamped]
		local cx, cy = v.x, v.y
		if vec2_magnitude(v.x, v.y) > 1 then
			cx, cy = vec2_normalized(v.x, v.y)
		end
		cv.x = cx
		cv.y = cy
		-- print(v)
	end

end	

function input.update(dt)
	input.process(input)
end

function input.fixed_update(dt)
	input.process(input.fixed)
end


return input
