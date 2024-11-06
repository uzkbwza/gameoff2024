local LevelEditScene = GameScene:extend()

	
TILE_SIZE = 9
	
shift_chars = {
	["1"] = "!",
	["2"] = "@",
	["3"] = "#",
	["4"] = "$",
	["5"] = "%",
	["6"] = "^",
	["7"] = "&",
	["8"] = "*",
	["9"] = "(",
	["0"] = ")",
	["-"] = "_",
	["="] = "+",
	["["] = "{",
	["]"] = "}",
	["\\"] = "|",
	[";"] = ":",
	["'"] = "\"",
	[","] = "<",
	["."] = ">",
	["/"] = "?",
}

local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890!@#$%^&*()_+-=[]{}|;':\",.<>/?\\"

function LevelEditScene:new()

	self.mpos = Vec2(0, 0)
	self.mdxy = Vec2(0, 0)
	self.mcell = Vec2(0, 0)
	self.lmb = 0
	self.mmb = 0
	self.rmb = 0
	
	self.offset = Vec2(0, 0)

	-- paint, fill, rectangle_start, rectangle_end
	self.mode = "paint"

	self.painting = false
	self.erasing = false
	
	self.tiles = {}

	self.edit_history = {}
	self.edit_future = {}
	
	self.active_key = "#"
	
	self.notify_text = ""
	self.notify_text_alpha = 0

	LevelEditScene.super.new(self)

	input.signals.key_pressed:connect(
	function(key) 
		if input.keyboard_held["lctrl"] or input.keyboard_held["rctrl"] then
			if key == "s" or key == "c" then 
				local string = self:get_level_string()
				love.system.setClipboardText(string)
				self:notify("Copied level to clipboard")
			elseif key == "v" then 
				self:update_history()
				local string = love.system.getClipboardText()
				self:build_from_level_string(string)
				self:notify("Pasted level from clipboard")
				self.offset = Vec2(0, 0)
			elseif key == "delete" then
				self:update_history()
				self.tiles = {}
				self:notify("Cleared")
			elseif key == "d" then 
				self.mode = "paint"
				self:notify("Mode: Paint")
			elseif key == "f" then
				if self.mode == "fill" then 
					self.mode = "paint"
					self:notify("Mode: Paint")
				else
					self.mode = "fill"
					self:notify("Mode: Fill")
				end
			elseif key == "z" then 
				if input.keyboard_held["lshift"] or input.keyboard_held["rshift"] then
					self:redo()
				else
					self:undo()
				end
			end
			return
		end
		if #key == 1 then 
			if input.keyboard_held["lshift"] or input.keyboard_held["rshift"] then 
				self.active_key = shift_chars[key]
				return
			else 
				self.active_key = key
				return
			end
		end
	end)
	input.signals.mouse_pressed:connect(
	function(x, y, button)
		if self.mode == "fill" then
			if button == 1 or button == 2 then
				self:update_history()
				self:flood_fill(self.mcell.x, self.mcell.y, button == 1 and self.active_key or nil)
			end
		end
	end)
end

function LevelEditScene:notify(text)
	self.notify_text = text
	local s = self.sequencer
	s:start(function()
		s:tween_property(self, "notify_text_alpha", 1, 0, 60, "inQuad")
	end)
end

function LevelEditScene:update_history()
	print("updating history")
	self.edit_future = {}
	table.push_back(self.edit_history, table.deepcopy(self.tiles))
end

function LevelEditScene:redo()
	if table.is_empty(self.edit_future) then return end
	table.push_back(self.edit_history, table.deepcopy(self.tiles))
	self.tiles = table.pop_back(self.edit_future)
	self:notify("Redo")
end

function LevelEditScene:undo()
	if table.is_empty(self.edit_history) then return end
	table.push_back(self.edit_future, table.deepcopy(self.tiles))
	self.tiles = table.pop_back(self.edit_history)
	self:notify("Undo")
end

