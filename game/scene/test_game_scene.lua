local fx = require "fx.mooncatdeath"
local GameScene = require("scene.game_scene")
local collision = require("lib.collision")

local TestGameScene = GameScene:extend()

local BALL_RADIUS = 3
local PADDLE_WIDTH = 70
local PADDLE_HEIGHT = 12
local BALL_SPEED = 2
local GRAVITY = 0.0
local PADDLE_SPEED = 6
local BOUNDS = {
	xstart = -conf.viewport_size.x/2,
	xend = conf.viewport_size.x/2,
	ystart = -conf.viewport_size.y/2,
	yend = conf.viewport_size.y/2,
}


-- local ball_anim = Animation(
-- 	1, textures.ball1,
-- 	5, textures.ball2,
-- 	9, textures.ball3,
-- 	13, "end"
-- )


-- local ball_anim = Animation(
-- 	1, "ball1",
-- 	5, "ball2",
-- 	9, "ball3",
-- 	13, "end"
-- )

-- same as above
local ball_anim = Animation.from_sequence("ball", 1, 3, 4)

local Ball = GameObject:extend()

local i = 0

function Ball:new(x, y)
	Ball.super.new(self, x, y)
	self.velocity = Vec2()
	self.texture = textures.ball1
	if i % 2 == 0 then
		self.texture = textures.ball2
	end

	i = i + 1
	self:add_elapsed_time()
	self:add_elapsed_ticks()
	self.tick = rng(0, 1)
end

function Ball:update(dt)
	self:movev(self.velocity * dt)
	if self.pos.x < BOUNDS.xstart then
		self:move_to(BOUNDS.xstart, self.pos.y)
		self.velocity.x = self.velocity.x * -1
	elseif self.pos.x > BOUNDS.xend then
		self:move_to(BOUNDS.xend, self.pos.y)
		self.velocity.x = self.velocity.x * -1
	end
	if self.pos.y < BOUNDS.ystart then
		self:move_to(self.pos.x, BOUNDS.ystart)
		self.velocity.y = self.velocity.y * -1
	elseif self.pos.y > BOUNDS.yend then
		self:move_to(self.pos.x, BOUNDS.yend)
		self.velocity.y = self.velocity.y * -1
	end

	if self.paddle then 
		local paddle_min = Vec2(self.paddle.pos.x - PADDLE_WIDTH / 2, self.paddle.pos.y - PADDLE_HEIGHT / 2)
		local paddle_max = Vec2(self.paddle.pos.x + PADDLE_WIDTH / 2, self.paddle.pos.y + PADDLE_HEIGHT / 2)

		local overlap = collision.check_circle_aabb_overlap(self.pos, BALL_RADIUS, paddle_min, paddle_max) 
		
		if overlap > 0 then 
			self:movev(overlap * self.velocity:normalize_in_place() * -1  * dt)
			self.velocity.y = self.velocity.y * -1
			local x_overlap = (self.pos.x - self.paddle.pos.x) / (PADDLE_WIDTH / 2)
			-- print(x_overlap)

			self.velocity.x = self.velocity.x + (x_overlap * 0.9)

			self.velocity = self.velocity:normalize_in_place():mul_in_place(BALL_SPEED)
		end
	end
	self.velocity.y = self.velocity.y + GRAVITY * dt
end

function Ball:draw()
	self.scale.x = 2 + sin(self.elapsed * 0.35) * 1
	self.scale.y = 2 + cos(self.elapsed * 0.5) * 1
	graphics.draw_centered(ball_anim:get_frame(self.elapsed, "loop"))

end

local Paddle = GameObject:extend()

function Paddle:new(x, y)
	Paddle.super.new(self, x, y)
end

function Paddle:update(dt)
	local input = self:get_input_table()

	if input.move_left then
		self:move(-PADDLE_SPEED * dt * input.move_left_amount, 0)
	end
	if input.move_right then
		self:move(PADDLE_SPEED * dt * input.move_right_amount, 0)
	end

	if self.pos.x < BOUNDS.xstart then
		self:move_to(BOUNDS.xstart, self.pos.y)
	elseif self.pos.x > BOUNDS.xend then
		self:move_to(BOUNDS.xend, self.pos.y)
	end
end

function Paddle:draw()
	
	graphics.set_color(1, 1, 1, 1)
	graphics.draw_centered(textures.paddle)
end

function TestGameScene:new()
	TestGameScene.super.new(self)
	-- self.draw_sort = function(a, b)
	-- 	return a.pos.y < b.pos.y
	-- end
end

function TestGameScene:enter()
	self.paddle = self:add_object(Paddle(0, 60))
	-- self.camera:follow(self.paddle)
	-- self.paddle = self:add_object(Paddle(conf.viewport_size.x / 2, conf.viewport_size.y / 2 + 90))
	for i= 1, 1 do
		local ball = self:add_object(Ball(0, 45))
		ball.paddle = self.paddle
		-- ball.velocity = Vec2(1, 2000):normalize_in_place():mul_in_place(BALL_SPEED * rng.randfn(1.0, 0.2))
		ball.velocity = rng.random_vec2():normalize_in_place():mul_in_place(BALL_SPEED * rng.randfn(1.0, 0.1))
	end
end

function TestGameScene:draw()
	graphics.push()
	graphics.origin()
	-- graphics.draw(textures.bg, 0, 0, 0, 1, 1)
	graphics.pop()
	TestGameScene.super.draw(self)

end

function TestGameScene:update(dt)

	if input.menu_pressed then

		self:push("Pause")
	end
end


return TestGameScene
