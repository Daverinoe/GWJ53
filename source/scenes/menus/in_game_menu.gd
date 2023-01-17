extends Control

@onready var button_refs := [
	$MarginContainer/VBoxContainer/MarginContainer5/Resume,
	$MarginContainer/VBoxContainer/MarginContainer/SaveGame,
	$MarginContainer/VBoxContainer/MarginContainer2/LoadGame,
	$MarginContainer/VBoxContainer/MarginContainer3/Settings,
	$MarginContainer/VBoxContainer/MarginContainer4/Quit,
]

var is_sub_menu_open := false

func _ready() -> void:
	GlobalRefs.active_menu = self
	print('level_ref: ', GlobalRefs.level_ref)
	GlobalRefs.level_ref.process_mode = PROCESS_MODE_DISABLED


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu") and !is_sub_menu_open:
		self.queue_free()


func _on_save_game_pressed() -> void:
	var menu_instance = GlobalRefs.save_menu_ref.instantiate()
	
	load_sub_menu(menu_instance)


func _on_load_game_pressed() -> void:
	var menu_instance = GlobalRefs.load_menu_ref.instantiate()
	
	load_sub_menu(menu_instance)


func _on_settings_pressed() -> void:
	var menu_instance = GlobalRefs.settings_menu_ref.instantiate()
	
	load_sub_menu(menu_instance)


func _on_quit_pressed() -> void:
	SceneManager.emit_signal("change_scene_to_file", get_parent(), GlobalRefs.main_menu_path)


func set_menu_open() -> void:
	is_sub_menu_open = false
	change_interaction(false)


func change_interaction(is_enabled: bool) -> void:
	for button in button_refs:
		button.disabled = is_enabled


func load_sub_menu(menu_instance) -> void:
	menu_instance.process_mode = Node.PROCESS_MODE_ALWAYS
	menu_instance.top_level = true
	is_sub_menu_open = true
	menu_instance.connect("tree_exited", set_menu_open)
	self.add_child(menu_instance)
	
	# Turn off interaction
	change_interaction(true)


func _on_tree_exiting():
	GlobalRefs.level_ref.process_mode = PROCESS_MODE_INHERIT


func _on_resume_pressed():
	self.queue_free()
