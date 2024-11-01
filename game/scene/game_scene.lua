local GameScene = GameObject:extend()

local Camera = require("obj.camera")

local elapsed = 0.0

function GameScene:new()
	GameScene.super.new(self)

	self.objects = {}
	self.fixed_update_objects = {}
	self.update_objects = {}
	self.draw_objects = {}

	
	-- function to sort draw objects
	self.draw_sort = nil
	--[[	example: y-sorting function for draw objects
	
	self.draw_sort = function(a, b)
		return a.pos.y < b.pos.y
	end

	]]--

	self.blocks_logic = true
	self.blocks_render = true
	self.blocks_input = true
	
	self:add_sequencer()
	self:add_fixed_sequencer()
	self:add_elapsed_time()
	self:add_elapsed_ticks()
	self:add_elapsed_frames()

	self.scene_pushed = Signal()
	self.scene_popped = Signal()

	self.interp_fraction = 0

	self.viewport_size = Vec2(conf.viewport_size.x, conf.viewport_size.y)
	self.camera = self:add_object(Camera())

	self.scene = self
	-- self.camera.pos = self.viewport_size / 2

end

function GameScene:update_shared(dt)

	GameScene.super.update_shared(self, dt)

	for obj, _ in pairs(self.update_objects) do
		obj:update_shared(dt)
	end

end

function GameScene:update(dt)
end

function GameScene:fixed_update_shared(dt)

	GameScene.super.fixed_update_shared(self, dt)

	for obj, _ in pairs(self.fixed_update_objects) do
		obj:fixed_update_shared(dt)
	end

end

function GameScene:fixed_update(dt)
end

function GameScene:draw()
	if self.draw_sort then
		local sorted = {}
		for obj, _ in pairs(self.draw_objects) do
			table.insert(sorted, obj)
		end
		table.sort(sorted, self.draw_sort)
		for _, obj in ipairs(sorted) do
			obj:draw_shared()
		end
		return
	else	
		for obj, _ in pairs(self.draw_objects) do
			obj:draw_shared()
		end
	end
	
end

function GameScene:draw_shared()
	graphics.push()
	local zoom = self.camera.zoom
	self.camera:update_interpolated_position()
	local offset = self:get_object_draw_position(self.camera)

	if self.camera.following then
		self.camera.following:update_interpolated_position()
		offset = self:get_object_draw_position(self.camera.following)

	end
	offset.y = -offset.y + (self.viewport_size.y / 2) / zoom
	offset.x = -offset.x + (self.viewport_size.x / 2) / zoom
	graphics.scale(zoom, zoom)
	graphics.translate(offset.x, offset.y)
	self:draw()
	graphics.pop()
end

function GameScene:get_object_draw_position(obj)
	return obj.i_pos
end

function GameScene:enter_shared()
	self.input = input.dummy
	self:enter()
end

function GameScene:exit_shared()
	self:exit()
end

function GameScene:enter()

end

function GameScene:exit()
end

function GameScene:push(scene_name)
	self.scene_pushed:emit(scene_name)
end

function GameScene:pop()
	self.scene_popped:emit()
end

function GameScene:add_object(obj)
	obj.scene = self
	self.objects[obj] = true

	if not obj.static then
		self.fixed_update_objects[obj] = true
		self.update_objects[obj] = true
	end

	if obj.draw then
		self.draw_objects[obj] = true
	end

	if obj.visibility_changed then
		obj.visibility_changed:connect(function(visible)
			if visible then
				self.draw_objects[obj] = true
			else
				self.draw_objects[obj] = nil
			end
		end)
	end

	if obj.update_changed then
		obj.update_changed:connect(function(update)
			if update then
				self.update_objects[obj] = true
			else
				self.update_objects[obj] = nil
			end
		end)
	end

	if obj.fixed_update_changed then
		obj.fixed_update_changed:connect(function(fixed_update)
			if fixed_update then
				self.fixed_update_objects[obj] = true
			else
				self.fixed_update_objects[obj] = nil
			end
		end)
	end

	obj.destroyed:connect(function() self:remove_object(obj) end )

	obj:enter_shared()
	return obj
end

function GameScene:remove_object(obj)
	obj.scene = nil
	self.objects[obj] = nil
	self.fixed_update_objects[obj] = nil
	self.update_objects[obj] = nil
	self.draw_objects[obj] = nil
end

return GameScene