function LevelEditScene:update(dt)
	self.mpos.x = floor(input.mouse.pos.x - self.offset.x)
	self.mpos.y = floor(input.mouse.pos.y - self.offset.y)
	self.mdxy.x = input.mouse.dxy.x
	self.mdxy.y = input.mouse.dxy.y
	self.mcell.x = floor(self.mpos.x / TILE_SIZE)
	self.mcell.y = floor(self.mpos.y / TILE_SIZE)
	
	self.lmb = input.mouse.lmb
	self.mmb = input.mouse.mmb
	self.rmb = input.mouse.rmb

	if self.mmb ~= nil then 
		self.offset.x = self.offset.x + self.mdxy.x
		self.offset.y = self.offset.y + self.mdxy.y
	end

	if self.lmb ~= nil then
		local cx, cy = floor(self.mpos.x / TILE_SIZE), floor(self.mpos.y / TILE_SIZE)
		if input.keyboard_held["lalt"] or input.keyboard_held["ralt"] then
			self.active_key = self:get_tile(cx, cy) or self.active_key
		else
			if self.mode == "paint" then
				if not self.painting then self:update_history() end
				self:set_tile(cx, cy, self.active_key)
				self.painting = true
			end
		end
	else
		self.painting = false
	end

	if self.rmb ~= nil then 
		local cx, cy = floor(self.mpos.x / TILE_SIZE), floor(self.mpos.y / TILE_SIZE)
		if self.mode == "paint" then
			if not self.erasing then self:update_history() end
			self:set_tile(cx, cy, nil)
			self.erasing = true
		end
	else

		self.erasing = false
	end

	if input.debug_editor_toggle_pressed then
		self:pop()
	end
	
	dbg("self.offset", self.offset)
end

function LevelEditScene:flood_fill(cx, cy, tile)

	local tile_to_change = self:get_tile(cx, cy)
	
	tile = tile or " "

	if tile == tile_to_change then return end

	local min_x, min_y, max_x, max_y = self:get_bounds()
	local check_solid = function(c2x, c2y)
		if c2x < min_x or c2x > max_x or c2y < min_y or c2y > max_y then 
			return true 
		end
		local check_tile = self:get_tile(c2x, c2y)
		if check_tile == tile_to_change then 
			return false
		end
		return true
	end
	local fill = function(c2x, c2y) 
		self:set_tile(c2x, c2y, tile)
	end
	flood_fill(cx, cy, fill, check_solid)
end

