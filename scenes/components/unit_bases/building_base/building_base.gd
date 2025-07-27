class_name BuildingBase
extends StaticBody2D

@export_group("Size")
## 建筑的占地面积，只能使用整数坐标(单位为一个tile图格大小)。与碰撞体积无关。
@export var place_rect: Rect2i = Rect2i(0, 0, 4, 4) :
	set(val):
		var old_rect = get_rect()
		place_rect = val
		_update_rect(old_rect)
		
## 建筑的碰撞体大小及位置。
@export var collision_rect: Rect2 = Rect2(0.0, 0.0, 80.0, 80.0) :
	set(val_):
		var val: Rect2 = val_.abs()
		collision_rect = val
		if collision_polygon:
			collision_polygon.polygon = PackedVector2Array([
				val.position,
				val.position + Vector2(val.size.x, 0.0),
				val.position + val.size,
				val.position + Vector2(0.0, val.size.y),
			])

## 在TileMap中的位置。
@export var tile_position: Vector2i = Vector2i(0, 0) :
	set(val):
		var old_rect = get_rect()
		tile_position = val
		_update_rect(old_rect)

@onready var collision_polygon: CollisionPolygon2D = $CollisionPolygon

func _ready() -> void:
	_update_rect(get_rect())
	collision_rect = collision_rect

## 通过节点组`maps`调用地图管理器更新节点位置。
func _update_rect(old_rect: Rect2i) -> void:
	var tree = get_tree()
	if tree:
		tree.call_group("maps", "update_building_rect", self, old_rect)

func _exit_tree() -> void:
	# 清理Object占用，重构导航多边形。
	var tree: SceneTree = get_tree()
	tree.call_group("maps", "erase_building_rect", get_rect())
	tree.call_group("maps", "queue_bake")

## 获取建筑占用多边形
func get_rect() -> Rect2i:
	var r = place_rect
	r.position += tile_position
	return r
