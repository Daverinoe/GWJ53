class_name GhostPlacement extends Sprite2D

@onready var transparency_animator: AnimationPlayer = get_node("%transparency_animator")

func _ready() -> void:
	transparency_animator.seek(randf())
	transparency_animator.play()
