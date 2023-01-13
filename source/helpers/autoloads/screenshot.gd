extends Node

# Private constants

const OUTPUT_DIRECTORY: String = "screenshots"
const OUTPUT_FILE_NAME: String = "%04d_%02d_%02d_%02dh%02dm%02ds.png"


# Private variables

var activate_prev: bool = false
var activate_curr: bool = true


# Lifecycle methods

func _ready() -> void:
	IOHelper.directory_create(OUTPUT_DIRECTORY)

	self.process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	# TODO: Update to input action

	activate_prev = activate_curr
	activate_curr = Input.is_key_pressed(KEY_S)

	var pressed = !activate_prev && activate_curr

	if Input.is_key_pressed(KEY_CTRL) && Input.is_key_pressed(KEY_SHIFT) && pressed:
		self.screenshot()


# Private methods

func screenshot() -> String:
	await RenderingServer.frame_post_draw
	var capture: Image = self.get_viewport().get_texture().get_image()
	
	var datetime: Dictionary = Time.get_datetime_dict_from_system(true)
	var file_name: String = OUTPUT_FILE_NAME % [
		datetime["year"],
		datetime["month"],
		datetime["day"],
		datetime["hour"],
		datetime["minute"],
		datetime["second"],
	]
	
	var save_path: String = "user://%s/%s" % [OUTPUT_DIRECTORY, file_name]
	var capture_result: int = capture.save_png(save_path)
	if capture_result != OK:
		
		return "" # TODO: Call logger
	
	return save_path
