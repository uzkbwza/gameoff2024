local Floor = GameObject:extend()

function Floor:new(x, y, tile_size)
	local bump_info = {
		rect = Rect.centered(0, 0, tile_size, tile_size),
		solid = false,
	}
	Floor.super.new(self, x, y)
	self:bump_init(bump_info)
	self.static = true
	self.floor_type = "normal"
	self.z_index = -100

end

function Floor:debug_draw_bounds_shared()
end

function Floor:draw()
	graphics.draw_centered(textures.floor)
end

return Floor
