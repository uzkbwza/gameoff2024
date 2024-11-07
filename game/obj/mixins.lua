local Illuminator = Object:extend()
function Illuminator:_init(radius)
	self.illumination_radius = radius or 32
	self.illuminating = false

	self:add_update_function(
		Illuminator.illuminate
	)

	self:add_draw_function(
		Illuminator._draw
	)

	self.illuminated_objects = {}
end

function Illuminator:_draw()
	-- graphics.set_color(1, 1, 1, 1/4)
	-- graphics.circle("line", 0, 0, self.illumination_radius)
	if not self.illuminating then return end
	-- graphics.set_color(palette.yellow, 1/64)
	-- graphics.circle("line", 0, 0, self.illumination_radius)
	-- graphics.circle("line", 0, 0, self.illumination_radius - 1)

	graphics.set_color(self.illumination_color or palette.yellow, 1/64 + rng.randfn(0, 1/512))
	graphics.circle("fill", 0, 0, rng.randfn(self.illumination_radius, 0.5))
	graphics.set_color(1, 1, 1, 1)
end

function Illuminator:illuminate()
	if self.illuminating then
		local objs = self:get_overlapping_objects_in_rect(Rect.centered(0, 0, self.illumination_radius * 2, self.illumination_radius * 2))
		for _, obj in ipairs(objs) do
			if self.pos:distance_to(obj.pos) < self.illumination_radius then
				if obj.on_illuminated then
					obj:on_illuminated(self)
				end
			end
		end
	end
end

function Illuminator:activate_illumination()
	self.illuminating = true
end

function Illuminator:deactivate_illumination()
	self.illuminating = false
end

local Flammable = Object:extend()
function Flammable:_init(illumination_radius)
	assert(self.tracks_overlaps, "Flammable must track overlaps")

	self.flammable = true
	self.static = false
	self.on_fire = false


	if not self.sequencer then
		self:add_sequencer()
	end

	self:add_area_entered_function(
		function(self, other)
			if other.flammable and not other.on_fire and self.on_fire then
				other:light_flame()
			end
		end
	)

	self:mix_in(
		Illuminator,
		illumination_radius
	)

	self.starting_illumination_radius = self.illumination_radius

end


function Flammable:light_flame()
	if self.on_fire then return end
	local s = self.sequencer
	self.on_fire = true 
	s:do_while(
		function() return self.on_fire end,
		function() 
			self:spawn_particle()
			s:wait(rng.randf_range(0, 7))
		end
	)
	self:activate_illumination()
end

function Flammable:extinguish()
	self.on_fire = false
	self:deactivate_illumination()
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

local Pickupable = Object:extend()
function Pickupable:_init()
	self.is_pickupable = true
end

local Useable = Object:extend()
function Useable:_init(use_function)
	self.is_useable = true
	self.use_function = use_function or function(user) return false end -- returns whether you should drop the item
end

local Illuminable = Object:extend()
function Illuminable:_init(static)
	-- self:add_draw_function(Illuminable._draw)
	self:add_update_function(Illuminable._update)
	self.lightness = 0
	self.revealed = false
	if static then
		self.static_illuminable = true
	end
end

function Illuminable:_draw()
	local l = 1 - pow(1 - self.lightness, 5)
	local dark = palette.skyblue
	graphics.set_color(lerp(dark.r, 1, l), lerp(dark.g, 1, l), lerp(dark.b, 1, l))
end

function Illuminable:on_illuminated(illuminator)
	if self.static_illuminable then
		self:set_update(true)
	end
	self.illumination_frames = 2
	self.lit = true
	self.illuminators = self.illuminators or {}
	self.illuminators[illuminator] = true
	self.lightness = 0
	if self.lit then
		for illum, v in pairs(self.illuminators) do
			self.lightness = self.lightness + lerp(0.0, 1, 1 - self.pos:distance_to(illum.pos) / illum.illumination_radius)
			self.lightness = clamp(self.lightness, 0, 1)
		end
	end
end

function Illuminable:_update(dt)
	if self.illumination_frames then
		self.lit = true
		self.illumination_frames = self.illumination_frames - 1
		if self.illumination_frames == 0 then
			self.lit = false
			self.lightness = 0
			self.illuminators = nil
			if self.static_illuminable then
				self:set_update(false)
			end
		end
	end
	self.revealed = self.lightness > 0.15
end

local TorchLightRevealable = Object:extend()
function TorchLightRevealable:_init()
end

return {
	Flammable = Flammable,
	Pickupable = Pickupable,
	Useable = Useable,
	Illuminator = Illuminator,
	Illuminable = Illuminable,
}
