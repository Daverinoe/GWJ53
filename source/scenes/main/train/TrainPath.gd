extends Path2D

var current_cell_position
@onready var path_follow : PathFollow2D = $TrainPathFollow

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Event.connect("curve_generated", set_new_curve)
	Event.connect("train_on_cell", set_new_position)


func set_new_position(new_position) -> void:
	current_cell_position = new_position
	self.global_position = new_position


func set_new_curve(new_curve : Curve2D) -> void:
	self.curve = new_curve
	path_follow.progress = 0
