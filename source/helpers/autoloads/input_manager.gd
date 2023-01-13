extends Node

class InputKey:
	var current: int
	var default: int
	var valid: bool

	func _init(default_inc: int,current_inc: int = KEY_UNKNOWN,valid_inc: bool = true):
		self.current = current_inc if current_inc != KEY_UNKNOWN else default_inc
		self.default = default_inc
		self.valid = valid_inc

	func get_key() -> int:
		return self.current if self.valid else self.default


var input: Dictionary = {
	# key: String, name of action
	# value: InputKey
}

var used_keys: Dictionary  = {
	# key: int, key code
	# value: String, name of action
}


# Lifecycle methods
func _ready() -> void:
	for action_name in self.input:
		self.input[action_name].valid = self.update_used_keys(
			action_name,
			self.input[action_name].current
		)

	var input_settings: Dictionary = SettingsManager.get_setting("input", {})
	for action_name in input_settings:
		if !(action_name in self.input):
			self.input[action_name] = {}
			self.input[action_name]["current"] = input_settings[action_name]
			self.input[action_name]["valid"] = self.update_used_keys(
				action_name,
				self.input[action_name].current
			)
		else:
			pass

	if input_settings.size() != self.input.size():
		SettingsManager.set_setting("input", self.input_serialize(), true)

	for action_name in self.input:
		self.update_action_binding(
			action_name,
			self.input[action_name]["current"]
		)


# Public methods

func get_key(action_name: String) -> int:
#	if !self.input.has(action_name):
#		return -1

	return self.input[action_name]["current"]


func is_used(key: int) -> bool:
	return self.used_keys.has(key)


func set_key(action_name: String, key: int) -> void:
	if !self.input.has(action_name):
		return

	var current_key: int = self.input[action_name].current
	if self.used_keys[current_key] == action_name:
		self.used_keys.erase(current_key)

	self.input[action_name].current = key
	self.input[action_name].valid = self.update_used_keys(
		action_name,
		self.input[action_name].current
	)

	self.update_action_binding(action_name, key)
	
#	var value = self.input_serialize()


# Private methods
func update_used_keys(action_name: String, key: int) -> bool:
	if !self.used_keys.has(key) || self.used_keys[key] == action_name:
		self.used_keys[key] = action_name
		return true

	return false


func update_action_binding(action_name: String, key: int) -> void:
	if !InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	InputMap.action_erase_events(action_name)

	var event: InputEventKey = InputEventKey.new()
	event.keycode = key

	InputMap.action_add_event(action_name, event)


func input_serialize() -> Dictionary:
	var data: Dictionary = {}

	for action_name in self.input:
		data[action_name] = self.input[action_name].current

	return data
