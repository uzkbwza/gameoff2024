local Floor = GameObject:extend()
local mixins = require "obj.mixins"


function Floor:new(x, y, tile_size)
	local bump_info = {
		rect = Rect.centered(0, 0, tile_size, tile_size),
		solid = false,
		-- track_overlaps = true,
	}
	Floor.super.new(self, x, y)
	self:add_update_signals()
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
