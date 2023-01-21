extends AudioStreamPlayer2D

var max_db = 5

var max_pitch_scale = 4.0
var min_pitch_scale = 0.1

@onready var train = get_parent()

func _ready() -> void:
	randomize()
	Event.connect("zoom_level_changed", set_chugga_volume)
	await get_tree().create_timer(randf_range(1e-3, 1e-1))
	self.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	self.pitch_scale = clamp(train.current_speed / train.max_speed * max_pitch_scale, 0.01, 4.0)

func set_chugga_volume(zoom_level) -> void:
	self.volume_db = linear_to_db(zoom_level/VariableManager.max_zoom_level) + max_db
