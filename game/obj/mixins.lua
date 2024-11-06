local Flammable = Object:extend()
local Pickupable = Object:extend()

function Flammable._init(self)
	self.flammable = true
	self:add_area_entered_function(
		function(self, other)
			if other.flammable and other.lit and not self.lit then
				self:light()
			end
		end
	)
end

function Flammable:light()
	if self.lit then return end
	local s = self.sequencer
	self.lit = true 
	s:do_while(
		function() return self.lit end,
		function() 
			s:wait(rng.randf_range(1, 7))
			self:spawn_particle()
		end
	)
end

function Flammable:extinguish()
	self.lit = false
end

function Flammable:spawn_particle()
	local p = Effect()
	
	p.duration = rng.randf_range(10, 60)
	p.start_size = rng.randf_range(1, 4)
	p.size = p.start_size
	p.start_pos = Vec2(rng(-2, 2), rng(-2, 2))

	-- local xdir = rng(-1, 1)

	local dx = rng.randf_range(-0.001, 0.001)

	local start_x = self.pos.x

	p.z_pos = -4
	p.draw = function(p, elapsed, ticks, t)
		p.z_pos = -4 - elapsed * 0.1
		p.pos.x = start_x + p.start_pos.x + dx * elapsed
		p.size = (p.start_size * (1 - t))

		if p.size / p.start_size < 0.2 then
			graphics.set_color(palette.black)
		elseif p.size / p.start_size < 0.4 then 
			graphics.set_color(palette.maroon)
		elseif p.size / p.start_size < 0.6 then
			graphics.set_color(palette.red)
		elseif p.size / p.start_size < 0.8 then
			graphics.set_color(palette.orange)
		else
			graphics.set_color(palette.yellow)
		end

		graphics.circle("fill", 0, 0, p.size)
	end

	self:spawn_object(p, p.start_pos.x, p.start_pos.y)
end

function Pickupable._init(self)
	self.is_pickupable = true
end


return {
	Flammable = Flammable,
	Pickupable = Pickupable,
}
