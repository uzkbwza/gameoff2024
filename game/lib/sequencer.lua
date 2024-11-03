
Sequencer = Object:extend()


-- Example usage: 
--[[

s:start(
	s:chain(
		-- wait for one second
		s:wait(60),
		-- print hello
		function() print("hello") end,
		-- tween my position to the left over a second
		s:tween_property(self.pos, "x", -30, 60.0, "inOutQuad"),
		-- wait until i move back to the right
		s:wait_for(function() return self.pos.x >= 0 end),
		-- print hello again
		function() print("hello again") end,
		-- wait for the self.died signal to fire, presumably when i die
		s:wait_for(self.died),
		-- print goodbye
		function() print("goodbye") end
	)
)

]]

function Sequencer:new()
	self.running = {}
	self.suspended = {}
	self.dt = 0
	self.elapsed = 0
end

function Sequencer:start(func)
	local co = coroutine.create(func)
	self:init_coroutine(co)
end

function Sequencer:chain(...)
	local funcs = {...}
	local func = (function()
		for _, func in ipairs(funcs) do
			self:call(func)
		end
	end)

	return func
end

function Sequencer:start_chain(...)
	self:start(self:chain(...))
end

function Sequencer:loop(func, times)
	assert(times == nil or type(times) == "number", "times must be a number")
	if times == nil then
		return function()
			while true do
				func()
				coroutine.yield()
			end
		end
	end
	return function()
		for i = 1, times do
			func()
			coroutine.yield()
		end
	end
end

function Sequencer:init_coroutine(co)
	table.insert(self.running, co)
end

function Sequencer:update(dt)
	if table.is_empty(self.running) then
		return
	end

	self.dt = dt

	for _, value in ipairs(self.running) do
		self.current_chain = value
		if self.suspended[value] == nil then
			coroutine.resume(value)
		end
	end

	table.fast_remove(self.running, function(t, i, j)
		local co = t[i]
		return self.suspended[co] ~= nil or coroutine.status(co) ~= "dead"
	end)

	self.elapsed = self.elapsed + dt

end

function Sequencer:wait(duration)
	return function()
		local start = self.elapsed
		local finish = self.elapsed + duration
		while self.elapsed < finish do
			coroutine.yield()
		end
	end
end

function Sequencer:tween(func, value_start, value_end, duration, easing)
	return function()
		local start = self.elapsed
		local finish = self.elapsed + duration
		local ease_func = ease(easing)


		while self.elapsed < finish do
			local t = ease_func((self.elapsed - start) / duration)
			func(value_start + t * (value_end - value_start))
			coroutine.yield()
		end
	end
end

function Sequencer:tween_property(obj, property, value_end, duration, easing)
	return self:tween(function(value) obj[property] = value end, obj[property], value_end, duration, easing)
end

function Sequencer:suspend(chain)
	self.suspended[chain] = true
	self.running[chain] = nil
end

function Sequencer:resume(chain)
	self.suspended[chain] = nil
	self.running[chain] = true
	self:init_coroutine(chain)
end

function Sequencer:wait_for(func)
	if Object.is(func, Signal) then
		return function()
			self:suspend(self.current_chain)
			func:connect(function() self:resume(self.current_chain) end)
			coroutine.yield()
		end
	end
	return function()
		while not func() do
			coroutine.yield()
		end
	end
end

function Sequencer:call(func)
	local co = coroutine.create(func)
	while coroutine.status(co) ~= "dead" do
		local status, err = coroutine.resume(co)
		if not status then
			error(err)
		end
		coroutine.yield()
	end
end

function Sequencer:destroy()
	self.running = nil
	self.suspended = nil
	self.dt = 0
	self.elapsed = 0
end
