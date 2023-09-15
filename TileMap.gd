extends TileMap


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var mouse_position = self.local_to_map(self.get_local_mouse_position())
	var atlas_coords = self.get_cell_atlas_coords(0, mouse_position)
	
	print("Cell at position", mouse_position, "is", atlas_coords)

