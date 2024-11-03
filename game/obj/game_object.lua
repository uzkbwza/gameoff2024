local GameObject = Object:extend()

function GameObject:new(x, y)
	--- remember to use GameObject.super.new(self, x, y)
	-- self:setup_base_functions()

	self.destroyed = Signal()
	self.removed = Signal()
	self.added = Signal()
	self.moved = Signal()

	if x then
		if type(x) == "table" then
			self.pos = Vec2(x.x, x.y)
		else
			self.pos = Vec2(x, y)
		end
	else
		self.pos = Vec2(0, 0)
	end

	self.rot = 0
	self.scale = Vec2(1, 1)


	-- interpolation stuff
	self.i_prev_pos = Vec2(self.pos.x, self.pos.y)
	self.i_pos = Vec2(self.pos.x, self.pos.y)
	self.i_prev_rot = self.rot
	self.i_prev_scale = Vec2(self.scale.x, self.scale.y)
	self.i_rot = self.rot
	self.i_scale = Vec2(self.scale.x, self.scale.y)

	self._update_functions = {}

	self._fixed_update_functions = {}

	self.scene = nil
	
	self.visible = true

	-- signals
	self.visibility_changed = nil
	self.update_changed = nil
	self.static = false
	self.should_update_interpolation = false

	self.is_bump_object = nil

end

function GameObject:on_moved()
	self.should_update_interpolation = true
	self.moved:emit()
end

function GameObject.dummy() end

-- function GameObject:setup_base_functions()
-- 	if conf.interpolate_timestep then
-- 		self.draw_shared = self.draw_shared_interpolated
-- 	else
-- 		self.update_interpolated_position = GameObject.dummy
-- 		self.reset_interpolation = GameObject.dummy
-- 		self.draw_shared = self.draw_shared_uninterpolated
-- 	end
-- end


function GameObject:add_scale2()
	self.scale2 = Vec2(1, 1)
	self._prev_scale2_viz = Vec2(self.scale2.x, self.scale2.y)
	self.i_scale2 = Vec2(self.scale2.x, self.scale2.y)
	self.has_scale2 = true
end

function GameObject:add_sequencer()
	assert(self.sequencer == nil, "GameObject:add_sequencer() called but sequencer already exists")
	self.sequencer = Sequencer()
	table.insert(self._update_functions, function(dt) self.sequencer:update(dt) end)
end

function GameObject:add_fixed_sequencer()
	assert(self.fixed_sequencer == nil, "GameObject:add_fixed_sequencer() called but fixed_sequencer already exists")
	self.fixed_sequencer = Sequencer()
	table.insert(self._fixed_update_functions, function(dt) self.fixed_sequencer:update(dt) end)
end

function GameObject:add_elapsed_time()
	self.elapsed = 1
	table.insert(self._update_functions, function(dt) self.elapsed = self.elapsed + dt end)
end

function GameObject:add_elapsed_ticks()
	self.tick = 1
	table.insert(self._fixed_update_functions, function(dt) self.tick = self.tick + 1 end)
end

function GameObject:add_elapsed_frames()
	self.frame = 1
	table.insert(self._update_functions, function(dt) self.frame = self.frame + 1 end)
end

function GameObject:update_shared(dt, ...)
	-- assert(self.update ~= nil, "GameObject:update_shared() called but no update function implemented")
	self:update(dt, ...)
	for _, func in ipairs(self._update_functions) do
		func(dt, ...)
	end
end

function GameObject:add_update_signals()
	self.update_changed = Signal()
	self.visibility_changed = Signal()
end

function GameObject:spawn_object(obj)
	obj.pos = self.pos:clone()
	self.scene:add_object(obj)
end

function GameObject:get_input_table()
	return self.base_scene:get_input_table()
end

function GameObject:get_interp_fraction()
	return self.base_scene.interp_fraction
end

function GameObject:movev(dv)
	self:move(dv.x, dv.y)
end

function GameObject:move(dx, dy)
	self:move_to(self.pos.x + dx, self.pos.y + dy)
end

function GameObject.default_bump_filter(item, other)
	return "slide"
end

function GameObject:hide()
	if not self.visible then
		return
	end
	self.visible = false
	self.visibility_changed:emit()
end

function GameObject:show()
	if self.visible then
		return
	end
	self.visible = true
	self.visibility_changed:emit()
end

function GameObject:bump_init(info_table, filter)

	-- initializes bump.lua physics with AABB collisions and spatial hashing. useful even for non-physics objects for collision detection for e.g. coins
	info_table = info_table or {
		rect = Rect.centered(0, 0, 16, 16)
	}

	-- TODO: position centered on feet?
	assert(info_table.rect.x == -info_table.rect.width / 2 and info_table.rect.y == -info_table.rect.height / 2, "collision rect must be centered")

	filter = filter or GameObject.default_bump_filter
	self.is_bump_object = true
	self.collision_rect = (info_table.rect) or Rect(0, 0, 0, 0)
	self.move_to = GameObject.move_to_bump
	self.bump_filter = filter
	self.bump_filter_checks = {}
	self.bump_world = nil
end