function LevelEditScene:draw()
	LevelEditScene.super.draw(self)
	graphics.push()
	graphics.origin()
	graphics.set_color(palette.white)
	graphics.translate(floor(self.offset.x), floor(self.offset.y))
	-- graphics.circle("line", self.mpos.x, self.mpos.y, 2)
	graphics.set_font(graphics.font["PixelOperatorMono8-Bold"])

	self:draw_grid()
	self:draw_tiles()

	graphics.set_color(palette.black)
	graphics.print(self.active_key, self.mpos.x + 2, self.mpos.y + 2)
	graphics.points(self.mpos.x+1, self.mpos.y+1)

	graphics.set_color(palette.white)
	graphics.print(self.active_key, self.mpos.x + 1, self.mpos.y + 1)
	graphics.points(self.mpos.x, self.mpos.y)


	graphics.set_color(1, 1, 1, 0.25)
	graphics.rectangle("line", self.mcell.x * TILE_SIZE, self.mcell.y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
	graphics.origin()

	graphics.set_font(graphics.font["PixelOperator8"])
	graphics.set_color(palette.white)
	graphics.print(self.mode, 0, 0)
	if self.notify_text ~= "" then 
		graphics.set_color(palette.white, self.notify_text_alpha)
		graphics.print(self.notify_text, 0, self.viewport_size.y - 8)
	end

	graphics.pop()
end

function LevelEditScene:tile_color(char)
	if char == nil then 
		return palette.black
	end
	if char == "#" or char == "." then 
		return palette.darkgreyblue
	end
	if string.match("0123456789", char) then
		return palette.green
	end
	return palette.white
end

function LevelEditScene:draw_grid()
	graphics.push()
	graphics.set_color(1, 1, 1, 0.05)

	local start_x = (floor(-self.offset.x / TILE_SIZE - 2) * TILE_SIZE)
	local end_x = start_x + floor(graphics.main_viewport_size.x / TILE_SIZE + 4) * TILE_SIZE
	local start_y = (floor(-self.offset.y / TILE_SIZE - 2) * TILE_SIZE)
	local end_y = start_y + floor(graphics.main_viewport_size.y / TILE_SIZE + 4) * TILE_SIZE
	for i=1, graphics.main_viewport_size.x / TILE_SIZE + 3 do 
		graphics.line(start_x + i * TILE_SIZE, start_y, start_x + i * TILE_SIZE, end_y)

	end
	for i=1, graphics.main_viewport_size.y / TILE_SIZE + 3 do 
		graphics.line(start_x, start_y + i * TILE_SIZE, end_x, start_y + i * TILE_SIZE)
	end

	

	graphics.pop()
end

function LevelEditScene:get_level_string()
	local min_x, min_y, max_x, max_y = self:get_bounds()
	local level_string = ""
	for y = min_y, max_y do 
		local line = ""
		for x = min_x, max_x do 
			local char = self:get_tile(x, y)
			if char == "\n" or char == " " or char == nil then
				char = "_"
			end
			line = line .. char
		end
		local line1 = string.strip_whitespace(line, false, true)
		local line2 = string.strip_char(line1, "_", false, true)
		level_string = level_string .. line2 .. "\n"
	end
	print(level_string)
	return level_string
end

function LevelEditScene:get_tile(x, y)
	if self.tiles[y] == nil then
		return nil
	end

	return self.tiles[y][x] or " "
end

function LevelEditScene:build_from_level_string(level_string)
	if type(level_string) ~= "string" then 
		return
	end
	local lines = string.split(level_string, "\n")
	self.tiles = {}

	for y=1, #lines do 
		local line = lines[y]
		if string.strip_whitespace(line) == "" then 
			y = y - 1
			goto continue
		end

		local len = #line
		if line:sub(len, len) == "" then 
			line = line:sub(1, len - 1)
		end
		for x = 1, len do
			self:set_tile(x, y, line:sub(x, x))
		end
	    ::continue::
	end
end

function LevelEditScene:set_tile(x, y, char)
	local in_charset = false 
	for i=1, #charset do 
		if charset:sub(i, i) == char then
			in_charset = true
			break
		end
	end
	if not in_charset then 
		char = nil
	end
	if char == " " or char == "\n" or char == "_" then 
		char = nil
	end
	if self.tiles[y] == nil then 
		if char == nil then 
			return
		end
		self.tiles[y] = {}
	end

	self.tiles[y][x] = char
end

function LevelEditScene:get_bounds()
	local min_x = math.huge
	local min_y = math.huge
	local max_x = -math.huge
	local max_y = -math.huge
	for y, row in pairs(self.tiles) do 
		for x, _ in pairs(row) do 
			min_x = min(min_x, x)
			min_y = min(min_y, y)
			max_x = max(max_x, x)
			max_y = max(max_y, y)
		end
	end
	return min_x, min_y, max_x, max_y
end

function LevelEditScene:draw_tiles()
	graphics.push()
	local min_x, min_y, max_x, max_y = self:get_bounds()
	
	-- graphics.set_color(palette.darkgreyblue)
	for y=min_y, max_y do 
		for x=min_x, max_x do
			if x >= min_x and x <= max_x and y >= min_y and y <= max_y then 
				graphics.set_color(palette.darkgreyblue, 0.1)
				graphics.rectangle("fill", x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
			end
			local tile = self:get_tile(x, y)
			if tile then 
				graphics.set_color(self:tile_color(tile))
				graphics.print(tile, x * TILE_SIZE, y * TILE_SIZE)
			end
		end
	end
	graphics.pop()
end

function LevelEditScene:enter()
	self.clear_color = palette.black
	self:update_history()
	love.mouse.setVisible(false)
end

function LevelEditScene:exit()
	love.mouse.setVisible(true)
end

return LevelEditScene
