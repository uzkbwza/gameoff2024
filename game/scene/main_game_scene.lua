local obj = require("obj.dungeon_objects")
local RoomScene = require("scene.room_scene")
local fsm = require("lib.fsm")

local MainGameScene = GameScene:extend()

function MainGameScene:new()
	MainGameScene.super.new(self)
	self:create_bump_world(64)
	
	self.follow_camera = false
	self.current_room = nil
	self.state_machine = fsm.StateMachine()

	self:add_update_function(function(dt) self.state_machine:update(dt) end)
end

function MainGameScene:update(dt)
	MainGameScene.super.update(self, dt)
end

function MainGameScene:build_rooms(map_data)
	self.rooms = {}

	local exit_function = function(exit_data) 
		self.state_machine:change_state(
			"TransitionRooms",
			exit_data.room,
			self.rooms[exit_data.room].exits[self.current_room.name].enter_pos.x,
			self.rooms[exit_data.room].exits[self.current_room.name].enter_pos.y
		)
	end

	for _, data in ipairs(map_data) do
		local room = RoomScene(0, 0, data)
		room.exited:connect(exit_function)
		self:add_object(room)
		self.rooms[data.name] = room
    end


end

function MainGameScene:switch_room(room, player_x, player_y)
	player_x = player_x or 0
	player_y = player_y or 0
	
	if type(room) == "string" then
		room = self.rooms[room]
	end

	if self.current_room then
		self.current_room:destroy_player()
		self.current_room:hide()
		self.current_room:set_update(false)
	end

	self.current_room = room

	self.current_room:add_player(self:create_player(player_x, player_y))
	self.current_room:show()
end

function MainGameScene:on_room_entered(room)
	self.current_room = room
end

function MainGameScene:create_player(x, y)
	if self.player ~= nil then 
		error("player already exists")
	end

	local player = obj.PlayerObject(x, y)
	
	player.destroyed:connect(function()
		self.player = nil
	end)

	self.player = player

	return player
end

function MainGameScene:enter()
	local map_data = nil
	
	self:build_rooms({
		{
			name = "Room1",
			dimensions = Vec2(200, 150),
			exits = {
				Room2 = {
					room = "Room2", 
					pos = Vec2(105, 75/2),
					enter_pos = Vec2(95, 75/2)
				}
			}
		},
		{
			name = "Room2",
			dimensions = Vec2(200, 150),
			exits = {
				Room1 = {
					room = "Room1", 
					pos = Vec2(-105, -75/2),
					enter_pos = Vec2(-95, -75/2)
				}
			}
		}
	})

	-- self.rooms[1].camera:set_limits(-10, -10, 500, 500) 

	self:switch_room("Room1")
	
	self:setup_states()
end

function MainGameScene:setup_states()
	
	self.state_machine:add_states{
		fsm.State{
			name = "Update",

			enter = function() 
				self.current_room:set_update(true)
			end,

			update = function() 

			end,

			exit = function()
				self.current_room:set_update(false)
			end
		},

		fsm.State{
			name = "TransitionRooms",

			enter = function(go, next_room, x, y)
				local s = self.sequencer
				s:start_chain(
					-- s:wait(5),
					function() 
						self:switch_room(next_room, x, y) 
					end,
					-- s:wait(5),
					function() 
						go("Update") 
					end
				)
			end
		}
	}

end

return MainGameScene
