local PlayerObject = require("obj.dungeon_objects.DungeonObject"):extend()

local accel_speed = 0.11
local interact_dist = 8
local hold_dist = 6
local hold_speed = 2

function PlayerObject:new(x, y)
	PlayerObject.super.new(self, x, y)
	
	self:bump_init{
		rect = Rect.centered(0, 0, 5, 5),
		solid=false, 
		track_overlaps=true,
		filter = function(item, other) 
			if self.holding == other then 
				return "cross" 
			end
			return self.default_bump_filter(item, other)
		end
	}

	self:add_signal("exit_bumped")
	self.is_player = true

	self.interact_rect = Rect.centered(0, 0, 12, 12)

	self.holding = nil

	self.facing = Vec2(0, 0)

	self.hold_offset = Vec2(0, 0)
end

function PlayerObject:update(dt)
	local input = self:get_input_table()
	local move = input.move_clamped

	if move.x ~= 0 or move.y ~= 0 then
		local interact_x = move.x * interact_dist
		local interact_y = move.y * interact_dist

		self.facing.x = move.x
		self.facing.y = move.y
		self.facing:normalize_in_place()
		self.interact_rect:center_to(interact_x, interact_y)
		self:apply_force(move.x * accel_speed, move.y * accel_speed)
	end

	self.hold_offset.x = self.facing.x
	self.hold_offset.y = self.facing.y

	self.hold_offset:normalize_in_place():mul_in_place(hold_dist)

	if self.holding then
		local hx, hy = splerp_vec_unpacked(self.holding.pos.x, self.holding.pos.y, self.pos.x + self.hold_offset.x, self.pos.y + self.hold_offset.y + 1, dt, 30)

		self.holding:move_toward(self.pos.x + self.hold_offset.x, self.pos.y + self.hold_offset.y, hold_speed * dt)
		-- self.holding:move_to(hx, hy)
		if self.holding.is_simple_physics_object then
			self.holding.vel:mul_in_place(0.0)
		end
		if self.holding.pos:distance_to(self.pos) > hold_dist * 4 then
			self:drop_item()
		end
		-- self.holding.noclip = self.holding.pos:distance_to(self.pos) > hold_dist
		-- self.holding.noclip = true
	end

	if input.primary_pressed then
		if self.holding == nil then
			self:interact()
		else
			self:use_held_item()
		end
	end

	if input.secondary_pressed then
		if self.holding == nil then
			self:pickup()
		else
			self:drop_item()
		end
	end

	if input.debug_count_memory_pressed then
		table.pretty_print(self.signals)
	end
end

function PlayerObject:use_held_item()
	if self.holding == nil then return end
	if self.holding.is_usable then
		local should_drop = self.holding:on_use(self)
		if should_drop then
			self:drop_item()
		end
	end
end

function PlayerObject:interact()
	local obj = self:get_closest_overlapping_object(
		self.interact_rect,
		function(o) 
			return (o.on_interact) and o ~= self.holding
		end
	)
	if obj == nil then return end
	
	-- if obj.is_pickupable and not obj.is_interactable then
	-- 	self:pickup(obj)
	-- 	return
	-- end
	obj:on_interact(self)
end

function PlayerObject:pickup(obj)
	obj = obj or self:get_closest_overlapping_object(
		self.interact_rect,
		function(o) 
			return o.is_pickupable
		end
	)

	if obj == nil then return end

	if self.holding then
		self:drop_item()
	end
	self.holding = obj

	if self.holding then
		self:add_child(self.holding)
		self.holding.held_by = self
	end
end

function PlayerObject:drop_item()
	if self.holding then
		-- self.holding.noclip = true
		-- self.holding:move_to(self.pos.x, self.pos.y)
		self.holding.noclip = false
		-- self.holding:move_to(self.pos.x + self.hold_offset.x, self.pos.y + self.hold_offset.y)
		if self.holding.is_simple_physics_object then
			self.holding.vel.x = self.vel.x
			self.holding.vel.y = self.vel.y
		end
		self.holding.held_by = nil
		self.holding = nil
		self:remove_child(self.holding)
		
	end
end

function PlayerObject:area_entered(other)
	if other == nil then return end
	if other.exit_to and other.openable then
		self.exit_bumped:emit(other.exit_to)
	end
	-- if other.floor_type then
	-- end
end

function PlayerObject:draw()
	local r = self.collision_rect
	-- graphics.rectangle("fill", -r.width/2, -r.height/2, r.width, r.height)
	graphics.draw_centered(textures.player)
end

function PlayerObject:debug_draw_bounds()
	PlayerObject.super.debug_draw_bounds(self)
	graphics.draw_collision_box(self.interact_rect, palette.lilac, 1.0)
end

return PlayerObject
