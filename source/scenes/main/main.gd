extends MainScene


func _ready() -> void:
	SerialisationManager.add_to_persist(self)
	GlobalRefs.level_ref = self


func _process(delta: float) -> void:
	$WorldEnvironment.environment.sky_rotation.y += 0.5 * delta


func save() -> Dictionary:
	return {
		name: {
			"sky_rotation": $WorldEnvironment.environment.sky_rotation.y
		}
	}


func load_data(incoming_data: Dictionary) -> void:
	$WorldEnvironment.environment.sky_rotation.y = incoming_data["sky_rotation"]
