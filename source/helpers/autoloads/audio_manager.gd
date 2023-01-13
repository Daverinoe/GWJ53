extends Node

var bus_list : Dictionary = {
	"master": 0,
	"music": 1,
	"effects": 2,
	"ambience": 3,
}


func _ready() -> void:
	randomize()


func set_volume(bus_name: String, value: float) -> void:
	var volume = linear_to_db(clamp(value, 0.0, 1.0))
	AudioServer.set_bus_volume_db(bus_list[bus_name], volume)

