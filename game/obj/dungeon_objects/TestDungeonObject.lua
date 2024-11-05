local TestDungeonObject = require("obj.dungeon_objects.DungeonObject"):extend()

local bump_info = {
	rect = Rect.centered(0, 0, 4, 4)
}

function TestDungeonObject:new(x, y)
	TestDungeonObject.super.new(self, x, y)
	self:bump_init(bump_info)
	self.collision_rect = bump_info.rect
	self:add_update_signals()
	self:set_update(false)
	-- self:hide()
end

function TestDungeonObject:update(dt)
	if self.player then 
		local input = self:get_input_table()
		local move = input.move_clamped

		if move.x ~= 0 or move.y ~= 0 then 
			self:move(move.x * dt * 2.0, move.y * dt * 2.0)
		end
		-- self:move(move.x * dt * 2.0, move.y * dt * 2.0)
	end
end

function TestDungeonObject:draw()
	local r = self.collision_rect
	-- graphics.rectangle("fill", -r.width/2, -r.height/2, r.width, r.height)
	graphics.draw_centered(textures.ball1)
end

return TestDungeonObject
