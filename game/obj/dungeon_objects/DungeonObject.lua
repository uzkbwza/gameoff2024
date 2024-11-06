local DungeonObject = GameObject:extend()

function DungeonObject:new(x, y)
	DungeonObject.super.new(self, x, y)
	self.pickupable = false
	self:add_update_signals()
	-- self:set_update(false)
	self:init_basic_physics()
	self.drag = 0.08
end

return DungeonObject
