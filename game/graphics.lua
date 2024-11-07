local Packer = require("lib.packer.packer")
local utf8 = require "utf8"


local graphics = {
	canvas = nil,
	canvas2 = nil,
	sequencer = Sequencer(),
	packer = nil,
	textures = nil,
	texture_data = nil,
	sprite_paths = nil,
	scene_stack = nil,
	interp_fraction = 0,
	shader = require "shader.shader",
	main_canvas_start_pos = Vec2(0,0),
	main_canvas_size = Vec2(0,0),
	main_canvas_scale = 1,
	main_viewport_size = Vec2(0,0),
	palette = nil,
}

function graphics.load_textures(texture_atlas)

	texture_atlas = texture_atlas or false

	local packer = nil
	if texture_atlas then
		packer = Packer()

	end

	local textures = {}
	local texture_data = {}
	local sprite_paths = filesystem.get_files_of_type("assets", "png", true)
	local image_settings = {
		mipmaps = false,
		linear = false,
	}

	-- local time = love.timer.getTime()
	-- coroutine.yield()
	for _, v in ipairs(sprite_paths) do
		local tex = graphics.new_image(v, image_settings)
		local data = graphics.new_image_data(v)
		local name = filesystem.filename_to_asset_name(v, "png")
		textures[name] = tex
		texture_data[name] = data
		-- local current_time = love.timer.getTime()
		-- if current_time - time > 1 then
			-- time = current_time
			-- coroutine.yield()
		-- end
		if packer then
			packer:add_texture(data, tex, name)
		end

	end

	dbg("Loaded textures", table.length(textures))


	if packer then 
		packer:bake()
	end

	graphics.packer = packer
	graphics.textures = textures
	graphics.texture_data = texture_data
	graphics.sprite_paths = sprite_paths

end

function graphics.load()
	graphics.set_default_filter("nearest", "nearest", 0)
	graphics.canvas = graphics.new_canvas(conf.viewport_size.x, conf.viewport_size.y)
	graphics.canvas2 = graphics.new_canvas(conf.viewport_size.x, conf.viewport_size.y)
	graphics.set_canvas(graphics.canvas)
	graphics.clear(0, 0, 0, 0)
	graphics.set_blend_mode("alpha")
	graphics.set_line_style("rough")
    graphics.set_canvas()
	-- graphics.sequencer:start(function()
	-- 	load_textures(true)
	-- end)

	graphics.load_textures(false)

	local font_paths = filesystem.get_files_of_type("assets/font", "ttf", true)
	graphics.font = {

	}
	
	for _, v in ipairs(font_paths) do 
		graphics.font[filesystem.filename_to_asset_name(v, "ttf", "font_")] = graphics.new_font(v, v:find("8") and 8 or 16)
	end
	graphics.font.main = graphics.font["PixelOperator-Bold"]
	graphics.set_font(graphics.font.main)

end

function graphics.color_from_html(str)
	return
	{
		r = tonumber("0x" .. string.sub(str, 1, 2)) / 255,
		g = tonumber("0x" .. string.sub(str, 3, 4)) / 255,
		b = tonumber("0x" .. string.sub(str, 5, 6)) / 255,
		a = 1
	}
end

function graphics.game_draw()

	graphics.push()

	local ordered_draw = {}

	local update_interp = true 
	for _, scene in ipairs(graphics.scene_stack) do
		if update_interp then
			scene.interp_fraction = update_interp and graphics.interp_fraction or scene.interp_fraction
		end
	
		table.insert(ordered_draw, scene)

		if scene.blocks_logic then
			update_interp = false
		end
		
		if scene.blocks_render then
			break
		end
	end

	for i=#ordered_draw, 1, -1 do
		ordered_draw[i]:draw_shared()
	end

	graphics.pop()
end

