class_name PlayerCamera extends Camera2D

@export var min_zoom_level: float = 0.5
@export var max_zoom_level: float = 2.5  # TODO: Set by the active tile set

@export var zoom_factor: float = 0.2
@export var zoom_duration: float = 0.2

@export var drag_factor: float = 0.000000000001
var follow_factor: float = 0.2  # The factor for following the target position - <0.5 for smooth drag, 1.0 for tight

var locomotive: TrainCarriage  # Used as an anchor

# Set up the bounds of the camera
var min_x: int = 0
var max_x: int = 0
var min_y: int = 0
var max_y: int = 0

var target_pos: Vector2 = Vector2.ZERO
var scroll_active: bool = false
var follow_train: bool = false

var zoom_level: float = 1.0: set = _set_zoom_level


func initialise_camera(locomotive_ref: TrainCarriage) -> void:
	locomotive = locomotive_ref
	follow_train = true


func _ready():
	pass


func _process(delta: float):
	if follow_train:
		# Chase the train
		target_pos = locomotive.global_position
		
	global_position = lerp(global_position, target_pos, follow_factor)
	


func _input(event):
	if event.is_action_pressed("reset_camera"):
		global_position = locomotive.global_position
		target_pos = locomotive.global_position
		follow_factor = 0.2
		follow_train = true
	
	if event.is_action_pressed("zoom_in"):
		_set_zoom_level(zoom_level - zoom_factor)
		print("I zoomed!")
	elif event.is_action_pressed("zoom_out"):
		_set_zoom_level(zoom_level + zoom_factor)
	
	if event.is_action_pressed("click_drag"):
		if not scroll_active:
			follow_train = false
			scroll_active = true
			follow_factor = 1.0
		
	if event.is_action_released("click_drag"):
		scroll_active = false
		
	if event is InputEventMouseMotion and scroll_active:
		target_pos -= event.relative


func _set_zoom_level(value: float) -> void:
	zoom_level = clamp(value, min_zoom_level, max_zoom_level)
	create_tween() \
	.tween_property(self, "zoom", Vector2(zoom_level, zoom_level), zoom_duration) \
	.set_trans(Tween.TRANS_SINE) \
	.set_ease(Tween.EASE_OUT)

# TODO: This should be based on the limits of the fog of war
func update_limits(active_blob_world_coords: Array[Vector2i]) -> void:
	var new_min_x: int = 1e10
	var new_max_x: int = -1e10
	var new_min_y: int = 1e10
	var new_max_y: int = -1e10
	
	for coord in active_blob_world_coords:
		new_min_x = min(new_min_x, coord[0])
		new_max_x = max(new_max_x, coord[0])
		new_min_y = max(new_min_y, coord[1])
		new_max_y = max(new_max_y, coord[1])
