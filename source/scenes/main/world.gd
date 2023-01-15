class_name World extends Node2D

@onready var tile_system: TileSystem = get_node("%tile_system")
@onready var train: Train = get_node("%train")

var curr_train_speed: int = 100

func _ready():
	train.initialise_train(self, tile_system)


func _process(delta):
	pass
