local Wall = GameObject:extend()
local mixins = require "obj.mixins"



function Wall:new(x, y, tile_size)
	local bump_info = {
		rect = Rect.centered(0, 0, tile_size, tile_size)
	}
	Wall.super.new(self, x, y)
	self:bump_init(bump_info)
	-- self:add_sequencer()
	-- self.static = true
	-- self.pickupable = false
	self:add_update_signals()
	-- self:set_update(false)
	-- self:init_basic_physics()
end

function Wall:draw()
	graphics.draw_centered(textures.wall)
end

return Wall
