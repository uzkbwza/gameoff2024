local DungeonObject = GameObject:extend()

function DungeonObject:new(x, y)
	DungeonObject.super.new(self, x, y)
	self.pickupable = false
	self:add_update_signals()
	-- self:set_update(false)
	self:init_basic_physics()
end

function DungeonObject:make_pickupable()
	self.pickupable = true
end

return DungeonObject
