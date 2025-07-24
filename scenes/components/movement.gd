# 基础移动组件 - 可作为独立节点附加到任何单位上
class_name MovementComponent
extends Node

# 状态枚举
enum State { IDLE, ROTATING, MOVING }

# 可导出配置
@export var speed: float = 50
@export var rotate_speed: float = 3.0
@export var stopping_distance: float = 0.5
@export var can_fly: bool = false  # 飞行单位可忽略地形
@export var pathfinder: NodePath  # 路径查找器引用

# 内部变量
var current_state: State = State.IDLE
var target_pos: Vector2 = Vector2.ZERO
var path: Array[Vector2] = []
var rotate_tween: Tween
var is_new_path: bool = false
var unit: CharacterBody2D

func _ready():
	unit = get_parent() as CharacterBody2D
	if not unit:
		push_error("MovementComponent must be a child of CharacterBody2D")

# 设置移动路径
func set_path(new_path: Array[Vector2]):
	if rotate_tween:
		rotate_tween.kill()
		rotate_tween = null
	
	path = new_path
	is_new_path = true
	
	if not path.is_empty():
		current_state = State.ROTATING
		_process_next_target()

# 处理物理移动
func process_movement(delta: float):
	match current_state:
		State.IDLE:
			unit.velocity = Vector2.ZERO
		
		State.ROTATING:
			unit.velocity = Vector2.ZERO
		
		State.MOVING:
			var move_direction = unit.position.direction_to(target_pos)
			unit.velocity = move_direction * speed
			
			if unit.position.distance_to(target_pos) <= stopping_distance:
				_process_next_target()

# 处理下一个目标点
func _process_next_target():
	if path.is_empty():
		current_state = State.IDLE
		return
	
	target_pos = path.pop_front()
	
	if is_new_path:
		is_new_path = false
		_process_next_target()
		return
	
	current_state = State.ROTATING
	_start_rotation(target_pos)

# 开始旋转动画
func _start_rotation(target: Vector2):
	if rotate_tween:
		rotate_tween.kill()
		rotate_tween = null
	
	var target_direction = (target - unit.global_position).normalized()
	var target_angle = target_direction.angle()
	var angle_diff = wrapf(target_angle - unit.rotation, -PI, PI)
	
	if abs(angle_diff) >= 0.1:
		var rotation_time = abs(angle_diff) / rotate_speed
		rotate_tween = create_tween()
		rotate_tween.tween_property(unit, "rotation", unit.rotation + angle_diff, rotation_time)
		rotate_tween.tween_callback(func(): 
			current_state = State.MOVING
			rotate_tween = null
		)
	else:
		current_state = State.MOVING
