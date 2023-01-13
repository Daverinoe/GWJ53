extends Control


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		_on_back_pressed()


func _on_back_pressed() -> void:
	SettingsManager.settings_save()
	self.queue_free()
