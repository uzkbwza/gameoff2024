local Door = GameObject:extend()



function Door:new(x, y, tile_size, exit)
	local bump_info = {
		rect = Rect.centered(0, 0, tile_size, tile_size),
		solid = false,
	}
	Door.super.new(self, x, y)
	self:bump_init(bump_info)
	self.static = true
	self.exit_to = exit

end

function Door:draw()
	graphics.draw_centered(textures.door)
end

return Door
