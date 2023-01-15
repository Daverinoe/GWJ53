class_name TileSystem extends TileMap

@onready var active_tile_marker: Sprite2D = get_node("%active_tile_marker")
@onready var tile_select_marker: Sprite2D = get_node("%tile_select_marker")

enum HexPos {
	TOP,
	BOTTOM,
	RIGHT_TOP,
	RIGHT_BOTTOM,
	LEFT_TOP,
	LEFT_BOTTOM
}

# NOTE: Update this if hex tile change!
const HEX_RELATIVE_POS_MAPPING = {
	HexPos.TOP: Vector2i(0, -32),
	HexPos.BOTTOM: Vector2i(0, 32),
	HexPos.RIGHT_TOP: Vector2i(36, -16),
	HexPos.RIGHT_BOTTOM: Vector2i(36, 16),
	HexPos.LEFT_TOP: Vector2i(-36, -16),
	HexPos.LEFT_BOTTOM: Vector2i(-36, 16),
}

# This is a map of the Atlas Map coords to the array of connection points (HexPos)
# Todo: Organise the tilemap such that this can be generated
const ATLAS_MAP_LOOKUP = {
	Vector2i(0, 0): [HexPos.TOP, HexPos.BOTTOM],
	Vector2i(1, 0): [HexPos.TOP, HexPos.LEFT_BOTTOM],
	Vector2i(2, 0): [HexPos.TOP, HexPos.RIGHT_BOTTOM],
	Vector2i(3, 0): [HexPos.LEFT_TOP, HexPos.RIGHT_TOP],
	Vector2i(0, 1): [],
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
var selected_tile_world_coord: Vector2i = Vector2i(-999, -999)
# TODO: Handle the above with a selected flag, rather than a shitty placeholder vector
var active_atlas_map: int = 0


func _ready():
	tile_select_marker.hide()


func _process(delta):
	# Find active tile (i.e. cursor)
	curr_mouse_position = get_global_mouse_position()
	active_tile_map_coord = local_to_map(curr_mouse_position)
	active_tile_world_coord = map_to_local(active_tile_map_coord)  # This will make it a grid
	active_tile_marker.global_position = active_tile_world_coord


func _unhandled_input(event) -> void:
	if event.is_action_pressed("tile_select"):
		# Update tile if appropriate
		if selected_tile_world_coord == Vector2i(-999, -999):
			selected_tile_world_coord = active_tile_world_coord
			selected_tile_map_coord = local_to_map(selected_tile_world_coord)
			tile_select_marker.global_position = selected_tile_world_coord
			tile_select_marker.show()
		else:
			# Find the new selection and switch them
			_switch_tiles(selected_tile_map_coord, active_tile_map_coord)
			tile_select_marker.hide()
			selected_tile_world_coord = Vector2i(-999, -999)
			
	elif event.is_action_pressed("tile_deselect"):
		tile_select_marker.hide()
		selected_tile_world_coord = Vector2i(-999, -999)


func _switch_tiles(map_tile_coord_1: Vector2i, map_tile_coord_2: Vector2i) -> void:
	var tile_source_1: Vector2i = get_cell_atlas_coords(0, map_tile_coord_1)
	var tile_source_2: Vector2i = get_cell_atlas_coords(0, map_tile_coord_2)
	
	set_cell(0, map_tile_coord_1, active_atlas_map, tile_source_2)
	set_cell(0, map_tile_coord_2, active_atlas_map, tile_source_1)
	
	
func get_vectors(world_coord: Vector2i) -> Array[Vector2i]:
	return [Vector2i.ZERO]
