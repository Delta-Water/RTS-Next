class_name Maps
extends Node2D

@onready var ground: TileMapLayer = $Ground
@onready var navigation_regions: Node2D = $NavigationRegions

## collision_mask和navigation_layer的映射表
var layers_table: Dictionary[int, NavigationRegion2D] = {}

func request_navigation_layer_for_mask(collision_mask: int) -> RID:
	if layers_table.has(collision_mask):
		var t_region := layers_table[collision_mask]
		if !t_region:
			push_error("Expected 'NavigationAgent2D', removing the object that has an incorrect type")
			layers_table.erase(collision_mask)
		else:
			return t_region.get_navigation_map()
	
	var nav_map = NavigationServer2D.map_create()
	
	var rect: Rect2i = ground.get_used_rect().abs()
	var tile_size: Vector2 = ground.tile_set.tile_size
	var gposition: Vector2 = Vector2(rect.position) * tile_size
	var gsize: Vector2 = Vector2(rect.size) * tile_size
	var outline = PackedVector2Array([
		gposition,
		gposition + Vector2(gsize.x, 0),
		gposition + gsize,
		gposition +  Vector2(0, gsize.y),
	])
	var polygon := NavigationPolygon.new()
	polygon.add_outline(outline)
	polygon.agent_radius = 9
	polygon.parsed_geometry_type = NavigationPolygon.PARSED_GEOMETRY_STATIC_COLLIDERS
	polygon.parsed_collision_mask = 0b11110000 ^ ~collision_mask & 0xfffffff0
	polygon.source_geometry_mode = NavigationPolygon.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	polygon.source_geometry_group_name = "npsgg_test"
	
	NavigationServer2D.map_set_cell_size(nav_map, polygon.cell_size)
	NavigationServer2D.bake_from_source_geometry_data(polygon, NavigationMeshSourceGeometryData2D.new())
	
	var region := NavigationRegion2D.new()
	region.set_navigation_map(nav_map)
	region.navigation_polygon = polygon
	region.navigation_layers = 1
	region.use_edge_connections = false
	NavigationServer2D.map_set_active(nav_map, true)
	
	layers_table.set(collision_mask, region)
	get_tree().create_timer(1.0).timeout.connect(func():
		region.bake_navigation_polygon(false)
	)
	
	region.name = "Region_%x" % collision_mask
	navigation_regions.add_child(region)
	layers_table.set(collision_mask, region)
	
	return nav_map
	
