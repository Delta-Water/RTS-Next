extends Node2D

# 导出单位类型（以后最好通过代码实现加载到树）
@export var combat_engineer: PackedScene

var selected_units: Array = []

func _input(event):
	# 监听单位移动事件
	# 监听单位选择事件
	pass

# 生成单位
# func spawn_unit(type: String, position: Vector2) -> UnitBase1:
func spawn_unit(type: String, position: Vector2):
	pass

# 单位选择逻辑
func _select_units():
	pass