function GameObject:set_bump_collision_rect(rect)
	self.collision_rect = rect
	self.world:update(self, self.pos.x - self.collision_rect.width / 2, self.pos.y - self.collision_rect.height / 2, self.collision_rect.width, self.collision_rect.height)
end

function GameObject:set_bump_world(world)
	self.bump_world = world
	if world then
		world:add(self, self.pos.x - self.collision_rect.width / 2, self.pos.y - self.collision_rect.height / 2, self.collision_rect.width, self.collision_rect.height)
	end
end

function GameObject:move_to_bump(x, y, filter, noclip)
	
	local old_x = self.pos.x
	local old_y = self.pos.y

	filter = filter or self.filter
	if noclip then 
		self.pos.x = x
		self.pos.y = y
		if old_x ~= self.pos.x or old_y ~= self.pos.y then
			self:on_moved()
		end
		return
	end
	local actual_x, actual_y, collisions, num_collisions = self.bump_world:move(self, x - self.collision_rect.width / 2, y - self.collision_rect.height / 2, filter)
	self.pos.x = actual_x + self.collision_rect.width / 2
	self.pos.y = actual_y + self.collision_rect.height / 2

	for i = 1, num_collisions do
		local col = collisions[i]
		self:process_collision(col.other, col.dx, col.dy)
	end

	if old_x ~= self.pos.x or old_y ~= self.pos.y then
		self:on_moved()
	end
end

function GameObject:process_collision(other, dx, dy)
end

---@diagnostic disable-next-line: duplicate-set-field
function GameObject:move_to(x, y)
	local old_x = self.pos.x
	local old_y = self.pos.y

	self.pos.x = x
	self.pos.y = y

	if old_x ~= self.pos.x or old_y ~= self.pos.y then
		self:on_moved()
	end
end

function GameObject:movev_to(v)
	self:move_to(v.x, v.y)
end

function GameObject:tp_to(x, y)
	self:move_to(x, y, nil, true)
	self:reset_interpolation()
end

function GameObject:tpv_to(v)
	self:tp_to(v.x, v.y)
end

function GameObject:reset_interpolation()
	-- resets the physics interpolation
	-- print(self.i_prev_pos)

	self.i_prev_pos.x = self.pos.x
	self.i_prev_pos.y = self.pos.y
	self.i_prev_rot = self.rot
	self.i_prev_scale.x = self.scale.x
	self.i_prev_scale.y = self.scale.y
	self.should_update_interpolation = false
end

function GameObject:set_update(on)
	self.static = not on
	self.update_changed:emit()
end

function GameObject:fixed_update(dt, ...)
end

function GameObject:update(dt, ...)
end

function GameObject:fixed_update_shared(dt, ...)
	self:reset_interpolation()

	self:fixed_update(dt, ...)

	for _, func in ipairs(self._fixed_update_functions) do
		func(dt, ...)
	end
end

-- if you implement this it will be run
-- function GameObject:draw()
-- 	graphics.rectangle("fill", -50, -50, 100, 100)
-- end

-- function GameObject:draw_shared_interpolated(...)
-- 	self:update_interpolated_position()
-- 	self:_draw_shared(self.i_pos, self.i_rot, self.i_scale, ...)
-- end

-- function GameObject:draw_shared_uninterpolated(...)
-- 	self:_draw_shared(self.pos, self.rot, self.scale, ...)
-- end


function GameObject:update_interpolated_position()
	-- if true then return end
	local lerp = lerp
	local lerp_angle = lerp_angle
	local t = self:get_interp_fraction()
	-- print(self.pos)

	self.i_pos.x = lerp(self.i_prev_pos.x, self.pos.x, t)
	self.i_pos.y = lerp(self.i_prev_pos.y, self.pos.y, t)
	self.i_rot = lerp_angle(self.i_prev_rot, self.rot, t)
	self.i_scale.x = lerp(self.i_prev_scale.x, self.scale.x, t)
	self.i_scale.y = lerp(self.i_prev_scale.y, self.scale.y, t)
end

function GameObject:draw_shared(...)
-- end

-- function GameObject:_draw_shared(pos, rot, scale, ...)

	-- using my wrapper eats some performance so im not using it here
	-- local pos = self.i_pos
	-- local rot = self.i_rot
	-- local scale = self.i_scale
	-- local pos = self.pos
	-- local scale = self.scale
	-- local rot = self.rot
	-- if self.should_update_interpolation then
	self:update_interpolated_position()
	local pos = self.i_pos
	local scale = self.i_scale
	local rot = self.i_rot
	-- end
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.push()
	love.graphics.translate(pos.x, pos.y)
	love.graphics.rotate(rot)
	love.graphics.scale(scale.x, scale.y)

	self:draw(...)
	love.graphics.pop()
end

function GameObject:destroy()
	self.is_destroyed = true
	self:exit_shared()
	if self.sequencer then
		self.sequencer:destroy()
	end
	if self.fixed_sequencer then
		self.fixed_sequencer:destroy()
	end
	self.destroyed:emit()
end

function GameObject:enter_shared()
	self:enter()
end

function GameObject:enter() end

function GameObject:exit_shared()
	self:exit()
end

function GameObject:to_local(pos)
	return pos - self.pos
end

function GameObject:to_world(pos)
	return pos + self.pos
end

function GameObject:exit() end


return GameObject
