extends CharacterBody2D

@export var COLOR : GLOBALS.color
@export var walk_time : float
@export var walk_speed : float
var terminal_velocity = 100

var curr_grid_pos: Vector2i
var prev_grid_pos: Vector2i
var curr_grid_neighborhood: Array
const neighborhood_mask = [
	Vector2i(-2, -2), Vector2i(-1, -2), Vector2i( 0, -2), Vector2i( 1, -2), Vector2i( 2, -2), 
	Vector2i(-2, -1), Vector2i(-1, -1), Vector2i( 0, -1), Vector2i( 1, -1), Vector2i( 2, -1), 
	Vector2i(-2,  0), Vector2i(-1,  0), Vector2i( 0,  0), Vector2i( 1,  0), Vector2i( 2,  0), 
	Vector2i(-2,  1), Vector2i(-1,  1), Vector2i( 0,  1), Vector2i( 1,  1), Vector2i( 2,  1), 
	Vector2i(-2,  2), Vector2i(-1,  2), Vector2i( 0,  2), Vector2i( 1,  2), Vector2i( 2,  2), 	
]

	
var curr_state = states.safe_idle
var prev_state = states.safe_idle
var state_timer : int = 0
var delta_sum = 0
var rand_time = 0
var stop_count = 0
var walking_right = true
var mine_queue = []

var rng : RandomNumberGenerator

# Map properties
var tilemap : TileMap
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

enum states {
	safe_idle,
	safe_wander,
	safe_mine,
	danger_chase,
	danger_mine,
	danger_attack,
	danger_run
}

func _ready():

	print("Enemy is idle")
	tilemap = get_owner().find_child("TileMap")
	rng = RandomNumberGenerator.new()
	rand_time = rng.randf_range(0, 2)
	curr_grid_pos = tilemap.local_to_map(tilemap.to_local(self.position))
	prev_grid_pos = curr_grid_pos
	print(get_mineable_tiles())

func _process(delta):
	read_neighborhood()

	# Add the gravity.
	if not is_on_floor():
		if velocity.y <= 0:
			velocity.y = min(velocity.y - gravity * delta, -terminal_velocity)
		else:
			velocity.y -= gravity * delta

	# If idle for more than 3 + rand sec, transition to wander
	if (curr_state == states.safe_idle):
		proc_idle()
		
	elif (curr_state == states.safe_wander):
		proc_wander()
		
	elif (curr_state == states.safe_mine):
		proc_mine()
	
	move_and_slide()
	prev_grid_pos = curr_grid_pos
	curr_grid_pos = tilemap.local_to_map(tilemap.to_local(self.position))
	delta_sum += delta

func proc_idle():
	velocity.x = 0
	if (delta_sum > 3 + rand_time):
		print("Enemy is wandering")
		curr_state = states.safe_wander
		rand_time = rng.randf_range(0, 2)
		delta_sum = 0

	prev_state = states.safe_idle

func proc_wander():
	if (stop_check()):
		stop_count += 1
		print("stop count: ", stop_count)
	if (delta_sum < walk_time + rand_time and stop_count < 5):
		# If not falling off a cliff
		# Highlight "bottom right" 
		if (curr_grid_pos != prev_grid_pos):
			tilemap.set_cell(-1, curr_grid_pos + down(), 0, GLOBALS.atlas.default_blue_tile)
		else:
			tilemap.set_cell(-1, curr_grid_pos + down() + front(), 0, Vector2i(1, 1))

		velocity.x = walk_speed * front().x

	else:
		stop_count = 0		
		tilemap.set_cell(-1, curr_grid_pos + down() + front(), 0, GLOBALS.atlas.default_blue_tile)
		if rng.randf() < 0:
			print("Enemy is idle")
			curr_state = states.safe_idle
		else:
			print("Enemy is mining")
			fill_mine_queue()
			print(mine_queue)
			curr_state = states.safe_mine
		rand_time = rng.randf_range(0, 2)
		delta_sum = 0 
		walking_right = !walking_right
	prev_state = states.safe_wander

func proc_mine():
	velocity.x = 0
	var mine_speed = 2
	
	if mine_queue.is_empty():
		curr_state = states.safe_idle
		prev_state = states.safe_mine
		print("Enemy is idle")
	elif delta_sum > mine_speed:
		var target = mine_queue.pop_back()
		print("Mining ", target)
		mine_tile(target)
		delta_sum = 0	
	#var target = fill_mine_queue()
	#mine_tile(target)
	


	
func stop_check():
	if COLOR == GLOBALS.color.blue:
		print("Front (stop check): ", tile_color(curr_grid_pos + front()))		
		# Ledge check		
		if (
			tile_color(curr_grid_pos + front()) != COLOR and 
			tile_color(curr_grid_pos + front() + down()) != COLOR and 
			tile_color(curr_grid_pos + down()) == COLOR
		):
			print("Ledge")
			return true
		# Wall check
		elif (
			tile_color(curr_grid_pos + front()) == COLOR and 
			tile_color(curr_grid_pos + down()) == COLOR
		):
			print("Wall")
			return true
		return false
			

