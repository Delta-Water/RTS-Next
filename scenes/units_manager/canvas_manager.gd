extends Node2D

const SELECTED_HIGHLIGHT_CIRCLE = preload("res://scenes/components/canvas_items/selected_highlight/SelectedHighlight.tscn")
const LINES_TO_TARGET = preload("res://scenes/components/canvas_items/lines_to_target/lines_to_target.tscn")

# 存储单位与其对应画布的映射
var unit_canvas = {}

func _physics_process(delta: float) -> void:
	update_canvas()

# 为指定单位创建画布
func create_canvas_for_unit(unit: UnitBase1):
	# 创建新画布
	var circle = SELECTED_HIGHLIGHT_CIRCLE.instantiate()
	var lines = LINES_TO_TARGET.instantiate()
	circle.unit_position = unit.position
	circle.radius = unit.display_radius
	lines.unit_position = unit.position
	lines.target_position = unit.position if unit.current_state == unit.State.IDLE else unit.target_position
	# 添加到场景
	var canvas = [circle, lines]
	for canva in canvas:
		add_child(canva)
	
	# 存储映射关系
	unit_canvas[unit] = canvas
	
	# 连接单位的删除信号
	#if not unit.is_connected("tree_exiting", self, "_on_unit_exiting"):
		#unit.connect("tree_exiting", self, "_on_unit_exiting", [unit])

# 移除单位的画布
func remove_canvas_for_unit(unit: UnitBase1):
	if unit_canvas.has(unit):
		var canvas = unit_canvas[unit]
		for canva in canvas:
			canva.queue_free()
		unit_canvas.erase(unit)

# 更新所有画布
func update_canvas():
	for unit in unit_canvas:
		var canvas = unit_canvas[unit]
		canvas[0].unit_position = unit.position
		canvas[0].set_selected_state(unit.is_selected)
		canvas[1].unit_position = unit.position
		canvas[1].target_position = unit.position if unit.current_state == unit.State.IDLE else unit.target_position
		canvas[1].set_selected_state(unit.is_selected)
		#for canva in canvas:
			#if is_instance_valid(unit) and unit.target_position != Vector2.ZERO:
				## 设置线条起点（单位当前位置）和终点（目标位置）
				#canva.points = [unit.global_position, unit.target_position]

# 单位被删除时的处理
func _on_unit_exiting(unit: UnitBase1):
	remove_canvas_for_unit(unit)
