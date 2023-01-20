extends Node

# Emit this signal to switch between scenes.
signal change_scene_to_file(scene1, scene_path)
signal load_save_from_file(scene1, scene_path, load_requested, json_path)
signal finished_loading()


# List of loading screen hints
const HINTS : PackedStringArray = [
	"If you mix red and green, you get yellow!",
	"If you're having trouble winning, just quit!",
	"Hints are cool!",
]


var path_to_load: String
var new_instance = null
var is_finished_loading := false
var load_variables = null
var background = preload("res://source/scenes/menus/main_menu/menu_background.tscn")

var train_tween : Tween
var track_tween : Tween


@onready var hint_ref = $VBoxContainer/hint
@onready var finished_ref = $VBoxContainer/finished


func _ready() -> void:
	randomize()
	set_process(false)
	self.visible = false
	
	connect("change_scene_to_file", switch_scenes)
	connect("load_save_from_file", switch_scenes)


func _process(_delta):
	# Check load progress and update progress bar
	var error_code = ResourceLoader.load_threaded_get_status(path_to_load)
	if error_code == ResourceLoader.THREAD_LOAD_LOADED:
		emit_signal("finished_loading")
	elif error_code == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		pass
	elif error_code == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		pass
	else:
		push_error("Loading new scene failed!")


func _input(event):
	# Also check for action released of the select button, so it doesn't automatically load into the game if the 
	# file is small enough.
	if is_finished_loading and !(event is InputEventMouseMotion) and !event.is_action_released("ui_select"):
		pass
		finish_switch()


func switch_scenes(previous_scene_reference, next_scene_path, is_load_request: bool = false, load_json: Dictionary = {}) -> void:
	
	var bg_to_load = background.instantiate()
	self.add_child(bg_to_load)
	self.move_child(bg_to_load, 0)
	
	animate_train()
	
	path_to_load = next_scene_path
	
	initiate_load(previous_scene_reference)
	
	if is_load_request:
		# Handle the load JSON instead
		path_to_load = handle_load_json(load_json)
	
	# Load new scene
	ResourceLoader.load_threaded_request(path_to_load)
	await self.finished_loading
	is_finished_loading = true

	# Instance new scene
	var new_scene = ResourceLoader.load_threaded_get(path_to_load)
	new_instance = new_scene.instantiate()
	new_instance.visible = false
	new_instance.modulate = Color(1.0, 1.0, 1.0, 0.0)
	
	new_instance.set_process_mode(Node.PROCESS_MODE_DISABLED)
	
	# If loading, pass off instance to the load handler
	if load_variables != null:
		apply_load_variables()
	
	if next_scene_path == GlobalRefs.main_menu_path:
		finish_switch()
	
	
	loading_animation(false)
	self.set_process(false)
	
	hint_ref.visible = false
	finished_ref.visible = true
	finished_ref.text =  "Press any key to continue."


func tween_load_visibility(start_alpha, final_alpha) -> void:
	var tween = get_tree().create_tween()
	var property_tweener : PropertyTweener = tween.tween_property(
		self,
		"modulate",
		Color(1.0, 1.0, 1.0, final_alpha),
		0.5
	)
	
	property_tweener.from(Color(1.0, 1.0, 1.0, start_alpha))
	tween.play()
	await tween.finished


func finish_switch() -> void:
	finish_train_animation()
	
	await train_tween.finished
	track_tween.kill()
	
	$menu_background.queue_free()
	
	new_instance.modulate = Color(1.0, 1.0, 1.0, 1.0)
	new_instance.visible = true
	# Fade out loading scene
	tween_load_visibility(1.0, 0.0)
	self.visible = false
	new_instance.set_process_mode(Node.PROCESS_MODE_INHERIT)
	get_tree().root.add_child(new_instance)
	new_instance = null
	is_finished_loading = false
	pass
	


func loading_animation(is_playing: bool) -> void:
	$loading_texture.visible = is_playing
	$AnimationPlayer.play("loading")


func set_hint() -> void:
	hint_ref.text = HINTS[randi() % HINTS.size()]
	# If loading, get a new hint every few seconds
	if !is_finished_loading:
		await get_tree().create_timer(6.0).timeout
		set_hint()


func initiate_load(previous_scene_reference) -> void:
	hint_ref.visible = true
	finished_ref.visible = false
	set_hint()
	
	self.visible = true
	# Fade in loading scene
	tween_load_visibility(0, 1.0)
	
	loading_animation(true)
	self.set_process(true)
	
	# Remove old scene
	(previous_scene_reference as Node).queue_free() 


func handle_load_json(load_json: Dictionary) -> String:
	# Load the JSON file, return the active scene path, and then load
	# the serialise scene details into load_variables
	load_variables = load_json
	return load_json.active_scene


func apply_load_variables() -> void:
	var persist_scenes = get_tree().get_nodes_in_group("Persist")
	
	for scene in persist_scenes:
		var variables = load_variables[scene.name]
		scene.load_data(variables[scene.name])


func animate_train() -> void:
	# Move track under the train
	track_tween = get_tree().create_tween()
	track_tween.set_ease(Tween.EASE_IN)
	track_tween.tween_method(
		set_scroll_speed,
		0.0,
		0.5,
		30.0
	)
	
	track_tween.play()
	
	# Move the train back and forth
	var initial_position = $menu_background/train.position.x
	train_tween = get_tree().create_tween()
	
	train_tween.set_loops()
	train_tween.set_ease(Tween.EASE_IN_OUT)
#	train_tween.set_trans(Tween.TRANS_EXPO)
	
	train_tween.tween_property(
		$menu_background/train,
		"position:x",
		initial_position - 400,
		8.0
	)
	
	train_tween.tween_interval(2)
	
	train_tween.tween_property(
		$menu_background/train,
		"position:x",
		initial_position,
		8.0
	)
	
	train_tween.play()


func set_scroll_speed(speed) -> void:
	$menu_background/background.material.set_shader_parameter("scroll_speed", speed)


func finish_train_animation() -> void:
	var train = $menu_background/train
	var current_position = train.position.x
	
	train_tween.kill()
	train_tween = get_tree().create_tween()
	train_tween.set_ease(Tween.EASE_IN)
	train_tween.set_trans(Tween.TRANS_EXPO)
	
	train.position.x = current_position
	
	train_tween.tween_property(
		train,
		"position:x",
		current_position + 2 * DisplayServer.screen_get_size().x,
		2.0
	)
	
	train_tween.play()
