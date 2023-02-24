class_name TrainCarriage extends Node2D

@export var is_locomotive: bool = false
var next_carriage: TrainCarriage
var target_speed: float = 20
var speed_multiplier: float = 1.0
var speed: float = 1  # TODO Get this from the parent
var carriage_initialised: bool = false
var crashed: bool = false

@onready var locomotive_sprite: AnimatedSprite2D = get_node("locomotive_sprite")
@onready var carriage_sprite: AnimatedSprite2D = get_node("carriage_sprite")
@onready var steam_particles: CPUParticles2D = get_node("CPUParticles2D")

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
	Event.connect("you_died", train_died)


func train_died():
	steam_particles.emitting = false

func update_speed(new_speed):
	speed = lerp(speed, new_speed, 0.2)

func set_new_speed_multiplier(new_speed_multiplier):
	if not crashed:
		speed_multiplier = new_speed_multiplier 

func _physics_process(delta):
	VariableManager.train_speed = speed
	if is_locomotive:
		change_active_frames(locomotive_sprite)
	else:
		change_active_frames(carriage_sprite)


func change_active_frames(sprite: AnimatedSprite2D):
	var current_angle = rad_to_deg(current_heading.angle())
	#print(current_angle)
	if current_angle >= -95 && current_angle < -85:
		sprite.set_animation("top")
	elif current_angle >= 85 && current_angle < 95:
		sprite.set_animation("down")
	elif current_angle >= -85 && current_angle < -5:
		sprite.set_animation("top_right")
	elif current_angle >= 5 && current_angle < 85:
		sprite.set_animation("down_right")


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
	
	if tile_system != null:
		current_tile_map_coord = tile_system.local_to_map(global_position)
		current_tile_center_coord = tile_system.map_to_local(current_tile_map_coord)
	
	carriage_initialised = true
	print("TRAIN CARRIAGE INIT, CURRENT HEADING" + str(current_heading))
