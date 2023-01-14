extends Control


var settings = preload("res://source/scenes/menus/settings/settings.tscn")
var load_menu = preload("res://source/scenes/menus/serials/load.tscn")

@onready var button_container_ref: VBoxContainer = $HBoxContainer/MarginContainer/VBoxContainer

func _ready() -> void:
	Event.connect("reload_main_menu", check_menu_items)
	
	if OS.has_feature("JavaScript"):
		$HBoxContainer/MarginContainer/VBoxContainer/quit.queue_free()
	
	check_menu_items()
	
	button_container_ref.get_child(0).grab_focus()
	
	GlobalRefs.active_scene = self


func _on_play_pressed() -> void:
	SceneManager.emit_signal("change_scene_to_file", self, "res://source/scenes/main/world.tscn")


func _on_settings_pressed() -> void:
	var settings_popup = settings.instantiate()
	self.set_disabled(true)
	settings_popup.connect("tree_exited", set_disabled.bind(false))
	self.add_child(settings_popup)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_load_pressed():
	var load_popup = load_menu.instantiate()
	self.set_disabled(true)
	load_popup.connect("tree_exited", set_disabled.bind(false))
	self.add_child(load_popup)


func _on_continue_pressed():
	SaveMenu.load_latest_save()


func set_disabled(is_disabled: bool) -> void:
	# Use to disable the buttons in the main menu so they can't be clicked while another menu is open.
	for button in button_container_ref.get_children():
		button.disabled = is_disabled


func check_menu_items() -> void:
	if SerialisationManager.do_saves_exist():
		$HBoxContainer/MarginContainer/VBoxContainer/play.text = "New Game"
		$HBoxContainer/MarginContainer/VBoxContainer/continue.visible = true
		$HBoxContainer/MarginContainer/VBoxContainer/load.visible = true
	else:
		$HBoxContainer/MarginContainer/VBoxContainer/play.text = "Play"
		$HBoxContainer/MarginContainer/VBoxContainer/continue.visible = false
		$HBoxContainer/MarginContainer/VBoxContainer/load.visible = false
