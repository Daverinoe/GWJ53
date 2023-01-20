class_name TileSystem extends TileMap

@export var valid_placement_indicator_scene: PackedScene

@onready var active_tile_marker: Sprite2D = get_node("%active_tile_marker")
@onready var tile_select_marker: Sprite2D = get_node("%tile_select_marker")

@onready var ghost_selection: Node2D = get_node("%ghost_selection")
@onready var ghost_selection_animator: AnimationPlayer = get_node("%ghost_selection_animator")
@onready var ghost_selection_sprite: Sprite2D = get_node("%ghost_selection_sprite")
@onready var valid_placement: Node2D = get_node("%valid_placements")

var train: Train  # Reference to player train for active blob
var current_train_map_coord: Vector2i

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

var tile_selected: bool = false
var active_atlas_map: int = 0

@onready var full_atlas_texture: Texture = tile_set.get_source(0).texture

@onready var selected_tile = TilePack.new()
@onready var swapped_tile = TilePack.new()

var available_tiles: Array = []


func _ready():
	tile_select_marker.hide()
	
	ghost_selection_sprite.texture = full_atlas_texture
	ghost_selection_sprite.region_enabled = true
	ghost_selection.hide()


func _process(delta):
	# Find active tile (i.e. cursor)
	curr_mouse_position = get_global_mouse_position()
	active_tile_map_coord = local_to_map(curr_mouse_position)
	active_tile_world_coord = map_to_local(active_tile_map_coord)  # This will make it a grid
	active_tile_marker.global_position = active_tile_world_coord


func _physics_process(delta):
	# Find tile that train reference is currently on
	current_train_map_coord = local_to_map(train.global_position)


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
			selected_tile.world_coordinate = active_tile_world_coord
			selected_tile.map_coordinate = local_to_map(selected_tile.world_coordinate)
			selected_tile.atlas_region = get_tile_rect(selected_tile)
			
			tile_select_marker.global_position = selected_tile.world_coordinate
			tile_select_marker.show()
			
			ghost_selection.global_position = selected_tile.world_coordinate
			ghost_selection.show()
			ghost_selection_animator.play("pickup")
			set_cell(BASE_TILE_LAYER, selected_tile.map_coordinate, -1)  # Remove from map
			
			# Now a tile is raised up and ready to place, determine the current available tiles 
			_get_possible_tiles()
			
			for available_tile in available_tiles:
				var valid_placement_indicator = valid_placement_indicator_scene.instantiate()
				valid_placement_indicator.position = map_to_local(available_tile)
				valid_placement.add_child(valid_placement_indicator)
			
			
#			if is_obstacle(selected_tile_map_coord):
#				tile_select_marker.modulate = Color(1.0, 0.0, 0.0, 1.0)
		else:
			# Check if this tile could be placed.
#			_switch_tiles(selected_tile_map_coord, active_tile_map_coord)
			tile_select_marker.hide()
			tile_select_marker.modulate = Color(1.0, 0.77, 1.0, 1.0)
			
	elif event.is_action_pressed("tile_deselect"):
		tile_deselect()


func _get_possible_tiles() -> void:
	# Flood fill out to get all tiles
	available_tiles = []
	var explored = []
	var queue = [current_train_map_coord]
	
	var curr_node: Vector2i
	var curr_neighbours: Array[Vector2i]
	
	var loops := 0
	
	while queue.size() > 0 and loops < 50:
		loops += 1
		curr_node = queue.pop_front()
		explored.append(curr_node)
		if get_cell_atlas_coords(BASE_TILE_LAYER, curr_node) != Vector2i(-1, -1) or is_obstacle(curr_node):
			available_tiles.append(curr_node)

		curr_neighbours = get_surrounding_cells(curr_node)

		for neighbour in curr_neighbours:
			if not (neighbour in queue) or not (neighbour in available_tiles):
				# Not already going to check it, next check
				queue.append(neighbour)
				
	print(loops)


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


func get_tile_rect(tile_pack: TilePack) -> Rect2:
	var base_pos = tile_set.tile_size * (tile_pack.map_coordinate + Vector2i.ONE)
	return Rect2(base_pos[0], base_pos[1], tile_set.tile_size[0], tile_set.tile_size[1])


#func set_ghost_selection(tile_coord: Vector2i, tile_global_coord: Vector2) -> void:
#	var base_pos = tile_set.tile_size * (tile_coord + Vector2i.ONE)
#	var tile_rect: Rect2 = Rect2(base_pos[0], base_pos[1], tile_set.tile_size[0], tile_set.tile_size[1])
#	ghost_selection.region_rect = tile_rect
#	ghost_selection.global_position = tile_global_coord
#	ghost_selection.show()
	
