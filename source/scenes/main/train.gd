class_name Train extends Node2D

# A train is a group of TrainCarriage objects
@export var is_main: bool = false
@export var train_carriage_node: PackedScene
@export var active: bool
@export var max_speed: float = 100 # Only used for chuggachugga pitch scale at the moment
var child_carriages = []
var locomotive_ref: TrainCarriage = null

var train_length: int = 0
var world: World
var tile_system: TileSystem
var current_speed: float = 0

var hex_check : RayCast2D

func _ready():
	hex_check = get_node_or_null("TileCheck")
	
	for child_train_carriage in get_children():
		if child_train_carriage.has_method("initialise_train_carriage"):
			if not child_train_carriage.is_locomotive:
				child_carriages.append(child_train_carriage)
			else:
				locomotive_ref = child_train_carriage
	Event.connect("update_train_speed_multiplier", _on_update_train_speed_multiplier)
	Event.connect("get_next_hex", get_next_hex)
	if hex_check != null:
		# Wait for a few hundred milliseconds, because waiting for ready signal doesn't seem to work?
		# Also tried waiting the draw signal, also didn't work.
		await get_tree().create_timer(0.2).timeout
		start_pathing()


func start_pathing() -> void:
	Event.emit_signal("generate_hex_path", get_next_hex())

#func on_update_speed(new_t_speed):
#	for child_train_carriage in child_carriages:
#		if child_train_carriage.has_method("update_speed"):
#			child_train_carriage.update_speed(new_t_speed)
	
func _physics_process(delta):
	if locomotive_ref != null:
		current_speed = locomotive_ref.speed

func initialise_train(world_ref: World, tile_system_ref: TileSystem) -> void:
	world = world_ref
	tile_system = tile_system_ref
	
	#if child_train_carriage.is_locomotive:
	#			print("this is the locamotive")
	#			#locomotive_ref = child_train_carriage
	#			child_train_carriage.initialise_train_carriage(self, tile_system, max_speed, self)
	#			previous_carriage = child_train_carriage
	
	var previous_carriage = null
	locomotive_ref.initialise_train_carriage(self, tile_system, max_speed, self)
	# child_carriages should only be the non locamotive carriages
	for child_train_carriage in child_carriages:
		if child_train_carriage.has_method("initialise_train_carriage"):
			print("this one isn't the main train part")
			if previous_carriage == null:
				print("this must be the first one in the list so the 'previous_carriage' should be locamotive")
				previous_carriage = locomotive_ref
			child_train_carriage.initialise_train_carriage(self, tile_system, max_speed, previous_carriage)
			previous_carriage = child_train_carriage

			
func _on_update_train_speed_multiplier(new_t_speed_multiplier):
	print("updating speed multiplier to: ", new_t_speed_multiplier)
	locomotive_ref.set_new_speed_multiplier(new_t_speed_multiplier)


func get_next_hex():
	hex_check.force_raycast_update()
	var collider = hex_check.get_collider()
	return collider
