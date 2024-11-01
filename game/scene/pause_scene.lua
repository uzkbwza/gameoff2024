local GameScene = require("scene.game_scene")

local PauseScene = GameScene:extend()

function PauseScene:new()
	PauseScene.super.new(self)
	self.blocks_render = false
end

function PauseScene:update(dt)
	if self.input.menu_pressed then
		self:pop()
	end
end

function PauseScene:draw()
	PauseScene.super.draw(self)

	graphics.print("PAUSED", 0, 0)
end

function PauseScene:enter()
end

return PauseScene
