local tiles =
{
[[
#########.....................
#.......#.....................
#.......#.....................
#.......#.....................
#.......#.....................
#.......#.....................
#.......#######...............
#.............#......#########
#.............#......#.......#
#########.....#......#.......#
........#.....#......#.......#
........#.....########.......#
........#....................#
........#....................#
.########....................#
.#............############2###
.#.f..........#...............
.#............#...............
.#............#...............
.#............#...............
.#..........@.#...............
.#............#...............
.####1#########...............



]],

}

local tile_data = {
	["1"] = {
		-- to_map : to_exit : facing_direction
		exit = "map1:1:up"
	},
	["2"] = {
		-- to_map : to_exit : facing_direction
		exit = "map1:2:up"
	},


}

local map_info = {}

return {
	tiles = tiles,
	tile_data = tile_data,
	map_info = map_info
}
