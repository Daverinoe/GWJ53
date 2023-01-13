extends Node

signal set_ss_shader


func set_graphic(setting_name: String, value) -> void:
	match setting_name:
		"screen_resolution":
			change_resolution(value)
		"fullscreen":
			set_fullscreen(value)
		"colorblind":
			set_colorblind(value)
		"colorblind_intensity":
			set_colorblind_intensity(value)
		_:
			push_warning("Option doesn't exist.")
			pass

func change_resolution(value: String) -> void:
	var res_vals = value.split("x")
	var resolution = Vector2(str_to_var(res_vals[0]), str_to_var(res_vals[1]))
	DisplayServer.window_set_size(resolution)


func set_fullscreen(value: bool) -> void:
	if value:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func set_colorblind(_value: int) -> void:
	emit_signal("set_ss_shader")


func set_colorblind_intensity(_value: float) -> void:
	emit_signal("set_ss_shader")
