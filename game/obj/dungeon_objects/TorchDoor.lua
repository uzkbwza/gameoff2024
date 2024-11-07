local TorchDoor = require("obj.dungeon_objects.Exit"):extend()
local mixins = require "obj.mixins"


function TorchDoor:new(x, y, ...)
	TorchDoor.super.new(self, x, y, ...)
	self:set_openable(false)
	self:mix_in(mixins.Illuminable, true)
end

function TorchDoor:update(dt)
	-- TorchDoor.super.update(self, dt)
	if self.lightness > 0.15 then 
		self:set_openable(true)
	end
end

-- function TorchDoor:get_texture()

-- end

function TorchDoor:draw()
	TorchDoor.super.draw(self)
	graphics.set_color(1, 1, 1, 1 - self.lightness)
	graphics.draw_centered(textures.wall)
end

return TorchDoor
