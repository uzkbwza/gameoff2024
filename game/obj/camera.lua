local Camera = GameObject:extend()

function Camera:new(x, y)
	Camera.super.new(self, x, y)
	self:add_sequencer()
	self:add_fixed_sequencer()
	self:add_elapsed_time()
	self:add_elapsed_ticks()
	self:add_elapsed_frames()
	self.following = nil
	self.zoom = 1
end

function Camera:follow(obj)
	self.following = obj
end

return Camera
