class_name TileSystem extends TileMap

@onready var active_tile_marker: Sprite2D = get_node("%active_tile_marker")
@onready var tile_select_marker: Sprite2D = get_node("%tile_select_marker")

enum HexPos {
	BORKED,
	TOP,
	BOTTOM,
	RIGHT_TOP,
	RIGHT_BOTTOM,
	LEFT_TOP,
	LEFT_BOTTOM
}

const BASE_TILE_LAYER: int = 0

# NOTE: Update this if hex tile change!
const HEX_RELATIVE_POS_MAPPING = {
	HexPos.BORKED: Vector2i(0, 0),
	HexPos.TOP: Vector2i(0, -128),
	HexPos.BOTTOM: Vector2i(0, 128),
	HexPos.RIGHT_TOP: Vector2i(144, -64),
	HexPos.RIGHT_BOTTOM: Vector2i(144, 64),
	HexPos.LEFT_TOP: Vector2i(-144, -64),
	HexPos.LEFT_BOTTOM: Vector2i(-144, 64),
}

# This is a map of the Atlas Map coords to the array of connection points (HexPos)
# Todo: Organise the tilemap such that this can be generated
const ATLAS_MAP_LOOKUP = {
	Vector2i(-1, -1): [HexPos.BORKED, HexPos.BORKED],
	Vector2i(0, 0): [HexPos.TOP, HexPos.BOTTOM],
	Vector2i(1, 0): [HexPos.TOP, HexPos.LEFT_BOTTOM],
	Vector2i(2, 0): [HexPos.TOP, HexPos.RIGHT_BOTTOM],
	Vector2i(3, 0): [HexPos.LEFT_TOP, HexPos.RIGHT_TOP],
	Vector2i(0, 1): [HexPos.BORKED, HexPos.BORKED],
	Vector2i(1, 1): [HexPos.LEFT_TOP, HexPos.BOTTOM],
	Vector2i(2, 1): [HexPos.RIGHT_TOP, HexPos.BOTTOM],
	Vector2i(3, 1): [HexPos.LEFT_BOTTOM, HexPos.RIGHT_BOTTOM],
	Vector2i(1, 2): [HexPos.LEFT_TOP, HexPos.RIGHT_BOTTOM],
	Vector2i(2, 2): [HexPos.LEFT_BOTTOM, HexPos.RIGHT_TOP],
	Vector2i(3, 2): [HexPos.LEFT_TOP, HexPos.LEFT_BOTTOM],
	Vector2i(4, 2): [HexPos.RIGHT_TOP, HexPos.RIGHT_BOTTOM],
}

var curr_mouse_position: Vector2i
var active_tile_map_coord: Vector2i  # This is the coord where the "cursor" is and moves with the mouse
var active_tile_world_coord: Vector2i
var selected_tile_map_coord: Vector2i  # This will be the tile that the player has selected. Can be null
var selected_tile_world_coord: Vector2i = Vector2i.ZERO

# TODO: Handle the above with a selected flag, rather than a shitty placeholder vector
var tile_selected: bool = false
var active_atlas_map: int = 0


func _ready():
	tile_select_marker.hide()
	Event.connect("generate_hex_path", generate_hex_path)


func _process(delta):
	# Find active tile (i.e. cursor)
	curr_mouse_position = to_local(get_global_mouse_position())
	active_tile_map_coord = local_to_map(curr_mouse_position)
	active_tile_world_coord = map_to_local(active_tile_map_coord)  # This will make it a grid
	active_tile_marker.global_position = active_tile_world_coord


func _input(event) -> void:
	if event.is_action_pressed("tile_select"):
#		if not local_to_map(active_tile_world_coord) in get_used_cells(BASE_TILE_LAYER):
#			print("TILE NOT EXIST")
#			# TODO: FIX THIS SUCH AS TO NOT BLOCK ALL TILE MOVEMENT
#			return  # TODO: Update this if further unhandled input is required
#
		# Update tile if appropriate
		if not tile_selected:
			tile_selected = true
			selected_tile_world_coord = active_tile_world_coord
			selected_tile_map_coord = local_to_map(selected_tile_world_coord)
			tile_select_marker.global_position = selected_tile_world_coord
			tile_select_marker.show()
			if is_obstacle(selected_tile_map_coord):
				tile_select_marker.modulate = Color(1.0, 0.0, 0.0, 1.0)
		else:
			# Find the new selection and switch them
			_switch_tiles(selected_tile_map_coord, active_tile_map_coord)
			tile_select_marker.hide()
			tile_select_marker.modulate = Color(1.0, 0.77, 1.0, 1.0)
			
	elif event.is_action_pressed("tile_deselect"):
		tile_deselect()


func _switch_tiles(map_tile_coord_1: Vector2i, map_tile_coord_2: Vector2i) -> void:
	# Check for obstacles on layer 1 of the tileset. If they exist, don't swap.
	if is_obstacle(map_tile_coord_1) or is_obstacle(map_tile_coord_2):
		tile_deselect()
		return
	
	var tile_source_1: Vector2i = get_cell_atlas_coords(BASE_TILE_LAYER, map_tile_coord_1)
	var tile_source_2: Vector2i = get_cell_atlas_coords(BASE_TILE_LAYER, map_tile_coord_2)
	
	set_cell(BASE_TILE_LAYER, map_tile_coord_1, active_atlas_map, tile_source_2)
	set_cell(BASE_TILE_LAYER, map_tile_coord_2, active_atlas_map, tile_source_1)
	tile_deselect()
	
	
func get_vectors(world_coord: Vector2i) -> Array[Vector2i]:
	return [Vector2i.ZERO]


func tile_deselect() -> void:
	# TODO: Handle logic if a tile has been "picked up"
	tile_selected = false
	tile_select_marker.hide()
	tile_select_marker.self_modulate = Color(1.0, 0.77, 0.0, 1.0)


func is_obstacle(map_tile_coord) -> bool:
	# TODO: This raises an error in the debugger - need to fix the logic so we aren't checking null but instead reading what layer is active
	var obstacle_check: TileData = get_cell_tile_data(1, map_tile_coord)
	return true if obstacle_check != null else false


func generate_hex_path(hex_coords) -> void:
	print("Current hex coords: %s" % hex_coords)
	
	if is_obstacle(hex_coords):
		Event.emit_signal("curve_generated", null)
	
	var atlas_cell : Vector2i = get_cell_atlas_coords(BASE_TILE_LAYER, hex_coords)
	var mapping : Array = ATLAS_MAP_LOOKUP[atlas_cell]
	
	var new_curve : Curve2D = Curve2D.new()
	
	# All paths will have 3 points at the moment
	# TODO: Generalise for multi-path tiles
	new_curve.add_point(HEX_RELATIVE_POS_MAPPING[mapping[0]])
	new_curve.add_point(Vector2.ZERO)
	new_curve.add_point(HEX_RELATIVE_POS_MAPPING[mapping[1]])
	
	Event.emit_signal("curve_generated", new_curve)
