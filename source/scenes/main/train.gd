class_name Train extends Node2D

# A train is a group of TrainCarriage objects
@export var train_carriage_node: PackedScene

var locomotive_ref: TrainCarriage

var train_length: int = 0
var world: World
var tile_system: TileSystem


func _ready():
	pass


func _process(delta):
	pass


func initialise_train(world_ref: World, tile_system_ref: TileSystem) -> void:
	world = world_ref
	tile_system = tile_system_ref
	
	var previous_carriage
	
	for child_train_carriage in get_children():
		if child_train_carriage.has_method("initialise_train_carriage"):
			if child_train_carriage.is_locomotive:
				locomotive_ref = child_train_carriage
				child_train_carriage.initialise_train_carriage(self, tile_system)
				previous_carriage = child_train_carriage
			else:
				child_train_carriage.initialise_train_carriage(self, tile_system, previous_carriage)
				previous_carriage = child_train_carriage
	
	
