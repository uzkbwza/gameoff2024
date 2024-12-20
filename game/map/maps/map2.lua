local tiles =
{
[[

#########
#....t..#
#.......#
#.......#
#.......#
#.......#
#.......#######
#.............#______#########
#.............#______#.......#
#########.....#______#.......#
________#.....#______#.......#
________#.....########.......#
________#....................#
________#....................#
_########....................#
_#............################
_#............#
_3............#
_#............#
_#......t.....#
_#............#
_#............#
_##############

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
	["3"] = {
		-- to_map : to_exit : facing_direction
		exit = "map1:3:right",
		torch_door = true,
		start_openable = true,
	}


}

local map_info = {}

return {
	tiles = tiles,
	tile_data = tile_data,
	map_info = map_info
}
