# 单位基类
class_name UnitBase
extends CharacterBody2D

# 组件引用
var movement_component: MovementComponent

func _ready():
	# 查找并初始化移动组件
	movement_component = $MovementComponent
	if not movement_component:
		push_error("Unit is missing MovementComponent")

# 物理处理
func _physics_process(delta):
	if movement_component:
		movement_component.process_movement(delta)
		move_and_slide()

# 设置移动路径
func set_path(path: Array[Vector2]):
	if movement_component:
		movement_component.set_path(path)
