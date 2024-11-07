local Door = GameObject:extend()

function Door:new(x, y, tile_size, exit, exit_table)
	local bump_info = {
		rect = Rect.centered(0, 0, tile_size, tile_size),
		solid = false,
	}
	Door.super.new(self, x, y)
	self:bump_init(bump_info)
	self:add_update_signals()
	self.static = true
	self.exit_to = exit
	self.exit_table = exit_table
	self.side = self.exit_table.facing_direction == "right" or self.exit_table.facing_direction == "left" and "horizontal" or "vertical"
	self.texture = self.side == "vertical" and textures.door or textures.door_side
	self:set_openable(true)

end

function Door:set_openable(openable)
	self.openable = openable
	self.solid = not openable
end

function Door:draw()
	graphics.draw_centered(self:get_texture())
end

function Door:get_texture()
	-- return self.texture
end

return Door
