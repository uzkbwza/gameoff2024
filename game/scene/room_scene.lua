local obj = require("obj.dungeon_objects")

local RoomScene = GameScene:extend()

function RoomScene:new()
	RoomScene.super.new(self)
	self:create_bump_world()
end

function RoomScene:enter()
	for x = 0, self.viewport_size.x - 1, 16 do
		-- x = x - self.viewport_size.x / 2

		self:add_object(obj.TestDungeonObject(8 + x, 8))
		self:add_object(obj.TestDungeonObject(8 + x, self.viewport_size.y - 8))
	end
	for y = 0, self.viewport_size.y - 1, 16 do
		-- y = y - self.viewport_size.y / 2
		
		self:add_object(obj.TestDungeonObject(8, 8 + y))
		self:add_object(obj.TestDungeonObject(self.viewport_size.x - 8, 8 + y))
	end
	local player = obj.TestDungeonObject(40, 40)
	player.player = true

	self:add_object(player)
	self.camera:set_limits(0, self.viewport_size.x, 0, self.viewport_size.y)
	self.camera:follow(player)
end

return RoomScene
