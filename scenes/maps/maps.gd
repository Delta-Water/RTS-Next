extends Node2D

@onready var object_layer: TileMapLayer = $Object
@onready var navigation_region: NavigationRegion2D = $NavigationRegion2D

var navigation_region_need_bake: bool = false

# 用于管理Object层的函数

func erase_building_rect(rect: Rect2i) -> void:
	var r := rect.abs()
	for x in range(r.size.x):
		for y in range(r.size.y):
			object_layer.erase_cell(r.position + Vector2i(x, y))

func update_building_position(building: BuildingBase) -> void:
	building.global_position = object_layer.to_global(object_layer.map_to_local(building.tile_position)) - Vector2(object_layer.tile_set.tile_size) / 2.0
	building.display_container.position = object_layer.to_global(object_layer.tile_set.tile_size * building.place_rect.size) / 2.0
	queue_bake()

func fill_building_rect(old_rect: Rect2i) -> void:
	var src_id := object_layer.tile_set.get_source_id(0)
	var r := old_rect.abs()
	for x in range(r.size.x):
		for y in range(r.size.y):
			object_layer.set_cell(r.position + Vector2i(x, y), src_id, Vector2i(0, 0))

func update_building_rect(building: BuildingBase, old_rect: Rect2i) -> void:
	erase_building_rect(old_rect)
	update_building_position(building)
	fill_building_rect(building.get_rect())

# ------------

## 使导航多边形在帧末尾刷新。多次调用只会刷新一次。
func queue_bake() -> void:
	navigation_region_need_bake = true

func _process(_delta: float) -> void:
	_frame_end_callback.call_deferred()

func _frame_end_callback() -> void:
	if navigation_region_need_bake && !navigation_region.is_baking():
		navigation_region.bake_navigation_polygon()
		navigation_region_need_bake = false