function graphics.main_viewport_draw()
	graphics.set_canvas(graphics.canvas)
	graphics.clear(0, 0, 0)

	graphics.game_draw()


	graphics.set_color(1,1,1)
	graphics.set_canvas()

	-- TODO: stop generating garbage with vec2s
	local window_width, window_height = graphics.get_dimensions()
	local window_size = Vec2(window_width, window_height)
	local viewport_size = Vec2(conf.viewport_size.x, conf.viewport_size.y)
	local max_width_scale = math.floor(window_size.x / viewport_size.x)
	local max_height_scale = math.floor(window_size.y / viewport_size.y)
	local viewport_pixel_scale = math.floor(math.min(max_width_scale, max_height_scale))
	local canvas_size = viewport_size * viewport_pixel_scale
	local canvas_pos = window_size / 2 - (canvas_size) / 2

	if usersettings.use_screen_shader and viewport_pixel_scale >= 2 then
		if gametime.ticks % 10 == 0 then
			-- pcall(graphics.shader.update)
		end
		local shader = graphics.shader.test
		shader:send("viewport_size", {viewport_size.x, viewport_size.y})
		shader:send("canvas_size", {canvas_size.x, canvas_size.y})
		shader:send("canvas_pos", {canvas_pos.x, canvas_pos.y})
		graphics.set_shader(shader)
	end

	graphics.main_canvas_start_pos = canvas_pos
	graphics.main_canvas_size = canvas_size
	graphics.main_canvas_scale = viewport_pixel_scale
	graphics.main_viewport_size = viewport_size

	graphics.draw(graphics.canvas, math.floor(canvas_pos.x), math.floor(canvas_pos.y), 0, viewport_pixel_scale, viewport_pixel_scale)

	graphics.set_shader()

	graphics.set_canvas()

	debug.printlines(0, 0)
end

function graphics.screen_pos_to_canvas_pos(sposx, sposy)
	return ((sposx - graphics.main_canvas_start_pos.x) / graphics.main_canvas_scale), ((sposy - graphics.main_canvas_start_pos.y) / graphics.main_canvas_scale)
end

function graphics.update(dt)
	graphics.sequencer:update(dt)
	if input.fullscreen_toggle_pressed then
		love.window.setFullscreen( not love.window.getFullscreen() )
	end
end

function graphics.draw_loop()
	graphics.main_viewport_draw()
end

--- love API wrappers
function graphics.set_color(r, g, b, a)
	if type(r) == "table" then
		if g ~= nil then
			a = g
		else
			if a == nil then
				a = r.a
			end
		end
		g = r.g
		b = r.b
		r = r.r
		if a == nil then
			a = 1.0
		end
	end
	love.graphics.setColor(r, g, b, a)
end


function graphics.push()
	love.graphics.push()
end

function graphics.pop()
	love.graphics.pop()
end

function graphics.origin()
	love.graphics.origin()
end

function graphics.translate(x, y)
	love.graphics.translate(x, y)
end

function graphics.rotate(r)
	love.graphics.rotate(r)
end

function graphics.scale(x, y)
	love.graphics.scale(x, y)
end

function graphics.set_font(font)
	love.graphics.setFont(font)
end

function graphics.new_font(path, size)
	return love.graphics.newFont(path, size)
end

function graphics.new_image_font(path, glyphs, spacing)
	return love.graphics.newImageFont(path, glyphs, spacing)
end

function graphics.new_quad(x, y, width, height, sw, sh)
	return love.graphics.newQuad(x, y, width, height, sw, sh)
end

function graphics.new_text(text, font)
	return love.graphics.newText(font, text)
end

function graphics.new_sprite_batch(texture, size, usage)
	return love.graphics.newSpriteBatch(texture, size, usage)
end

function graphics.draw_quad(quad, x, y, r, sx, sy, ox, oy, kx, ky)
	love.graphics.draw(quad, x, y, r, sx, sy, ox, oy, kx, ky)
end

function graphics.draw(texture, x, y, r, sx, sy, ox, oy, kx, ky)
	if texture == nil then
		return
	end
	love.graphics.draw(texture, x, y, r, sx, sy, ox, oy, kx, ky)
end

function graphics.draw_centered(texture, x, y, r, sx, sy, ox, oy, kx, ky)
	if texture == nil then
		return
	end
	
	ox = ox or 0
	oy = oy or 0
	local offset_x = texture:getWidth() / 2
	local offset_y = texture:getHeight() / 2
	love.graphics.draw(texture, x, y, r, sx, sy, ox + offset_x, oy + offset_y, kx, ky)
end

function graphics.clear(r, g, b, a)
	if type(r) == "table" then
		if g ~= nil then
			a = g
		else
			if a == nil then
				a = r.a
			end
		end
		g = r.g
		b = r.b
		r = r.r
		if a == nil then
			a = 1.0
		end
	end
	love.graphics.clear(r, g, b, a)
end

function graphics.set_canvas(canvas)
	love.graphics.setCanvas(canvas)
