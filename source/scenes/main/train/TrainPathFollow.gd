extends PathFollow2D


var end_of_path_reached : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Event.connect("move_to_start_of_path", go_to_beginning_of_path)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if !end_of_path_reached:
		progress_ratio += VariableManager.train_speed * delta
		if progress_ratio == 1.0:
			Event.emit_signal("at_end_of_path")
			end_of_path_reached = true
	
	if end_of_path_reached and progress_ratio == 0:
		end_of_path_reached = false
	
	
	VariableManager.train_rotation = self.rotation_degrees


func go_to_beginning_of_path() -> void:
	progress_ratio = 0.0
	end_of_path_reached = false