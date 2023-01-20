class_name TrainCarriage extends Node2D

@export var is_locomotive: bool = false
var next_carriage: TrainCarriage
var target_speed: float = 20
var speed_multiplier: float = 1.0
var speed: float = 0  # TODO Get this from the parent
var carriage_initialised: bool = false

@onready var locomotive_sprite: AnimatedSprite2D = get_node("locomotive_sprite")
@onready var carriage_sprite: AnimatedSprite2D = get_node("carriage_sprite")

# Handle vector based movement
var current_heading: Vector2
var check_tile_coord: Vector2i
var current_tile_map_coord: Vector2i
var current_tile_center_coord: Vector2
var current_tile_entrypoint: TileSystem.HexPos
var tile_centre_reached: bool = false

var train: Train
var tile_system: TileSystem 


func _ready():
	if is_locomotive:
		locomotive_sprite.visible = true
		carriage_sprite.visible = false
	else:
		carriage_sprite.visible = true
		locomotive_sprite.visible = false

func update_speed(new_speed):
	speed = lerp(speed, new_speed, 0.2)

func set_new_speed_multiplier(new_speed_multiplier):
	speed_multiplier = new_speed_multiplier 

func _physics_process(delta):
	if carriage_initialised:
		update_speed(target_speed * speed_multiplier)
		#speed = lerp(speed, target_speed, 0.2)  # Provide some linear acceleration to the train
		_check_vector_change()
		global_position += current_heading * speed * delta
	if is_locomotive:
		change_active_frames(locomotive_sprite)
	else:
		change_active_frames(carriage_sprite)


func _process(delta):
	# Look at heading in a lerp fashion
	rotation_degrees = lerp(rotation_degrees, rad_to_deg(current_heading.angle()), 0.5)

func change_active_frames(sprite: AnimatedSprite2D):
	var current_angle = rad_to_deg(current_heading.angle())
	print(current_angle)
	if current_angle >= -95 && current_angle < -85:
		sprite.set_animation("top")
	elif current_angle >= 85 && current_angle < 95:
		sprite.set_animation("down")
	elif current_angle >= -85 && current_angle < -5:
		sprite.set_animation("top_right")
	elif current_angle >= 5 && current_angle < 85:
		sprite.set_animation("down_right")


func _get_tile_entrypoint() -> TileSystem.HexPos:
	# Get the entry position (as TileSystem.HexPos) to ensure we don't head to
	# that from the center point
	var heading_x = current_heading.sign()[0]
	var heading_y = current_heading.sign()[1]
	
	if heading_x == -1.0 and abs(current_heading[0]) > 0.1:  # entered from the right
		if heading_y == -1.0:  # entered from bottom
			return tile_system.HexPos.RIGHT_BOTTOM
		else:
			return tile_system.HexPos.RIGHT_TOP
	
	elif heading_x == 1.0 and abs(current_heading[0]) > 0.1:  # entered from the left
		if heading_y == -1.0:  # entered from bottom
			return tile_system.HexPos.LEFT_BOTTOM
		else:
			return tile_system.HexPos.LEFT_TOP
			
	else:  # Entered from the top/bottom
		if heading_y == -1.0:
			return tile_system.HexPos.BOTTOM
		else:
			return tile_system.HexPos.TOP


func _check_close_enough_to_center() -> bool:
	return abs(global_position.x - current_tile_center_coord.x) < 1.0 \
			and abs(global_position.y - current_tile_center_coord.y) < 1.0


func _check_vector_change() -> void:
	check_tile_coord = tile_system.local_to_map(global_position)
	if check_tile_coord != current_tile_map_coord:
		# In this case, we have entered a new tile. Do checks here
		tile_centre_reached = false
		if is_locomotive:
			pass  # TODO: Check illegal tile
				
		current_tile_map_coord = check_tile_coord
		current_tile_center_coord = tile_system.map_to_local(current_tile_map_coord)
		
		# Emit signal to fog of war process
		if get_parent().is_main:
			Event.emit_signal("train_on_cell", current_tile_center_coord)
		
		""" TODO: Fix this - using the current global_position can cause the train to be
		offset from the track. This should instead snap to a tile property, such as
		from tile_system.HEX_RELATIVE_POS_MAPPING
		"""
		current_heading = (current_tile_center_coord - global_position).normalized()
		print("NEW HEADING ", str(current_heading))
		
		current_tile_entrypoint = _get_tile_entrypoint()
		
	# If not a new tile, then we need to check if we have hit the center
	elif _check_close_enough_to_center() and not tile_centre_reached:
		# Get new heading at this point
		tile_centre_reached = true
		
		# Note: Duplicated here to ensure that the original lookup is unaffected
		var available_exits: Array = tile_system.ATLAS_MAP_LOOKUP[
			tile_system.get_cell_atlas_coords(0, current_tile_map_coord)
			].duplicate()
		print("current tile map coordinate:", current_tile_center_coord)
		print("available exits:", available_exits)
		
		available_exits.erase(current_tile_entrypoint)
		assert(len(available_exits) > 0)
		
		# TODO: IF LEN > 1 support random choice
		current_heading = (
			(current_tile_center_coord + Vector2(tile_system.HEX_RELATIVE_POS_MAPPING[available_exits[0]])
			) - global_position).normalized()
			
		# Lock carriage to center
		global_position = current_tile_center_coord
		print("HIT CENTRE, NEW HEADING " + str(current_heading))
		

func initialise_train_carriage(train_ref: Train, tile_system_ref: TileSystem, t_speed: float, next_carriage_ref=null) -> void:
	# Currently handling this as dependency injection rather than globals
	train = train_ref
	tile_system = tile_system_ref
	target_speed = t_speed * speed_multiplier
	# locomotive should decide if it is the front of the train
	# We still want non locomotive parts of the train to move (carrages should still move). 
	current_heading = Vector2.DOWN

	if not is_locomotive:
		next_carriage = next_carriage_ref
		current_heading = next_carriage.current_heading
	
	current_tile_map_coord = tile_system.local_to_map(global_position)
	current_tile_center_coord = tile_system.map_to_local(current_tile_map_coord)
	
	carriage_initialised = true
	print("TRAIN CARRIAGE INIT, CURRENT HEADING" + str(current_heading))
