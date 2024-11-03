local PlayerObject = GameObject:extend()

function PlayerObject:update(dt)
	local input = self:get_input_table()
	local move = input.move_clamped

	if move.x ~= 0 or move.y ~= 0 then 
		self:move(move.x * dt * 2.0, move.y * dt * 2.0)
	end
	-- self:move(move.x * dt * 2.0, move.y * dt * 2.0)
end

function PlayerObject:draw()
	local r = self.collision_rect
	-- graphics.rectangle("fill", -r.width/2, -r.height/2, r.width, r.height)
	graphics.draw_centered(textures.ball1)
end

return PlayerObject
