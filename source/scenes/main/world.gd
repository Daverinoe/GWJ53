class_name World extends MainScene

@onready var tile_system: TileSystem = get_node("%tile_system")
@onready var train: Train = get_node("%train")
@onready var player_camera: PlayerCamera = get_node("%player_camera")

var curr_train_speed: int = 100


func _ready():
	train.initialise_train(self, tile_system)
	player_camera.initialise_camera(train.locomotive_ref)


func _process(delta):
	pass
