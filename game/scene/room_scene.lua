local RoomScene = GameScene:extend()
local obj = require("obj.dungeon_objects")
local map = require("map")

local SmoothCameraTarget = require("obj.smooth_camera_target")

local TILE_SIZE = 12

function RoomScene:new(x, y, data)
	RoomScene.super.new(self, x, y, data)

	self.build_data = data
	self.player = nil
	self.exited = Signal()

	self:add_update_signals()

	self.exits = {}
	self.room_strings = {}

	self:create_bump_world(64)

	self.draw_sort  = function(a, b)
		return a.pos.y + a.z_index < b.pos.y + b.z_index
	end

	self:set_update(false)
	self:hide()

end

function RoomScene:create_boundary(rect)
	local wall = GameObject(rect.x + rect.width/2, rect.y + rect.height/2)
	local centered = Rect.centered(0, 0, rect.width, rect.height)
	
	wall:add_update_signals()
	wall:set_update(false)
	wall:bump_init({rect = centered})
	
	wall.draw = function() end
	self:add_object(wall)

	wall.z_index = -1
	return wall
end

function RoomScene:update(dt)
	RoomScene.super.update(self, dt)
end

function RoomScene:draw()
	if debug.can_draw() then
		love.graphics.setColor(1, 1, 1, 1/32)
		graphics.rectangle("fill", self.center.x + -self.dimensions.x/2 + 1, self.center.y + -self.dimensions.y/2 + 1, self.dimensions.x - 1, self.dimensions.y - 1)
		graphics.set_color(1, 1, 1, 1/4)
		graphics.rectangle("line", self.center.x -self.dimensions.x/2 + 1, self.center.y + -self.dimensions.y/2 + 1, self.dimensions.x - 1, self.dimensions.y - 1)
	end
	RoomScene.super.draw(self)
end

function RoomScene:exit_to(exit)
	self.exited:emit(exit)
end



function RoomScene:build_from_data(build_data)
	local processed_data = RoomScene.process_data(build_data)
	self.dimensions = (processed_data.bounds.bottomright - processed_data.bounds.topleft) * TILE_SIZE
	self.center = (processed_data.bounds.bottomright / 2 + processed_data.bounds.topleft) * TILE_SIZE

	for _, string in pairs(processed_data.strings) do
		table.insert(self.room_strings, string)
	end

	self.camera:set_limits(
		(processed_data.bounds.topleft.x - 1) * TILE_SIZE, 
		(processed_data.bounds.topleft.y - 1) * TILE_SIZE, 
		(processed_data.bounds.bottomright.x + 2) * TILE_SIZE, 
		(processed_data.bounds.bottomright.y + 2) * TILE_SIZE
	)
	self.player_spawn_location = self.center
	for _, layer in ipairs(processed_data.layers) do
		for y, line in pairs(layer.tiles) do
			for x, tile in pairs(line) do 
				self:build_from_tile(tile, x, y)
			end
		end
	end
end

function RoomScene:build_from_tile(tile, x, y)
	if tile == nil then
		return
	end

	local pos = TILE_SIZE * Vec2(x, y) + Vec2(TILE_SIZE / 2, TILE_SIZE / 2)

	if not tile.nofloor then
		self:add_object(obj.Floor(pos.x, pos.y, TILE_SIZE))
	end

	if tile.wall then
		self:add_object(obj.Wall(pos.x, pos.y, TILE_SIZE))
	end

	if tile.player_spawn then
		self.player_spawn_location = pos
	end

	if tile.exit then
		local processed = self:process_exit_string(tile.exit)
		local exit = obj.Exit(pos.x, pos.y, TILE_SIZE, tile.exit, processed)
		local enter_pos = pos

		exit.side = processed.facing_direction == "right" or processed.facing_direction == "left"

		if processed.facing_direction == "up" then
			enter_pos = pos + Vec2(0, -TILE_SIZE)
		elseif processed.facing_direction == "down" then
			enter_pos = pos + Vec2(0, TILE_SIZE)
		elseif processed.facing_direction == "left" then
			enter_pos = pos + Vec2(-TILE_SIZE, 0)
		elseif processed.facing_direction == "right" then
			enter_pos = pos + Vec2(TILE_SIZE, 0)
		end

		self.exits[tile.character] = table.merged({
			enter_pos = enter_pos
		}, processed)
		
		self:add_object(exit)
	end

	if tile.torch then 
		local torch = self:add_object(obj.Torch(pos.x, pos.y, TILE_SIZE))
		if tile.lit then 
			torch:light()
		end
	end
