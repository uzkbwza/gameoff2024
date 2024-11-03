local RoomScene = GameScene:extend()
local obj = require("obj.dungeon_objects")

local SmoothCameraTarget = require("obj.smooth_camera_target")

function RoomScene:new(x, y, data)
	RoomScene.super.new(self, x, y, data)

	data = data or {
		name = "RoomScene",
		dimensions = Vec2(128, 128),
		exits = {}
	}

	self.name = data.name
	self.dimensions = Vec2(data.dimensions.x, data.dimensions.y)

	self.exits = data.exits

	self.exited = Signal()

	self:add_update_signals()
	self:create_bump_world(64)

	self.draw_sort  = function(a, b)
		return a.pos.y < b.pos.y
	end

	self:set_update(false)
	self:hide()

end

function RoomScene:update(dt)
	RoomScene.super.update(self, dt)
	for _, exit in pairs(self.exits) do
		if self.player.pos:distance_to(exit.pos) < 10 then
			self:exit_to(exit)
		end
	end
end

function RoomScene:draw()
	RoomScene.super.draw(self)
	graphics.set_color(1, 1, 1, 1)
	graphics.rectangle("line", -self.dimensions.x/2, -self.dimensions.y/2, self.dimensions.x, self.dimensions.y)
	for _, exit in pairs(self.exits) do
		graphics.circle("line", exit.pos.x, exit.pos.y, 5)
	end
end

function RoomScene:exit_to(exit)
	self.exited:emit(exit)
end

function RoomScene:add_player(obj)
	self:add_object(obj)
	self.camera_target = self:add_object(SmoothCameraTarget(obj, 3))
	self.player = obj
	self.camera:follow(self.camera_target)
end

function RoomScene:destroy_player()
	self.player:destroy()
	self.camera_target:destroy()
	self.player = nil
end

return RoomScene
