extends RefCounted
class_name PathFinding

const ABILITY_LAND: int  = 0b0000_0001
const ABILITY_WATER: int = 0b0000_0010
const ABILITY_AIR: int   = 0b0000_0100
const ABILITY_CLIFF: int = 0b0000_1000

enum TerrainType {
	LAND = 1,
	WATER = 2,
	CLIFF = 3,
	LAVA = 4,
}

var backend: AStarGrid2D = AStarGrid2D.new()
var ability: int
var map_manager: RtsMapManager

static func ability_to_collision_mask(iability: int) -> int:
	if iability & PathFinding.ABILITY_AIR:
		return CollisionGroup.UNIT
	var mask = CollisionGroup.ALL ^ CollisionGroup.UNIT
	if iability & PathFinding.ABILITY_LAND:
		mask ^= CollisionGroup.TERRAIN_LAND
	if iability & PathFinding.ABILITY_WATER:
		mask ^= CollisionGroup.TERRAIN_WATER
	if iability & PathFinding.ABILITY_CLIFF:
		mask ^= CollisionGroup.TERRAIN_CLIFF
	return mask

func _init(map_manager_: RtsMapManager, init_ability: int):
	map_manager = map_manager_
	ability = init_ability

func sync_terrain_layer():
	var rect = map_manager.terrain_layer.get_used_rect()
	backend.region = rect
	backend.cell_size = map_manager.terrain_layer.tile_set.tile_size
	
	backend.default_compute_heuristic = AStarGrid2D.HEURISTIC_EUCLIDEAN
	backend.default_estimate_heuristic = AStarGrid2D.HEURISTIC_EUCLIDEAN
	backend.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	backend.jumping_enabled = true
	backend.update()
	
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			var coord = Vector2i(x, y)
			var tile_data = map_manager.terrain_layer.get_cell_tile_data(coord)
			if tile_data and tile_data.get_custom_data("TerrainType") != TerrainType.LAND:
				backend.set_point_solid(coord)

func query_path(from: Vector2i, to: Vector2i):
	return backend.get_id_path(from, to)

func query_global_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var terrain_layer = map_manager.terrain_layer
	var local_path = query_path(terrain_layer.local_to_map(from), terrain_layer.local_to_map(to))
	if local_path.is_empty():
		return [to]
	var global_path = PackedVector2Array()
	var first = true
	local_path.remove_at(local_path.size() - 1)
	for local_node in local_path:
		if first:
			first = false
			continue
		global_path.push_back(terrain_layer.map_to_local(local_node))
	global_path.push_back(to)
	return global_path

func clear():
	backend.clear()
