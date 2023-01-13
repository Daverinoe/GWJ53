extends Control

signal selected(was_open_command)

var screenshot: Texture
var details: String


@onready var screenshot_ref := $MarginContainer/Panel/MarginContainer/HBoxContainer/MarginContainer/SaveScreenshot
@onready var details_ref := $MarginContainer/Panel/MarginContainer/HBoxContainer/MarginContainer2/SaveDetails
@onready var panel_ref := $MarginContainer/Panel

var json_path: String
var screenshot_path: String
var save_name: String

func _ready() -> void:
	screenshot_ref.texture = screenshot
	details_ref.text = details


func _on_mouse_entered():
	self.grab_focus()


func _on_mouse_exited():
	pass


func _on_focus_entered():
	change_modulation(Color(0.5, 0.5, 0.5, 0))


func _on_focus_exited():
	change_modulation(Color(-0.5, -0.5, -0.5, 0))


func _on_gui_input(event: InputEvent) -> void:
	if (event.is_action_pressed("ui_accept")
	or (event is InputEventMouseButton and (event as InputEventMouseButton).double_click)):
		print(event)
		emit_signal("selected", true)
	if event.is_action_pressed("ui_select"):
		emit_signal("selected", false)


func change_modulation(colorChange: Color) -> void:
	panel_ref.self_modulate += colorChange