func read_neighborhood():
	curr_grid_neighborhood = []
	for i in range(25):
		curr_grid_neighborhood.append(curr_grid_pos + neighborhood_mask[i])
	
func get_mineable_tiles():
	var ret = []
	for i in range(-1, 2):
		for j in range(-1, 2):
			if i == 0 and j == 0:
				continue
			var curr_tile = curr_grid_pos + Vector2i(i, j)
			if tile_color(curr_tile) == COLOR:
				ret.append(curr_tile)
	return ret
	
func fill_mine_queue():
	print("Tile colors:")

	print("Front: ", tile_color(curr_grid_pos + front()))
	print("Down: ", tile_color(curr_grid_pos + down()))
	print("Front Down: ", tile_color(curr_grid_pos + front() + down()))

	var rand_num = randf()
	
	if (   # Case 1 
		tile_color(curr_grid_pos + up()) == COLOR
	):
		print("Case 1")
		mine_queue = [curr_grid_pos + up()]
	elif ( # Case 2
		tile_color(curr_grid_pos + down()) == COLOR and 
		tile_color(curr_grid_pos + front()) == COLOR and 
		tile_color(curr_grid_pos + front() + up()) == COLOR and 
		rand_num < .5
	):
		print("Case 2")
		mine_queue = [
			curr_grid_pos + front(), 
			curr_grid_pos + front() + up()
		]
	elif ( # Case 3
		tile_color(curr_grid_pos + front()) == COLOR and 
		tile_color(curr_grid_pos + down()) == COLOR and 
		tile_color(curr_grid_pos + front() + up()) != COLOR and 
		rand_num < .5
	):
		print("Case 3")		
		mine_queue = [
			curr_grid_pos + front()
		]
	elif ( # Case 4
		tile_color(curr_grid_pos + down()) == COLOR and 
		tile_color(curr_grid_pos + down() + front()) == COLOR and 
		tile_color(curr_grid_pos + down() + back()) == COLOR
	): 
		print("Case 4")		
		mine_queue = [
			curr_grid_pos + down(),
			curr_grid_pos + down() + back(),
			curr_grid_pos + down() + front(), 
		]
		
	## Pick a random tile 
	#var mineable_tiles = get_mineable_tiles()
	#var size = mineable_tiles.size()
	#var ret_idx = randi_range(0, size - 1)
	#print("Mineable tiles are ", mineable_tiles, ", picked: ", mineable_tiles[ret_idx])	
	#return mineable_tiles[ret_idx]
	
func mine_tile(targ: Vector2i):
	var new_tile_atlas_coord: Vector2i
	if COLOR == GLOBALS.color.blue:
		new_tile_atlas_coord = GLOBALS.atlas.default_red_tile
	elif COLOR == GLOBALS.color.blue:
		new_tile_atlas_coord = GLOBALS.atlas.default_blue_tile
	tilemap.set_cell(0, targ, 0, new_tile_atlas_coord)
	print("Mining tile at ", targ, " into ", new_tile_atlas_coord)

func tile_color(tile: Vector2i):
	if GLOBALS.bluetiles.has(tilemap.get_cell_atlas_coords(0, tile)):
		return GLOBALS.color.blue
	elif GLOBALS.redtiles.has(tilemap.get_cell_atlas_coords(0, tile)):
		return GLOBALS.color.red
	else:
		print("TILE AT ", tile, " IS NOT IN ATLAS! ")
		print("Atlas coords are ", tilemap.get_cell_atlas_coords(0, tile))

func tile_is_diff_color(tile: Vector2i):
	if COLOR == GLOBALS.color.blue:
		if GLOBALS.redtiles.has(tilemap.get_cell_atlas_coords(0, tile)):
			return true
		else:
			return false
	elif COLOR == GLOBALS.color.red:
		if GLOBALS.bluetiles.has(tilemap.get_cell_atlas_coords(0, tile)):
			return true
		else:
			return false
	
func up():
	if COLOR == GLOBALS.color.blue:
		return Vector2i(0, 1)
	elif COLOR == GLOBALS.color.red:
		return Vector2i(0, -1)

func down():
	if COLOR == GLOBALS.color.blue:
		return Vector2i(0, -1)
	elif COLOR == GLOBALS.color.red:
		return Vector2i(0, 1)

func front():
	if walking_right:
		if COLOR == GLOBALS.color.blue:
			return Vector2i(-1, 0)
		elif COLOR == GLOBALS.color.red:
			return Vector2i( 1, 0)
	else:
		if COLOR == GLOBALS.color.blue:
			return Vector2i( 1, 0)
		elif COLOR == GLOBALS.color.red:
			return Vector2i(-1, 0)

func back():
	if walking_right:
		if COLOR == GLOBALS.color.blue:
			return Vector2i( 1, 0)
		elif COLOR == GLOBALS.color.red:
			return Vector2i(-1, 0)
	else:
		if COLOR == GLOBALS.color.blue:
			return Vector2i(-1, 0)
		elif COLOR == GLOBALS.color.red:
			return Vector2i( 1, 0)


