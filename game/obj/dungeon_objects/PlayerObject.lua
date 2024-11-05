local PlayerObject = require("obj.dungeon_objects.DungeonObject"):extend()

local accel_speed = 0.11

function PlayerObject:new(x, y)
	PlayerObject.super.new(self, x, y)
	self:init_basic_physics()
	self.drag = 0.08
	self:bump_init{rect = Rect.centered(0, 0, 5, 5), solid=false, track_overlaps=true}
	-- self:bump_init({rect = self.collision_rect})
	-- self:add_update_signals()
	-- self:set_update(true)
	-- self:hide()
	self.exit_bumped = Signal()
end

function PlayerObject:update(dt)
	local input = self:get_input_table()
	local move = input.move_clamped

	if move.x ~= 0 or move.y ~= 0 then 
		self:apply_force(move.x * accel_speed, move.y * accel_speed)
	end

end

function PlayerObject:area_entered(other)
	if other and other.exit_to then
		self.exit_bumped:emit(other.exit_to)
	end
	-- other:destroy()
end

function PlayerObject:draw()
	local r = self.collision_rect
	-- graphics.rectangle("fill", -r.width/2, -r.height/2, r.width, r.height)
	graphics.draw_centered(textures.player)
end

return PlayerObject
