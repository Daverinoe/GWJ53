class_name World extends MainScene


const GRID_SIZE: int = 16


var curr_train_speed: int = 100

# Fog reveal vars
var light_image : Image = Image.load_from_file("res://assets/tile_system/fog_light.png")
var light_offset : Vector2 = Vector2(light_image.get_width()/2.0, light_image.get_height()/2.0)
# Fog vars
var fog_image : Image
var fog_texture : ImageTexture

@onready var tile_system: TileSystem = get_node("%tile_system")
@onready var train: Train = get_node("%train")
@onready var player_camera: PlayerCamera = get_node("%player_camera")
@onready var fog: Sprite2D = $%Fog


func _ready():
	# This should fire every time the train enters a cell, and should reveal that area
	Event.connect("train_on_cell", update_fog)
	
	train.initialise_train(self, tile_system)
	player_camera.initialise_camera(train.locomotive_ref)
	
	initialise_fog()
	update_fog_texture()


func _process(delta):
	pass


func initialise_fog() -> void:
	# TODO: Update for procedural generation?
	var window_size: Vector2i = DisplayServer.window_get_size_with_decorations()
	
	# Create initial fog
	fog_image = Image.create(window_size.x, window_size.y, false, Image.FORMAT_RGBAH)
	fog_image.fill(Color.BLACK)

	light_image.convert(Image.FORMAT_RGBAH) # Ensure compatibility	


func update_fog(new_position: Vector2) -> void:
	# Create rect to blend with fog
	var light_rect: Rect2 = Rect2(Vector2.ZERO, Vector2(light_image.get_width(), light_image.get_height()))
	fog_image.blend_rect(light_image, light_rect, new_position - light_offset)
	
	# Update the displayed fog
	update_fog_texture()


func update_fog_texture() -> void:
	fog_texture = ImageTexture.create_from_image(fog_image)
	fog.texture = fog_texture


