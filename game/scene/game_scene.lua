local Camera = require("obj.camera")
local bump = require("lib.bump")

local elapsed = 0.0

local GameScene = GameObject:extend()

-- Helper functions
local function add_to_array(array, indices, obj)
    if indices[obj] then
        return -- Object already in array
    end
    table.insert(array, obj)
    indices[obj] = #array
end

local function remove_from_array(array, indices, obj)
    local index = indices[obj]
    if not index then
        return -- Object not in array
    end
    local last = array[#array]
    array[index] = last
    indices[last] = index
    array[#array] = nil
    indices[obj] = nil
end

function GameScene:new()
    GameScene.super.new(self)
	self.scene = self


    self.objects = {}
    self.objects_indices = {}

    self.update_objects = {}
    self.update_indices = {}

    self.draw_objects = {}
    self.draw_indices = {}
	self.bump_world = nil

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

	self.follow_camera = true

    self:add_sequencer()
    self:add_elapsed_time()
    self:add_elapsed_ticks()

    self.scene_pushed = Signal()
    self.scene_popped = Signal()

    self.interp_fraction = 0

    self.viewport_size = Vec2(conf.viewport_size.x, conf.viewport_size.y)
    self.camera = self:add_object(Camera())

end

function GameScene:create_bump_world(cell_size)
	cell_size = cell_size or 64
	self.bump_world = bump.newWorld(cell_size)

end

function GameScene:update_shared(dt)
    GameScene.super.update_shared(self, dt)

    for _, obj in ipairs(self.update_objects) do
        obj:update_shared(dt)
    end
end

function GameScene:update(dt)
end


function GameScene:draw()
    if self.draw_sort then
        table.sort(self.draw_objects, self.draw_sort)
    end
	
    for i, obj in ipairs(self.draw_objects) do
        self.draw_indices[obj] = i
    end


	for _, obj in ipairs(self.draw_objects) do
		obj:draw_shared()
	end

	if debug.can_draw() then 
		for _, obj in ipairs(self.draw_objects) do
			obj:debug_draw_bounds()
		end
		for _, obj in ipairs(self.draw_objects) do
			obj:debug_draw_shared()
		end
	end


end

function GameScene:draw_shared()
	if self.clear_color then
		graphics.push()
		graphics.origin()
		graphics.clear(self.clear_color.r, self.clear_color.g, self.clear_color.b)
		graphics.pop()
	end

    graphics.push()
	local offset = Vec2(0, 0)
	local zoom = 1.0
	if self.follow_camera then
		zoom = self.camera.zoom
		self.camera.viewport_size = self.viewport_size
		offset = self:get_object_draw_position(self.camera)

		if self.camera.following then
			offset = self:get_object_draw_position(self.camera.following)
		end

		offset = self.camera:clamp_to_limits(offset)
	
		offset.y = -offset.y + (self.viewport_size.y / 2) / zoom
		offset.x = -offset.x + (self.viewport_size.x / 2) / zoom
	end

	graphics.set_color(1, 1, 1, 1)
    graphics.scale(zoom, zoom)
    graphics.translate(floor(offset.x), floor(offset.y))
    self:draw()
    graphics.pop()
end

function GameScene:get_object_draw_position(obj)
    return obj.pos:clone()
end

function GameScene:enter_shared()
    self.input = input.dummy
    self:enter()
end

function GameScene:spawn_object(obj)
	return self:add_object(obj)
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

function GameScene:get_input_table()
	return self:get_base_scene().input
end

function GameScene:get_base_scene()
	local s = self.scene
	while s ~= s.scene do
		s = s.scene
	end
	return s
end

function GameScene:add_object(obj)
    obj.scene = self
	obj.base_scene = self:get_base_scene()
    add_to_array(self.objects, self.objects_indices, obj)

	self:add_to_update_tables(obj)

    if obj.visibility_changed then
        obj.visibility_changed:connect(function()
            if obj.visible then
                add_to_array(self.draw_objects, self.draw_indices, obj)
            else
                remove_from_array(self.draw_objects, self.draw_indices, obj)
            end
        end)
    end

    if obj.update_changed then
        obj.update_changed:connect(function()
            if not obj.static then
                add_to_array(self.update_objects, self.update_indices, obj)
            else
                remove_from_array(self.update_objects, self.update_indices, obj)
            end
        end)
    end

    obj.destroyed:connect(function() self:remove_object(obj) end, true)

	if obj.is_bump_object then 
		obj:set_bump_world(self.bump_world)
	end

    obj:enter_shared()
	obj.added:emit()

    return obj
end

function GameScene:add_to_update_tables(obj)

    if not obj.static then
        add_to_array(self.update_objects, self.update_indices, obj)
    end

    if obj.draw and obj.visible then
        add_to_array(self.draw_objects, self.draw_indices, obj)
    end

end

function GameScene:remove_object(obj)
	if not obj.scene == self then
		return
	end

    obj.scene = nil
	obj.base_scene = nil
    remove_from_array(self.objects, self.objects_indices, obj)
    remove_from_array(self.update_objects, self.update_indices, obj)
    remove_from_array(self.draw_objects, self.draw_indices, obj)
	if obj.is_bump_object then
		self.bump_world:remove(obj)
		obj:set_bump_world(nil)
	end
	obj.removed:emit()
end

return GameScene
