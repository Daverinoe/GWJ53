extends Node3D 
# An extension of the basic node-type to include
# some helper functions into each level.
# Change extended node to suit game.

class_name MainScene

var in_game_menu_open := false

func _input(event: InputEvent) -> void:
	GlobalRefs.active_scene = self
	if event.is_action_pressed("menu") and !in_game_menu_open:
		var menu_instance = GlobalRefs.in_game_menu_ref.instantiate()
		self.add_child(menu_instance)
		in_game_menu_open = true
		menu_instance.connect("tree_exited", reset_menu_open)


func reset_menu_open() -> void:
	in_game_menu_open = false
