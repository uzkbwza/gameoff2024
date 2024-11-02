local TestDungeonObject = GameObject:extend()

local bump_data = {
	rect = Rect.centered(0, 0, 16, 16)
}

function TestDungeonObject:new(x, y)
	TestDungeonObject.super.new(self, x, y)
	self:bump_init(bump_data)
end

function TestDungeonObject:fixed_update(dt)
	if self.player then 
		local input = self:get_input_table()
		local move = input.move_normalized

		self:move(move.x * dt * 2.0, move.y * dt * 2.0)
	end
end

function TestDungeonObject:draw()
	graphics.set_color(1, 1, 1)
	graphics.rectangle("fill",  -8, -8, 16, 16)
end

return TestDungeonObject