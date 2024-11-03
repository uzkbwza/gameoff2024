local game = {}

game.scene_stack = {}
game.queued_scene = nil
game.sequencer = Sequencer()

game.scenes = {
	Base = "game_scene",
	Game = "main_game_scene",
	Pause = "pause_scene",
}

function game.load()
	graphics.scene_stack = game.scene_stack
	graphics.load()

	game.transition_to_scene("Game")
end

function game.queue_scene(scene)
	game.queued_scene = scene
end

function game.push_scene(scene)
	scene = game.scene_from_name(scene)
	table.push_front(game.scene_stack, scene)
	scene.scene_pushed:connect(game.queue_scene)
	scene.scene_popped:connect(game.pop_scene)
	scene:enter_shared()
end

function game.pop_scene()
	local scene = table.pop_front(game.scene_stack)
	if scene then
		scene:exit_shared()
	end
	return scene
end

function game.scene_from_name(scene)
	if type(scene) == "string" then
		return require("scene." .. game.scenes[scene])()
	end
	return scene
end

function game.transition_to_scene(new_scene)

	game.pop_scene()
	game.scene_stack = {}
	game.queue_scene(new_scene)
end

function game.update_input_stack(table)
	local scene_process_input = true
	for _, v in ipairs(game.scene_stack) do
		v.input = scene_process_input and table or input.dummy
		if v.blocks_input then
			scene_process_input = false
		end
	end
end

function game.update(dt)
	-- input
	if game.queued_scene then
		game.push_scene(game.queued_scene)
		game.queued_scene = nil
	end

	game.update_input_stack(input)
	
	-- update
	for _, v in ipairs(game.scene_stack) do
		v:update_shared(dt)
		if v.blocks_logic then
			break
		end
	end
	game.sequencer:update(dt)
	graphics.update(dt)
end


function game.draw()
	graphics.scene_stack = game.scene_stack
	graphics.draw_loop()
end

return game
