extends Control
var rotation_scale = 0.6 # wooo magic number!
var new_value: float
var min_multiplier = 1
var max_multiplier = 3
var temp_val
# This object should only ever "multiply" the current trains speed. 
# That way we can avoid having to get references to max/min speeds ect

func calculate_speed_multiplier(minimum_multiplier, maximum_multiplier, slider_value):
	# This math is to get our number range from -1, 1 to 1,3
	# Thanks ChatGPT
	return(slider_value + 1) * ((maximum_multiplier - minimum_multiplier)/2) + minimum_multiplier
	

func _ready():
	temp_val = $SpeedController/HiddenSpeedSlider.value
	$SpeedController/TextureProgressBar/SpeedKnobTexture.rotation = temp_val * rotation_scale
	Event.emit_signal("update_train_speed_multiplier", calculate_speed_multiplier(min_multiplier, max_multiplier, temp_val))
	
func _on_hidden_speed_slider_value_changed(value):
	$SpeedController/TextureProgressBar/SpeedKnobTexture.rotation = (value) * rotation_scale
	Event.emit_signal("update_train_speed_multiplier", calculate_speed_multiplier(min_multiplier, max_multiplier, value))

