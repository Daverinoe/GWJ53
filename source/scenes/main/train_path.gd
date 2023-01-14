class_name TrainPath extends Node2D

# This class will provide methods to the train, generating a path

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

var tile_system: TileSystem
var line_segments: Dictionary = {}


func initialise_path_logic(tile_system_ref: TileSystem) -> void:
	var tile_world_pos: Vector2i
	var tile_atlas_vector: Vector2i
	var tile_points: Array
	
	# Called by parent, this injects a reference to the tilemap, and the logic
	# for connections of the hex tiles is done here
	
	tile_system = tile_system_ref
	
	# Create path segments for each tile present
	for tile in tile_system.get_used_cells(0):
		# For each tile, get the global position, and then add the matching points
		# based on the atlas vector
		var line_points: Array = []
		
		tile_world_pos = tile_system.map_to_local(tile)
		tile_atlas_vector = tile_system.get_cell_atlas_coords(0, tile)
		
		tile_points = ATLAS_MAP_LOOKUP[tile_atlas_vector]
		if len(tile_points) == 0:  # Do not make a line segment for empty/scenary tile
			continue
		
		line_points.append(tile_world_pos + HEX_RELATIVE_POS_MAPPING[tile_points[0]])
		line_points.append(tile_world_pos)
		line_points.append(tile_world_pos + HEX_RELATIVE_POS_MAPPING[tile_points[1]])

		line_segments[tile] = line_points
		
		
	for line_segment in line_segments:
		var new_line = Line2D.new()
		for line_point in line_segments[line_segment]:
			new_line.add_point(line_point)
		
		add_child(new_line)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
