local Wall = GameObject:extend()



function Wall:new(x, y, tile_size)
	local bump_info = {
		rect = Rect.centered(0, 0, tile_size, tile_size)
	}
	Wall.super.new(self, x, y)
	self:bump_init(bump_info)
	self.static = true
	-- self.pickupable = false
	-- self:add_update_signals()
	-- self:set_update(false)
	-- self:init_basic_physics()
end

function Wall:draw()
	graphics.draw_centered(textures.wall)
end

return Wall
