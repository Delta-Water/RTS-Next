class_name UnitBase1
extends CharacterBody2D

enum State { IDLE, ROTATING, MOVING }

@export var movement_speed = 50
@export var rotate_speed: float = 3
@export var can_move_while_rotating: bool = true
## 碰撞体积半径。(与避障半径自动关联）
@export_range(0.1, 50.0, 0.1, "or_greater")
var radius: float = 10.0:
	set(val):
		radius = val
		if collision_shape_2d and navigation_agent_2d:
			(collision_shape_2d.shape as CircleShape2D).radius = val
			navigation_agent_2d.radius = val

## 显示体积半径。
@export_range(0.1, 50.0, 0.1, "or_greater")
var display_radius: float = 10.0

var is_selected: bool = false
var target_position:Vector2 = Vector2(0, 0)
var current_state: State = State.IDLE
var rotate_tween: Tween
var current_path_index: int = -1

@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	navigation_agent_2d.velocity_computed.connect(_on_velocity_computed)
	
	# 再次调用set函数保证子节点属性被正确赋值
	radius = radius
	display_radius = display_radius

func set_movement_target(target: Vector2):
	_interrupt_current_action()
	target_position = target
	current_path_index = -1
	navigation_agent_2d.target_position = target
	# 状态将在 physics_process 中更新
	current_state = State.IDLE

## 同步碰撞体积和显示体积的半径。
func set_both_radius(new_radius: float) -> void:
	radius = new_radius
	display_radius = new_radius

func _physics_process(_delta: float):
	match current_state:
		State.IDLE:
			# 等待导航路径更新
			if not navigation_agent_2d.is_navigation_finished():
				_start_moving()
			else:
				velocity = Vector2.ZERO
				move_and_slide()
		
		State.ROTATING:
			if can_move_while_rotating:
				_perform_move()
			else:
				# 旋转前保持静止
				velocity = Vector2.ZERO
				move_and_slide()
		
		State.MOVING:
			_perform_move()

func _perform_move():
	if navigation_agent_2d.is_navigation_finished():
		current_state = State.IDLE
		return
		
	var next_path_pos = navigation_agent_2d.get_next_path_position()
	var new_velocity = global_position.direction_to(next_path_pos) * movement_speed
	
	if navigation_agent_2d.avoidance_enabled:
		navigation_agent_2d.set_velocity(new_velocity)
	else:
		_on_velocity_computed(new_velocity)
	
	# 检查路径点变化
	var new_index = navigation_agent_2d.get_current_navigation_path_index()
	if current_path_index != new_index:
		current_path_index = new_index
		_start_rotation(navigation_agent_2d.get_next_path_position())

func _interrupt_current_action():
	if rotate_tween and rotate_tween.is_running():
		rotate_tween.kill()
	current_state = State.IDLE

func _start_moving():
	if navigation_agent_2d.is_navigation_finished():
		return
	
	# 初始旋转
	_start_rotation(navigation_agent_2d.get_next_path_position())

func _start_rotation(target_position: Vector2):
	current_state = State.ROTATING
	navigation_agent_2d.set_velocity_forced(Vector2.ZERO)
	
	# 清除现有动画
	if rotate_tween and rotate_tween.is_valid():
		rotate_tween.kill()
	
	# 计算目标方向（使用全局位置）
	var direction_to_target = (target_position - global_position).normalized()
	var target_angle = direction_to_target.angle()
	
	# 计算最短旋转角度
	rotation = wrapf(rotation, -PI, PI)
	var angle_diff = abs(target_angle - rotation)
	var rotation_direction: int = 1
	
	if rotation >= target_angle:
		rotation_direction = -1
	if angle_diff > PI:
		angle_diff = 2 * PI - angle_diff
		rotation_direction *= -1
	
	# 微小角度直接设置
	if abs(angle_diff) < 0.01:
		rotation = target_angle
		current_state = State.MOVING
		return
	
	# 创建旋转动画
	rotate_tween = create_tween()
	var rot_duration = angle_diff / rotate_speed
	
	rotate_tween.tween_property(
		self, 
		"rotation", 
		rotation + angle_diff * rotation_direction, 
		rot_duration
	).set_ease(Tween.EASE_OUT)
	
	rotate_tween.tween_callback(_on_rotation_finished)

func _on_rotation_finished():
	if current_state == State.ROTATING:  # 防止中断后仍切换状态
		current_state = State.MOVING
	rotate_tween = null

func _on_velocity_computed(safe_velocity: Vector2):
	if can_move_while_rotating || current_state == State.MOVING:
		velocity = safe_velocity
		move_and_slide()

func change_selected_state(state: bool):
	is_selected = state