end

function RoomScene.process_data(data)
	local tile_data = table.merged(map.default_build_tile_data, data.tile_data)

	local layers = {}
	local strings = data.tiles

	local bounds_min_x = math.huge
	local bounds_max_x = -math.huge
	local bounds_min_y = math.huge
	local bounds_max_y = -math.huge


	for _, str in ipairs(strings) do 
		local min_x = math.huge
		local max_x = -math.huge
		local min_y = math.huge
		local max_y = -math.huge

		local layer_data = {
			tiles = {}
		}

		local shrunk = string.strip_whitespace(str:gsub(" ", ""))
		for y, line in ipairs(string.split(shrunk, "\n")) do 
			local strippedline = string.strip_whitespace(line)
			layer_data.tiles[y] = {}
			for x = 1, #strippedline do 
				local char = strippedline:sub(x, x)
				if char == "_" then goto continue end
				local data = table.merged({character = char}, tile_data[char])

				layer_data.tiles[y][x] = data or {}
				
				if x < min_x then min_x = x
				elseif x > max_x then max_x = x end
				::continue::
			end
			if y < min_y then min_y = y
			elseif y > max_y then max_y = y end
		end

		if min_x < bounds_min_x then bounds_min_x = min_x end
		if max_x > bounds_max_x then bounds_max_x = max_x end
		if min_y < bounds_min_y then bounds_min_y = min_y end
		if max_y > bounds_max_y then bounds_max_y = max_y end

		layer_data.bounds = {
			topleft = Vec2(min_x, min_y),
			bottomright = Vec2(max_x, max_y)
		}

		table.insert(layers, layer_data)

	end

	return {
		layers = layers,
		strings = strings,
		bounds = {
			topleft = Vec2(bounds_min_x, bounds_min_y),
			bottomright = Vec2(bounds_max_x, bounds_max_y)
		}
	}
end


function RoomScene:process_exit_string(s)
	local split = string.split(s, ":")
	return {
		to_map = split[1],
		to_entrance = split[2],
		facing_direction = split[3]
	}
end

function RoomScene:enter()
	self:build_from_data(self.build_data)
	
	-- self:create_boundary(Rect(-self.dimensions.x/2 -16, -self.dimensions.y/2 - 16, self.dimensions.x + 32, 16))
	-- self:create_boundary(Rect(-self.dimensions.x/2 -16, -self.dimensions.y/2 - 16, 16, self.dimensions.y + 32))
	-- self:create_boundary(Rect(-self.dimensions.x/2 -16, self.dimensions.y/2, self.dimensions.x + 32, 16))
	-- self:create_boundary(Rect(self.dimensions.x/2, -self.dimensions.y/2 - 16, 16, self.dimensions.y + 32))
	
	-- local area_object = GameObject(20, 20)
	-- -- area_object:add_update_signals()
	-- -- area_object:set_update(false)
	-- area_object:bump_init({rect = Rect.centered(0, 0, 16, 16), solid = false})
	-- area_object.draw = function() end
	-- self:add_object(area_object)

end

function RoomScene:add_player(obj)
	self:add_object(obj)
	self.camera_target = self:add_object(SmoothCameraTarget(obj, 6))
	self.player = obj

	if self.exit_function == nil then 
		self.exit_function = function(exit) 
			self:exit_to(self:process_exit_string(exit))
		end
	end
	
	self.player.exit_bumped:connect(
		self,
		self.exit_function,
		true
	)

	self.camera:follow(self.camera_target)
end

function RoomScene:remove_player()
	local p = self.player
	self:remove_object(p)
	self.camera_target:destroy()
	self.camera:follow(nil)
	p:clear_signals()
	return p
end 

return RoomScene
