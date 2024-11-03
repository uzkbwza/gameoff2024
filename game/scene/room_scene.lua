local RoomScene = GameScene:extend()

function RoomScene:new(x, y, data)
	RoomScene.super.new(self, x, y, data)
	self:add_update_signals()
	
	self:hide()
	self:set_update(false)
	self:create_bump_world(64)

end

return RoomScene
