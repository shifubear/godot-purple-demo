class_name GLOBALS	
enum color {
	red = 1, 
	blue = -1,
	none
}

const atlas = {
	default_blue_tile = Vector2i(0, 1),
	default_red_tile = Vector2i(2, 2),
	hover_blue_tile_far = Vector2i(0, 3),
	hover_blue_tile_close = Vector2i(0, 4),
	hover_red_tile_far = Vector2i(2, 3),
	hover_red_tile_close = Vector2i(2, 4)
}

const bluetiles = [
	atlas.default_blue_tile,
	atlas.hover_blue_tile_close,
	atlas.hover_blue_tile_far
]

const redtiles = [
	atlas.default_red_tile,
	atlas.hover_red_tile_close,
	atlas.hover_red_tile_far
]

