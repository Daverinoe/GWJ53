extends AudioStreamPlayer2D

var min_db = -80
var max_db = 0

var max_pitch_scale = 4.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	var train = get_parent()
	self.pitch_scale = train.current_speed / train.max_speed * max_pitch_scale
