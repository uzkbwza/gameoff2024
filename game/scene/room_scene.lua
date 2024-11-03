local RoomScene = GameScene:extend()
local obj = require("obj.dungeon_objects")

function RoomScene:new(x, y, data)
	RoomScene.super.new(self, x, y, data)
	self:add_update_signals()
	self:create_bump_world(64)

	-- self.draw_sort  = function(a, b)
	-- 	return a.pos.y < b.pos.y
	-- end

	self:set_update(false)
	self:hide()

	for _=1, 1000 do
		local obj = obj.TestDungeonObject(rng.random_vec2(rng(0, 1000), rng(0, 1000)), 0, nil)
		self:add_object(obj)
	end

end

function RoomScene:add_player(obj)
	self:add_object(obj)
	self.player = obj
	self.camera:follow(obj)
end

function RoomScene:destroy_player()
	self.player:destroy()
	self.player = nil
end

return RoomScene
