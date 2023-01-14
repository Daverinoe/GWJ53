extends Node 

# enums
enum COLORBLIND_OPTIONS {
	NONE = 0, 
	PROTANOPIA, 
	DEUTRANOPIA, 
	TRITANOPIA,
	}

# Public signals

signal setting_changed(type, name, value)


# Private consts

const SETTINGS_PATH = "settings.json"

# Public variables
var resolutions : PackedStringArray = [
	"1024x768",
	"1280x800",
	"1280x720",
	"1280x1024",
	"1360x768",
	"1366x768",
	"1440x900",
	"1600x900",
	"1600x1050",
	"1920x1200",
	"1920x1080",
	"2560x1080",
	"2560x1600",
	"2560x1440",
	"3440x1440",
	"3840x2160",
]

# Private variables 

var settings: Dictionary = {}
var settings_default: Dictionary = {
	"audio": {
		"master": 0.8,
		"music": 0.7,
		"effects": 0.8,
		"ambience": 0.8,
	},
	"input": {
		"move_left": KEY_A,
		"move_right": KEY_D,
		"jump": KEY_SPACE,
		"glide": KEY_SPACE,
	},
	"graphics": {
		"screen_resolution": "1920x1080",
		"fullscreen": false,
		"colorblind": COLORBLIND_OPTIONS.NONE,
		"colorblind_intensity": 1.0,
	},
	"gameplay": {
	},
}


# Lifecycle methods

func _ready() -> void: 
	# The below line removes the title bar for some reason. 
	#DisplayServer.window_set_position(Vector2(0,0))
	settings_load()
	self.connect("setting_changed",Callable(self,"change_setting"))


# Public methods
func get_setting(setting_to_get, default = null):
	var path: Array = setting_to_get.split("/")
	var location: Dictionary = self.settings

	for index in range(path.size() - 1):
		var part: String = path[index]

		if location.has(part):
			location = location[part]
		else:
			return default

	var setting_name: String = path[path.size() - 1]
	if location.has(setting_name):
		return location.get(setting_name)
	else:
		return default


func set_setting(setting_to_set: String, value, _save: bool = false) -> void:	
	for key in settings.keys():
		if settings[key].has(setting_to_set):
			self.change_setting(key, setting_to_set, value)
			break


func change_setting(type: String, setting_name: String, value, _save: bool = false) -> void: 
	match type:
		"audio":
			AudioManager.set_volume(setting_name, value)
		"graphics":
			GraphicManager.set_graphic(setting_name, value)
		"effects":
			EffectManager.set_effect(setting_name, value)
		"input":
			InputManager.set_key(setting_name, value)
		_:
			pass
	
	settings[type][setting_name] = value
	settings_save()


func settings_load() -> void: 
	if IOHelper.file_exists(SETTINGS_PATH):
		var setting_string: String = IOHelper.file_load(SETTINGS_PATH)
		
		var test_json_conv = JSON.new()
		test_json_conv.parse(setting_string)
		settings = test_json_conv.get_data()
		
#		if merge_settings(settings_default, settings): 
#			settings_save()
		
	else:
		settings = settings_default
		
		settings_save()
	
	set_settings(settings)


func settings_save() -> void: 
	var setting_string: String = JSON.stringify(settings)
	
	var _worked = IOHelper.file_save(setting_string, SETTINGS_PATH)


# Private methods 

func merge_settings(a: Dictionary, b: Dictionary) -> bool: 
	var changed: bool = false
	
	for key in b: 
		if !a.has(key) || typeof(a[key]) != typeof(b[key]):
			a[key] = b[key]
			
			changed = true
		elif b[key] is Dictionary:
			changed = changed || merge_settings(a[key], b[key]) 
			
	return changed


func set_settings(settings_to_set: Dictionary, type: String = "") -> void:
	for key in settings_to_set.keys():
		var setting = settings_to_set[key]
		# Recursion! Yay! Nothing could possibly go wrong here!
		if typeof(setting) == TYPE_DICTIONARY:
			set_settings(setting, key)
		if type:
			change_setting(type, key, settings_to_set[key])

func get_settings() -> Dictionary:
	return settings
