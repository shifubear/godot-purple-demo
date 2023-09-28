extends CharacterBody2D

# Editor properties 
@export var PLAYER_COLOR : GLOBALS.color
@export var TOP_SPEED : float
var PLAYER_ACCELERATION : float
var PLAYER_DECELERATION : float
@export var JUMP_VELOCITY : float
@export var TERMINAL_VELOCITY : float
@export var mineable_distance : float

@onready var _animated_sprite = $AnimatedSprite2D

# Mouse/Input properties
var prev_mouse_position : Vector2i
var prev_mouse_color : GLOBALS.color

# Player meta data
var block_stock : int
var my_map_position : Vector2i

# Map properties
var tilemap : TileMap
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Utility variables

# Called when the node enters the scene tree for the first time.
func _ready():
	# Initialize prev_mouse_position with current position
	tilemap = get_owner().find_child("TileMap")
	prev_mouse_position = tilemap.local_to_map(self.get_local_mouse_position())
	prev_mouse_color = GLOBALS.color.none
	PLAYER_ACCELERATION = TOP_SPEED / 15.0
	PLAYER_DECELERATION = TOP_SPEED / 3.0
	

func _physics_process(delta):
	my_map_position = tilemap.local_to_map(tilemap.to_local(self.position))
	mouse_handler()
	
	# Add the gravity.
	if not is_on_floor():
		if velocity.y >= 0:
			velocity.y = max(velocity.y + gravity * delta, TERMINAL_VELOCITY)
		else:
			velocity.y += gravity * delta
	
	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		print("Jumping")

		velocity.y = JUMP_VELOCITY


	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("left", "right")
	if direction:
		if direction < 0:
			_animated_sprite.set_flip_h(true)
			velocity.x = max(velocity.x - PLAYER_ACCELERATION, -TOP_SPEED)
		elif direction > 0:
			_animated_sprite.set_flip_h(false)
			velocity.x = min(velocity.x + PLAYER_ACCELERATION, TOP_SPEED)
		_animated_sprite.play("run")
	else:
		velocity.x = move_toward(velocity.x, 0, PLAYER_DECELERATION)
		if is_on_floor():
			_animated_sprite.play("idle")

	move_and_slide()
	
	
func mouse_handler():
	## ==================================================================
	##                          LOOP STARTUP 
	## ==================================================================
	var curr_mouse_position = tilemap.local_to_map(tilemap.get_local_mouse_position())
	var atlas_coords = tilemap.get_cell_atlas_coords(0, curr_mouse_position)
	var curr_color = atlas_coord_to_color(atlas_coords)
	var distance_to_mouse = Vector2(my_map_position).distance_to(curr_mouse_position)

	
	## ==================================================================
	##                        MOUSE HOVER LOGIC
	## ==================================================================
	# If the current coordinate is the default blue tile:
	if distance_to_mouse > 0 and (curr_mouse_position - my_map_position != Vector2i(0,- 1)):
		if (atlas_coords == GLOBALS.atlas.default_blue_tile):
			if distance_to_mouse > mineable_distance:
				tilemap.set_cell(0, curr_mouse_position, 0, GLOBALS.atlas.hover_blue_tile_far)
			else:
				tilemap.set_cell(0, curr_mouse_position, 0, GLOBALS.atlas.hover_blue_tile_close)		# If the current coordinate is the default red tile:
		elif (atlas_coords == GLOBALS.atlas.default_red_tile):
			if distance_to_mouse > mineable_distance:
				tilemap.set_cell(0, curr_mouse_position, 0, GLOBALS.atlas.hover_red_tile_far)
			else:
				tilemap.set_cell(0, curr_mouse_position, 0, GLOBALS.atlas.hover_red_tile_close)		# If the current coordinate is the default red tile:
	
	# Reset the tile state when mouse moves away
	if (curr_mouse_position != prev_mouse_position):
		if (prev_mouse_color == GLOBALS.color.red):
			tilemap.set_cell(0, prev_mouse_position, 0, GLOBALS.atlas.default_red_tile)
		elif (prev_mouse_color == GLOBALS.color.blue):
			tilemap.set_cell(0, prev_mouse_position, 0, GLOBALS.atlas.default_blue_tile)
	
	## ==================================================================
	##                        MOUSE CLICK LOGIC
	## ==================================================================	
	if (Input.is_action_just_pressed("secondary_fire")):
		print("Attacking")
	elif (Input.is_action_just_pressed("primary_fire") and mineable_tile(curr_mouse_position)):
		print("Mouse clicked at ", curr_mouse_position)
		if (curr_color == GLOBALS.color.red):
			tilemap.set_cell(0, prev_mouse_position, 0, GLOBALS.atlas.default_blue_tile)
			curr_color = GLOBALS.color.blue
			_animated_sprite.play("mine")
		elif (curr_color == GLOBALS.color.blue):
			tilemap.set_cell(0, prev_mouse_position, 0, GLOBALS.atlas.default_red_tile)		
			curr_color = GLOBALS.color.red
			_animated_sprite.play("mine")


	## ==================================================================
	##                       LOOP POSTPROCESSING
	## ==================================================================
	prev_mouse_position = curr_mouse_position
	prev_mouse_color = curr_color

func mineable_tile(mouse_position):
	var distance_to_mouse = Vector2(my_map_position).distance_to(mouse_position)
	return distance_to_mouse > 0 and distance_to_mouse < mineable_distance and (mouse_position - my_map_position != Vector2i(0,- 1))

func atlas_coord_to_color(atlas_coord):
	if (GLOBALS.bluetiles.has(atlas_coord)):
		return GLOBALS.color.blue
	elif (GLOBALS.redtiles.has(atlas_coord)):
		return GLOBALS.color.red
	else:
		return GLOBALS.color.none
