class_name TileSystem extends TileMap

@onready var active_tile_marker: Sprite2D = get_node("%active_tile_marker")
@onready var tile_select_marker: Sprite2D = get_node("%tile_select_marker")

@onready var ghost_selection: Sprite2D = get_node("%ghost_selection")
@onready var valid_placement: Node2D = get_node("%valid_placements")

var train: Train  # Reference to player train for active blob

enum HexPos {
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
	HexPos.TOP: Vector2i(0, -128),
	HexPos.BOTTOM: Vector2i(0, 128),
	HexPos.RIGHT_TOP: Vector2i(144, -64),
	HexPos.RIGHT_BOTTOM: Vector2i(144, 64),
	HexPos.LEFT_TOP: Vector2i(-144, -64),
	HexPos.LEFT_BOTTOM: Vector2i(-144, 64),
}
# This script will work so well I already know it - hype

# This is a map of the Atlas Map coords to the array of connection points (HexPos)
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
var selected_tile_world_coord: Vector2i = Vector2i.ZERO

# TODO: Handle the above with a selected flag, rather than a shitty placeholder vector
var tile_selected: bool = false
var active_atlas_map: int = 0
var full_atlas_texture: Texture


func _ready():
	tile_select_marker.hide()
	full_atlas_texture = tile_set.get_source(0).texture
	ghost_selection.texture = full_atlas_texture
	ghost_selection.region_enabled = true
	ghost_selection.hide()


func _process(delta):
	# Find active tile (i.e. cursor)
	curr_mouse_position = get_global_mouse_position()
	active_tile_map_coord = local_to_map(curr_mouse_position)
	active_tile_world_coord = map_to_local(active_tile_map_coord)  # This will make it a grid
	active_tile_marker.global_position = active_tile_world_coord


func _unhandled_input(event) -> void:
	"""Handle the tile system interaction
	
	First:
		Check if tile is selectable. 
			Selectable means not blocked by a train carriage OR not obstacle layer
		if not selectable, raise signal and flash cursor
		
	Next: tile is selectable
		Grab tile texture and add to ghost_selection node. Raise ghost select mode from board
		Spawn available spots to place tile outside blob (also accept swaps)
		
	If player right clicks OR attempts placement on invalid tile
		return tile to tilemap. Hide ghost_selection
	
	If player places tile
		if target tile is populated, animate a tile switch, else animate tile placement
			move ghost_selection - on finish, update tilemap
	"""
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
			
			# +++++++++++++++++++++++
			set_ghost_selection(selected_tile_map_coord, selected_tile_world_coord)
			# +++++++++++++++++++++++
			
			if is_obstacle(selected_tile_map_coord):
				tile_select_marker.modulate = Color(1.0, 0.0, 0.0, 1.0)
		else:
			# Find the new selection and switch them
			_switch_tiles(selected_tile_map_coord, active_tile_map_coord)
			tile_select_marker.hide()
			tile_select_marker.modulate = Color(1.0, 0.77, 1.0, 1.0)
			
	elif event.is_action_pressed("tile_deselect"):
		tile_deselect()


func initialise_tile_system(train_ref: Train) -> void:
	train = train_ref


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


func set_ghost_selection(tile_coord: Vector2i, tile_global_coord: Vector2) -> void:
	var base_pos = tile_set.tile_size * (tile_coord + Vector2i.ONE)
	var tile_rect: Rect2 = Rect2(base_pos[0], base_pos[1], tile_set.tile_size[0], tile_set.tile_size[1])
	ghost_selection.region_rect = tile_rect
	ghost_selection.global_position = tile_global_coord
	ghost_selection.show()
	
