class_name CustomButton extends Button


func _ready() -> void:
	self.connect("pressed", play_sound)


func play_sound() -> void:
	AudioManager.play_sound("ui_click")
