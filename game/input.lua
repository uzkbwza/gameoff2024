local input = {}

input.mapping = nil
input.vectors = nil

input.dummy = {}
input.fixed = {}

function input.load()
	input.mapping = conf.input_actions
	input.vectors = conf.input_vectors
	
	input.dummy.mapping = conf.input_actions
	input.dummy.vectors = conf.input_vectors
	
	input.fixed.mapping = conf.input_actions
	input.fixed.vectors = conf.input_vectors

	for action, _ in pairs(input.mapping) do
		input[action] = false
		input[action .. "_pressed"] = false
		input[action .. "_released"] = false
		
		input.dummy[action] = false
		input.dummy[action .. "_pressed"] = false
		input.dummy[action .. "_released"] = false

		input.fixed[action] = false
		input.fixed[action .. "_pressed"] = false
		input.fixed[action .. "_released"] = false

	end
	for vector, _ in pairs(input.vectors) do
		input[vector] = Vec2(0, 0)
		input.dummy[vector] = Vec2(0, 0)
		input.fixed[vector] = Vec2(0, 0)
	end
end

function input.process(table)
	for action, _ in pairs(table.mapping) do
		table[action .. "_pressed"] = false
		table[action .. "_released"] = false
	end

	for action, keys in pairs(table.mapping) do
		local pressed = false

		if action.debug and not debug.enabled then
			goto skip
		end

		for _, keycombo in ipairs(keys.keyboard) do
			if type(keycombo) == "string" then 
				if love.keyboard.isDown(keycombo) then
					pressed = true
				end
			else
				local all_pressed = true
				for _, key in ipairs(keycombo) do 
					if not love.keyboard.isDown(key) then
						all_pressed = false
						break
					end
				end
				pressed = all_pressed
			end

			if pressed then
				break
			end
		end
		
		if pressed then
			if not table[action] then
				table[action .. "_pressed"] = true
			end
		else
			if table[action] then
				table[action .. "_released"] = true
			end
		end

		::skip::

		table[action] = pressed
	end

	for k, dirs in pairs(table.vectors) do

		local v = table[k]
		v.x = 0
		v.y = 0
		if table[dirs.left] then
			v.x = v.x - 1
		end
		if table[dirs.right] then
			v.x = v.x + 1
		end
		if table[dirs.up] then
			v.y = v.y - 1
		end
		if table[dirs.down] then
			v.y = v.y + 1
		end

		table[k] = v
	end

end	

function input.update(dt)
	input.process(input)
end

function input.fixed_update(dt)
	input.process(input.fixed)
end

return input
