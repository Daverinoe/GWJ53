class_name World extends MainScene

var curr_train_speed: int = 100

# Fog reveal vars
var light_texture = preload("res://assets/tile_system/fog_light_x4.png")
var light_image : Image
var light_offset : Vector2 = Vector2(light_texture.get_width()/2.0, light_texture.get_height()/2.0)
# Fog vars
var thread = Thread.new()
var fog_texture : ImageTexture
var fog_images : Dictionary = {}
var initial_view : int = 2
var current_chunk : Dictionary = {}
var dict_key : String = ""
var neighbours_and_offsets : Array
var previous_chunk : Dictionary = {}
var fog_material : CanvasItemMaterial = preload("res://assets/materials/fog_sprite_material.tres")
var chunk_size : Vector2i

@onready var tile_system: TileSystem = get_node("%tile_system")
@onready var train: Train = get_node("%train")
@onready var player_camera: PlayerCamera = get_node("%player_camera")
@onready var fog_container: Node2D = $%Fog
@onready var gameover_graphic: TextureRect = get_node("%GameOverGraphic")


func _ready():
	chunk_size = light_texture.get_size()
	
	# This should fire every time the train enters a cell, and should reveal that area
	Event.connect("train_on_cell", threaded_update_fog)
	
	Event.connect("you_died", you_died)
	get_tree().call_group("Train", "initialise_train", self, tile_system)
	player_camera.initialise_camera(train.locomotive_ref)
	
	initialise_fog()
	update_fog_texture(fog_images["0_0:0_0"])
	GlobalRefs.level_ref = self
	
	var timer = get_tree().create_timer(0.3)
	timer.connect("timeout", start_game)


func _process(delta):
	pass


func start_game() -> void:
	Event.emit_signal("start_pathing")


func you_died():
	gameover_graphic.visible = true


func initialise_fog() -> void:
	# TODO: Update for procedural generation?
	
	for i in range(-2, 3):
		for j in range(-2, 3):
			# Create initial fog
			var fog_image = Image.create(chunk_size.x, chunk_size.y, false, Image.FORMAT_RGBAH)
			fog_image.fill(Color.BLACK)
			
			# Create sprite for texture
			var fog_sprite = Sprite2D.new()
			fog_sprite.position = chunk_size * Vector2i(i, j)
			fog_sprite.centered = false
			fog_sprite.material = fog_material
			fog_container.add_child(fog_sprite)
			
			# Add to dictionary by position
			var dict_string = vec2_to_dict_string(fog_sprite.position)
			fog_images[dict_string] = {
				"image": fog_image,
				"sprite": fog_sprite
			}
	
	for key in fog_images.keys():
		var chunk = fog_images[key]
		update_fog_texture(chunk)
	
	light_image = light_texture.get_image()
	light_image.convert(Image.FORMAT_RGBAH) # Ensure compatibility	
	
	update_fog(train.get_global_transform().origin)
	# If you want multiple trains to be reveailing the fog of war at once: 
	#for t in get_tree().get_nodes_in_group("Train"):
	#	update_fog(t.get_global_transform().origin)


func update_fog(new_position: Vector2) -> void:
	# Create rect to blend with fog
	var light_rect: Rect2 = Rect2(Vector2.ZERO, Vector2(light_image.get_width(), light_image.get_height()))
	
	if dict_key == "":
		dict_key = get_current_chunk(new_position)
	var this_chunk = fog_images[dict_key]
	
	var chunk_changed: bool = false
	if this_chunk != current_chunk:
		current_chunk = this_chunk
		chunk_changed = true
	
	var fog_image = current_chunk["image"]
	fog_image.blend_rect(light_image, light_rect, new_position - light_offset)
	
	# Update the displayed fog
	update_fog_texture(current_chunk)
	
	# Also update neighbouring chunks
	if chunk_changed:
		neighbours_and_offsets = get_neighbouring_chunks_and_offsets(dict_key)
	var neighbours = neighbours_and_offsets[0]
	var offsets = neighbours_and_offsets[1]
	for i in range(neighbours.size()):
		var key = neighbours[i]
		var chunk = fog_images[key]
		fog_image = chunk["image"]
		
		# Add offset * -1 to account for direction of chunk from center chunk
		fog_image.blend_rect(light_image, light_rect, new_position - light_offset - offsets[i])
		
		update_fog_texture(chunk)


func update_fog_texture(chunk: Dictionary) -> void:
	var fog_image = chunk["image"]
	var current_texture = chunk["sprite"].texture
	if current_texture != null:
		(current_texture as ImageTexture).update(fog_image)
	else:
		var fog_texture = ImageTexture.create_from_image(fog_image)
		chunk["sprite"].texture = fog_texture


func start_following() -> void:
	player_camera.current = true


func dict_string_to_vec2(dict_string) -> Vector2:
	var x_y_strings = dict_string.split(":")
	var x = str_to_var(x_y_strings[0].replace("_", "."))
	var y = str_to_var(x_y_strings[1].replace("_", "."))
	return Vector2(x, y)

func vec2_to_dict_string(vector: Vector2) -> String:
	return (var_to_str(vector.x).replace('.', '_') 
	+ ":" 
	+ var_to_str(vector.y).replace('.', '_') )


func get_current_chunk(new_position: Vector2) -> String:
	# Select correct image to update
	var key_to_use : String
	var dict_keys = fog_images.keys()
	
	# Search for x_index
	var x_index
	for i in range(dict_keys.size()):
		var image_position: Vector2 = dict_string_to_vec2(dict_keys[i])
		if new_position.x > image_position.x:
			continue
		x_index = i - 1
		break
	
	# Search for y_index
	var y_index
	for j in range(x_index, dict_keys.size()):
		var image_position: Vector2 = dict_string_to_vec2(dict_keys[j])
		if new_position.y > image_position.y:
			continue
		y_index = j - 2
		break
	
	return dict_keys[y_index]


func get_neighbouring_chunks_and_offsets(chunk_key: String) -> Array:
	var current_position: Vector2 = dict_string_to_vec2(chunk_key)
	
	# Get neighbour keys by subb/add-ing the chunk size to the current position
	var neighbours: PackedStringArray = PackedStringArray([])
	var offsets: Array = []
	for i in [-1, 0, 1]:
		for j in [-1, 0, 1]:
			# Skip current position
			if i == 0 and j == 0:
				continue
			
			var offset = (chunk_size as Vector2) * Vector2(i, j)
			offsets.push_back(offset)
			
			var new_neighbour = current_position + offset
			var new_neighbour_key = vec2_to_dict_string(new_neighbour)
			neighbours.push_back(new_neighbour_key)
	return [neighbours, offsets]


func threaded_update_fog(new_position: Vector2) -> void:
	if thread.is_alive():
		pass
	
	if thread.is_started():
		thread.wait_to_finish()
	
	thread.start(update_fog.bind(new_position))



func _on_tree_exiting() -> void:
	thread.wait_to_finish()
