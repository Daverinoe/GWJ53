extends Node

var base_path := "savegames/"

func _ready() -> void:
	if not IOHelper.directory_exists(base_path):
		IOHelper.directory_create(base_path)

func load_from_save(save_path: String) -> void:
	# Load dictionary from file
	var load_json = IOHelper.file_load(save_path)
	
	# Emit scene switch signal 
	SceneManager.emit_signal("load_save_from_file", GlobalRefs.active_scene, "", true, JSON.parse_string(load_json))



func save(save_name: String, override_file: bool = false, override_path: String = "") -> String:
	
	# Get the level reference, then loop through serialisable nodes
	# constructing the dictionary in a simily of the tree structure
	var save_json: Dictionary = await construct_save_json(save_name)
	
	var save_string := JSON.stringify(save_json)
	
	var file_path := base_path + save_name + ".save"
	
	if override_file:
		file_path = override_path
	
	# Write to file
	IOHelper.file_save(save_string, file_path)
	
	return file_path


func construct_save_json(save_name: String) -> Dictionary:
	# Take a screenshot to use in the file preview
	GlobalRefs.active_menu.visible = false
	var screenshot_path: String = await Screenshot.screenshot()
	GlobalRefs.active_menu.visible = true
	
	# Get nodes to save
	var persist_nodes = get_tree().get_nodes_in_group("Persist")
	
	var export_dict := {
		"active_scene": GlobalRefs.level_ref.scene_file_path
	}
	
	for save_node in persist_nodes:
		if save_node.has_method("save"):
			export_dict[save_node.name] = save_node.save()
	
	
	# Add screenshot path, and some metadata
	export_dict["screenshot_path"] = screenshot_path
	export_dict["date_time"] = Time.get_datetime_dict_from_system(true)
	export_dict["name"] = save_name
	
	return export_dict


func get_save_game_paths() -> PackedStringArray:
	return IOHelper.directory_list_files(base_path)


func add_to_persist(node_to_add) -> void:
	node_to_add.add_to_group("Persist")


func do_saves_exist() -> bool:
	if get_save_game_paths().size() > 0:
		return true
	
	return false
