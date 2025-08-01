class_name BuildingBase
extends StaticBody2D

enum State {
	Preview = 1,
	Building = 2,
	Ready = 3,
}

@export_enum("Preview:1", "Building:2", "Ready:3") var state: int = State.Building :
	set(val):
		if collision_polygon:
			var is_preview: bool = state == State.Preview
			if collision_polygon.disabled != is_preview:
				var tree = get_tree()
				if tree: tree.call_group("maps", "queue_bake")
			collision_polygon.disabled = is_preview
		state = val

@export_group("Build")
## 建造所需秒数
@export_range(0.0, 60.0, 1.0, "or_greater") var build_time: float = 5.0

## 正在建造的建造者数量
@export var builder_num: int = 0

## 当前建造进度，当超过 `build_time` 时视为建造完成。
@export_range(0.0, 60.0, 0.1) var current_build_time: float = 0.0

## 建造进度条边框颜色。
@export var progress_bar_border_color: Color = Color(0.6, 0.73, 0.92)
## 建造进度条填充颜色。
@export var progress_bar_fill_color: Color = Color(0.4, 0.54, 0.78)

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
@onready var display_container: Node2D = $DisplayContainer
@onready var progress_bar: Node2D = $ProgressBar

## 当前的建造进度，范围 [0,1]
var current_build_progress: float = 0.0 :
	get(): return clamp(current_build_time / build_time, 0.0, 1.0)
	set(val): current_build_time = clamp(build_time * val, 0.0, build_time)

func _ready() -> void:
	_update_rect(get_rect())
	collision_rect = collision_rect
	state = state

## 通过节点组`maps`调用地图管理器更新节点位置。
func _update_rect(old_rect: Rect2i) -> void:
	if is_node_ready():
		get_tree().call_group("maps", "update_building_rect", self, old_rect)

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

func _input(event: InputEvent) -> void:
	if event is InputEventKey && (event as InputEventKey).as_text_keycode() == "R" && (event as InputEventKey).is_pressed():
		#state = State.Preview if state == State.Ready else State.Ready
		state =  State.Building
		current_build_progress = 0.0

func _process(delta: float) -> void:
	# 调整显示层透明度
	var new_opacity: float = 0.4
	match state:
		State.Preview:
			pass
		State.Building:
			new_opacity += current_build_progress * 0.6
		State.Ready:
			new_opacity = 1.0
	display_container.modulate.a = new_opacity
	
	# 增加建造进度
	if state == State.Building:
		if current_build_time >= build_time:
			state = State.Ready
			queue_redraw()
		elif builder_num > 0:
			current_build_time += delta * builder_num
			queue_redraw()

func _draw() -> void:
	if state == State.Building:
		var global_size: Vector2 = display_container.position * 2.0
		var pbar_rect := Rect2(global_size.x * 0.1, global_size.y + 10.0, global_size.x * 0.8, 5.0)
		var pbar_fill_rect := pbar_rect
		pbar_fill_rect.size.x *= current_build_progress
		draw_rect(pbar_fill_rect, progress_bar_fill_color, true)
		draw_rect(pbar_rect, progress_bar_border_color, false, 1)
