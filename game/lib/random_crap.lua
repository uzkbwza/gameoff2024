---@diagnostic disable: lowercase-global
function UUID()
    local fn = function(x)
        local r = love.math.random(16) - 1
        r = (x == "x") and (r + 1) or (r % 4) + 9
        return ("0123456789abcdef"):sub(r, r)
    end
    return (("xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"):gsub("[xy]", fn))
end


function frames_to_seconds(n)
	return n / 60
end

function seconds_to_frames(n)
	return n * 60
end

function flood_fill(x, y, fill, check_solid)
	local stack = {Vec2(x, y)}
	while not table.is_empty(stack) do
		local coord = table.pop_front(stack)
		if not check_solid(coord.x, coord.y) then 
			fill(coord.x, coord.y)
			table.push_back(stack, coord + Vec2(-1, 0))
			table.push_back(stack, coord + Vec2(1, 0))
			table.push_back(stack, coord + Vec2(0, -1))
			table.push_back(stack, coord + Vec2(0, 1))
		end
	end
end

