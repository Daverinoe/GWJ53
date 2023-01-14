class_name World extends MainScene

@onready var tile_system: TileSystem = get_node("%tile_system")
@onready var train_path: TrainPath = get_node("%train_path")


func _ready():
	print(tile_system)
	train_path.initialise_path_logic(tile_system)


func _process(delta):
	pass
