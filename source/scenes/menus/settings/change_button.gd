class_name ChangeButton extends CustomButton


# Public variables

@export var binding: String


# Private methods

var current: int = 0
var listening: bool = false


# Lifecycle methods

func _ready() -> void:
	self.custom_minimum_size.x = 75
	self.current = InputManager.get_key(self.binding)
	self.update_text()

	self.connect("focus_exited",Callable(self,"focus_exited"))
	self.connect("pressed",Callable(self,"pressed"))


func _input(event: InputEvent) -> void:
	if self.listening && event is InputEventKey && event.pressed:
		self.update_text_color(Color.WHITE)

		var incoming: int = event.physical_keycode

		if incoming == self.current:
			self.get_viewport().set_input_as_handled()
			self.listening = false
			self.update_text()
			return

		if InputManager.is_used(incoming):
			self.get_viewport().set_input_as_handled()
			self.update_text_color(Color("#b1385c"))
			self.update_text(incoming)
			return

		SettingsManager.set_setting(self.binding, incoming)

		self.current = incoming
		self.listening = false
		self.update_text()
		self.get_viewport().set_input_as_handled()


# Private methods

func focus_exited() -> void:
	self.listening = false
	self.update_text()
	self.update_text_color(Color.WHITE)


func pressed() -> void:
	self.listening = true
	self.text = "..."


func update_text(override: int = -1) -> void:
	var value: int = self.current

	if override != -1:
		value = override

	self.text = OS.get_keycode_string(value)

func update_text_color(color: Color) -> void:
	self.add_theme_color_override("font_color", color)
	self.add_theme_color_override("font_color_focus", color)
	self.add_theme_color_override("font_color_hover", color)
