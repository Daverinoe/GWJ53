extends SaveMenu

@onready var delete_button_ref := $Panel/VBoxContainer/HBoxContainer/MarginContainer3/DeleteButton
@onready var load_button_ref := $Panel/VBoxContainer/HBoxContainer/MarginContainer2/LoadButton

func _process(delta: float) -> void:
	if current_selection != null:
		delete_button_ref.disabled = false
		load_button_ref.disabled = false
	else:
		delete_button_ref.disabled = true
		load_button_ref.disabled = true


func _on_load_button_pressed():
	SerialisationManager.load_from_save(current_selection.json_path)


# Overwrite _handle_save() function to load instead of save
func _handle_save() -> void:
	_on_load_button_pressed()


func _on_delete_button_pressed() -> void:
	confirm_dialog.visible = true


func _handle_confirm_choice(choice: bool) -> void:
	if choice:
		delete_save()
