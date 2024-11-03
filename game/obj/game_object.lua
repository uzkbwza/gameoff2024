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

	self._update_functions = {}

	self.scene = nil
	
	self.visible = true

	-- signals
	self.visibility_changed = nil
	self.update_changed = nil
	self.static = false

	self.is_bump_object = nil

end

function GameObject:on_moved()
	self.moved:emit()
end

function GameObject.dummy() end


function GameObject:add_sequencer()
	assert(self.sequencer == nil, "GameObject:add_sequencer() called but sequencer already exists")
	self.sequencer = Sequencer()
	table.insert(self._update_functions, function(dt) self.sequencer:update(dt) end)
end

function GameObject:add_elapsed_time()
	self.elapsed = 1
	table.insert(self._update_functions, function(dt) self.elapsed = self.elapsed + dt end)
end

function GameObject:add_elapsed_ticks()
	assert(self.elapsed ~= nil, "GameObject:add_elapsed_ticks() called but no elapsed time implemented")
	self.tick = 1
	table.insert(self._update_functions, function(dt) self.tick = floor(self.elapsed) end)
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
	-- old method from when interpolation was used
	self:move_to(x, y, nil, true)
end

function GameObject:tpv_to(v)
	self:tp_to(v.x, v.y)
end


function GameObject:set_update(on)
	self.static = not on
	self.update_changed:emit()
end

function GameObject:update(dt, ...)
end

function GameObject:draw_shared(...)

	local pos = self.pos
	local scale = self.scale
	-- end
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.push()
	love.graphics.translate(pos.x, pos.y)
	love.graphics.rotate(self.rot)
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
