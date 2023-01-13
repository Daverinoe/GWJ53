extends Control
class_name SaveMenu

@export var save_scroller: VBoxContainer
@export var confirm_dialog: ConfirmationDialog
@export var save_name_dialog: ConfirmationDialog

var save_file = preload("res://source/scenes/menus/serials/save_game.tscn")
var current_selection = null

@onready var line_edit: LineEdit = LineEdit.new()
@onready var save_game_files: PackedStringArray = SerialisationManager.get_save_game_paths()

func _ready() -> void:
	# Need to swap buttons because otherwise the layout is different to what I want
	confirm_dialog.get_cancel_button().pressed.connect(_handle_confirm_choice.bind(true))
	confirm_dialog.get_ok_button().pressed.connect(_handle_confirm_choice.bind(false))
	
	confirm_dialog.position = get_viewport_rect().size / 2 - (confirm_dialog.size / 2 as Vector2)
	save_name_dialog.position = get_viewport_rect().size / 2 - (save_name_dialog.size / 2 as Vector2)
	
	save_name_dialog.get_cancel_button().pressed.connect(save_game.bind("", true))
	save_name_dialog.add_child(line_edit)
	save_name_dialog.register_text_enter(line_edit)

	get_saves()
	
	# Give focus to the top save
	if save_scroller.get_child_count() > 0:
		save_scroller.get_child(0).grab_focus()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		self.queue_free()


func _on_cancel_button_pressed() -> void:
	self.queue_free()


func _on_save_button_pressed(save_name: String = "", override: bool = false) -> void:
	
	if current_selection != null and !override:
		confirm_dialog.visible = true
		return
	
	if current_selection == null and override:
		save_game(save_name)
	
	if save_name == "":
		line_edit.text = "Save " + str(save_game_files.size() + 1)
		save_name_dialog.visible = true



func save_game(save_name, get_from_line_edit: bool = false) -> void:
	if get_from_line_edit:
		save_name = line_edit.text
	
	# Don't allow empty save game names
	if save_name == "":
		save_name = "Save " + str(save_game_files.size() + 1)
	
	await SerialisationManager.save(save_name.replace(" ", "_"))
	self.queue_free()


func get_saves() -> void:
	if save_game_files.size() < 1:
		return
	
	var sorted = sort_saves()
	var key_strings = sorted[0]
	var sort_dict = sorted[1]
	
	for key in key_strings:
		var new_child = sort_dict[key]
		new_child.connect("selected", select_save)
		save_scroller.add_child(new_child)


static func get_save(file: String) -> Dictionary:
	var save_scene = load("res://source/scenes/menus/serials/save_game.tscn")
	var gotten_save = save_scene.instantiate()
	
	var file_path = SerialisationManager.base_path + file
	
	var save_dict: Dictionary = JSON.parse_string(IOHelper.file_load(file_path))
	var save_image: Image = Image.load_from_file(save_dict["screenshot_path"])
	var save_texture: ImageTexture = ImageTexture.create_from_image(save_image)
	
	var save_name = save_dict["name"].replace("_", " ")
	var datetime = save_dict["date_time"]
	var date = str(datetime["day"]) + "/" + str(datetime["month"]) + "/" + str(datetime["year"])
	var time = str(datetime["hour"]) + ":" + str(datetime["minute"]) + ":" + str(datetime["second"])
	# Set up the "details" of the save that will be shown on the save game shield.
	var details = (save_name + "\n" 
	+ date + "\n" 
	+ "Saved at: " + time)
	
	gotten_save.save_name = save_name
	gotten_save.details = details
	gotten_save.screenshot = save_texture
	gotten_save.json_path = file_path
	gotten_save.screenshot_path = save_dict["screenshot_path"]
	
	# Construct key string for the whole datetime for easy sorting
	var key_string = create_sort_string(datetime)
	
	var out_dict := {
		key_string: gotten_save
	}
	
	return out_dict


static func create_sort_string(datetime: Dictionary) -> String:
	
	# Need to ensure there's always leading 0's
	var second = datetime["second"]
	second = str(second) if (second > 9) else ("0" + str(second))
	
	var minute = datetime["minute"]
	minute = str(minute) if (minute > 9) else ("0" + str(minute))
	
	var hour = datetime["hour"]
	hour = str(hour) if (hour > 9) else ("0" + str(hour))
	
	var day = datetime["day"]
	day = str(day) if (day > 9) else ("0" + str(day))
	
	var month = datetime["month"]
	month = str(month) if (month > 9) else ("0" + str(month))
	
	var year = datetime["year"]
	year = str(year) if (year > 9) else ("0" + str(year))
	
	
	return year + month + day + hour + minute + second


func select_save(was_open_command: bool) -> void:
	if current_selection != null:
		current_selection.change_modulation(Color(0.0, 0.0, -1.0, 0.0))
	current_selection = get_viewport().gui_get_focus_owner()
	if current_selection != null:
		current_selection.change_modulation(Color(0.0, 0.0, 1.0, 0.0))
	
	if was_open_command:
		_handle_save()


func _handle_save() -> void:
	# In the base class, this overwrites the save that was chosen.
	var overwrite_save_name = current_selection.save_name
	delete_save()
	current_selection = null
	_on_save_button_pressed(overwrite_save_name, true)


func delete_save() -> void:
	IOHelper.file_delete(current_selection.json_path)
	IOHelper.file_delete(current_selection.screenshot_path)
	current_selection.queue_free()
	current_selection = null
	get_saves()
	Event.emit_signal("reload_main_menu")


static func sort_saves() -> Array:
	var sort_dict := {}
	var save_files = SerialisationManager.get_save_game_paths()
	
	for file in save_files:
		
		var dict_to_add = get_save(file)
		sort_dict.merge(dict_to_add, true)
	
	var key_strings = sort_dict.keys()
	
	# Sort in descending order, so latest saves are always at the top
	key_strings.sort_custom(func(a, b): return a > b)
	
	return [key_strings, sort_dict]


static func load_latest_save() -> void:
	
	var sorted = sort_saves()
	var key_strings = sorted[0]
	var sort_dict = sorted[1]
	
	SerialisationManager.load_from_save(sort_dict[key_strings[0]].json_path)


func _handle_confirm_choice(choice: bool) -> void:
	if choice:
		_handle_save()
