local obj = require("obj.dungeon_objects")
local RoomScene = require("scene.room_scene")
local fsm = require("lib.fsm")
local map = require("map")

local MainGameScene = GameScene:extend()

function MainGameScene:new()
	MainGameScene.super.new(self)
	self:create_bump_world(64)
	
	self.fade_alpha = 0

	self.follow_camera = false
	self.current_room = nil
	self.state_machine = fsm.StateMachine()

	self:add_update_function(function(obj, dt) obj.state_machine:update(dt) end)

	self.clear_color = palette.black
end

function MainGameScene:update(dt)
	MainGameScene.super.update(self, dt)
	if input.debug_editor_toggle_pressed then
		self:push("LevelEdit")
	end

end

function MainGameScene:build_rooms(map_data)
	self.rooms = {}

	local exit_function = function(exit_data)
		self.state_machine:change_state(
			"TransitionRooms",
			exit_data.to_map,
			self.rooms[exit_data.to_map].exits[exit_data.to_entrance].enter_pos.x,
			self.rooms[exit_data.to_map].exits[exit_data.to_entrance].enter_pos.y
		)
	end

	for key, data in pairs(map_data) do
		local room = RoomScene(0, 0, data)
		room.exited:connect(exit_function)
		self:add_object(room)
		self.rooms[key] = room
    end


end

function MainGameScene:switch_room(room, player_x, player_y)
	
	if type(room) == "string" then
		room = self.rooms[room]
	end

	player_x = player_x or room.player_spawn_location.x
	player_y = player_y or room.player_spawn_location.y

	if self.current_room then
		self.current_room:remove_player()
		self.current_room:hide()
		self.current_room:set_update(false)
	end

	self.current_room = room

	if self.player then
		self.player:tp_to(player_x, player_y)
	else
		self:create_player(player_x, player_y)
	end

	self.current_room:add_player(self.player)
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
	end, true)

	self.player = player

	return player
end

function MainGameScene:draw_shared()
	MainGameScene.super.draw_shared(self)
	local color = palette.black
	dbg("fade_alpha", self.fade_alpha)
	if self.fade_alpha > 0 then
		graphics.set_color(color, self.fade_alpha)
		graphics.rectangle("fill", 0, 0, self.viewport_size.x, self.viewport_size.y)
	end
end

function MainGameScene:enter()
	local map_data = nil
	
	self:build_rooms(map.maps)

	-- self.rooms[1].camera:set_limits(-10, -10, 500, 500) 

	self:switch_room("map1")
	
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
					s:tween_property(self, "fade_alpha", 0, 1, 5, "linear", 0.5),
					-- s:wait(5),
					function() 
						self:switch_room(next_room, x, y) 
						self.fade_alpha = 1
					end,
					s:wait(5),
					s:tween_property(self, "fade_alpha", 1, 0, 5, "linear", 0.5),
					-- s:wait(5),
					function() 
						go("Update") 
					end
				)
				-- self:switch_room(next_room, x, y)
				-- go("Update")
			end
		}
	}

end

return MainGameScene
