local tiles =
{
[[
###############
#.............#
#.............#
#.............#
#.............#
#.............#######
#t..................#
2...................1
#..................l#
######......#########
_____#......#
_____#......#
_____#......#
_____#..t...#
_____#......#
_____#......#
_____####3###


]],

}

local tile_data = {
	["1"] = {
		-- to_map : to_exit : facing_direction
		exit = "map2:1:left"
	}
	,
	["2"] = {
		exit = "map2:2:right"
	},
	["3"] = {
		exit = "map2:3:up"
	},

	l = {
		torch = true,
		lit = true,
	}
}

local map_info = {}

return {
	tiles = tiles,
	tile_data = tile_data,
	map_info = map_info
}
