local tiles =
{
[[

####3####
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
_########................t...#
_#fffffff.....############2###
_#fffffff.....#
_#fffffff.....#
_#fffffff.....#
_#fffffff.....#
_#fffffff...@.#
_#fftffff.....#
_####1#########

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
		exit = "map1:3:down"
	}


}

local map_info = {}

return {
	tiles = tiles,
	tile_data = tile_data,
	map_info = map_info
}
