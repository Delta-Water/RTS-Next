# 选择区域控制器，用于框选游戏中的单位
extends Area2D

@onready var region_shape: CollisionShape2D = $RegionShape
@onready var region_display: Polygon2D = $RegionDisplay

## 当选择区域可见时，多边形填充颜色的透明度(0-1范围)
@export_range(0, 1, 0.01) var visible_opacity: float = 0.34

# 信号：当单位进入区域时触发
signal unit_enter(UnitBase1)
# 信号：当单位离开区域时触发
signal unit_exit(UnitBase1)
# 信号：当区域重置时清除所有已记录单位
signal clear_units()

## 选择区域的起始点(设置时会重置区域)
var start_point: Vector2 = Vector2.ZERO :
	# 设置起始点的setter函数
	set(val):
		# 更新起始点值
		start_point = val
		# 同时重置结束点(触发end_point的setter)
		end_point = val
		# 发出清除单位信号
		clear_units.emit()

## 选择区域的结束点(设置时会更新区域形状)
var end_point: Vector2 = Vector2.ZERO :
	# 设置结束点的setter函数
	set(val):
		# 更新结束点值
		end_point = val
		# 计算区域中心位置(起始点和结束点的中点)
		global_position = (start_point + end_point) / 2.0
		
		# 计算矩形选择框的尺寸(取绝对值确保正值)
		var rect_size = (start_point - end_point).abs()
		# 更新内部矩形形状的尺寸
		_internal_shape.size = rect_size
		# 将更新后的形状应用到碰撞形状
		region_shape.shape = _internal_shape
		
		# 计算矩形的一半尺寸(用于顶点计算)
		var half_size = rect_size / 2.0
		# 更新显示多边形的顶点(按逆时针顺序)
		region_display.polygon = PackedVector2Array([
			Vector2(-half_size.x, -half_size.y),  # 左上角
			Vector2(half_size.x, -half_size.y),   # 右上角
			Vector2(half_size.x, half_size.y),    # 右下角
			Vector2(-half_size.x, half_size.y)    # 左下角
		])

# 内部使用的矩形碰撞形状
var _internal_shape: RectangleShape2D = RectangleShape2D.new()
# 透明度动画的补间对象引用
var _opacity_tween: Tween

func _ready() -> void:
	# 连接物体进入区域的信号
	body_entered.connect(func(node):
		if node is UnitBase1:
			var unit: UnitBase1 = node
			unit_enter.emit(unit)
	)
	
	# 连接物体离开区域的信号
	body_exited.connect(func(node):
		# 如果区域处于非监控状态，忽略离开事件
		if !monitoring:
			return
		if node is UnitBase1:
			var unit: UnitBase1 = node
			unit_exit.emit(unit)
	)

## 启用/禁用区域的选择功能
var enable: bool :
	# getter函数(直接返回enable值)
	get: return enable
	# setter函数
	set(val):
		# 更新启用状态
		enable = val
		# 同步更新区域监控状态
		monitoring = val
		
		# 根据启用状态决定目标透明度
		var target_opacity = 0.0
		# 如果启用则使用可见透明度
		if val:
			target_opacity = visible_opacity
		
		if _opacity_tween != null:
			_opacity_tween.kill()
		
		_opacity_tween = get_tree().create_tween()
		_opacity_tween.tween_property(region_display, "color:a", target_opacity, 0.2)
		_opacity_tween.tween_callback(func(): _opacity_tween = null)
