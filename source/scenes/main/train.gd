class_name Train extends Node2D

# A train is a group of TrainCarriage objects
@export var train_carriage_node: PackedScene
<<<<<<< HEAD
@export var is_main_train: bool
=======
@export var active: bool
@export var max_speed: float = 100 # Only used for chuggachugga pitch scale at the moment
>>>>>>> main

var locomotive_ref: TrainCarriage = null

var train_length: int = 0
var world: World
var tile_system: TileSystem

<<<<<<< HEAD
=======

var current_speed: float = 0

>>>>>>> main
func _ready():
	pass


func _physics_process(delta):
	if locomotive_ref != null:
		current_speed = locomotive_ref.speed


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


func get_locomotive() -> TrainCarriage:
	return locomotive_ref
