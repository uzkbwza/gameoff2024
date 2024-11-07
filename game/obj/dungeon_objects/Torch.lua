local DungeonObject = require("obj.dungeon_objects.DungeonObject"):extend()
local mixins = require("obj.mixins")

local Torch = DungeonObject:extend()

function Torch:new(x, y)
	Torch.super.new(self, x, y)
	self:add_sequencer()


	self.is_torch = true

	self:bump_init{
		rect = Rect.centered(0, 0, 8, 8),
		solid = false,
		track_overlaps = true,
	}
	
	self:mix_in(mixins.Pickupable)
	self:mix_in(mixins.Flammable)

end

function Torch:draw()
	graphics.draw_centered(self.on_fire and textures.torch_lit or textures.torch)
end

function Torch:on_interact()
	if self.on_fire then
		self:extinguish()
	else
		self:light_flame()
	end
end

return Torch