end

function graphics.set_blend_mode(mode)
	love.graphics.setBlendMode(mode)
end

function graphics.set_line_style(style)
	love.graphics.setLineStyle(style)
end

function graphics.set_default_filter(min, mag, anisotropy)
	love.graphics.setDefaultFilter(min, mag, anisotropy)
end

function graphics.get_dimensions()
	return love.graphics.getDimensions()
end

function graphics.new_canvas(width, height)
	return love.graphics.newCanvas(width, height)
end

function graphics.new_image(path, settings)
	return love.graphics.newImage(path, settings)
end

function graphics.new_image_data(path)
	return love.image.newImageData(path)
end

function graphics.points(...)
	love.graphics.points(...)
end

function graphics.circle(mode, x, y, radius, segments)
	love.graphics.circle(mode, x, y, radius, segments)
end

function graphics.rectangle(mode, x, y, width, height)
	love.graphics.rectangle(mode, x, y, width, height)
end

function graphics.line(x1, y1, x2, y2)
	love.graphics.line(x1, y1, x2, y2)
end

function graphics.polygon(mode, ...)
	love.graphics.polygon(mode, ...)
end

function graphics.print(text, x, y, r, sx, sy, ox, oy, kx, ky)
	graphics.push()
	-- graphics.set_color(palette.black)
	-- love.graphics.print(text, x+1, y + 1, r, sx, sy, ox, oy, kx, ky)
	-- love.graphics.print(text, x-1, y - 1, r, sx, sy, ox, oy, kx, ky)
	-- love.graphics.print(text, x+1, y - 1, r, sx, sy, ox, oy, kx, ky)
	-- love.graphics.print(text, x-1, y + 1, r, sx, sy, ox, oy, kx, ky)
	-- graphics.set_color(palette.white)
	
	love.graphics.print(text, x, y, r, sx, sy, ox, oy, kx, ky)
	graphics.pop()
end

function graphics.draw_collision_box(rect, color, alpha)
	love.graphics.setColor(color.r, color.g, color.b, alpha * 0.125)
	love.graphics.rectangle("fill", rect.x, rect.y, rect.width, rect.height)
	love.graphics.setColor(color.r, color.g, color.b, alpha)
	love.graphics.rectangle("line", rect.x, rect.y, rect.width, rect.height)
end

function graphics.reset()
	love.graphics.reset()
end

function graphics.set_shader(shader)
	love.graphics.setShader(shader)
end

graphics.palette = {
	black = graphics.color_from_html("02040a"),
	white = graphics.color_from_html("ffffff"),
	lightred = graphics.color_from_html("f7aaaa"),
	brown = graphics.color_from_html("883425"),
	terracotta = graphics.color_from_html("ca6845"),
	peach = graphics.color_from_html("ffd8b3"),
	orange = graphics.color_from_html("ff8800"),
	gold = graphics.color_from_html("f6c319"),
	hazel = graphics.color_from_html("856e13"),
	puke = graphics.color_from_html("a6ac17"),
	yellow = graphics.color_from_html("f3f967"),
	lime = graphics.color_from_html("9feb26"),
	forest = graphics.color_from_html("1e7f44"),
	turquoise = graphics.color_from_html("83eec6"),
	seagreen = graphics.color_from_html("0dcc8b"),
	darkgreen = graphics.color_from_html("00261b"),
	skyblue = graphics.color_from_html("82c6ff"),
	darkskyblue = graphics.color_from_html("3c95e9"),
	blue = graphics.color_from_html("151e2f"),
	navyblue = graphics.color_from_html("0d1c4a"),
	darkblue = graphics.color_from_html("151e2f"),
	darkgreyblue = graphics.color_from_html("474c6c"),
	greyblue = graphics.color_from_html("646dac"),
	lilac = graphics.color_from_html("b488ff"),
	darkpurple = graphics.color_from_html("472b6d"),
	purple = graphics.color_from_html("7521e3"),
	pink = graphics.color_from_html("e5baf3"),
	magenta = graphics.color_from_html("d655db"),
	maroon = graphics.color_from_html("820b2e"),
	salmon = graphics.color_from_html("f17589"),
	red = graphics.color_from_html("e2383d"),
	darkred = graphics.color_from_html("420a0b"),
}

graphics.palette.green = graphics.color_from_html("9feb26")


return graphics

