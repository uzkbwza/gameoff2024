local obj = require("obj.dungeon_objects")
local RoomScene = require("scene.room_scene")

local MainGameScene = GameScene:extend()

function MainGameScene:new()
	MainGameScene.super.new(self)
	self:create_bump_world(64)

	self.follow_camera = false

	self.current_room = nil


end

function MainGameScene:update(dt)
	MainGameScene.super.update(self, dt)
	local i = self:get_input_table()
	if i.menu_pressed then
		if self.current_room == self.rooms[1] then
			self:switch_room(self.rooms[2])
		else
			self:switch_room(self.rooms[1])
		end
	end
end

function MainGameScene:build_rooms(map_data)
	self.rooms = {}

	for i=1,3 do
		local room = RoomScene(0, 0, nil)
		self:add_object(room)
		self.rooms[i] = room
	end

end

function MainGameScene:switch_room(room)
	if self.current_room then
		self.current_room:destroy_player()
		self.current_room:hide()
		self.current_room:set_update(false)
	end

	self.current_room = room

	self.current_room:add_player(self:create_player(0, 0))
	self.current_room:show()
	self.current_room:set_update(true)
end

function MainGameScene:on_room_entered(room)
	self.current_room = room
end

function MainGameScene:create_player(x, y)
	if self.player ~= nil then 
		error("player already exists")
	end

	local player = obj.TestDungeonObject(x, y)
	
	player.destroyed:connect(function()
		self.player = nil
	end)

	player.player = true
	self.player = player
	player:set_update(true)
	player:show()

	return player
end

function MainGameScene:enter()
	local map_data = nil
	
	self:build_rooms(map_data)

	self.rooms[2].camera:set_limits(-10, -10, 500, 500) 

	self:switch_room(self.rooms[1])
	

end

return MainGameScene
