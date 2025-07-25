extends Area2D

@onready var region_shape: CollisionShape2D = %RegionShape
@onready var region_display: Polygon2D = %RegionDisplay

## 当选择区域可见时，多边形填充颜色的透明度。
@export_range(0, 1, 0.01) var visible_opacity: float = 0.34

signal unit_enter(UnitBase1)
signal unit_exit(UnitBase1)
signal clear_units()

## 选择区域的起始点，更新该点会一并重设`end_point`和碰撞体积并触发`clear`信号。
var start_point: Vector2 = Vector2.ZERO :
	set(val):
		start_point = val
		end_point = val
		global_position = val
		
		# 重置碰撞区域
		_internal_shape.size = Vector2.ZERO
		region_shape.shape = _internal_shape
		
		# 重置显示区域
		region_display.polygon = PackedVector2Array()
		
		clear_units.emit()

## 选择区域的结束点，更新该点会重新计算碰撞体积。
var end_point: Vector2 = Vector2.ZERO :
	set(val):
		end_point = val
		global_position = (start_point + end_point) / 2.0
		
		# 重新计算碰撞区域
		_internal_shape.size = (start_point - end_point).abs()
		region_shape.shape = _internal_shape
		
		var half_size = _internal_shape.size / 2.0
		# 重新设置显示区域
		region_display.polygon = PackedVector2Array([
			half_size,
			half_size * Vector2(1.0, -1.0),
			half_size * Vector2(-1.0, -1.0),
			half_size * Vector2(-1.0, 1.0),
		])

var _internal_shape: RectangleShape2D = RectangleShape2D.new()

func _ready() -> void:
	body_entered.connect(func(node):
		var unit := node as UnitBase1
		if unit != null:
			unit_enter.emit(unit)
	)
	body_exited.connect(func(node):
		# 停止选择后保留已选择的单位
		if !monitoring:
			return
		var unit := node as UnitBase1
		if unit != null:
			unit_exit.emit(unit)
	)

var _opacity_tween: Tween

var enable: bool :
	get: return enable
	set(val):
		enable = val
		monitoring = val
		
		# 开始透明度动画
		var target_opacity = 0.0
		if val:
			target_opacity = visible_opacity
		
		# 结束先前的透明度动画
		if _opacity_tween != null:
			_opacity_tween.kill()
		_opacity_tween = get_tree().create_tween()
		_opacity_tween.tween_property(region_display, "color:a", target_opacity, 0.2)
		_opacity_tween.tween_callback(func(): _opacity_tween = null )
