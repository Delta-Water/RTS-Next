class_name Units
extends Node2D

## 单位仓库。用于注册单位用于动态生成。
var registry: Dictionary[String, PackedScene] = {
	"rts:combat_engineer" = preload("res://scenes/units/combat_engineer/combat_engineer.tscn"),
}

var selected_units: Array = []

func _input(event):
	# 监听单位移动事件
	# 监听单位选择事件
	pass

## 生成单位
func spawn_unit(type: String, unit_position: Vector2) -> UnitBase:
	var scene: PackedScene = registry.get(type)
	var node: UnitBase = scene.instantiate()
	node.position = unit_position
	add_child(node)
	return node

# 单位选择逻辑
func _select_units():
	pass
